class_name SisangSystem
extends RefCounted

## 시상(詩想) 시스템 (Phase 2-2).
## 런 전체에 시조 완성 횟수를 누적하여 마일스톤 보상 제공.
## 시상 5: 이벤트 추가 선택지 해금
## 시상 10: 시조 일격 피해 +25%
## 시상 15: 보스전 시조 완성 시 ×2.0
## 시상 20+: 최종보스 "어사출두" 특수 공격 가능

## 마일스톤 임계값
const MILESTONE_EVENT_CHOICES := 5      # 이벤트 추가 선택지
const MILESTONE_STRIKE_BONUS := 10      # 시조 일격 +25%
const MILESTONE_BOSS_DOUBLE := 15       # 보스전 시조 ×2.0
const MILESTONE_EOSA_CHULDU := 20       # 어사출두 해금

## 마일스톤 정보 (UI 표시용)
const MILESTONES := [
	{"threshold": 5,  "key": "SISANG_MILESTONE_5",  "icon": "event"},
	{"threshold": 10, "key": "SISANG_MILESTONE_10", "icon": "sword"},
	{"threshold": 15, "key": "SISANG_MILESTONE_15", "icon": "boss"},
	{"threshold": 20, "key": "SISANG_MILESTONE_20", "icon": "star"},
]


## 시조 완성 시 호출 — 카운트 증가 + 마일스톤 달성 여부 반환
static func on_sijo_complete(rd: RunData) -> Dictionary:
	if rd == null:
		return {}
	var old_count := rd.sisang_count
	rd.sisang_count += 1
	var new_count := rd.sisang_count

	# 마일스톤을 새로 넘었는지 확인
	var result := {"count": new_count, "milestone_reached": ""}
	for ms in MILESTONES:
		var t: int = ms["threshold"]
		if old_count < t and new_count >= t:
			result["milestone_reached"] = ms["key"]
			break  # 한 번에 하나만 알림
	return result


## 이벤트 추가 선택지 해금 여부
static func has_event_bonus(rd: RunData) -> bool:
	return rd != null and rd.sisang_count >= MILESTONE_EVENT_CHOICES


## 시조 일격 추가 배율 (시상 10 달성 시 +0.25)
static func get_strike_bonus_multiplier(rd: RunData) -> float:
	if rd != null and rd.sisang_count >= MILESTONE_STRIKE_BONUS:
		return 1.25
	return 1.0


## 보스전 시조 완성 추가 배율 (시상 15 달성 시 ×2.0)
static func get_boss_sijo_multiplier(rd: RunData) -> float:
	if rd != null and rd.sisang_count >= MILESTONE_BOSS_DOUBLE:
		return 2.0
	return 1.0


## 어사출두 해금 여부 (시상 20+)
static func has_eosa_chuldu(rd: RunData) -> bool:
	return rd != null and rd.sisang_count >= MILESTONE_EOSA_CHULDU


## 현재 시상 수 반환
static func get_count(rd: RunData) -> int:
	if rd == null:
		return 0
	return rd.sisang_count


## 다음 마일스톤까지 남은 시조 수 반환
static func get_next_milestone_info(rd: RunData) -> Dictionary:
	if rd == null:
		return {"remaining": 5, "threshold": 5, "key": "SISANG_MILESTONE_5"}
	for ms in MILESTONES:
		var t: int = ms["threshold"]
		if rd.sisang_count < t:
			return {"remaining": t - rd.sisang_count, "threshold": t, "key": ms["key"]}
	return {"remaining": 0, "threshold": 20, "key": "SISANG_MILESTONE_20"}
