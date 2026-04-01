class_name MapGenerator
extends RefCounted

## 1막 맵 절차적 생성기.
## Slay the Spire 스타일: 시작(전투) → 중간(혼합) → 휴식 → 보스.
## 3~4 경로 분기, 15~17 노드.

const TOTAL_ROWS := 7        # 행 0~6 (6 = 보스)
const MIN_NODES_PER_ROW := 2
const MAX_NODES_PER_ROW := 4
const BOSS_ROW := 6

## 행별 노드 타입 분포 가중치.
## row 0: 전투 전용, row 5: 휴식 가능, row 6: 보스 전용.
const ROW_WEIGHTS := {
	# row: { NodeType: weight }
	1: { "BATTLE": 50, "EVENT": 30, "SHOP": 10, "REST": 10 },
	2: { "BATTLE": 40, "EVENT": 25, "ELITE": 15, "SHOP": 10, "REST": 10 },
	3: { "BATTLE": 30, "EVENT": 20, "ELITE": 25, "SHOP": 15, "REST": 10 },
	4: { "BATTLE": 35, "EVENT": 25, "ELITE": 20, "SHOP": 10, "REST": 10 },
	5: { "BATTLE": 15, "EVENT": 15, "ELITE": 10, "SHOP": 20, "REST": 40 },
}


var _rng: RandomNumberGenerator


func generate(seed_value: int, act: int = 1) -> MapData.RunMap:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value

	var run_map := MapData.RunMap.new()
	run_map.act = act
	run_map.seed_value = seed_value
	run_map.total_rows = TOTAL_ROWS

	var next_id := 0

	# 1. 행별 노드 수 결정
	var row_sizes: Array[int] = []
	row_sizes.append(_rng.randi_range(3, MAX_NODES_PER_ROW))  # row 0: 시작 3~4
	for r in range(1, BOSS_ROW):
		row_sizes.append(_rng.randi_range(MIN_NODES_PER_ROW, 3))
	row_sizes.append(1)  # boss row

	# 총 노드 수 조정 (15~17 목표)
	var total := 0
	for s in row_sizes:
		total += s
	while total < 15:
		var target_row := _rng.randi_range(1, BOSS_ROW - 1)
		if row_sizes[target_row] < MAX_NODES_PER_ROW:
			row_sizes[target_row] += 1
			total += 1
	while total > 17:
		var target_row := _rng.randi_range(1, BOSS_ROW - 1)
		if row_sizes[target_row] > MIN_NODES_PER_ROW:
			row_sizes[target_row] -= 1
			total -= 1

	# 2. 노드 생성
	for r in range(TOTAL_ROWS):
		var row_ids: Array[int] = []
		for c in range(row_sizes[r]):
			var node := MapData.MapNode.new()
			node.id = next_id
			node.row = r
			node.column = c
			node.type = _pick_node_type(r)
			run_map.nodes[next_id] = node
			row_ids.append(next_id)
			next_id += 1
		run_map.rows.append(row_ids)

	# 3. 연결 생성 (모든 노드 도달 가능 보장)
	_generate_connections(run_map)

	# 4. 엘리트 최소 1개 보장
	_ensure_elite(run_map)

	return run_map


func _pick_node_type(row: int) -> MapData.NodeType:
	if row == 0:
		return MapData.NodeType.BATTLE
	if row == BOSS_ROW:
		return MapData.NodeType.BOSS

	var weights: Dictionary = ROW_WEIGHTS.get(row, ROW_WEIGHTS[1])
	var total_weight := 0
	for w in weights.values():
		total_weight += w

	var roll := _rng.randi_range(1, total_weight)
	var cumulative := 0
	for type_name in weights:
		cumulative += weights[type_name]
		if roll <= cumulative:
			return _type_from_string(type_name)

	return MapData.NodeType.BATTLE


func _type_from_string(s: String) -> MapData.NodeType:
	match s:
		"BATTLE": return MapData.NodeType.BATTLE
		"ELITE": return MapData.NodeType.ELITE
		"EVENT": return MapData.NodeType.EVENT
		"SHOP": return MapData.NodeType.SHOP
		"REST": return MapData.NodeType.REST
		"BOSS": return MapData.NodeType.BOSS
	return MapData.NodeType.BATTLE


func _generate_connections(run_map: MapData.RunMap) -> void:
	for r in range(TOTAL_ROWS - 1):
		var current_row: Array = run_map.rows[r]
		var next_row: Array = run_map.rows[r + 1]
		var next_count: int = next_row.size()

		# 먼저 모든 다음 행 노드가 최소 1개 부모를 갖도록 보장
		var connected_children: Dictionary = {}  # child_id → bool

		for i in range(current_row.size()):
			var node: MapData.MapNode = run_map.nodes[current_row[i]]
			# 기본 연결: 대응하는 위치의 자식 (또는 가장 가까운)
			var base_child_idx := clampi(i, 0, next_count - 1)
			var child_id: int = next_row[base_child_idx]
			if child_id not in node.connections:
				node.connections.append(child_id)
			connected_children[child_id] = true

			# 추가 연결 (인접 노드로, 40% 확률)
			if base_child_idx > 0 and _rng.randf() < 0.4:
				var alt_id: int = next_row[base_child_idx - 1]
				if alt_id not in node.connections:
					node.connections.append(alt_id)
				connected_children[alt_id] = true
			if base_child_idx < next_count - 1 and _rng.randf() < 0.4:
				var alt_id: int = next_row[base_child_idx + 1]
				if alt_id not in node.connections:
					node.connections.append(alt_id)
				connected_children[alt_id] = true

		# 연결 안 된 자식 노드 처리 (가장 가까운 부모에서 연결)
		for j in range(next_count):
			var child_id: int = next_row[j]
			if not connected_children.has(child_id):
				var best_parent_idx := clampi(j, 0, current_row.size() - 1)
				var parent: MapData.MapNode = run_map.nodes[current_row[best_parent_idx]]
				if child_id not in parent.connections:
					parent.connections.append(child_id)


func _ensure_elite(run_map: MapData.RunMap) -> void:
	var has_elite := false
	for nid in run_map.nodes:
		if run_map.nodes[nid].type == MapData.NodeType.ELITE:
			has_elite = true
			break

	if not has_elite:
		# 행 2~4 에서 하나를 엘리트로 변경
		var candidates: Array[int] = []
		for r in range(2, 5):
			for nid in run_map.rows[r]:
				if run_map.nodes[nid].type == MapData.NodeType.BATTLE:
					candidates.append(nid)
		if not candidates.is_empty():
			var pick: int = candidates[_rng.randi_range(0, candidates.size() - 1)]
			run_map.nodes[pick].type = MapData.NodeType.ELITE
