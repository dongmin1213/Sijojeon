extends Node

## 접근성 관리 오토로드.
## 글자 크기 배율과 색맹 모드를 전역으로 관리한다.

## 글자 크기 변경 시 emit. UI가 이 시그널을 받아 폰트 크기를 재적용한다.
signal font_scale_changed(scale: float)
## 색맹 모드 변경 시 emit.
signal colorblind_mode_changed(mode: int)

## 색맹 모드 상수
enum ColorblindMode {
	NONE = 0,       ## 없음
	PROTANOPIA = 1, ## 적녹색맹
	TRITANOPIA = 2, ## 청황색맹
}

## 현재 글자 크기 배율 (0.8 ~ 1.5)
var font_scale: float = 1.0
## 현재 색맹 모드
var colorblind_mode: int = ColorblindMode.NONE
## 화면 흔들림 활성화 여부
var screen_shake_enabled: bool = true


func _ready() -> void:
	var settings := SaveManager.load_settings()
	font_scale = settings.get("font_size_scale", 1.0)
	colorblind_mode = settings.get("colorblind_mode", 0)
	screen_shake_enabled = settings.get("screen_shake_enabled", true)
	if colorblind_mode != ColorblindMode.NONE:
		_apply_colorblind_shader(colorblind_mode)


func set_font_scale(scale: float) -> void:
	font_scale = clampf(scale, 0.8, 1.5)
	font_scale_changed.emit(font_scale)


func set_colorblind_mode(mode: int) -> void:
	colorblind_mode = mode
	_apply_colorblind_shader(mode)
	colorblind_mode_changed.emit(mode)


func set_screen_shake_enabled(enabled: bool) -> void:
	screen_shake_enabled = enabled


func scaled_font_size(base_size: int) -> int:
	## base_size에 현재 배율을 적용한 폰트 크기를 반환한다.
	return int(base_size * font_scale)


func get_type_color(card_type: String) -> Color:
	## 카드 타입 색상을 색맹 모드에 맞게 반환한다.
	match colorblind_mode:
		ColorblindMode.PROTANOPIA:
			return _protanopia_colors().get(card_type, Color.WHITE)
		ColorblindMode.TRITANOPIA:
			return _tritanopia_colors().get(card_type, Color.WHITE)
		_:
			return _default_colors().get(card_type, Color.WHITE)


func _default_colors() -> Dictionary:
	return {
		"attack": Color(0.85, 0.25, 0.2),
		"defense": Color(0.2, 0.55, 0.85),
		"spell": Color(0.6, 0.3, 0.85),
		"movement": Color(0.2, 0.75, 0.45),
		"formation": Color(0.85, 0.65, 0.15),
	}


func _protanopia_colors() -> Dictionary:
	## 적녹색맹용 — 빨강/초록을 파랑/노랑 대비로 교체
	return {
		"attack": Color(0.9, 0.6, 0.1),    # 주황
		"defense": Color(0.2, 0.4, 0.9),   # 파랑
		"spell": Color(0.7, 0.3, 0.9),     # 보라
		"movement": Color(0.1, 0.7, 0.9),  # 시안
		"formation": Color(0.9, 0.85, 0.2), # 노랑
	}


func _tritanopia_colors() -> Dictionary:
	## 청황색맹용 — 파랑/노랑을 빨강/초록 대비로 교체
	return {
		"attack": Color(0.9, 0.2, 0.3),    # 빨강
		"defense": Color(0.3, 0.8, 0.4),   # 초록
		"spell": Color(0.8, 0.3, 0.6),     # 분홍
		"movement": Color(0.2, 0.6, 0.5),  # 틸
		"formation": Color(0.9, 0.5, 0.2), # 주황
	}


func _apply_colorblind_shader(mode: int) -> void:
	## 색맹 모드에 따라 월드 환경 셰이더를 적용한다.
	## 현재는 색상 팔레트 교체 방식을 사용 (셰이더 없이 코드 레벨).
	## 향후 포스트 프로세싱 셰이더로 확장 가능.
	pass
