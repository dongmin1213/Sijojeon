class_name CardZoomPopup
extends CanvasLayer

## 카드 상세보기 팝업. 카드를 확대하여 전체 정보를 표시한다.
## 터치/클릭으로 닫을 수 있다.

var _bg: ColorRect
var _panel: PanelContainer
var _card_data: CardData


func _init() -> void:
	layer = 100  # 최상위 레이어


func show_card(card: CardData) -> void:
	_card_data = card
	_build_ui()


func _build_ui() -> void:
	# 배경 (반투명 오버레이)
	_bg = ColorRect.new()
	_bg.anchors_preset = Control.PRESET_FULL_RECT
	_bg.color = Color(0, 0, 0, 0.7)
	_bg.gui_input.connect(_on_bg_input)
	add_child(_bg)

	# 중앙 패널 — 뷰포트 중앙에 명시적 배치
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(360, 540)
	var vp_size := get_viewport().get_visible_rect().size
	_panel.position = Vector2(
		(vp_size.x - 360) / 2.0,
		(vp_size.y - 540) / 2.0
	)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.13, 0.2)
	style.border_color = Color(0.6, 0.5, 0.8)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", style)
	_bg.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	# 카드 이름
	var name_label := Label.new()
	var display_name := _card_data.get_display_name()
	if _card_data.upgraded:
		display_name += "+"
	name_label.text = display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	vbox.add_child(name_label)

	# 카드 일러스트
	var art := TextureRect.new()
	art.texture = TextureManager.get_card_texture(_card_data.id, _card_data.type)
	art.custom_minimum_size = Vector2(280, 160)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(art)

	# 타입 + 희귀도
	var type_names := {
		"attack": "공격", "defense": "방어", "spell": "주술",
		"movement": "이동", "formation": "진형",
	}
	var type_label := Label.new()
	type_label.text = type_names.get(_card_data.type, _card_data.type)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 18)
	var type_color: Color = AccessibilityManager.get_type_color(_card_data.type)
	type_label.add_theme_color_override("font_color", type_color)
	vbox.add_child(type_label)

	# 구분선
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# 스탯 그리드
	var stats := _build_stat_text()
	var stat_label := Label.new()
	stat_label.text = stats
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(stat_label)

	# 효과 설명
	var effect_label := Label.new()
	effect_label.text = _card_data.get_current_effect()
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	effect_label.custom_minimum_size = Vector2(300, 0)
	effect_label.add_theme_font_size_override("font_size", 18)
	effect_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(effect_label)

	# 닫기 안내
	var hint := Label.new()
	hint.text = "터치하여 닫기"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(hint)


func _build_stat_text() -> String:
	var lines: Array[String] = []
	lines.append("기(氣): %d  |  음보(拍): %d" % [_card_data.cost, _card_data.beat])

	if _card_data.damage > 0:
		var dmg := "피해: %d" % _card_data.damage
		if _card_data.is_aoe:
			dmg += " (전체)"
		lines.append(dmg)
	if _card_data.block_value > 0:
		lines.append("방어: %d" % _card_data.block_value)
	if _card_data.draw_count > 0:
		lines.append("드로우: +%d" % _card_data.draw_count)
	if _card_data.qi_gain > 0:
		lines.append("기 회복: +%d" % _card_data.qi_gain)
	if _card_data.stamina_cost > 0:
		lines.append("자원 비용: %d" % _card_data.stamina_cost)
	if _card_data.stamina_gain > 0:
		lines.append("자원 획득: +%d" % _card_data.stamina_gain)

	return "\n".join(lines)


func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()


func _close() -> void:
	queue_free()
