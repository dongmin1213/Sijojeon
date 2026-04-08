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
# v4: 카드 크기 대폭 확대 — 가독성과 터치 타겟 우선
const BASE_CARD_WIDTH := 380.0
const BASE_CARD_HEIGHT := 580.0
const BASE_VIEWPORT_WIDTH := 1080.0

# 카드 타입별 색상 — v5: 오방색 팔레트, 보라색 제거
const TYPE_COLORS := {
	"attack": Color(0.76, 0.23, 0.13),    # 적 (오방색 빨강 #C23B22)
	"defense": Color(0.18, 0.31, 0.56),   # 청 (오방색 파랑 #2E5090)
	"spell": Color(0.18, 0.31, 0.56),     # 청 (도사 — 학자의 색)
	"movement": Color(0.23, 0.49, 0.27),  # 송록 (소나무 녹색)
	"formation": Color(0.76, 0.23, 0.13), # 황 (오방색 노랑 #D4A017)
}

# 희귀도별 색상 — v5: 오방색 기반 재질감
const RARITY_COLORS := {
	1: Color(0.45, 0.42, 0.38),  # 나무 (일반)
	2: Color(0.55, 0.45, 0.30),  # 청동 (고급)
	3: Color(0.65, 0.68, 0.72),  # 은 (희귀)
	4: Color(0.76, 0.23, 0.13),  # 적옥 (영웅 — 오방색 적)
	5: Color(0.76, 0.23, 0.13),  # 금박 (전설 — 오방색 황)
}

# v6: 카드 프레임 SVG 텍스처 경로 (희귀도별)
const FRAME_PATHS := {
	1: "res://art/ui/card_frame_common.svg",
	2: "res://art/ui/card_frame_uncommon.svg",
	3: "res://art/ui/card_frame_rare.svg",
	4: "res://art/ui/card_frame_rare.svg",
	5: "res://art/ui/card_frame_legendary.svg",
}

# 기본 스타일 (코드로 생성)
var _normal_stylebox: StyleBoxFlat
var _hover_stylebox: StyleBoxFlat
var _selected_stylebox: StyleBoxFlat
var _disabled_stylebox: StyleBoxFlat
var _drag_stylebox: StyleBoxFlat
var _sijo_match_stylebox: StyleBoxFlat

# v6: 프레임 텍스처 캐시
var _frame_stylebox_cache: Dictionary = {}  # rarity → StyleBoxTexture

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
	# v5: 오방색 스타일 — 흑 기반, 따뜻한 테두리
	_normal_stylebox = StyleBoxFlat.new()
	_normal_stylebox.bg_color = Color(0.12, 0.11, 0.10)
	_normal_stylebox.border_color = Color(0.25, 0.23, 0.20)
	_normal_stylebox.set_border_width_all(2)
	_normal_stylebox.set_corner_radius_all(14)
	_normal_stylebox.shadow_color = Color(0, 0, 0, 0.4)
	_normal_stylebox.shadow_size = 8
	_normal_stylebox.shadow_offset = Vector2(0, 4)

	_hover_stylebox = StyleBoxFlat.new()
	_hover_stylebox.bg_color = Color(0.16, 0.15, 0.13)
	_hover_stylebox.border_color = Color(0.76, 0.23, 0.13, 0.9)
	_hover_stylebox.set_border_width_all(2)
	_hover_stylebox.set_corner_radius_all(14)
	_hover_stylebox.shadow_color = Color(0.76, 0.23, 0.13, 0.2)
	_hover_stylebox.shadow_size = 10
	_hover_stylebox.shadow_offset = Vector2(0, 2)

	_selected_stylebox = StyleBoxFlat.new()
	_selected_stylebox.bg_color = Color(0.18, 0.17, 0.15)
	_selected_stylebox.border_color = Color(0.76, 0.23, 0.13, 1.0)
	_selected_stylebox.set_border_width_all(3)
	_selected_stylebox.set_corner_radius_all(14)
	_selected_stylebox.shadow_color = Color(0.76, 0.23, 0.13, 0.3)
	_selected_stylebox.shadow_size = 12
	_selected_stylebox.shadow_offset = Vector2(0, 2)

	_disabled_stylebox = StyleBoxFlat.new()
	_disabled_stylebox.bg_color = Color(0.08, 0.08, 0.07)
	_disabled_stylebox.border_color = Color(0.18, 0.17, 0.15, 0.5)
	_disabled_stylebox.set_border_width_all(1)
	_disabled_stylebox.set_corner_radius_all(14)

	_drag_stylebox = StyleBoxFlat.new()
	_drag_stylebox.bg_color = Color(0.20, 0.19, 0.17)
	_drag_stylebox.border_color = Color(0.76, 0.23, 0.13, 1.0)
	_drag_stylebox.set_border_width_all(3)
	_drag_stylebox.set_corner_radius_all(14)
	_drag_stylebox.shadow_color = Color(0.76, 0.23, 0.13, 0.25)
	_drag_stylebox.shadow_size = 14
	_drag_stylebox.shadow_offset = Vector2(0, 4)

	# 시조 비트 매칭 카드 — 금색 글로우 (초록보다 테마에 맞음)
	_sijo_match_stylebox = StyleBoxFlat.new()
	_sijo_match_stylebox.bg_color = Color(0.14, 0.12, 0.08)
	_sijo_match_stylebox.border_color = Color(0.76, 0.23, 0.13, 1.0)
	_sijo_match_stylebox.set_border_width_all(4)
	_sijo_match_stylebox.set_corner_radius_all(14)
	_sijo_match_stylebox.shadow_color = Color(0.76, 0.23, 0.13, 0.35)
	_sijo_match_stylebox.shadow_size = 10


func _apply_font_scaling(scale: float) -> void:
	## 뷰포트 비율에 맞게 카드 내부 폰트 크기와 요소 높이를 조정한다.
	# v4: 최소 폰트 크기 대폭 상향, 모바일 가독성 최우선
	var name_size := AccessibilityManager.scaled_font_size(maxi(int(32 * scale), 28))
	var cost_size := AccessibilityManager.scaled_font_size(maxi(int(26 * scale), 22))
	var type_size := AccessibilityManager.scaled_font_size(maxi(int(24 * scale), 22))
	var effect_size := AccessibilityManager.scaled_font_size(maxi(int(24 * scale), 21))
	var sijo_size := AccessibilityManager.scaled_font_size(maxi(int(28 * scale), 24))

	card_name_label.add_theme_font_size_override("font_size", name_size)
	beat_cost_label.add_theme_font_size_override("font_size", cost_size)
	type_label.add_theme_font_size_override("font_size", type_size)
	effect_label.add_theme_font_size_override("font_size", effect_size)
	sijo_indicator.add_theme_font_size_override("font_size", sijo_size)

	# 카드 내부 요소 최소 높이도 비율에 맞게 조정
	card_name_label.custom_minimum_size.y = 52 * scale
	card_art.custom_minimum_size.y = 130 * scale
	effect_label.custom_minimum_size.y = 130 * scale


func _update_display() -> void:
	if card_data == null:
		return

	# v6: 카드 이름 — 금색 강조, 강화 시 + 표시
	var display_name := card_data.get_display_name()
	if card_data.upgraded:
		display_name += "+"
	card_name_label.text = display_name
	card_name_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))

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
		sijo_indicator.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
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
		# v6: 카드 프레임 텍스처 우선 사용, 없으면 StyleBoxFlat fallback
		var frame_sb: StyleBoxTexture = null
		if card_data:
			var type_tint := _get_type_border_color(card_data.type)
			# 프레임 색조: 타입 색상을 밝게 섞어서 프레임에 적용
			var tint := type_tint.lightened(0.3)
			frame_sb = _make_frame_stylebox(card_data.rarity, tint)
		if frame_sb:
			add_theme_stylebox_override("panel", frame_sb)
		else:
			var typed_style := _normal_stylebox.duplicate()
			if card_data:
				var type_bg := _get_type_bg_color(card_data.type)
				typed_style.bg_color = type_bg
				typed_style.border_color = _get_type_border_color(card_data.type)
			add_theme_stylebox_override("panel", typed_style)
		modulate = Color(1, 1, 1, 1)


func _start_sijo_glow() -> void:
	## 시조 매칭 카드에 부드러운 테두리 펄스 애니메이션
	if not is_inside_tree():
		return
	if _sijo_glow_tween and _sijo_glow_tween.is_valid():
		_sijo_glow_tween.kill()
	_sijo_glow_tween = create_tween().set_loops()
	_sijo_glow_tween.tween_method(_set_sijo_border_alpha, 0.3, 1.0, 0.5)
	_sijo_glow_tween.tween_method(_set_sijo_border_alpha, 1.0, 0.3, 0.5)


func _set_sijo_border_alpha(alpha: float) -> void:
	if _sijo_match_stylebox:
		_sijo_match_stylebox.border_color = Color(0.76, 0.23, 0.13, alpha)


func _make_frame_stylebox(rarity: int, tint: Color = Color.WHITE) -> StyleBoxTexture:
	## v6: 카드 프레임 SVG를 StyleBoxTexture로 변환. nine-patch 마진 설정.
	var cache_key := rarity * 1000 + tint.to_rgba32()
	if _frame_stylebox_cache.has(cache_key):
		return _frame_stylebox_cache[cache_key].duplicate()
	var path: String = FRAME_PATHS.get(rarity, FRAME_PATHS[1])
	if not ResourceLoader.exists(path):
		return null
	var tex = load(path) as Texture2D
	if not tex:
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	# SVG는 160x220 — nine-patch 마진 설정
	sb.texture_margin_left = 12
	sb.texture_margin_right = 12
	sb.texture_margin_top = 42
	sb.texture_margin_bottom = 12
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.modulate_color = tint
	_frame_stylebox_cache[cache_key] = sb
	return sb.duplicate()


func _get_type_bg_color(type: String) -> Color:
	## 카드 타입별 배경색 — v5: 오방색 흑 기반, 타입별 은은한 색조
	match type:
		"attack": return Color(0.16, 0.08, 0.06)    # 흑+적
		"defense": return Color(0.06, 0.10, 0.16)   # 흑+청
		"spell": return Color(0.06, 0.10, 0.16)     # 흑+청
		"movement": return Color(0.06, 0.14, 0.08)  # 흑+송록
		"formation": return Color(0.16, 0.13, 0.04) # 흑+황
		_: return Color(0.12, 0.11, 0.10)


func _get_type_border_color(type: String) -> Color:
	## 카드 타입별 테두리색 — v5: 오방색 팔레트
	match type:
		"attack": return Color(0.76, 0.23, 0.13)
		"defense": return Color(0.18, 0.31, 0.56)
		"spell": return Color(0.18, 0.31, 0.56)
		"movement": return Color(0.23, 0.49, 0.27)
		"formation": return Color(0.76, 0.23, 0.13)
		_: return Color(0.25, 0.23, 0.20)


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
