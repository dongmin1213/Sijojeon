class_name CardHand
extends Control

## 카드 핸드 UI. 카드를 부채꼴로 배치하고 선택/드래그/플레이 인터랙션을 관리한다.

signal card_played(hand_index: int, target_enemy_index: int)
signal card_zoom_requested(card_data: CardData)

const CardUIScene := preload("res://scenes/ui/card_ui.tscn")

# 부채꼴 배치 파라미터
@export var fan_spread_degrees: float = 5.0   # 카드 간 회전 각도
@export var fan_y_curve: float = 20.0         # 부채꼴 높이 커브
@export var hover_lift: float = 30.0          # 호버 시 위로 올라가는 높이
@export var select_lift: float = 50.0         # 선택 시 위로 올라가는 높이

# 뷰포트 기준 비율 (1080x1920 기본 해상도 기준)
const BASE_WIDTH := 1080.0
# 카드 간격: 카드 너비의 배수로 설정.
const MAX_CARD_SPACING := 190.0    # 넉넉할 때 카드 간 간격
const MIN_CARD_SPACING := 130.0    # 카드 너비의 약 57% — 겹침 허용
# 손패 카드 수에 따른 카드 크기 스케일 (가독성 확보)
const HAND_SCALE_THRESHOLD := 5    # 이 수 이상이면 카드 축소 시작
const MIN_HAND_SCALE := 0.8        # 카드 최소 축소 비율

var card_widgets: Array[CardUI] = []
var selected_index: int = -1
var hovered_index: int = -1
var dragging_index: int = -1

# 외부에서 참조할 상태
var current_qi: int = 0
var next_sijo_beat: int = -1  # 시조 시스템의 다음 필요 비트

# 배치 최적화: dirty flag로 프레임당 최대 1회 재배치
var _layout_dirty: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _process(_delta: float) -> void:
	if not is_inside_tree():
		return
	if _layout_dirty:
		_layout_dirty = false
		_arrange_cards()
		set_process(false)


func _mark_layout_dirty() -> void:
	## 레이아웃 재계산을 다음 프레임으로 지연시킨다.
	if not _layout_dirty:
		_layout_dirty = true
		set_process(true)


func update_hand(hand_ids: Array[String], qi: int, sijo_beat: int, bm: BattleManager = null) -> void:
	current_qi = qi
	next_sijo_beat = sijo_beat
	selected_index = -1
	hovered_index = -1
	dragging_index = -1

	# 기존 위젯 제거 (시그널 정리 후 해제)
	for widget in card_widgets:
		if widget.card_clicked.is_connected(_on_card_clicked):
			widget.card_clicked.disconnect(_on_card_clicked)
		if widget.card_hovered.is_connected(_on_card_hovered):
			widget.card_hovered.disconnect(_on_card_hovered)
		if widget.card_unhovered.is_connected(_on_card_unhovered):
			widget.card_unhovered.disconnect(_on_card_unhovered)
		if widget.card_drag_started.is_connected(_on_card_drag_started):
			widget.card_drag_started.disconnect(_on_card_drag_started)
		if widget.card_drag_ended.is_connected(_on_card_drag_ended):
			widget.card_drag_ended.disconnect(_on_card_drag_ended)
		if widget.card_zoom_requested.is_connected(_on_card_zoom_requested):
			widget.card_zoom_requested.disconnect(_on_card_zoom_requested)
		widget.queue_free()
	card_widgets.clear()

	# 새 카드 위젯 생성
	for i in hand_ids.size():
		var card_id: String = hand_ids[i]
		var card: CardData = DataLoader.get_card(card_id)
		if card == null:
			continue

		# 강화 상태 반영
		if GameManager.run_data and card_id in GameManager.run_data.upgraded_cards:
			card = card.duplicate_card()
			card.upgraded = true

		var widget: CardUI = CardUIScene.instantiate()
		add_child(widget)

		var playable := bm.can_play_card(card) if bm else card.cost <= qi
		var matches_sijo := (sijo_beat > 0 and card.beat == sijo_beat)
		widget.setup(card, i, playable, matches_sijo)

		widget.card_clicked.connect(_on_card_clicked)
		widget.card_hovered.connect(_on_card_hovered)
		widget.card_unhovered.connect(_on_card_unhovered)
		widget.card_drag_started.connect(_on_card_drag_started)
		widget.card_drag_ended.connect(_on_card_drag_ended)
		widget.card_zoom_requested.connect(_on_card_zoom_requested)

		card_widgets.append(widget)

	_arrange_cards()


func _arrange_cards() -> void:
	var count := card_widgets.size()
	if count == 0:
		return

	# 뷰포트 너비에 비례하여 카드 간격 계산
	var scale_factor := size.x / BASE_WIDTH

	# 손패 수에 따른 카드 크기 동적 조정
	var hand_scale := 1.0
	if count > HAND_SCALE_THRESHOLD:
		# 카드 수가 임계값 초과 시 점진적 축소 (최대 10장 기준)
		var excess := float(count - HAND_SCALE_THRESHOLD) / float(10 - HAND_SCALE_THRESHOLD)
		hand_scale = lerpf(1.0, MIN_HAND_SCALE, clampf(excess, 0.0, 1.0))

	# 카드 크기 조정 적용
	var base_card_w := CardUI.BASE_CARD_WIDTH * scale_factor
	var base_card_h := CardUI.BASE_CARD_HEIGHT * scale_factor
	var scaled_card_w := base_card_w * hand_scale
	var scaled_card_h := base_card_h * hand_scale
	for widget in card_widgets:
		widget.custom_minimum_size = Vector2(scaled_card_w, scaled_card_h)
		widget.size = Vector2(scaled_card_w, scaled_card_h)

	var card_w := scaled_card_w
	# 사용 가능 영역의 95%를 카드 배치에 활용 (좌우 여백 2.5%씩)
	var available_width := size.x * 0.95
	# 이상적 간격: 카드 너비 + 약간의 여백
	var ideal_spacing := MAX_CARD_SPACING * scale_factor * hand_scale
	# 필요한 전체 폭 = (count-1) * spacing + card_w
	var needed_width := (count - 1) * ideal_spacing + card_w
	var card_spacing := ideal_spacing
	if count > 1 and needed_width > available_width:
		# 공간이 부족하면 간격 축소 (최소 간격까지)
		card_spacing = (available_width - card_w) / float(count - 1)
		card_spacing = maxf(card_spacing, MIN_CARD_SPACING * scale_factor * hand_scale)

	var center_x := size.x / 2.0
	var base_y := size.y * 0.05
	var total_width := (count - 1) * card_spacing
	var start_x := center_x - total_width / 2.0

	# 부채꼴 커브도 높이에 비례
	var height_scale := size.y / 1920.0
	var scaled_y_curve := fan_y_curve * height_scale

	for i in count:
		var widget := card_widgets[i]

		# 드래그 중인 카드는 배치에서 제외
		if i == dragging_index:
			continue

		var t := 0.0 if count == 1 else float(i) / float(count - 1)
		var centered_t := t - 0.5  # -0.5 ~ 0.5

		# 위치 계산
		var x := start_x + i * card_spacing - widget.size.x / 2.0
		var y := base_y + scaled_y_curve * (centered_t * centered_t * 4.0)

		# 호버/선택 시 올림 (뷰포트 높이에 비례)
		if i == selected_index:
			y -= select_lift * height_scale
		elif i == hovered_index:
			y -= hover_lift * height_scale

		# 회전 계산 (부채꼴)
		var rotation_deg := centered_t * fan_spread_degrees * (count - 1)

		widget.position = Vector2(x, y)
		widget.rotation_degrees = rotation_deg
		widget.z_index = i
		if i == hovered_index or i == selected_index:
			widget.z_index = count + 1


func _on_card_clicked(hand_index: int) -> void:
	if dragging_index >= 0:
		return  # 드래그 중에는 클릭 무시

	if selected_index == hand_index:
		# 이미 선택된 카드를 다시 클릭 → 첫 번째 적에게 플레이
		card_played.emit(hand_index, 0)
		selected_index = -1
		_deselect_all()
		_mark_layout_dirty()
	else:
		# 카드 선택
		_deselect_all()
		selected_index = hand_index
		if hand_index >= 0 and hand_index < card_widgets.size():
			card_widgets[hand_index].set_selected(true)
		_mark_layout_dirty()


func _on_card_hovered(hand_index: int) -> void:
	if dragging_index >= 0:
		return
	hovered_index = hand_index
	_mark_layout_dirty()


func _on_card_unhovered(_hand_index: int) -> void:
	if dragging_index >= 0:
		return
	hovered_index = -1
	_mark_layout_dirty()


func _on_card_drag_started(hand_index: int) -> void:
	dragging_index = hand_index
	# 드래그 시작 시 선택 해제
	_deselect_all()
	selected_index = -1
	hovered_index = -1


func _on_card_drag_ended(hand_index: int, played: bool) -> void:
	dragging_index = -1
	if played:
		# 위로 드래그 → 카드 플레이 (첫 번째 적 타겟)
		card_played.emit(hand_index, 0)
	else:
		# 원래 위치로 복원
		_mark_layout_dirty()


func play_selected_on_target(target_enemy_index: int) -> void:
	if selected_index >= 0:
		card_played.emit(selected_index, target_enemy_index)
		selected_index = -1
		_deselect_all()


func _deselect_all() -> void:
	for widget in card_widgets:
		widget.set_selected(false)


func _on_card_zoom_requested(card_data: CardData) -> void:
	card_zoom_requested.emit(card_data)


func get_selected_index() -> int:
	return selected_index
