class_name StatusEffectData
extends RefCounted

## 상태이상 정의 데이터 클래스.
## 각 상태이상의 메타데이터(이름, 타입, 아이콘, 색상 등)를 정의한다.

enum EffectType {
	BUFF,       # 긍정 효과
	DEBUFF,     # 부정 효과
	DOT,        # 지속 피해 (Damage over Time)
}

var id: String
var name_ko: String
var icon_text: String        # 간략 아이콘 텍스트 (예: "🔥", "☠")
var color: Color             # UI 표시 색상
var type: EffectType
var description: String
var show_duration: bool      # 턴 카운터 표시 여부
var is_permanent: bool       # 영구 효과 여부 (strength 등)


func _init(p_id: String = "", p_name: String = "", p_icon: String = "",
		p_color: Color = Color.WHITE, p_type: EffectType = EffectType.DEBUFF,
		p_desc: String = "", p_show_duration: bool = true,
		p_is_permanent: bool = false) -> void:
	id = p_id
	name_ko = p_name
	icon_text = p_icon
	color = p_color
	type = p_type
	description = p_desc
	show_duration = p_show_duration
	is_permanent = p_is_permanent


## 전체 상태이상 정의 레지스트리
static var _registry: Dictionary = {}


static func get_definition(effect_id: String) -> StatusEffectData:
	if _registry.is_empty():
		_init_registry()
	return _registry.get(effect_id, null)


static func get_all_definitions() -> Dictionary:
	if _registry.is_empty():
		_init_registry()
	return _registry


static func _init_registry() -> void:
	# --- DoT (지속 피해) ---
	_registry["독"] = StatusEffectData.new(
		"독", TranslationServer.translate("STATUS_POISON"), "☠", Color(0.4, 0.8, 0.2), EffectType.DOT,
		TranslationServer.translate("SE_DESC_POISON"), true, false
	)
	_registry["화상"] = StatusEffectData.new(
		"화상", TranslationServer.translate("STATUS_BURN"), "🔥", Color(1.0, 0.4, 0.1), EffectType.DOT,
		TranslationServer.translate("SE_DESC_BURN"), true, false
	)
	_registry["출혈"] = StatusEffectData.new(
		"출혈", TranslationServer.translate("SE_NAME_BLEED"), "🩸", Color(0.8, 0.1, 0.1), EffectType.DOT,
		TranslationServer.translate("SE_DESC_BLEED"), true, false
	)
	_registry["death_mark"] = StatusEffectData.new(
		"death_mark", TranslationServer.translate("SE_NAME_DEATH_MARK"), "💀", Color(0.5, 0.0, 0.5), EffectType.DOT,
		TranslationServer.translate("SE_DESC_DEATH_MARK"), true, false
	)

	# --- 디버프 ---
	_registry["약화"] = StatusEffectData.new(
		"약화", TranslationServer.translate("STATUS_WEAKEN"), "⬇", Color(1.0, 0.6, 0.2), EffectType.DEBUFF,
		TranslationServer.translate("SE_DESC_WEAKEN"), true, false
	)
	_registry["취약"] = StatusEffectData.new(
		"취약", TranslationServer.translate("STATUS_VULNERABLE"), "🔻", Color(1.0, 0.3, 0.3), EffectType.DEBUFF,
		TranslationServer.translate("SE_DESC_VULNERABLE"), true, false
	)
	_registry["냉기"] = StatusEffectData.new(
		"냉기", TranslationServer.translate("SE_NAME_CHILL"), "❄", Color(0.5, 0.8, 1.0), EffectType.DEBUFF,
		TranslationServer.translate("SE_DESC_CHILL"), false, false
	)
	_registry["death_countdown"] = StatusEffectData.new(
		"death_countdown", TranslationServer.translate("SE_NAME_DEATH_COUNTDOWN"), "⏳", Color(0.3, 0.0, 0.3), EffectType.DEBUFF,
		TranslationServer.translate("SE_DESC_DEATH_COUNTDOWN"), true, false
	)

	# --- 버프 ---
	_registry["strength"] = StatusEffectData.new(
		"strength", TranslationServer.translate("STATUS_STRENGTH"), "⚔", Color(1.0, 0.3, 0.3), EffectType.BUFF,
		TranslationServer.translate("SE_DESC_STRENGTH"), false, true
	)
	_registry["thorns"] = StatusEffectData.new(
		"thorns", TranslationServer.translate("SE_NAME_THORNS"), "🌹", Color(0.6, 0.3, 0.1), EffectType.BUFF,
		TranslationServer.translate("SE_DESC_THORNS"), false, true
	)
	_registry["갑주"] = StatusEffectData.new(
		"갑주", TranslationServer.translate("SE_NAME_ARMOR"), "🛡", Color(0.3, 0.6, 1.0), EffectType.BUFF,
		TranslationServer.translate("SE_DESC_ARMOR"), false, true
	)
	_registry["병사_토큰"] = StatusEffectData.new(
		"병사_토큰", TranslationServer.translate("SE_NAME_SOLDIER_TOKEN"), "⚑", Color(0.9, 0.7, 0.2), EffectType.BUFF,
		TranslationServer.translate("SE_DESC_SOLDIER_TOKEN"), false, true
	)
	_registry["구금"] = StatusEffectData.new(
		"구금", TranslationServer.translate("SE_NAME_DETENTION"), "⛓", Color(0.6, 0.4, 0.2), EffectType.DEBUFF,
		TranslationServer.translate("SE_DESC_DETENTION"), true, false
	)
	_registry["주박"] = StatusEffectData.new(
		"주박", TranslationServer.translate("SE_NAME_SHACKLE"), "🔮", Color(0.5, 0.2, 0.7), EffectType.DEBUFF,
		TranslationServer.translate("SE_DESC_SHACKLE"), true, false
	)
	_registry["기절"] = StatusEffectData.new(
		"기절", TranslationServer.translate("STATUS_STUN"), "💫", Color(1.0, 0.9, 0.3), EffectType.DEBUFF,
		TranslationServer.translate("SE_DESC_STUN"), true, false
	)
	_registry["허점_노출"] = StatusEffectData.new(
		"허점_노출", TranslationServer.translate("SE_NAME_WEAKNESS_EXPOSED"), "🎯", Color(1.0, 0.2, 0.4), EffectType.DEBUFF,
		TranslationServer.translate("SE_DESC_WEAKNESS_EXPOSED"), true, false
	)
	_registry["폭발_카운트다운"] = StatusEffectData.new(
		"폭발_카운트다운", TranslationServer.translate("SE_NAME_EXPLOSION"), "💣", Color(1.0, 0.5, 0.0), EffectType.DEBUFF,
		TranslationServer.translate("SE_DESC_EXPLOSION"), true, false
	)
	_registry["반격"] = StatusEffectData.new(
		"반격", TranslationServer.translate("SE_NAME_COUNTER"), "🔄", Color(0.8, 0.4, 0.1), EffectType.BUFF,
		TranslationServer.translate("SE_DESC_COUNTER"), false, true
	)
