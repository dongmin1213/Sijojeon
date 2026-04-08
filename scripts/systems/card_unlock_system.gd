class_name CardUnlockSystem
extends RefCounted

## 카드 해금 시스템 (Phase 2-4).
## 메타 진행도(meta_data.json)에 해금된 카드 ID를 저장.
## 직업별 27장 중 기본 20장은 즉시 사용 가능, 7장은 업적/조건으로 해금.
## 해금 시 팝업 알림 + 다음 런부터 보상 풀에 등장.

## 해금 조건 타입
## "default" — 기본 해금 (처음부터 보상에 등장)
## "class_clear" — 해당 직업으로 런 클리어
## "class_runs_3" — 해당 직업으로 3회 런
## "sijo_total_10" — 런 통틀어 시조 10회 완성 (메타 누적)
## "sijo_total_30" — 시조 30회 완성
## "ascension_3" — 어센션 3단계 클리어
## "ascension_5" — 어센션 5단계 클리어
## "boss_no_hit" — 보스에게 피해 0으로 클리어 (미구현, 플레이스홀더)

## 해금 조건 정의 — 각 직업 마지막 7장 카드
## 카드 풀 인덱스 20~26 (0-indexed)이 해금 카드
const UNLOCK_CARDS_PER_CLASS := {
	"mugwan": {
		20: "class_runs_3",
		21: "class_runs_3",
		22: "class_clear",
		23: "class_clear",
		24: "sijo_total_10",
		25: "ascension_3",
		26: "ascension_5",
	},
	"mungwan": {
		20: "class_runs_3",
		21: "class_runs_3",
		22: "class_clear",
		23: "class_clear",
		24: "sijo_total_10",
		25: "ascension_3",
		26: "ascension_5",
	},
	"dosa": {
		20: "class_runs_3",
		21: "class_runs_3",
		22: "class_clear",
		23: "class_clear",
		24: "sijo_total_10",
		25: "ascension_3",
		26: "ascension_5",
	},
}

## 공용 카드 해금 (54장 중 마지막 8장)
const UNLOCK_CARDS_COMMON := {
	46: "sijo_total_10",
	47: "sijo_total_10",
	48: "sijo_total_30",
	49: "sijo_total_30",
	50: "class_clear",
	51: "class_clear",
	52: "ascension_3",
	53: "ascension_5",
}


## 메타에서 해금된 카드 ID 목록 로드
static func get_unlocked_cards() -> Array[String]:
	var meta: Dictionary = SaveManager.load_meta()
	var unlocked: Array = meta.get("unlocked_cards", [])
	var result: Array[String] = []
	for id in unlocked:
		result.append(str(id))
	return result


## 카드가 해금되었는지 확인
static func is_card_unlocked(card_id: String) -> bool:
	# 해금 조건이 정의되지 않은 카드 = 기본 해금
	if not _is_lockable_card(card_id):
		return true
	var unlocked := get_unlocked_cards()
	return unlocked.has(card_id)


## 보상 풀에서 사용 가능한 카드만 필터
static func filter_reward_pool(card_ids: Array) -> Array:
	var result: Array = []
	for id in card_ids:
		if is_card_unlocked(str(id)):
			result.append(id)
	return result


## 카드 해금 — 메타에 저장 + 새로 해금된 카드 ID 배열 반환
static func unlock_card(card_id: String) -> bool:
	if not _is_lockable_card(card_id):
		return false
	var meta: Dictionary = SaveManager.load_meta()
	if not meta.has("unlocked_cards"):
		meta["unlocked_cards"] = []
	if meta["unlocked_cards"].has(card_id):
		return false
	meta["unlocked_cards"].append(card_id)
	SaveManager.save_meta(meta)
	return true


## 런 결과에 따라 해금 조건을 체크하고, 새로 해금된 카드 반환
static func check_and_unlock(victory: bool, character_id: String) -> Array[String]:
	var newly_unlocked: Array[String] = []
	var meta: Dictionary = SaveManager.load_meta()

	# 캐릭터 통계 읽기
	var char_stats: Dictionary = meta.get("character_stats", {}).get(character_id, {})
	var char_runs: int = char_stats.get("runs", 0)
	var char_victories: int = char_stats.get("victories", 0)
	var total_sijo: int = meta.get("total_sijo_completions", 0)
	var max_ascension: int = 0
	if meta.has("ascension"):
		max_ascension = meta["ascension"].get(character_id, 0)

	# 직업별 카드 체크
	var card_pool_name := character_id
	if card_pool_name == "mugwan" or card_pool_name == "mungwan" or card_pool_name == "dosa":
		var class_unlocks: Dictionary = UNLOCK_CARDS_PER_CLASS.get(card_pool_name, {})
		var cards: Array = _get_card_ids_for_pool(card_pool_name)
		for idx in class_unlocks:
			if idx >= cards.size():
				continue
			var cid: String = cards[idx]
			if is_card_unlocked(cid):
				continue
			var condition: String = class_unlocks[idx]
			if _check_condition(condition, char_runs, char_victories, victory, total_sijo, max_ascension):
				if unlock_card(cid):
					newly_unlocked.append(cid)

	# 공용 카드 체크
	var common_cards: Array = _get_card_ids_for_pool("common")
	for idx in UNLOCK_CARDS_COMMON:
		if idx >= common_cards.size():
			continue
		var cid: String = common_cards[idx]
		if is_card_unlocked(cid):
			continue
		var condition: String = UNLOCK_CARDS_COMMON[idx]
		if _check_condition(condition, char_runs, char_victories, victory, total_sijo, max_ascension):
			if unlock_card(cid):
				newly_unlocked.append(cid)

	return newly_unlocked


## 해금 조건 판정
static func _check_condition(condition: String, runs: int, victories: int, this_victory: bool, total_sijo: int, max_asc: int) -> bool:
	match condition:
		"default":
			return true
		"class_runs_3":
			return runs >= 3
		"class_clear":
			return victories >= 1 or this_victory
		"sijo_total_10":
			return total_sijo >= 10
		"sijo_total_30":
			return total_sijo >= 30
		"ascension_3":
			return max_asc >= 3
		"ascension_5":
			return max_asc >= 5
	return false


## 카드가 해금 테이블에 포함되는지 확인
static func _is_lockable_card(card_id: String) -> bool:
	for pool_name in UNLOCK_CARDS_PER_CLASS:
		var cards: Array = _get_card_ids_for_pool(pool_name)
		var indices: Dictionary = UNLOCK_CARDS_PER_CLASS[pool_name]
		for idx in indices:
			if idx < cards.size() and cards[idx] == card_id:
				return true
	var common_cards: Array = _get_card_ids_for_pool("common")
	for idx in UNLOCK_CARDS_COMMON:
		if idx < common_cards.size() and common_cards[idx] == card_id:
			return true
	return false


## 카드 풀의 카드 ID 목록 반환 (캐시됨)
static var _card_id_cache: Dictionary = {}

static func _get_card_ids_for_pool(pool_name: String) -> Array:
	if _card_id_cache.has(pool_name):
		return _card_id_cache[pool_name]
	var cards: Array[CardData] = DataLoader.get_cards_by_pool(pool_name)
	var ids: Array = []
	for card in cards:
		ids.append(card.id)
	_card_id_cache[pool_name] = ids
	return ids


## 전체 카드 컬렉션 정보 반환 (UI용)
## [{id, name, pool, unlocked, unlock_condition}]
static func get_collection_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var unlocked := get_unlocked_cards()

	for pool_name in ["mugwan", "mungwan", "dosa", "common"]:
		var cards: Array = _get_card_ids_for_pool(pool_name)
		var lock_table: Dictionary = {}
		if pool_name == "common":
			lock_table = UNLOCK_CARDS_COMMON
		else:
			lock_table = UNLOCK_CARDS_PER_CLASS.get(pool_name, {})

		for i in cards.size():
			var cid: String = cards[i]
			var card_data: CardData = DataLoader.get_card(cid)
			var card_name := cid
			if card_data:
				card_name = card_data.get_display_name()

			var is_locked: bool = lock_table.has(i)
			var is_unlocked: bool = not is_locked or unlocked.has(cid)
			var condition: String = lock_table.get(i, "default")

			result.append({
				"id": cid,
				"name": card_name,
				"pool": pool_name,
				"unlocked": is_unlocked,
				"unlock_condition": condition,
				"index": i,
			})
	return result


## 메타에 시조 완성 누적 수 업데이트
static func add_sijo_completion_to_meta(count: int = 1) -> void:
	var meta: Dictionary = SaveManager.load_meta()
	var current: int = meta.get("total_sijo_completions", 0)
	meta["total_sijo_completions"] = current + count
	SaveManager.save_meta(meta)
