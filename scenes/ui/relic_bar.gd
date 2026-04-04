class_name RelicBar
extends HBoxContainer

## 보유 유물 아이콘을 표시하는 UI 바.
## 전투 씬, 맵 씬 등에서 사용.

const BASE_VIEWPORT_WIDTH := 1080.0
const BASE_ICON_SIZE := Vector2(48, 48)
const BASE_FONT_SIZE := 20


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_BEGIN
	RelicManager.relic_acquired.connect(_on_relic_acquired)
	refresh()


func refresh() -> void:
	## 현재 보유 유물 목록으로 UI를 갱신한다.
	for child in get_children():
		child.queue_free()

	var relics := RelicManager.get_owned_relics()
	for relic_id in relics:
		_add_relic_icon(relic_id)


func _get_scale_factor() -> float:
	var vp := get_viewport()
	if vp == null:
		return 1.0
	return vp.get_visible_rect().size.x / BASE_VIEWPORT_WIDTH


func _add_relic_icon(relic_id: String) -> void:
	var relic := DataLoader.get_relic(relic_id)
	if relic.is_empty():
		return

	var sf := _get_scale_factor()
	var icon_size := BASE_ICON_SIZE * sf

	var panel := PanelContainer.new()
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.12, 0.12, 0.12, 0.9)
	stylebox.border_color = RelicManager.get_relic_rarity_color(relic_id)
	stylebox.set_border_width_all(int(2.0 * sf))
	stylebox.set_corner_radius_all(int(6.0 * sf))
	stylebox.set_content_margin_all(int(4.0 * sf))
	panel.add_theme_stylebox_override("panel", stylebox)
	panel.custom_minimum_size = icon_size

	var label := Label.new()
	var name_data = relic.get("name", {})
	var display_name: String = ""
	if name_data is Dictionary:
		display_name = name_data.get("ko", relic_id)
	else:
		display_name = str(name_data)

	# 이름의 앞 2글자를 아이콘으로 사용 (1글자로는 의미 전달 부족)
	label.text = display_name.substr(0, 2) if display_name.length() >= 2 else display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", int(BASE_FONT_SIZE * sf))
	label.add_theme_color_override("font_color", RelicManager.get_relic_rarity_color(relic_id))

	# 툴팁: 유물 이름 + 효과 설명
	var relic_desc := RelicManager.get_relic_description(relic_id)
	var tooltip := "%s\n%s" % [display_name, relic_desc]
	panel.tooltip_text = tooltip

	# 모바일 터치 대응: 탭하면 유물 정보를 팝업으로 표시
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_relic_info(display_name, relic_desc, relic_id)
	)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	panel.add_child(label)
	add_child(panel)


func _show_relic_info(relic_name: String, relic_desc: String, _relic_id: String) -> void:
	## 유물 탭 시 간단한 정보 팝업 표시
	var dialog := AcceptDialog.new()
	dialog.title = relic_name
	dialog.dialog_text = relic_desc
	dialog.ok_button_text = "닫기"
	add_child(dialog)
	dialog.popup_centered()


func _on_relic_acquired(_relic_id: String) -> void:
	refresh()
