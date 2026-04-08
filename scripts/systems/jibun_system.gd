class_name JibunSystem
extends RefCounted

## 신분 레벨업 시스템 (Phase 1-5 재설계).
## 전투 승리 기반 레벨업. 각 단계별 패시브 보너스 제공.
## 천민→상민(카드 업그레이드)→중인(기+1)→양반(드로우+1)→당상관(엘리트 보상 2배)→정승(시조 일격 2배)

## 신분 단계별 진입 점수
const RANK_THRESHOLDS := {
	0: -100,  # 천민
	1: 0,     # 상민(평민)
	2: 100,   # 중인
	3: 250,   # 양반
	4: 500,   # 당상관
	5: 800,   # 판서/정승
}

## 단계별 번역 키
const RANK_KEYS := {
	0: "JIBUN_RANK_0",
	1: "JIBUN_RANK_1",
	2: "JIBUN_RANK_2",
	3: "JIBUN_RANK_3",
	4: "JIBUN_RANK_4",
	5: "JIBUN_RANK_5",
}

## 신분 단계 상승 시 엘리트 등장 가중치 증가 (단계당 10%)
const ELITE_WEIGHT_PER_RANK := 10


## 점수를 추가하고 단계를 갱신한다. 단계 변경 시 [old_rank, new_rank] 반환, 아니면 null.
static func add_score(rd: RunData, delta: int) -> Variant:
	if rd == null:
		return null
	var old_rank := rd.jibun_rank
	rd.jibun_score = clampi(rd.jibun_score + delta, -100, 999)
	rd.jibun_rank = _calculate_rank(rd.jibun_score)
	if rd.jibun_rank != old_rank:
		return [old_rank, rd.jibun_rank]
	return null


## 점수로 단계를 계산한다.
static func _calculate_rank(score: int) -> int:
	var rank := 0
	for r in range(5, -1, -1):
		if score >= RANK_THRESHOLDS[r]:
			rank = r
			break
	return rank


## 현재 단계 이름 반환.
static func get_rank_name(rank: int) -> String:
	var key: String = RANK_KEYS.get(rank, "JIBUN_RANK_1")
	return TranslationServer.translate(key)


## 전투 승리 시 호출 — 노드 타입에 따라 점수 부여.
static func on_battle_victory(rd: RunData, node_type: int) -> Variant:
	match node_type:
		MapData.NodeType.BATTLE:
			return add_score(rd, 5)
		MapData.NodeType.ELITE:
			return add_score(rd, 15)
		MapData.NodeType.BOSS:
			return add_score(rd, 30)
	return null


## 과거시험 결과에 따른 점수 변동.
static func on_gwageo_result(rd: RunData, grade: String) -> Variant:
	match grade:
		"jangwon":  # 장원 급제
			return add_score(rd, 50)
		"geupje":   # 급제
			return add_score(rd, 20)
		"hapgyeok": # 합격
			return add_score(rd, 10)
		"nakbang":  # 낙방
			return add_score(rd, -10)
	return null


# ── 레벨업 패시브 보너스 ──────────────────────────────

## 중인(2+): 턴당 기 +1
static func get_qi_bonus(rd: RunData) -> int:
	if rd != null and rd.jibun_rank >= 2:
		return 1
	return 0


## 양반(3+): 턴당 드로우 +1
static func get_draw_bonus(rd: RunData) -> int:
	if rd != null and rd.jibun_rank >= 3:
		return 1
	return 0


## 당상관(4+): 엘리트 보상 배율
static func get_elite_reward_multiplier(rd: RunData) -> float:
	if rd != null and rd.jibun_rank >= 4:
		return 2.0
	return 1.0


## 정승(5): 시조 일격 배율
static func get_sijo_strike_multiplier(rd: RunData) -> float:
	if rd != null and rd.jibun_rank >= 5:
		return 2.0
	return 1.0


# ── 신분 승급 즉각 보상 ──────────────────────────────

## 승급 보상 타입 상수
const RANK_UP_REWARDS := {
	1: "card_upgrade",     # 상민 승급: 덱 카드 1장 강화
	2: "qi_bonus",         # 중인 승급: 기+1 (패시브)
	3: "draw_bonus",       # 양반 승급: 드로우+1 (패시브)
	4: "elite_reward_2x",  # 당상관 승급: 엘리트 보상 2배 (패시브)
	5: "sijo_strike_2x",   # 정승 승급: 시조 일격 2배 (패시브)
}

## 승급 보상 설명 번역 키
const RANK_UP_REWARD_KEYS := {
	1: "JIBUN_RANKUP_1",
	2: "JIBUN_RANKUP_2",
	3: "JIBUN_RANKUP_3",
	4: "JIBUN_RANKUP_4",
	5: "JIBUN_RANKUP_5",
}


# ── 기존 호환 함수 (다른 시스템에서 호출) ──────────────────────────────

## 종장 클리어 보너스 배율 반환 — 정승(5): 시조 일격 2배로 대체
static func get_jongchang_bonus(rd: RunData) -> float:
	return get_sijo_strike_multiplier(rd)


## 과거시험 접근 — 양반(3+)
static func can_access_gwageo(rd: RunData) -> bool:
	if rd == null:
		return true
	return rd.jibun_rank >= 3


## 엘리트 등장 보너스 — 중인(2+): +5%
static func get_elite_spawn_bonus(rd: RunData) -> float:
	if rd != null and rd.jibun_rank >= 2:
		return 0.05
	return 0.0
