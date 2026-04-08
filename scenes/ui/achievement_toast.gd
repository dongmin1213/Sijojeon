extends PanelContainer

## 업적 달성 토스트 알림.
## AchievementManager.achievement_unlocked 시그널에 연결하여 사용한다.

const DISPLAY_DURATION := 3.0
const SLIDE_DURATION := 0.4
const BASE_VIEWPORT_WIDTH := 1080.0

var _queue: Array[Dictionary] = []
var _showing := false


func _ready() -> void:
	visible = false
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(ach: Dictionary) -> void:
	_queue.append(ach)
	if not _showing:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var ach: Dictionary = _queue.pop_front()
	_display(ach)


func _get_scale_factor() -> float:
	var vp := get_viewport()
	if vp == null:
		return 1.0
	return vp.get_visible_rect().size.x / BASE_VIEWPORT_WIDTH


func _display(ach: Dictionary) -> void:
	# 내부 컨텐츠 구성
	for child in get_children():
		child.queue_free()

	var sf := _get_scale_factor()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(20.0 * sf))
	margin.add_theme_constant_override("margin_right", int(20.0 * sf))
	margin.add_theme_constant_override("margin_top", int(12.0 * sf))
	margin.add_theme_constant_override("margin_bottom", int(12.0 * sf))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(12.0 * sf))

	# 업적 아이콘 (텍스트 대체)
	var icon_label := Label.new()
	icon_label.text = "★"
	icon_label.add_theme_font_size_override("font_size", int(28.0 * sf))
	icon_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
	hbox.add_child(icon_label)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(2.0 * sf))

	var header := Label.new()
	header.text = tr("ACHIEVEMENT_UNLOCKED")
	header.add_theme_font_size_override("font_size", int(14.0 * sf))
	header.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
	vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = TranslationManager.trd(ach, "name", "")
	name_label.add_theme_font_size_override("font_size", int(20.0 * sf))
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = TranslationManager.trd(ach, "description", "")
	desc_label.add_theme_font_size_override("font_size", int(14.0 * sf))
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	hbox.add_child(vbox)
	margin.add_child(hbox)
	add_child(margin)

	# 슬라이드 인 애니메이션
	visible = true
	modulate.a = 0.0
	var target_pos := position
	position.y -= int(60.0 * sf)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:y", target_pos.y, SLIDE_DURATION)
	tween.parallel().tween_property(self, "modulate:a", 1.0, SLIDE_DURATION * 0.6)
	tween.tween_interval(DISPLAY_DURATION)
	tween.tween_property(self, "modulate:a", 0.0, SLIDE_DURATION)
	tween.tween_callback(_on_toast_finished)


func _on_toast_finished() -> void:
	visible = false
	_show_next()
