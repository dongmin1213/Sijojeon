extends Control

## 런 맵 화면. 세로 스크롤 가능한 노드 맵을 표시하고 노드 탭으로 이동.

# v5: 단청 팔레트 노드 색상 — 타입별 명확한 시각 구분
const NODE_COLORS := {
	MapData.NodeType.BATTLE: Color(0.78, 0.29, 0.19),    # 주홍 (공격)
	MapData.NodeType.ELITE: Color(0.42, 0.25, 0.63),     # 자주 (엘리트)
	MapData.NodeType.EVENT: Color(0.23, 0.49, 0.27),     # 송록 (이벤트)
	MapData.NodeType.SHOP: Color(0.17, 0.30, 0.50),      # 남색 (상점)
	MapData.NodeType.REST: Color(0.24, 0.67, 0.43),      # 녹색 (휴식)
	MapData.NodeType.BOSS: Color(0.70, 0.15, 0.15),      # 진홍 (보스)
	MapData.NodeType.GWAGEO: Color(0.83, 0.66, 0.26),   # 금색 (과거시험)
}

var NODE_LABELS := {
	MapData.NodeType.BATTLE: "NODE_BATTLE",
	MapData.NodeType.ELITE: "NODE_ELITE",
	MapData.NodeType.EVENT: "NODE_EVENT",
	MapData.NodeType.SHOP: "NODE_SHOP",
	MapData.NodeType.REST: "NODE_REST",
	MapData.NodeType.BOSS: "NODE_BOSS",
	MapData.NodeType.GWAGEO: "NODE_GWAGEO",
}

## 이모지 대신 텍스트 심볼 사용 — Android에서 이모지 폰트 미포함 시 렌더링 실패 방지
const NODE_ICONS := {
	MapData.NodeType.BATTLE: "X",
	MapData.NodeType.ELITE: "*",
	MapData.NodeType.EVENT: "?",
	MapData.NodeType.SHOP: "$",
	MapData.NodeType.REST: "+",
	MapData.NodeType.BOSS: "!",
	MapData.NodeType.GWAGEO: "#",
}

## 기준 뷰포트 너비 (1080 기반 비례 스케일링)
const BASE_VIEWPORT_WIDTH := 1080.0
const BASE_NODE_SIZE := Vector2(200, 100)
const BASE_ROW_SPACING := 160.0
const BASE_MAP_PADDING_X := 80.0
const BASE_MAP_PADDING_TOP := 40.0
const BASE_MAP_PADDING_BOTTOM := 160.0

## 막별 맵 배경 색상 (그라데이션 기반)
const ACT_BG_COLORS := {
	1: Color(0.08, 0.06, 0.12),  # 한양 — 어두운 보라
	2: Color(0.05, 0.1, 0.06),   # 지리산 — 어두운 녹색
	3: Color(0.12, 0.04, 0.04),  # 경복궁 — 어두운 적색
}

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var map_container: Control = $ScrollContainer/MapContainer
@onready var node_layer: Control = $ScrollContainer/MapContainer/NodeLayer
@onready var line_layer: Control = $ScrollContainer/MapContainer/LineLayer
@onready var hp_label: Label = $HUD/HBoxContainer/HPLabel
@onready var gold_label: Label = $HUD/HBoxContainer/GoldLabel
@onready var act_label: Label = $HUD/TopRow/ActLabel
@onready var jibun_label: Label = $HUD/SubHBox/JibunLabel
@onready var faction_label: Label = $HUD/FactionRow/FactionLabel
@onready var minshim_label: Label = $HUD/SubHBox/MinshimLabel

var _node_buttons: Dictionary = {}  # node_id → Button
var _node_positions: Dictionary = {}  # node_id → Vector2 (center)
var _available_node_ids: Array[int] = []
var _node_selected: bool = false  # 노드 선택 후 중복 입력 차단
var _locked_node_costs: Dictionary = {}  # node_id → gold cost (갈림길 잠금 해제)
var _unlocked_nodes: Array[int] = []  # 이번 런에서 금화로 해제한 노드

## 갈림길 잠금 해제 비용
const FORK_UNLOCK_COST := 40


func _ready() -> void:
	if GameManager.run_data == null or GameManager.run_data.run_map == null:
		push_warning("RunMap: run_data 또는 run_map이 없음")
		return

	# 방 완료 후 맵 복귀: 대기 노드를 방문 완료로 확정
	_finalize_pending_node()

	_build_map()
	_update_hud()
	_update_node_states()
	_init_relic_bar()
	# 스크롤을 현재 위치로 이동
	call_deferred("_scroll_to_current")


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

	# 신분/당파/민심 HUD 업데이트
	_update_jibun_display(rd)
	if rd.faction_pair.size() == 2:
		var fa := FactionSystem.get_faction_name(rd.faction_pair[0])
		var fb := FactionSystem.get_faction_name(rd.faction_pair[1])
		var ma: int = rd.faction_meters.get(rd.faction_pair[0], 0)
		var mb: int = rd.faction_meters.get(rd.faction_pair[1], 0)
		faction_label.text = tr("MAP_FACTION_FMT") % [fa, ma, fb, mb]
	else:
		faction_label.text = tr("MAP_FACTION_NONE")
	_update_minshim_display(rd)

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
	var padding_top := BASE_MAP_PADDING_TOP * scale_factor
	var padding_bottom := BASE_MAP_PADDING_BOTTOM * scale_factor
	var font_size := maxi(int(28.0 * scale_factor), 24)

	# 행 간격: 뷰포트 높이에 맞춰 동적 계산 (노드가 화면에 균등 분포)
	var available_height: float = viewport_height - padding_top - padding_bottom - node_size.y
	var row_spacing: float
	if run_map.total_rows > 1:
		row_spacing = available_height / (run_map.total_rows - 1)
	else:
		row_spacing = 0.0
	# 최소 간격 보장
	var min_row_spacing: float = BASE_ROW_SPACING * scale_factor
	row_spacing = maxf(row_spacing, min_row_spacing)

	# 맵 전체 높이 계산 (아래에서 위로: row 0 = 하단, boss = 상단)
	var total_height: float = padding_top + padding_bottom + (run_map.total_rows - 1) * row_spacing + node_size.y
	map_container.custom_minimum_size = Vector2(viewport_width, total_height)

	# 노드 위치 계산 및 버튼 생성
	for r in range(run_map.total_rows):
		var row_nodes: Array = run_map.rows[r]
		var node_count: int = row_nodes.size()
		var usable_width: float = viewport_width - padding_x * 2

		for i in range(node_count):
			var node_id: int = row_nodes[i]
			var map_node: MapData.MapNode = run_map.nodes[node_id]

			# Y: 보스(마지막 행)가 위, 시작(0행)이 아래
			var y: float = padding_top + (run_map.total_rows - 1 - r) * row_spacing
			# X: 행 내 균등 분배
			var x: float
			if node_count == 1:
				x = viewport_width / 2.0 - node_size.x / 2.0
			else:
				x = padding_x + (usable_width - node_size.x) * i / (node_count - 1)

			var center := Vector2(x + node_size.x / 2.0, y + node_size.y / 2.0)
			_node_positions[node_id] = center

			# 노드 버튼 생성
			var btn := Button.new()
			btn.custom_minimum_size = node_size
			btn.size = node_size
			btn.position = Vector2(x, y)
			btn.focus_mode = Control.FOCUS_NONE  # 모바일 원탭 진입 (포커스 단계 제거)

			var icon_text: String = NODE_ICONS.get(map_node.type, "?")
			var label_key: String = NODE_LABELS.get(map_node.type, "")
			var label_text: String = tr(label_key) if label_key != "" else "???"
			btn.text = "%s\n%s" % [icon_text, label_text]

			btn.add_theme_font_size_override("font_size", font_size)
			btn.pressed.connect(_on_node_pressed.bind(node_id))

			node_layer.add_child(btn)
			_node_buttons[node_id] = btn

	# 연결선 그리기 — Line2D 노드로 생성
	_draw_connections()


func _draw_connections() -> void:
	if not is_inside_tree():
		return
	# 기존 연결선 제거 — 즉시 삭제로 메모리 누적 방지
	for child in line_layer.get_children():
		line_layer.remove_child(child)
		child.free()

	if GameManager.run_data == null or GameManager.run_data.run_map == null:
		return
	var run_map := GameManager.run_data.run_map
	var visited := GameManager.run_data.visited_nodes

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
			var color: Color
			var width: float
			if is_visited_path:
				# v5: 이미 지나간 경로 — 단청 금색
				color = Color(0.83, 0.66, 0.26, 0.85)
				width = 4.0
			elif nid in visited and conn_id in _available_node_ids:
				# v5: 선택 가능한 경로 — 밝은 금색
				color = Color(0.83, 0.66, 0.26, 0.6)
				width = 3.5
			else:
				# v5: 미래 경로 — 은은한 회색
				color = Color(0.45, 0.40, 0.35, 0.4)
				width = 2.5

			var line := Line2D.new()
			line.add_point(from_pos)
			line.add_point(to_pos)
			line.default_color = color
			line.width = width
			line.antialiased = true
			line_layer.add_child(line)


func _update_node_states() -> void:
	if GameManager.run_data == null or GameManager.run_data.run_map == null:
		return
	var run_map := GameManager.run_data.run_map
	var visited := GameManager.run_data.visited_nodes

	# 선택 가능한 노드 계산
	var available_nodes := run_map.get_available_nodes(visited)
	_available_node_ids.clear()

	# 민심 < 30: 상점 노드 50% 비활성화
	var minshim: int = GameManager.run_data.narrative_state.get("minshim", 50)
	var disabled_shop_ids: Array[int] = []
	if minshim < 30:
		disabled_shop_ids = _get_disabled_shop_nodes(run_map, visited)

	for node in available_nodes:
		if node.id in disabled_shop_ids:
			continue  # 민란으로 폐업한 상점
		_available_node_ids.append(node.id)

	# 갈림길 잠금 해제: 선택 가능한 노드가 3개 이상이면 일부를 잠금
	_locked_node_costs.clear()
	_unlocked_nodes.clear()
	for n in GameManager.run_data.narrative_state.get("unlocked_fork_nodes", []):
		_unlocked_nodes.append(int(n))
	if _available_node_ids.size() >= 3:
		_calculate_locked_forks(run_map)

	for nid in _node_buttons:
		var btn: Button = _node_buttons[nid]
		var map_node: MapData.MapNode = run_map.nodes[nid]
		var node_color: Color = NODE_COLORS.get(map_node.type, Color.WHITE)

		# 민란으로 폐업한 상점 표시
		if nid in disabled_shop_ids and nid not in visited:
			btn.disabled = true
			btn.text = "X\n" + tr("MAP_CLOSED")
			btn.modulate = Color(0.35, 0.28, 0.25, 0.6)
			btn.tooltip_text = tr("MAP_CLOSED_TOOLTIP")
			continue

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
			var label_key: String = NODE_LABELS.get(map_node.type, "")
			var label_text: String = tr(label_key) if label_key != "" else "???"
			btn.text = "%s\n%s\n%s" % [icon_text, label_text, tr("MAP_FORK_COST_FMT") % cost]
			btn.disabled = false
			btn.modulate = Color(0.83, 0.66, 0.26, 0.85)
			btn.tooltip_text = tr("MAP_FORK_UNLOCK_TOOLTIP") % cost
			var style := _make_node_style(Color(0.15, 0.12, 0.08), Color(0.83, 0.66, 0.26, 0.7), 2)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_color_override("font_color", Color(0.83, 0.66, 0.26))
		elif nid in _available_node_ids:
			# v5: 선택 가능한 노드 — 타입 색상 + 금박 보더 + 펄스
			btn.disabled = false
			btn.modulate = Color.WHITE
			var style := _make_node_style(node_color.darkened(0.15), Color(0.83, 0.66, 0.26, 0.9), 3)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)

			var pressed_style := style.duplicate()
			pressed_style.bg_color = node_color.lightened(0.2)
			btn.add_theme_stylebox_override("pressed", pressed_style)

			btn.add_theme_color_override("font_color", Color.WHITE)
			# 펄스 애니메이션
			_start_node_pulse(btn)
		else:
			# v5: 미래 노드 — 어두운 타입 색상, 얇은 테두리
			btn.disabled = true
			var style := _make_node_style(node_color.darkened(0.45), node_color.darkened(0.15), 1)
			btn.add_theme_stylebox_override("disabled", style)
			btn.modulate = Color(0.75, 0.70, 0.65, 0.65)
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
			var style := _make_node_style(cur_color.darkened(0.2), Color(0.83, 0.66, 0.26, 1.0), 4)
			style.shadow_color = Color(0.83, 0.66, 0.26, 0.3)
			style.shadow_size = 6
			btn.add_theme_stylebox_override("disabled", style)
			btn.add_theme_color_override("font_disabled_color", Color(0.83, 0.66, 0.26))
			# 텍스트에 ▶ 마커 추가
			var icon_text: String = NODE_ICONS.get(map_node_cur.type, "?")
			var label_key: String = NODE_LABELS.get(map_node_cur.type, "")
			var label_text: String = tr(label_key) if label_key != "" else "???"
			btn.text = "▶ %s\n%s" % [icon_text, label_text]

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


## v5: 단청 스타일 노드 공통 헬퍼 — 둥근 모서리, 그림자 포함
func _make_node_style(bg: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(12)
	style.set_border_width_all(border_width)
	style.border_color = border_color
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	style.shadow_size = 3
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


## 민심 < 30일 때 비활성화할 상점 노드를 결정한다 (시드 기반 50%).
func _get_disabled_shop_nodes(run_map: MapData.RunMap, visited: Array[int]) -> Array[int]:
	var result: Array[int] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = GameManager.run_data.map_seed + 7777  # 결정론적 시드
	for nid in run_map.nodes:
		if nid in visited:
			continue
		var map_node: MapData.MapNode = run_map.nodes[nid]
		if map_node.type == MapData.NodeType.SHOP:
			if rng.randf() < 0.5:
				result.append(nid)
	return result


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
			# 해제 기록 저장 (세이브 영속화)
			if not GameManager.run_data.narrative_state.has("unlocked_fork_nodes"):
				GameManager.run_data.narrative_state["unlocked_fork_nodes"] = []
			GameManager.run_data.narrative_state["unlocked_fork_nodes"].append(node_id)
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

	# 민심 0~9 구간: 비전투 노드 이동 시 25% 확률 강제 전투 삽입
	var minshim: int = GameManager.run_data.narrative_state.get("minshim", 50)
	if minshim < 10 and map_node.type not in [MapData.NodeType.BATTLE, MapData.NodeType.ELITE, MapData.NodeType.BOSS]:
		if randf() < 0.25:
			# 원래 목적지 정보를 저장하고 강제 전투로 전환
			GameManager.run_data.set_meta("minran_forced_original_type", map_node.type)
			GameManager.run_data.set_meta("minran_forced_original_encounter", map_node.encounter_id)
			GameManager.run_data.current_node_type = MapData.NodeType.BATTLE
			GameManager.run_data.current_encounter_id = "E001"  # 민란군 기본 적
			GameManager.save_current_run()
			GameManager.change_state(GameManager.GameState.BATTLE)
			return

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
		MapData.NodeType.GWAGEO:
			GameManager.change_state(GameManager.GameState.GWAGEO)


# ── 민심 표시 개선 ──────────────────────────────

## 민심 구간 상태명과 색상을 반환한다.
func _get_minshim_tier(value: int) -> Dictionary:
	# v5: 단청 팔레트 민심 색상
	if value >= 80:
		return {"name": tr("MINSHIM_TIER_HIGH"), "color": Color(0.23, 0.49, 0.27)}
	elif value >= 50:
		return {"name": tr("MINSHIM_TIER_NORMAL"), "color": Color(0.75, 0.70, 0.65)}
	elif value >= 30:
		return {"name": tr("MINSHIM_TIER_UNREST"), "color": Color(0.83, 0.66, 0.26)}
	else:
		return {"name": tr("MINSHIM_TIER_CRISIS"), "color": Color(0.78, 0.29, 0.19)}


## 민심 라벨 업데이트: 수치 + 구간명 + 색상.
func _update_minshim_display(rd: RunData) -> void:
	var minshim: int = rd.narrative_state.get("minshim", 50)
	var tier := _get_minshim_tier(minshim)
	minshim_label.text = tr("MAP_MINSHIM_TIER_FMT") % [minshim, tier["name"]]
	minshim_label.add_theme_color_override("font_color", tier["color"])
	# 툴팁: 탭/클릭 시 팝업으로 민심 효과 목록 표시
	if not minshim_label.gui_input.is_connected(_on_minshim_tapped):
		minshim_label.mouse_filter = Control.MOUSE_FILTER_STOP
		minshim_label.gui_input.connect(_on_minshim_tapped)


## 민심 라벨 탭 시 효과 목록 팝업.
func _on_minshim_tapped(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var rd := GameManager.run_data
	if rd == null:
		return
	var minshim: int = rd.narrative_state.get("minshim", 50)
	var tier := _get_minshim_tier(minshim)

	var text := "%s %d [%s]\n" % [tr("MINSHIM_TOOLTIP_TITLE"), minshim, tier["name"]]
	text += "─────────────────\n"
	text += "■ 80+: %s\n" % tr("MINSHIM_EFFECT_80")
	text += "■ 70+: %s\n" % tr("MINSHIM_EFFECT_70")
	text += "■ 30~49: %s\n" % tr("MINSHIM_EFFECT_30")
	text += "■ <30: %s" % tr("MINSHIM_EFFECT_0")

	var dialog := AcceptDialog.new()
	dialog.title = tr("MINSHIM_TOOLTIP_TITLE")
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


# ── 신분 표시 개선 ──────────────────────────────

## 신분 라벨 업데이트: 단계명 + 점수 + 프로그레스바.
func _update_jibun_display(rd: RunData) -> void:
	var rank := rd.jibun_rank
	var score := rd.jibun_score
	var rank_name := JibunSystem.get_rank_name(rank)
	var next_threshold := _get_next_rank_threshold(rank)

	if next_threshold > 0:
		var progress := _make_progress_bar(score, _get_current_rank_threshold(rank), next_threshold)
		jibun_label.text = tr("MAP_JIBUN_PROGRESS_FMT") % [rank_name, score, next_threshold, progress]
	else:
		# 최고 등급
		jibun_label.text = tr("MAP_JIBUN_MAX_FMT") % [rank_name, score]

	# 툴팁: 탭/클릭 시 팝업으로 신분 효과 표시
	if not jibun_label.gui_input.is_connected(_on_jibun_tapped):
		jibun_label.mouse_filter = Control.MOUSE_FILTER_STOP
		jibun_label.gui_input.connect(_on_jibun_tapped)


## 현재 등급의 진입 점수.
func _get_current_rank_threshold(rank: int) -> int:
	return JibunSystem.RANK_THRESHOLDS.get(rank, 0)


## 다음 등급 진입 점수 (최고 등급이면 -1).
func _get_next_rank_threshold(rank: int) -> int:
	if rank >= 5:
		return -1
	return JibunSystem.RANK_THRESHOLDS.get(rank + 1, -1)


## 텍스트 프로그레스바 생성 (총 6칸).
func _make_progress_bar(score: int, current_min: int, next_threshold: int) -> String:
	var range_size := next_threshold - current_min
	if range_size <= 0:
		return "██████"
	var filled := clampi(int(6.0 * (score - current_min) / range_size), 0, 6)
	var empty := 6 - filled
	return "█".repeat(filled) + "░".repeat(empty)


## 신분 라벨 탭 시 효과 팝업.
func _on_jibun_tapped(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var rd := GameManager.run_data
	if rd == null:
		return
	var rank := rd.jibun_rank
	var score := rd.jibun_score
	var rank_name := JibunSystem.get_rank_name(rank)

	var text := "%s: %s (%d%s)\n" % [tr("JIBUN_TOOLTIP_CURRENT"), rank_name, score, tr("JIBUN_TOOLTIP_POINTS")]
	text += "─────────────────\n"
	text += "%s:\n" % tr("JIBUN_TOOLTIP_EFFECTS")

	# 현재 등급의 활성 효과 표시
	match rank:
		0:
			text += "■ %s\n" % tr("JIBUN_EFFECT_0_GOLD")
			text += "■ %s\n" % tr("JIBUN_EFFECT_0_HIDDEN")
		1:
			text += "■ %s\n" % tr("JIBUN_EFFECT_1_CARD")
		2:
			text += "■ %s\n" % tr("JIBUN_EFFECT_2_UPGRADE")
			text += "■ %s\n" % tr("JIBUN_EFFECT_2_ELITE")
		3:
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_SHOP")
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_MINSHIM")
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_GWAGEO")
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_ELITE_HP")
		4:
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_SHOP")
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_MINSHIM")
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_GWAGEO")
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_ELITE_HP")
			text += "■ %s\n" % tr("JIBUN_EFFECT_4_BOSS_HP")
		5:
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_SHOP")
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_MINSHIM")
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_GWAGEO")
			text += "■ %s\n" % tr("JIBUN_EFFECT_3_ELITE_HP")
			text += "■ %s\n" % tr("JIBUN_EFFECT_4_BOSS_HP")
			text += "■ %s\n" % tr("JIBUN_EFFECT_5_REWARD")

	# 다음 등급 정보
	var next_threshold := _get_next_rank_threshold(rank)
	if next_threshold > 0:
		var next_name := JibunSystem.get_rank_name(rank + 1)
		text += "\n%s (%s, %d%s):\n" % [tr("JIBUN_TOOLTIP_NEXT"), next_name, next_threshold, tr("JIBUN_TOOLTIP_POINTS")]
		var reward_key: String = JibunSystem.RANK_UP_REWARD_KEYS.get(rank + 1, "")
		if reward_key != "":
			text += "■ %s: %s" % [tr("JIBUN_TOOLTIP_RANKUP"), tr(reward_key)]

	var dialog := AcceptDialog.new()
	dialog.title = tr("JIBUN_TOOLTIP_TITLE")
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
