extends Node

## 세이브/로드 관리 오토로드.

const SAVE_PATH := "user://save_data.json"
const META_PATH := "user://meta_data.json"


func save_run() -> void:
	var data := {
		"character": GameManager.current_character,
		"act": GameManager.current_act,
		"hp": GameManager.player_hp,
		"max_hp": GameManager.player_max_hp,
		"gold": GameManager.player_gold,
		"deck": GameManager.deck,
		"relics": GameManager.relics,
	}
	_write_json(SAVE_PATH, data)


func load_run() -> bool:
	var data := _read_json(SAVE_PATH)
	if data.is_empty():
		return false
	GameManager.current_character = data.get("character", "")
	GameManager.current_act = data.get("act", 1)
	GameManager.player_hp = data.get("hp", 80)
	GameManager.player_max_hp = data.get("max_hp", 80)
	GameManager.player_gold = data.get("gold", 99)
	GameManager.deck = data.get("deck", [])
	GameManager.relics = data.get("relics", [])
	return true


func delete_run_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func has_run_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_meta(meta: Dictionary) -> void:
	_write_json(META_PATH, meta)


func load_meta() -> Dictionary:
	return _read_json(META_PATH)


func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return {}
	if json.data is Dictionary:
		return json.data
	return {}
