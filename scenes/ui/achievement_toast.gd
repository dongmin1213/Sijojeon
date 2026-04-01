extends PanelContainer

## 업적 달성 토스트 알림.
## AchievementManager.achievement_unlocked 시그널에 연결하여 사용한다.

const DISPLAY_DURATION := 3.0
const SLIDE_DURATION := 0.4

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


func _display(ach: Dictionary) -> void:
	# 내부 컨텐츠 구성
	for child in get_children():
		child.queue_free()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	# 업적 아이콘 (텍스트 대체)
	var icon_label := Label.new()
	icon_label.text = "★"
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	hbox.add_child(icon_label)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var header := Label.new()
	header.text = "업적 달성!"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(header)

	var name_label := Label.new()
	name_label.text = ach.get("name", "")
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = ach.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)

	hbox.add_child(vbox)
	margin.add_child(hbox)
	add_child(margin)

	# 슬라이드 인 애니메이션
	visible = true
	modulate.a = 0.0
	var target_pos := position
	position.y -= 60

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
