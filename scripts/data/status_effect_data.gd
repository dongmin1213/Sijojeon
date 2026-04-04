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
		"독", "독", "☠", Color(0.4, 0.8, 0.2), EffectType.DOT,
		"턴 시작 시 N 피해, 매 턴 1씩 감소", true, false
	)
	_registry["화상"] = StatusEffectData.new(
		"화상", "화상", "🔥", Color(1.0, 0.4, 0.1), EffectType.DOT,
		"턴 시작 시 N 피해, 매 턴 1씩 감소", true, false
	)
	_registry["출혈"] = StatusEffectData.new(
		"출혈", "출혈", "🩸", Color(0.8, 0.1, 0.1), EffectType.DOT,
		"턴 시작 시 N 피해, 매 턴 1씩 감소. 방어도 획득 시 피해 2배", true, false
	)
	_registry["death_mark"] = StatusEffectData.new(
		"death_mark", "사망표식", "💀", Color(0.5, 0.0, 0.5), EffectType.DOT,
		"매 턴 5 피해, 1씩 감소", true, false
	)

	# --- 디버프 ---
	_registry["약화"] = StatusEffectData.new(
		"약화", "약화", "⬇", Color(1.0, 0.6, 0.2), EffectType.DEBUFF,
		"다음 공격 피해 25% 감소", true, false
	)
	_registry["취약"] = StatusEffectData.new(
		"취약", "취약", "🔻", Color(1.0, 0.3, 0.3), EffectType.DEBUFF,
		"받는 피해 25% 증가", true, false
	)
	_registry["냉기"] = StatusEffectData.new(
		"냉기", "냉기", "❄", Color(0.5, 0.8, 1.0), EffectType.DEBUFF,
		"드로우 1장 감소", false, false
	)
	_registry["death_countdown"] = StatusEffectData.new(
		"death_countdown", "사망선고", "⏳", Color(0.3, 0.0, 0.3), EffectType.DEBUFF,
		"N턴 후 HP 50% 감소", true, false
	)

	# --- 버프 ---
	_registry["strength"] = StatusEffectData.new(
		"strength", "힘", "⚔", Color(1.0, 0.3, 0.3), EffectType.BUFF,
		"공격 피해 +N", false, true
	)
	_registry["thorns"] = StatusEffectData.new(
		"thorns", "가시", "🌹", Color(0.6, 0.3, 0.1), EffectType.BUFF,
		"피격 시 공격자에게 3 피해 반사", false, true
	)
	_registry["갑주"] = StatusEffectData.new(
		"갑주", "갑주", "🛡", Color(0.3, 0.6, 1.0), EffectType.BUFF,
		"턴 시작 시 사라지지 않는 방어막", false, true
	)
	_registry["병사_토큰"] = StatusEffectData.new(
		"병사_토큰", "병사", "⚑", Color(0.9, 0.7, 0.2), EffectType.BUFF,
		"무관 진형 토큰. 스택 수만큼 패시브/액티브 효과 적용", false, true
	)
	_registry["구금"] = StatusEffectData.new(
		"구금", "구금", "⛓", Color(0.6, 0.4, 0.2), EffectType.DEBUFF,
		"카드 사용 비용 +1. 지정 턴 수 후 해제", true, false
	)
	_registry["주박"] = StatusEffectData.new(
		"주박", "주박", "🔮", Color(0.5, 0.2, 0.7), EffectType.DEBUFF,
		"받는 DoT 피해 1.5배", true, false
	)
	_registry["기절"] = StatusEffectData.new(
		"기절", "기절", "💫", Color(1.0, 0.9, 0.3), EffectType.DEBUFF,
		"행동 불가. 턴 종료 시 해제", true, false
	)
