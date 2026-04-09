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
	# v10: 타이틀 레이블에 고운바탕 Bold 적용
	var title_font := load("res://fonts/GowunBatang-Bold.ttf") as Font
	if title_font:
		title_label.add_theme_font_override("font", title_font)

	# 이어하기 버튼: 세이브 있을 때만 표시
	continue_button.visible = SaveManager.has_run_save()

	# 버전 표시
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.1.0")

	# v10: "새 게임" 버튼을 주 액션(CTA)으로 강조 — 적색 배경+큰 글씨
	_apply_primary_button_style(start_button)

	# v9: 모든 버튼에 호버 글로우 효과 적용
	for btn in [continue_button, chronicle_button, settings_button, quit_button]:
		_apply_hover_glow(btn)

	# v10: 바텀 시트 상단 그라데이션 전환 (배경→패널 자연 블렌딩)
	_add_panel_gradient_transition()

	# v9: 반딧불 파티클 효과 (타이틀 분위기)
	_add_firefly_particles()

	# 디버그 빌드에서만 디버그 메뉴 버튼 표시
	if OS.is_debug_build():
		var debug_btn := Button.new()
		debug_btn.text = "Debug Menu"
		debug_btn.custom_minimum_size = Vector2(0, 76)
		debug_btn.add_theme_font_size_override("font_size", 34)
		debug_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		debug_btn.pressed.connect(func(): GameManager.change_state(GameManager.GameState.DEBUG_MENU))
		$TitlePanel/VBoxContainer.add_child(debug_btn)
		# 종료 버튼 앞에 배치
		$TitlePanel/VBoxContainer.move_child(debug_btn, quit_button.get_index())

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
	## v10: 주 액션 버튼에 적색 강조 스타일 적용 (CTA) — 단청 적색
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.76, 0.23, 0.13, 0.15)
	style.set_border_width_all(2)
	style.border_color = Color(0.76, 0.23, 0.13, 0.9)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.76, 0.23, 0.13, 0.15)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.76, 0.23, 0.13, 0.25)
	hover.shadow_size = 10
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.76, 0.23, 0.13, 0.35)
	pressed.shadow_size = 4
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(0.96, 0.88, 0.78))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.85))
	btn.add_theme_font_size_override("font_size", 38)


func _apply_hover_glow(btn: Button) -> void:
	## v10: 일반 버튼에 호버 시 적색 글로우 효과 적용 — 단청 적색
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.76, 0.23, 0.13, 0.08)
	hover_style.set_border_width_all(1)
	hover_style.border_color = Color(0.76, 0.23, 0.13, 0.4)
	hover_style.set_corner_radius_all(12)
	hover_style.shadow_color = Color(0.76, 0.23, 0.13, 0.1)
	hover_style.shadow_size = 6
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.85))


func _add_panel_gradient_transition() -> void:
	## v10: 바텀 시트 위에 그라데이션 오버레이 — 배경에서 패널로 자연스러운 전환
	var gradient_rect := TextureRect.new()
	gradient_rect.layout_mode = 1
	gradient_rect.anchor_left = 0.0
	gradient_rect.anchor_right = 1.0
	gradient_rect.anchor_top = 0.40
	gradient_rect.anchor_bottom = 0.56
	gradient_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.06, 0.04, 0.02, 0.0))
	gradient.set_color(1, Color(0.06, 0.04, 0.02, 0.72))

	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 4
	tex.height = 64

	gradient_rect.texture = tex
	gradient_rect.expand_mode = 1
	gradient_rect.stretch_mode = 0
	# 패널(TitlePanel) 바로 앞에 삽입
	var panel_idx: int = $TitlePanel.get_index()
	add_child(gradient_rect)
	move_child(gradient_rect, panel_idx)


func _add_firefly_particles() -> void:
	## v9: 타이틀 화면에 반딧불 파티클 효과 추가 (GPUParticles2D)
	var particles := GPUParticles2D.new()
	particles.amount = 12
	particles.lifetime = 4.0
	# GPUParticles2D는 Node2D 기반이므로 anchors 대신 position으로 배치
	particles.z_index = -1  # 배경 위, UI 아래

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(540, 960, 0)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 15.0
	mat.gravity = Vector3(0, -2, 0)
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = Color(0.85, 0.35, 0.15, 0.4)

	# 페이드인/아웃을 위한 색상 램프 — 붉은 등불 색감
	var gradient := Gradient.new()
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, Color(0.85, 0.35, 0.15, 0.0))
	gradient.add_point(0.3, Color(0.85, 0.35, 0.15, 0.5))
	gradient.add_point(0.7, Color(0.85, 0.35, 0.15, 0.4))
	gradient.set_offset(gradient.get_point_count() - 1, 1.0)
	gradient.set_color(gradient.get_point_count() - 1, Color(0.85, 0.35, 0.15, 0.0))
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp

	particles.process_material = mat
	particles.position = Vector2(540, 960)  # 화면 중앙
	add_child(particles)
