class_name GwageoScorer
extends RefCounted

## 과거시험 채점 시스템 (Phase 4).
## 초장(균형), 중장(시너지), 종장(피해) 3단계 채점.

## 시험관 유형
const EXAMINER_DEFAULT := "scholar"
const EXAMINER_FACTION := "faction"
const EXAMINER_CORRUPT := "corrupt"
const EXAMINER_SECRET := "amhaengosa"

## 시험관 테이블
const EXAMINERS := [
	{"id": "scholar", "name": "청렴한 학자", "weight": 40},
	{"id": "faction", "name": "당파 시험관", "weight": 25},
	{"id": "corrupt", "name": "탐관 시험관", "weight": 20},
	{"id": "amhaengosa", "name": "암행어사", "weight": 15},
]


## 초장 채점: 공격/방어/기술 비율 균형 (0~40점).
## cards: Array[CardData] — 선택한 카드 3장.
static func score_balance(cards: Array) -> int:
	if cards.is_empty() or cards.size() > 5:
		return 0
	var type_counts := {"attack": 0, "defense": 0, "other": 0}
	for card in cards:
		var t: String = card.type if card is CardData else str(card.get("type", ""))
		if t == "attack":
			type_counts["attack"] += 1
		elif t == "defense":
			type_counts["defense"] += 1
		else:
			type_counts["other"] += 1

	# 1:1:1 = 만점 40, 2:1:0 = 25, 3:0:0 = 10
	var unique_types := 0
	for count in type_counts.values():
		if count > 0:
			unique_types += 1

	match unique_types:
		3: return 40   # 모든 유형 포함
		2: return 25   # 두 유형
		_: return 10   # 한 유형만


## 중장 채점: 시너지 태그 연계 (0~35점).
## cards: Array[CardData] — 선택한 카드 3장.
## chojangs: Array[CardData] — 초장에서 선택한 카드 (비교 대상).
static func score_synergy(cards: Array, chojangs: Array) -> int:
	if cards.is_empty() or chojangs.is_empty():
		return 0
	# 시너지 판정: subtypes 교집합 개수
	var chojang_tags := {}
	for card in chojangs:
		var subs: Array = card.subtypes if card is CardData else card.get("subtypes", [])
		for tag in subs:
			chojang_tags[tag] = true

	var synergy_count := 0
	for card in cards:
		var subs: Array = card.subtypes if card is CardData else card.get("subtypes", [])
		for tag in subs:
			if chojang_tags.has(tag):
				synergy_count += 1

	# pool(직업) 일치도 시너지 카운트
	var chojang_pools := {}
	for card in chojangs:
		var p: String = card.pool if card is CardData else str(card.get("pool", ""))
		if p != "common":
			chojang_pools[p] = true
	for card in cards:
		var p: String = card.pool if card is CardData else str(card.get("pool", ""))
		if chojang_pools.has(p):
			synergy_count += 1

	if synergy_count >= 4:
		return 35
	elif synergy_count >= 2:
		return 25
	elif synergy_count >= 1:
		return 15
	return 5


## 종장 채점: 합산 피해량 (0~25점).
## cards: Array[CardData] — 선택한 카드 2장.
static func score_damage(cards: Array) -> int:
	if cards.is_empty() or cards.size() > 5:
		return 0
	var total_damage := 0
	for card in cards:
		var dmg: int = card.damage if card is CardData else int(card.get("damage", 0))
		total_damage += dmg

	if total_damage >= 12:
		return 25
	elif total_damage >= 8:
		return 20
	elif total_damage >= 6:
		return 15
	elif total_damage >= 3:
		return 10
	return 5


## 전체 채점. 시험관 보너스 적용 전 원점수 반환.
static func calculate_score(chojangs: Array, jungjangs: Array, jongjangs: Array) -> int:
	var score := 0
	score += score_balance(chojangs)
	score += score_synergy(jungjangs, chojangs)
	score += score_damage(jongjangs)
	return clampi(score, 0, 100)


## 시험관 보너스 적용.
static func apply_examiner_bonus(base_score: int, examiner_id: String, rd: RunData) -> int:
	match examiner_id:
		"faction":
			# 당파 카드 포함 시 +15점 (TODO: 실제 당파 카드 판별)
			return base_score + 15
		_:
			return base_score


## 등급 판정.
static func get_grade(score: int) -> String:
	if score >= 85:
		return "jangwon"   # 장원 급제
	elif score >= 65:
		return "geupje"    # 급제
	elif score >= 40:
		return "hapgyeok"  # 합격
	return "nakbang"       # 낙방


## 등급 한글 이름.
static func get_grade_name(grade: String) -> String:
	match grade:
		"jangwon": return "장원 급제"
		"geupje": return "급제"
		"hapgyeok": return "합격"
		"nakbang": return "낙방"
	return "낙방"


## 시험관 무작위 선택.
static func roll_examiner() -> Dictionary:
	var total_weight := 0
	for ex in EXAMINERS:
		total_weight += ex["weight"]
	var roll := randi() % total_weight
	var cumulative := 0
	for ex in EXAMINERS:
		cumulative += ex["weight"]
		if roll < cumulative:
			return ex
	return EXAMINERS[0]
