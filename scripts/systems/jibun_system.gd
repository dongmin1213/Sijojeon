class_name JibunSystem
extends RefCounted

## 신분 트랙 시스템 (Phase 3-A).
## 신분 점수를 관리하고 단계를 갱신한다.

## 신분 단계별 진입 점수
const RANK_THRESHOLDS := {
	1: 0,     # 평민
	2: 100,   # 중인
	3: 250,   # 양반
	4: 500,   # 당상관
	5: 800,   # 판서/정승
}

## 단계별 명칭
const RANK_NAMES := {
	1: "평민(平民)",
	2: "중인(中人)",
	3: "양반(兩班)",
	4: "당상관(堂上官)",
	5: "판서/정승",
}

## 신분 단계 상승 시 엘리트 등장 가중치 증가 (단계당 10%)
const ELITE_WEIGHT_PER_RANK := 10


## 점수를 추가하고 단계를 갱신한다. 단계 변경 시 [old_rank, new_rank] 반환, 아니면 null.
static func add_score(rd: RunData, delta: int) -> Variant:
	if rd == null:
		return null
	var old_rank := rd.jibun_rank
	rd.jibun_score = clampi(rd.jibun_score + delta, 0, 999)
	rd.jibun_rank = _calculate_rank(rd.jibun_score)
	if rd.jibun_rank != old_rank:
		return [old_rank, rd.jibun_rank]
	return null


## 점수로 단계를 계산한다.
static func _calculate_rank(score: int) -> int:
	var rank := 1
	for r in range(5, 0, -1):
		if score >= RANK_THRESHOLDS[r]:
			rank = r
			break
	return rank


## 현재 단계 이름 반환.
static func get_rank_name(rank: int) -> String:
	return RANK_NAMES.get(rank, "평민(平民)")


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


## 종장 클리어 보너스 배율 반환 (5단계: +30%).
static func get_jongchang_bonus(rd: RunData) -> float:
	if rd == null or rd.jibun_rank < 5:
		return 1.0
	return 1.3
