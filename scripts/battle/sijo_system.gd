class_name SijoSystem
extends Node

## 시조 리듬 시스템. 3슬롯 (초장/중장/종장 각 1슬롯).
## 매 턴 3카드 = 1턴 완성 사이클. beat 일치도가 곧 보상.
## beat 3/3 완벽: 전체 카드 ×1.5 + qi +2 + draw +1
## beat 2/3: 마지막 일치 카드 ×1.3 + qi +1
## beat 1/3 또는 0/3: 보너스 없음 (카드 자체 효과만)

## 시조 비트 패턴 변형 — 매 전투마다 랜덤 선택
const PATTERN_VARIANTS: Array = [
	[3, 4, 3],  # 기본 정격
	[4, 3, 4],  # 역배치
	[3, 3, 4],  # 초장 경쾌
	[4, 4, 3],  # 초장 무거움
	[3, 4, 4],  # 변격 1
	[4, 3, 3],  # 변격 2
]
static var JANG_NAMES: Array[String]:
	get:
		return [TranslationServer.translate("SIJO_FIRST_VERSE"), TranslationServer.translate("SIJO_MIDDLE_VERSE"), TranslationServer.translate("SIJO_FINAL_VERSE")]

var pattern: Array[int] = [3, 4, 3]  # 현재 전투 패턴
var slots: Array[String] = []  # 채워진 카드 ID
var beat_matches: Array[bool] = []  # 각 슬롯의 beat 일치 여부
var current_slot_index: int = 0

signal slot_filled(index: int, card_id: String, jang_name: String, beat_matched: bool)
## 시조 완성 시그널: 마지막 카드 ID + 3장 카드 ID 배열 + beat 일치 수
signal sijo_completed(final_card_id: String, all_slot_card_ids: Array, match_count: int)


func _ready() -> void:
	_randomize_pattern()


func try_fill_slot(card_beat: int, card_id: String) -> bool:
	## 모든 카드가 슬롯을 채운다. beat가 패턴과 일치하면 true 반환.
	if current_slot_index >= pattern.size():
		return false
	var beat_matched := card_beat == pattern[current_slot_index]

	slots.append(card_id)
	beat_matches.append(beat_matched)
	var jang := JANG_NAMES[current_slot_index]
	slot_filled.emit(current_slot_index, card_id, jang, beat_matched)
	current_slot_index += 1

	# 3슬롯 모두 채우면 시조 완성
	if current_slot_index >= pattern.size():
		var match_count := get_match_count()
		sijo_completed.emit(card_id, slots.duplicate(), match_count)
	return beat_matched


func get_next_required_beat() -> int:
	if current_slot_index >= pattern.size():
		return -1
	return pattern[current_slot_index]


func get_filled_count() -> int:
	return current_slot_index


func get_match_count() -> int:
	## beat 일치 슬롯 수 반환
	var count := 0
	for matched in beat_matches:
		if matched:
			count += 1
	return count


func is_complete() -> bool:
	return current_slot_index >= pattern.size()


func reset_random_slot() -> void:
	# 채워진 슬롯 중 마지막 것을 초기화 (보스 특수 능력)
	if current_slot_index <= 0:
		return
	current_slot_index -= 1
	if slots.size() > current_slot_index:
		slots.resize(current_slot_index)
	if beat_matches.size() > current_slot_index:
		beat_matches.resize(current_slot_index)


func reset() -> void:
	slots.clear()
	beat_matches.clear()
	current_slot_index = 0
	_randomize_pattern()


func _randomize_pattern() -> void:
	## 전투 시작/시조 리셋 시 패턴 변형을 랜덤으로 선택한다.
	var variant: Array = PATTERN_VARIANTS[randi() % PATTERN_VARIANTS.size()]
	pattern.clear()
	for beat in variant:
		pattern.append(beat)
