class_name TutorialOverlay
extends CanvasLayer

## 튜토리얼 가이드 오버레이. 특정 UI 영역을 하이라이트하고 설명 텍스트를 표시한다.
## 코드 기반으로 동작하며, 아트 에셋 불필요.

signal step_acknowledged  # 플레이어가 "다음" 또는 지정된 액션을 수행

const OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.7)
const HIGHLIGHT_COLOR := Color(1.0, 0.85, 0.3, 0.4)
const HIGHLIGHT_BORDER_COLOR := Color(1.0, 0.85, 0.3, 0.9)
const ARROW_COLOR := Color(1.0, 0.85, 0.3)
const TEXT_BG_COLOR := Color(0.1, 0.08, 0.15, 0.95)

var _overlay_bg: ColorRect = null
var _highlight_rect: ColorRect = null
var _highlight_border: ReferenceRect = null
var _arrow_node: Control = null
var _text_panel: PanelContainer = null
var _text_label: Label = null
var _next_button: Button = null
var _skip_button: Button = null
var _waiting_for_action: bool = false  # true이면 버튼 숨기고 액션 대기


func _ready() -> void:
	layer = 90  # 대부분의 UI 위에 표시
	_build_ui()


func _build_ui() -> void:
	# 전체 화면 반투명 오버레이
	_overlay_bg = ColorRect.new()
	_overlay_bg.color = OVERLAY_COLOR
	_overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay_bg)

	# 하이라이트 영역 (밝은 사각형)
	_highlight_rect = ColorRect.new()
	_highlight_rect.color = HIGHLIGHT_COLOR
	_highlight_rect.visible = false
	_highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_highlight_rect)

	# 화살표 노드 (삼각형 도형)
	_arrow_node = Control.new()
	_arrow_node.visible = false
	_arrow_node.custom_minimum_size = Vector2(40, 40)
	_arrow_node.size = Vector2(40, 40)
	_arrow_node.draw.connect(_draw_arrow)
	add_child(_arrow_node)

	# 텍스트 패널
	_text_panel = PanelContainer.new()
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = TEXT_BG_COLOR
	stylebox.set_border_width_all(2)
	stylebox.border_color = Color(1.0, 0.85, 0.3, 0.8)
	stylebox.set_corner_radius_all(8)
	stylebox.set_content_margin_all(20)
	_text_panel.add_theme_stylebox_override("panel", stylebox)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)

	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 18)
	_text_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	_text_label.custom_minimum_size = Vector2(400, 0)
	vbox.add_child(_text_label)

	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 16)

	_next_button = Button.new()
	_next_button.text = "다음"
	_next_button.add_theme_font_size_override("font_size", 18)
	_next_button.custom_minimum_size = Vector2(120, 40)
	_next_button.pressed.connect(_on_next_pressed)
	btn_container.add_child(_next_button)

	_skip_button = Button.new()
	_skip_button.text = "튜토리얼 건너뛰기"
	_skip_button.add_theme_font_size_override("font_size", 14)
	_skip_button.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_skip_button.custom_minimum_size = Vector2(160, 40)
	btn_container.add_child(_skip_button)

	vbox.add_child(btn_container)
	_text_panel.add_child(vbox)
	add_child(_text_panel)

	# 초기 숨김
	_text_panel.visible = false


## 설명 텍스트만 표시 (하이라이트 없이)
func show_message(text: String, wait_for_action: bool = false) -> void:
	_waiting_for_action = wait_for_action
	_text_label.text = text
	_text_panel.visible = true
	_highlight_rect.visible = false
	_arrow_node.visible = false
	_next_button.visible = not wait_for_action
	_next_button.text = "다음"

	# 텍스트 패널을 화면 중앙 하단에 배치
	_text_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - _text_panel.size.x) / 2.0,
		get_viewport().get_visible_rect().size.y - _text_panel.size.y - 40
	)

	# 마우스 입력 통과 설정
	if wait_for_action:
		_overlay_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		_overlay_bg.mouse_filter = Control.MOUSE_FILTER_STOP


## 특정 영역을 하이라이트하고 설명 텍스트를 표시
func highlight_area(rect: Rect2, text: String, arrow_dir: String = "down", wait_for_action: bool = false) -> void:
	_waiting_for_action = wait_for_action
	_text_label.text = text
	_text_panel.visible = true
	_next_button.visible = not wait_for_action
	_next_button.text = "다음"

	# 하이라이트 영역 표시
	_highlight_rect.position = rect.position
	_highlight_rect.size = rect.size
	_highlight_rect.visible = true

	# 화살표 배치
	_arrow_node.visible = true
	match arrow_dir:
		"down":
			_arrow_node.position = Vector2(
				rect.position.x + rect.size.x / 2.0 - 20,
				rect.position.y - 50
			)
			_arrow_node.rotation = 0
		"up":
			_arrow_node.position = Vector2(
				rect.position.x + rect.size.x / 2.0 - 20,
				rect.position.y + rect.size.y + 10
			)
			_arrow_node.rotation = PI
		"left":
			_arrow_node.position = Vector2(
				rect.position.x + rect.size.x + 10,
				rect.position.y + rect.size.y / 2.0 - 20
			)
			_arrow_node.rotation = -PI / 2
		"right":
			_arrow_node.position = Vector2(
				rect.position.x - 50,
				rect.position.y + rect.size.y / 2.0 - 20
			)
			_arrow_node.rotation = PI / 2

	# 텍스트 패널 위치: 하이라이트 영역 아래 또는 위
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_y: float
	if rect.position.y > viewport_size.y / 2.0:
		# 하이라이트가 하단이면 텍스트를 상단에 배치
		panel_y = 40.0
	else:
		# 하이라이트가 상단이면 텍스트를 하단에 배치
		panel_y = viewport_size.y - _text_panel.size.y - 40
	_text_panel.position = Vector2(
		(viewport_size.x - _text_panel.size.x) / 2.0,
		panel_y
	)

	# 마우스 입력 통과 설정
	if wait_for_action:
		_overlay_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		_overlay_bg.mouse_filter = Control.MOUSE_FILTER_STOP


## 액션 완료 시 외부에서 호출
func acknowledge_action() -> void:
	if _waiting_for_action:
		_waiting_for_action = false
		step_acknowledged.emit()


## 오버레이 숨기기
func hide_overlay() -> void:
	_text_panel.visible = false
	_highlight_rect.visible = false
	_arrow_node.visible = false
	_overlay_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE


## 오버레이 완전 제거
func cleanup() -> void:
	queue_free()


## 스킵 버튼에 콜백 연결
func connect_skip(callback: Callable) -> void:
	_skip_button.pressed.connect(callback)


func _on_next_pressed() -> void:
	step_acknowledged.emit()


func _draw_arrow() -> void:
	# 아래를 가리키는 삼각형 화살표 (회전으로 방향 변경)
	var points := PackedVector2Array([
		Vector2(20, 40),  # 하단 꼭짓점
		Vector2(0, 0),    # 좌상
		Vector2(40, 0),   # 우상
	])
	_arrow_node.draw_colored_polygon(points, ARROW_COLOR)
