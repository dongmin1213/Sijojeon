class_name MapGenerator
extends RefCounted

## v10: 경로 기반 맵 생성기 (Slay the Spire 방식).
## 7열 그리드에 6개 경로를 생성하고, 경로가 지나는 셀에만 노드를 배치.
## 교차 연결 제거로 가시성 대폭 개선.

const NUM_COLUMNS := 7
const NUM_PATHS := 6

## 막별 설정
const ACT_CONFIG := {
	1: { "total_rows": 16, "name": "한양" },
	2: { "total_rows": 17, "name": "지리산" },
	3: { "total_rows": 17, "name": "경복궁" },
}

## 막별 노드 타입 분포 가중치 (진행도 구간별)
const ACT_PHASE_WEIGHTS := {
	1: {
		"early":    { "BATTLE": 50, "EVENT": 25, "SHOP": 5, "REST": 10, "ELITE": 10 },
		"mid":      { "BATTLE": 40, "EVENT": 28, "ELITE": 8, "SHOP": 10, "REST": 14 },
		"late":     { "BATTLE": 35, "EVENT": 25, "ELITE": 12, "SHOP": 10, "REST": 18 },
		"pre_boss": { "BATTLE": 15, "EVENT": 15, "ELITE": 5, "SHOP": 25, "REST": 40 },
	},
	2: {
		"early":    { "BATTLE": 45, "EVENT": 25, "ELITE": 10, "SHOP": 5, "REST": 15 },
		"mid":      { "BATTLE": 40, "EVENT": 25, "ELITE": 12, "SHOP": 10, "REST": 13 },
		"late":     { "BATTLE": 35, "EVENT": 22, "ELITE": 15, "SHOP": 12, "REST": 16 },
		"pre_boss": { "BATTLE": 15, "EVENT": 10, "ELITE": 5, "SHOP": 25, "REST": 45 },
	},
	3: {
		"early":    { "BATTLE": 45, "EVENT": 20, "ELITE": 15, "SHOP": 5, "REST": 15 },
		"mid":      { "BATTLE": 40, "EVENT": 22, "ELITE": 18, "SHOP": 8, "REST": 12 },
		"late":     { "BATTLE": 35, "EVENT": 18, "ELITE": 22, "SHOP": 10, "REST": 15 },
		"pre_boss": { "BATTLE": 15, "EVENT": 10, "ELITE": 10, "SHOP": 25, "REST": 40 },
	},
}


var _rng: RandomNumberGenerator


## 막 이름을 반환한다 (번역키 사용).
static func get_act_name(act: int) -> String:
	var key := "ACT_NAME_%d" % act
	var translated := TranslationServer.translate(key)
	if translated != key:
		return translated
	var config: Dictionary = ACT_CONFIG.get(act, ACT_CONFIG[1])
	return config.get("name", "%d막" % act)


func generate(seed_value: int, act: int = 1) -> MapData.RunMap:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value

	var config: Dictionary = ACT_CONFIG.get(act, ACT_CONFIG[1])
	var total_rows: int = config.get("total_rows", 16)
	var boss_row: int = total_rows - 1

	var run_map := MapData.RunMap.new()
	run_map.act = act
	run_map.seed_value = seed_value
	run_map.total_rows = total_rows

	# 1. 경로 생성 — 6개 경로가 7열 그리드를 관통
	var paths := _generate_paths(total_rows)

	# 2. 경로를 기반으로 노드 생성 (같은 셀은 노드 공유)
	var grid: Dictionary = {}  # "row,col" → node_id
	var next_id := 0

	for r in range(total_rows):
		var row_ids: Array[int] = []
		# 이 행에서 경로가 지나는 열 수집 (중복 제거, 정렬)
		var cols_in_row: Array[int] = []
		for path in paths:
			var col: int = path[r]
			if col not in cols_in_row:
				cols_in_row.append(col)
		cols_in_row.sort()

		for col in cols_in_row:
			var key := "%d,%d" % [r, col]
			if not grid.has(key):
				var node := MapData.MapNode.new()
				node.id = next_id
				node.row = r
				node.column = col
				node.type = _pick_node_type(r, boss_row, act)
				node.encounter_id = _pick_encounter_id(node.type, act)
				run_map.nodes[next_id] = node
				grid[key] = next_id
				row_ids.append(next_id)
				next_id += 1
			else:
				var existing_id: int = grid[key]
				if existing_id not in row_ids:
					row_ids.append(existing_id)

		# row_ids를 열 순서대로 정렬
		row_ids.sort_custom(func(a: int, b: int) -> bool:
			return run_map.nodes[a].column < run_map.nodes[b].column
		)
		run_map.rows.append(row_ids)

	# 3. 경로를 따라 연결 생성 (교차 없음)
	_generate_connections_from_paths(run_map, paths, grid)

	# 4. 노드 타입 최소 보장
	_ensure_node_type(run_map, MapData.NodeType.ELITE, 3)
	_ensure_node_type(run_map, MapData.NodeType.REST, 3)
	_ensure_node_type(run_map, MapData.NodeType.EVENT, 4)

	# 5. 행 규칙 적용 — 보스 직전(pre_boss) 행은 REST 보장
	_ensure_pre_boss_rest(run_map)

	return run_map


## 6개 경로를 생성한다. 각 경로는 0행~(total_rows-1)행까지의 열 인덱스 배열.
func _generate_paths(total_rows: int) -> Array:
	var paths: Array = []
	var used_start_cols: Array[int] = []

	for _p in range(NUM_PATHS):
		var path: Array[int] = []
		# 시작 열 선택 (다양한 시작점 보장)
		var start_col: int
		if used_start_cols.size() < NUM_COLUMNS:
			# 아직 사용하지 않은 열 중 선택
			var available_cols: Array[int] = []
			for c in range(NUM_COLUMNS):
				if c not in used_start_cols:
					available_cols.append(c)
			start_col = available_cols[_rng.randi() % available_cols.size()]
		else:
			start_col = _rng.randi_range(0, NUM_COLUMNS - 1)
		used_start_cols.append(start_col)
		path.append(start_col)

		# 경로 진행: 인접 열로 이동 (x-1, x, x+1)
		for r in range(1, total_rows - 1):
			var prev_col: int = path[r - 1]
			var min_col := maxi(0, prev_col - 1)
			var max_col := mini(NUM_COLUMNS - 1, prev_col + 1)
			var next_col := _rng.randi_range(min_col, max_col)
			path.append(next_col)

		# 보스 행: 중앙 열로 수렴
		path.append(NUM_COLUMNS / 2)
		paths.append(path)

	# 교차 제거: 두 경로가 같은 행에서 교차(X자)하면 하나를 조정
	_remove_path_crossings(paths, total_rows)

	return paths


## 경로 교차를 제거한다. X자 교차가 발생하면 열을 맞바꿔 해소.
func _remove_path_crossings(paths: Array, total_rows: int) -> void:
	for r in range(total_rows - 1):
		for i in range(paths.size()):
			for j in range(i + 1, paths.size()):
				var a_cur: int = paths[i][r]
				var a_next: int = paths[i][r + 1]
				var b_cur: int = paths[j][r]
				var b_next: int = paths[j][r + 1]
				# 교차 조건: a가 b보다 왼쪽인데 다음 행에서 오른쪽이 됨 (또는 반대)
				if (a_cur < b_cur and a_next > b_next) or (a_cur > b_cur and a_next < b_next):
					# j 경로의 다음 행 열을 i의 다음 행과 맞바꿈
					paths[j][r + 1] = a_next
					paths[i][r + 1] = b_next


## 경로 기반 연결 생성 (교차 없음 보장).
func _generate_connections_from_paths(run_map: MapData.RunMap, paths: Array, grid: Dictionary) -> void:
	for path in paths:
		for r in range(run_map.total_rows - 1):
			var from_key := "%d,%d" % [r, path[r]]
			var to_key := "%d,%d" % [r + 1, path[r + 1]]
			if not grid.has(from_key) or not grid.has(to_key):
				continue
			var from_id: int = grid[from_key]
			var to_id: int = grid[to_key]
			var from_node: MapData.MapNode = run_map.nodes[from_id]
			if to_id not in from_node.connections:
				from_node.connections.append(to_id)


func _pick_node_type(row: int, boss_row: int, act: int) -> MapData.NodeType:
	if row == 0:
		return MapData.NodeType.BATTLE
	if row == boss_row:
		return MapData.NodeType.BOSS

	var phase := _get_row_phase(row, boss_row)
	var act_weights: Dictionary = ACT_PHASE_WEIGHTS.get(act, ACT_PHASE_WEIGHTS[1])
	var weights: Dictionary = act_weights.get(phase, act_weights["mid"]).duplicate()

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


func _get_row_phase(row: int, boss_row: int) -> String:
	var progress := float(row) / float(boss_row)
	if progress <= 0.25:
		return "early"
	elif progress <= 0.60:
		return "mid"
	elif progress <= 0.85:
		return "late"
	else:
		return "pre_boss"


func _ensure_node_type(run_map: MapData.RunMap, target_type: MapData.NodeType, min_count: int) -> void:
	var count := 0
	for nid in run_map.nodes:
		if run_map.nodes[nid].type == target_type:
			count += 1

	var boss_row: int = run_map.total_rows - 1
	while count < min_count:
		var candidates: Array[int] = []
		for r in range(2, boss_row):
			for nid in run_map.rows[r]:
				if run_map.nodes[nid].type == MapData.NodeType.BATTLE:
					candidates.append(nid)
		if candidates.is_empty():
			break
		var pick: int = candidates[_rng.randi_range(0, candidates.size() - 1)]
		run_map.nodes[pick].type = target_type
		count += 1


## 보스 직전 2행의 노드 중 최소 1개는 REST 보장.
func _ensure_pre_boss_rest(run_map: MapData.RunMap) -> void:
	var boss_row: int = run_map.total_rows - 1
	var pre_boss_row: int = boss_row - 1
	if pre_boss_row < 1:
		return
	var has_rest := false
	for nid in run_map.rows[pre_boss_row]:
		if run_map.nodes[nid].type == MapData.NodeType.REST:
			has_rest = true
			break
	if not has_rest and not run_map.rows[pre_boss_row].is_empty():
		# 전투 노드를 REST로 변환
		for nid in run_map.rows[pre_boss_row]:
			if run_map.nodes[nid].type == MapData.NodeType.BATTLE:
				run_map.nodes[nid].type = MapData.NodeType.REST
				break


## 노드 타입과 act에 따라 적절한 encounter_id를 랜덤 선택한다.
func _pick_encounter_id(node_type: MapData.NodeType, act: int) -> String:
	match node_type:
		MapData.NodeType.BATTLE:
			var pool := DataLoader.get_regular_enemy_ids_for_act(act)
			if not pool.is_empty():
				return pool[_rng.randi() % pool.size()]
			return ""
		MapData.NodeType.ELITE:
			var pool := DataLoader.get_elite_enemy_ids_for_act(act)
			if not pool.is_empty():
				return pool[_rng.randi() % pool.size()]
			return ""
		MapData.NodeType.BOSS:
			return _get_boss_encounter_id(act)
		_:
			return ""


func _get_boss_encounter_id(act: int) -> String:
	match act:
		1: return "B_ACT1_FINAL"
		2: return "B_ACT2_FINAL"
		3: return "B_ACT3_FINAL"
	return "B_ACT1_FINAL"
