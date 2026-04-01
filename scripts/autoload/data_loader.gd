extends Node

## JSON 데이터 파일을 로드하여 게임 데이터로 변환하는 오토로드.

var _card_data: Dictionary = {}
var _enemy_data: Dictionary = {}
var _event_data: Dictionary = {}
var _relic_data: Dictionary = {}


func _ready() -> void:
	_load_all_cards()
	_load_all_enemies()


func _load_all_cards() -> void:
	_load_json_dir("res://data/cards/", _card_data)


func _load_all_enemies() -> void:
	_load_json_dir("res://data/enemies/", _enemy_data)


func _load_json_dir(path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var full_path := path + file_name
			var file := FileAccess.open(full_path, FileAccess.READ)
			if file:
				var json := JSON.new()
				var err := json.parse(file.get_as_text())
				if err == OK:
					var data = json.data
					if data is Dictionary:
						target.merge(data)
					elif data is Array:
						for item in data:
							if item is Dictionary and item.has("id"):
								target[item["id"]] = item
				file.close()
		file_name = dir.get_next()
	dir.list_dir_end()


func get_card(card_id: String) -> Dictionary:
	return _card_data.get(card_id, {})


func get_all_cards() -> Dictionary:
	return _card_data


func get_starter_deck(character: String) -> Array:
	var starter := []
	for card_id in _card_data:
		var card: Dictionary = _card_data[card_id]
		var pool: String = card.get("pool", "")
		if pool == "common" or pool == character:
			if card.get("starter", false):
				starter.append(card.duplicate(true))
	return starter


func get_enemy(enemy_id: String) -> Dictionary:
	return _enemy_data.get(enemy_id, {})
