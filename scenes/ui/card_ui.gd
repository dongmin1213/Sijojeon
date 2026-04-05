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
const DRAG_MOVE_THRESHOLD_SQ := 4.0  # 드래그 중 미세 이동 무시 임계값 (2px^2)

# 드래그 중 마지막 처리 위치
var _last_drag_global_pos: Vector2 = Vector2.ZERO

# 길게 누르기 상태
var _long_press_timer: Timer = null
var _long_press_triggered: bool = false

# 뷰포트 기준 카드 크기 비율 (1080x1920 기본 해상도 기준)
const BASE_CARD_WIDTH := 280.0
const BASE_CARD_HEIGHT := 400.0
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
var _sijo_match_stylebox: StyleBoxFlat

# 시조 매칭 글로우 애니메이션
var _sijo_glow_tween: Tween = null


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
	# 카드 내부 폰트 크기를 뷰포트 비율에 맞게 조정
	_apply_font_scaling(scale)

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

	# setup 완료 후 카드 크기를 강제 고정 (PanelContainer 자동 확장 방지)
	var parent_hand := get_parent() as CardHand
	if parent_hand:
		parent_hand._mark_layout_dirty()


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

	# 시조 비트 매칭 카드 — 초록 글로우 테두리
	_sijo_match_stylebox = StyleBoxFlat.new()
	_sijo_match_stylebox.bg_color = Color(0.12, 0.22, 0.15)  # 약간 녹색 틴트
	_sijo_match_stylebox.border_color = Color(0.3, 1.0, 0.5)
	_sijo_match_stylebox.set_border_width_all(5)  # 두꺼운 보더로 눈에 띄게
	_sijo_match_stylebox.set_corner_radius_all(8)
	_sijo_match_stylebox.shadow_color = Color(0.2, 0.9, 0.4, 0.4)
	_sijo_match_stylebox.shadow_size = 6  # 외부 글로우 효과


func _apply_font_scaling(scale: float) -> void:
	## 뷰포트 비율에 맞게 카드 내부 폰트 크기와 요소 높이를 조정한다.
	# 최소 폰트 크기를 보장하여 가독성 확보 (모바일 기준 상향)
	var name_size := AccessibilityManager.scaled_font_size(maxi(int(26 * scale), 22))
	var cost_size := AccessibilityManager.scaled_font_size(maxi(int(22 * scale), 18))
	var type_size := AccessibilityManager.scaled_font_size(maxi(int(22 * scale), 18))
	var effect_size := AccessibilityManager.scaled_font_size(maxi(int(20 * scale), 17))
	var sijo_size := AccessibilityManager.scaled_font_size(maxi(int(24 * scale), 20))

	card_name_label.add_theme_font_size_override("font_size", name_size)
	beat_cost_label.add_theme_font_size_override("font_size", cost_size)
	type_label.add_theme_font_size_override("font_size", type_size)
	effect_label.add_theme_font_size_override("font_size", effect_size)
	sijo_indicator.add_theme_font_size_override("font_size", sijo_size)

	# 카드 내부 요소 최소 높이도 비율에 맞게 조정
	card_name_label.custom_minimum_size.y = 44 * scale
	card_art.custom_minimum_size.y = 100 * scale
	effect_label.custom_minimum_size.y = 90 * scale


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
	var cost_text := tr("CARD_BEAT_COST_FMT") % [card_data.beat, card_data.cost]
	if card_data.stamina_cost > 0:
		cost_text += tr("CARD_STAMINA_COST_FMT") % card_data.stamina_cost
	elif card_data.stamina_gain > 0:
		cost_text += tr("CARD_STAMINA_GAIN_FMT") % card_data.stamina_gain
	beat_cost_label.text = cost_text

	# 타입 표시
	var type_names := {
		"attack": tr("CARD_TYPE_ATTACK"),
		"defense": tr("CARD_TYPE_DEFENSE"),
		"spell": tr("CARD_TYPE_SPELL_ALT"),
		"movement": tr("CARD_TYPE_MOVEMENT"),
		"formation": tr("CARD_TYPE_FORMATION"),
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
	# 기존 글로우 애니메이션 정리
	if _sijo_glow_tween and _sijo_glow_tween.is_valid():
		_sijo_glow_tween.kill()
		_sijo_glow_tween = null

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
	elif sijo_match and is_playable:
		add_theme_stylebox_override("panel", _sijo_match_stylebox)
		modulate = Color(1, 1, 1, 1)
		_start_sijo_glow()
	else:
		add_theme_stylebox_override("panel", _normal_stylebox)
		modulate = Color(1, 1, 1, 1)


func _start_sijo_glow() -> void:
	## 시조 매칭 카드에 부드러운 테두리 펄스 애니메이션
	if not is_inside_tree():
		return
	_sijo_glow_tween = create_tween().set_loops()
	_sijo_glow_tween.tween_method(_set_sijo_border_alpha, 0.3, 1.0, 0.5)
	_sijo_glow_tween.tween_method(_set_sijo_border_alpha, 1.0, 0.3, 0.5)


func _set_sijo_border_alpha(alpha: float) -> void:
	if _sijo_match_stylebox:
		_sijo_match_stylebox.border_color = Color(0.3, 1.0, 0.5, alpha)


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
			# length_squared로 비교하여 sqrt 호출 방지
			if delta.length_squared() > DRAG_THRESHOLD * DRAG_THRESHOLD:
				_long_press_timer.stop()
				_start_drag()
		if is_dragging:
			# 미세한 이동(2px 미만)은 무시하여 불필요한 위치 업데이트 방지
			if event.global_position.distance_squared_to(_last_drag_global_pos) > DRAG_MOVE_THRESHOLD_SQ:
				_last_drag_global_pos = event.global_position
				_process_drag(event.global_position)


func _start_drag() -> void:
	is_dragging = true
	_last_drag_global_pos = drag_start_pos
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
