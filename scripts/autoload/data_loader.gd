extends Node

## JSON 데이터 파일을 로드하여 게임 데이터로 변환하는 오토로드.

# CardData 리소스 (id → CardData)
var _cards: Dictionary = {}
# 적 데이터 (id → Dictionary)
var _enemies: Dictionary = {}
# 유물 데이터 (id → Dictionary)
var _relics: Dictionary = {}
# 희귀도별 드롭 가중치
var _relic_rarity_table: Dictionary = {}
# 캐릭터 스탯 데이터
var _character_stats: Dictionary = {}
# 카드 풀별 아키타입 데이터 (class → Array[Dictionary])
var _archetypes: Dictionary = {}
# 어센션 시스템 데이터
var _ascension_data: Dictionary = {}

# 스타터 덱 구성 (character_id → Array[card_id])
const STARTER_DECKS := {
	"dosa": [
		"M003", "M003",  # 후퇴 ×2
		"M005",          # 포복 ×1
		"D001", "D001",  # 기공 ×2
		"D002", "D002",  # 결인 ×2
		"D003",          # 진언 ×1
		"D007", "D007",  # 수결 ×2
	],
	"mugwan": [
		"M003", "M003",  # 후퇴 ×2
		"M005",          # 포복 ×1
		"G001", "G001",  # 전투 전환 ×2
		"G002", "G002",  # 돌격 ×2
		"G003",          # 포위 ×1
		"M002", "M002",  # 도약 ×2
	],
	"mungwan": [
		"M003", "M003",  # 후퇴 ×2
		"M005",          # 포복 ×1
		"W001", "W001",  # 직언 ×2
		"W004",          # 경연 ×1
		"W006",          # 독서 ×1
		"W005",          # 예제 ×1
		"W007", "W007",  # 격물치지 ×2
	],
	"uiwon": [
		"M003", "M003",  # 후퇴 ×2
		"M005",          # 포복 ×1
		"H001", "H001",  # 침술 ×2 — 기본 공격
		"H002", "H002",  # 채집 ×2 — 자원 획득
		"H003",          # 경옥고 ×1 — 회복
		"H004", "H004",  # 독침 ×2 — 독 부여
	],
	"gungsu": [
		"M003", "M003",    # 후퇴 ×2
		"M005",            # 포복 ×1
		"GI001", "GI001",  # 추파 ×2 — 기본 공격
		"GI002", "GI002",  # 향낭 ×2 — 0코스트 버프
		"GI004",           # 춤사위 ×1 — 방어+연타
		"GI006", "GI006",  # 검무 ×2 — 공격
	],
	"sangin": [
		"M003", "M003",  # 후퇴 ×2
		"M005",          # 포복 ×1
		"S001", "S001",  # 석장 타격 ×2 — 기본 공격
		"S002", "S002",  # 참선 ×2 — 방어
		"S003",          # 금강역사 ×1 — 반격
		"S004", "S004",  # 염불 ×2 — 회복
	],
}


func _ready() -> void:
	_load_all_cards()
	_load_all_enemies()
	_load_relics()
	_load_skills()
	_load_ascension()


func _load_all_cards() -> void:
	# Android APK에서는 DirAccess.open("res://")이 null을 반환하므로
	# 카드 파일 경로를 명시적으로 지정
	var card_files := [
		"res://data/cards/common.json",
		"res://data/cards/dosa.json",
		"res://data/cards/mugwan.json",
		"res://data/cards/mungwan.json",
		"res://data/cards/uinyeo.json",
		"res://data/cards/gisaeng.json",
		"res://data/cards/seungbyeong.json",
	]
	for path in card_files:
		_load_card_file(path)
	if _cards.is_empty():
		push_error("DataLoader: 카드 데이터 로드 실패 — _cards 비어있음")


func _load_card_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("DataLoader: 카드 파일 열기 실패 — %s" % path)
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

	# 아키타입 데이터 저장
	var archetypes = data.get("archetypes", [])
	if archetypes is Array and not archetypes.is_empty():
		_archetypes[pool] = archetypes

	var cards_array = data.get("cards", [])
	if not cards_array is Array:
		return

	for card_dict in cards_array:
		if card_dict is Dictionary and card_dict.has("id"):
			var card := CardData.from_dict(card_dict, pool)
			_cards[card.id] = card


func _load_all_enemies() -> void:
	# Android APK에서는 DirAccess.open("res://")이 null을 반환하므로
	# 적 파일 경로를 명시적으로 지정
	var enemy_files := [
		"res://data/enemies/act1.json",
		"res://data/enemies/act1_boss.json",
		"res://data/enemies/act1_boss_alt.json",
		"res://data/enemies/act1_boss_mid.json",
		"res://data/enemies/act1_boss_tamhak.json",
		"res://data/enemies/act2.json",
		"res://data/enemies/act2_boss.json",
		"res://data/enemies/act2_boss_alt.json",
		"res://data/enemies/act2_boss_mid.json",
		"res://data/enemies/act2_boss_mid_gungan.json",
		"res://data/enemies/act2_boss_tamgwan.json",
		"res://data/enemies/act2_minions.json",
		"res://data/enemies/act3.json",
		"res://data/enemies/act3_boss.json",
		"res://data/enemies/act3_boss_mid.json",
		"res://data/enemies/special_elites.json",
	]
	for path in enemy_files:
		_load_enemy_file(path)
	if _enemies.is_empty():
		push_error("DataLoader: 적 데이터 로드 실패 — _enemies 비어있음")


func _load_enemy_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("DataLoader: 적 파일 열기 실패 — %s" % path)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return

	var data = json.data
	if data is Dictionary:
		# 보스 파일: 루트 딕셔너리에 id가 직접 있는 경우
		if data.has("id"):
			_enemies[data["id"]] = data
		else:
			# 일반 적 파일: 중첩 구조 (regular_enemies, elite_enemies, bosses)
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


func _load_relics() -> void:
	var path := "res://data/relics/relics.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or not (json.data is Dictionary):
		push_warning("DataLoader: 유물 JSON 파싱 실패 — %s" % path)
		return

	var data: Dictionary = json.data
	# 희귀도 테이블 저장
	_relic_rarity_table = data.get("rarity_table", {})

	var relics_array: Array = data.get("relics", [])
	for relic_dict in relics_array:
		if relic_dict is Dictionary and relic_dict.has("id"):
			_relics[relic_dict["id"]] = relic_dict


func _load_skills() -> void:
	var path := "res://data/characters/stats.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("DataLoader: 캐릭터 스탯 파일 열기 실패 — %s" % path)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("DataLoader: 캐릭터 스탯 JSON 파싱 실패 — %s" % path)
		return
	if json.data is Dictionary:
		_character_stats = json.data.get("characters", {})


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


## 캐릭터 카드 풀의 아키타입 배열을 반환한다.
func get_archetypes(character_id: String) -> Array:
	return _archetypes.get(character_id, [])


func get_starter_deck(character_id: String) -> Array[String]:
	if STARTER_DECKS.has(character_id):
		# const Dictionary에서 꺼낸 Array는 untyped Variant이므로
		# 명시적으로 typed Array[String]을 구성해야 Godot 4 변환 이슈 방지
		var result: Array[String] = []
		for card_id in STARTER_DECKS[character_id]:
			result.append(card_id)
		return result
	push_error("DataLoader.get_starter_deck: 알 수 없는 character_id='%s'" % character_id)
	return []


func get_enemy(enemy_id: String) -> Dictionary:
	return _enemies.get(enemy_id, {})


## 해당 act의 일반 적 ID 목록을 반환한다.
func get_regular_enemy_ids_for_act(act: int) -> Array[String]:
	var prefix: String
	match act:
		1: prefix = "E0"
		2: prefix = "E2"
		3: prefix = "E3"
		_: prefix = "E0"
	var result: Array[String] = []
	for id in _enemies:
		if id.begins_with(prefix) and not id.begins_with("EL"):
			result.append(id)
	return result


## 해당 act의 엘리트 적 ID 목록을 반환한다.
func get_elite_enemy_ids_for_act(act: int) -> Array[String]:
	var prefix: String
	match act:
		1: prefix = "EL0"
		2: prefix = "EL2"
		3: prefix = "EL3"
		_: prefix = "EL0"
	var result: Array[String] = []
	for id in _enemies:
		if id.begins_with(prefix):
			result.append(id)
	return result


func get_relic(relic_id: String) -> Dictionary:
	return _relics.get(relic_id, {})


func get_all_relics() -> Dictionary:
	return _relics


func get_relics_by_rarity(rarity: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for relic in _relics.values():
		if relic.get("rarity", 0) == rarity:
			result.append(relic)
	return result


func get_available_relics(owned_ids: Array[String], character_id: String) -> Array[Dictionary]:
	## 소유하지 않은 유물 중 획득 가능한 것만 반환 (직업 제한 확인)
	var result: Array[Dictionary] = []
	for relic in _relics.values():
		var relic_id: String = relic.get("id", "")
		if relic_id in owned_ids:
			continue
		var restriction = relic.get("class_restriction", null)
		if restriction != null and restriction is String:
			# 직업 제한이 있는데 현재 캐릭터와 불일치
			if not _matches_class(restriction, character_id):
				continue
		result.append(relic)
	return result


func _matches_class(restriction: String, character_id: String) -> bool:
	## 직업 제한 문자열(한글)과 캐릭터 ID 매칭
	var class_map := {
		"무당": "dosa",
		"의적": "mugwan",
		"선비": "mungwan",
		"의녀": "uiwon",
		"기생": "gungsu",
		"승병": "sangin",
	}
	return class_map.get(restriction, "") == character_id


func get_relic_rarity_table() -> Dictionary:
	return _relic_rarity_table


func get_ascension_data() -> Dictionary:
	return _ascension_data


func get_ascension_level(level: int) -> Dictionary:
	var levels: Array = _ascension_data.get("levels", [])
	for l in levels:
		if l is Dictionary and l.get("level", -1) == level:
			return l
	return {}


func _load_ascension() -> void:
	var path := "res://data/unlock/ascension.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err == OK and json.data is Dictionary:
		_ascension_data = json.data
		# 저주 카드를 카드 풀에 등록
		var curse: Dictionary = _ascension_data.get("curse_card", {})
		if curse.has("id"):
			var card := CardData.from_dict(curse, "curse")
			_cards[card.id] = card
		# 미니 적(영혼 잔해)를 적 풀에 등록
		var mini_enemy: Dictionary = _ascension_data.get("mini_enemy", {})
		if mini_enemy.has("id"):
			_enemies[mini_enemy["id"]] = mini_enemy


func get_character_skills(character_id: String) -> Dictionary:
	var stats: Dictionary = _character_stats.get(character_id, {})
	if stats.is_empty():
		return {}
	return {
		"base_hp": stats.get("hp", 70),
		"base_qi": stats.get("qi_per_turn", 3),
	}
