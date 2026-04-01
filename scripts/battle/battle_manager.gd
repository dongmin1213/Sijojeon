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
const MAX_STAMINA := 10  # 기력 최대치

var state: BattleState = BattleState.BATTLE_START
var current_qi: int = 0
var max_qi: int = STARTING_QI
var turn_number: int = 0

# 기력 (무관 전용 자원) — 턴 간 유지, 전투 시작 시 0
var current_stamina: int = 0
var is_mugwan: bool = false  # 무관 클래스 여부

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
signal stamina_changed(current: int, max_val: int)


func _ready() -> void:
	# StatusEffectManager 자동 생성
	if status_effects == null:
		status_effects = StatusEffectManager.new()
		add_child(status_effects)
		status_effects.effect_applied.connect(_on_effect_applied)
		status_effects.effect_removed.connect(_on_effect_removed)
		status_effects.effect_triggered.connect(_on_effect_triggered)


func start_battle(deck: Array[String], enemy_data: Array[Dictionary], hp: int, max_hp: int, qi: int, character_id: String = "") -> void:
	player_hp = hp
	player_max_hp = max_hp
	max_qi = qi
	turn_number = 0
	player_block = 0
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()

	# 기력 초기화 (무관 전용)
	is_mugwan = character_id == "mugwan"
	current_stamina = 0
	if is_mugwan:
		stamina_changed.emit(current_stamina, MAX_STAMINA)

	# 상태이상 초기화
	status_effects.clear_all()

	# 덱 셔플
	draw_pile = deck.duplicate()
	_shuffle_draw_pile()

	# 적 초기화
	enemies.clear()
	for e in enemy_data:
		var enemy := e.duplicate(true)
		var hp_data = enemy.get("hp", {})
		if hp_data is Dictionary:
			enemy["current_hp"] = randi_range(hp_data.get("min", 20), hp_data.get("max", 30))
			enemy["max_hp"] = enemy["current_hp"]
		elif hp_data is int:
			enemy["current_hp"] = hp_data
			enemy["max_hp"] = hp_data
		enemy["block"] = 0
		enemy["move_index"] = 0
		enemies.append(enemy)

	# 시조 시스템 초기화
	if sijo_system:
		sijo_system.reset()

	_change_state(BattleState.BATTLE_START)
	begin_player_turn()


func begin_player_turn() -> void:
	turn_number += 1

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
		return false
	if hand_index < 0 or hand_index >= hand.size():
		return false

	var card_id: String = hand[hand_index]
	var card: CardData = DataLoader.get_card(card_id)
	if card == null:
		return false

	# 기(氣) 확인
	if card.cost > current_qi:
		return false

	# 기력 확인 (무관 전용)
	if is_mugwan and card.stamina_cost > 0 and card.stamina_cost > current_stamina:
		return false

	# 기 소비
	current_qi -= card.cost
	qi_changed.emit(current_qi, max_qi)

	# 기력 소비 (무관 전용)
	if is_mugwan and card.stamina_cost > 0:
		current_stamina -= card.stamina_cost
		current_stamina = maxi(current_stamina, 0)
		stamina_changed.emit(current_stamina, MAX_STAMINA)

	# 시조 슬롯 시도
	if sijo_system:
		sijo_system.try_fill_slot(card.beat, card_id)

	# 카드 효과 적용
	_resolve_card_effect(card, target_enemy_index)

	# 손패에서 제거 → 버린 카드로
	hand.remove_at(hand_index)
	discard_pile.append(card_id)
	hand_changed.emit(hand)

	# 전투 종료 확인 (적 사망)
	if _all_enemies_dead():
		_change_state(BattleState.BATTLE_WIN)
		battle_ended.emit(true)

	return true


func end_player_turn() -> void:
	if state != BattleState.PLAYER_ACTION:
		return

	_change_state(BattleState.PLAYER_TURN_END)

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

		# 적 디버프 기간 감소
		status_effects.process_turn_end(enemy_target)

		var intent := _get_enemy_intent(i)
		_execute_enemy_action(i, intent)

		# 행동 인덱스 진행
		var pattern = enemy.get("move_pattern", {})
		var sequence: Array = pattern.get("sequence", []) if pattern is Dictionary else []
		var total: int = sequence.size() if not sequence.is_empty() else enemy.get("moves", []).size()
		if total > 0:
			enemy["move_index"] = (enemy["move_index"] + 1) % total

	# 전투 종료 확인
	if player_hp <= 0:
		_change_state(BattleState.BATTLE_LOSE)
		battle_ended.emit(false)
		return

	if _all_enemies_dead():
		_change_state(BattleState.BATTLE_WIN)
		battle_ended.emit(true)
		return

	# 다음 플레이어 턴
	begin_player_turn()


func draw_cards(count: int) -> void:
	for i in count:
		if draw_pile.is_empty():
			_reshuffle_discard()
		if draw_pile.is_empty():
			break
		var card_id: String = draw_pile.pop_back()
		hand.append(card_id)
		card_drawn.emit(card_id)
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


func gain_block(amount: int) -> void:
	player_block += amount
	block_changed.emit(player_block)

	# 출혈: 방어도 획득 시 출혈 스택만큼 추가 피해
	var bleed_damage := status_effects.calculate_bleed_on_block("player", amount)
	if bleed_damage > 0:
		player_hp -= bleed_damage
		player_hp = maxi(player_hp, 0)
		hp_changed.emit(player_hp, player_max_hp)


func deal_damage_to_enemy(enemy_index: int, amount: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
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
		qi_changed.emit(current_qi, max_qi)

	# 카드 드로우
	if card.draw_count > 0:
		draw_cards(card.draw_count)

	# 기력 획득 (무관 전용)
	if is_mugwan and card.stamina_gain > 0:
		current_stamina += card.stamina_gain
		current_stamina = mini(current_stamina, MAX_STAMINA)
		stamina_changed.emit(current_stamina, MAX_STAMINA)


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
		"buff":
			_apply_intent_effects(enemy_index, intent)
		"debuff":
			_apply_intent_effects(enemy_index, intent)


func _execute_enemy_attack(enemy_index: int, intent: Dictionary) -> void:
	var base_damage: int = intent.get("damage", 0)
	var times: int = intent.get("times", 1)
	var enemy_target := "enemy_%d" % enemy_index

	# 적 공격력 수정 (strength, 약화)
	var final_damage := status_effects.calculate_outgoing_damage(enemy_target, base_damage)

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


func _resolve_effect_target(target_str: String, enemy_target: String) -> String:
	match target_str:
		"player":
			return "player"
		"self":
			return enemy_target
		_:
			return target_str


func can_play_card(card: CardData) -> bool:
	if card.cost > current_qi:
		return false
	if is_mugwan and card.stamina_cost > 0 and card.stamina_cost > current_stamina:
		return false
	return true


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
	dot_damage_dealt.emit(target, effect_id, value)
