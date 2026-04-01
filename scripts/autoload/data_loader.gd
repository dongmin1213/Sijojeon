extends Node

## JSON 데이터 파일을 로드하여 게임 데이터로 변환하는 오토로드.

# CardData 리소스 (id → CardData)
var _cards: Dictionary = {}
# 적 데이터 (id → Dictionary)
var _enemies: Dictionary = {}
# 캐릭터 스킬 데이터
var _skills_data: Dictionary = {}

# 스타터 덱 구성 (character_id → Array[card_id])
const STARTER_DECKS := {
	"dosa": [
		"M003", "M003",  # 후퇴 ×2
		"M005",          # 포복 ×1
		"D001", "D001",  # 기공 ×2
		"D002",          # 결인 ×1
		"D003",          # 진언 ×1
		"D007", "D007", "D007",  # 수결(베기 대용) ×3
	],
	"mugwan": [
		"M003", "M003",  # 후퇴 ×2
		"M005",          # 포복 ×1
		"G001", "G001",  # 진형 전환 ×2
		"G002", "G002",  # 돌격 ×2
		"G003",          # 포위 ×1
		"M002", "M002",  # 도약 ×2
	],
}


func _ready() -> void:
	_load_all_cards()
	_load_all_enemies()
	_load_skills()


func _load_all_cards() -> void:
	var dir := DirAccess.open("res://data/cards/")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var full_path := "res://data/cards/" + file_name
			_load_card_file(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_card_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("DataLoader: JSON 파싱 실패 — %s" % path)
		return

	var data = json.data
	if not data is Dictionary:
		return

	var pool: String = data.get("class", "common")
	var cards_array = data.get("cards", [])
	if not cards_array is Array:
		return

	for card_dict in cards_array:
		if card_dict is Dictionary and card_dict.has("id"):
			var card := CardData.from_dict(card_dict, pool)
			_cards[card.id] = card


func _load_all_enemies() -> void:
	var dir := DirAccess.open("res://data/enemies/")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var full_path := "res://data/enemies/" + file_name
			_load_enemy_file(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_enemy_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return

	var data = json.data
	if data is Dictionary:
		# 적 파일도 중첩 구조일 수 있음
		for category_key in ["regular_enemies", "elite_enemies", "bosses"]:
			var enemies_array = data.get(category_key, [])
			if enemies_array is Array:
				for enemy_dict in enemies_array:
					if enemy_dict is Dictionary and enemy_dict.has("id"):
						_enemies[enemy_dict["id"]] = enemy_dict
	elif data is Array:
		for item in data:
			if item is Dictionary and item.has("id"):
				_enemies[item["id"]] = item


func _load_skills() -> void:
	var path := "res://data/skills/special_skills.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var json := JSON.new()
		var err := json.parse(file.get_as_text())
		if err == OK and json.data is Dictionary:
			_skills_data = json.data
		file.close()


# --- 공개 API ---

func get_card(card_id: String) -> CardData:
	return _cards.get(card_id, null)


func get_all_cards() -> Dictionary:
	return _cards


func get_cards_by_pool(pool: String) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in _cards.values():
		if card.pool == pool:
			result.append(card)
	return result


func get_starter_deck(character_id: String) -> Array[String]:
	if STARTER_DECKS.has(character_id):
		return STARTER_DECKS[character_id].duplicate()
	return []


func get_enemy(enemy_id: String) -> Dictionary:
	return _enemies.get(enemy_id, {})


func get_character_skills(character_id: String) -> Dictionary:
	if not _skills_data.has("character_special_skills"):
		return {}
	for entry in _skills_data["character_special_skills"]:
		if entry.get("class_id", "") == character_id:
			var hp_data: Dictionary = _skills_data.get("core_systems", {}).get("hp", {}).get("base_hp_by_class", {}).get(character_id, {})
			var energy_data: Dictionary = _skills_data.get("core_systems", {}).get("energy", {})
			return {
				"base_hp": hp_data.get("hp", 70),
				"base_qi": energy_data.get("base_energy_per_turn", 3),
				"starting_relic": entry.get("starting_relic", {}).get("id", ""),
				"passive": entry.get("passive_name", {}),
				"active_skill": entry.get("active_skill", {}),
			}
	return {}
