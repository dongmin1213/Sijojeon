extends Node

## 다국어 번역 관리 오토로드.
## TranslationServer 래핑 + 데이터 기반 텍스트 로케일 반환.

signal locale_changed(new_locale: String)

## 지원 로케일 목록
const SUPPORTED_LOCALES := ["ko", "en"]

## 기본 로케일
const DEFAULT_LOCALE := "ko"


func _ready() -> void:
	# 저장된 로케일 설정 복원
	var settings := SaveManager.load_settings()
	var saved_locale: String = settings.get("locale", DEFAULT_LOCALE)
	if saved_locale in SUPPORTED_LOCALES:
		TranslationServer.set_locale(saved_locale)
	else:
		TranslationServer.set_locale(DEFAULT_LOCALE)


func get_locale() -> String:
	## 현재 로케일 반환
	return TranslationServer.get_locale()


func set_locale(locale: String) -> void:
	## 로케일 변경 및 저장
	if locale not in SUPPORTED_LOCALES:
		push_warning("TranslationManager: 지원하지 않는 로케일 — %s" % locale)
		return
	TranslationServer.set_locale(locale)
	# 설정에 저장
	var settings := SaveManager.load_settings()
	settings["locale"] = locale
	SaveManager.save_settings(settings)
	locale_changed.emit(locale)


func trd(data: Dictionary, field: String, fallback: String = "") -> String:
	## 데이터 딕셔너리에서 현재 로케일에 맞는 텍스트를 반환.
	## JSON 데이터 구조: { "name": { "ko": "한글", "en": "English" } }
	## 또는 단순 필드: { "effect": "한글 텍스트" }
	var value = data.get(field, null)
	if value == null:
		return fallback
	# 딕셔너리 형태 (다국어 필드)
	if value is Dictionary:
		var locale := get_locale()
		if value.has(locale):
			return value[locale]
		# 폴백: 한국어 → 영어 → 첫 번째 값
		if value.has("ko"):
			return value["ko"]
		if value.has("en"):
			return value["en"]
		if not value.is_empty():
			return str(value.values()[0])
		return fallback
	# 문자열 형태 (아직 다국어 미지원 필드)
	if value is String:
		return value
	return fallback


func trd_name(data: Dictionary, _include_hanja: bool = false) -> String:
	## 이름 필드 전용 헬퍼. name.ko 또는 name.en 반환.
	var name_data = data.get("name", {})
	if not name_data is Dictionary:
		return str(name_data) if name_data else ""
	var locale := get_locale()
	if locale == "ko":
		return name_data.get("ko", "")
	# 영어 또는 기타 로케일
	if name_data.has(locale):
		return name_data[locale]
	# 로마자 폴백
	if name_data.has("romanized"):
		return name_data["romanized"]
	return name_data.get("ko", "")


func get_locale_index() -> int:
	## 현재 로케일의 SUPPORTED_LOCALES 내 인덱스 반환
	var locale := get_locale()
	var idx := SUPPORTED_LOCALES.find(locale)
	return idx if idx >= 0 else 0


func get_locale_display_name(locale: String) -> String:
	## 로케일 코드를 표시용 이름으로 변환
	match locale:
		"ko":
			return "한국어"
		"en":
			return "English"
		_:
			return locale
