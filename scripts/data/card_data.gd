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
	return copy
