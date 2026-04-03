extends Node

## 업적 시스템 관리 오토로드.
## 업적 정의를 로드하고, 메타 데이터 기준으로 달성 여부를 판정한다.

const ACHIEVEMENTS_PATH := "res://data/achievements/achievements.json"

## 새로 달성된 업적이 있을 때 발생. UI 알림에 사용.
signal achievement_unlocked(achievement: Dictionary)

var _achievements: Array[Dictionary] = []


func _ready() -> void:
	_load_achievements()


func _load_achievements() -> void:
	var file := FileAccess.open(ACHIEVEMENTS_PATH, FileAccess.READ)
	if file == null:
		push_error("AchievementManager: 업적 파일 로드 실패 — %s" % ACHIEVEMENTS_PATH)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or not (json.data is Dictionary):
		push_error("AchievementManager: 업적 JSON 파싱 실패")
		return
	_achievements.clear()
	for entry in json.data.get("achievements", []):
		_achievements.append(entry)


## 모든 업적 정의를 반환한다.
func get_all_achievements() -> Array[Dictionary]:
	return _achievements


## 업적 달성 여부를 판정한다.
func is_achievement_unlocked(achievement_id: String) -> bool:
	var meta := SaveManager.load_meta()
	for ach in _achievements:
		if ach.get("id", "") == achievement_id:
			return _check_condition(ach, meta)
	return false


## 현재 달성된 모든 업적 ID 목록을 반환한다.
## meta를 전달하면 디스크 I/O를 생략한다.
func get_unlocked_ids(meta: Dictionary = {}) -> Array[String]:
	if meta.is_empty():
		meta = SaveManager.load_meta()
	var result: Array[String] = []
	for ach in _achievements:
		if _check_condition(ach, meta):
			result.append(ach["id"])
	return result


## 달성 진행도를 반환한다. { "current": int, "target": int }
func get_progress(achievement_id: String) -> Dictionary:
	var meta := SaveManager.load_meta()
	for ach in _achievements:
		if ach.get("id", "") == achievement_id:
			return _get_progress_data(ach, meta)
	return { "current": 0, "target": 1 }


## 모든 업적의 진행도를 한 번에 반환한다. meta를 한 번만 로드하여 성능 최적화.
## 반환: { achievement_id: { "current": int, "target": int } }
## meta를 전달하면 디스크 I/O를 생략한다.
func get_all_progress(meta: Dictionary = {}) -> Dictionary:
	if meta.is_empty():
		meta = SaveManager.load_meta()
	var result := {}
	for ach in _achievements:
		var ach_id: String = ach.get("id", "")
		result[ach_id] = _get_progress_data(ach, meta)
	return result


## 런 종료 후 호출. 새로 달성된 업적을 감지하여 시그널을 발생시킨다.
func check_new_achievements() -> Array[Dictionary]:
	var meta := SaveManager.load_meta()
	var previously_unlocked: Array = meta.get("unlocked_achievements", [])
	var newly_unlocked: Array[Dictionary] = []

	for ach in _achievements:
		var ach_id: String = ach.get("id", "")
		if ach_id in previously_unlocked:
			continue
		if _check_condition(ach, meta):
			newly_unlocked.append(ach)
			previously_unlocked.append(ach_id)

	# 새로 달성된 업적이 있으면 메타에 저장
	if newly_unlocked.size() > 0:
		meta["unlocked_achievements"] = previously_unlocked
		SaveManager.save_meta(meta)
		for ach in newly_unlocked:
			achievement_unlocked.emit(ach)

	return newly_unlocked


## 업적 달성 조건 판정 내부 로직.
func _check_condition(ach: Dictionary, meta: Dictionary) -> bool:
	var ach_type: String = ach.get("type", "")
	var params: Dictionary = ach.get("params", {})
	var stats: Dictionary = meta.get("stats", {})
	var char_stats: Dictionary = meta.get("character_stats", {})

	match ach_type:
		"total_runs":
			return stats.get("total_runs", 0) >= params.get("min_runs", 1)
		"total_victories":
			return stats.get("victories", 0) >= params.get("min_victories", 1)
		"best_act":
			return stats.get("best_act", 0) >= params.get("min_act", 1)
		"character_victory":
			var cid: String = params.get("character_id", "")
			return char_stats.get(cid, {}).get("victories", 0) > 0
		"all_characters_victory":
			var ids: Array = params.get("character_ids", [])
			for cid in ids:
				if char_stats.get(cid, {}).get("victories", 0) <= 0:
					return false
			return ids.size() > 0
	return false


## 업적 진행도 데이터 반환.
func _get_progress_data(ach: Dictionary, meta: Dictionary) -> Dictionary:
	var ach_type: String = ach.get("type", "")
	var params: Dictionary = ach.get("params", {})
	var stats: Dictionary = meta.get("stats", {})
	var char_stats: Dictionary = meta.get("character_stats", {})

	match ach_type:
		"total_runs":
			var target: int = params.get("min_runs", 1)
			return { "current": mini(stats.get("total_runs", 0), target), "target": target }
		"total_victories":
			var target: int = params.get("min_victories", 1)
			return { "current": mini(stats.get("victories", 0), target), "target": target }
		"best_act":
			var target: int = params.get("min_act", 1)
			return { "current": mini(stats.get("best_act", 0), target), "target": target }
		"character_victory":
			var cid: String = params.get("character_id", "")
			var wins: int = char_stats.get(cid, {}).get("victories", 0)
			return { "current": mini(wins, 1), "target": 1 }
		"all_characters_victory":
			var ids: Array = params.get("character_ids", [])
			var count := 0
			for cid in ids:
				if char_stats.get(cid, {}).get("victories", 0) > 0:
					count += 1
			return { "current": count, "target": ids.size() }

	return { "current": 0, "target": 1 }
