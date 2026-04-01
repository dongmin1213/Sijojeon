extends Control

## 런 맵 화면. 세로 스크롤 가능한 노드 맵을 표시하고 노드 탭으로 이동.

const NODE_COLORS := {
	MapData.NodeType.BATTLE: Color(0.85, 0.3, 0.3),    # 빨강
	MapData.NodeType.ELITE: Color(0.9, 0.6, 0.1),      # 주황
	MapData.NodeType.EVENT: Color(0.3, 0.75, 0.4),     # 초록
	MapData.NodeType.SHOP: Color(0.3, 0.6, 0.9),       # 파랑
	MapData.NodeType.REST: Color(0.6, 0.85, 0.6),      # 연두
	MapData.NodeType.BOSS: Color(0.95, 0.2, 0.2),      # 진빨
}

const NODE_LABELS := {
	MapData.NodeType.BATTLE: "전투",
	MapData.NodeType.ELITE: "정예",
	MapData.NodeType.EVENT: "이벤트",
	MapData.NodeType.SHOP: "상점",
	MapData.NodeType.REST: "휴식",
	MapData.NodeType.BOSS: "보스",
}

const NODE_ICONS := {
	MapData.NodeType.BATTLE: "⚔",
	MapData.NodeType.ELITE: "💀",
	MapData.NodeType.EVENT: "?",
	MapData.NodeType.SHOP: "🏪",
	MapData.NodeType.REST: "🔥",
	MapData.NodeType.BOSS: "👹",
}

const NODE_SIZE := Vector2(120, 60)
const ROW_SPACING := 140.0
const MAP_PADDING_X := 80.0
const MAP_PADDING_TOP := 100.0
const MAP_PADDING_BOTTOM := 160.0

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
@onready var act_label: Label = $HUD/ActLabel

var _node_buttons: Dictionary = {}  # node_id → Button
var _node_positions: Dictionary = {}  # node_id → Vector2 (center)
var _available_node_ids: Array[int] = []


func _ready() -> void:
	if GameManager.run_data == null or GameManager.run_data.run_map == null:
		push_warning("RunMap: run_data 또는 run_map이 없음")
		return

	_build_map()
	_update_hud()
	_update_node_states()
	# 스크롤을 현재 위치로 이동
	call_deferred("_scroll_to_current")


func _update_hud() -> void:
	var rd := GameManager.run_data
	hp_label.text = "HP: %d/%d" % [rd.current_hp, rd.max_hp]
	gold_label.text = "금화: %d" % rd.gold
	var act_name: String = MapGenerator.get_act_name(rd.current_act)
	act_label.text = "%d막 — %s" % [rd.current_act, act_name]

	# 막별 배경색 적용
	var bg_color: Color = ACT_BG_COLORS.get(rd.current_act, ACT_BG_COLORS[1])
	_apply_map_background(bg_color)


func _apply_map_background(color: Color) -> void:
	# MapContainer에 배경색 적용
	var bg := map_container.get_node_or_null("Background")
	if bg == null:
		bg = ColorRect.new()
		bg.name = "Background"
		map_container.add_child(bg)
		map_container.move_child(bg, 0)
	bg.color = color
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.size = map_container.custom_minimum_size


func _build_map() -> void:
	var run_map := GameManager.run_data.run_map
	var viewport_width: float = get_viewport_rect().size.x

	# 맵 전체 높이 계산 (아래에서 위로: row 0 = 하단, boss = 상단)
	var total_height: float = MAP_PADDING_TOP + MAP_PADDING_BOTTOM + (run_map.total_rows - 1) * ROW_SPACING + NODE_SIZE.y
	map_container.custom_minimum_size = Vector2(viewport_width, total_height)

	# 노드 위치 계산 및 버튼 생성
	for r in range(run_map.total_rows):
		var row_nodes: Array = run_map.rows[r]
		var node_count: int = row_nodes.size()
		var usable_width: float = viewport_width - MAP_PADDING_X * 2

		for i in range(node_count):
			var node_id: int = row_nodes[i]
			var map_node: MapData.MapNode = run_map.nodes[node_id]

			# Y: 보스(마지막 행)가 위, 시작(0행)이 아래
			var y: float = MAP_PADDING_TOP + (run_map.total_rows - 1 - r) * ROW_SPACING
			# X: 행 내 균등 분배
			var x: float
			if node_count == 1:
				x = viewport_width / 2.0 - NODE_SIZE.x / 2.0
			else:
				x = MAP_PADDING_X + (usable_width - NODE_SIZE.x) * i / (node_count - 1)

			var center := Vector2(x + NODE_SIZE.x / 2.0, y + NODE_SIZE.y / 2.0)
			_node_positions[node_id] = center

			# 노드 버튼 생성
			var btn := Button.new()
			btn.custom_minimum_size = NODE_SIZE
			btn.size = NODE_SIZE
			btn.position = Vector2(x, y)

			var icon_text: String = NODE_ICONS.get(map_node.type, "?")
			var label_text: String = NODE_LABELS.get(map_node.type, "???")
			btn.text = "%s\n%s" % [icon_text, label_text]

			btn.add_theme_font_size_override("font_size", 16)
			btn.pressed.connect(_on_node_pressed.bind(node_id))

			node_layer.add_child(btn)
			_node_buttons[node_id] = btn

	# 연결선 그리기 — Line2D 노드로 생성
	_draw_connections()


func _draw_connections() -> void:
	# 기존 연결선 제거
	for child in line_layer.get_children():
		child.queue_free()

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
				color = Color(0.9, 0.85, 0.5, 0.9)
				width = 3.0
			elif nid in visited and conn_id in _available_node_ids:
				color = Color(0.8, 0.8, 0.8, 0.6)
				width = 2.0
			else:
				color = Color(0.4, 0.4, 0.4, 0.3)
				width = 1.5

			var line := Line2D.new()
			line.add_point(from_pos)
			line.add_point(to_pos)
			line.default_color = color
			line.width = width
			line.antialiased = true
			line_layer.add_child(line)


func _update_node_states() -> void:
	var run_map := GameManager.run_data.run_map
	var visited := GameManager.run_data.visited_nodes

	# 선택 가능한 노드 계산
	var available_nodes := run_map.get_available_nodes(visited)
	_available_node_ids.clear()
	for node in available_nodes:
		_available_node_ids.append(node.id)

	for nid in _node_buttons:
		var btn: Button = _node_buttons[nid]
		var map_node: MapData.MapNode = run_map.nodes[nid]
		var node_color: Color = NODE_COLORS.get(map_node.type, Color.WHITE)

		if nid in visited:
			# 방문한 노드: 어두운 색 + 비활성화
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5, 0.6)
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		elif nid in _available_node_ids:
			# 선택 가능한 노드: 밝은 색 + 펄스 효과
			btn.disabled = false
			btn.modulate = Color.WHITE
			var style := StyleBoxFlat.new()
			style.bg_color = node_color
			style.corner_radius_top_left = 8
			style.corner_radius_top_right = 8
			style.corner_radius_bottom_left = 8
			style.corner_radius_bottom_right = 8
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = Color(1, 1, 1, 0.8)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)

			var pressed_style := style.duplicate()
			pressed_style.bg_color = node_color.lightened(0.2)
			btn.add_theme_stylebox_override("pressed", pressed_style)

			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			# 잠긴 노드: 어둡게
			btn.disabled = true
			var style := StyleBoxFlat.new()
			style.bg_color = node_color.darkened(0.6)
			style.corner_radius_top_left = 8
			style.corner_radius_top_right = 8
			style.corner_radius_bottom_left = 8
			style.corner_radius_bottom_right = 8
			btn.add_theme_stylebox_override("disabled", style)
			btn.modulate = Color(0.6, 0.6, 0.6, 0.5)
			btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))

	# 현재 위치 마커: 마지막 방문 노드에 표시
	if not visited.is_empty():
		var last_id: int = visited[-1]
		if _node_buttons.has(last_id):
			var btn: Button = _node_buttons[last_id]
			btn.modulate = Color(1, 0.9, 0.4, 0.9)

	# 연결선 다시 그리기
	_draw_connections()


func _scroll_to_current() -> void:
	var run_map := GameManager.run_data.run_map
	var visited := GameManager.run_data.visited_nodes

	var target_y: float
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


func _on_node_pressed(node_id: int) -> void:
	if node_id not in _available_node_ids:
		return

	var run_map := GameManager.run_data.run_map
	var map_node: MapData.MapNode = run_map.nodes[node_id]

	# 방문 기록 추가
	GameManager.run_data.visited_nodes.append(node_id)

	# 현재 노드 정보를 GameManager에 전달 (전투용)
	GameManager.run_data.set_meta("current_node_type", map_node.type)
	GameManager.run_data.set_meta("current_encounter_id", map_node.encounter_id)

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
