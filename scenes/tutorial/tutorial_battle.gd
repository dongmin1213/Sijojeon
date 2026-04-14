extends Control

## 튜토리얼 전투 씬. 실제 전투 씬과 동일한 레이아웃을 사용하되,
## 튜토리얼 매니저를 추가하여 학습용 전투를 진행한다.
## 약한 적(불량배) 1마리와 스타터 덱으로 진행.

@onready var hp_label: Label = $PlayerHUD/StatusRow/HPLabel
@onready var qi_label: Label = $PlayerHUD/StatusRow/QiLabel
@onready var block_label: Label = $PlayerHUD/StatusRow/BlockLabel
@onready var turn_label: Label = $HiddenRefs/TurnLabel
@onready var card_hand: CardHand = $HandZone/CardHand
@onready var enemy_container: HBoxContainer = $EnemyZone/EnemyContainer
@onready var sijo_container: HBoxContainer = $SijoBar/SijoContainer
@onready var _hud_end_turn_button: Button = $HiddenRefs/EndTurnButton
@onready var draw_pile_label: Label = $HiddenRefs/DrawPileLabel
@onready var discard_pile_label: Label = $HiddenRefs/DiscardPileLabel

# 플로팅 턴 종료 버튼 (실제 전투와 동일)
var end_turn_button: Button = null

# 턴 표시 오버레이 (실제 전투와 동일)
var _turn_overlay_label: Label = null

# 덱 정보 오버레이 (실제 전투와 동일)
var _draw_pile_overlay: PanelContainer = null
var _discard_pile_overlay: PanelContainer = null

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
	# HandZone 클립 비활성화 — 카드가 위로 올라올 수 있도록
	var hand_zone := $HandZone as PanelContainer
	if hand_zone:
		hand_zone.clip_contents = false
		card_hand.clip_contents = false

	# 매니저 초기화
	battle_manager = BattleManager.new()
	sijo_system = SijoSystem.new()
	battle_manager.sijo_system = sijo_system
	add_child(battle_manager)
	add_child(sijo_system)

	# 플로팅 UI 요소 생성 (실제 전투와 동일한 스타일)
	_create_floating_ui()

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


func _create_deck_pill_label(font_color: Color) -> PanelContainer:
	## 반투명 배경 pill 컨테이너 + 라벨 — 실제 전투와 동일
	var pill := PanelContainer.new()
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color(0.03, 0.02, 0.06, 0.85)
	pill_style.set_border_width_all(1)
	pill_style.border_color = Color(font_color.r, font_color.g, font_color.b, 0.4)
	pill_style.set_corner_radius_all(14)
	pill_style.content_margin_left = 14.0
	pill_style.content_margin_right = 14.0
	pill_style.content_margin_top = 4.0
	pill_style.content_margin_bottom = 4.0
	pill.add_theme_stylebox_override("panel", pill_style)

	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", font_color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(lbl)
	return pill


func _create_floating_ui() -> void:
	## 플로팅 UI 요소 생성: 턴 종료 버튼, 턴 표시, 덱 정보 — 실제 전투와 동일
	# 턴 종료 버튼 — 크고 눈에 띄는 배치
	end_turn_button = Button.new()
	end_turn_button.text = tr("BATTLE_END_TURN")
	end_turn_button.custom_minimum_size = Vector2(200, 80)
	end_turn_button.add_theme_font_size_override("font_size", 30)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.78, 0.29, 0.19, 0.95)
	btn_style.set_border_width_all(2)
	btn_style.border_color = Color(0.76, 0.23, 0.13, 0.9)
	btn_style.set_corner_radius_all(18)
	btn_style.set_content_margin_all(12)
	btn_style.shadow_color = Color(0.78, 0.15, 0.10, 0.4)
	btn_style.shadow_size = 10
	btn_style.shadow_offset = Vector2(0, 4)
	end_turn_button.add_theme_stylebox_override("normal", btn_style)
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.88, 0.38, 0.25, 1.0)
	btn_hover.shadow_color = Color(0.76, 0.23, 0.13, 0.3)
	btn_hover.shadow_size = 12
	end_turn_button.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed := btn_style.duplicate()
	btn_pressed.bg_color = Color(0.60, 0.20, 0.12, 0.95)
	btn_pressed.shadow_size = 4
	end_turn_button.add_theme_stylebox_override("pressed", btn_pressed)
	end_turn_button.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
	end_turn_button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.90))
	# 액션바 우측, 시조바와 같은 높이 (62-68%)
	end_turn_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	end_turn_button.anchor_left = 0.60
	end_turn_button.anchor_right = 0.98
	end_turn_button.anchor_top = 0.62
	end_turn_button.anchor_bottom = 0.68
	end_turn_button.z_index = 12
	add_child(end_turn_button)

	# 턴 표시 오버레이 — HUD 좌측 (노치 아래)
	_turn_overlay_label = Label.new()
	_turn_overlay_label.add_theme_font_size_override("font_size", 16)
	_turn_overlay_label.add_theme_color_override("font_color", Color(0.70, 0.64, 0.50, 0.85))
	_turn_overlay_label.anchor_left = 0.02
	_turn_overlay_label.anchor_top = 0.035
	_turn_overlay_label.anchor_right = 0.15
	_turn_overlay_label.anchor_bottom = 0.06
	_turn_overlay_label.z_index = 15
	add_child(_turn_overlay_label)

	# 드로우/버림 더미 — 핸드존 좌/우 상단 (68% 라인)
	_draw_pile_overlay = _create_deck_pill_label(Color(0.45, 0.65, 0.90))
	_draw_pile_overlay.anchor_left = 0.02
	_draw_pile_overlay.anchor_top = 0.68
	_draw_pile_overlay.anchor_right = 0.18
	_draw_pile_overlay.anchor_bottom = 0.72
	_draw_pile_overlay.z_index = 12
	add_child(_draw_pile_overlay)

	_discard_pile_overlay = _create_deck_pill_label(Color(0.90, 0.50, 0.40))
	_discard_pile_overlay.anchor_left = 0.82
	_discard_pile_overlay.anchor_top = 0.68
	_discard_pile_overlay.anchor_right = 0.98
	_discard_pile_overlay.anchor_bottom = 0.72
	_discard_pile_overlay.z_index = 12
	add_child(_discard_pile_overlay)


func _start_tutorial_battle() -> void:
	# 튜토리얼용 간단한 스타터 덱 (음보 3과 4가 골고루 포함)
	var tutorial_deck: Array[String] = [
		"M003", "M003",  # 후퇴 x2 (beat 3, 0코스트, 방어+약화)
		"D007", "D007", "D007",  # 수결 x3 (공격 카드)
		"D001", "D001",  # 기공 x2 (beat 3)
		"D002",          # 결인 x1 (beat 4)
		"M005",          # 포복 x1 (beat 3)
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
	# 짧은 딜레이 후 복귀
	var timer := get_tree().create_timer(1.5)
	await timer.timeout
	_return_to_game()


func _on_tutorial_skipped() -> void:
	_return_to_game()


func _return_to_game() -> void:
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)


# --- 시조 슬롯 UI (실제 전투와 동일한 스타일) ---

func _init_sijo_toggle() -> void:
	var sijo_area := $SijoBar
	_sijo_toggle_button = Button.new()
	_sijo_toggle_button.text = "▼"
	_sijo_toggle_button.custom_minimum_size = Vector2(40, 40)
	_sijo_toggle_button.add_theme_font_size_override("font_size", 18)
	_sijo_toggle_button.pressed.connect(_on_sijo_toggle_pressed)
	sijo_area.add_child(_sijo_toggle_button)
	sijo_area.move_child(_sijo_toggle_button, 0)

	_sijo_summary_label = Label.new()
	_sijo_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sijo_summary_label.add_theme_font_size_override("font_size", 18)
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
	var total := sijo_system.pattern.size()
	_sijo_summary_label.text = tr("BATTLE_SIJO_SUMMARY_FMT") % [filled, total]


func _init_sijo_slots() -> void:
	sijo_slot_labels.clear()
	for child in sijo_container.get_children():
		child.queue_free()

	var jang_names: Array[String] = [tr("SIJO_FIRST_VERSE"), tr("SIJO_MIDDLE_VERSE"), tr("SIJO_FINAL_VERSE")]
	var jang_symbols: Array[String] = [tr("JANG_SYMBOL_1"), tr("JANG_SYMBOL_2"), tr("JANG_SYMBOL_3")]
	for i in sijo_system.pattern.size():
		var slot_panel := PanelContainer.new()
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.05, 0.05, 0.04, 0.9)
		slot_style.set_border_width_all(1)
		slot_style.border_color = Color(0.30, 0.28, 0.25, 0.6)
		slot_style.set_corner_radius_all(12)
		slot_style.content_margin_left = 12
		slot_style.content_margin_right = 12
		slot_style.content_margin_top = 8
		slot_style.content_margin_bottom = 8
		# 현재 활성 슬롯 강조 — 금색 테두리
		if i == sijo_system.current_slot_index:
			slot_style.border_color = Color(0.76, 0.23, 0.13, 0.9)
			slot_style.shadow_color = Color(0.76, 0.23, 0.13, 0.2)
			slot_style.shadow_size = 6
		slot_panel.add_theme_stylebox_override("panel", slot_style)
		slot_panel.custom_minimum_size = Vector2(140, 60)
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)

		# 장 이름 + 심볼 (한 줄)
		var header := Label.new()
		header.text = "%s %s" % [jang_symbols[i] if i < jang_symbols.size() else "", jang_names[i] if i < jang_names.size() else ""]
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_font_size_override("font_size", 16)
		if i == sijo_system.current_slot_index:
			header.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
		else:
			header.add_theme_color_override("font_color", Color(0.50, 0.48, 0.42))

		# 음보 수 + 카드 이름 표시용 라벨
		var label := Label.new()
		label.text = "[%d]" % sijo_system.pattern[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

		vbox.add_child(header)
		vbox.add_child(label)
		slot_panel.add_child(vbox)
		sijo_container.add_child(slot_panel)
		sijo_slot_labels.append(label)


func _refresh_hand_ui() -> void:
	var sijo_beat := sijo_system.get_next_required_beat() if sijo_system else -1
	card_hand.update_hand(battle_manager.hand, battle_manager.current_qi, sijo_beat, battle_manager)
	# 플로팅 덱 정보 업데이트
	var draw_text := tr("BATTLE_DRAW_PILE_FMT") % battle_manager.draw_pile.size()
	var discard_text := tr("BATTLE_DISCARD_PILE_FMT") % battle_manager.discard_pile.size()
	draw_pile_label.text = draw_text
	discard_pile_label.text = discard_text
	if _draw_pile_overlay and _draw_pile_overlay.get_child_count() > 0:
		(_draw_pile_overlay.get_child(0) as Label).text = draw_text
	if _discard_pile_overlay and _discard_pile_overlay.get_child_count() > 0:
		(_discard_pile_overlay.get_child(0) as Label).text = discard_text


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
			cache["block_label"].text = tr("BATTLE_ENEMY_BLOCK_FMT") % block_val
			cache["block_label"].visible = block_val > 0
			var intent := battle_manager._get_enemy_intent(i)
			cache["intent_label"].text = _format_intent(intent)
		else:
			var enemy_name: String = TranslationManager.trd_name(enemy)
			if enemy_name == "":
				enemy_name = tr("BATTLE_ENEMY_FALLBACK")

			var panel := PanelContainer.new()
			# 적 패널 — 실제 전투와 유사한 반투명 스타일
			var panel_style := StyleBoxFlat.new()
			panel_style.bg_color = Color(0.06, 0.06, 0.06, 0.75)
			panel_style.set_border_width_all(1)
			panel_style.border_color = Color(0.76, 0.23, 0.13, 0.3)
			panel_style.set_corner_radius_all(12)
			panel_style.content_margin_left = 12
			panel_style.content_margin_right = 12
			panel_style.content_margin_top = 8
			panel_style.content_margin_bottom = 8
			panel.add_theme_stylebox_override("panel", panel_style)

			var vbox := VBoxContainer.new()
			var name_label := Label.new()
			name_label.text = enemy_name
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.add_theme_font_size_override("font_size", 22)
			name_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
			var hp_lbl := Label.new()
			hp_lbl.text = "HP: %d/%d" % [enemy["current_hp"], enemy["max_hp"]]
			hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hp_lbl.add_theme_font_size_override("font_size", 18)
			hp_lbl.add_theme_color_override("font_color", Color(0.78, 0.29, 0.19))

			var intent_label := Label.new()
			intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			intent_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
			intent_label.add_theme_font_size_override("font_size", 18)
			var intent := battle_manager._get_enemy_intent(i)
			intent_label.text = _format_intent(intent)

			var block_val: int = enemy.get("block", 0)
			var enemy_block_label := Label.new()
			enemy_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			enemy_block_label.text = tr("BATTLE_ENEMY_BLOCK_FMT") % block_val
			enemy_block_label.add_theme_color_override("font_color", Color(0.23, 0.48, 0.84))
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
				return "%s %dx%d" % [name_str, dmg, times] if name_str else tr("BATTLE_ATTACK_MULTI_FMT") % [dmg, times]
			return "%s %d" % [name_str, dmg] if name_str else tr("BATTLE_ATTACK_FMT") % dmg
		"defend", "defend_buff", "buff_defend":
			var blk: int = intent.get("block", 0)
			return "%s %d" % [name_str, blk] if name_str else tr("BATTLE_DEFEND_FMT") % blk
		"buff":
			return name_str if name_str else tr("BATTLE_BUFF")
		"debuff":
			return name_str if name_str else tr("BATTLE_DEBUFF")
		_:
			return name_str if name_str else "???"


func _show_sijo_reward_popup(text: String) -> void:
	var popup := Label.new()
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.anchors_preset = Control.PRESET_CENTER_TOP
	popup.position.y = 120
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_color_override("font_color", Color(0.6, 1.0, 0.5))
	add_child(popup)
	var tween := create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(popup.queue_free)


# --- 시그널 핸들러 ---

func _on_hand_changed(_new_hand: Array[String]) -> void:
	_refresh_hand_ui()


func _on_qi_changed(current: int, max_val: int) -> void:
	qi_label.text = tr("BATTLE_QI_FMT") % [current, max_val]
	_refresh_hand_ui()


func _on_hp_changed(current: int, max_val: int) -> void:
	hp_label.text = "HP: %d/%d" % [current, max_val]


func _on_block_changed(new_block: int) -> void:
	block_label.text = tr("BATTLE_BLOCK_FMT") % new_block
	block_label.visible = new_block > 0


func _on_turn_started(turn: int) -> void:
	turn_label.text = tr("BATTLE_TURN_FMT") % turn
	if _turn_overlay_label:
		_turn_overlay_label.text = tr("BATTLE_TURN_FMT") % turn


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


func _on_sijo_slot_filled(index: int, card_id: String, _jang_name: String, beat_matched: bool) -> void:
	AudioManager.play_sfx_by_key("sijo_slot")
	if index < sijo_slot_labels.size():
		var card: CardData = DataLoader.get_card(card_id)
		if card:
			sijo_slot_labels[index].text = card.get_display_name()
		else:
			sijo_slot_labels[index].text = card_id
		if beat_matched:
			sijo_slot_labels[index].add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
		else:
			sijo_slot_labels[index].add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	if _sijo_collapsed:
		_update_sijo_summary()

	match index:
		2:
			battle_manager.current_qi = mini(battle_manager.current_qi + 1, battle_manager.max_qi)
			battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
			_show_sijo_reward_popup(tr("TUTORIAL_CHOJANG_REWARD"))
		3:
			battle_manager.draw_cards(1)
			_show_sijo_reward_popup(tr("TUTORIAL_JUNGJANG_REWARD"))


func _on_sijo_completed(final_card_id: String, _all_slot_card_ids: Array) -> void:
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
	overlay.z_index = 20
	add_child(overlay)

	var label := Label.new()
	label.text = tr("TUTORIAL_VICTORY_TEXT") if victory else tr("TUTORIAL_DEFEAT_TEXT")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.layout_mode = 1
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91) if victory else Color(1, 0.3, 0.3))
	overlay.add_child(label)
