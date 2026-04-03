extends Node

## Safe area 관리 오토로드.
## 모바일 기기의 노치, 시스템 바 영역을 감지하여 UI 컨트롤에 여백을 자동 적용한다.
## 각 씬의 루트 Control 직계 자식 중 배경(ColorRect/TextureRect)이 아닌
## 컨트롤 노드에 safe area 오프셋을 추가한다.

## 앵커가 화면 가장자리에 근접한 것으로 판단하는 임계값.
## 예: anchor_top < 0.12 이면 상단 가장자리 근처로 간주.
const EDGE_THRESHOLD := 0.12

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
	apply_to_current_scene()


func _calculate_margins() -> void:
	## DisplayServer의 safe area 정보를 뷰포트 좌표로 변환한다.
	var screen_size := DisplayServer.screen_get_size()
	if screen_size.x <= 0 or screen_size.y <= 0:
		return

	var safe_rect := DisplayServer.get_display_safe_area()

	# safe area가 전체 화면과 동일하면 마진 불필요 (데스크톱 등)
	if safe_rect.position == Vector2i.ZERO and safe_rect.size == screen_size:
		return

	# 뷰포트 크기 (stretch mode 적용 후)
	var viewport_size := get_viewport().get_visible_rect().size

	# 비율 기반으로 스크린 좌표 → 뷰포트 좌표 변환
	margin_top = float(safe_rect.position.y) / float(screen_size.y) * viewport_size.y
	margin_bottom = float(screen_size.y - safe_rect.end.y) / float(screen_size.y) * viewport_size.y
	margin_left = float(safe_rect.position.x) / float(screen_size.x) * viewport_size.x
	margin_right = float(screen_size.x - safe_rect.end.x) / float(screen_size.x) * viewport_size.x

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
	if _has_no_margins():
		return

	for child in scene.get_children():
		if child is not Control:
			continue
		# 배경 노드는 전체 화면 유지
		if child is ColorRect or child is TextureRect:
			continue
		_apply_margins_to_node(child)


func _apply_margins_to_node(node: Control) -> void:
	## 노드의 앵커 위치를 기준으로 가장자리에 근접한 방향에 safe area 오프셋을 추가한다.
	## 중복 적용 방지: 이미 적용된 노드는 건너뛴다.
	if node.has_meta("_safe_area_applied"):
		return
	node.set_meta("_safe_area_applied", true)

	if node.anchor_top < EDGE_THRESHOLD:
		node.offset_top += margin_top
	if node.anchor_bottom > (1.0 - EDGE_THRESHOLD):
		node.offset_bottom -= margin_bottom
	if node.anchor_left < EDGE_THRESHOLD:
		node.offset_left += margin_left
	if node.anchor_right > (1.0 - EDGE_THRESHOLD):
		node.offset_right -= margin_right


func _has_no_margins() -> bool:
	return margin_top == 0.0 and margin_bottom == 0.0 \
		and margin_left == 0.0 and margin_right == 0.0
