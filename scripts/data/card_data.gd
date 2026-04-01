class_name CardData
extends Resource

## 카드 데이터 클래스. JSON에서 파싱된 카드 한 장의 정보.

@export var id: String = ""
@export var name_ko: String = ""
@export var name_hanja: String = ""
@export var name_romanized: String = ""
@export var beat: int = 3
@export var cost: int = 1
@export var type: String = ""
@export var subtypes: Array[String] = []
@export var rarity: int = 1
@export var pool: String = ""  # "common", "dosa", "mugwan"
@export var effect: String = ""
@export var effect_upgraded: String = ""
@export var flavor_text: String = ""
@export var upgrade_cost: int = 75
@export var upgraded: bool = false

# 구조화된 효과 수치
@export var damage: int = 0
@export var block_value: int = 0
@export var draw_count: int = 0
@export var qi_gain: int = 0
@export var is_aoe: bool = false
@export var tokens: int = 0
@export var stamina_cost: int = 0   # 클래스 고유 자원 소비량 (무관: 기력, 문관: 학식)
@export var stamina_gain: int = 0   # 클래스 고유 자원 획득량

# 문관 전용 특수 효과
@export var consume_all_resource: bool = false  # 학식 전량 소비 (상소)
@export var resource_damage_multiplier: int = 0  # 소비 학식당 피해 배수
@export var min_resource_damage: int = 0  # 최소 피해 (학식 0일 때)
@export var cost_reduce_next: int = 0  # 다음 카드 비용 감소 (격물치지)
@export var conditional_resource_gain: int = 0  # 조건부 자원 획득량 (피화)
@export var conditional_resource_threshold: int = 0  # 조건 충족 기준 (시조 슬롯 수)
@export var optional_resource_cost: int = 0  # 선택적 자원 소비 (탄핵: 학식 있으면 소비하여 추가 효과)
@export var apply_debuff_on_resource: String = ""  # 선택적 자원 소비 시 부여할 디버프 (탄핵 등)
@export var debuff_duration: int = 0  # 디버프 지속 턴


static func from_dict(data: Dictionary, card_pool: String) -> CardData:
	var card := CardData.new()
	card.id = data.get("id", "")

	var name_data = data.get("name", {})
	if name_data is Dictionary:
		card.name_ko = name_data.get("ko", "")
		card.name_hanja = name_data.get("hanja", "")
		card.name_romanized = name_data.get("romanized", "")
	elif name_data is String:
		card.name_ko = name_data

	card.beat = data.get("beat", 3)
	card.cost = data.get("cost", 1)
	card.type = data.get("type", "")

	var st = data.get("subtypes", [])
	if st is Array:
		for s in st:
			card.subtypes.append(str(s))

	card.rarity = data.get("rarity", 1)
	card.pool = card_pool
	card.effect = data.get("effect", "")
	card.effect_upgraded = data.get("effect_upgraded", "")
	card.flavor_text = data.get("flavor_text", "")
	card.upgrade_cost = data.get("upgrade_cost", 75)

	var values = data.get("values", {})
	if values is Dictionary:
		card.damage = values.get("damage", 0)
		card.block_value = values.get("block", 0)
		card.draw_count = values.get("draw", 0)
		card.qi_gain = values.get("qi_gain", 0)
		card.is_aoe = values.get("is_aoe", false)
		card.tokens = values.get("tokens", 0)
		card.stamina_cost = values.get("stamina_cost", 0)
		card.stamina_gain = values.get("stamina_gain", 0)

		# 문관 전용: 학식 관련 값도 stamina로 매핑
		if values.has("hakshik_cost"):
			card.stamina_cost = values.get("hakshik_cost", 0)
		if values.has("hakshik_gain"):
			card.stamina_gain = values.get("hakshik_gain", 0)

		# 문관 전용 특수 효과
		card.consume_all_resource = values.get("consume_all_resource", false)
		card.resource_damage_multiplier = values.get("damage_per_hakshik", 0)
		card.min_resource_damage = values.get("min_damage", 0)
		card.cost_reduce_next = values.get("cost_reduce_next", 0)
		card.conditional_resource_gain = values.get("hakshik_gain_conditional", 0)
		card.conditional_resource_threshold = values.get("conditional_threshold", 3)
		card.optional_resource_cost = values.get("optional_resource_cost", 0)
		card.apply_debuff_on_resource = values.get("apply_debuff_on_resource", "")
		card.debuff_duration = values.get("debuff_duration", 0)

	return card


func get_display_name() -> String:
	if name_hanja != "":
		return "%s(%s)" % [name_ko, name_hanja]
	return name_ko


func get_current_effect() -> String:
	if upgraded and effect_upgraded != "":
		return effect_upgraded
	return effect


func duplicate_card() -> CardData:
	var copy := CardData.new()
	copy.id = id
	copy.name_ko = name_ko
	copy.name_hanja = name_hanja
	copy.name_romanized = name_romanized
	copy.beat = beat
	copy.cost = cost
	copy.type = type
	copy.subtypes = subtypes.duplicate()
	copy.rarity = rarity
	copy.pool = pool
	copy.effect = effect
	copy.effect_upgraded = effect_upgraded
	copy.flavor_text = flavor_text
	copy.upgrade_cost = upgrade_cost
	copy.upgraded = upgraded
	copy.damage = damage
	copy.block_value = block_value
	copy.draw_count = draw_count
	copy.qi_gain = qi_gain
	copy.is_aoe = is_aoe
	copy.tokens = tokens
	copy.stamina_cost = stamina_cost
	copy.stamina_gain = stamina_gain
	copy.consume_all_resource = consume_all_resource
	copy.resource_damage_multiplier = resource_damage_multiplier
	copy.min_resource_damage = min_resource_damage
	copy.cost_reduce_next = cost_reduce_next
	copy.conditional_resource_gain = conditional_resource_gain
	copy.conditional_resource_threshold = conditional_resource_threshold
	copy.optional_resource_cost = optional_resource_cost
	copy.apply_debuff_on_resource = apply_debuff_on_resource
	copy.debuff_duration = debuff_duration
	return copy
