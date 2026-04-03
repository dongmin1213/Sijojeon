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


func clear_buffs(target: String) -> void:
	if not _effects.has(target):
		return
	var effects: Dictionary = _effects[target]
	var to_remove: Array[String] = []
	for effect_id in effects:
		var def := StatusEffectData.get_definition(effect_id)
		if def != null and def.type == StatusEffectData.EffectType.BUFF:
			to_remove.append(effect_id)
	for effect_id in to_remove:
		effects.erase(effect_id)
		effect_removed.emit(target, effect_id)


func apply_effect(target: String, effect_id: String, stacks: int) -> void:
	if target.is_empty():
		push_error("StatusEffectManager.apply_effect: target이 비어있음")
		return
	if effect_id.is_empty():
		push_error("StatusEffectManager.apply_effect: effect_id가 비어있음 (target=%s)" % target)
		return
	if stacks <= 0:
		push_warning("StatusEffectManager.apply_effect: stacks가 0 이하 — %d (target=%s, effect=%s)" % [stacks, target, effect_id])
		return
	if not _effects.has(target):
		_effects[target] = {}
	# R002 평안 부적: 플레이어에게 버프 적용 시 지속 턴 +1
	var final_stacks := stacks
	if target == "player":
		var buff_def := StatusEffectData.get_definition(effect_id)
		if buff_def and buff_def.type == StatusEffectData.EffectType.BUFF:
			final_stacks = RelicManager.trigger_on_buff_apply(stacks)
	# R008 동의보감: 독 부여 시 스택 보너스
	if effect_id == "독":
		final_stacks = RelicManager.trigger_on_apply_poison(target, final_stacks)
	var current: int = _effects[target].get(effect_id, 0)
	# 스택 오버플로 방지 (최대 999)
	_effects[target][effect_id] = mini(current + final_stacks, 999)
	effect_applied.emit(target, effect_id, _effects[target][effect_id])
	# 버프/디버프 SFX (플레이어 대상일 때만 재생)
	if target == "player":
		var sfx_def := StatusEffectData.get_definition(effect_id)
		if sfx_def and sfx_def.type == StatusEffectData.EffectType.BUFF:
			AudioManager.play_sfx_by_key("buff")
		else:
			AudioManager.play_sfx_by_key("debuff")


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


## 턴 시작 시 효과 처리 (독, 화상, 출혈, 사망표식 등의 지속 피해)
## 반환: { "damage": int, "armor": int } — 이 턴에 받을 지속 피해 합계와 갑주 방어도
func process_turn_start(target: String) -> Dictionary:
	var result := {"damage": 0, "armor": 0}
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

	# 출혈: 매 턴 n피해, 1턴씩 감소. 방어도 획득 시 피해 2배 (별도 처리)
	if effects.has("출혈"):
		var bleed_stacks: int = effects["출혈"]
		result["damage"] += bleed_stacks
		effect_triggered.emit(target, "출혈", bleed_stacks)
		var remaining := bleed_stacks - 1
		if remaining <= 0:
			remove_effect(target, "출혈")
		else:
			_effects[target]["출혈"] = remaining

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

	# 사망선고: 매 턴 1씩 감소, 0이 되면 HP 50% 감소 트리거
	if effects.has("death_countdown"):
		var stacks: int = effects["death_countdown"]
		var remaining := stacks - 1
		if remaining <= 0:
			remove_effect(target, "death_countdown")
			# -1 = 사망선고 발동 시그널 (BattleManager에서 HP 50% 처리)
			effect_triggered.emit(target, "death_countdown", -1)
		else:
			_effects[target]["death_countdown"] = remaining

	# 주박: DoT 피해 1.5배
	if effects.has("주박") and result["damage"] > 0:
		result["damage"] = int(result["damage"] * 1.5)

	# 갑주: 영구 방어막 (턴 시작 시 block에 추가)
	if effects.has("갑주"):
		result["armor"] = effects["갑주"]

	return result


## 턴 종료 시 디버프 기간 감소 (취약 등 턴 기반 효과)
func process_turn_end(target: String) -> void:
	# 취약: 매 턴 종료 시 1 감소
	if has_effect(target, "취약"):
		consume_stacks(target, "취약", 1)
	# 구금: 매 턴 종료 시 1 감소
	if has_effect(target, "구금"):
		consume_stacks(target, "구금", 1)
	# 주박: 매 턴 종료 시 1 감소
	if has_effect(target, "주박"):
		consume_stacks(target, "주박", 1)

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

	# 취약: 받는 피해 50% 증가
	if has_effect(defender, "취약"):
		final_damage = int(final_damage * 1.5)

	return final_damage


## 출혈 시 방어도 획득 추가 피해 계산 (block 획득 시 출혈 스택만큼 추가 피해)
func calculate_bleed_on_block(target: String, block_amount: int) -> int:
	if block_amount <= 0:
		return 0
	var bleed_stacks := get_stacks(target, "출혈")
	if bleed_stacks <= 0:
		return 0
	# 출혈 상태에서 방어도 획득 시 출혈 스택만큼 추가 피해
	effect_triggered.emit(target, "출혈", bleed_stacks)
	return bleed_stacks


## 가시(thorns) 반사 피해 계산
func get_thorns_damage(defender: String) -> int:
	return get_stacks(defender, "thorns")


## 드로우 수 수정자 (냉기 등)
func get_draw_modifier(target: String) -> int:
	var modifier := 0

	# 냉기: 드로우 1장 감소
	if has_effect(target, "냉기"):
		modifier -= 1

	return modifier
