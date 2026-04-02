class_name CardUI
extends PanelContainer

## 개별 카드 UI 위젯. 카드 데이터를 표시하고 호버/선택/드래그 상태를 관리한다.

signal card_clicked(hand_index: int)
signal card_hovered(hand_index: int)
signal card_unhovered(hand_index: int)
signal card_drag_started(hand_index: int)
signal card_drag_ended(hand_index: int, played: bool)
signal card_zoom_requested(card_data: CardData)

@onready var card_name_label: Label = $MarginContainer/VBoxContainer/CardNameLabel
@onready var card_art: TextureRect = $MarginContainer/VBoxContainer/CardArt
@onready var beat_cost_label: Label = $MarginContainer/VBoxContainer/BeatCostRow/BeatCostLabel
@onready var type_label: Label = $MarginContainer/VBoxContainer/TypeLabel
@onready var effect_label: Label = $MarginContainer/VBoxContainer/EffectLabel
@onready var rarity_bar: ColorRect = $MarginContainer/VBoxContainer/RarityBar
@onready var sijo_indicator: Label = $MarginContainer/VBoxContainer/BeatCostRow/SijoIndicator

var hand_index: int = -1
var card_data: CardData = null
var is_playable: bool = true
var is_selected: bool = false
var is_hovered: bool = false
var sijo_match: bool = false  # 시조 슬롯과 비트 일치 여부

# 드래그 관련 상태
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var original_rotation: float = 0.0
var original_z_index: int = 0

const DRAG_THRESHOLD := 15.0   # 드래그 시작 최소 거리 (px)
const PLAY_THRESHOLD := 80.0   # 위로 드래그 시 카드 플레이 최소 거리 (px)
const LONG_PRESS_TIME := 0.5   # 길게 누르기 감지 시간 (초)

# 길게 누르기 상태
var _long_press_timer: Timer = null
var _long_press_triggered: bool = false

# 뷰포트 기준 카드 크기 비율 (1080x1920 기본 해상도 기준)
const BASE_CARD_WIDTH := 140.0
const BASE_CARD_HEIGHT := 200.0
const BASE_VIEWPORT_WIDTH := 1080.0

# 카드 타입별 색상
const TYPE_COLORS := {
	"attack": Color(0.85, 0.25, 0.2),
	"defense": Color(0.2, 0.55, 0.85),
	"spell": Color(0.6, 0.3, 0.85),
	"movement": Color(0.2, 0.75, 0.45),
	"formation": Color(0.85, 0.65, 0.15),
}

# 희귀도별 색상
const RARITY_COLORS := {
	1: Color(0.5, 0.5, 0.5),     # 회색
	2: Color(0.3, 0.7, 0.3),     # 초록
	3: Color(0.3, 0.5, 0.9),     # 파랑
	4: Color(0.7, 0.3, 0.9),     # 보라
	5: Color(0.9, 0.7, 0.1),     # 금색
}

# 기본 스타일 (코드로 생성)
var _normal_stylebox: StyleBoxFlat
var _hover_stylebox: StyleBoxFlat
var _selected_stylebox: StyleBoxFlat
var _disabled_stylebox: StyleBoxFlat
var _drag_stylebox: StyleBoxFlat


func _ready() -> void:
	_create_styleboxes()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 뷰포트 너비에 비례하여 카드 크기 조정
	var vp_width := get_viewport().get_visible_rect().size.x
	var scale := vp_width / BASE_VIEWPORT_WIDTH
	custom_minimum_size = Vector2(BASE_CARD_WIDTH * scale, BASE_CARD_HEIGHT * scale)

	# 길게 누르기 타이머 초기화
	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.wait_time = LONG_PRESS_TIME
	_long_press_timer.timeout.connect(_on_long_press)
	add_child(_long_press_timer)


func setup(data: CardData, index: int, playable: bool, matches_sijo: bool) -> void:
	card_data = data
	hand_index = index
	is_playable = playable
	sijo_match = matches_sijo

	if not is_node_ready():
		await ready

	_update_display()
	_update_style()


func _create_styleboxes() -> void:
	_normal_stylebox = StyleBoxFlat.new()
	_normal_stylebox.bg_color = Color(0.18, 0.16, 0.22)
	_normal_stylebox.border_color = Color(0.4, 0.35, 0.5)
	_normal_stylebox.set_border_width_all(2)
	_normal_stylebox.set_corner_radius_all(8)

	_hover_stylebox = StyleBoxFlat.new()
	_hover_stylebox.bg_color = Color(0.22, 0.20, 0.28)
	_hover_stylebox.border_color = Color(0.7, 0.6, 0.9)
	_hover_stylebox.set_border_width_all(3)
	_hover_stylebox.set_corner_radius_all(8)

	_selected_stylebox = StyleBoxFlat.new()
	_selected_stylebox.bg_color = Color(0.25, 0.22, 0.35)
	_selected_stylebox.border_color = Color(1.0, 0.85, 0.3)
	_selected_stylebox.set_border_width_all(3)
	_selected_stylebox.set_corner_radius_all(8)

	_disabled_stylebox = StyleBoxFlat.new()
	_disabled_stylebox.bg_color = Color(0.12, 0.11, 0.14)
	_disabled_stylebox.border_color = Color(0.25, 0.22, 0.3)
	_disabled_stylebox.set_border_width_all(2)
	_disabled_stylebox.set_corner_radius_all(8)

	_drag_stylebox = StyleBoxFlat.new()
	_drag_stylebox.bg_color = Color(0.28, 0.24, 0.38)
	_drag_stylebox.border_color = Color(1.0, 0.9, 0.4)
	_drag_stylebox.set_border_width_all(3)
	_drag_stylebox.set_corner_radius_all(8)


func _update_display() -> void:
	if card_data == null:
		return

	# 카드 이름 (강화 시 + 표시)
	var display_name := card_data.get_display_name()
	if card_data.upgraded:
		display_name += "+"
	card_name_label.text = display_name

	# 카드 일러스트 (TextureManager에서 로드, 없으면 placeholder)
	card_art.texture = TextureManager.get_card_texture(card_data.id, card_data.type)

	# 비트 + 코스트 + 기력
	var cost_text := "[%d] %d氣" % [card_data.beat, card_data.cost]
	if card_data.stamina_cost > 0:
		cost_text += " %d力" % card_data.stamina_cost
	elif card_data.stamina_gain > 0:
		cost_text += " +%d力" % card_data.stamina_gain
	beat_cost_label.text = cost_text

	# 타입 표시
	var type_names := {
		"attack": "공격",
		"defense": "방어",
		"spell": "주술",
		"movement": "이동",
		"formation": "진형",
	}
	type_label.text = type_names.get(card_data.type, card_data.type)
	var type_color: Color = AccessibilityManager.get_type_color(card_data.type)
	type_label.add_theme_color_override("font_color", type_color)

	# 효과 텍스트
	effect_label.text = card_data.get_current_effect()

	# 희귀도 바
	var rarity_color: Color = RARITY_COLORS.get(card_data.rarity, Color(0.5, 0.5, 0.5))
	rarity_bar.color = rarity_color

	# 시조 비트 일치 표시
	if sijo_match:
		sijo_indicator.text = "♪"
		sijo_indicator.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		sijo_indicator.visible = true
	else:
		sijo_indicator.visible = false


func _update_style() -> void:
	if not is_playable:
		add_theme_stylebox_override("panel", _disabled_stylebox)
		modulate = Color(0.6, 0.6, 0.6, 0.8)
	elif is_dragging:
		add_theme_stylebox_override("panel", _drag_stylebox)
		modulate = Color(1, 1, 1, 1)
	elif is_selected:
		add_theme_stylebox_override("panel", _selected_stylebox)
		modulate = Color(1, 1, 1, 1)
	elif is_hovered:
		add_theme_stylebox_override("panel", _hover_stylebox)
		modulate = Color(1, 1, 1, 1)
	else:
		add_theme_stylebox_override("panel", _normal_stylebox)
		modulate = Color(1, 1, 1, 1)


func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_style()


func save_layout_state() -> void:
	original_position = position
	original_rotation = rotation_degrees
	original_z_index = z_index


func restore_layout_state() -> void:
	position = original_position
	rotation_degrees = original_rotation
	z_index = original_z_index


func _on_mouse_entered() -> void:
	if not is_dragging:
		is_hovered = true
		_update_style()
		card_hovered.emit(hand_index)


func _on_mouse_exited() -> void:
	if not is_dragging:
		is_hovered = false
		_update_style()
		card_unhovered.emit(hand_index)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_long_press_triggered = false
				_long_press_timer.start()
				if is_playable:
					drag_start_pos = event.global_position
					drag_offset = Vector2.ZERO
			else:
				_long_press_timer.stop()
				# 마우스 버튼 떼기
				if _long_press_triggered:
					_long_press_triggered = false
					return  # 길게 누르기 후에는 다른 액션 무시
				if is_dragging:
					_end_drag()
				elif is_playable:
					# 드래그 아님 → 클릭으로 처리
					card_clicked.emit(hand_index)
		# 우클릭: 카드 상세보기
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if card_data:
				card_zoom_requested.emit(card_data)

	elif event is InputEventMouseMotion:
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			return
		if is_playable and not is_dragging and not _long_press_triggered:
			var delta: Vector2 = event.global_position - drag_start_pos
			if delta.length() > DRAG_THRESHOLD:
				_long_press_timer.stop()
				_start_drag()
		if is_dragging:
			_process_drag(event.global_position)


func _start_drag() -> void:
	is_dragging = true
	save_layout_state()
	z_index = 100
	rotation_degrees = 0.0
	_update_style()
	card_drag_started.emit(hand_index)


func _process_drag(global_pos: Vector2) -> void:
	var delta := global_pos - drag_start_pos
	position = original_position + delta


func _on_long_press() -> void:
	## 길게 누르기: 카드 상세보기 팝업
	_long_press_triggered = true
	if card_data:
		card_zoom_requested.emit(card_data)


func _end_drag() -> void:
	var delta_y := position.y - original_position.y
	var played := delta_y < -PLAY_THRESHOLD  # 위로 드래그해서 플레이
	is_dragging = false

	if not played:
		restore_layout_state()

	_update_style()
	card_drag_ended.emit(hand_index, played)
