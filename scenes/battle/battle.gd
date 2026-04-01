extends Control

## 전투 씬 메인 스크립트. UI와 BattleManager를 연결한다.

@onready var hp_label: Label = $BattleHUD/PlayerInfo/HPLabel
@onready var qi_label: Label = $BattleHUD/PlayerInfo/QiLabel
@onready var block_label: Label = $BattleHUD/PlayerInfo/BlockLabel
@onready var turn_label: Label = $BattleHUD/TurnLabel
@onready var card_hand: CardHand = $HandArea/CardHand
@onready var enemy_container: HBoxContainer = $EnemyArea/EnemyContainer
@onready var sijo_container: HBoxContainer = $SijoArea/SijoContainer
@onready var end_turn_button: Button = $BattleHUD/EndTurnButton
@onready var draw_pile_label: Label = $BattleHUD/DeckInfo/DrawPileLabel
@onready var discard_pile_label: Label = $BattleHUD/DeckInfo/DiscardPileLabel

var battle_manager: BattleManager
var sijo_system: SijoSystem

# 시조 슬롯 UI 라벨
var sijo_slot_labels: Array[Label] = []


func _ready() -> void:
	# 매니저 초기화
	battle_manager = BattleManager.new()
	sijo_system = SijoSystem.new()
	battle_manager.sijo_system = sijo_system
	add_child(battle_manager)
	add_child(sijo_system)

	# 시그널 연결
	battle_manager.hand_changed.connect(_on_hand_changed)
	battle_manager.qi_changed.connect(_on_qi_changed)
	battle_manager.hp_changed.connect(_on_hp_changed)
	battle_manager.block_changed.connect(_on_block_changed)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.enemy_hp_changed.connect(_on_enemy_hp_changed)
	battle_manager.enemy_intent_shown.connect(_on_enemy_intent_shown)
	battle_manager.battle_ended.connect(_on_battle_ended)
	sijo_system.slot_filled.connect(_on_sijo_slot_filled)
	sijo_system.sijo_completed.connect(_on_sijo_completed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# CardHand 시그널 연결
	card_hand.card_played.connect(_on_card_played)

	# 상태이상 시그널 연결
	battle_manager.status_effect_changed.connect(_on_status_effect_changed)

	# 시조 슬롯 UI 초기화
	_init_sijo_slots()

	# 전투 시작
	_start_battle()


func _start_battle() -> void:
	if GameManager.run_data == null:
		return

	var rd := GameManager.run_data
	var deck := rd.deck.duplicate()

	# TODO: 적 선택 로직 (현재는 임시로 첫 번째 적 사용)
	var enemy_data: Array[Dictionary] = []
	var test_enemy := DataLoader.get_enemy("E001")
	if not test_enemy.is_empty():
		enemy_data.append(test_enemy)

	battle_manager.start_battle(deck, enemy_data, rd.current_hp, rd.max_hp, rd.qi_per_turn)


func _init_sijo_slots() -> void:
	sijo_slot_labels.clear()
	for child in sijo_container.get_children():
		child.queue_free()

	for i in SijoSystem.PATTERN.size():
		var label := Label.new()
		label.text = "[%d]" % SijoSystem.PATTERN[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(120, 60)
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		sijo_container.add_child(label)
		sijo_slot_labels.append(label)


func _refresh_hand_ui() -> void:
	var sijo_beat := sijo_system.get_next_required_beat() if sijo_system else -1
	card_hand.update_hand(battle_manager.hand, battle_manager.current_qi, sijo_beat)

	# 덱 정보 갱신
	draw_pile_label.text = "드로우: %d" % battle_manager.draw_pile.size()
	discard_pile_label.text = "버림: %d" % battle_manager.discard_pile.size()


func _update_enemy_ui() -> void:
	for child in enemy_container.get_children():
		child.queue_free()

	for i in battle_manager.enemies.size():
		var enemy: Dictionary = battle_manager.enemies[i]
		if enemy["current_hp"] <= 0:
			continue
		var name_data = enemy.get("name", {})
		var enemy_name: String = ""
		if name_data is Dictionary:
			enemy_name = name_data.get("ko", "적")
		elif name_data is String:
			enemy_name = name_data

		var panel := PanelContainer.new()
		var vbox := VBoxContainer.new()
		var name_label := Label.new()
		name_label.text = enemy_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var hp_lbl := Label.new()
		hp_lbl.text = "HP: %d/%d" % [enemy["current_hp"], enemy["max_hp"]]
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# 적 인텐트 표시
		var intent_label := Label.new()
		intent_label.name = "IntentLabel"
		intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		intent_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		var intent := battle_manager._get_enemy_intent(i)
		intent_label.text = _format_intent(intent)

		# 방어도 표시
		var block_val: int = enemy.get("block", 0)
		var enemy_block_label := Label.new()
		enemy_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enemy_block_label.text = "방어: %d" % block_val
		enemy_block_label.visible = block_val > 0

		# 적 상태이상 표시
		var enemy_target := "enemy_%d" % i
		var status_label := Label.new()
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.add_theme_font_size_override("font_size", 12)
		status_label.text = _format_status_effects(enemy_target)
		status_label.visible = not status_label.text.is_empty()

		vbox.add_child(name_label)
		vbox.add_child(hp_lbl)
		vbox.add_child(enemy_block_label)
		vbox.add_child(status_label)
		vbox.add_child(intent_label)
		panel.add_child(vbox)
		panel.custom_minimum_size = Vector2(200, 180)
		enemy_container.add_child(panel)


func _format_intent(intent: Dictionary) -> String:
	var intent_type: String = intent.get("intent", intent.get("type", ""))
	var name_str: String = intent.get("name", "")
	match intent_type:
		"attack", "attack_debuff":
			var dmg: int = intent.get("damage", 0)
			var times: int = intent.get("times", 1)
			if times > 1:
				return "%s %d×%d" % [name_str, dmg, times] if name_str else "공격 %d×%d" % [dmg, times]
			return "%s %d" % [name_str, dmg] if name_str else "공격 %d" % dmg
		"defend", "defend_buff", "buff_defend":
			var blk: int = intent.get("block", 0)
			return "%s %d" % [name_str, blk] if name_str else "방어 %d" % blk
		"buff":
			return name_str if name_str else "강화"
		"debuff":
			return name_str if name_str else "디버프"
		_:
			return name_str if name_str else "???"


# --- 시그널 핸들러 ---

func _on_hand_changed(_new_hand: Array[String]) -> void:
	_refresh_hand_ui()
	_update_enemy_ui()


func _on_qi_changed(current: int, max_val: int) -> void:
	qi_label.text = "氣: %d/%d" % [current, max_val]
	_refresh_hand_ui()


func _on_hp_changed(current: int, max_val: int) -> void:
	hp_label.text = "HP: %d/%d" % [current, max_val]


func _on_block_changed(new_block: int) -> void:
	block_label.text = "방어: %d" % new_block
	block_label.visible = new_block > 0


func _on_turn_started(turn: int) -> void:
	turn_label.text = "%d턴" % turn


func _on_enemy_hp_changed(_enemy_index: int, _current: int, _max_val: int) -> void:
	_update_enemy_ui()


func _on_enemy_intent_shown(_enemy_index: int, _intent: Dictionary) -> void:
	_update_enemy_ui()


func _on_card_played(hand_index: int, target_enemy_index: int) -> void:
	battle_manager.try_play_card(hand_index, target_enemy_index)


func _on_end_turn_pressed() -> void:
	battle_manager.end_player_turn()


func _on_sijo_slot_filled(index: int, card_id: String, _jang_name: String) -> void:
	if index < sijo_slot_labels.size():
		var card: CardData = DataLoader.get_card(card_id)
		if card:
			sijo_slot_labels[index].text = card.name_ko
		else:
			sijo_slot_labels[index].text = card_id
		sijo_slot_labels[index].add_theme_color_override("font_color", Color(1, 0.85, 0.3))


func _on_sijo_completed(_final_card_id: String) -> void:
	# 시조 완성 보상: 기 1 회복 + 카드 1장 드로우
	battle_manager.current_qi += 1
	battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
	battle_manager.draw_cards(1)
	sijo_system.reset()
	_init_sijo_slots()


func _on_status_effect_changed(_target: String, _effect_id: String, _stacks: int) -> void:
	_update_player_status_ui()
	_update_enemy_ui()


func _update_player_status_ui() -> void:
	var status_text := _format_status_effects("player")
	if status_text.is_empty():
		block_label.text = "방어: %d" % battle_manager.player_block
		block_label.visible = battle_manager.player_block > 0
	else:
		# 방어도 뒤에 상태이상 표시
		var display := ""
		if battle_manager.player_block > 0:
			display = "방어: %d  " % battle_manager.player_block
		display += status_text
		block_label.text = display
		block_label.visible = true


func _format_status_effects(target: String) -> String:
	if battle_manager.status_effects == null:
		return ""
	var effects := battle_manager.status_effects.get_all_effects(target)
	if effects.is_empty():
		return ""

	var parts: Array[String] = []
	# 상태이상 아이콘 매핑
	var icons := {
		"약화": "약화",
		"취약": "취약",
		"화상": "화상",
		"독": "독",
		"냉기": "냉기",
		"strength": "힘",
		"thorns": "가시",
		"death_mark": "사망표식",
		"death_countdown": "카운트다운",
	}
	for effect_id in effects:
		var stacks: int = effects[effect_id]
		var display_name: String = icons.get(effect_id, effect_id)
		parts.append("%s×%d" % [display_name, stacks])

	return " ".join(parts)


func _on_battle_ended(victory: bool) -> void:
	end_turn_button.disabled = true
	card_hand.visible = false

	# HP 동기화
	if GameManager.run_data:
		GameManager.run_data.current_hp = battle_manager.player_hp

	# 전투 결과 오버레이 표시
	_show_battle_result(victory)

	# 1.5초 후 씬 전환
	var timer := get_tree().create_timer(1.5)
	await timer.timeout
	if victory:
		# 적 보상 데이터 수집 → 보상 씬으로 전달
		var rewards := _collect_enemy_rewards()
		if GameManager.run_data:
			GameManager.run_data.set_meta("battle_rewards", rewards)
		GameManager.change_state(GameManager.GameState.REWARD)
	else:
		GameManager.end_run(false)


func _show_battle_result(victory: bool) -> void:
	var overlay := ColorRect.new()
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.color = Color(0, 0, 0, 0.6)
	add_child(overlay)

	var label := Label.new()
	label.text = "승리!" if victory else "패배..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if victory else Color(1, 0.3, 0.3))
	overlay.add_child(label)


func _collect_enemy_rewards() -> Dictionary:
	var total_gold := 0
	var card_chance := 0.0
	var relic_chance := 0.0
	for enemy in battle_manager.enemies:
		var rewards = enemy.get("rewards", {})
		if rewards is Dictionary:
			var gold_data = rewards.get("gold", {})
			if gold_data is Dictionary:
				total_gold += randi_range(gold_data.get("min", 10), gold_data.get("max", 20))
			elif gold_data is int:
				total_gold += gold_data
			card_chance = maxf(card_chance, rewards.get("card_chance", 0.0))
			relic_chance = maxf(relic_chance, rewards.get("relic_chance", 0.0))
	return {
		"gold": total_gold,
		"card_chance": card_chance,
		"relic_chance": relic_chance,
	}
