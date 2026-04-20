class_name CardData
extends Resource

## 카드 데이터 클래스. JSON에서 파싱된 카드 한 장의 정보.

@export var id: String = ""
@export var name_ko: String = ""
@export var name_en: String = ""
@export var name_hanja: String = ""
@export var name_romanized: String = ""
@export var cost: int = 1
@export var type: String = ""
@export var subtypes: Array[String] = []
@export var rarity: int = 1
@export var pool: String = ""  # "common", "dosa", "mugwan"
@export var effect: String = ""
@export var effect_en: String = ""
@export var effect_upgraded: String = ""
@export var effect_upgraded_en: String = ""
@export var flavor_text: String = ""
@export var flavor_text_en: String = ""
@export var upgrade_cost: int = 75
@export var upgraded: bool = false

# 구조화된 효과 수치
@export var damage: int = 0
@export var block_value: int = 0
@export var draw_count: int = 0
@export var qi_gain: int = 0
@export var is_aoe: bool = false
@export var burn_stacks: int = 0  # 화상 부여 스택
@export var poison_stacks: int = 0  # 독 부여 스택
@export var bonus_on_burn: int = 0  # 대상 화상≥2 시 추가 피해 (흑염 D017)
@export var bonus_on_poison: int = 0  # 대상 독≥2 시 추가 피해 (흑염 D017)
@export var vulnerable_stacks: int = 0  # 취약 부여 스택
@export var weaken_stacks: int = 0  # 약화 부여 스택 (후퇴 M003 등)
@export var remove_buffs: bool = false  # 적 버프 제거 여부 (파직 W018 등)



static func from_dict(data: Dictionary, card_pool: String) -> CardData:
	var card := CardData.new()
	card.id = data.get("id", "")

	var name_data = data.get("name", {})
	if name_data is Dictionary:
		card.name_ko = name_data.get("ko", "")
		card.name_en = name_data.get("en", "")
		card.name_hanja = name_data.get("hanja", "")
		card.name_romanized = name_data.get("romanized", "")
	elif name_data is String:
		card.name_ko = name_data

	card.cost = data.get("cost", 1)
	card.type = data.get("type", "")

	var st = data.get("subtypes", [])
	if st is Array:
		for s in st:
			card.subtypes.append(str(s))

	card.rarity = data.get("rarity", 1)
	card.pool = card_pool

	# 다국어 텍스트 필드 파싱 (Dictionary 또는 String)
	var effect_data = data.get("effect", "")
	if effect_data is Dictionary:
		card.effect = effect_data.get("ko", "")
		card.effect_en = effect_data.get("en", "")
	else:
		card.effect = str(effect_data) if effect_data else ""

	var effect_up_data = data.get("effect_upgraded", "")
	if effect_up_data is Dictionary:
		card.effect_upgraded = effect_up_data.get("ko", "")
		card.effect_upgraded_en = effect_up_data.get("en", "")
	else:
		card.effect_upgraded = str(effect_up_data) if effect_up_data else ""

	var flavor_data = data.get("flavor_text", "")
	if flavor_data is Dictionary:
		card.flavor_text = flavor_data.get("ko", "")
		card.flavor_text_en = flavor_data.get("en", "")
	else:
		card.flavor_text = str(flavor_data) if flavor_data else ""
	card.upgrade_cost = data.get("upgrade_cost", 75)

	var values = data.get("values", {})
	if values is Dictionary:
		card.damage = values.get("damage", 0)
		card.block_value = values.get("block", 0)
		card.draw_count = values.get("draw", 0)
		card.qi_gain = values.get("qi_gain", 0)
		card.is_aoe = values.get("is_aoe", false)
		card.burn_stacks = values.get("burn", 0)
		card.poison_stacks = values.get("poison", 0)
		card.bonus_on_burn = values.get("bonus_on_burn", 0)
		card.bonus_on_poison = values.get("bonus_on_poison", 0)
		card.vulnerable_stacks = values.get("vulnerable", 0)
		card.weaken_stacks = values.get("weaken", 0)
		card.remove_buffs = bool(values.get("remove_buffs", false))

	return card


func get_display_name() -> String:
	var locale := TranslationServer.get_locale()
	if locale == "en" and name_en != "":
		return name_en
	if locale == "en" and name_romanized != "":
		return name_romanized
	if name_hanja != "":
		return "%s(%s)" % [name_ko, name_hanja]
	return name_ko


func get_current_effect() -> String:
	var locale := TranslationServer.get_locale()
	if locale == "en":
		if upgraded and effect_upgraded_en != "":
			return effect_upgraded_en
		if effect_en != "":
			return effect_en
	if upgraded and effect_upgraded != "":
		return effect_upgraded
	return effect


func get_flavor_text() -> String:
	var locale := TranslationServer.get_locale()
	if locale == "en" and flavor_text_en != "":
		return flavor_text_en
	return flavor_text


func duplicate_card() -> CardData:
	var copy := CardData.new()
	copy.id = id
	copy.name_ko = name_ko
	copy.name_en = name_en
	copy.name_hanja = name_hanja
	copy.name_romanized = name_romanized
	copy.cost = cost
	copy.type = type
	copy.subtypes = subtypes.duplicate()
	copy.rarity = rarity
	copy.pool = pool
	copy.effect = effect
	copy.effect_en = effect_en
	copy.effect_upgraded = effect_upgraded
	copy.effect_upgraded_en = effect_upgraded_en
	copy.flavor_text = flavor_text
	copy.flavor_text_en = flavor_text_en
	copy.upgrade_cost = upgrade_cost
	copy.upgraded = upgraded
	copy.damage = damage
	copy.block_value = block_value
	copy.draw_count = draw_count
	copy.qi_gain = qi_gain
	copy.is_aoe = is_aoe
	copy.burn_stacks = burn_stacks
	copy.poison_stacks = poison_stacks
	copy.bonus_on_burn = bonus_on_burn
	copy.bonus_on_poison = bonus_on_poison
	copy.vulnerable_stacks = vulnerable_stacks
	copy.weaken_stacks = weaken_stacks
	copy.remove_buffs = remove_buffs
	return copy
