extends Node

## 접근성 관리 오토로드.
## 글자 크기 배율, 색맹 모드, DPI 기반 스케일링을 전역으로 관리한다.

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

## 기준 DPI (안드로이드 mdpi). 이 값 대비 실제 DPI 비율로 스케일 계산.
const BASE_DPI := 160.0
## 뷰포트 기준 너비 (project.godot의 viewport_width)
const DESIGN_WIDTH := 1080.0
## 최소/최대 DPI 스케일 팩터
const MIN_DPI_SCALE := 1.0
const MAX_DPI_SCALE := 2.0

## 현재 글자 크기 배율 (0.8 ~ 1.5) — 사용자 설정
var font_scale: float = 1.0
## DPI 기반 자동 스케일 팩터 — 디바이스에 따라 자동 결정
var dpi_scale: float = 1.0
## 현재 색맹 모드
var colorblind_mode: int = ColorblindMode.NONE
## 화면 흔들림 활성화 여부
var screen_shake_enabled: bool = true


func _ready() -> void:
	# DPI 기반 콘텐츠 스케일 적용
	_apply_dpi_scaling()

	var settings := SaveManager.load_settings()
	font_scale = settings.get("font_size_scale", 1.0)
	colorblind_mode = settings.get("colorblind_mode", 0)
	screen_shake_enabled = settings.get("screen_shake_enabled", true)
	if colorblind_mode != ColorblindMode.NONE:
		_apply_colorblind_shader(colorblind_mode)


func _apply_dpi_scaling() -> void:
	## 화면 DPI를 감지하여 content_scale_factor를 조정한다.
	## 소형/고밀도 화면에서 UI가 너무 작아지는 문제를 해결.
	var screen_dpi := DisplayServer.screen_get_dpi()
	if screen_dpi <= 0:
		screen_dpi = 160  # 감지 실패 시 기본값

	# 화면 물리 너비(dp) 계산: 픽셀 너비 / (DPI / 160)
	var screen_size := DisplayServer.screen_get_size()
	var density := float(screen_dpi) / BASE_DPI
	var screen_width_dp := float(screen_size.x) / density

	# 화면이 작을수록 스케일을 높여 UI를 키운다.
	# 기준: 물리 너비 360dp 이하이면 스케일 업 필요
	# 뷰포트 1080px / 실제 dp 너비 = 논리 밀도. 360dp 기준으로 1.0
	var ideal_scale := 1.0
	if screen_width_dp < 400.0:
		# 소형 화면: 스케일 업 (360dp 폴더블 → ~1.2배)
		ideal_scale = 400.0 / screen_width_dp
	elif screen_width_dp > 600.0:
		# 태블릿/대형 화면: 스케일 다운 방지, 유지
		ideal_scale = 1.0

	# 고DPI 기기(density > 2.0)에서 UI가 물리적으로 너무 작아지는 문제 보정
	# density 2.0 → factor 1.0, density 3.0 → factor 1.3 (선형 보간)
	if density > 2.0:
		var high_dpi_factor := lerpf(1.0, 1.3, (density - 2.0) / 1.0)
		high_dpi_factor = clampf(high_dpi_factor, 1.0, 1.5)
		ideal_scale = maxf(ideal_scale, high_dpi_factor)

	dpi_scale = clampf(ideal_scale, MIN_DPI_SCALE, MAX_DPI_SCALE)

	if dpi_scale > 1.0:
		# 터치 좌표 불일치 방지: content_scale_factor 적용 시 하단 버튼 터치 불가 문제 발생
		# 대신 뷰포트 크기를 직접 조정하여 동일 효과 달성
		#get_window().content_scale_factor = dpi_scale
		print("[AccessibilityManager] DPI 스케일 감지: %.2f (DPI=%d, density=%.1f, 화면폭=%ddp) — content_scale_factor 미적용" % [dpi_scale, screen_dpi, density, int(screen_width_dp)])


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
	# v5: 오방색 팔레트 — card_ui.gd TYPE_COLORS와 동기화
	return {
		"attack": Color(0.76, 0.23, 0.13),    # 적 (#C23B22)
		"defense": Color(0.18, 0.31, 0.56),   # 청 (#2E5090)
		"spell": Color(0.18, 0.31, 0.56),     # 청 (도사)
		"movement": Color(0.23, 0.49, 0.27),  # 송록
		"formation": Color(0.76, 0.23, 0.13), # 황 (#D4A017)
	}


func _protanopia_colors() -> Dictionary:
	## 적녹색맹용 — 빨강/초록을 파랑/노랑 대비로 교체
	return {
		"attack": Color(0.76, 0.23, 0.13),    # 주황
		"defense": Color(0.2, 0.4, 0.9),   # 파랑
		"spell": Color(0.1, 0.5, 0.7),     # 틸 (보라 제거)
		"movement": Color(0.1, 0.7, 0.9),  # 시안
		"formation": Color(0.96, 0.94, 0.91), # 노랑
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
