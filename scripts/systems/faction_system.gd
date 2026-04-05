class_name FactionSystem
extends RefCounted

## 당파 시스템 (Phase 3-B).
## 런의 당파 대립 쌍과 미터를 관리한다.

## 당파 ID → 번역 키
const FACTION_KEYS := {
	"noron": "FACTION_NORON",
	"soron": "FACTION_SORON",
	"namin": "FACTION_NAMIN",
	"seoin": "FACTION_SEOIN",
	"dongin": "FACTION_DONGIN",
	"bugin": "FACTION_BUGIN",
}

## 미터 효과 임계값
const THRESHOLD_DISCOUNT := 20
const THRESHOLD_CARD_OFFER := 50
const THRESHOLD_RELIC_BOSS := 80
const THRESHOLD_CLIMAX := 100


## 당파 미터를 변경한다. 클라이맥스 도달 시 faction_id 반환, 아니면 "".
static func change_meter(rd: RunData, faction_id: String, delta: int) -> String:
	if rd == null or not rd.faction_meters.has(faction_id):
		return ""
	var old_value: int = rd.faction_meters[faction_id]
	rd.faction_meters[faction_id] = clampi(old_value + delta, 0, 100)
	# 클라이맥스 달성 체크
	if old_value < THRESHOLD_CLIMAX and rd.faction_meters[faction_id] >= THRESHOLD_CLIMAX:
		return faction_id
	return ""


## 런의 두 당파 이름을 반환한다.
static func get_faction_names(rd: RunData) -> Array[String]:
	var names: Array[String] = []
	for fid in rd.faction_pair:
		names.append(get_faction_name(fid))
	return names


## 특정 당파 이름 반환 (번역키 사용).
static func get_faction_name(faction_id: String) -> String:
	var key: String = FACTION_KEYS.get(faction_id, "")
	if key != "":
		return TranslationServer.translate(key)
	return faction_id


## 당파 미터 효과가 활성화되었는지 확인한다.
static func has_discount(rd: RunData, faction_id: String) -> bool:
	return rd.faction_meters.get(faction_id, 0) >= THRESHOLD_DISCOUNT


static func has_card_offer(rd: RunData, faction_id: String) -> bool:
	return rd.faction_meters.get(faction_id, 0) >= THRESHOLD_CARD_OFFER


static func has_relic_and_boss(rd: RunData, faction_id: String) -> bool:
	return rd.faction_meters.get(faction_id, 0) >= THRESHOLD_RELIC_BOSS


static func has_climax(rd: RunData, faction_id: String) -> bool:
	return rd.faction_meters.get(faction_id, 0) >= THRESHOLD_CLIMAX


## 상점 할인율 반환. 해당 당파 20+ 시 10% 할인.
static func get_shop_discount(rd: RunData) -> float:
	if rd == null:
		return 1.0
	for fid in rd.faction_pair:
		if has_discount(rd, fid):
			return 0.9
	return 1.0


## 라이벌 당파 ID 반환.
static func get_rival_faction(rd: RunData, faction_id: String) -> String:
	if rd.faction_pair.size() != 2:
		return ""
	if rd.faction_pair[0] == faction_id:
		return rd.faction_pair[1]
	return rd.faction_pair[0]


## 양측 미터를 동시에 감소시킨다 (중립 선택 시).
static func reduce_both(rd: RunData, amount: int) -> void:
	if rd == null:
		return
	for fid in rd.faction_pair:
		rd.faction_meters[fid] = clampi(rd.faction_meters.get(fid, 0) - amount, 0, 100)
