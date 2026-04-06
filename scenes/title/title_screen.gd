extends Control

## 타이틀 화면. 게임 시작, 이어하기, 연대기, 설정 등 메인 메뉴 제공.

@onready var start_button: Button = $TitlePanel/VBoxContainer/StartButton
@onready var continue_button: Button = $TitlePanel/VBoxContainer/ContinueButton
@onready var chronicle_button: Button = $TitlePanel/VBoxContainer/ChronicleButton
@onready var settings_button: Button = $TitlePanel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $TitlePanel/VBoxContainer/QuitButton
@onready var title_label: Label = $TitleArea/TitleLabel
@onready var version_label: Label = $VersionLabel


func _ready() -> void:
	# 이어하기 버튼: 세이브 있을 때만 표시
	continue_button.visible = SaveManager.has_run_save()

	# 버전 표시
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.1.0")

	# v8: "새 게임" 버튼을 주 액션(CTA)으로 강조 — 금색 배경+큰 글씨
	_apply_primary_button_style(start_button)

	# 버튼 연결
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	chronicle_button.pressed.connect(_on_chronicle_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 타이틀 페이드인 연출 (ColorRect 오버레이로 입력 차단 방지)
	var fade_rect := ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.8)
	tween.tween_callback(fade_rect.queue_free)


func _on_start_pressed() -> void:
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)


func _on_continue_pressed() -> void:
	GameManager.load_saved_run()


func _on_chronicle_pressed() -> void:
	GameManager.change_state(GameManager.GameState.CHRONICLE)


func _on_settings_pressed() -> void:
	GameManager.change_state(GameManager.GameState.SETTINGS)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _apply_primary_button_style(btn: Button) -> void:
	## v8: 주 액션 버튼에 금색 강조 스타일 적용 (CTA)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.83, 0.66, 0.26, 0.15)
	style.set_border_width_all(2)
	style.border_color = Color(0.83, 0.66, 0.26, 0.9)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.83, 0.66, 0.26, 0.15)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.83, 0.66, 0.26, 0.25)
	hover.shadow_size = 10
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.83, 0.66, 0.26, 0.35)
	pressed.shadow_size = 4
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(0.83, 0.66, 0.26))
	btn.add_theme_color_override("font_hover_color", Color(0.93, 0.78, 0.36))
	btn.add_theme_font_size_override("font_size", 38)
