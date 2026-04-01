extends Node

## 세이브/로드 관리 오토로드.
## 런 데이터 저장, 메타 통계, 오토세이브를 담당한다.

const SAVE_PATH := "user://save_data.json"
const META_PATH := "user://meta_data.json"
const SETTINGS_PATH := "user://settings.json"

signal save_completed(success: bool)


# --- 런 세이브/로드 ---

func save_run(data: Dictionary) -> bool:
	var ok := _write_json(SAVE_PATH, data)
	save_completed.emit(ok)
	return ok


func load_run() -> Dictionary:
	return _read_json(SAVE_PATH)


func delete_run_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func has_run_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# --- 메타 데이터 (런 통계) ---

func save_meta(meta: Dictionary) -> bool:
	return _write_json(META_PATH, meta)


func load_meta() -> Dictionary:
	return _read_json(META_PATH)


## 런 통계를 업데이트한다.
## victory: 클리어 여부, character_id: 사용한 캐릭터, act_reached: 도달한 막
func record_run_result(victory: bool, character_id: String, act_reached: int) -> void:
	var meta := load_meta()

	# 기본 통계 구조 초기화
	if not meta.has("stats"):
		meta["stats"] = {
			"total_runs": 0,
			"victories": 0,
			"deaths": 0,
			"best_act": 0,
		}

	# 캐릭터별 통계 초기화
	if not meta.has("character_stats"):
		meta["character_stats"] = {}
	if not meta["character_stats"].has(character_id):
		meta["character_stats"][character_id] = {
			"runs": 0,
			"victories": 0,
		}

	# 통계 갱신
	meta["stats"]["total_runs"] += 1
	if victory:
		meta["stats"]["victories"] += 1
	else:
		meta["stats"]["deaths"] += 1
	if act_reached > meta["stats"]["best_act"]:
		meta["stats"]["best_act"] = act_reached

	meta["character_stats"][character_id]["runs"] += 1
	if victory:
		meta["character_stats"][character_id]["victories"] += 1

	save_meta(meta)


# --- 설정 저장/로드 ---

const DEFAULT_SETTINGS := {
	"bgm_volume": 0.8,
	"sfx_volume": 0.8,
	"vibration": true,
}


func save_settings(settings: Dictionary) -> bool:
	return _write_json(SETTINGS_PATH, settings)


func load_settings() -> Dictionary:
	var data := _read_json(SETTINGS_PATH)
	# 기본값 병합
	for key in DEFAULT_SETTINGS:
		if not data.has(key):
			data[key] = DEFAULT_SETTINGS[key]
	return data


# --- 내부 유틸 ---

func _write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: 파일 쓰기 실패 — %s (에러: %s)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: 파일 읽기 실패 — %s (에러: %s)" % [path, FileAccess.get_open_error()])
		return {}
	var text := file.get_as_text()
	file.close()
	if text.is_empty():
		return {}
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("SaveManager: JSON 파싱 실패 — %s (줄 %d: %s)" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	if json.data is Dictionary:
		return json.data
	return {}
