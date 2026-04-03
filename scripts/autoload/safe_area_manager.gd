extends Node

## Safe area 관리 오토로드.
## 모바일 기기의 노치, 시스템 바 영역을 감지하여 UI 컨트롤에 여백을 자동 적용한다.
## 각 씬의 루트 Control 직계 자식 중 배경(ColorRect/TextureRect)이 아닌
## 컨트롤 노드에 safe area 오프셋을 추가한다.

## 앵커가 화면 가장자리에 근접한 것으로 판단하는 임계값.
## 예: anchor_top < 0.12 이면 상단 가장자리 근처로 간주.
const EDGE_THRESHOLD := 0.12

## 모바일에서 safe area 보고가 지연될 때 최대 재시도 횟수
const MAX_RETRY := 3

## 뷰포트 좌표 기준 safe area 마진 (픽셀)
var margin_top: float = 0.0
var margin_bottom: float = 0.0
var margin_left: float = 0.0
var margin_right: float = 0.0


func _ready() -> void:
	# AccessibilityManager의 DPI 스케일링 적용 후 마진을 계산하기 위해 1프레임 대기
	get_tree().process_frame.connect(_deferred_init, CONNECT_ONE_SHOT)


func _deferred_init() -> void:
	_calculate_margins()
	# 모바일에서 OS가 safe area를 아직 보고하지 않았을 수 있으므로 재시도
	if _has_no_margins() and _is_mobile():
		for i in MAX_RETRY:
			await get_tree().create_timer(0.3 * (i + 1)).timeout
			_calculate_margins()
			if not _has_no_margins():
				break
	apply_to_current_scene()
	# 화면 크기 변경 시 마진 재계산 (방향 전환 등)
	get_tree().get_root().size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	_calculate_margins()
	apply_to_current_scene()


func _calculate_margins() -> void:
	## DisplayServer의 safe area 정보를 뷰포트 좌표로 변환한다.
	var screen_size := DisplayServer.screen_get_size()
	var window_size := DisplayServer.window_get_size()
	var safe_rect := DisplayServer.get_display_safe_area()

	print("[SafeAreaManager] 진단: OS=%s, screen=%s, window=%s, safe_rect=%s" % [
		OS.get_name(), screen_size, window_size, safe_rect])

	# 참조 크기 결정: safe_rect는 스크린 좌표 또는 윈도우 좌표일 수 있음
	# safe_rect.end가 window_size 이하이면 윈도우 좌표 기준으로 판단
	var ref_size := screen_size
	if window_size.x > 0 and window_size.y > 0:
		if safe_rect.end.x <= window_size.x and safe_rect.end.y <= window_size.y:
			ref_size = window_size
		elif safe_rect.end.x <= screen_size.x and safe_rect.end.y <= screen_size.y:
			ref_size = screen_size

	if ref_size.x <= 0 or ref_size.y <= 0:
		return

	# safe area가 전체 화면과 동일하면 마진 불필요 (데스크톱 등)
	var is_full_screen := (safe_rect.position == Vector2i.ZERO and safe_rect.size == ref_size)
	var is_full_screen_alt := (safe_rect.position == Vector2i.ZERO and safe_rect.size == screen_size)
	if is_full_screen or is_full_screen_alt:
		if _is_mobile():
			print("[SafeAreaManager] safe area == 전체 화면 (OS 미보고 가능성)")
		return

	# 뷰포트 크기 (stretch mode 적용 후)
	var viewport_size := get_viewport().get_visible_rect().size

	# 비율 기반으로 스크린/윈도우 좌표 → 뷰포트 좌표 변환
	margin_top = float(safe_rect.position.y) / float(ref_size.y) * viewport_size.y
	margin_bottom = float(ref_size.y - safe_rect.end.y) / float(ref_size.y) * viewport_size.y
	margin_left = float(safe_rect.position.x) / float(ref_size.x) * viewport_size.x
	margin_right = float(ref_size.x - safe_rect.end.x) / float(ref_size.x) * viewport_size.x

	# 음수 마진 방지 (좌표계 불일치 시)
	margin_top = maxf(margin_top, 0.0)
	margin_bottom = maxf(margin_bottom, 0.0)
	margin_left = maxf(margin_left, 0.0)
	margin_right = maxf(margin_right, 0.0)

	if not _has_no_margins():
		print("[SafeAreaManager] 마진 적용: top=%.0f, bottom=%.0f, left=%.0f, right=%.0f (뷰포트 px)" % [margin_top, margin_bottom, margin_left, margin_right])


func apply_to_current_scene() -> void:
	## 현재 활성 씬의 루트에 safe area 마진을 적용한다.
	## GameManager에서 씬 전환 후 호출하거나, 초기 씬 로드 시 자동 호출된다.
	var scene := get_tree().current_scene
	if scene is Control:
		_apply_to_scene(scene)


func _apply_to_scene(scene: Control) -> void:
	## 씬 루트의 직계 자식 컨트롤에 safe area 오프셋을 추가한다.
	## ColorRect/TextureRect(배경)는 전체 화면을 유지하므로 건너뛴다.
	if not is_instance_valid(scene):
		return

	for child in scene.get_children():
		if child is not Control:
			continue
		# 배경 노드는 전체 화면 유지
		if child is ColorRect or child is TextureRect:
			continue
		# 마진이 0이고 이전 적용도 없으면 건너뜀
		if _has_no_margins() and not child.has_meta("_safe_area_applied"):
			continue
		_apply_margins_to_node(child)


func _apply_margins_to_node(node: Control) -> void:
	## 노드의 앵커 위치를 기준으로 가장자리에 근접한 방향에 safe area 오프셋을 추가한다.
	## 이미 적용된 노드는 이전 마진을 되돌린 뒤 새 마진을 적용한다.
	if node.has_meta("_safe_area_applied"):
		# 이전에 적용한 마진을 되돌림
		var prev: Dictionary = node.get_meta("_safe_area_applied")
		node.offset_top -= prev.get("top", 0.0)
		node.offset_bottom += prev.get("bottom", 0.0)
		node.offset_left -= prev.get("left", 0.0)
		node.offset_right += prev.get("right", 0.0)

	var applied := {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}

	if node.anchor_top < EDGE_THRESHOLD:
		node.offset_top += margin_top
		applied["top"] = margin_top
	if node.anchor_bottom > (1.0 - EDGE_THRESHOLD):
		node.offset_bottom -= margin_bottom
		applied["bottom"] = margin_bottom
	if node.anchor_left < EDGE_THRESHOLD:
		node.offset_left += margin_left
		applied["left"] = margin_left
	if node.anchor_right > (1.0 - EDGE_THRESHOLD):
		node.offset_right -= margin_right
		applied["right"] = margin_right

	node.set_meta("_safe_area_applied", applied)


func _has_no_margins() -> bool:
	return margin_top == 0.0 and margin_bottom == 0.0 \
		and margin_left == 0.0 and margin_right == 0.0


func _is_mobile() -> bool:
	return OS.get_name() in ["Android", "iOS"]
