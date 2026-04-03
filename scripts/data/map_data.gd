class_name MapData
extends RefCounted

## 런 맵의 노드 및 전체 맵 데이터 구조.
## Slay the Spire 스타일: 행(row) 기반 노드 그래프, 3~4 경로 분기.

enum NodeType {
	BATTLE,    # 일반 전투
	ELITE,     # 정예 전투
	EVENT,     # 랜덤 이벤트
	SHOP,      # 상점
	REST,       # 휴식
	BOSS,      # 보스
	GWAGEO,    # 과거시험
}

## 맵 위의 단일 노드.
class MapNode:
	var id: int                       # 고유 ID
	var row: int                      # 행 (0 = 시작, 마지막 = 보스)
	var column: int                   # 열 위치 (같은 행 내 순서)
	var type: NodeType                # 노드 종류
	var connections: Array[int]       # 다음 행으로 연결되는 노드 ID 목록
	var encounter_id: String = ""     # 적/이벤트 등 구체적 데이터 ID

	func _init() -> void:
		connections = []

	func to_dict() -> Dictionary:
		return {
			"id": id,
			"row": row,
			"column": column,
			"type": type,
			"connections": connections,
			"encounter_id": encounter_id,
		}

	static func from_dict(data: Dictionary) -> MapNode:
		var node := MapNode.new()
		node.id = data.get("id", 0)
		node.row = data.get("row", 0)
		node.column = data.get("column", 0)
		node.type = data.get("type", NodeType.BATTLE) as NodeType
		node.connections = Array(data.get("connections", []), TYPE_INT, "", null)
		node.encounter_id = data.get("encounter_id", "")
		return node


## 전체 런 맵 (1막 분량).
class RunMap:
	var act: int = 1
	var seed_value: int = 0
	var total_rows: int = 0           # 보스 행 포함
	var nodes: Dictionary             # id → MapNode
	var rows: Array                   # row_index → Array[int] (노드 ID 배열)

	func _init() -> void:
		nodes = {}
		rows = []

	func get_node(node_id: int) -> MapNode:
		return nodes.get(node_id)

	func get_row_nodes(row_index: int) -> Array:
		if row_index < 0 or row_index >= rows.size():
			return []
		var result: Array = []
		for nid in rows[row_index]:
			result.append(nodes[nid])
		return result

	## 현재 위치에서 선택 가능한 다음 노드 목록 반환.
	func get_available_nodes(visited: Array[int]) -> Array:
		if visited.is_empty():
			return get_row_nodes(0)

		var last_visited_id: int = visited[-1]
		var last_node: MapNode = nodes.get(last_visited_id)
		if not last_node:
			return []

		var available: Array = []
		for conn_id in last_node.connections:
			available.append(nodes[conn_id])
		return available

	func to_dict() -> Dictionary:
		var nodes_dict := {}
		for nid in nodes:
			nodes_dict[str(nid)] = nodes[nid].to_dict()
		var rows_array := []
		for row in rows:
			rows_array.append(Array(row))
		return {
			"act": act,
			"seed_value": seed_value,
			"total_rows": total_rows,
			"nodes": nodes_dict,
			"rows": rows_array,
		}

	static func from_dict(data: Dictionary) -> RunMap:
		var rm := RunMap.new()
		rm.act = data.get("act", 1)
		rm.seed_value = data.get("seed_value", 0)
		rm.total_rows = data.get("total_rows", 0)
		var nodes_data: Dictionary = data.get("nodes", {})
		for key in nodes_data:
			var node := MapNode.from_dict(nodes_data[key])
			rm.nodes[node.id] = node
		var rows_data: Array = data.get("rows", [])
		for row in rows_data:
			rm.rows.append(Array(row, TYPE_INT, "", null))
		return rm
