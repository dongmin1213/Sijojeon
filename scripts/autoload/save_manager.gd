extends Node

## 세이브/로드 관리 오토로드.

const SAVE_PATH := "user://save_data.json"
const META_PATH := "user://meta_data.json"


func save_run(data: Dictionary) -> void:
	_write_json(SAVE_PATH, data)


func load_run() -> Dictionary:
	return _read_json(SAVE_PATH)


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
