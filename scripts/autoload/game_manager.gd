extends Node

## 게임 전체 상태를 관리하는 오토로드 싱글톤.
## 상태 머신: TITLE → CHARACTER_SELECT → MAP ↔ BATTLE/EVENT/SHOP/REST → REWARD → MAP

enum GameState {
	TITLE,
	CHARACTER_SELECT,
	CHRONICLE,
	SETTINGS,
	TUTORIAL,
	MAP,
	BATTLE,
	EVENT,
	SHOP,
	REST,
	REWARD,
	ACT_TRANSITION,
	RUN_OVER,
	RUN_WIN,
	GWAGEO,
}

const MAX_ACT := 3

var current_state: GameState = GameState.TITLE
var run_data: RunData = null
var _transitioning: bool = false  # 씬 전환 중복 호출 방지

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
		GameState.TUTORIAL:
			return "res://scenes/tutorial/tutorial_battle.tscn"
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
		GameState.GWAGEO:
			return "res://scenes/gwageo/gwageo_minigame.tscn"
	return ""


func change_state(new_state: GameState) -> void:
	# 씬 전환 중복 호출 방지 (빠른 연속 터치 대응)
	if _transitioning:
		return
	current_state = new_state
	state_changed.emit(new_state)

	# 씬 전환 (매핑된 씬이 있을 때만)
	var scene_path := _get_scene_path(new_state)
	if scene_path != "":
		if ResourceLoader.exists(scene_path):
			_transitioning = true
			# 구 씬 전체 프로세싱 즉시 중지 — 씬 전환 중 !is_inside_tree() 에러 방지
			var old_scene := get_tree().current_scene
			if old_scene:
				old_scene.process_mode = Node.PROCESS_MODE_DISABLED
			get_tree().change_scene_to_file(scene_path)
			# 다음 프레임에 전환 잠금 해제 및 safe area 적용 (새 씬 _ready() 이후)
			get_tree().process_frame.connect(func():
				_transitioning = false
				SafeAreaManager.apply_to_current_scene()
			, CONNECT_ONE_SHOT)
		else:
			push_warning("GameManager: 씬 파일 없음 — %s (상태: %s)" % [scene_path, GameState.keys()[new_state]])


func start_new_run(character_id: String, ascension_level: int = 0) -> void:
	if character_id.is_empty():
		push_error("GameManager.start_new_run: character_id가 비어있음")
		return

	run_data = RunData.new()
	run_data.character_id = character_id
	run_data.map_seed = randi()
	run_data.ascension_level = ascension_level
	RelicManager.reset_run_state()

	# DataLoader에서 캐릭터 데이터로 HP 설정
	var skills_data := DataLoader.get_character_skills(character_id)
	if not skills_data:
		push_warning("GameManager.start_new_run: 캐릭터 스킬 데이터 없음 — character_id=%s, 기본값 사용" % character_id)
	if skills_data:
		run_data.max_hp = skills_data.get("base_hp", 70)
		run_data.current_hp = run_data.max_hp
		run_data.qi_per_turn = skills_data.get("base_qi", 3)

	# 기본 덱 로드
	run_data.deck = DataLoader.get_starter_deck(character_id)
	if run_data.deck.is_empty():
		push_error("GameManager: 스타터 덱이 비어있음 — character_id=%s, 기본 덱 사용" % character_id)
		run_data.deck = ["C001", "C001", "C001", "C001", "C002", "C002", "C002", "C003", "C003", "C004"]

	# 시작 유물
	if skills_data and skills_data.has("starting_relic"):
		run_data.relics.append(skills_data["starting_relic"])

	# 민심 게이지 초기화 (기본값 50: 중립)
	if not run_data.narrative_state.has("minshim"):
		run_data.narrative_state["minshim"] = 50

	# 신분 트랙 초기화
	run_data.jibun_score = 0
	run_data.jibun_rank = 1

	# 당파 시스템 초기화 — 런마다 무작위 대립 쌍 선택
	var faction_pairs := [
		["noron", "soron"],    # 노론 vs 소론
		["namin", "seoin"],    # 남인 vs 서인
		["dongin", "bugin"],   # 동인 vs 북인
	]
	var pair: Array = faction_pairs[randi() % faction_pairs.size()]
	run_data.faction_pair = Array(pair, TYPE_STRING, "", null)
	run_data.faction_meters = {pair[0]: 0, pair[1]: 0}

	# 어센션 수정자 적용
	if ascension_level > 0:
		_apply_ascension_modifiers(ascension_level)

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
	if run_data == null:
		push_warning("GameManager.end_run: run_data가 null — 런이 시작되지 않았거나 이미 종료됨")
	# 런 통계 기록
	if run_data:
		SaveManager.record_run_result(victory, run_data.character_id, run_data.current_act)
		# 어센션 클리어 시 다음 레벨 해금
		if victory and run_data.ascension_level >= 0:
			SaveManager.save_ascension_progress(run_data.character_id, run_data.ascension_level)
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


func _apply_ascension_modifiers(level: int) -> void:
	## 어센션 수정자를 run_data에 적용한다.
	var asc_data := DataLoader.get_ascension_level(level)
	if asc_data.is_empty():
		return

	var modifiers: Array = asc_data.get("modifiers", [])
	run_data.ascension_modifiers = modifiers

	for mod in modifiers:
		if mod is not Dictionary:
			continue
		var mod_type: String = mod.get("type", "")

		match mod_type:
			"starter_deck":
				# 저주 카드 추가
				var card_id: String = mod.get("card_id", "")
				var count: int = mod.get("count", 1)
				for _i in count:
					run_data.deck.append(card_id)
			"player_stat":
				# 플레이어 스탯 수정 (기 감소 등)
				var stat: String = mod.get("stat", "")
				var value = mod.get("value", 0)
				match stat:
					"starting_qi":
						run_data.qi_per_turn = maxi(run_data.qi_per_turn + int(value), 1)


func get_ascension_enemy_hp_multiplier() -> float:
	## 현재 어센션의 적 HP 배율을 계산한다.
	if run_data == null:
		return 1.0
	var multiplier := 1.0
	for mod in run_data.ascension_modifiers:
		if mod is not Dictionary:
			continue
		if mod.get("type", "") == "enemy_stat" and mod.get("stat", "") == "hp":
			if mod.get("target", "") == "all_enemies":
				multiplier *= mod.get("value", 1.0)
	return multiplier


func get_ascension_boss_hp_multiplier() -> float:
	## 보스 전용 추가 HP 배율 (10단계)
	if run_data == null:
		return 1.0
	var multiplier := get_ascension_enemy_hp_multiplier()
	for mod in run_data.ascension_modifiers:
		if mod is not Dictionary:
			continue
		if mod.get("type", "") == "enemy_stat" and mod.get("target", "") == "boss_only":
			multiplier *= mod.get("value", 1.0)
	return multiplier


func get_ascension_shop_price_multiplier() -> float:
	## 상점 가격 배율
	if run_data == null:
		return 1.0
	var multiplier := 1.0
	for mod in run_data.ascension_modifiers:
		if mod is not Dictionary:
			continue
		if mod.get("type", "") == "shop_price" and mod.get("target", "") == "all":
			if mod.get("operation", "") == "multiply":
				multiplier *= mod.get("value", 1.0)
	return multiplier


func get_ascension_card_removal_extra_cost() -> int:
	## 카드 제거 추가 비용
	if run_data == null:
		return 0
	var extra := 0
	for mod in run_data.ascension_modifiers:
		if mod is not Dictionary:
			continue
		if mod.get("type", "") == "shop_price" and mod.get("target", "") == "card_removal":
			if mod.get("operation", "") == "add":
				extra += int(mod.get("value", 0))
	return extra


func has_ascension_modifier(mod_id: String) -> bool:
	## 특정 수정자가 활성화되어 있는지 확인
	if run_data == null:
		return false
	for mod in run_data.ascension_modifiers:
		if mod is Dictionary and mod.get("id", "") == mod_id:
			return true
	return false


func has_daily_challenge_today() -> bool:
	## 오늘 일일 도전을 이미 완료했는지 확인
	var today := Time.get_date_string_from_system()
	return SaveManager.has_daily_result(today)


func is_tutorial_completed() -> bool:
	## 튜토리얼 완료 여부를 확인한다.
	var meta := SaveManager.load_meta()
	return meta.get("tutorial_completed", false)


func start_tutorial() -> void:
	## 튜토리얼 전투를 시작한다.
	change_state(GameState.TUTORIAL)


