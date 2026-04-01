class_name RunData
extends Resource

## 현재 런 상태를 추적하는 데이터 클래스.

@export var character_id: String = ""
@export var current_hp: int = 70
@export var max_hp: int = 70
@export var gold: int = 99
@export var qi_per_turn: int = 3
@export var current_act: int = 1
@export var current_floor: int = 0
@export var deck: Array[String] = []
@export var relics: Array[String] = []
@export var map_seed: int = 0
@export var visited_nodes: Array[int] = []
var run_map: MapData.RunMap = null


func to_dict() -> Dictionary:
	return {
		"character_id": character_id,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"gold": gold,
		"qi_per_turn": qi_per_turn,
		"current_act": current_act,
		"current_floor": current_floor,
		"deck": deck,
		"relics": relics,
		"map_seed": map_seed,
		"visited_nodes": visited_nodes,
		"run_map": run_map.to_dict() if run_map else {},
	}


static func from_dict(data: Dictionary) -> RunData:
	var rd := RunData.new()
	rd.character_id = data.get("character_id", "")
	rd.current_hp = data.get("current_hp", 70)
	rd.max_hp = data.get("max_hp", 70)
	rd.gold = data.get("gold", 99)
	rd.qi_per_turn = data.get("qi_per_turn", 3)
	rd.current_act = data.get("current_act", 1)
	rd.current_floor = data.get("current_floor", 0)
	rd.deck = Array(data.get("deck", []), TYPE_STRING, "", null)
	rd.relics = Array(data.get("relics", []), TYPE_STRING, "", null)
	rd.map_seed = data.get("map_seed", 0)
	rd.visited_nodes = Array(data.get("visited_nodes", []), TYPE_INT, "", null)
	var map_dict: Dictionary = data.get("run_map", {})
	if not map_dict.is_empty():
		rd.run_map = MapData.RunMap.from_dict(map_dict)
	return rd
