extends Control

## 런 맵 화면. 세로 스크롤 가능한 노드 맵을 표시하고 노드 탭으로 이동.

# v6: 오방색 팔레트 노드 색상 — 보라색 완전 제거
const NODE_COLORS := {
	MapData.NodeType.BATTLE: Color(0.76, 0.23, 0.13),    # 적 (공격 — #C23B22)
	MapData.NodeType.ELITE: Color(0.76, 0.23, 0.13),     # 적 (엘리트 — 밝은 적)
	MapData.NodeType.EVENT: Color(0.23, 0.49, 0.27),     # 송록 (이벤트)
	MapData.NodeType.SHOP: Color(0.18, 0.31, 0.56),      # 청 (상점 — #2E5090)
	MapData.NodeType.REST: Color(0.24, 0.67, 0.43),      # 녹색 (휴식)
	MapData.NodeType.BOSS: Color(0.70, 0.15, 0.15),      # 진홍 (보스)
}

var NODE_LABELS := {
	MapData.NodeType.BATTLE: "NODE_BATTLE",
	MapData.NodeType.ELITE: "NODE_ELITE",
	MapData.NodeType.EVENT: "NODE_EVENT",
	MapData.NodeType.SHOP: "NODE_SHOP",
	MapData.NodeType.REST: "NODE_REST",
	MapData.NodeType.BOSS: "NODE_BOSS",
}

## v6: 노드 아이콘 — 직관적 심볼 (Android 호환 유니코드)
const NODE_ICONS := {
	MapData.NodeType.BATTLE: "⚔",
	MapData.NodeType.ELITE: "★",
	MapData.NodeType.EVENT: "？",
	MapData.NodeType.SHOP: "￥",
	MapData.NodeType.REST: "♨",
	MapData.NodeType.BOSS: "☠",
}

## 기준 뷰포트 너비 (1080 기반 비례 스케일링)
const BASE_VIEWPORT_WIDTH := 1080.0
const BASE_NODE_SIZE := Vector2(80, 80)  # v11: 모바일 터치 타겟 확대 (64→80)
const BASE_ROW_SPACING := 180.0  # v10: 고정 행 간격 (스크롤 맵)
const BASE_MAP_PADDING_X := 20.0  # v11: 좌우 여백 확대 (잘림 방지)
const BASE_MAP_PADDING_TOP := 140.0  # v9: 플로팅 HUD 아래 시작
const BASE_MAP_PADDING_BOTTOM := 140.0  # v11: 하단 잘림 방지 여백 확대

## 막별 맵 배경 색상 (오방색 기반)
const ACT_BG_COLORS := {
	1: Color(0.10, 0.10, 0.10),  # 한양 — 먹색 (흑)
	2: Color(0.05, 0.1, 0.06),   # 지리산 — 어두운 녹색
	3: Color(0.12, 0.04, 0.04),  # 경복궁 — 어두운 적색
}

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_container: Control = $ScrollContainer/MapContainer
@onready var node_layer: Control = $ScrollContainer/MapContainer/NodeLayer
@onready var line_layer: Control = $ScrollContainer/MapContainer/LineLayer
@onready var hp_label: Label = $HUD/VBoxContainer/HBoxContainer/HPLabel
@onready var gold_label: Label = $HUD/VBoxContainer/HBoxContainer/GoldLabel
@onready var act_label: Label = $HUD/VBoxContainer/TopRow/ActLabel

# v8: HUD 확장/축소 상태
var _hud_expanded: bool = false

var _node_buttons: Dictionary = {}  # node_id → Button
var _node_positions: Dictionary = {}  # node_id → Vector2 (center)
var _available_node_ids: Array[int] = []
var _node_selected: bool = false  # 노드 선택 후 중복 입력 차단
var _locked_node_costs: Dictionary = {}  # node_id → gold cost (갈림길 잠금 해제)
var _unlocked_nodes: Array[int] = []  # 이번 런에서 금화로 해제한 노드
var _safe_area_top_px: float = 40.0  # 노치/상태바 높이 (px)
var _hud_bottom_ratio: float = 0.09  # HUD 하단 앵커 비율

## 갈림길 잠금 해제 비용
const FORK_UNLOCK_COST := 40


func _ready() -> void:
	if GameManager.run_data == null or GameManager.run_data.run_map == null:
		push_warning("RunMap: run_data 또는 run_map이 없음")
		return

	# 노치/상태바 안전 영역 적용
	_apply_safe_area_margin()

	# 방 완료 후 맵 복귀: 대기 노드를 방문 완료로 확정
	_finalize_pending_node()

	_build_map()
	_update_hud()
	_update_node_states()
	_init_relic_bar()
	_init_hud_toggle()
	# 스크롤을 현재 위치로 이동
	call_deferred("_scroll_to_current")


func _apply_safe_area_margin() -> void:
	## 카메라 노치/상태바 안전 영역을 HUD와 스크롤 영역에 적용한다.
	var safe_area := DisplayServer.get_display_safe_area()
	var screen_size := DisplayServer.screen_get_size()
	# safe_area.position.y = 노치/상태바 높이 (픽셀)
	var top_inset_px: float = safe_area.position.y
	if top_inset_px <= 0:
		# 안전 영역 정보가 없으면 기본 마진 적용 (40px)
		top_inset_px = 40.0
	# 뷰포트 비율로 변환
	var viewport_height: float = get_viewport_rect().size.y
	var top_ratio: float = top_inset_px / maxf(float(screen_size.y), viewport_height)
	# HUD 상단 앵커에 안전 영역 마진 반영
	var hud := $HUD
	hud.anchor_top = maxf(top_ratio, 0.02)
	hud.anchor_bottom = hud.anchor_top + 0.07
	# SafeAreaManager 이중 적용 방지 — 이미 직접 처리했으므로 빈 기록 설정
	var no_margin := {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	hud.set_meta("_safe_area_applied", no_margin)
	# ScrollContainer: HUD 하단 아래부터 시작하여 맵이 가려지지 않도록
	scroll_container.anchor_top = hud.anchor_bottom
	scroll_container.set_meta("_safe_area_applied", no_margin)
	# 맵 패딩 계산용 저장
	_safe_area_top_px = top_inset_px
	_hud_bottom_ratio = hud.anchor_bottom


func _finalize_pending_node() -> void:
	## 방 완료 후 맵에 돌아왔을 때: 대기 노드를 방문 완료 처리.
	var rd := GameManager.run_data
	if rd.pending_node_id >= 0:
		if rd.pending_node_id not in rd.visited_nodes:
			rd.visited_nodes.append(rd.pending_node_id)
		rd.pending_node_id = -1
		rd.current_node_type = -1
		rd.current_encounter_id = ""
		GameManager.save_current_run()


func _init_hud_toggle() -> void:
	pass


func _init_relic_bar() -> void:
	var relic_bar := RelicBar.new()
	relic_bar.name = "RelicBar"
	$HUD.add_child(relic_bar)


func _update_hud() -> void:
	var rd := GameManager.run_data
	if rd == null:
		return
	hp_label.text = "HP: %d/%d" % [rd.current_hp, rd.max_hp]
	gold_label.text = tr("MAP_GOLD_FMT") % rd.gold
	var act_name: String = MapGenerator.get_act_name(rd.current_act)
	act_label.text = tr("MAP_ACT_FMT") % [rd.current_act, act_name]

	# 막별 배경색 적용
	var bg_color: Color = ACT_BG_COLORS.get(rd.current_act, ACT_BG_COLORS[1])
	_apply_map_background(bg_color)


func _apply_map_background(color: Color) -> void:
	# MapContainer에 배경색 적용
	var bg := map_container.get_node_or_null("Background")
	if bg == null:
		bg = ColorRect.new()
		bg.name = "Background"
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 터치 이벤트가 노드 버튼으로 전달되도록
		map_container.add_child(bg)
		map_container.move_child(bg, 0)
	bg.color = color
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.size = map_container.custom_minimum_size


func _build_map() -> void:
	if GameManager.run_data == null or GameManager.run_data.run_map == null:
		return
	var run_map := GameManager.run_data.run_map
	var viewport_width: float = get_viewport_rect().size.x
	var viewport_height: float = get_viewport_rect().size.y
	var scale_factor: float = viewport_width / BASE_VIEWPORT_WIDTH

	# 스케일링된 상수
	var node_size := BASE_NODE_SIZE * scale_factor
	var padding_x := BASE_MAP_PADDING_X * scale_factor
	# 맵 상단 패딩: ScrollContainer가 HUD 아래부터 시작하므로 여유 공간만 필요
	var padding_top := 24.0 * scale_factor
	var padding_bottom := BASE_MAP_PADDING_BOTTOM * scale_factor
	var font_size := maxi(int(32.0 * scale_factor), 28)  # v10: 아이콘 전용 — 폰트 크기 증가

	# v10: 고정 행 간격 (스크롤 맵 — 뷰포트에 맞춰 압축하지 않음)
	var row_spacing: float = BASE_ROW_SPACING * scale_factor

	# 맵 전체 높이 계산 (아래에서 위로: row 0 = 하단, boss = 상단)
	var total_height: float = padding_top + padding_bottom + (run_map.total_rows - 1) * row_spacing + node_size.y
	map_container.custom_minimum_size = Vector2(viewport_width, total_height)

	# v10: 시드 기반 jitter RNG
	var jitter_rng := RandomNumberGenerator.new()
	jitter_rng.seed = run_map.seed_value + 9999
	var jitter_max: float = node_size.x * 0.35

	# v10: 7열 그리드 기반 X 좌표 계산
	var col_spacing: float = (viewport_width - padding_x * 2 - node_size.x) / float(MapGenerator.NUM_COLUMNS - 1)

	# 노드 위치 계산 및 버튼 생성
	for r in range(run_map.total_rows):
		var row_nodes: Array = run_map.rows[r]
		var node_count: int = row_nodes.size()

		for i in range(node_count):
			var node_id: int = row_nodes[i]
			var map_node: MapData.MapNode = run_map.nodes[node_id]

			# Y: 보스(마지막 행)가 위, 시작(0행)이 아래
			var y: float = padding_top + (run_map.total_rows - 1 - r) * row_spacing
			# X: 7열 그리드 내 열 인덱스 기반
			var x: float = padding_x + map_node.column * col_spacing

			# v10: 시드 기반 jitter — 시작행/보스행/단독 노드 제외
			if node_count > 1 and r > 0 and r < run_map.total_rows - 1:
				var jx: float = jitter_rng.randf_range(-jitter_max, jitter_max)
				var jy: float = jitter_rng.randf_range(-jitter_max * 0.3, jitter_max * 0.3)
				x = clampf(x + jx, padding_x, viewport_width - padding_x - node_size.x)
				y += jy

			var center := Vector2(x + node_size.x / 2.0, y + node_size.y / 2.0)
			_node_positions[node_id] = center

			# v10: 노드 버튼 생성 — 아이콘 전용
			var btn := Button.new()
			btn.custom_minimum_size = node_size
			btn.size = node_size
			btn.position = Vector2(x, y)
			btn.focus_mode = Control.FOCUS_NONE  # 모바일 원탭 진입

			# v10: 아이콘만 표시 (라벨 텍스트 제거)
			var icon_text: String = NODE_ICONS.get(map_node.type, "?")
			btn.text = icon_text

			btn.add_theme_font_size_override("font_size", font_size)
			btn.pressed.connect(_on_node_pressed.bind(node_id))

			node_layer.add_child(btn)
			_node_buttons[node_id] = btn

	# 연결선 그리기 — Line2D 노드로 생성
	_draw_connections()


func _draw_connections() -> void:
	if not is_inside_tree():
		return
	# 기존 연결선 제거
	for child in line_layer.get_children():
		line_layer.remove_child(child)
		child.free()

	if GameManager.run_data == null or GameManager.run_data.run_map == null:
		return
	var run_map := GameManager.run_data.run_map
	var visited := GameManager.run_data.visited_nodes

	# v10: 현재 행 계산 (거리 기반 페이드용)
	var current_row: int = 0
	if not visited.is_empty():
		var last_id: int = visited[-1]
		if run_map.nodes.has(last_id):
			current_row = run_map.nodes[last_id].row

	# v10: 곡선 보간용 시드 RNG
	var curve_rng := RandomNumberGenerator.new()
	curve_rng.seed = run_map.seed_value + 7777

	for nid in run_map.nodes:
		var map_node: MapData.MapNode = run_map.nodes[nid]
		if not _node_positions.has(nid):
			continue
		var from_pos: Vector2 = _node_positions[nid]

		for conn_id in map_node.connections:
			if not _node_positions.has(conn_id):
				continue
			var to_pos: Vector2 = _node_positions[conn_id]

			var is_visited_path: bool = (nid in visited) and (conn_id in visited)
			var is_available_path: bool = (nid in visited) and (conn_id in _available_node_ids)
			var color: Color
			var width: float
			if is_visited_path:
				color = Color(0.76, 0.23, 0.13, 0.85)
				width = 3.5
			elif is_available_path:
				color = Color(0.76, 0.23, 0.13, 0.6)
				width = 3.0
			else:
				# v10: 거리 기반 페이드
				var node_row: int = map_node.row
				var dist: int = absi(node_row - current_row)
				var alpha: float
				if dist <= 2:
					alpha = 0.35
				elif dist <= 5:
					alpha = lerpf(0.35, 0.1, float(dist - 2) / 3.0)
				else:
					alpha = 0.1
				color = Color(0.45, 0.40, 0.35, alpha)
				width = 2.0

			# v10: 베지어 곡선 — 중간 보간점 생성
			var line := Line2D.new()
			var curve_points := _make_curve_points(from_pos, to_pos, curve_rng)
			for pt in curve_points:
				line.add_point(pt)
			line.default_color = color
			line.width = width
			line.antialiased = true
			line_layer.add_child(line)


## v10: 두 점 사이에 베지어 곡선 보간점을 생성한다.
func _make_curve_points(from: Vector2, to: Vector2, rng: RandomNumberGenerator) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var segments := 8
	# 제어점: 중간 지점에서 수평 오프셋
	var mid := (from + to) / 2.0
	var dist := from.distance_to(to)
	var offset_x: float = rng.randf_range(-dist * 0.15, dist * 0.15)
	var ctrl := Vector2(mid.x + offset_x, mid.y)

	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		# 2차 베지어: B(t) = (1-t)²P0 + 2(1-t)tP1 + t²P2
		var p: Vector2 = (1.0 - t) * (1.0 - t) * from + 2.0 * (1.0 - t) * t * ctrl + t * t * to
		points.append(p)
	return points


func _update_node_states() -> void:
	if GameManager.run_data == null or GameManager.run_data.run_map == null:
		return
	var run_map := GameManager.run_data.run_map
	var visited := GameManager.run_data.visited_nodes

	# 선택 가능한 노드 계산
	var available_nodes := run_map.get_available_nodes(visited)
	_available_node_ids.clear()

	for node in available_nodes:
		_available_node_ids.append(node.id)

	# 갈림길 잠금 해제: 선택 가능한 노드가 3개 이상이면 일부를 잠금
	_locked_node_costs.clear()
	_unlocked_nodes.clear()
	if _available_node_ids.size() >= 3:
		_calculate_locked_forks(run_map)

	for nid in _node_buttons:
		var btn: Button = _node_buttons[nid]
		var map_node: MapData.MapNode = run_map.nodes[nid]
		var node_color: Color = NODE_COLORS.get(map_node.type, Color.WHITE)

		if nid in visited:
			# v5: 방문 노드 — 어두운 톤 + 얇은 테두리
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.6, 0.7)
			var style := _make_node_style(node_color.darkened(0.5), Color(0.4, 0.35, 0.30, 0.4), 1)
			btn.add_theme_stylebox_override("disabled", style)
			btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.42, 0.40))
		elif nid in _locked_node_costs:
			# 갈림길 잠금 노드: 금화로 해제 가능
			var cost: int = _locked_node_costs[nid]
			var icon_text: String = NODE_ICONS.get(map_node.type, "?")
			btn.text = "%s\n%s" % [icon_text, tr("MAP_FORK_COST_FMT") % cost]
			btn.disabled = false
			btn.modulate = Color(0.76, 0.23, 0.13, 0.85)
			btn.tooltip_text = tr("MAP_FORK_UNLOCK_TOOLTIP") % cost
			var style := _make_node_style(Color(0.15, 0.12, 0.08), Color(0.76, 0.23, 0.13, 0.7), 2)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
		elif nid in _available_node_ids:
			# v5: 선택 가능한 노드 — 타입 색상 + 금박 보더 + 펄스
			btn.disabled = false
			btn.modulate = Color.WHITE
			var style := _make_node_style(node_color.darkened(0.15), Color(0.76, 0.23, 0.13, 0.9), 3)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)

			var pressed_style := style.duplicate()
			pressed_style.bg_color = node_color.lightened(0.2)
			btn.add_theme_stylebox_override("pressed", pressed_style)

			btn.add_theme_color_override("font_color", Color.WHITE)
			# 펄스 애니메이션
			_start_node_pulse(btn)
		else:
			# v10: 미래 노드 — 거리 기반 페이드
			btn.disabled = true
			var style := _make_node_style(node_color.darkened(0.45), node_color.darkened(0.15), 1)
			btn.add_theme_stylebox_override("disabled", style)
			# 현재 위치에서 거리 기반 투명도
			var dist: int = absi(map_node.row - _get_current_row())
			var node_alpha: float
			if dist <= 2:
				node_alpha = 0.65
			elif dist <= 5:
				node_alpha = lerpf(0.65, 0.25, float(dist - 2) / 3.0)
			else:
				node_alpha = 0.25
			btn.modulate = Color(0.75, 0.70, 0.65, node_alpha)
			btn.add_theme_color_override("font_disabled_color", Color(0.60, 0.55, 0.50))

	# 현재 위치 마커: 마지막 방문 노드에 밝은 금색 보더 + ▶ 표시
	if not visited.is_empty():
		var last_id: int = visited[-1]
		if _node_buttons.has(last_id):
			var btn: Button = _node_buttons[last_id]
			var map_node_cur: MapData.MapNode = run_map.nodes[last_id]
			var cur_color: Color = NODE_COLORS.get(map_node_cur.type, Color.WHITE)
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			# v5: 현재 위치 — 금박 강조 보더
			var style := _make_node_style(cur_color.darkened(0.2), Color(0.76, 0.23, 0.13, 1.0), 4)
			style.shadow_color = Color(0.76, 0.23, 0.13, 0.3)
			style.shadow_size = 6
			btn.add_theme_stylebox_override("disabled", style)
			btn.add_theme_color_override("font_disabled_color", Color(0.76, 0.23, 0.13))
			# v10: 아이콘 전용 마커
			var icon_text: String = NODE_ICONS.get(map_node_cur.type, "?")
			btn.text = "▶%s" % icon_text

	# 연결선 다시 그리기
	_draw_connections()


func _scroll_to_current() -> void:
	if not is_inside_tree() or GameManager.run_data == null or GameManager.run_data.run_map == null:
		return
	var run_map := GameManager.run_data.run_map
	var visited := GameManager.run_data.visited_nodes

	var target_y: float = 0.0
	if visited.is_empty():
		# 시작: row 0 (하단) 으로 스크롤
		var total_height: float = map_container.custom_minimum_size.y
		target_y = total_height - scroll_container.size.y
	else:
		# 마지막 방문 노드 위치로 스크롤
		var last_id: int = visited[-1]
		if _node_positions.has(last_id):
			var pos: Vector2 = _node_positions[last_id]
			target_y = pos.y - scroll_container.size.y / 2.0

	target_y = clampf(target_y, 0, map_container.custom_minimum_size.y - scroll_container.size.y)
	scroll_container.scroll_vertical = int(target_y)


## v10: 현재 위치 행 번호를 반환한다.
func _get_current_row() -> int:
	if GameManager.run_data == null or GameManager.run_data.visited_nodes.is_empty():
		return 0
	var last_id: int = GameManager.run_data.visited_nodes[-1]
	if GameManager.run_data.run_map and GameManager.run_data.run_map.nodes.has(last_id):
		return GameManager.run_data.run_map.nodes[last_id].row
	return 0


## 단청 스타일 노드 공통 헬퍼 — 둥근 모서리, 그림자 포함
func _make_node_style(bg: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(32)  # v10: BASE_NODE_SIZE / 2 = 원형
	style.set_border_width_all(border_width)
	style.border_color = border_color
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	return style


## 선택 가능한 노드에 펄스 애니메이션 적용
func _start_node_pulse(btn: Button) -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(btn, "modulate:a", 0.7, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(btn, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)


## 갈림길 잠금 노드를 계산한다. 3개 이상 선택지 중 1개를 잠금.
## 보스/휴식 노드는 잠그지 않는다. 최소 2개는 항상 무료.
func _calculate_locked_forks(run_map: MapData.RunMap) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = GameManager.run_data.map_seed + GameManager.run_data.visited_nodes.size() * 31

	# 잠금 후보: 보스/휴식이 아닌 노드
	var candidates: Array[int] = []
	for nid in _available_node_ids:
		if nid in _unlocked_nodes:
			continue  # 이미 해제한 노드
		var map_node: MapData.MapNode = run_map.nodes[nid]
		if map_node.type == MapData.NodeType.BOSS or map_node.type == MapData.NodeType.REST:
			continue  # 보스/휴식은 잠그지 않음
		candidates.append(nid)

	# 최소 2개 무료 보장: 잠글 수 있는 후보가 available - 1 이하여야 함
	var max_lockable := _available_node_ids.size() - 2
	if max_lockable <= 0 or candidates.is_empty():
		return

	# 1개만 잠금
	candidates.shuffle()
	var lock_id: int = candidates[rng.randi() % candidates.size()]
	_locked_node_costs[lock_id] = FORK_UNLOCK_COST
	_available_node_ids.erase(lock_id)


func _on_node_pressed(node_id: int) -> void:
	# 중복 입력 완전 차단 (씬 전환 중 추가 탭 방지)
	if _node_selected:
		return

	# 갈림길 잠금 노드 처리: 금화 지불로 해제
	if node_id in _locked_node_costs:
		var cost: int = _locked_node_costs[node_id]
		if GameManager.run_data and GameManager.run_data.gold >= cost:
			AudioManager.play_sfx_by_key("coin")
			GameManager.run_data.gold -= cost
			_locked_node_costs.erase(node_id)
			_available_node_ids.append(node_id)
			_update_node_states()
			_update_hud()
		return  # 해제만 하고 즉시 이동하지 않음

	if node_id not in _available_node_ids:
		return
	_node_selected = true
	_available_node_ids.clear()

	# 모든 버튼 즉시 비활성화 — freed 노드 콜백 방지
	for nid in _node_buttons:
		var btn: Button = _node_buttons[nid]
		if is_instance_valid(btn):
			btn.disabled = true

	# null 안전 검사
	if GameManager.run_data == null or GameManager.run_data.run_map == null:
		push_warning("RunMap: _on_node_pressed — run_data/run_map null")
		return

	var run_map := GameManager.run_data.run_map
	if not run_map.nodes.has(node_id):
		push_warning("RunMap: _on_node_pressed — node_id %d 없음" % node_id)
		return
	var map_node: MapData.MapNode = run_map.nodes[node_id]

	# 방문 대기 기록 — 방 완료 후 MAP으로 돌아올 때 visited_nodes에 추가됨
	GameManager.run_data.pending_node_id = node_id

	# 현재 노드 정보를 RunData에 저장 (세이브 영속화)
	GameManager.run_data.current_node_type = map_node.type
	GameManager.run_data.current_encounter_id = map_node.encounter_id

	# 자동 저장
	GameManager.save_current_run()

	# 노드 타입에 따라 씬 전환
	match map_node.type:
		MapData.NodeType.BATTLE, MapData.NodeType.ELITE:
			GameManager.change_state(GameManager.GameState.BATTLE)
		MapData.NodeType.BOSS:
			GameManager.change_state(GameManager.GameState.BATTLE)
		MapData.NodeType.SHOP:
			GameManager.change_state(GameManager.GameState.SHOP)
		MapData.NodeType.REST:
			GameManager.change_state(GameManager.GameState.REST)
		MapData.NodeType.EVENT:
			GameManager.change_state(GameManager.GameState.EVENT)


