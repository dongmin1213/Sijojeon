class_name CardZoomPopup
extends CanvasLayer

## 카드 상세보기 팝업. 카드를 확대하여 전체 정보를 표시한다.
## 터치/클릭으로 닫을 수 있다.

var _bg: ColorRect
var _panel: PanelContainer
var _card_data: CardData


func _init() -> void:
	layer = 100  # 최상위 레이어


func show_card(card: CardData) -> void:
	_card_data = card
	_build_ui()


func _build_ui() -> void:
	# 배경 (반투명 오버레이)
	_bg = ColorRect.new()
	_bg.anchors_preset = Control.PRESET_FULL_RECT
	_bg.color = Color(0, 0, 0, 0.7)
	_bg.gui_input.connect(_on_bg_input)
	add_child(_bg)

	# 중앙 패널 — 뷰포트 중앙에 명시적 배치
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(360, 540)
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS  # 패널 터치가 배경까지 전달
	var vp_size := get_viewport().get_visible_rect().size
	_panel.position = Vector2(
		(vp_size.x - 360) / 2.0,
		(vp_size.y - 540) / 2.0
	)

	# v6: 카드 프레임 SVG 텍스처 기반 팝업
	var frame_path := _get_frame_path(_card_data.rarity)
	var frame_tex = load(frame_path) as Texture2D if ResourceLoader.exists(frame_path) else null
	if frame_tex:
		var tex_sb := StyleBoxTexture.new()
		tex_sb.texture = frame_tex
		tex_sb.texture_margin_left = 12
		tex_sb.texture_margin_right = 12
		tex_sb.texture_margin_top = 42
		tex_sb.texture_margin_bottom = 12
		tex_sb.content_margin_left = 20
		tex_sb.content_margin_right = 20
		tex_sb.content_margin_top = 14
		tex_sb.content_margin_bottom = 14
		_panel.add_theme_stylebox_override("panel", tex_sb)
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.05, 0.12, 0.97)
		style.border_color = Color(0.76, 0.23, 0.13, 0.9)
		style.set_border_width_all(3)
		style.set_corner_radius_all(16)
		style.set_content_margin_all(22)
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
		style.shadow_size = 10
		_panel.add_theme_stylebox_override("panel", style)
	_bg.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	_panel.add_child(vbox)

	# 닫기 버튼 (우측 상단)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)

	# 카드 이름
	var name_label := Label.new()
	var display_name := _card_data.get_display_name()
	if _card_data.upgraded:
		display_name += "+"
	name_label.text = display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
	vbox.add_child(name_label)

	# 카드 일러스트
	var art := TextureRect.new()
	art.texture = TextureManager.get_card_texture(_card_data.id, _card_data.type)
	art.custom_minimum_size = Vector2(280, 160)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(art)

	# 타입 + 희귀도
	var type_names := {
		"attack": tr("CARD_ZOOM_TYPE_ATTACK"), "defense": tr("CARD_ZOOM_TYPE_DEFENSE"), "spell": tr("CARD_ZOOM_TYPE_SPELL"),
		"movement": tr("CARD_ZOOM_TYPE_MOVEMENT"), "formation": tr("CARD_ZOOM_TYPE_FORMATION"),
	}
	var type_label := Label.new()
	type_label.text = type_names.get(_card_data.type, _card_data.type)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 18)
	var type_color: Color = AccessibilityManager.get_type_color(_card_data.type)
	type_label.add_theme_color_override("font_color", type_color)
	vbox.add_child(type_label)

	# 구분선
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# 스탯 그리드
	var stats := _build_stat_text()
	var stat_label := Label.new()
	stat_label.text = stats
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(stat_label)

	# 효과 설명
	var effect_label := Label.new()
	effect_label.text = _card_data.get_current_effect()
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	effect_label.custom_minimum_size = Vector2(300, 0)
	effect_label.add_theme_font_size_override("font_size", 18)
	effect_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(effect_label)

	# 키워드 설명 섹션
	var keywords := _find_keywords_in_card()
	if not keywords.is_empty():
		var kw_sep := HSeparator.new()
		vbox.add_child(kw_sep)

		var kw_title := Label.new()
		kw_title.text = tr("CARD_ZOOM_KEYWORD_TITLE")
		kw_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kw_title.add_theme_font_size_override("font_size", 16)
		kw_title.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91, 0.8))
		vbox.add_child(kw_title)

		for kw in keywords:
			var kw_entry := RichTextLabel.new()
			kw_entry.bbcode_enabled = true
			var color_hex: String = kw.get("color", "#FFD966")
			kw_entry.text = "[color=%s]%s[/color]: %s" % [color_hex, kw.get("name", ""), kw.get("description", "")]
			kw_entry.fit_content = true
			kw_entry.custom_minimum_size = Vector2(300, 0)
			kw_entry.add_theme_font_size_override("normal_font_size", 14)
			kw_entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(kw_entry)

	# 닫기 안내
	var hint := Label.new()
	hint.text = tr("CARD_ZOOM_HINT")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(hint)


func _build_stat_text() -> String:
	var lines: Array[String] = []
	lines.append(tr("CARD_ZOOM_STAT_QI_BEAT") % [_card_data.cost, _card_data.beat])

	if _card_data.damage > 0:
		var dmg := tr("CARD_ZOOM_DAMAGE") % _card_data.damage
		if _card_data.is_aoe:
			dmg += " " + tr("SHOP_CARD_DAMAGE_AOE")
		lines.append(dmg)
	if _card_data.block_value > 0:
		lines.append(tr("CARD_ZOOM_BLOCK") % _card_data.block_value)
	if _card_data.draw_count > 0:
		lines.append(tr("CARD_ZOOM_DRAW") % _card_data.draw_count)
	if _card_data.qi_gain > 0:
		lines.append(tr("CARD_ZOOM_QI_GAIN") % _card_data.qi_gain)
	if _card_data.stamina_cost > 0:
		lines.append(tr("CARD_ZOOM_RESOURCE_COST") % _card_data.stamina_cost)
	if _card_data.stamina_gain > 0:
		lines.append(tr("CARD_ZOOM_RESOURCE_GAIN") % _card_data.stamina_gain)

	return "\n".join(lines)


func _find_keywords_in_card() -> Array[Dictionary]:
	## 카드 효과 텍스트와 속성에서 관련 키워드를 찾아 반환
	var found: Array[Dictionary] = []
	var found_ids: Array[String] = []
	var all_kw := KeywordTooltip.get_all_keywords()

	# 카드 속성 기반 키워드 자동 추가
	var auto_keywords: Array[String] = ["beat", "qi"]  # 모든 카드에 기본 표시

	if _card_data.damage > 0 and _card_data.is_aoe:
		auto_keywords.append("aoe")
	if _card_data.block_value > 0:
		auto_keywords.append("block")
	if _card_data.stamina_cost > 0 or _card_data.stamina_gain > 0:
		if _card_data.pool == "mugwan":
			auto_keywords.append("giryeok")
		elif _card_data.pool == "mungwan":
			auto_keywords.append("haksik")

	# 효과 텍스트에서 키워드 검색
	var effect_text := _card_data.get_current_effect()
	for kw_id in all_kw:
		var kw: Dictionary = all_kw[kw_id]
		# id 기반 매칭만 (name 기반 중복 방지)
		if kw.get("id", "") != kw_id:
			continue
		var kw_name: String = kw.get("name", "")
		var kw_short: String = kw.get("id", "")
		# 효과 텍스트에 키워드 이름이나 ID가 포함되어 있으면 추가
		if kw_short in auto_keywords or effect_text.find(kw_short) >= 0 or (kw_name != "" and effect_text.find(kw_name.split("(")[0]) >= 0):
			if kw_short not in found_ids:
				found_ids.append(kw_short)
				found.append(kw)

	# 상태이상 관련 키워드 (효과 텍스트에서 감지)
	var status_keywords := ["독", "화상", "출혈", "약화", "취약", "냉기", "구금", "주박", "소멸"]
	for sk in status_keywords:
		if effect_text.find(sk) >= 0 and sk not in found_ids:
			if all_kw.has(sk):
				found_ids.append(sk)
				found.append(all_kw[sk])

	return found


func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()
	elif event is InputEventScreenTouch and event.pressed:
		_close()


func _get_frame_path(rarity_level: int) -> String:
	## v6: 희귀도별 카드 프레임 SVG 경로
	match rarity_level:
		2: return "res://art/ui/card_frame_uncommon.svg"
		3: return "res://art/ui/card_frame_rare.svg"
		4: return "res://art/ui/card_frame_rare.svg"
		5: return "res://art/ui/card_frame_legendary.svg"
	return "res://art/ui/card_frame_common.svg"


func _close() -> void:
	queue_free()
