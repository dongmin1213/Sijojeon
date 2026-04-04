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
	label.text = "+%d 방어" % amount
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


# --- 시조 완성 연출 ---

func sijo_complete_vfx(parent: Control) -> void:
	## 시조 완성 시: 히트스톱 + 슬로우모션 + 화면 플래시 + 큰 텍스트 + 강화된 파티클
	# 히트스톱 + 슬로우모션 연출 (순간 정지 → 느린 복귀)
	_apply_slow_motion(0.05, 0.3)

	# 화면 플래시 (더 밝고 오래 지속)
	flash_screen(parent, Color(1.0, 0.85, 0.3, 0.55), 0.4)

	# 강화된 화면 흔들림
	screen_shake(18.0, 5.0)

	# 완성 텍스트 연출
	var label := _acquire_label()
	label.text = "시조 완성!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_CENTER
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	label.add_theme_color_override("font_outline_color", Color(0.6, 0.3, 0.0))
	label.add_theme_constant_override("outline_size", 4)
	label.pivot_offset = label.size / 2.0
	label.z_index = 90
	parent.add_child(label)

	# 스케일 업 + 페이드 아웃 (더 역동적)
	var tween := parent.create_tween()
	label.scale = Vector2(0.3, 0.3)
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tween.tween_callback(_release_label.bind(label))

	# 1차 파티클: 빠르게 퍼지는 코어 (24개)
	_spawn_particles(parent, 24, Color(1.0, 0.85, 0.3))
	# 2차 파티클: 느리게 퍼지는 외곽 링 (12개, 더 크고 밝음)
	_spawn_ring_particles(parent, 12, Color(1.0, 0.95, 0.6))


func _spawn_particles(parent: Control, count: int, color: Color) -> void:
	## 간단한 코드 기반 파티클 — 작은 ColorRect 조각들이 퍼져나감
	var center := parent.size / 2.0
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
	var center := parent.size / 2.0
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
	var original_scale := node.scale
	var tween := node.create_tween()
	tween.tween_property(node, "scale", original_scale * scale_factor, duration * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", original_scale, duration * 0.6).set_ease(Tween.EASE_OUT)


func shake_node(node: Control, intensity: float = 4.0, duration: float = 0.3) -> void:
	## 노드를 짧게 좌우로 흔든다 (데미지, 디버프 등)
	if not is_instance_valid(node):
		return
	var original_pos := node.position
	var tween := node.create_tween()
	var steps := 6
	for i in steps:
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity * 0.5, intensity * 0.5))
		intensity *= 0.7  # 감쇠
		tween.tween_property(node, "position", original_pos + offset, duration / steps)
	tween.tween_property(node, "position", original_pos, duration / steps)


# --- HP 바 스무스 애니메이션 ---

func animate_hp_bar(label: Label, from_hp: int, to_hp: int, max_hp: int, duration: float = 0.4) -> void:
	## HP 라벨 텍스트를 점진적으로 변경하는 카운트 다운 효과
	if not is_instance_valid(label):
		return

	var tween := label.create_tween()
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
