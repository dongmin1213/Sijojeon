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
		"death_mark", TranslationServer.translate("SE_NAME_DEATH_MARK"), "💀", Color(0.50, 0.10, 0.10), EffectType.DOT,
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
		"death_countdown", TranslationServer.translate("SE_NAME_DEATH_COUNTDOWN"), "⏳", Color(0.30, 0.08, 0.08), EffectType.DEBUFF,
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
	_registry["구금"] = StatusEffectData.new(
		"구금", TranslationServer.translate("SE_NAME_DETENTION"), "⛓", Color(0.6, 0.4, 0.2), EffectType.DEBUFF,
		TranslationServer.translate("SE_DESC_DETENTION"), true, false
	)
	_registry["주박"] = StatusEffectData.new(
		"주박", TranslationServer.translate("SE_NAME_SHACKLE"), "🔮", Color(0.18, 0.31, 0.56), EffectType.DEBUFF,
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

	# --- StS 핵심 상태이상 (누락분 추가) ---
	_registry["dexterity"] = StatusEffectData.new(
		"dexterity", "민첩", "🏃", Color(0.3, 0.9, 0.3), EffectType.BUFF,
		"민첩 수치만큼 방어도 카드 사용 시 추가 방어도를 획득한다.", false, true
	)
	_registry["허약"] = StatusEffectData.new(
		"허약", "허약", "🦴", Color(0.6, 0.5, 0.3), EffectType.DEBUFF,
		"허약 상태에서는 방어도 카드의 방어도가 25% 감소한다.", true, false
	)
	_registry["artifact"] = StatusEffectData.new(
		"artifact", "신물", "✨", Color(1.0, 0.84, 0.0), EffectType.BUFF,
		"디버프를 받을 때 신물 1을 소모하여 디버프를 무효화한다.", false, false
	)
	_registry["intangible"] = StatusEffectData.new(
		"intangible", "무형", "👻", Color(0.7, 0.7, 1.0), EffectType.BUFF,
		"받는 피해와 HP 손실이 1로 감소한다.", true, false
	)
	_registry["regeneration"] = StatusEffectData.new(
		"regeneration", "재생", "💚", Color(0.2, 0.8, 0.4), EffectType.BUFF,
		"턴 종료 시 재생 수치만큼 HP를 회복하고 재생이 1 감소한다.", true, false
	)
	_registry["ritual"] = StatusEffectData.new(
		"ritual", "의식", "🕯", Color(0.8, 0.2, 0.5), EffectType.BUFF,
		"턴 종료 시 의식 수치만큼 힘을 획득한다.", false, true
	)
	_registry["metallicize"] = StatusEffectData.new(
		"metallicize", "금속화", "⛏", Color(0.6, 0.6, 0.7), EffectType.BUFF,
		"턴 종료 시 방어도를 수치만큼 획득한다.", false, true
	)
	_registry["barricade"] = StatusEffectData.new(
		"barricade", "보루", "🏰", Color(0.4, 0.4, 0.8), EffectType.BUFF,
		"방어도가 턴 종료 시 사라지지 않는다.", false, true
	)
	_registry["no_draw"] = StatusEffectData.new(
		"no_draw", "드로우 불가", "🚫", Color(0.5, 0.5, 0.5), EffectType.DEBUFF,
		"다음 턴에 카드를 드로우할 수 없다.", true, false
	)
	_registry["entangle"] = StatusEffectData.new(
		"entangle", "속박", "🕸", Color(0.4, 0.3, 0.2), EffectType.DEBUFF,
		"이번 턴에 공격 카드를 사용할 수 없다.", true, false
	)
