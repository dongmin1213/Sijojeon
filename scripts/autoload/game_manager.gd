extends Node

## 게임 전체 상태를 관리하는 오토로드 싱글톤.
## 상태 머신: TITLE → CHARACTER_SELECT → MAP ↔ BATTLE/EVENT/SHOP/REST → REWARD → MAP

enum GameState {
	TITLE,
	CHARACTER_SELECT,
	CHRONICLE,
	MAP,
	BATTLE,
	EVENT,
	SHOP,
	REST,
	REWARD,
	ACT_TRANSITION,
	RUN_OVER,
	RUN_WIN,
}

const MAX_ACT := 3

var current_state: GameState = GameState.TITLE
var run_data: RunData = null

signal state_changed(new_state: GameState)


## 상태별 씬 경로를 반환한다. 매핑이 없으면 빈 문자열.
func _get_scene_path(state: GameState) -> String:
	match state:
		GameState.TITLE:
			return "res://scenes/title/title_screen.tscn"
		GameState.CHARACTER_SELECT:
			return "res://scenes/character_select/character_select.tscn"
		GameState.CHRONICLE:
			return "res://scenes/chronicle/chronicle.tscn"
		GameState.MAP:
			return "res://scenes/map/run_map.tscn"
		GameState.BATTLE:
			return "res://scenes/battle/battle.tscn"
		GameState.EVENT:
			return "res://scenes/event/event.tscn"
		GameState.SHOP:
			return "res://scenes/shop/shop.tscn"
		GameState.REST:
			return "res://scenes/rest/rest.tscn"
		GameState.REWARD:
			return "res://scenes/reward/reward.tscn"
		GameState.ACT_TRANSITION:
			return "res://scenes/act_transition/act_transition.tscn"
		GameState.RUN_OVER, GameState.RUN_WIN:
			return "res://scenes/run_result/run_result.tscn"
	return ""


func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)

	# 씬 전환 (매핑된 씬이 있을 때만)
	var scene_path := _get_scene_path(new_state)
	if scene_path != "":
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)
		else:
			push_warning("GameManager: 씬 파일 없음 — %s (상태: %s)" % [scene_path, GameState.keys()[new_state]])


func start_new_run(character_id: String) -> void:
	run_data = RunData.new()
	run_data.character_id = character_id
	run_data.map_seed = randi()
	RelicManager.reset_run_state()

	# DataLoader에서 캐릭터 데이터로 HP 설정
	var skills_data := DataLoader.get_character_skills(character_id)
	if skills_data:
		run_data.max_hp = skills_data.get("base_hp", 70)
		run_data.current_hp = run_data.max_hp
		run_data.qi_per_turn = skills_data.get("base_qi", 3)

	# 기본 덱 로드
	run_data.deck = DataLoader.get_starter_deck(character_id)

	# 시작 유물
	if skills_data and skills_data.has("starting_relic"):
		run_data.relics.append(skills_data["starting_relic"])

	# 맵 생성
	var generator := MapGenerator.new()
	run_data.run_map = generator.generate(run_data.map_seed, run_data.current_act)

	change_state(GameState.MAP)


func load_saved_run() -> bool:
	var save_dict: Dictionary = SaveManager.load_run()
	if save_dict.is_empty():
		return false
	run_data = RunData.from_dict(save_dict)
	change_state(GameState.MAP)
	return true


func end_run(victory: bool) -> void:
	# 런 통계 기록
	if run_data:
		SaveManager.record_run_result(victory, run_data.character_id, run_data.current_act)

	# 새 업적 달성 여부 확인
	AchievementManager.check_new_achievements()

	if victory:
		change_state(GameState.RUN_WIN)
	else:
		change_state(GameState.RUN_OVER)
	# 런 세이브 삭제 (런 종료 시)
	SaveManager.delete_run_save()


func save_current_run() -> void:
	if run_data:
		SaveManager.save_run(run_data.to_dict())


func reset_to_title() -> void:
	run_data = null
	change_state(GameState.TITLE)


func advance_floor() -> void:
	if run_data:
		run_data.current_floor += 1


func advance_act() -> void:
	if run_data:
		# 현재 막 맵을 이전 맵 목록에 보존
		if run_data.run_map:
			run_data.previous_maps.append({
				"act": run_data.current_act,
				"map": run_data.run_map.to_dict(),
				"visited_nodes": Array(run_data.visited_nodes),
			})
		run_data.current_act += 1
		run_data.current_floor = 0
		run_data.visited_nodes.clear()
		var generator := MapGenerator.new()
		run_data.run_map = generator.generate(
			run_data.map_seed + run_data.current_act, run_data.current_act
		)
