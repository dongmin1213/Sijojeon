class_name SijoSystem
extends Node

## 시조 리듬 시스템. 6슬롯 (초장3, 초장4, 중장3, 중장4, 종장3, 종장4).
## 카드의 음보(beat)가 슬롯 패턴과 일치하면 채워진다.
## 6슬롯 모두 채우면 시조 완성: 마지막 카드 효과 ×2 + 기 1 회복 + 카드 1장 드로우.

const PATTERN: Array[int] = [3, 4, 3, 4, 3, 4]
const JANG_NAMES: Array[String] = ["초장", "초장", "중장", "중장", "종장", "종장"]

var slots: Array[String] = []  # 채워진 카드 ID
var current_slot_index: int = 0

signal slot_filled(index: int, card_id: String, jang_name: String)
signal sijo_completed(final_card_id: String)


func try_fill_slot(card_beat: int, card_id: String) -> bool:
	if current_slot_index >= PATTERN.size():
		return false
	if card_beat != PATTERN[current_slot_index]:
		return false

	slots.append(card_id)
	var jang := JANG_NAMES[current_slot_index]
	slot_filled.emit(current_slot_index, card_id, jang)
	current_slot_index += 1

	if current_slot_index >= PATTERN.size():
		sijo_completed.emit(card_id)
	return true


func get_next_required_beat() -> int:
	if current_slot_index >= PATTERN.size():
		return -1
	return PATTERN[current_slot_index]


func get_filled_count() -> int:
	return current_slot_index


func is_complete() -> bool:
	return current_slot_index >= PATTERN.size()


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
