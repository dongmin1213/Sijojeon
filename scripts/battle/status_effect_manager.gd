class_name StatusEffectManager
extends Node

## 상태이상(버프/디버프) 관리 시스템.
## 플레이어와 적의 버프/디버프 스택을 추적하고, 턴 시작/종료 시 효과를 적용한다.

signal effect_applied(target: String, effect_id: String, stacks: int)
signal effect_removed(target: String, effect_id: String)
signal effect_triggered(target: String, effect_id: String, value: int)

# target key → { effect_id → stacks }
# target key: "player" or "enemy_0", "enemy_1", ...
var _effects: Dictionary = {}


func clear_all() -> void:
	_effects.clear()


func clear_target(target: String) -> void:
	_effects.erase(target)


func apply_effect(target: String, effect_id: String, stacks: int) -> void:
	if not _effects.has(target):
		_effects[target] = {}
	var current: int = _effects[target].get(effect_id, 0)
	_effects[target][effect_id] = current + stacks
	effect_applied.emit(target, effect_id, _effects[target][effect_id])


func remove_effect(target: String, effect_id: String) -> void:
	if _effects.has(target):
		_effects[target].erase(effect_id)
		effect_removed.emit(target, effect_id)


func get_stacks(target: String, effect_id: String) -> int:
	if _effects.has(target) and _effects[target].has(effect_id):
		return _effects[target][effect_id]
	return 0


func has_effect(target: String, effect_id: String) -> bool:
	return get_stacks(target, effect_id) > 0


func get_all_effects(target: String) -> Dictionary:
	if _effects.has(target):
		return _effects[target].duplicate()
	return {}


func consume_stacks(target: String, effect_id: String, amount: int = 1) -> int:
	## 스택을 소비하고 소비된 수를 반환. 0이 되면 제거.
	var current := get_stacks(target, effect_id)
	if current <= 0:
		return 0
	var consumed := mini(current, amount)
	var remaining := current - consumed
	if remaining <= 0:
		remove_effect(target, effect_id)
	else:
		_effects[target][effect_id] = remaining
	return consumed


## 턴 시작 시 효과 처리 (독, 화상, 사망표식 등의 지속 피해)
## 반환: { "damage": int } — 이 턴에 받을 지속 피해 합계
func process_turn_start(target: String) -> Dictionary:
	var result := {"damage": 0}
	var effects := get_all_effects(target)

	# 독: 매 턴 n피해 후 n 1 감소, 0이면 소멸
	if effects.has("독"):
		var poison_stacks: int = effects["독"]
		result["damage"] += poison_stacks
		effect_triggered.emit(target, "독", poison_stacks)
		var remaining := poison_stacks - 1
		if remaining <= 0:
			remove_effect(target, "독")
		else:
			_effects[target]["독"] = remaining

	# 화상: 매 턴 n피해 (스택 = 남은 턴 수), 1턴씩 감소
	if effects.has("화상"):
		var burn_stacks: int = effects["화상"]
		result["damage"] += burn_stacks
		effect_triggered.emit(target, "화상", burn_stacks)
		var remaining := burn_stacks - 1
		if remaining <= 0:
			remove_effect(target, "화상")
		else:
			_effects[target]["화상"] = remaining

	# 사망 표식: 매 턴 1씩 감소, 줄어들 때 5피해
	if effects.has("death_mark"):
		var stacks: int = effects["death_mark"]
		result["damage"] += 5
		effect_triggered.emit(target, "death_mark", 5)
		var remaining := stacks - 1
		if remaining <= 0:
			remove_effect(target, "death_mark")
		else:
			_effects[target]["death_mark"] = remaining

	return result


## 턴 종료 시 디버프 기간 감소 (취약 등 턴 기반 효과)
func process_turn_end(target: String) -> void:
	# 취약: 매 턴 종료 시 1 감소
	if has_effect(target, "취약"):
		consume_stacks(target, "취약", 1)

	# 냉기: 1턴 후 해제 (턴 종료 시 제거)
	if has_effect(target, "냉기"):
		remove_effect(target, "냉기")


## 공격 피해 수정자 계산
func calculate_outgoing_damage(attacker: String, base_damage: int) -> int:
	var damage := base_damage

	# strength: 공격 피해 + stacks
	var strength := get_stacks(attacker, "strength")
	if strength > 0:
		damage += strength

	# 약화: 다음 공격 피해 25% 감소, 1회 발동 후 소멸
	if has_effect(attacker, "약화"):
		damage = int(damage * 0.75)
		consume_stacks(attacker, "약화", 1)

	return maxi(damage, 0)


## 받는 피해 수정자 계산
func calculate_incoming_damage(defender: String, damage: int) -> int:
	var final_damage := damage

	# 취약: 받는 피해 25% 증가
	if has_effect(defender, "취약"):
		final_damage = int(final_damage * 1.25)

	return final_damage


## 드로우 수 수정자 (냉기 등)
func get_draw_modifier(target: String) -> int:
	var modifier := 0

	# 냉기: 드로우 1장 감소
	if has_effect(target, "냉기"):
		modifier -= 1

	return modifier
