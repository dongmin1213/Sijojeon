extends Node

## 게임 전체 상태를 관리하는 오토로드 싱글톤.
## 상태 머신: TITLE → CHARACTER_SELECT → MAP ↔ BATTLE/EVENT/SHOP/REST → REWARD → MAP

enum GameState {
	TITLE,
	CHARACTER_SELECT,
	CHRONICLE,
	SETTINGS,
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
		GameState.SETTINGS:
			return "res://scenes/settings/settings.tscn"
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
	if run_data.deck.is_empty():
		push_error("GameManager: 스타터 덱이 비어있음 — character_id=%s" % character_id)

	# 시작 유물
	if skills_data and skills_data.has("starting_relic"):
		run_data.relics.append(skills_data["starting_relic"])

	# 맵 생성
	var generator := MapGenerator.new()
	run_data.run_map = generator.generate(run_data.map_seed, run_data.current_act)

	change_state(GameState.MAP)


func start_daily_challenge(character_id: String) -> void:
	## 일일 도전 모드 시작. 날짜 기반 시드로 동일한 맵/적 생성.
	var today := Time.get_date_string_from_system()
	var daily_seed := today.hash()

	run_data = RunData.new()
	run_data.character_id = character_id
	run_data.map_seed = daily_seed
	run_data.is_daily_challenge = true
	run_data.daily_date = today
	run_data.daily_score = 0
	RelicManager.reset_run_state()

	var skills_data := DataLoader.get_character_skills(character_id)
	if skills_data:
		# 일일 도전: HP -10% 제약
		var base_hp: int = skills_data.get("base_hp", 70)
		run_data.max_hp = int(base_hp * 0.9)
		run_data.current_hp = run_data.max_hp
		run_data.qi_per_turn = skills_data.get("base_qi", 3)

	run_data.deck = DataLoader.get_starter_deck(character_id)

	if skills_data and skills_data.has("starting_relic"):
		run_data.relics.append(skills_data["starting_relic"])

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
		# 일일 도전 점수 저장
		if run_data.is_daily_challenge:
			var score := _calculate_daily_score(victory)
			run_data.daily_score = score
			SaveManager.save_daily_result(run_data.daily_date, run_data.character_id, score, victory)

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


func _calculate_daily_score(victory: bool) -> int:
	## 일일 도전 점수 계산: 잔여 HP + 막 진행 + 승리 보너스
	if not run_data:
		return 0
	var score := 0
	score += run_data.current_hp * 2  # 잔여 HP당 2점
	score += (run_data.current_act - 1) * 100  # 막당 100점
	score += run_data.current_floor * 10  # 층당 10점
	if victory:
		score += 500  # 승리 보너스
	return score


func has_daily_challenge_today() -> bool:
	## 오늘 일일 도전을 이미 완료했는지 확인
	var today := Time.get_date_string_from_system()
	return SaveManager.has_daily_result(today)
