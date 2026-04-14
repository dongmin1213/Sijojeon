extends Node

## 유물(부적) 시스템을 관리하는 오토로드 싱글톤.
## 유물 획득, 효과 트리거, 보상 롤링을 처리한다.

# 유물 발동 관련 시그널
signal relic_acquired(relic_id: String)
signal relic_triggered(relic_id: String, effect_description: String)

# 런당 유물별 발동 횟수 추적 (max_activations_per_run용)
var _activation_counts: Dictionary = {}


func _ready() -> void:
	pass


# --- 유물 획득 ---

func acquire_relic(relic_id: String) -> bool:
	## 유물을 획득하여 run_data에 추가한다. 이미 보유 시 false.
	if relic_id.is_empty():
		push_error("RelicManager.acquire_relic: relic_id가 비어있음")
		return false
	if GameManager.run_data == null:
		push_warning("RelicManager.acquire_relic: run_data가 null — 런 밖에서 호출됨")
		return false
	if relic_id in GameManager.run_data.relics:
		return false
	var relic := DataLoader.get_relic(relic_id)
	if relic.is_empty():
		push_warning("RelicManager.acquire_relic: DataLoader에서 유물 데이터 로드 실패 — relic_id=%s" % relic_id)
		return false
	GameManager.run_data.relics.append(relic_id)
	relic_acquired.emit(relic_id)
	return true


func has_relic(relic_id: String) -> bool:
	if GameManager.run_data == null:
		return false
	return relic_id in GameManager.run_data.relics


func get_owned_relics() -> Array[String]:
	if GameManager.run_data == null:
		return []
	return GameManager.run_data.relics


# --- 유물 보상 롤링 ---

func roll_relic_reward(source: String) -> String:
	## source별 드롭 가중치로 유물 1개를 롤링한다.
	## source: "elite", "event", "shop", "boss"
	## 반환: 유물 ID 또는 빈 문자열 (획득 가능 유물 없음)
	if GameManager.run_data == null:
		return ""

	var character_id: String = GameManager.run_data.character_id
	var owned: Array[String] = GameManager.run_data.relics
	var available := DataLoader.get_available_relics(owned, character_id)
	if available.is_empty():
		return ""

	# 희귀도별 가중치 합산
	var rarity_table := DataLoader.get_relic_rarity_table()
	var weighted_pool: Array[Dictionary] = []
	for relic in available:
		var rarity: int = relic.get("rarity", 1)
		var rarity_key := "%d_%s" % [rarity, _rarity_name(rarity)]
		var weights: Dictionary = rarity_table.get(rarity_key, {}).get("drop_weight", {})
		var weight: int = weights.get(source, 0)
		if weight > 0:
			weighted_pool.append({"relic": relic, "weight": weight})

	if weighted_pool.is_empty():
		return ""

	# 가중치 기반 랜덤 선택
	var total_weight := 0
	for entry in weighted_pool:
		total_weight += entry["weight"]

	var roll := randi() % total_weight
	var cumulative := 0
	for entry in weighted_pool:
		cumulative += entry["weight"]
		if roll < cumulative:
			return entry["relic"].get("id", "")

	return weighted_pool[-1]["relic"].get("id", "")


func _rarity_name(rarity: int) -> String:
	match rarity:
		1: return "common"
		2: return "uncommon"
		3: return "rare"
		4: return "legendary"
		_: return "common"


# --- 유물 효과 트리거 ---

func trigger_battle_start(battle_manager: BattleManager) -> void:
	## 전투 시작 시 발동하는 유물 효과를 처리한다.
	if battle_manager == null:
		push_error("RelicManager.trigger_battle_start: battle_manager가 null")
		return
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		if relic.is_empty():
			push_warning("RelicManager.trigger_battle_start: 유물 데이터 없음 — %s" % relic_id)
			continue
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		match trigger:
			"battle_start":
				_handle_battle_start_relic(relic_id, relic, values, battle_manager)
			"dual":
				# R014 저주받은 투구: 전투 시작 시 자기 독
				if values.has("self_poison_on_battle_start"):
					var poison: int = values["self_poison_on_battle_start"]
					battle_manager.status_effects.apply_effect("player", "독", poison)
					relic_triggered.emit(relic_id, tr("RELIC_POISON_SELF_FMT") % poison)
			"on_turn_start":
				pass  # 턴 시작마다 처리 (trigger_turn_start에서)
			"passive":
				_handle_passive_relic(relic_id, relic, values, battle_manager)


func _handle_battle_start_relic(relic_id: String, relic: Dictionary, values: Dictionary, battle_manager: BattleManager) -> void:
	# R001 편자: 방어도 5
	if values.has("block"):
		battle_manager.gain_block(values["block"])
		relic_triggered.emit(relic_id, tr("RELIC_BLOCK_FMT") % values["block"])

	# R006 호신검: AP +1 (무관 전용)
	if values.has("ap_bonus_per_battle"):
		battle_manager.max_qi += values["ap_bonus_per_battle"]
		battle_manager.current_qi += values["ap_bonus_per_battle"]
		battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
		relic_triggered.emit(relic_id, "AP +%d" % values["ap_bonus_per_battle"])

	# R012 어사마패: 최고 HP 적에게 취약 2
	if values.has("vulnerable_stacks"):
		var stacks: int = values["vulnerable_stacks"]
		var highest_hp_index := _find_highest_hp_enemy(battle_manager)
		if highest_hp_index >= 0:
			var target := "enemy_%d" % highest_hp_index
			battle_manager.status_effects.apply_effect(target, "취약", stacks)
			relic_triggered.emit(relic_id, tr("RELIC_VULN_ENEMY_FMT") % stacks)

	# R016: 전투 시작 시 독 제거
	if values.has("cleanse_poison_on_battle_start") and values["cleanse_poison_on_battle_start"]:
		battle_manager.status_effects.remove_effect("player", "독")
		relic_triggered.emit(relic_id, tr("RELIC_CURE_POISON"))

	# R020: 전투 시작 시 방어도
	if values.has("block_on_battle_start"):
		battle_manager.gain_block(values["block_on_battle_start"])
		relic_triggered.emit(relic_id, tr("RELIC_BLOCK_FMT") % values["block_on_battle_start"])

	# R025: 전투마다 공격력 +1 / 최대 기 +1
	if values.has("strength_per_battle"):
		battle_manager.status_effects.apply_effect("player", "strength", values["strength_per_battle"])
		relic_triggered.emit(relic_id, tr("RELIC_STRENGTH_FMT") % values["strength_per_battle"])
	if values.has("max_qi_per_battle"):
		battle_manager.max_qi += values["max_qi_per_battle"]
		battle_manager.current_qi += values["max_qi_per_battle"]
		battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)



func _handle_passive_relic(_relic_id: String, _relic: Dictionary, values: Dictionary, battle_manager: BattleManager) -> void:
	# R010 각궁: 전투 시작 화살 +2 (궁수 전용, 향후 확장)
	if values.has("arrows_on_battle_start"):
		relic_triggered.emit(_relic_id, tr("RELIC_ARROWS_FMT") % values["arrows_on_battle_start"])


func trigger_turn_start(battle_manager: BattleManager) -> void:
	## 매 턴 시작 시 발동하는 유물 효과를 처리한다.
	if battle_manager == null:
		push_error("RelicManager.trigger_turn_start: battle_manager가 null")
		return
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		if relic.is_empty():
			continue
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_turn_start" or trigger == "turn_start":
			# R015 삼족오 깃털: AP +1
			if values.has("ap_per_turn_bonus"):
				battle_manager.current_qi += values["ap_per_turn_bonus"]
				battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
				relic_triggered.emit(relic_id, tr("RELIC_TURN_AP_FMT") % values["ap_per_turn_bonus"])
			# R017: 턴 시작 시 방어도
			if values.has("block_per_turn"):
				battle_manager.gain_block(values["block_per_turn"])
				relic_triggered.emit(relic_id, tr("RELIC_TURN_BLOCK_FMT") % values["block_per_turn"])


func trigger_combat_victory() -> void:
	## 전투 승리 시 발동하는 유물 효과를 처리한다.
	if GameManager.run_data == null:
		return
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_combat_victory":
			# R003 행운의 엽전: 골드 +10
			if values.has("gold_on_victory"):
				GameManager.run_data.gold += values["gold_on_victory"]
				relic_triggered.emit(relic_id, tr("RELIC_GOLD_FMT") % values["gold_on_victory"])


func trigger_elite_victory() -> void:
	## 정예 전투 승리 시 발동하는 유물 효과를 처리한다.
	if GameManager.run_data == null:
		return
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_elite_victory":
			# R005 홍삼 뿌리: 체력 +8
			if values.has("heal_on_elite_victory"):
				var heal: int = values["heal_on_elite_victory"]
				GameManager.run_data.current_hp = mini(
					GameManager.run_data.current_hp + heal,
					GameManager.run_data.max_hp
				)
				relic_triggered.emit(relic_id, tr("RELIC_HEAL_FMT") % heal)
			# R024: 엘리트 승리 시 골드
			if values.has("gold_on_elite_victory"):
				GameManager.run_data.gold += values["gold_on_elite_victory"]
				relic_triggered.emit(relic_id, tr("RELIC_GOLD_FMT") % values["gold_on_elite_victory"])


func trigger_boss_enter() -> void:
	## 보스 전투 진입 시 발동하는 유물 효과를 처리한다.
	if GameManager.run_data == null:
		return
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_enter_boss_combat":
			# R013 만파식적: 최대 HP의 25% 회복
			if values.has("heal_percent_on_boss_enter"):
				var percent: int = values["heal_percent_on_boss_enter"]
				var heal: int = GameManager.run_data.max_hp * percent / 100
				GameManager.run_data.current_hp = mini(
					GameManager.run_data.current_hp + heal,
					GameManager.run_data.max_hp
				)
				relic_triggered.emit(relic_id, tr("RELIC_HEAL_PERCENT_FMT") % [percent, heal])


func trigger_enter_shop() -> void:
	## 상점 입장 시 발동하는 유물 효과를 처리한다.
	if GameManager.run_data == null:
		return
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_enter_shop":
			# R011 상단 장부: 골드 +35 (런당 최대 2회)
			if values.has("gold_on_enter_shop"):
				var max_act: int = values.get("max_activations_per_run", 999)
				var count: int = _activation_counts.get(relic_id, 0)
				if count < max_act:
					var gold: int = values["gold_on_enter_shop"]
					GameManager.run_data.gold += gold
					_activation_counts[relic_id] = count + 1
					relic_triggered.emit(relic_id, tr("RELIC_GOLD_PER_ACT_FMT") % [gold, count + 1, max_act])


func trigger_on_attack_card_played(battle_manager: BattleManager, target_enemy_index: int) -> void:
	## 공격 카드 사용 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "dual":
			# R014 저주받은 투구: 공격 시 출혈 +1
			if values.has("bleed_on_attack"):
				var stacks: int = values["bleed_on_attack"]
				if target_enemy_index >= 0 and target_enemy_index < battle_manager.enemies.size():
					var target := "enemy_%d" % target_enemy_index
					battle_manager.status_effects.apply_effect(target, "출혈", stacks)


func trigger_on_buff_apply(buff_duration: int) -> int:
	## 버프 적용 시 지속시간 수정자를 반환한다.
	var bonus := 0
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_buff_apply_to_self":
			# R002 평안 부적: 버프 지속 턴 +1
			if values.has("buff_duration_bonus"):
				bonus += values["buff_duration_bonus"]
	return buff_duration + bonus


func trigger_on_deck_shuffle(battle_manager: BattleManager) -> void:
	## 덱 셔플 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_deck_shuffle":
			# R004 봉황 깃털: 무료 드로우 +1
			if values.has("draw_on_shuffle"):
				battle_manager.draw_cards(values["draw_on_shuffle"])
				relic_triggered.emit(relic_id, tr("RELIC_SHUFFLE_DRAW_FMT") % values["draw_on_shuffle"])


func trigger_on_first_card_play_per_turn(battle_manager: BattleManager) -> void:
	## 턴당 첫 번째 카드 사용 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		if relic.is_empty():
			continue
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_first_card_play_per_turn":
			# R007 사서: 카드 1장 추가 드로우
			if values.has("draw_on_first_card_per_turn"):
				battle_manager.draw_cards(values["draw_on_first_card_per_turn"])
				relic_triggered.emit(relic_id, tr("RELIC_FIRST_CARD_DRAW_FMT") % values["draw_on_first_card_per_turn"])


func trigger_on_apply_poison(target: String, stacks: int) -> int:
	## 독 부여 시 추가 스택 보너스를 반환한다.
	var bonus := 0
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		if relic.is_empty():
			continue
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_apply_poison":
			# R008 동의보감: 독 스택 +1
			if values.has("poison_stack_bonus"):
				bonus += values["poison_stack_bonus"]
				relic_triggered.emit(relic_id, tr("RELIC_POISON_STACK_FMT") % values["poison_stack_bonus"])
	return stacks + bonus


func trigger_boss_battle_start(battle_manager: BattleManager) -> void:
	## 보스 전투 시작 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		if relic.is_empty():
			continue
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "boss_battle_start":
			# R027 왕의 옥새: 방어도 +15
			if values.has("block_on_boss_start"):
				battle_manager.gain_block(values["block_on_boss_start"])
				relic_triggered.emit(relic_id, tr("RELIC_BOSS_BLOCK_FMT") % values["block_on_boss_start"])


func trigger_on_lethal_damage(battle_manager: BattleManager) -> bool:
	## 치명적 피해 시 즉사 방지 유물을 확인한다. true 반환 시 생존.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		if relic.is_empty():
			continue
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_lethal_damage":
			# R028 불사신 부적: HP 1로 생존 (런당 1회)
			if values.has("death_prevention"):
				var max_uses: int = values.get("uses_per_run", 1)
				var count: int = _activation_counts.get(relic_id, 0)
				if count < max_uses:
					_activation_counts[relic_id] = count + 1
					battle_manager.player_hp = 1
					battle_manager.hp_changed.emit(battle_manager.player_hp, battle_manager.player_max_hp)
					relic_triggered.emit(relic_id, tr("RELIC_DEATH_PREVENT_FMT") % [count + 1, max_uses])
					return true
	return false


func trigger_on_formation_card_play(battle_manager: BattleManager) -> void:
	## 진형 카드 사용 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		if relic.is_empty():
			continue
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_formation_card_play":
			pass


func trigger_on_scholarship_exhaust(battle_manager: BattleManager, consumed: int) -> void:
	## 학식 전소 시 발동하는 유물 효과를 처리한다.
	if consumed <= 0:
		return
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		if relic.is_empty():
			continue
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_scholarship_exhaust":
			# RW001 어진: HP 최대치의 5% 회복
			if values.has("hp_percent_on_scholarship_exhaust"):
				var percent: int = values["hp_percent_on_scholarship_exhaust"]
				var heal: int = battle_manager.player_max_hp * percent / 100
				heal = maxi(heal, 1)
				battle_manager.player_hp += heal
				battle_manager.player_hp = mini(battle_manager.player_hp, battle_manager.player_max_hp)
				battle_manager.hp_changed.emit(battle_manager.player_hp, battle_manager.player_max_hp)
				relic_triggered.emit(relic_id, tr("RELIC_STUDY_BURN_HEAL_FMT") % [heal, percent])


func trigger_on_spell_card_play(battle_manager: BattleManager) -> void:
	## 주문 카드 사용 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		if relic.is_empty():
			continue
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_spell_card_play":
			# RD001 선단: 기 +1
			if values.has("extra_qi_on_spell_card"):
				var amount: int = values["extra_qi_on_spell_card"]
				battle_manager.current_qi += amount
				battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
				relic_triggered.emit(relic_id, tr("RELIC_SPELL_QI_FMT") % amount)


func trigger_on_summon_token_death(battle_manager: BattleManager) -> void:
	## 소환 토큰 소멸 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		if relic.is_empty():
			continue
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_summon_token_death":
			# RD002 음양패: 카드 1장 드로우
			if values.has("draw_on_summon_death"):
				battle_manager.draw_cards(values["draw_on_summon_death"])
				relic_triggered.emit(relic_id, tr("RELIC_SUMMON_DEATH_DRAW_FMT") % values["draw_on_summon_death"])


func trigger_on_wildcard_play(battle_manager: BattleManager) -> void:
	## 와일드카드 사용 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		if relic.is_empty():
			continue
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_wildcard_play":
			# RS005 장단 북: 기 +1
			if values.has("qi_on_wildcard"):
				var amount: int = values["qi_on_wildcard"]
				battle_manager.current_qi += amount
				battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
				relic_triggered.emit(relic_id, tr("RELIC_WILDCARD_QI_FMT") % amount)


func reset_run_state() -> void:
	## 런 시작 시 발동 횟수 초기화
	_activation_counts.clear()


# --- 유틸 ---

func trigger_on_enemy_kill(battle_manager: BattleManager) -> void:
	## 적 제거 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_kill_enemy":
			# R018: 적 제거 시 기 +1
			if values.has("qi_on_kill"):
				battle_manager.current_qi += values["qi_on_kill"]
				battle_manager.current_qi = mini(battle_manager.current_qi, battle_manager.max_qi)
				battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
				relic_triggered.emit(relic_id, tr("RELIC_QI_FMT") % values["qi_on_kill"])


func trigger_on_card_exhaust(battle_manager: BattleManager) -> void:
	## 카드 소멸 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_card_exhaust":
			# R021: 카드 소멸 시 기 +1
			if values.has("qi_on_exhaust"):
				battle_manager.current_qi += values["qi_on_exhaust"]
				battle_manager.current_qi = mini(battle_manager.current_qi, battle_manager.max_qi)
				battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
				relic_triggered.emit(relic_id, tr("RELIC_QI_FMT") % values["qi_on_exhaust"])


func get_card_removal_discount() -> int:
	## 카드 제거 할인 금액을 반환한다.
	var discount := 0
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "passive":
			# R022: 카드 제거 비용 할인
			if values.has("card_removal_discount"):
				discount += values["card_removal_discount"]
	return discount


func _find_highest_hp_enemy(battle_manager: BattleManager) -> int:
	var best_index := -1
	var best_hp := 0
	for i in battle_manager.enemies.size():
		var hp: int = battle_manager.enemies[i].get("current_hp", 0)
		if hp > best_hp:
			best_hp = hp
			best_index = i
	return best_index


func get_relic_display_name(relic_id: String) -> String:
	var relic := DataLoader.get_relic(relic_id)
	if relic.is_empty():
		return relic_id
	return TranslationManager.trd_name(relic)


func get_relic_description(relic_id: String) -> String:
	var relic := DataLoader.get_relic(relic_id)
	return TranslationManager.trd(relic, "effect_description", "")


func get_relic_rarity_color(relic_id: String) -> Color:
	var relic := DataLoader.get_relic(relic_id)
	var rarity: int = relic.get("rarity", 1)
	match rarity:
		1: return Color("#aaaaaa")
		2: return Color("#4a90d9")
		3: return Color("#f5c518")
		4: return Color("#e94f37")
		_: return Color.WHITE
