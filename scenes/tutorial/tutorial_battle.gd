extends Control

## 튜토리얼 전투 씬. 일반 전투 씬을 기반으로 튜토리얼 매니저를 추가한다.
## 약한 적(불량배) 1마리와 스타터 덱으로 진행되는 학습용 전투.

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
var tutorial_manager: TutorialManager

# 시조 슬롯 UI 라벨
var sijo_slot_labels: Array[Label] = []
var _sijo_collapsed: bool = false
var _sijo_toggle_button: Button = null
var _sijo_summary_label: Label = null

# 플레이어 상태이상 UI 컨테이너
var _player_status_container: HBoxContainer = null

# 적 UI 캐시
var _enemy_ui_cache: Dictionary = {}


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
	card_hand.card_played.connect(_on_card_played)
	card_hand.card_zoom_requested.connect(_on_card_zoom_requested)
	battle_manager.status_effect_changed.connect(_on_status_effect_changed)

	# 시조 슬롯 UI 초기화
	_init_sijo_toggle()
	_init_sijo_slots()

	# 튜토리얼 전투 시작
	_start_tutorial_battle()


func _start_tutorial_battle() -> void:
	# 튜토리얼용 간단한 스타터 덱 (음보 3과 4가 골고루 포함)
	var tutorial_deck: Array[String] = [
		"M003", "M003",  # 후퇴 ×2 (beat 3, 0코스트, 방어+약화)
		"D007", "D007", "D007",  # 수결 ×3 (공격 카드)
		"D001", "D001",  # 기공 ×2 (beat 3)
		"D002",          # 결인 ×1 (beat 4)
		"M005",          # 포복 ×1 (beat 3)
	]

	# 튜토리얼용 약한 적 — 불량배(E001) 데이터를 직접 구성
	var tutorial_enemy: Array[Dictionary] = [{
		"id": "T001",
		"name": {"ko": "허수아비 불량배"},
		"hp": 15,  # 일반 불량배보다 약함
		"moves": [
			{
				"id": "weak_slash",
				"name": "서투른 공격",
				"intent": "attack",
				"damage": 4,
				"times": 1,
			},
			{
				"id": "hesitate",
				"name": "망설임",
				"intent": "defend",
				"block": 3,
			},
		],
		"move_pattern": [0, 1, 0, 0, 1],
		"rewards": {
			"gold": {"min": 8, "max": 12},
			"card_chance": 1.0,
		},
	}]

	battle_manager.start_battle(tutorial_deck, tutorial_enemy, 70, 70, 3, "dosa")

	# 튜토리얼 매니저 시작 (전투 시작 직후)
	tutorial_manager = TutorialManager.new()
	add_child(tutorial_manager)
	tutorial_manager.tutorial_completed.connect(_on_tutorial_completed)
	tutorial_manager.tutorial_skipped.connect(_on_tutorial_skipped)
	tutorial_manager.start(self, battle_manager, sijo_system)


func _on_tutorial_completed() -> void:
	# 짧은 딜레이 후 보상 씬 또는 맵으로 전환
	var timer := get_tree().create_timer(1.5)
	await timer.timeout
	_return_to_game()


func _on_tutorial_skipped() -> void:
	# 스킵 시 즉시 복귀
	_return_to_game()


func _return_to_game() -> void:
	# 튜토리얼 후 캐릭터 선택 화면으로 복귀
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)


# --- 시조 슬롯 UI (battle.gd에서 복사) ---

func _init_sijo_toggle() -> void:
	var sijo_area := $SijoArea
	_sijo_toggle_button = Button.new()
	_sijo_toggle_button.text = "▼"
	_sijo_toggle_button.custom_minimum_size = Vector2(40, 40)
	_sijo_toggle_button.add_theme_font_size_override("font_size", 16)
	_sijo_toggle_button.pressed.connect(_on_sijo_toggle_pressed)
	sijo_area.add_child(_sijo_toggle_button)
	sijo_area.move_child(_sijo_toggle_button, 0)

	_sijo_summary_label = Label.new()
	_sijo_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sijo_summary_label.add_theme_font_size_override("font_size", 14)
	_sijo_summary_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_sijo_summary_label.visible = false
	sijo_area.add_child(_sijo_summary_label)


func _on_sijo_toggle_pressed() -> void:
	_sijo_collapsed = not _sijo_collapsed
	sijo_container.visible = not _sijo_collapsed
	_sijo_summary_label.visible = _sijo_collapsed
	_sijo_toggle_button.text = "▶" if _sijo_collapsed else "▼"
	if _sijo_collapsed:
		_update_sijo_summary()


func _update_sijo_summary() -> void:
	if not _sijo_summary_label:
		return
	var filled := sijo_system.current_slot_index if sijo_system else 0
	var total := SijoSystem.PATTERN.size()
	_sijo_summary_label.text = "시조 %d/%d" % [filled, total]


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
	card_hand.update_hand(battle_manager.hand, battle_manager.current_qi, sijo_beat, battle_manager)
	draw_pile_label.text = "드로우: %d" % battle_manager.draw_pile.size()
	discard_pile_label.text = "버림: %d" % battle_manager.discard_pile.size()


func _update_enemy_ui() -> void:
	for i in battle_manager.enemies.size():
		var enemy: Dictionary = battle_manager.enemies[i]
		if enemy["current_hp"] <= 0:
			if _enemy_ui_cache.has(i):
				_enemy_ui_cache[i]["panel"].visible = false
			continue

		if _enemy_ui_cache.has(i):
			var cache: Dictionary = _enemy_ui_cache[i]
			cache["panel"].visible = true
			cache["hp_label"].text = "HP: %d/%d" % [enemy["current_hp"], enemy["max_hp"]]
			var block_val: int = enemy.get("block", 0)
			cache["block_label"].text = "방어: %d" % block_val
			cache["block_label"].visible = block_val > 0
			var intent := battle_manager._get_enemy_intent(i)
			cache["intent_label"].text = _format_intent(intent)
		else:
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

			var intent_label := Label.new()
			intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			intent_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
			var intent := battle_manager._get_enemy_intent(i)
			intent_label.text = _format_intent(intent)

			var block_val: int = enemy.get("block", 0)
			var enemy_block_label := Label.new()
			enemy_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			enemy_block_label.text = "방어: %d" % block_val
			enemy_block_label.visible = block_val > 0

			vbox.add_child(name_label)
			vbox.add_child(hp_lbl)
			vbox.add_child(enemy_block_label)
			vbox.add_child(intent_label)
			panel.add_child(vbox)
			panel.custom_minimum_size = Vector2(200, 180)
			enemy_container.add_child(panel)

			_enemy_ui_cache[i] = {
				"panel": panel,
				"name_label": name_label,
				"hp_label": hp_lbl,
				"block_label": enemy_block_label,
				"intent_label": intent_label,
			}


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


func _show_sijo_reward_popup(text: String) -> void:
	var popup := Label.new()
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.anchors_preset = Control.PRESET_CENTER_TOP
	popup.position.y = 120
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", Color(0.6, 1.0, 0.5))
	add_child(popup)
	var tween := create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(popup.queue_free)


# --- 시그널 핸들러 ---

func _on_hand_changed(_new_hand: Array[String]) -> void:
	_refresh_hand_ui()


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


func _on_card_zoom_requested(card_data: CardData) -> void:
	var popup := CardZoomPopup.new()
	add_child(popup)
	popup.show_card(card_data)


func _on_end_turn_pressed() -> void:
	AudioManager.play_sfx_by_key("end_turn")
	battle_manager.end_player_turn()


func _on_sijo_slot_filled(index: int, card_id: String, _jang_name: String) -> void:
	AudioManager.play_sfx_by_key("sijo_slot")
	if index < sijo_slot_labels.size():
		var card: CardData = DataLoader.get_card(card_id)
		if card:
			sijo_slot_labels[index].text = card.name_ko
		else:
			sijo_slot_labels[index].text = card_id
		sijo_slot_labels[index].add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	if _sijo_collapsed:
		_update_sijo_summary()

	match index:
		2:
			battle_manager.current_qi = mini(battle_manager.current_qi + 1, battle_manager.max_qi)
			battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
			_show_sijo_reward_popup("초장 완성! 기 +1")
		3:
			battle_manager.draw_cards(1)
			_show_sijo_reward_popup("중장 완성! 카드 드로우")


func _on_sijo_completed(final_card_id: String) -> void:
	if battle_manager.state == BattleManager.BattleState.BATTLE_WIN or battle_manager.state == BattleManager.BattleState.BATTLE_LOSE:
		return
	AudioManager.play_sfx_by_key("sijo_complete")
	var card: CardData = battle_manager._get_battle_card(final_card_id)
	if card:
		var target_index := 0
		for i in battle_manager.enemies.size():
			if battle_manager.enemies[i]["current_hp"] > 0:
				target_index = i
				break
		battle_manager._resolve_card_effect(card, target_index)
	battle_manager.current_qi += 1
	battle_manager.current_qi = mini(battle_manager.current_qi, battle_manager.max_qi)
	battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
	battle_manager.draw_cards(1)
	sijo_system.reset()
	_init_sijo_slots()


func _on_status_effect_changed(_target: String, _effect_id: String, _stacks: int) -> void:
	_update_enemy_ui()


func _on_battle_ended(victory: bool) -> void:
	end_turn_button.disabled = true
	card_hand.visible = false

	# 결과 오버레이 표시
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
