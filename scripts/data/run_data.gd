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
@export var card_removals_count: int = 0
@export var upgraded_cards: Array[String] = []  # 강화된 카드 ID 목록
@export var map_seed: int = 0
@export var visited_nodes: Array[int] = []
var run_map: MapData.RunMap = null
var previous_maps: Array = []  # 이전 막 맵 목록 [{act, map_dict, visited_nodes}]
var current_node_type: int = -1  # 현재 노드 타입 (MapData.NodeType, -1은 없음)
var current_encounter_id: String = ""  # 현재 조우 ID
var is_daily_challenge: bool = false  # 일일 도전 모드 여부
var daily_date: String = ""  # 일일 도전 날짜 (YYYY-MM-DD)
var daily_score: int = 0  # 일일 도전 점수
var ascension_level: int = 0  # 어센션(귀신 단계) 레벨
var ascension_modifiers: Array = []  # 현재 적용 중인 수정자 목록

## 역사 사건 이벤트 — 발동된 이벤트 ID 목록 (중복 방지)
var triggered_special_events: Array[String] = []
## 서사 프레임 상태 (파벌 점수, 태그, 대기 효과 등)
var narrative_state: Dictionary = {}


func to_dict() -> Dictionary:
	var prev_maps_arr := []
	for pm in previous_maps:
		prev_maps_arr.append(pm)
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
		"card_removals_count": card_removals_count,
		"upgraded_cards": upgraded_cards,
		"map_seed": map_seed,
		"visited_nodes": visited_nodes,
		"run_map": run_map.to_dict() if run_map else {},
		"previous_maps": prev_maps_arr,
		"current_node_type": current_node_type,
		"current_encounter_id": current_encounter_id,
		"is_daily_challenge": is_daily_challenge,
		"daily_date": daily_date,
		"daily_score": daily_score,
		"ascension_level": ascension_level,
		"ascension_modifiers": ascension_modifiers,
		"triggered_special_events": triggered_special_events,
		"narrative_state": narrative_state,
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
	rd.card_removals_count = data.get("card_removals_count", 0)
	rd.upgraded_cards = Array(data.get("upgraded_cards", []), TYPE_STRING, "", null)
	rd.map_seed = data.get("map_seed", 0)
	rd.visited_nodes = Array(data.get("visited_nodes", []), TYPE_INT, "", null)
	var map_dict: Dictionary = data.get("run_map", {})
	if not map_dict.is_empty():
		rd.run_map = MapData.RunMap.from_dict(map_dict)
	rd.previous_maps = data.get("previous_maps", [])
	rd.current_node_type = data.get("current_node_type", -1)
	rd.current_encounter_id = data.get("current_encounter_id", "")
	rd.is_daily_challenge = data.get("is_daily_challenge", false)
	rd.daily_date = data.get("daily_date", "")
	rd.daily_score = data.get("daily_score", 0)
	rd.ascension_level = data.get("ascension_level", 0)
	rd.ascension_modifiers = data.get("ascension_modifiers", [])
	rd.triggered_special_events = Array(data.get("triggered_special_events", []), TYPE_STRING, "", null)
	rd.narrative_state = data.get("narrative_state", {})
	return rd
