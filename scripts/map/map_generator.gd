class_name MapGenerator
extends RefCounted

## 맵 절차적 생성기 (1~3막 지원).
## Slay the Spire 스타일: 시작(전투) → 중간(혼합) → 휴식 → 보스.
## 3~4 경로 분기, 막별 난이도 스케일링.

const MIN_NODES_PER_ROW := 2
const MAX_NODES_PER_ROW := 4

## 막별 설정: 행 수, 목표 노드 수, 막 이름
const ACT_CONFIG := {
	1: { "total_rows": 7, "min_nodes": 15, "max_nodes": 17, "name": "한양" },
	2: { "total_rows": 8, "min_nodes": 17, "max_nodes": 20, "name": "지리산" },
	3: { "total_rows": 8, "min_nodes": 17, "max_nodes": 20, "name": "경복궁" },
}

## 막별 행 노드 타입 분포 가중치.
## row 0: 전투 전용, 마지막 행: 보스 전용.
## 2막: 엘리트 비중 증가, 휴식 감소.
## 3막: 전투+엘리트 대폭 증가, 상점/이벤트 감소.
const ACT_ROW_WEIGHTS := {
	1: {
		1: { "BATTLE": 50, "EVENT": 30, "SHOP": 10, "REST": 10 },
		2: { "BATTLE": 40, "EVENT": 25, "ELITE": 15, "SHOP": 10, "REST": 10 },
		3: { "BATTLE": 30, "EVENT": 20, "ELITE": 25, "SHOP": 15, "REST": 10 },
		4: { "BATTLE": 35, "EVENT": 25, "ELITE": 20, "SHOP": 10, "REST": 10 },
		5: { "BATTLE": 15, "EVENT": 15, "ELITE": 10, "SHOP": 20, "REST": 40 },
	},
	2: {
		1: { "BATTLE": 45, "EVENT": 25, "ELITE": 10, "SHOP": 10, "REST": 10 },
		2: { "BATTLE": 35, "EVENT": 20, "ELITE": 20, "SHOP": 10, "REST": 15 },
		3: { "BATTLE": 30, "EVENT": 15, "ELITE": 30, "SHOP": 10, "REST": 15 },
		4: { "BATTLE": 30, "EVENT": 15, "ELITE": 25, "SHOP": 15, "REST": 15 },
		5: { "BATTLE": 25, "EVENT": 15, "ELITE": 15, "SHOP": 15, "REST": 30 },
		6: { "BATTLE": 15, "EVENT": 10, "ELITE": 10, "SHOP": 25, "REST": 40 },
	},
	3: {
		1: { "BATTLE": 40, "EVENT": 20, "ELITE": 15, "SHOP": 10, "REST": 15 },
		2: { "BATTLE": 35, "EVENT": 15, "ELITE": 25, "SHOP": 10, "REST": 15 },
		3: { "BATTLE": 30, "EVENT": 10, "ELITE": 35, "SHOP": 10, "REST": 15 },
		4: { "BATTLE": 30, "EVENT": 15, "ELITE": 30, "SHOP": 10, "REST": 15 },
		5: { "BATTLE": 25, "EVENT": 10, "ELITE": 20, "SHOP": 15, "REST": 30 },
		6: { "BATTLE": 15, "EVENT": 10, "ELITE": 10, "SHOP": 25, "REST": 40 },
	},
}


var _rng: RandomNumberGenerator


## 막 이름을 반환한다.
static func get_act_name(act: int) -> String:
	var config: Dictionary = ACT_CONFIG.get(act, ACT_CONFIG[1])
	return config.get("name", "%d막" % act)


func generate(seed_value: int, act: int = 1) -> MapData.RunMap:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value

	var config: Dictionary = ACT_CONFIG.get(act, ACT_CONFIG[1])
	var total_rows: int = config.get("total_rows", 7)
	var boss_row: int = total_rows - 1
	var min_nodes: int = config.get("min_nodes", 15)
	var max_nodes: int = config.get("max_nodes", 17)

	var run_map := MapData.RunMap.new()
	run_map.act = act
	run_map.seed_value = seed_value
	run_map.total_rows = total_rows

	var next_id := 0

	# 1. 행별 노드 수 결정
	var row_sizes: Array[int] = []
	row_sizes.append(_rng.randi_range(3, MAX_NODES_PER_ROW))  # row 0: 시작 3~4
	for r in range(1, boss_row):
		row_sizes.append(_rng.randi_range(MIN_NODES_PER_ROW, 3))
	row_sizes.append(1)  # boss row

	# 총 노드 수 조정
	var total := 0
	for s in row_sizes:
		total += s
	while total < min_nodes:
		var target_row := _rng.randi_range(1, boss_row - 1)
		if row_sizes[target_row] < MAX_NODES_PER_ROW:
			row_sizes[target_row] += 1
			total += 1
	while total > max_nodes:
		var target_row := _rng.randi_range(1, boss_row - 1)
		if row_sizes[target_row] > MIN_NODES_PER_ROW:
			row_sizes[target_row] -= 1
			total -= 1

	# 2. 노드 생성
	for r in range(total_rows):
		var row_ids: Array[int] = []
		for c in range(row_sizes[r]):
			var node := MapData.MapNode.new()
			node.id = next_id
			node.row = r
			node.column = c
			node.type = _pick_node_type(r, boss_row, act)
			# 보스 노드에 encounter_id 할당
			if node.type == MapData.NodeType.BOSS:
				node.encounter_id = _get_boss_encounter_id(act)
			run_map.nodes[next_id] = node
			row_ids.append(next_id)
			next_id += 1
		run_map.rows.append(row_ids)

	# 3. 연결 생성 (모든 노드 도달 가능 보장)
	_generate_connections(run_map)

	# 4. 엘리트 최소 보장 (2막 이후 최소 2개)
	var min_elites := 2 if act >= 2 else 1
	_ensure_elite(run_map, min_elites)

	return run_map


func _pick_node_type(row: int, boss_row: int, act: int) -> MapData.NodeType:
	if row == 0:
		return MapData.NodeType.BATTLE
	if row == boss_row:
		return MapData.NodeType.BOSS

	var act_weights: Dictionary = ACT_ROW_WEIGHTS.get(act, ACT_ROW_WEIGHTS[1])
	var weights: Dictionary = act_weights.get(row, act_weights.get(1, {}))
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
	for r in range(run_map.total_rows - 1):
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


func _ensure_elite(run_map: MapData.RunMap, min_count: int = 1) -> void:
	var elite_count := 0
	for nid in run_map.nodes:
		if run_map.nodes[nid].type == MapData.NodeType.ELITE:
			elite_count += 1

	var boss_row: int = run_map.total_rows - 1
	while elite_count < min_count:
		# 행 2~(보스-2) 에서 전투 노드를 엘리트로 변경
		var candidates: Array[int] = []
		var elite_start := 2
		var elite_end := mini(boss_row - 1, boss_row)
		for r in range(elite_start, elite_end):
			for nid in run_map.rows[r]:
				if run_map.nodes[nid].type == MapData.NodeType.BATTLE:
					candidates.append(nid)
		if candidates.is_empty():
			break
		var pick: int = candidates[_rng.randi_range(0, candidates.size() - 1)]
		run_map.nodes[pick].type = MapData.NodeType.ELITE
		elite_count += 1


func _get_boss_encounter_id(act: int) -> String:
	## 막별 최종 보스 encounter_id 반환
	match act:
		1: return "B_ACT1_FINAL"
		2: return "B_ACT2_FINAL"
		3: return "B_ACT3_FINAL"
	return "B_ACT1_FINAL"
