class_name BattleManager
extends Node

## 전투 흐름을 제어하는 매니저. 턴 루프와 상태 전환을 관리한다.

enum BattleState {
	BATTLE_START,
	PLAYER_TURN_START,
	PLAYER_ACTION,
	PLAYER_TURN_END,
	ENEMY_TURN,
	BATTLE_WIN,
	BATTLE_LOSE,
}

const HAND_SIZE := 5
const STARTING_QI := 3
const DEFAULT_MAX_CLASS_RESOURCE := 10  # 클래스 고유 자원 기본 최대치

var state: BattleState = BattleState.BATTLE_START
var current_qi: int = 0
var max_qi: int = STARTING_QI
var turn_number: int = 0

# 클래스 고유 자원 — 턴 간 유지, 전투 시작 시 0
# 무관: 기력(氣力), 문관: 학식(學識)
var current_class_resource: int = 0
var max_class_resource: int = DEFAULT_MAX_CLASS_RESOURCE
var has_class_resource: bool = false  # 고유 자원 보유 여부
var character_id: String = ""  # 현재 캐릭터 클래스 ID
var _next_card_cost_reduce: int = 0  # 다음 카드 비용 감소 (격물치지 등)
var _cost_reduce_all_this_turn: int = 0  # 이번 턴 모든 카드 비용 감소 (축지법 등)
var _double_token_this_turn: bool = false  # 이번 턴 토큰 생성량 2배 (천하무적진)
var qi_gained_this_turn: int = 0  # 이번 턴 획득한 기 추적 (기폭용)

# 패시브/액티브 스킬 시스템
var cards_played_this_turn: int = 0  # 이번 턴 사용한 카드 수 (문관 패시브용)
var active_skill_used: bool = false  # 액티브 스킬 사용 여부 (전투당 1회)

# 카드 더미
var draw_pile: Array[String] = []   # 드로우 파일 (card IDs)
var hand: Array[String] = []         # 손패
var discard_pile: Array[String] = [] # 버린 카드 더미
var exhaust_pile: Array[String] = [] # 소멸 카드 더미

# 전투 참여자
var player_hp: int = 70
var player_max_hp: int = 70
var player_block: int = 0
var enemies: Array[Dictionary] = []

# 시조 시스템
var sijo_system: SijoSystem = null

# 상태이상 시스템
var status_effects: StatusEffectManager = null

signal state_changed(new_state: BattleState)
signal qi_changed(current: int, max_val: int)
signal hand_changed(new_hand: Array[String])
signal block_changed(new_block: int)
signal hp_changed(current: int, max_val: int)
signal card_drawn(card_id: String)
signal turn_started(turn: int)
signal enemy_intent_shown(enemy_index: int, intent: Dictionary)
signal enemy_hp_changed(enemy_index: int, current: int, max_val: int)
signal battle_ended(victory: bool)
signal status_effect_changed(target: String, effect_id: String, stacks: int)
signal dot_damage_dealt(target: String, effect_id: String, amount: int)
signal class_resource_changed(current: int, max_val: int)
signal passive_triggered(skill_name: String, description: String)
signal active_skill_available_changed(available: bool)


func _ready() -> void:
	# StatusEffectManager 자동 생성
	if status_effects == null:
		status_effects = StatusEffectManager.new()
		add_child(status_effects)
		status_effects.effect_applied.connect(_on_effect_applied)
		status_effects.effect_removed.connect(_on_effect_removed)
		status_effects.effect_triggered.connect(_on_effect_triggered)


func start_battle(deck: Array[String], enemy_data: Array[Dictionary], hp: int, max_hp: int, qi: int, character_id: String = "") -> void:
	if deck.is_empty():
		push_error("BattleManager.start_battle: 덱이 비어있음 — 기본 카드 추가")
		deck = ["C001", "C001", "C001", "C002", "C002"]  # 최소 플레이 가능한 안전 덱
	if enemy_data.is_empty():
		push_error("BattleManager.start_battle: 적 데이터가 비어있음 — 기본 적 추가")
		var fallback := DataLoader.get_enemy("E001")
		if not fallback.is_empty():
			enemy_data.append(fallback)
		else:
			enemy_data.append({"id": "E001", "name": {"ko": "허수아비"}, "hp": 20, "intents": []})
	if max_hp <= 0:
		push_error("BattleManager.start_battle: max_hp가 0 이하 — %d" % max_hp)
		max_hp = 1

	player_hp = hp
	player_max_hp = max_hp
	max_qi = qi
	turn_number = 0
	player_block = 0
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()

	# 클래스 고유 자원 초기화 (무관: 기력 최대 10, 문관: 학식 최대 6)
	self.character_id = character_id
	has_class_resource = character_id in ["mugwan", "mungwan"]
	current_class_resource = 0
	_next_card_cost_reduce = 0
	match character_id:
		"mugwan":
			max_class_resource = 10
		"mungwan":
			max_class_resource = 6
		_:
			max_class_resource = DEFAULT_MAX_CLASS_RESOURCE
	if has_class_resource:
		class_resource_changed.emit(current_class_resource, max_class_resource)

	# 스킬 초기화
	cards_played_this_turn = 0
	active_skill_used = false

	# 상태이상 초기화
	status_effects.clear_all()

	# 덱 셔플
	draw_pile = deck.duplicate()
	_shuffle_draw_pile()

	# 적 초기화 (어센션 HP 스케일링 적용)
	var hp_mult := GameManager.get_ascension_enemy_hp_multiplier()
	var is_boss_fight := GameManager.run_data and GameManager.run_data.current_node_type == MapData.NodeType.BOSS
	if is_boss_fight:
		hp_mult = GameManager.get_ascension_boss_hp_multiplier()
	enemies.clear()
	for e in enemy_data:
		var enemy := e.duplicate(true)
		var hp_data = enemy.get("hp", null)
		if hp_data == null:
			# hp 필드 없으면 hp_total을 fallback으로 사용
			hp_data = enemy.get("hp_total", null)
		if hp_data is Dictionary:
			enemy["current_hp"] = int(randi_range(hp_data.get("min", 20), hp_data.get("max", 30)) * hp_mult)
			enemy["max_hp"] = enemy["current_hp"]
		elif hp_data is int or hp_data is float:
			enemy["current_hp"] = int(int(hp_data) * hp_mult)
			enemy["max_hp"] = enemy["current_hp"]
		else:
			# HP 데이터를 찾을 수 없는 경우 에러 로그
			push_error("BattleManager: 적 '%s' HP 데이터 누락 — 기본값 1 적용" % enemy.get("id", "unknown"))
			enemy["current_hp"] = 1
			enemy["max_hp"] = 1
		enemy["block"] = 0
		enemy["move_index"] = 0
		enemy["current_phase"] = 0
		# 보스 페이즈: 첫 페이즈의 moves/pattern 적용
		var phases: Array = enemy.get("phases", [])
		if not phases.is_empty():
			var first_phase: Dictionary = phases[0]
			if first_phase.has("moves"):
				enemy["moves"] = first_phase["moves"]
			if first_phase.has("move_pattern"):
				enemy["move_pattern"] = first_phase["move_pattern"]
		enemies.append(enemy)

	# 시조 시스템 초기화
	if sijo_system:
		sijo_system.reset()

	_change_state(BattleState.BATTLE_START)

	# 보스 전투 시작 효과 처리 (소환, 버프, 대사 등)
	for i in enemies.size():
		var enemy := enemies[i]
		var start_effects: Array = enemy.get("on_battle_start_effects", [])
		for eff in start_effects:
			if eff is not Dictionary:
				continue
			_apply_battle_start_effect(i, eff)

	# 민심 70+ → 백성 지원병 등장
	_check_minshim_ally_support()

	# 이벤트 pending_effects 처리 (다음 전투 방어도 등)
	if GameManager.run_data and GameManager.run_data.narrative_state.has("pending_effects"):
		var pending: Array = GameManager.run_data.narrative_state["pending_effects"]
		var remaining: Array = []
		for eff in pending:
			if eff is not Dictionary:
				continue
			match eff.get("type", ""):
				"next_battle_block":
					player_block += int(eff.get("block", 0))
					block_changed.emit(player_block)
				_:
					remaining.append(eff)
		if remaining.is_empty():
			GameManager.run_data.narrative_state.erase("pending_effects")
		else:
			GameManager.run_data.narrative_state["pending_effects"] = remaining

	# 도사 액티브: 방술 개방 — 전투 시작 시 시조 첫 2칸 자동 채움
	if character_id == "dosa" and sijo_system:
		sijo_system.try_fill_slot(3, "D001")  # 기공 [3]
		sijo_system.try_fill_slot(4, "D002")  # 결인 [4]
		active_skill_used = true
		passive_triggered.emit("방술 개방", "시조 초장 자동 채움: 기공→결인")

	begin_player_turn()


func begin_player_turn() -> void:
	turn_number += 1
	_next_card_cost_reduce = 0  # 턴 시작 시 비용 감소 초기화
	_cost_reduce_all_this_turn = 0  # 턴 시작 시 전체 비용 감소 초기화
	_double_token_this_turn = false  # 턴 시작 시 토큰 2배 초기화
	qi_gained_this_turn = 0  # 턴 시작 시 기 획득량 초기화
	cards_played_this_turn = 0  # 턴 시작 시 카드 사용 수 초기화

	# 무관 패시브: 지휘통솔 — 병사 토큰 보유 시 방어도 2
	if character_id == "mugwan":
		var effects := status_effects.get_all_effects("player")
		var token_stacks: int = effects.get("병사_토큰", 0)
		if token_stacks > 0:
			gain_block(2)
			passive_triggered.emit("지휘통솔", "병사 토큰 보유 → 방어도 +2")

	# 갑주(영구 방어막) 처리: 갑주가 있으면 block을 갑주 값으로 유지, 없으면 리셋
	var dot_result := status_effects.process_turn_start("player")
	var armor: int = dot_result.get("armor", 0)
	if armor > 0:
		# 갑주: 기존 block을 리셋하되 갑주만큼 유지
		player_block = armor
	else:
		player_block = 0
	block_changed.emit(player_block)

	current_qi = max_qi
	qi_changed.emit(current_qi, max_qi)
	turn_started.emit(turn_number)

	_change_state(BattleState.PLAYER_TURN_START)

	# 플레이어 턴 시작 시 지속 피해 처리 (독, 화상, 출혈 등)
	if dot_result["damage"] > 0:
		player_hp -= dot_result["damage"]
		player_hp = maxi(player_hp, 0)
		hp_changed.emit(player_hp, player_max_hp)
		if player_hp <= 0:
			# 유물 트리거: 즉사 방지 (R028 불사신 부적)
			if not RelicManager.trigger_on_lethal_damage(self):
				AudioManager.play_sfx_by_key("defeat")
				_change_state(BattleState.BATTLE_LOSE)
				battle_ended.emit(false)
				return

	# 카드 드로우 (냉기 등 드로우 수정자 적용)
	var draw_count := HAND_SIZE + status_effects.get_draw_modifier("player")
	draw_count = maxi(draw_count, 1)  # 최소 1장은 드로우
	draw_cards(draw_count)

	# 적 인텐트 표시
	for i in enemies.size():
		if enemies[i]["current_hp"] > 0:
			var intent := _get_enemy_intent(i)
			enemy_intent_shown.emit(i, intent)

	_change_state(BattleState.PLAYER_ACTION)


func try_play_card(hand_index: int, target_enemy_index: int = 0) -> bool:
	if state != BattleState.PLAYER_ACTION:
		push_warning("BattleManager.try_play_card: 플레이어 액션 상태가 아님 — %s" % BattleState.keys()[state])
		return false
	if hand_index < 0 or hand_index >= hand.size():
		push_error("BattleManager.try_play_card: 잘못된 hand_index=%d (hand.size=%d)" % [hand_index, hand.size()])
		return false
	if target_enemy_index < 0 or target_enemy_index >= enemies.size():
		push_error("BattleManager.try_play_card: 잘못된 target_enemy_index=%d (enemies.size=%d)" % [target_enemy_index, enemies.size()])
		return false

	var card_id: String = hand[hand_index]
	var card: CardData = _get_battle_card(card_id)
	if card == null:
		push_error("BattleManager.try_play_card: 카드 데이터 로드 실패 — card_id=%s" % card_id)
		return false

	# 비용 계산: 구금(+1) → 축지법/격물치지(-N) 순서
	var effective_cost := card.cost
	var detention_stacks := status_effects.get_stacks("player", "구금")
	if detention_stacks > 0:
		effective_cost += detention_stacks
	if _cost_reduce_all_this_turn != 0:
		effective_cost -= _cost_reduce_all_this_turn
	if _next_card_cost_reduce > 0:
		effective_cost -= _next_card_cost_reduce
	effective_cost = maxi(effective_cost, 0)

	# 기(氣) 확인
	if effective_cost > current_qi:
		return false

	# 클래스 고유 자원 확인 (무관: 기력, 문관: 학식)
	if has_class_resource and card.stamina_cost > 0 and card.stamina_cost > current_class_resource:
		return false

	# 비용 감소 소비
	if _next_card_cost_reduce > 0:
		_next_card_cost_reduce = 0

	# 기 소비
	current_qi -= effective_cost
	qi_changed.emit(current_qi, max_qi)

	# 클래스 고유 자원 소비 (무관: 기력, 문관: 학식)
	if has_class_resource and card.stamina_cost > 0:
		current_class_resource -= card.stamina_cost
		current_class_resource = maxi(current_class_resource, 0)
		class_resource_changed.emit(current_class_resource, max_class_resource)

	# 카드 사용 SFX
	AudioManager.play_sfx_by_key("card_play")

	# 손패에서 먼저 제거 → 버린 카드로 이동
	# (이후 시그널 체인에서 UI가 재빌드될 때 일관된 손패 상태 보장)
	hand.remove_at(hand_index)
	discard_pile.append(card_id)

	# 시조 슬롯 시도
	if sijo_system:
		sijo_system.try_fill_slot(card.beat, card_id)

	# 카드 효과 적용
	_resolve_card_effect(card, target_enemy_index)

	# 유물 트리거: 턴당 첫 번째 카드 사용 (R007 사서)
	if cards_played_this_turn == 0:
		RelicManager.trigger_on_first_card_play_per_turn(self)

	# 유물 트리거: 진형 카드 사용 (RM001 병서)
	if card.type == "formation" or "formation" in card.subtypes:
		RelicManager.trigger_on_formation_card_play(self)

	# 유물 트리거: 주문 카드 사용 (RD001 선단)
	if card.type == "spell" or "spell" in card.subtypes:
		RelicManager.trigger_on_spell_card_play(self)

	# 유물 트리거: 와일드카드 사용 (RS005 장단 북)
	if "wildcard" in card.subtypes:
		RelicManager.trigger_on_wildcard_play(self)

	# 카드 사용 수 추적 (문관 패시브용)
	cards_played_this_turn += 1

	# 손패 변경 시그널 발행 (UI 갱신 트리거)
	hand_changed.emit(hand)

	# 전투 종료 확인 (적 사망)
	if _all_enemies_dead():
		AudioManager.play_sfx_by_key("victory")
		_change_state(BattleState.BATTLE_WIN)
		battle_ended.emit(true)

	return true


func end_player_turn() -> void:
	if state != BattleState.PLAYER_ACTION:
		return

	_change_state(BattleState.PLAYER_TURN_END)

	# 도사 패시브: 천지기 — 시조 슬롯 3칸 이상이면 기 1 회복
	if character_id == "dosa" and sijo_system:
		if sijo_system.get_filled_count() >= 3:
			current_qi += 1
			qi_changed.emit(current_qi, max_qi)
			passive_triggered.emit("천지기", "시조 슬롯 3칸 이상 → 기 +1")

	# 문관 패시브: 학식충전 — 카드 3장 이상 사용 시 학식 1 획득
	if character_id == "mungwan" and cards_played_this_turn >= 3:
		current_class_resource += 1
		current_class_resource = mini(current_class_resource, max_class_resource)
		class_resource_changed.emit(current_class_resource, max_class_resource)
		passive_triggered.emit("학식충전", "카드 3장 이상 사용 → 학식 +1")

	# 플레이어 턴 종료 시 디버프 기간 감소
	status_effects.process_turn_end("player")

	# 손패 → 버린 카드 더미
	for card_id in hand:
		discard_pile.append(card_id)
	hand.clear()
	hand_changed.emit(hand)

	# 적 턴 시작
	execute_enemy_turn()


func execute_enemy_turn() -> void:
	_change_state(BattleState.ENEMY_TURN)

	for i in enemies.size():
		var enemy := enemies[i]
		if enemy["current_hp"] <= 0:
			continue

		# 적 패시브: 턴 시작 시 항상 발동하는 효과 (탐관오리 보스 등)
		var passive: Dictionary = _get_current_passive(enemy)
		if not passive.is_empty():
			_execute_enemy_action(i, passive)

		# 적 지속 피해/갑주 처리
		var enemy_target := "enemy_%d" % i
		var dot_result := status_effects.process_turn_start(enemy_target)

		# 갑주(영구 방어막) 처리: 갑주가 있으면 block 유지, 없으면 리셋
		var enemy_armor: int = dot_result.get("armor", 0)
		if enemy_armor > 0:
			enemy["block"] = enemy_armor
		else:
			enemy["block"] = 0

		if dot_result["damage"] > 0:
			enemy["current_hp"] -= dot_result["damage"]
			enemy["current_hp"] = maxi(enemy["current_hp"], 0)
			enemy_hp_changed.emit(i, enemy["current_hp"], enemy["max_hp"])
			if enemy["current_hp"] <= 0:
				continue

		# 적 행동 실행 (디버프 감소 전에 행동해야 취약 등이 적용됨)
		var intent := _get_enemy_intent(i)
		_execute_enemy_action(i, intent)

		# 적 디버프 기간 감소 (행동 후 감소)
		status_effects.process_turn_end(enemy_target)

		# 행동 인덱스 진행
		var pattern = enemy.get("move_pattern", {})
		var sequence: Array = pattern.get("sequence", []) if pattern is Dictionary else []
		var total: int = sequence.size() if not sequence.is_empty() else enemy.get("moves", []).size()
		if total > 0:
			enemy["move_index"] = (enemy["move_index"] + 1) % total

	# 전투 종료 확인
	if player_hp <= 0:
		# 유물 트리거: 즉사 방지 (R028 불사신 부적)
		if not RelicManager.trigger_on_lethal_damage(self):
			AudioManager.play_sfx_by_key("defeat")
			_change_state(BattleState.BATTLE_LOSE)
			battle_ended.emit(false)
			return

	if _all_enemies_dead():
		AudioManager.play_sfx_by_key("victory")
		_change_state(BattleState.BATTLE_WIN)
		battle_ended.emit(true)
		return

	# 다음 플레이어 턴
	begin_player_turn()


func draw_cards(count: int) -> void:
	var drew_any := false
	for i in count:
		if draw_pile.is_empty():
			_reshuffle_discard()
		if draw_pile.is_empty():
			break
		var card_id: String = draw_pile.pop_back()
		hand.append(card_id)
		card_drawn.emit(card_id)
		drew_any = true
	if drew_any:
		AudioManager.play_sfx_by_key("card_draw")
	hand_changed.emit(hand)


func take_damage(amount: int) -> void:
	# 취약 적용 (받는 피해 증가)
	var final_amount := status_effects.calculate_incoming_damage("player", amount)

	var remaining := final_amount
	if player_block > 0:
		var blocked := mini(player_block, remaining)
		player_block -= blocked
		remaining -= blocked
		block_changed.emit(player_block)
	if remaining > 0:
		player_hp -= remaining
		player_hp = maxi(player_hp, 0)
		hp_changed.emit(player_hp, player_max_hp)
		AudioManager.play_sfx_by_key("damage")
		# 유물 트리거: 즉사 방지 (R028 불사신 부적)
		if player_hp <= 0:
			if not RelicManager.trigger_on_lethal_damage(self):
				AudioManager.play_sfx_by_key("defeat")
				_change_state(BattleState.BATTLE_LOSE)
				battle_ended.emit(false)
				return


func gain_block(amount: int) -> void:
	player_block += amount
	block_changed.emit(player_block)
	AudioManager.play_sfx_by_key("block")

	# 출혈: 방어도 획득 시 출혈 스택만큼 추가 피해
	var bleed_damage := status_effects.calculate_bleed_on_block("player", amount)
	if bleed_damage > 0:
		player_hp -= bleed_damage
		player_hp = maxi(player_hp, 0)
		hp_changed.emit(player_hp, player_max_hp)
		if player_hp <= 0:
			if not RelicManager.trigger_on_lethal_damage(self):
				AudioManager.play_sfx_by_key("defeat")
				_change_state(BattleState.BATTLE_LOSE)
				battle_ended.emit(false)


func deal_damage_to_enemy(enemy_index: int, amount: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		push_error("BattleManager.deal_damage_to_enemy: 잘못된 enemy_index=%d (enemies.size=%d)" % [enemy_index, enemies.size()])
		return
	var enemy := enemies[enemy_index]
	if enemy["current_hp"] <= 0:
		return

	# 플레이어 공격력 수정 (strength, 약화)
	var final_damage := status_effects.calculate_outgoing_damage("player", amount)

	# 적의 취약 적용
	var enemy_target := "enemy_%d" % enemy_index
	final_damage = status_effects.calculate_incoming_damage(enemy_target, final_damage)

	var remaining := final_damage
	var eblock: int = enemy.get("block", 0)
	if eblock > 0:
		var blocked := mini(eblock, remaining)
		enemy["block"] = eblock - blocked
		remaining -= blocked

	if remaining > 0:
		enemy["current_hp"] -= remaining
		enemy["current_hp"] = maxi(enemy["current_hp"], 0)

	enemy_hp_changed.emit(enemy_index, enemy["current_hp"], enemy["max_hp"])

	# 보스 페이즈 전환 체크
	if enemy["current_hp"] > 0:
		_check_phase_transition(enemy_index)
	elif enemy["current_hp"] <= 0:
		# 적 사망 시 유물 트리거 (R018 등)
		RelicManager.trigger_on_enemy_kill(self)
		# 소환된 적 사망 시 유물 트리거 (RD002 음양패)
		if enemy.get("_is_summoned", false):
			RelicManager.trigger_on_summon_token_death(self)
		# 아군 사망 시 다른 적들의 on_ally_death_effects 발동 (군관 보스 등)
		_trigger_ally_death_effects(enemy_index)


# --- 내부 함수 ---

func _resolve_card_effect(card: CardData, target_enemy_index: int) -> void:
	# 피해
	if card.damage > 0:
		if card.is_aoe:
			for i in enemies.size():
				if enemies[i]["current_hp"] > 0:
					deal_damage_to_enemy(i, card.damage)
					# 유물 트리거: 공격 카드 사용 시 (저주받은 투구)
					RelicManager.trigger_on_attack_card_played(self, i)
		else:
			deal_damage_to_enemy(target_enemy_index, card.damage)
			# 유물 트리거: 공격 카드 사용 시 (저주받은 투구)
			RelicManager.trigger_on_attack_card_played(self, target_enemy_index)

	# 방어도
	if card.block_value > 0:
		gain_block(card.block_value)

	# 기(氣) 획득
	if card.qi_gain > 0:
		current_qi += card.qi_gain
		qi_gained_this_turn += card.qi_gain
		qi_changed.emit(current_qi, max_qi)

	# 카드 드로우
	if card.draw_count > 0:
		draw_cards(card.draw_count)

	# 고유 자원 최대치 증가 (무관 G015/G025, 문관 W011)
	if has_class_resource and card.resource_max_increase > 0:
		max_class_resource += card.resource_max_increase
		class_resource_changed.emit(current_class_resource, max_class_resource)

	# 클래스 고유 자원 획득 (무관: 기력, 문관: 학식)
	if has_class_resource and card.stamina_gain > 0:
		current_class_resource += card.stamina_gain
		current_class_resource = mini(current_class_resource, max_class_resource)
		class_resource_changed.emit(current_class_resource, max_class_resource)

	# 문관 전용: 상소(W003) — 학식 전부 소비, 소비량×배수 피해
	if character_id == "mungwan" and card.consume_all_resource:
		var consumed := current_class_resource
		current_class_resource = 0
		class_resource_changed.emit(current_class_resource, max_class_resource)
		# 유물 트리거: 학식 전소 시 (RW001 어진)
		RelicManager.trigger_on_scholarship_exhaust(self, consumed)
		var bonus_damage := consumed * card.resource_damage_multiplier
		var total := maxi(bonus_damage, card.min_resource_damage)
		if card.is_aoe:
			for i in enemies.size():
				if enemies[i]["current_hp"] > 0:
					deal_damage_to_enemy(i, total)
		else:
			deal_damage_to_enemy(target_enemy_index, total)

	# 선택적 자원 소비 + 디버프 부여 (탄핵 등: 학식이 있으면 소비하고 추가 효과 발동)
	if has_class_resource and card.optional_resource_cost > 0 and card.apply_debuff_on_resource != "":
		if current_class_resource >= card.optional_resource_cost:
			current_class_resource -= card.optional_resource_cost
			current_class_resource = maxi(current_class_resource, 0)
			class_resource_changed.emit(current_class_resource, max_class_resource)
			var target_id := "enemy_%d" % target_enemy_index
			status_effects.apply_effect(target_id, card.apply_debuff_on_resource, card.debuff_duration)

	# 문관 전용: 격물치지(W007) — 다음 카드 비용 감소
	if card.cost_reduce_next > 0:
		_next_card_cost_reduce += card.cost_reduce_next

	# 문관 전용: 피화(W010) — 시조 슬롯 조건부 학식 획득
	if has_class_resource and card.conditional_resource_gain > 0 and sijo_system:
		var filled_count := sijo_system.get_filled_count()
		if filled_count >= card.conditional_resource_threshold:
			current_class_resource += card.conditional_resource_gain
			current_class_resource = mini(current_class_resource, max_class_resource)
			class_resource_changed.emit(current_class_resource, max_class_resource)

	# 토큰 생성 (무관: 병사 토큰)
	if card.tokens > 0:
		var token_amount := card.tokens
		if _double_token_this_turn:
			token_amount *= 2
		status_effects.apply_effect("player", "병사_토큰", token_amount)

	# 이번 턴 토큰 2배 활성화 (천하무적진 G005)
	if card.double_token_gen:
		_double_token_this_turn = true

	# 이번 턴 모든 카드 비용 감소 (축지법 D005)
	if card.cost_reduce_this_turn > 0:
		_cost_reduce_all_this_turn += card.cost_reduce_this_turn

	# 기폭 D009: 이번 턴 획득한 기×배수 피해
	if card.damage_per_qi_gained > 0:
		var qi_dmg := qi_gained_this_turn * card.damage_per_qi_gained
		qi_dmg = maxi(qi_dmg, card.min_damage)
		if card.is_aoe:
			for i in enemies.size():
				if enemies[i]["current_hp"] > 0:
					deal_damage_to_enemy(i, qi_dmg)
		else:
			deal_damage_to_enemy(target_enemy_index, qi_dmg)

	# 흑염 D017: 대상 화상≥2 또는 독≥2 시 추가 피해
	if card.bonus_on_burn > 0 or card.bonus_on_poison > 0:
		var target_id := "enemy_%d" % target_enemy_index
		var bonus := 0
		if card.bonus_on_burn > 0 and status_effects.get_stacks(target_id, "화상") >= 2:
			bonus += card.bonus_on_burn
		if card.bonus_on_poison > 0 and status_effects.get_stacks(target_id, "독") >= 2:
			bonus += card.bonus_on_poison
		if bonus > 0:
			deal_damage_to_enemy(target_enemy_index, bonus)

	# 화상 부여 (부적 D004 등)
	if card.burn_stacks > 0:
		if card.is_aoe:
			for i in enemies.size():
				if enemies[i]["current_hp"] > 0:
					status_effects.apply_effect("enemy_%d" % i, "화상", card.burn_stacks)
		else:
			status_effects.apply_effect("enemy_%d" % target_enemy_index, "화상", card.burn_stacks)

	# 독 부여 (독안개 D011 등)
	if card.poison_stacks > 0:
		if card.is_aoe:
			for i in enemies.size():
				if enemies[i]["current_hp"] > 0:
					status_effects.apply_effect("enemy_%d" % i, "독", card.poison_stacks)
		else:
			status_effects.apply_effect("enemy_%d" % target_enemy_index, "독", card.poison_stacks)

	# 약화 부여 (후퇴 M003 등)
	if card.weaken_stacks > 0:
		var target_id := "enemy_%d" % target_enemy_index
		status_effects.apply_effect(target_id, "약화", card.weaken_stacks)

	# 적 버프 제거 (파직 W018)
	if card.remove_buffs:
		if card.is_aoe:
			for i in enemies.size():
				if enemies[i]["current_hp"] > 0:
					status_effects.clear_buffs("enemy_%d" % i)
		else:
			status_effects.clear_buffs("enemy_%d" % target_enemy_index)

	# 주박 D019: 취약 부여 + DoT 배율 디버프
	if card.vulnerable_stacks > 0:
		var target_id := "enemy_%d" % target_enemy_index
		status_effects.apply_effect(target_id, "취약", card.vulnerable_stacks)
	if card.dot_multiplier > 0.0:
		var target_id := "enemy_%d" % target_enemy_index
		status_effects.apply_effect(target_id, "주박", 1)

	# 무관 전용: 기력 기반 피해 (역전의 기세 G014, 마지막 도박 G016)
	if has_class_resource and card.damage_per_stamina > 0:
		var stamina_used := current_class_resource
		if card.consume_all_stamina:
			current_class_resource = 0
			class_resource_changed.emit(current_class_resource, max_class_resource)
		var stam_dmg := stamina_used * card.damage_per_stamina
		stam_dmg = maxi(stam_dmg, card.min_damage)
		if card.is_aoe:
			for i in enemies.size():
				if enemies[i]["current_hp"] > 0:
					deal_damage_to_enemy(i, stam_dmg)
		else:
			deal_damage_to_enemy(target_enemy_index, stam_dmg)

	# 무관 전용: 기력당 추가 피해 (무쌍 G018 — 기본 데미지 + 기력×배수)
	if has_class_resource and card.bonus_damage_per_stamina > 0:
		var stamina_used := current_class_resource
		if card.consume_all_stamina and current_class_resource > 0:
			current_class_resource = 0
			class_resource_changed.emit(current_class_resource, max_class_resource)
		var bonus_dmg := stamina_used * card.bonus_damage_per_stamina
		if bonus_dmg > 0:
			if card.is_aoe:
				for i in enemies.size():
					if enemies[i]["current_hp"] > 0:
						deal_damage_to_enemy(i, bonus_dmg)
			else:
				deal_damage_to_enemy(target_enemy_index, bonus_dmg)


func _change_state(new_state: BattleState) -> void:
	state = new_state
	state_changed.emit(new_state)


func _shuffle_draw_pile() -> void:
	for i in range(draw_pile.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var temp: String = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = temp


func _reshuffle_discard() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	_shuffle_draw_pile()
	# 유물 트리거: 덱 셔플 (봉황 깃털)
	RelicManager.trigger_on_deck_shuffle(self)


func _get_enemy_intent(enemy_index: int) -> Dictionary:
	if enemy_index < 0 or enemy_index >= enemies.size():
		push_error("BattleManager._get_enemy_intent: 잘못된 enemy_index=%d" % enemy_index)
		return {"intent": "attack", "damage": 0, "times": 1}
	var enemy := enemies[enemy_index]
	var moves: Array = enemy.get("moves", [])
	if moves.is_empty():
		return {"intent": "attack", "damage": 6, "times": 1}

	# move_pattern.sequence가 있으면 move ID로 조회
	var pattern = enemy.get("move_pattern", {})
	var sequence: Array = pattern.get("sequence", []) if pattern is Dictionary else []
	if not sequence.is_empty():
		var seq_idx: int = enemy.get("move_index", 0) % sequence.size()
		var move_id: String = sequence[seq_idx]
		for move in moves:
			if move.get("id", "") == move_id:
				return move
		# ID를 못 찾으면 fallback
		return moves[0]

	# sequence가 없으면 순서대로
	var idx: int = enemy.get("move_index", 0) % moves.size()
	return moves[idx]


func _execute_enemy_action(enemy_index: int, intent: Dictionary) -> void:
	var action_type: String = intent.get("intent", intent.get("type", "attack"))
	var enemy_target := "enemy_%d" % enemy_index

	match action_type:
		"attack":
			_execute_enemy_attack(enemy_index, intent)
		"attack_debuff":
			_execute_enemy_attack(enemy_index, intent)
			_apply_intent_effects(enemy_index, intent)
		"defend":
			var block: int = intent.get("block", 0)
			enemies[enemy_index]["block"] += block
		"defend_buff", "buff_defend":
			var block: int = intent.get("block", 0)
			enemies[enemy_index]["block"] += block
			_apply_intent_effects(enemy_index, intent)
		"attack_buff":
			_execute_enemy_attack(enemy_index, intent)
			_apply_intent_effects(enemy_index, intent)
		"buff_debuff", "debuff_buff":
			_apply_intent_effects(enemy_index, intent)
		"buff":
			_apply_intent_effects(enemy_index, intent)
		"debuff":
			_apply_intent_effects(enemy_index, intent)
		"special":
			_apply_intent_effects(enemy_index, intent)
		"summon":
			_execute_enemy_summon(enemy_index, intent)
		"strip_buff":
			# 플레이어 버프 제거
			status_effects.clear_target("player")
		"cleanse_debuffs":
			# 자신의 디버프 제거
			status_effects.clear_target(enemy_target)
		"gold_drain":
			# 골드 강탈 (탐학한 수령 패시브)
			_execute_gold_drain(enemy_index, intent)
		"card_cost_increase":
			# 카드 비용 증가 디버프 (탐관 연합 패시브)
			var stacks: int = intent.get("stacks", 1)
			_cost_reduce_all_this_turn -= stacks  # 비용 증가 = 음수 감소
			var msg: String = intent.get("name", "")
			if msg != "":
				passive_triggered.emit(msg, "모든 카드 비용 +%d" % stacks)
		"taunt":
			# 조롱 — 플레이어에게 취약 부여 + 적 방어도 획득
			var block: int = intent.get("block", 0)
			var v_stacks: int = intent.get("vulnerability_stacks", 1)
			enemies[enemy_index]["block"] += block
			status_effects.apply_effect("player", "취약", v_stacks)


func _execute_enemy_attack(enemy_index: int, intent: Dictionary) -> void:
	var base_damage: int = intent.get("damage", 0)
	var times: int = intent.get("times", 1)
	var enemy_target := "enemy_%d" % enemy_index

	# 적 공격력 수정 (strength, 약화)
	var final_damage := status_effects.calculate_outgoing_damage(enemy_target, base_damage)

	AudioManager.play_sfx_by_key("enemy_attack")
	for t in times:
		take_damage(final_damage)

		# 가시(thorns): 플레이어가 피격 시 공격자에게 반사 피해
		var thorns_dmg := status_effects.get_thorns_damage("player")
		if thorns_dmg > 0 and enemies[enemy_index]["current_hp"] > 0:
			enemies[enemy_index]["current_hp"] -= thorns_dmg
			enemies[enemy_index]["current_hp"] = maxi(enemies[enemy_index]["current_hp"], 0)
			enemy_hp_changed.emit(enemy_index, enemies[enemy_index]["current_hp"], enemies[enemy_index]["max_hp"])

		if player_hp <= 0:
			break


func _apply_intent_effects(enemy_index: int, intent: Dictionary) -> void:
	var effects: Array = intent.get("effects", [])
	var enemy_target := "enemy_%d" % enemy_index

	for effect in effects:
		if effect is not Dictionary:
			continue
		var effect_type: String = effect.get("type", "")
		var stacks: int = effect.get("stacks", 1)
		var target_str: String = effect.get("target", "player")

		match effect_type:
			"apply_debuff":
				var debuff_id: String = effect.get("debuff", "")
				if debuff_id.is_empty():
					continue
				var resolved_target := _resolve_effect_target(target_str, enemy_target)
				status_effects.apply_effect(resolved_target, debuff_id, stacks)

			"apply_buff":
				var buff_id: String = effect.get("buff", "")
				if buff_id.is_empty():
					continue
				var resolved_target := _resolve_effect_target(target_str, enemy_target)
				status_effects.apply_effect(resolved_target, buff_id, stacks)

			"cleanse_buffs":
				var resolved_target := _resolve_effect_target(target_str, enemy_target)
				status_effects.clear_target(resolved_target)

			"strip_buff":
				# 플레이어 버프 제거 (탐관 연합 왕명 사칭 등)
				var resolved_target := _resolve_effect_target(target_str, enemy_target)
				status_effects.clear_target(resolved_target)

			"reset_sijo_slot":
				# 시조 슬롯 초기화 (보스 특수 능력)
				if sijo_system:
					var count: int = effect.get("count", 1)
					for _i in count:
						sijo_system.reset_random_slot()
					passive_triggered.emit("리듬 끊기", "시조 슬롯 %d개 초기화" % count)


func _execute_gold_drain(enemy_index: int, intent: Dictionary) -> void:
	# 골드 강탈: 엽전을 빼앗고, 없으면 HP 대신 손실
	if not GameManager.run_data:
		return
	var drain: int = intent.get("drain_amount", 15)
	var hp_fallback: int = intent.get("hp_fallback", 10)
	var rd := GameManager.run_data

	if rd.gold >= drain:
		rd.gold -= drain
		passive_triggered.emit(
			intent.get("name", "세금 강탈"),
			"엽전 %d 강탈당했다." % drain
		)
		# 전투 종료 후 환급 추적
		if not rd.narrative_state.has("gold_drained_this_run"):
			rd.narrative_state["gold_drained_this_run"] = 0
		rd.narrative_state["gold_drained_this_run"] = \
			rd.narrative_state.get("gold_drained_this_run", 0) + drain
	else:
		var actual_drain: int = rd.gold
		rd.gold = 0
		var remaining_drain: int = drain - actual_drain
		# 부족한 만큼 HP 대체 손실
		take_damage(hp_fallback)
		passive_triggered.emit(
			intent.get("name", "세금 강탈"),
			"엽전이 부족하다! HP %d 손실." % hp_fallback
		)


func _execute_enemy_summon(_enemy_index: int, intent: Dictionary) -> void:
	var summon_list: Array = intent.get("summon", [])
	for entry in summon_list:
		if entry is not Dictionary:
			continue
		var enemy_id: String = entry.get("enemy_id", "")
		var count: int = entry.get("count", 1)
		var hp_override: int = entry.get("hp_override", 0)
		var name_override: String = entry.get("name_override", "")

		for _i in count:
			var base_data: Dictionary = DataLoader.get_enemy(enemy_id)
			if base_data.is_empty():
				continue
			var summoned := base_data.duplicate(true)
			if hp_override > 0:
				summoned["current_hp"] = hp_override
				summoned["max_hp"] = hp_override
			else:
				var hp_data = summoned.get("hp", null)
				if hp_data == null:
					hp_data = summoned.get("hp_total", null)
				if hp_data is Dictionary:
					summoned["current_hp"] = randi_range(hp_data.get("min", 10), hp_data.get("max", 15))
					summoned["max_hp"] = summoned["current_hp"]
				elif hp_data is int or hp_data is float:
					summoned["current_hp"] = int(hp_data)
					summoned["max_hp"] = int(hp_data)
				else:
					push_error("BattleManager: 소환 적 '%s' HP 데이터 누락" % summoned.get("id", "unknown"))
					summoned["current_hp"] = 1
					summoned["max_hp"] = 1
			if name_override != "":
				summoned["name"] = {"ko": name_override}
			summoned["block"] = 0
			summoned["move_index"] = 0
			summoned["_is_summoned"] = true
			enemies.append(summoned)
			var new_idx := enemies.size() - 1
			enemy_hp_changed.emit(new_idx, summoned["current_hp"], summoned["max_hp"])


func _resolve_effect_target(target_str: String, enemy_target: String) -> String:
	match target_str:
		"player":
			return "player"
		"self":
			return enemy_target
		_:
			return target_str


func can_play_card(card: CardData) -> bool:
	var effective_cost := card.cost
	var detention_stacks := status_effects.get_stacks("player", "구금")
	if detention_stacks > 0:
		effective_cost += detention_stacks
	if _cost_reduce_all_this_turn != 0:
		effective_cost -= _cost_reduce_all_this_turn
	if _next_card_cost_reduce > 0:
		effective_cost -= _next_card_cost_reduce
	effective_cost = maxi(effective_cost, 0)
	if effective_cost > current_qi:
		return false
	if has_class_resource and card.stamina_cost > 0 and card.stamina_cost > current_class_resource:
		return false
	return true


## 클래스 고유 자원의 표시 이름을 반환한다.
func get_class_resource_name() -> String:
	match character_id:
		"mugwan":
			return "氣力"
		"mungwan":
			return "學識"
		_:
			return ""


## 클래스 고유 자원의 UI 색상을 반환한다.
func get_class_resource_color() -> Color:
	match character_id:
		"mugwan":
			return Color(0.9, 0.6, 0.2)  # 주황 (기력)
		"mungwan":
			return Color(0.3, 0.7, 1.0)  # 파랑 (학식)
		_:
			return Color.WHITE


func _check_phase_transition(enemy_index: int) -> void:
	var enemy := enemies[enemy_index]
	var phases: Array = enemy.get("phases", [])
	if phases.is_empty():
		return

	var current_phase_idx: int = enemy.get("current_phase", 0)
	var next_phase_idx := current_phase_idx + 1
	if next_phase_idx >= phases.size():
		return

	var next_phase: Dictionary = phases[next_phase_idx]
	var trigger = next_phase.get("phase_trigger", {})
	if trigger is not Dictionary:
		return

	var trigger_type: String = trigger.get("type", "")
	if trigger_type != "hp_threshold":
		return

	var hp_percent: int = trigger.get("hp_percent", 0)
	if enemy["max_hp"] <= 0:
		return
	var current_hp_percent := int(float(enemy["current_hp"]) / float(enemy["max_hp"]) * 100.0)
	if current_hp_percent > hp_percent:
		return

	# 페이즈 전환 실행
	enemy["current_phase"] = next_phase_idx

	# 새 페이즈의 moves/pattern으로 전환
	if next_phase.has("moves"):
		enemy["moves"] = next_phase["moves"]
	if next_phase.has("move_pattern"):
		enemy["move_pattern"] = next_phase["move_pattern"]
	enemy["move_index"] = 0

	# on_trigger 효과 적용 (버프, 디버프, 대사 등)
	var on_trigger: Array = trigger.get("on_trigger", [])
	var enemy_target := "enemy_%d" % enemy_index
	for effect in on_trigger:
		if effect is not Dictionary:
			continue
		var effect_type: String = effect.get("type", "")
		var target_str: String = effect.get("target", "player")
		var resolved_target := _resolve_effect_target(target_str, enemy_target)

		match effect_type:
			"apply_buff":
				var buff_id: String = effect.get("buff", "")
				var stacks: int = effect.get("stacks", 1)
				if buff_id != "":
					status_effects.apply_effect(resolved_target, buff_id, stacks)
			"apply_debuff":
				var debuff_id: String = effect.get("debuff", "")
				var stacks: int = effect.get("stacks", 1)
				if debuff_id != "":
					status_effects.apply_effect(resolved_target, debuff_id, stacks)
			"cleanse_debuffs":
				status_effects.clear_target(resolved_target)
			"summon":
				# 페이즈 전환 시 소환 (탐관 연합 등)
				_execute_enemy_summon(enemy_index, {"intent": "summon", "summon": effect.get("summon", [])})
			"dialogue":
				# 대사 표시 (시그널로 전달)
				var text: String = effect.get("text", "")
				if text != "":
					passive_triggered.emit("보스", text)


func _get_current_passive(enemy: Dictionary) -> Dictionary:
	# 현재 페이즈의 start_of_turn_passive 반환 (페이즈별 오버라이드 지원)
	var current_phase_idx: int = enemy.get("current_phase", 0)
	var phases: Array = enemy.get("phases", [])
	if not phases.is_empty() and current_phase_idx < phases.size():
		var phase: Dictionary = phases[current_phase_idx]
		if phase.has("start_of_turn_passive_override"):
			return phase["start_of_turn_passive_override"]
		if phase.has("start_of_turn_passive"):
			return phase["start_of_turn_passive"]
	# 페이즈 없으면 적 루트의 패시브
	return enemy.get("start_of_turn_passive", {})


func _apply_battle_start_effect(enemy_index: int, eff: Dictionary) -> void:
	# 전투 시작 시 효과 적용 (소환, 버프, 대사)
	var eff_type: String = eff.get("type", "")
	var enemy_target := "enemy_%d" % enemy_index
	match eff_type:
		"summon":
			_execute_enemy_summon(enemy_index, {"intent": "summon", "summon": eff.get("summon", [])})
		"apply_buff":
			var buff_id: String = eff.get("buff", "")
			if buff_id != "":
				status_effects.apply_effect(enemy_target, buff_id, eff.get("stacks", 1))
		"dialogue":
			var text: String = eff.get("text", "")
			if text != "":
				var boss_name: String = ""
				if enemy_index < enemies.size():
					var name_data = enemies[enemy_index].get("name", {})
					boss_name = name_data.get("ko", "") if name_data is Dictionary else str(name_data)
				passive_triggered.emit(boss_name, text)


func _trigger_ally_death_effects(dead_index: int) -> void:
	# 적 사망 시 다른 살아있는 적들의 on_ally_death_effects 발동
	for i in enemies.size():
		if i == dead_index or enemies[i]["current_hp"] <= 0:
			continue
		var ally_death_effects: Array = enemies[i].get("on_ally_death_effects", [])
		var enemy_target := "enemy_%d" % i
		for eff in ally_death_effects:
			if eff is not Dictionary:
				continue
			match eff.get("type", ""):
				"gain_block":
					var value: int = eff.get("value", 0)
					enemies[i]["block"] += value
					var name_data = enemies[i].get("name", {})
					var enemy_name: String = name_data.get("ko", "적") if name_data is Dictionary else str(name_data)
					passive_triggered.emit(enemy_name, "부하를 잃고 방어도 %d 획득" % value)
					enemy_hp_changed.emit(i, enemies[i]["current_hp"], enemies[i]["max_hp"])
				"apply_buff":
					var buff_id: String = eff.get("buff", "")
					var stacks: int = eff.get("stacks", 1)
					if buff_id != "":
						status_effects.apply_effect(enemy_target, buff_id, stacks)


func _check_minshim_ally_support() -> void:
	# 민심 70+ → 전투 시작 시 백성 지원병 효과 (랜덤 적에게 5피해)
	if not GameManager.run_data:
		return
	var minshim: int = GameManager.run_data.narrative_state.get("minshim", 50)
	if minshim < 70:
		return

	var is_elite: bool = GameManager.run_data.current_node_type == MapData.NodeType.ELITE
	var chance := 0.4 if is_elite else 0.2
	if randf() < chance:
		# 살아있는 랜덤 적에게 5피해
		var alive_indices: Array[int] = []
		for i in enemies.size():
			if enemies[i]["current_hp"] > 0:
				alive_indices.append(i)
		if not alive_indices.is_empty():
			var target_idx: int = alive_indices[randi() % alive_indices.size()]
			var support_dmg := 5
			enemies[target_idx]["current_hp"] -= support_dmg
			enemies[target_idx]["current_hp"] = maxi(enemies[target_idx]["current_hp"], 0)
			enemy_hp_changed.emit(target_idx, enemies[target_idx]["current_hp"], enemies[target_idx]["max_hp"])
			passive_triggered.emit("백성 지원", "민심이 높아 백성이 돕는다! 적에게 %d 피해." % support_dmg)


func _all_enemies_dead() -> bool:
	for enemy in enemies:
		if enemy["current_hp"] > 0:
			return false
	return true


# --- 상태이상 시그널 핸들러 ---

func _on_effect_applied(target: String, effect_id: String, stacks: int) -> void:
	status_effect_changed.emit(target, effect_id, stacks)


func _on_effect_removed(target: String, effect_id: String) -> void:
	status_effect_changed.emit(target, effect_id, 0)


func _on_effect_triggered(target: String, effect_id: String, value: int) -> void:
	# 사망선고 만료: 플레이어 현재 HP의 35% 감소
	if effect_id == "death_countdown" and value == -1 and target == "player":
		var penalty: int = int(player_hp * 0.35)
		penalty = maxi(penalty, 1)
		player_hp -= penalty
		player_hp = maxi(player_hp, 0)
		hp_changed.emit(player_hp, player_max_hp)
		dot_damage_dealt.emit(target, effect_id, penalty)
		if player_hp <= 0:
			# 유물 트리거: 즉사 방지 (R028 불사신 부적)
			if not RelicManager.trigger_on_lethal_damage(self):
				AudioManager.play_sfx_by_key("defeat")
				_change_state(BattleState.BATTLE_LOSE)
				battle_ended.emit(false)
		return
	dot_damage_dealt.emit(target, effect_id, value)


## 카드 ID로 전투용 CardData를 반환한다. 강화 상태를 반영한 복사본.
func _get_battle_card(card_id: String) -> CardData:
	var base: CardData = DataLoader.get_card(card_id)
	if base == null:
		return null
	if GameManager.run_data == null:
		return base

	# 강화 여부 확인
	if not card_id in GameManager.run_data.upgraded_cards:
		return base

	# 강화된 카드: 복사본에 보너스 적용
	var card := base.duplicate_card()
	card.upgraded = true
	# 기본 강화 보너스: 피해 +25%(최소 +2), 방어도 +25%(최소 +2)
	if card.damage > 0:
		card.damage += maxi(ceili(base.damage * 0.25), 2)
	if card.block_value > 0:
		card.block_value += maxi(ceili(base.block_value * 0.25), 2)
	if base.draw_count > 0:
		card.draw_count += 1
	# 약화/취약 강화 보너스: +1 스택
	if base.weaken_stacks > 0:
		card.weaken_stacks += 1
	if base.vulnerable_stacks > 0:
		card.vulnerable_stacks += 1
	return card


# --- 액티브 스킬 ---

## 액티브 스킬 사용 가능 여부를 반환한다.
func can_use_active_skill() -> bool:
	if state != BattleState.PLAYER_ACTION:
		return false
	if active_skill_used:
		return false
	match character_id:
		"dosa":
			# 방술 개방: 전투 시작 시 자동 발동 → 수동 사용 불가
			return false
		"mugwan":
			# 군령 하달: 토큰 수만큼 기 회복
			var effects := status_effects.get_all_effects("player")
			return effects.get("병사_토큰", 0) > 0
		"mungwan":
			# 경연개설: 학식 3 즉시 획득
			return current_class_resource < max_class_resource
		_:
			return false


## 액티브 스킬을 사용한다.
func use_active_skill() -> bool:
	if not can_use_active_skill():
		return false

	active_skill_used = true
	active_skill_available_changed.emit(false)

	match character_id:
		"mugwan":
			# 군령 하달: 보유 병사 토큰 수만큼 기 회복 (최대 3)
			var effects := status_effects.get_all_effects("player")
			var tokens: int = effects.get("병사_토큰", 0)
			var qi_recovered := mini(tokens, 3)
			current_qi += qi_recovered
			qi_changed.emit(current_qi, max_qi)
			passive_triggered.emit("군령 하달", "토큰 %d개 → 기 +%d" % [tokens, qi_recovered])
		"mungwan":
			# 경연개설: 학식 3 즉시 획득
			current_class_resource += 3
			current_class_resource = mini(current_class_resource, max_class_resource)
			class_resource_changed.emit(current_class_resource, max_class_resource)
			passive_triggered.emit("경연개설", "학식 +3")

	return true


## 액티브 스킬 이름을 반환한다.
func get_active_skill_name() -> String:
	match character_id:
		"dosa":
			return "방술 개방"
		"mugwan":
			return "군령 하달"
		"mungwan":
			return "경연개설"
		_:
			return ""
