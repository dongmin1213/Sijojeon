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
	if GameManager.run_data == null:
		return false
	if relic_id in GameManager.run_data.relics:
		return false
	var relic := DataLoader.get_relic(relic_id)
	if relic.is_empty():
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
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
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
					relic_triggered.emit(relic_id, "전투 시작 독 %d 자해" % poison)
			"on_turn_start":
				pass  # 턴 시작마다 처리 (trigger_turn_start에서)
			"passive":
				_handle_passive_relic(relic_id, relic, values, battle_manager)


func _handle_battle_start_relic(relic_id: String, relic: Dictionary, values: Dictionary, battle_manager: BattleManager) -> void:
	# R001 편자: 방어도 5
	if values.has("block"):
		battle_manager.gain_block(values["block"])
		relic_triggered.emit(relic_id, "방어도 +%d" % values["block"])

	# R006 호신검: AP +1 (무관 전용)
	if values.has("ap_bonus_per_battle"):
		battle_manager.max_qi += values["ap_bonus_per_battle"]
		battle_manager.current_qi += values["ap_bonus_per_battle"]
		battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
		relic_triggered.emit(relic_id, "AP +%d" % values["ap_bonus_per_battle"])

	# R009 무당 방울: 영력 +2 (무당 전용, 향후 확장)
	if values.has("spirit_power_on_battle_start"):
		relic_triggered.emit(relic_id, "영력 +%d" % values["spirit_power_on_battle_start"])

	# RS003 필연: 문관 전투 시작 시 학식 2 획득
	if values.has("scholarship_on_battle_start") and battle_manager.has_class_resource and battle_manager.character_id == "mungwan":
		var amount: int = values["scholarship_on_battle_start"]
		battle_manager.current_class_resource += amount
		battle_manager.current_class_resource = mini(battle_manager.current_class_resource, battle_manager.max_class_resource)
		battle_manager.class_resource_changed.emit(battle_manager.current_class_resource, battle_manager.max_class_resource)
		relic_triggered.emit(relic_id, "학식 +%d" % amount)

	# R012 어사마패: 최고 HP 적에게 취약 2
	if values.has("vulnerable_stacks"):
		var stacks: int = values["vulnerable_stacks"]
		var highest_hp_index := _find_highest_hp_enemy(battle_manager)
		if highest_hp_index >= 0:
			var target := "enemy_%d" % highest_hp_index
			battle_manager.status_effects.apply_effect(target, "취약", stacks)
			relic_triggered.emit(relic_id, "적에게 취약 %d 부여" % stacks)

	# R016: 전투 시작 시 독 제거
	if values.has("cleanse_poison_on_battle_start") and values["cleanse_poison_on_battle_start"]:
		battle_manager.status_effects.remove_effect("player", "독")
		relic_triggered.emit(relic_id, "독 제거")

	# R020: 전투 시작 시 방어도
	if values.has("block_on_battle_start"):
		battle_manager.gain_block(values["block_on_battle_start"])
		relic_triggered.emit(relic_id, "방어도 +%d" % values["block_on_battle_start"])

	# R025: 전투마다 공격력 +1 / 최대 기 +1
	if values.has("strength_per_battle"):
		battle_manager.status_effects.apply_effect("player", "strength", values["strength_per_battle"])
		relic_triggered.emit(relic_id, "힘 +%d" % values["strength_per_battle"])
	if values.has("max_qi_per_battle"):
		battle_manager.max_qi += values["max_qi_per_battle"]
		battle_manager.current_qi += values["max_qi_per_battle"]
		battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)

	# RS002: 무관 시작 유물 — 전투 시작 시 토큰 생성
	if values.has("tokens") and battle_manager.character_id == "mugwan":
		battle_manager.status_effects.apply_effect("player", "병사_토큰", values["tokens"])
		relic_triggered.emit(relic_id, "병사 토큰 +%d" % values["tokens"])


func _handle_passive_relic(_relic_id: String, _relic: Dictionary, values: Dictionary, battle_manager: BattleManager) -> void:
	# R010 각궁: 전투 시작 화살 +2 (궁수 전용, 향후 확장)
	if values.has("arrows_on_battle_start"):
		relic_triggered.emit(_relic_id, "화살 +%d" % values["arrows_on_battle_start"])


func trigger_turn_start(battle_manager: BattleManager) -> void:
	## 매 턴 시작 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "on_turn_start" or trigger == "turn_start":
			# R015 삼족오 깃털: AP +1
			if values.has("ap_per_turn_bonus"):
				battle_manager.current_qi += values["ap_per_turn_bonus"]
				battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
				relic_triggered.emit(relic_id, "턴 시작 AP +%d" % values["ap_per_turn_bonus"])
			# R017: 턴 시작 시 방어도
			if values.has("block_per_turn"):
				battle_manager.gain_block(values["block_per_turn"])
				relic_triggered.emit(relic_id, "방어도 +%d" % values["block_per_turn"])


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
				relic_triggered.emit(relic_id, "골드 +%d" % values["gold_on_victory"])


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
				relic_triggered.emit(relic_id, "체력 +%d 회복" % heal)
			# R024: 엘리트 승리 시 골드
			if values.has("gold_on_elite_victory"):
				GameManager.run_data.gold += values["gold_on_elite_victory"]
				relic_triggered.emit(relic_id, "골드 +%d" % values["gold_on_elite_victory"])


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
				relic_triggered.emit(relic_id, "체력 %d%% 회복 (+%d)" % [percent, heal])


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
					relic_triggered.emit(relic_id, "골드 +%d (%d/%d회)" % [gold, count + 1, max_act])


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
				relic_triggered.emit(relic_id, "셔플 드로우 +%d" % values["draw_on_shuffle"])


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
				relic_triggered.emit(relic_id, "기 +%d" % values["qi_on_kill"])


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
				relic_triggered.emit(relic_id, "기 +%d" % values["qi_on_exhaust"])


func trigger_on_sijo_milestone(battle_manager: BattleManager, filled_count: int) -> void:
	## 시조 슬롯 마일스톤 달성 시 발동하는 유물 효과를 처리한다.
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		# R019: 시조 초장 완성 (2칸) 시 기 +1
		if trigger == "sijo_milestone_2" and filled_count >= 2:
			if values.has("extra_qi_on_sijo_chojang"):
				battle_manager.current_qi += values["extra_qi_on_sijo_chojang"]
				battle_manager.current_qi = mini(battle_manager.current_qi, battle_manager.max_qi)
				battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
				relic_triggered.emit(relic_id, "초장 완성 기 +%d" % values["extra_qi_on_sijo_chojang"])


func trigger_on_sijo_complete(battle_manager: BattleManager) -> int:
	## 시조 완성 시 발동하는 유물 효과를 처리한다. 추가 드로우 수를 반환.
	var extra_draw := 0
	for relic_id in get_owned_relics():
		var relic := DataLoader.get_relic(relic_id)
		var trigger: String = relic.get("trigger", "")
		var values: Dictionary = relic.get("values", {})

		if trigger == "sijo_complete":
			# R023: 시조 완성 시 추가 드로우
			if values.has("extra_draw_on_sijo_complete"):
				extra_draw += values["extra_draw_on_sijo_complete"]
				relic_triggered.emit(relic_id, "시조 완성 드로우 +%d" % values["extra_draw_on_sijo_complete"])
	return extra_draw


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
	var name_data = relic.get("name", {})
	if name_data is Dictionary:
		return name_data.get("ko", relic_id)
	return str(name_data)


func get_relic_description(relic_id: String) -> String:
	var relic := DataLoader.get_relic(relic_id)
	return relic.get("effect_description", "")


func get_relic_rarity_color(relic_id: String) -> Color:
	var relic := DataLoader.get_relic(relic_id)
	var rarity: int = relic.get("rarity", 1)
	match rarity:
		1: return Color("#aaaaaa")
		2: return Color("#4a90d9")
		3: return Color("#f5c518")
		4: return Color("#e94f37")
		_: return Color.WHITE
