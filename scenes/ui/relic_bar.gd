class_name RelicBar
extends HBoxContainer

## 보유 유물 아이콘을 표시하는 UI 바.
## 전투 씬, 맵 씬 등에서 사용.

const ICON_SIZE := Vector2(48, 48)


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


func _add_relic_icon(relic_id: String) -> void:
	var relic := DataLoader.get_relic(relic_id)
	if relic.is_empty():
		return

	var panel := PanelContainer.new()
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.12, 0.12, 0.12, 0.9)
	stylebox.border_color = RelicManager.get_relic_rarity_color(relic_id)
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(6)
	stylebox.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", stylebox)
	panel.custom_minimum_size = ICON_SIZE

	var label := Label.new()
	var name_data = relic.get("name", {})
	var display_name: String = ""
	if name_data is Dictionary:
		display_name = name_data.get("ko", relic_id)
	else:
		display_name = str(name_data)

	# 이름의 첫 글자를 아이콘으로 사용
	label.text = display_name.substr(0, 1) if display_name.length() > 0 else "?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", RelicManager.get_relic_rarity_color(relic_id))

	# 툴팁: 유물 이름 + 효과 설명
	var tooltip := "%s\n%s" % [display_name, RelicManager.get_relic_description(relic_id)]
	panel.tooltip_text = tooltip

	panel.add_child(label)
	add_child(panel)


func _on_relic_acquired(_relic_id: String) -> void:
	refresh()
