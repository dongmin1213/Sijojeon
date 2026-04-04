class_name JibunSystem
extends RefCounted

## 신분 트랙 시스템 (Phase 3-A).
## 신분 점수를 관리하고 단계를 갱신한다.

## 신분 단계별 진입 점수
const RANK_THRESHOLDS := {
	0: -100,  # 천민
	1: 0,     # 상민(평민)
	2: 100,   # 중인
	3: 250,   # 양반
	4: 500,   # 당상관
	5: 800,   # 판서/정승
}

## 단계별 명칭
const RANK_NAMES := {
	0: "천민(賤民)",
	1: "상민(常民)",
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


# ── 신분별 gameplay 보너스 ──────────────────────────────

## 양반(3+): 상점 카드 가격 -15%
static func get_shop_price_modifier(rd: RunData) -> float:
	if rd != null and rd.jibun_rank >= 3:
		return 0.85
	return 1.0


## 양반(3+): 민심 획득량 +10%
static func get_minshim_gain_multiplier(rd: RunData) -> float:
	if rd != null and rd.jibun_rank >= 3:
		return 1.1
	return 1.0


## 중인(2): 카드 업그레이드 비용 -25%
static func get_upgrade_cost_discount(rd: RunData) -> float:
	if rd != null and rd.jibun_rank == 2:
		return 0.75
	return 1.0


## 상민(1): 카드 보상 선택지 +1
static func get_card_offer_bonus(rd: RunData) -> int:
	if rd != null and rd.jibun_rank == 1:
		return 1
	return 0


## 천민(0): 전투 보상 금화 +50%
static func get_gold_reward_multiplier(rd: RunData) -> float:
	if rd != null and rd.jibun_rank <= 0:
		return 1.5
	return 1.0


## 천민(0): 이벤트 히든 선택지 해금 여부
static func has_hidden_choices(rd: RunData) -> bool:
	if rd == null:
		return false
	return rd.jibun_rank <= 0


# ── 신분 승급 즉각 보상 ──────────────────────────────

## 승급 보상 타입 상수
const RANK_UP_REWARDS := {
	2: "card_select",      # 중인 승급: 카드 1장 추가 선택
	3: "card_remove_free", # 양반 승급: 카드 제거 1회 무료
	4: "relic_select",     # 당상관 승급: 유물 선택 1회 추가
	5: "card_upgrade",     # 판서/정승 승급: 덱 카드 1장 강화
}

## 승급 보상 설명 텍스트
const RANK_UP_REWARD_DESC := {
	2: "중인 승급 보상: 카드 1장을 추가로 선택할 수 있습니다!",
	3: "양반 승급 보상: 카드 제거 1회를 무료로 제공합니다!",
	4: "당상관 승급 보상: 유물 선택 기회 1회를 추가로 받습니다!",
	5: "판서/정승 승급 보상: 덱에서 카드 1장을 강화할 수 있습니다!",
}


# ── 신분 등급별 지속 효과 ──────────────────────────────

## 등급 2(중인): 엘리트 등장률 +5%
static func get_elite_spawn_bonus(rd: RunData) -> float:
	if rd != null and rd.jibun_rank >= 2:
		return 0.05
	return 0.0


## 등급 3(양반): 엘리트 HP +10%
static func get_elite_hp_modifier(rd: RunData) -> float:
	if rd != null and rd.jibun_rank >= 3:
		return 1.1
	return 1.0


## 등급 4(당상관): 보스 HP +10% (고위직의 무게감)
static func get_boss_hp_modifier(rd: RunData) -> float:
	if rd != null and rd.jibun_rank >= 4:
		return 1.1
	return 1.0


## 등급 3(양반)+: 과거시험 접근 가능 여부
static func can_access_gwageo(rd: RunData) -> bool:
	if rd == null:
		return true  # 기본 접근 허용
	return rd.jibun_rank >= 3


## 등급 5(판서/정승): 모든 전투 보상 +30%
static func get_all_reward_multiplier(rd: RunData) -> float:
	if rd != null and rd.jibun_rank >= 5:
		return 1.3
	return 1.0
