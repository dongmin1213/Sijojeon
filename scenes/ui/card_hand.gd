class_name CardHand
extends Control

## 카드 핸드 UI. 카드를 하단 숨김 + 호버 팝업 방식으로 표시한다.
## StS2 스타일: 카드가 화면 하단에 절반 숨겨져 있고, 탭/호버 시 올라온다.

signal card_played(hand_index: int, target_enemy_index: int)
signal card_zoom_requested(card_data: CardData)

const CardUIScene := preload("res://scenes/ui/card_ui.tscn")

# 하단 숨김 배치 파라미터 — v9: StS2 스타일
@export var fan_spread_degrees: float = 3.0   # 카드 간 회전 각도 (미니멀)
@export var fan_y_curve: float = 8.0          # 부채꼴 높이 커브 (완만)
@export var hover_lift: float = 280.0         # 호버 시 위로 올라가는 높이 (카드 전체가 보이도록)
@export var select_lift: float = 320.0        # 선택 시 위로 올라가는 높이
@export var card_peek_ratio: float = 0.35     # 숨김 상태에서 보이는 카드 비율 (35% — 이름+코스트 가시성)

# 뷰포트 기준 비율 (1080x1920 기본 해상도 기준)
const BASE_WIDTH := 1080.0
# v9: 카드 간격 — 하단 숨김 상태에서는 이름만 보이므로 넓게
const MAX_CARD_SPACING := 220.0    # 넉넉할 때 카드 간 간격
const MIN_CARD_SPACING := 120.0    # 겹침 최소화
# 손패 카드 수에 따른 카드 크기 스케일 (가독성 확보)
const HAND_SCALE_THRESHOLD := 4    # 4장 초과 시 축소 시작
const MIN_HAND_SCALE := 0.70       # 카드 최소 축소 비율

# 호버/선택 트윈 애니메이션 시간
const TWEEN_DURATION := 0.15

var card_widgets: Array[CardUI] = []
var _widget_pool: Array[CardUI] = []  # 재사용 가능한 CardUI 풀
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

	# 기존 위젯을 풀로 반환 (시그널 정리 후 숨기기)
	for widget in card_widgets:
		_return_to_pool(widget)
	card_widgets.clear()

	# 카드 위젯 생성 (풀에서 가져오거나 새로 인스턴스화)
	for i in hand_ids.size():
		var card_id: String = hand_ids[i]
		var card: CardData = DataLoader.get_card(card_id)
		if card == null:
			continue

		# 강화 상태 반영
		if GameManager.run_data and card_id in GameManager.run_data.upgraded_cards:
			card = card.duplicate_card()
			card.upgraded = true

		var widget: CardUI = _acquire_from_pool()
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


func _acquire_from_pool() -> CardUI:
	## 풀에서 CardUI를 꺼내거나 새로 인스턴스화한다.
	if _widget_pool.size() > 0:
		var widget: CardUI = _widget_pool.pop_back()
		widget.visible = true
		widget.is_selected = false
		widget.is_hovered = false
		widget.is_dragging = false
		return widget
	var widget: CardUI = CardUIScene.instantiate()
	add_child(widget)
	return widget


func _return_to_pool(widget: CardUI) -> void:
	## 위젯을 풀로 반환한다. 시그널 정리 후 숨긴다.
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
	widget.visible = false
	_widget_pool.append(widget)


func _arrange_cards() -> void:
	var count := card_widgets.size()
	if count == 0:
		return

	# 뷰포트 너비에 비례하여 카드 간격 계산
	var scale_factor := size.x / BASE_WIDTH
	var height_scale := size.y / 1920.0
	# 호버/선택 리프트는 뷰포트 높이 기준으로 계산 (HandZone이 화면 일부만 차지하므로)
	var vp_height := get_viewport_rect().size.y
	var lift_scale := vp_height / 1920.0

	# 손패 수에 따른 카드 크기 동적 조정
	var hand_scale := 1.0
	if count > HAND_SCALE_THRESHOLD:
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
		widget.set_deferred("size", Vector2(scaled_card_w, scaled_card_h))

	var card_w := scaled_card_w
	var available_width := size.x * 0.95
	var ideal_spacing := MAX_CARD_SPACING * scale_factor * hand_scale
	var needed_width := (count - 1) * ideal_spacing + card_w
	var card_spacing := ideal_spacing
	if count > 1 and needed_width > available_width:
		card_spacing = (available_width - card_w) / float(count - 1)
		card_spacing = maxf(card_spacing, MIN_CARD_SPACING * scale_factor * hand_scale)

	var center_x := size.x / 2.0
	# v9: 카드를 하단에 숨김 — 카드 높이의 peek_ratio만큼만 보이도록 배치
	# base_y = 영역 하단 - (카드 높이 * peek_ratio)  → 카드 상단 30%만 보임
	var base_y := size.y - (scaled_card_h * card_peek_ratio)
	var total_width := (count - 1) * card_spacing
	var start_x := center_x - total_width / 2.0

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

		# v9: 호버/선택 시 카드가 위로 올라와서 전체가 보이도록 (뷰포트 기준 리프트)
		var target_y := y
		if i == selected_index:
			target_y = base_y - select_lift * lift_scale
		elif i == hovered_index:
			target_y = base_y - hover_lift * lift_scale

		# 회전 계산 (부채꼴) — 호버/선택 시 회전 제거
		var rotation_deg := centered_t * fan_spread_degrees * (count - 1)
		var target_rot := rotation_deg
		if i == hovered_index or i == selected_index:
			target_rot = 0.0

		# v9: 부드러운 트윈 애니메이션으로 카드 이동
		_tween_card_to(widget, Vector2(x, target_y), target_rot)

		widget.z_index = i
		if i == hovered_index or i == selected_index:
			widget.z_index = count + 1


func _tween_card_to(widget: CardUI, target_pos: Vector2, target_rot: float) -> void:
	## 카드를 목표 위치/회전으로 부드럽게 이동시킨다.
	# 이전 트윈이 있으면 중지
	if widget.has_meta("_hand_tween"):
		var old_tween: Tween = widget.get_meta("_hand_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()

	# 위치 차이가 미미하면 즉시 적용 (불필요한 트윈 방지)
	if widget.position.distance_squared_to(target_pos) < 4.0 and absf(widget.rotation_degrees - target_rot) < 0.5:
		widget.position = target_pos
		widget.rotation_degrees = target_rot
		return

	var tw := widget.create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(widget, "position", target_pos, TWEEN_DURATION)
	tw.tween_property(widget, "rotation_degrees", target_rot, TWEEN_DURATION)
	widget.set_meta("_hand_tween", tw)


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
