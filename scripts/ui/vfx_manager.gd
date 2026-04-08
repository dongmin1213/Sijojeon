class_name VfxManager
extends Node

## 코드 기반 시각 효과(Game Juice) 유틸리티.
## 전투 씬에서 인스턴스화하여 사용한다. 아트 에셋 불필요.

## 화면 흔들림 — 루트 노드(전투 씬)의 position을 일시적으로 흔든다.
var _shake_target: Control = null
var _shake_intensity: float = 0.0
var _shake_decay: float = 8.0
var _original_position: Vector2 = Vector2.ZERO

## 오브젝트 풀 — Label/ColorRect 재사용으로 GC 부하 감소
var _label_pool: Array[Label] = []
var _color_rect_pool: Array[ColorRect] = []
const POOL_MAX_SIZE := 20

## 노드별 트윈 캐시 — 같은 노드에 중복 트윈 방지
var _node_tweens: Dictionary = {}  # node_id → Tween


func _ready() -> void:
	set_process(false)


func setup(target: Control) -> void:
	_shake_target = target
	_original_position = target.position


func _process(delta: float) -> void:
	if _shake_target and _shake_intensity > 0.5:
		var offset := Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		_shake_target.position = _original_position + offset
		_shake_intensity = lerpf(_shake_intensity, 0.0, _shake_decay * delta)
	elif _shake_target and _shake_intensity > 0.0:
		_shake_target.position = _original_position
		_shake_intensity = 0.0
		set_process(false)


## --- 오브젝트 풀 ---

func _acquire_label() -> Label:
	## 풀에서 Label을 꺼내거나 새로 생성한다.
	if _label_pool.size() > 0:
		var label: Label = _label_pool.pop_back()
		label.modulate = Color.WHITE
		label.scale = Vector2.ONE
		label.visible = true
		# 이전 사용의 레이아웃 상태 초기화 — 랜덤 위치 방지
		label.position = Vector2.ZERO
		label.size = Vector2.ZERO
		label.offset_left = 0
		label.offset_top = 0
		label.offset_right = 0
		label.offset_bottom = 0
		label.anchor_left = 0
		label.anchor_top = 0
		label.anchor_right = 0
		label.anchor_bottom = 0
		label.grow_horizontal = Control.GROW_DIRECTION_END
		label.grow_vertical = Control.GROW_DIRECTION_END
		label.pivot_offset = Vector2.ZERO
		label.rotation = 0
		return label
	return Label.new()


func _release_label(label: Label) -> void:
	## Label을 풀로 반환한다. 풀이 가득 차면 해제한다.
	if not is_instance_valid(label):
		return
	label.visible = false
	if label.get_parent():
		label.get_parent().remove_child(label)
	if _label_pool.size() < POOL_MAX_SIZE:
		_label_pool.append(label)
	else:
		label.queue_free()


func _acquire_color_rect() -> ColorRect:
	## 풀에서 ColorRect를 꺼내거나 새로 생성한다.
	if _color_rect_pool.size() > 0:
		var rect: ColorRect = _color_rect_pool.pop_back()
		rect.modulate = Color.WHITE
		rect.scale = Vector2.ONE
		rect.visible = true
		# 이전 사용의 레이아웃 상태 초기화 — 랜덤 위치 방지
		rect.position = Vector2.ZERO
		rect.size = Vector2.ZERO
		rect.offset_left = 0
		rect.offset_top = 0
		rect.offset_right = 0
		rect.offset_bottom = 0
		rect.anchor_left = 0
		rect.anchor_top = 0
		rect.anchor_right = 0
		rect.anchor_bottom = 0
		rect.grow_horizontal = Control.GROW_DIRECTION_END
		rect.grow_vertical = Control.GROW_DIRECTION_END
		rect.pivot_offset = Vector2.ZERO
		rect.rotation = 0
		rect.custom_minimum_size = Vector2.ZERO
		return rect
	return ColorRect.new()


func _release_color_rect(rect: ColorRect) -> void:
	## ColorRect를 풀로 반환한다. 풀이 가득 차면 해제한다.
	if not is_instance_valid(rect):
		return
	rect.visible = false
	if rect.get_parent():
		rect.get_parent().remove_child(rect)
	if _color_rect_pool.size() < POOL_MAX_SIZE:
		_color_rect_pool.append(rect)
	else:
		rect.queue_free()


# --- 화면 흔들림 ---

func screen_shake(intensity: float = 8.0, decay: float = 8.0) -> void:
	## 화면 흔들림 트리거. 접근성 설정에서 비활성화 가능.
	if not AccessibilityManager.screen_shake_enabled:
		return
	_shake_intensity = intensity
	_shake_decay = decay
	set_process(true)


# --- 데미지 숫자 팝업 ---

func spawn_damage_number(parent: Control, global_pos: Vector2, amount: int, is_heal: bool = false) -> void:
	## 데미지(빨강) 또는 회복(초록) 숫자를 떠오르는 텍스트로 표시한다.
	var label := _acquire_label()
	label.text = str(amount) if not is_heal else ("+%d" % amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)

	if is_heal:
		label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))

	label.position = global_pos + Vector2(0, -10)
	label.z_index = 100
	parent.add_child(label)

	# 위로 떠오르며 사라지는 애니메이션
	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.set_parallel(false)
	tween.tween_callback(_release_label.bind(label))


func spawn_block_number(parent: Control, global_pos: Vector2, amount: int) -> void:
	## 방어도 획득 숫자(파랑)를 표시한다.
	var label := _acquire_label()
	label.text = tr("VFX_BLOCK_FMT") % amount
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	label.position = global_pos + Vector2(0, -5)
	label.z_index = 100
	parent.add_child(label)

	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.7).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.2)
	tween.set_parallel(false)
	tween.tween_callback(_release_label.bind(label))


# --- 화면 플래시 ---

func flash_screen(parent: Control, color: Color = Color(1, 1, 1, 0.3), duration: float = 0.15) -> void:
	## 짧은 화면 플래시 (시조 완성, 크리티컬 등)
	var flash := _acquire_color_rect()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 80
	parent.add_child(flash)

	var tween := parent.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(_release_color_rect.bind(flash))


# --- 시선/절창 콤보 연출 ---

func combo_vfx(parent: Control, combo_text: String, color: Color) -> void:
	## 시선/절창 콤보 발동 연출: 화면 플래시 + 중앙 텍스트 팝업 + 파티클
	# 히트스톱
	_apply_slow_motion(0.1, 0.2)

	# 화면 플래시
	flash_screen(parent, Color(color.r, color.g, color.b, 0.4), 0.3)

	# 화면 흔들림
	screen_shake(12.0, 3.0)

	# 중앙 텍스트 팝업 — 앵커 기반 센터링으로 레이아웃 전에도 정확한 위치 보장
	var label := _acquire_label()
	label.text = combo_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 92
	# 앵커 기반 센터링 — add_child 전에 설정하여 레이아웃 안정화
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	parent.add_child(label)
	# size가 확정된 후 pivot 설정 (스케일 애니메이션 기준점)
	label.pivot_offset = label.size / 2.0

	var tween := parent.create_tween()
	label.scale = Vector2(0.3, 0.3)
	label.modulate.a = 0.0
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.set_parallel(false)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(_release_label.bind(label))

	# 파티클
	_spawn_particles(parent, 16, color)


# --- 시조 완성 연출 ---

func sijo_complete_vfx(parent: Control, slot_card_names: Array[String] = []) -> void:
	## 시조 완성 시: 히트스톱 + 슬로우모션 + 화면 플래시 + 한시 구절 연출 + 강화된 파티클
	# 히트스톱 + 슬로우모션 연출 (순간 정지 → 느린 복귀)
	_apply_slow_motion(0.05, 0.3)

	# 화면 플래시 (더 밝고 오래 지속)
	flash_screen(parent, Color(1.0, 0.85, 0.3, 0.55), 0.4)

	# 강화된 화면 흔들림
	screen_shake(18.0, 5.0)

	# 시조 구절 연출 — 6장 카드명을 초장/중장/종장 3행으로 표시
	if slot_card_names.size() == 6:
		_spawn_hanshi_overlay(parent, slot_card_names)
	else:
		# 카드명 없을 때 기존 단순 텍스트 폴백
		var label := _acquire_label()
		label.text = tr("VFX_SIJO_COMPLETE")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 56)
		label.add_theme_color_override("font_color", Color(0.83, 0.63, 0.09))
		label.add_theme_color_override("font_outline_color", Color(0.6, 0.3, 0.0))
		label.add_theme_constant_override("outline_size", 4)
		label.z_index = 90
		# 앵커 기반 센터링 — add_child 전에 설정
		label.set_anchors_preset(Control.PRESET_CENTER)
		label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		label.grow_vertical = Control.GROW_DIRECTION_BOTH
		parent.add_child(label)
		label.pivot_offset = label.size / 2.0
		var tween := parent.create_tween()
		label.scale = Vector2(0.3, 0.3)
		tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.6)
		tween.tween_callback(_release_label.bind(label))

	# 1차 파티클: 빠르게 퍼지는 코어 (24개)
	_spawn_particles(parent, 24, Color(0.83, 0.63, 0.09))
	# 2차 파티클: 느리게 퍼지는 외곽 링 (12개, 더 크고 밝음)
	_spawn_ring_particles(parent, 12, Color(1.0, 0.95, 0.6))


func _spawn_hanshi_overlay(parent: Control, names: Array[String]) -> void:
	## 시조 완성 한시 연출: 초장/중장/종장 3행을 중앙 오버레이로 표시
	## 각 행 = 카드명 두 개를 공백으로 연결, 서예 느낌의 금색 텍스트
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.03, 0.02, 0.82)  # 반투명 먹색 배경
	panel.anchor_left = 0.1
	panel.anchor_right = 0.9
	panel.anchor_top = 0.15
	panel.anchor_bottom = 0.55
	panel.z_index = 95
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)

	# 표제: "시조 완성!" 소형 헤더
	var header := Label.new()
	header.text = tr("VFX_SIJO_HEADER")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.anchor_left = 0.0
	header.anchor_right = 1.0
	header.anchor_top = 0.05
	header.anchor_bottom = 0.25
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(header)

	# 초장/중장/종장 3행
	var jang_labels: Array[String] = [tr("SIJO_FIRST_VERSE"), tr("SIJO_MIDDLE_VERSE"), tr("SIJO_FINAL_VERSE")]
	for i in 3:
		var line_text := "%s  %s" % [names[i * 2], names[i * 2 + 1]]
		var line_label := Label.new()
		line_label.text = line_text
		line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line_label.anchor_left = 0.0
		line_label.anchor_right = 1.0
		line_label.anchor_top = 0.25 + i * 0.22
		line_label.anchor_bottom = 0.47 + i * 0.22
		line_label.add_theme_font_size_override("font_size", 30)
		line_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
		line_label.add_theme_color_override("font_outline_color", Color(0.4, 0.2, 0.0))
		line_label.add_theme_constant_override("outline_size", 2)
		line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(line_label)

	# 패널 페이드 인 → 유지 → 페이드 아웃 (총 2.5초)
	panel.modulate.a = 0.0
	var tween := parent.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.6)
	tween.tween_property(panel, "modulate:a", 0.0, 0.6)
	tween.tween_callback(panel.queue_free)


func _spawn_particles(parent: Control, count: int, color: Color) -> void:
	## 간단한 코드 기반 파티클 — 작은 ColorRect 조각들이 퍼져나감
	var center := parent.get_viewport().get_visible_rect().size / 2.0
	for i in count:
		var particle := _acquire_color_rect()
		particle.size = Vector2(6, 6)
		particle.color = color.lerp(Color.WHITE, randf_range(0.0, 0.3))
		particle.position = center
		particle.z_index = 85
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(particle)

		var angle := (TAU / count) * i + randf_range(-0.3, 0.3)
		var distance := randf_range(80.0, 200.0)
		var target_pos := center + Vector2(cos(angle), sin(angle)) * distance
		var duration := randf_range(0.4, 0.8)

		var tween := parent.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_property(particle, "size", Vector2(2, 2), duration)
		tween.set_parallel(false)
		tween.tween_callback(_release_color_rect.bind(particle))


# --- 슬로우모션 ---

func _apply_slow_motion(time_scale: float = 0.05, duration: float = 0.3) -> void:
	## 히트스톱 + 슬로우모션: time_scale까지 즉시 감속 후 duration에 걸쳐 복귀.
	## process_mode가 ALWAYS인 타이머를 사용하여 time_scale 영향을 받지 않는다.
	Engine.time_scale = time_scale
	var timer := get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func(): Engine.time_scale = 1.0)


func _spawn_ring_particles(parent: Control, count: int, color: Color) -> void:
	## 2차 외곽 링 파티클 — 더 크고 느리게 퍼지며 회전하는 효과
	var center := parent.get_viewport().get_visible_rect().size / 2.0
	for i in count:
		var particle := _acquire_color_rect()
		particle.size = Vector2(10, 10)
		particle.color = color.lerp(Color.WHITE, randf_range(0.1, 0.4))
		particle.position = center
		particle.z_index = 84
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.pivot_offset = Vector2(5, 5)
		parent.add_child(particle)

		var angle := (TAU / count) * i
		var distance := randf_range(150.0, 300.0)
		var target_pos := center + Vector2(cos(angle), sin(angle)) * distance
		var duration := randf_range(0.7, 1.2)

		var tween := parent.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(particle, "modulate:a", 0.0, duration).set_delay(0.2)
		tween.tween_property(particle, "size", Vector2(3, 3), duration)
		tween.tween_property(particle, "rotation", randf_range(-PI, PI), duration)
		tween.set_parallel(false)
		tween.tween_callback(_release_color_rect.bind(particle))


# --- 턴 전환 효과 ---

func turn_transition(parent: Control, text: String, color: Color = Color(1, 0.85, 0.3)) -> void:
	## 턴 시작 시 슬라이드 인/아웃 텍스트 배너
	var vp_size := parent.get_viewport().get_visible_rect().size
	var banner := _acquire_color_rect()
	banner.color = Color(0, 0, 0, 0.7)
	banner.custom_minimum_size = Vector2(vp_size.x, 60)
	banner.size = Vector2(vp_size.x, 60)
	banner.position = Vector2(-vp_size.x, vp_size.y / 2.0 - 30)
	banner.z_index = 70
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(banner)

	var label := _acquire_label()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	banner.add_child(label)

	var tween := parent.create_tween()
	# 슬라이드 인
	tween.tween_property(banner, "position:x", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# 대기
	tween.tween_interval(0.6)
	# 슬라이드 아웃
	tween.tween_property(banner, "position:x", vp_size.x, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		_release_label(label)
		_release_color_rect(banner)
	)


# --- 상태효과 적용 시 바운스 ---

func bounce_node(node: Control, scale_factor: float = 1.3, duration: float = 0.2) -> void:
	## 노드에 바운스 스케일 효과를 적용한다 (상태효과 적용 등)
	if not is_instance_valid(node):
		return
	_kill_node_tween(node)
	var original_scale := node.scale
	var tween := node.create_tween()
	_node_tweens[node.get_instance_id()] = tween
	tween.tween_property(node, "scale", original_scale * scale_factor, duration * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", original_scale, duration * 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_clear_node_tween.bind(node.get_instance_id()))


func shake_node(node: Control, intensity: float = 4.0, duration: float = 0.3) -> void:
	## 노드를 짧게 좌우로 흔든다 (데미지, 디버프 등)
	if not is_instance_valid(node):
		return
	_kill_node_tween(node)
	var original_pos := node.position
	var tween := node.create_tween()
	_node_tweens[node.get_instance_id()] = tween
	var steps := 6
	var current_intensity := intensity
	for i in steps:
		var offset := Vector2(randf_range(-current_intensity, current_intensity), randf_range(-current_intensity * 0.5, current_intensity * 0.5))
		current_intensity *= 0.7  # 감쇠
		tween.tween_property(node, "position", original_pos + offset, duration / steps)
	tween.tween_property(node, "position", original_pos, duration / steps)
	tween.tween_callback(_clear_node_tween.bind(node.get_instance_id()))


func flash_node(node: Control, color: Color = Color(1, 1, 1, 0.6), duration: float = 0.15) -> void:
	## 노드 위에 짧은 플래시 오버레이 (피격 깜빡임)
	if not is_instance_valid(node):
		return
	var flash := _acquire_color_rect()
	flash.color = color
	flash.size = node.size
	flash.position = Vector2.ZERO
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 50
	node.add_child(flash)

	var tween := node.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(_release_color_rect.bind(flash))


func shield_effect(parent: Control, target_pos: Vector2) -> void:
	## 방어 카드 사용 시 파란색 실드 원형 이펙트
	var shield := _acquire_color_rect()
	shield.color = Color(0.2, 0.5, 1.0, 0.4)
	shield.size = Vector2(80, 80)
	shield.position = target_pos - Vector2(40, 40)
	shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shield.z_index = 60
	shield.pivot_offset = Vector2(40, 40)
	shield.scale = Vector2(0.3, 0.3)
	parent.add_child(shield)

	var tween := parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(shield, "scale", Vector2(1.2, 1.2), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(shield, "modulate:a", 0.0, 0.4).set_delay(0.15)
	tween.set_parallel(false)
	tween.tween_callback(_release_color_rect.bind(shield))


# --- HP 바 스무스 애니메이션 ---

func animate_hp_bar(label: Label, from_hp: int, to_hp: int, max_hp: int, duration: float = 0.4) -> void:
	## HP 라벨 텍스트를 점진적으로 변경하는 카운트 다운 효과
	if not is_instance_valid(label):
		return
	_kill_node_tween(label)
	var tween := label.create_tween()
	_node_tweens[label.get_instance_id()] = tween
	var hp_dict := {"value": float(from_hp)}

	tween.tween_method(func(val: float):
		hp_dict["value"] = val
		label.text = "HP: %d/%d" % [int(val), max_hp]
		# HP 비율에 따라 색상 변경
		var ratio := val / max_hp if max_hp > 0 else 0.0
		if ratio < 0.25:
			label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		elif ratio < 0.5:
			label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		else:
			label.remove_theme_color_override("font_color")
	, float(from_hp), float(to_hp), duration)
	tween.tween_callback(_clear_node_tween.bind(label.get_instance_id()))


# --- 시조 일격 수묵화 풀스크린 VFX (ZER-324) ---

func sijo_strike_vfx(parent: Control, strike_name: String) -> void:
	## 시조 일격 발동 시 수묵화 풀스크린 연출:
	## 먹색 배경 → 수묵 번짐 효과 → 필살기명 붓글씨 → 페이드아웃
	# 히트스톱
	_apply_slow_motion(0.02, 0.5)

	# 수묵화 배경 — 풀스크린 먹색 오버레이
	var ink_bg := _acquire_color_rect()
	ink_bg.color = Color(0.02, 0.01, 0.01, 0.0)
	ink_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ink_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink_bg.z_index = 96
	parent.add_child(ink_bg)

	# 수묵 번짐 효과 — 화면 중앙에서 퍼지는 원형 먹물 얼룩들
	var vp_size := parent.get_viewport().get_visible_rect().size
	var center := vp_size / 2.0
	for i in 8:
		var ink_blob := _acquire_color_rect()
		var blob_size := randf_range(60.0, 180.0)
		ink_blob.custom_minimum_size = Vector2(blob_size, blob_size)
		ink_blob.size = Vector2(blob_size, blob_size)
		ink_blob.color = Color(0.05, 0.03, 0.02, randf_range(0.3, 0.6))
		ink_blob.pivot_offset = Vector2(blob_size / 2.0, blob_size / 2.0)
		var offset := Vector2(randf_range(-200, 200), randf_range(-150, 150))
		ink_blob.position = center + offset - Vector2(blob_size / 2.0, blob_size / 2.0)
		ink_blob.scale = Vector2(0.1, 0.1)
		ink_blob.z_index = 97
		ink_blob.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ink_bg.add_child(ink_blob)

		var blob_tween := parent.create_tween()
		blob_tween.tween_property(ink_blob, "scale", Vector2(1.0, 1.0), randf_range(0.2, 0.4)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		blob_tween.tween_property(ink_blob, "modulate:a", 0.0, 0.6).set_delay(1.0)

	# 필살기명 붓글씨 텍스트 — 큰 세로 표시
	var strike_label := _acquire_label()
	strike_label.text = strike_name
	strike_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strike_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	strike_label.add_theme_font_size_override("font_size", 64)
	strike_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))  # 한지색
	strike_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	strike_label.add_theme_constant_override("outline_size", 8)
	strike_label.z_index = 98
	strike_label.set_anchors_preset(Control.PRESET_CENTER)
	strike_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	strike_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	parent.add_child(strike_label)
	strike_label.pivot_offset = strike_label.size / 2.0

	# 붓글씨 등장 애니메이션: 빠르게 스케일 인 → 잠시 유지 → 페이드 아웃
	strike_label.scale = Vector2(0.1, 0.1)
	strike_label.modulate.a = 0.0
	var label_tween := parent.create_tween()
	label_tween.set_parallel(true)
	label_tween.tween_property(strike_label, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	label_tween.tween_property(strike_label, "modulate:a", 1.0, 0.1)
	label_tween.set_parallel(false)
	label_tween.tween_property(strike_label, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN_OUT)
	label_tween.tween_interval(0.8)
	label_tween.tween_property(strike_label, "modulate:a", 0.0, 0.4)
	label_tween.tween_callback(_release_label.bind(strike_label))

	# 배경 페이드: 빠르게 드러남 → 유지 → 페이드 아웃
	var bg_tween := parent.create_tween()
	bg_tween.tween_property(ink_bg, "color:a", 0.85, 0.15)
	bg_tween.tween_interval(1.0)
	bg_tween.tween_property(ink_bg, "modulate:a", 0.0, 0.5)
	bg_tween.tween_callback(func():
		# 자식 먹물 얼룩 정리
		for child in ink_bg.get_children():
			if child is ColorRect:
				_release_color_rect(child)
		_release_color_rect(ink_bg)
	)

	# 강화된 화면 흔들림
	screen_shake(20.0, 4.0)

	# 먹물 파티클
	_spawn_ink_particles(parent, 20)


func _spawn_ink_particles(parent: Control, count: int) -> void:
	## 수묵화 먹물 파티클 — 검은 잉크 방울이 퍼져나감
	var center := parent.get_viewport().get_visible_rect().size / 2.0
	for i in count:
		var particle := _acquire_color_rect()
		var psize := randf_range(4.0, 12.0)
		particle.size = Vector2(psize, psize)
		particle.color = Color(0.05, 0.03, 0.02, randf_range(0.5, 0.9))
		particle.position = center
		particle.z_index = 99
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(particle)

		var angle := (TAU / count) * i + randf_range(-0.5, 0.5)
		var distance := randf_range(100.0, 350.0)
		var target_pos := center + Vector2(cos(angle), sin(angle)) * distance
		var duration := randf_range(0.3, 0.7)

		var tween := parent.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(particle, "modulate:a", 0.0, duration + 0.3)
		tween.tween_property(particle, "size", Vector2(2, 2), duration)
		tween.set_parallel(false)
		tween.tween_callback(_release_color_rect.bind(particle))


func _kill_node_tween(node: Control) -> void:
	## 노드에 실행 중인 트윈이 있으면 중단한다.
	var nid := node.get_instance_id()
	if _node_tweens.has(nid):
		var old_tween: Tween = _node_tweens[nid]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
		_node_tweens.erase(nid)


func _clear_node_tween(nid: int) -> void:
	## 트윈 완료 시 캐시에서 제거한다.
	_node_tweens.erase(nid)
