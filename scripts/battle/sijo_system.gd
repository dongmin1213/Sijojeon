class_name SijoSystem
extends Node

## 시조 리듬 시스템. 6슬롯 (초장3, 초장4, 중장3, 중장4, 종장3, 종장4).
## 카드의 음보(beat)가 슬롯 패턴과 일치하면 채워진다.
## 6슬롯 모두 채우면 시조 완성: 마지막 카드 효과 ×2 + 기 1 회복 + 카드 1장 드로우.

## 시조 비트 패턴 변형 — 매 전투마다 랜덤 선택하여 다양성 확보
const PATTERN_VARIANTS: Array = [
	[3, 4, 3, 4, 3, 4],  # 기본 정격
	[4, 3, 4, 3, 4, 3],  # 역배치
	[3, 3, 4, 4, 3, 4],  # 초장 경쾌, 중장 무거움
	[4, 4, 3, 3, 4, 3],  # 초장 무거움, 중장 경쾌
	[3, 4, 4, 3, 3, 4],  # 변격 1
	[4, 3, 3, 4, 4, 3],  # 변격 2
]
const JANG_NAMES: Array[String] = ["초장", "초장", "중장", "중장", "종장", "종장"]

var pattern: Array[int] = [3, 4, 3, 4, 3, 4]  # 현재 전투 패턴
var slots: Array[String] = []  # 채워진 카드 ID
var current_slot_index: int = 0

signal slot_filled(index: int, card_id: String, jang_name: String)
## 장 완성 시그널: 초장/중장/종장 각각 완성 시 발행
signal sijo_chapter_completed(chapter: String)
## sijo_completed: 마지막 카드 ID + 완성에 사용된 6장 카드 ID 배열 전달
signal sijo_completed(final_card_id: String, all_slot_card_ids: Array)


func _ready() -> void:
	_randomize_pattern()


func try_fill_slot(card_beat: int, card_id: String) -> bool:
	if current_slot_index >= pattern.size():
		return false
	if card_beat != pattern[current_slot_index]:
		return false

	slots.append(card_id)
	var jang := JANG_NAMES[current_slot_index]
	slot_filled.emit(current_slot_index, card_id, jang)
	current_slot_index += 1

	# 장 완성 감지: 초장(index 1 완료), 중장(index 3 완료), 종장(index 5 완료)
	if current_slot_index == 2:
		sijo_chapter_completed.emit("초장")
	elif current_slot_index == 4:
		sijo_chapter_completed.emit("중장")
	elif current_slot_index == 6:
		sijo_chapter_completed.emit("종장")

	if current_slot_index >= pattern.size():
		sijo_completed.emit(card_id, slots.duplicate())
	return true


func get_next_required_beat() -> int:
	if current_slot_index >= pattern.size():
		return -1
	return pattern[current_slot_index]


func get_filled_count() -> int:
	return current_slot_index


func is_complete() -> bool:
	return current_slot_index >= pattern.size()


func reset_random_slot() -> void:
	# 채워진 슬롯 중 마지막 것을 초기화 (보스 특수 능력)
	if current_slot_index <= 0:
		return
	current_slot_index -= 1
	if slots.size() > current_slot_index:
		slots.resize(current_slot_index)


func reset() -> void:
	slots.clear()
	current_slot_index = 0
	_randomize_pattern()


func _randomize_pattern() -> void:
	## 전투 시작/시조 리셋 시 패턴 변형을 랜덤으로 선택한다.
	var variant: Array = PATTERN_VARIANTS[randi() % PATTERN_VARIANTS.size()]
	pattern.clear()
	for beat in variant:
		pattern.append(beat)
