extends Control

## 캐릭터 선택 화면.
## DataLoader와 SaveManager를 활용하여 해금 상태, 시작 유물, 전용 자원을 표시한다.

# 캐릭터 정의 순서 (표시 순서)
const CHARACTER_IDS := ["mugwan", "mungwan", "dosa"]

# 캐릭터 ID → SVG 아트 파일명 매핑
const CHARACTER_ART_MAP := {
	"mugwan": "res://art/characters/warrior.svg",
	"mungwan": "res://art/characters/scholar.svg",
	"dosa": "res://art/characters/assassin.svg",
}

var _selected_index: int = -1
var _character_list: Array[Dictionary] = []
var _unlock_data: Array[Dictionary] = []

@onready var title_label: Label = $TitleLabel
@onready var card_container: HBoxContainer = $CardContainer
@onready var start_button: Button = $BottomBar/VBoxContainer/ButtonRow/StartButton
@onready var back_button: Button = $BottomBar/VBoxContainer/ButtonRow/BackButton

var _detail_panel: PanelContainer = null
var _achievement_panel: PanelContainer = null
var _achievement_visible := false


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# F1: 선택된 캐릭터로 게임 시작 (터치 입력 불가 환경 대응)
		if event.keycode == KEY_F1:
			if _selected_index >= 0:
				_on_start_pressed()
				get_viewport().set_input_as_handled()
		# F2: 뒤로 가기
		elif event.keycode == KEY_F2:
			_on_back_pressed()
			get_viewport().set_input_as_handled()


func _ready() -> void:
	# 뷰포트 비례 UI 스케일링 적용
	var vp_size := get_viewport().get_visible_rect().size
	var ui_scale := minf(vp_size.x / 1080.0, vp_size.y / 1920.0)
	title_label.add_theme_font_size_override("font_size", maxi(int(42 * ui_scale), 36))
	card_container.add_theme_constant_override("separation", int(20 * ui_scale))

	start_button.disabled = true
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	# v8: 시작 버튼에 주 액션(CTA) 스타일 적용
	_apply_start_button_style()
	_load_unlock_conditions()
	_build_character_list()
	_build_character_cards()
	_build_achievement_button()
	# 가이드 오버레이는 카드 렌더링 후 표시 (deferred)
	call_deferred("_show_first_play_guide")


func _load_unlock_conditions() -> void:
	var path := "res://data/unlock/unlock_conditions.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err == OK and json.data is Dictionary:
		_unlock_data = []
		for entry in json.data.get("characters", []):
			_unlock_data.append(entry)


func _is_character_unlocked(character_id: String) -> bool:
	## 메타 데이터와 해금 조건을 비교하여 해금 여부를 판정한다.
	var meta := SaveManager.load_meta()
	var stats: Dictionary = meta.get("stats", {})
	var char_stats: Dictionary = meta.get("character_stats", {})

	for cond in _unlock_data:
		if cond.get("id", "") != character_id:
			continue
		var unlock_type: String = cond.get("unlock_type", "default")
		match unlock_type:
			"default":
				return true
			"total_runs":
				var min_runs: int = cond.get("unlock_params", {}).get("min_runs", 1)
				return stats.get("total_runs", 0) >= min_runs
			"character_act_clear":
				var params: Dictionary = cond.get("unlock_params", {})
				var req_char: String = params.get("character_id", "")
				var min_act: int = params.get("min_act", 1)
				# 캐릭터 제한 없음 (빈 문자열): 아무 캐릭터로든 해당 막 보스 처치 시 해금
				if req_char == "":
					if stats.get("best_act", 0) > min_act:
						return true
					for cid in char_stats:
						if char_stats[cid].get("victories", 0) > 0:
							return true
					return false
				# 특정 캐릭터로 승리한 적이 있거나, best_act가 min_act 이상이면 해금
				var req_char_stats: Dictionary = char_stats.get(req_char, {})
				if req_char_stats.get("victories", 0) > 0:
					return true
				# 해당 캐릭터로 런을 진행하여 min_act를 넘긴 적이 있으면 해금
				return stats.get("best_act", 0) > min_act and req_char_stats.get("runs", 0) > 0
	# 해금 조건이 정의되지 않은 캐릭터는 기본 해금
	return true


## 리소스 ID(한국어) → 번역키 매핑
const RESOURCE_KEY_MAP := {
	"기력": "RESOURCE_STAMINA",
	"학식": "RESOURCE_SCHOLARSHIP",
	"기": "RESOURCE_QI",
}

func _translate_resource_name(res_id: String) -> String:
	var key: String = RESOURCE_KEY_MAP.get(res_id, "")
	if key != "":
		return tr(key)
	return res_id


func _get_unlock_description(character_id: String) -> String:
	for cond in _unlock_data:
		if cond.get("id", "") == character_id:
			return TranslationManager.trd(cond, "unlock_description", "")
	return ""


# 캐릭터 ID → 표시용 기본 이름 (스킬 데이터 로드 실패 시 fallback)
const CHARACTER_FALLBACK := {
	"mugwan": {"class_ko": "무관", "class_hanja": "武官"},
	"mungwan": {"class_ko": "문관", "class_hanja": "文官"},
	"dosa": {"class_ko": "도사", "class_hanja": "道士"},
}


func _build_character_list() -> void:
	## DataLoader에서 캐릭터 스킬 데이터를 가져와 표시용 목록을 구성한다.
	_character_list.clear()
	for char_id in CHARACTER_IDS:
		var skills: Dictionary = DataLoader.get_character_skills(char_id)
		var unlocked := _is_character_unlocked(char_id)

		# special_skills.json에서 상세 정보 추출
		var char_entry := _find_skill_entry(char_id)

		# fallback: 스킬 데이터가 없으면 기본 이름 사용
		var fallback: Dictionary = CHARACTER_FALLBACK.get(char_id, {})
		var class_ko: String = char_entry.get("class_ko", fallback.get("class_ko", char_id))
		var class_hanja: String = char_entry.get("class_hanja", fallback.get("class_hanja", ""))

		var class_resource_name := ""
		var class_resource_max := 0
		if char_entry.has("class_resource"):
			var res_id: String = char_entry["class_resource"].get("id", "")
			class_resource_name = _translate_resource_name(res_id)
			class_resource_max = char_entry["class_resource"].get("max", 0)

		var starting_relic_name := ""
		var starting_relic_effect := ""
		if char_entry.has("starting_relic"):
			starting_relic_name = TranslationManager.trd_name(char_entry["starting_relic"])
			starting_relic_effect = TranslationManager.trd(char_entry["starting_relic"], "effect", "")

		var passive_name := ""
		var passive_desc := ""
		if skills.has("passive"):
			passive_name = TranslationManager.trd(skills, "passive", "")
			var passive_data = skills.get("passive", {})
			if passive_data is Dictionary:
				passive_desc = TranslationManager.trd(passive_data, "description", "")

		var active_name := ""
		var active_desc := ""
		if skills.has("active_skill") and skills["active_skill"].has("name"):
			var skill_name_data: Dictionary = skills["active_skill"]["name"]
			active_name = TranslationManager.trd(skills["active_skill"], "name", "")
			active_desc = TranslationManager.trd(skill_name_data, "description", "")

		_character_list.append({
			"id": char_id,
			"name": tr("CHAR_NAME_" + char_id.to_upper()),
			"hp": skills.get("base_hp", 70),
			"qi": skills.get("base_qi", 3),
			"unlocked": unlocked,
			"unlock_description": _get_unlock_description(char_id),
			"class_resource_name": class_resource_name,
			"class_resource_max": class_resource_max,
			"starting_relic_name": starting_relic_name,
			"starting_relic_effect": starting_relic_effect,
			"passive_name": passive_name,
			"passive_desc": passive_desc,
			"active_name": active_name,
			"active_desc": active_desc,
		})

	if _character_list.is_empty():
		push_warning("CharacterSelect: 캐릭터 목록 구성 실패")


func _find_skill_entry(character_id: String) -> Dictionary:
	## DataLoader 내부 _skills_data에서 캐릭터 항목을 찾는다.
	var skills_data: Dictionary = DataLoader._skills_data
	if not skills_data.has("character_special_skills"):
		return {}
	for entry in skills_data["character_special_skills"]:
		if entry.get("class_id", "") == character_id:
			return entry
	return {}


func _build_character_cards() -> void:
	# 뷰포트 크기에 비례하여 패널 크기·폰트 조정
	var vp_size := get_viewport().get_visible_rect().size
	var scale_x := vp_size.x / 1080.0
	var scale_y := vp_size.y / 1920.0
	var ui_scale := minf(scale_x, scale_y)

	# v7: 쇼케이스 영역 활용 — 카드가 더 크게 표시됨
	var card_count := _character_list.size()
	var separation := int(card_container.get_theme_constant("separation"))
	var showcase_w := vp_size.x * 0.92  # CardContainer는 화면 92% 사용
	var panel_min_w := minf(320.0 * scale_x, (showcase_w - separation * (card_count - 1)) / card_count)
	var panel_min_h := vp_size.y * 0.68  # 쇼케이스 영역의 대부분을 카드가 차지

	# 스케일된 폰트 크기 계산 (모바일 가독성 확보)
	var fs_name := maxi(int(34 * ui_scale), 30)
	var fs_stat := maxi(int(28 * ui_scale), 26)
	var fs_lock := maxi(int(36 * ui_scale), 30)
	var fs_skill_desc := maxi(int(22 * ui_scale), 22)
	var margin_h := int(16 * ui_scale)
	var margin_v := int(12 * ui_scale)

	if _character_list.is_empty():
		push_warning("CharacterSelect: _character_list 비어있음 — 카드 생성 건너뜀")
		return

	# CardContainer에 최소 높이 보장 및 오버플로 방지
	card_container.custom_minimum_size = Vector2(0, panel_min_h)
	card_container.clip_contents = true

	for i in _character_list.size():
		var character: Dictionary = _character_list[i]
		var unlocked: bool = character["unlocked"]

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(panel_min_w, panel_min_h)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.clip_contents = true

		# v5: 단청 스타일 캐릭터 카드 — 금박 테두리, 깊은 배경
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.08, 0.06, 0.14, 0.95)
		card_style.border_color = Color(0.83, 0.66, 0.26, 0.85)
		card_style.set_border_width_all(3)
		card_style.set_corner_radius_all(14)
		card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
		card_style.shadow_size = 6
		card_style.set_content_margin_all(4)
		panel.add_theme_stylebox_override("panel", card_style)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", margin_h)
		margin.add_theme_constant_override("margin_right", margin_h)
		margin.add_theme_constant_override("margin_top", margin_v)
		margin.add_theme_constant_override("margin_bottom", margin_v)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", int(8 * ui_scale))

		# v5: 캐릭터 이름 — 금색 강조
		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", fs_name)
		name_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.26))
		if unlocked:
			name_label.text = character["name"]
		else:
			name_label.text = "??? (" + character["name"].split("(")[1] if "(" in character["name"] else "???"
		vbox.add_child(name_label)

		# v7: 캐릭터 일러스트 — 쇼케이스 크기, SVG 에셋 로드
		var char_art := TextureRect.new()
		char_art.custom_minimum_size = Vector2(0, 320 * ui_scale)
		char_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		char_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		char_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if unlocked:
			var art_path: String = CHARACTER_ART_MAP.get(character["id"], "")
			if art_path != "" and ResourceLoader.exists(art_path):
				char_art.texture = load(art_path)
			else:
				char_art.texture = TextureManager.get_card_texture(character["id"], "")
		else:
			# 잠김 캐릭터: 실루엣 (어두운 placeholder)
			var art_path: String = CHARACTER_ART_MAP.get(character["id"], "")
			if art_path != "" and ResourceLoader.exists(art_path):
				char_art.texture = load(art_path)
				char_art.modulate = Color(0.15, 0.15, 0.20, 0.8)
			else:
				char_art.texture = TextureManager.get_card_texture(character["id"], "")
				char_art.modulate = Color(0.15, 0.15, 0.20, 0.8)
		vbox.add_child(char_art)

		# v6: 구분선
		var sep := HSeparator.new()
		vbox.add_child(sep)

		# v6: HP / 기 정보 — 색상 구분
		var stat_hbox := HBoxContainer.new()
		stat_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		stat_hbox.add_theme_constant_override("separation", int(12 * ui_scale))
		if unlocked:
			var hp_label := Label.new()
			hp_label.text = "HP %d" % character["hp"]
			hp_label.add_theme_font_size_override("font_size", fs_stat)
			hp_label.add_theme_color_override("font_color", Color(0.78, 0.29, 0.19))
			stat_hbox.add_child(hp_label)
			var qi_label := Label.new()
			qi_label.text = "氣 %d" % character["qi"]
			qi_label.add_theme_font_size_override("font_size", fs_stat)
			qi_label.add_theme_color_override("font_color", Color(0.45, 0.60, 0.80))
			stat_hbox.add_child(qi_label)
		else:
			var unknown_label := Label.new()
			unknown_label.text = tr("CHARSEL_STAT_UNKNOWN")
			unknown_label.add_theme_font_size_override("font_size", fs_stat)
			unknown_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			stat_hbox.add_child(unknown_label)
		vbox.add_child(stat_hbox)

		# v5: 전용 자원 표시 — 시안 강조
		if character["class_resource_name"] != "" and unlocked:
			var resource_label := Label.new()
			resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			resource_label.text = tr("CHARSEL_CLASS_RESOURCE_FMT") % [character["class_resource_name"], character["class_resource_max"]]
			resource_label.add_theme_font_size_override("font_size", fs_stat)
			resource_label.add_theme_color_override("font_color", Color(0.3, 0.75, 0.85))
			vbox.add_child(resource_label)

		if unlocked:
			# v5: 패시브 스킬 — 금빛 텍스트
			if character["passive_name"] != "":
				var passive_hint := Label.new()
				passive_hint.text = "◆ " + character["passive_name"]
				passive_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				passive_hint.add_theme_font_size_override("font_size", fs_skill_desc)
				passive_hint.add_theme_color_override("font_color", Color(0.83, 0.66, 0.26, 0.9))
				vbox.add_child(passive_hint)

			# v5: 선택 안내 — 은은한 금색
			var select_hint := Label.new()
			select_hint.text = tr("CHARSEL_TAP_TO_SELECT")
			select_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			select_hint.add_theme_font_size_override("font_size", fs_skill_desc)
			select_hint.add_theme_color_override("font_color", Color(0.83, 0.66, 0.26, 0.5))
			select_hint.size_flags_vertical = Control.SIZE_SHRINK_END
			vbox.add_child(select_hint)
		else:
			# v5: 잠금 상태 — 자물쇠 아이콘
			var lock_label := Label.new()
			lock_label.text = "🔒 " + tr("CHARSEL_LOCKED")
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_label.add_theme_font_size_override("font_size", fs_lock)
			lock_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.4))
			lock_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			vbox.add_child(lock_label)

			var cond_label := Label.new()
			cond_label.text = tr("CHARSEL_UNLOCK_COND") + character["unlock_description"]
			cond_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cond_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cond_label.add_theme_font_size_override("font_size", fs_skill_desc)
			cond_label.add_theme_color_override("font_color", Color(0.55, 0.50, 0.45))
			vbox.add_child(cond_label)

		margin.add_child(vbox)
		panel.add_child(margin)

		# 카드 전체를 탭 가능하게 설정 (모바일 터치 대응)
		_set_mouse_filter_recursive(margin, Control.MOUSE_FILTER_IGNORE)
		var card_index := i
		if unlocked:
			panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_select_character(card_index)
					get_viewport().set_input_as_handled()
			)
			panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		else:
			panel.mouse_filter = Control.MOUSE_FILTER_STOP

		# 잠금 캐릭터는 어둡게 표시
		if not unlocked:
			panel.modulate = Color(0.5, 0.5, 0.5)

		card_container.add_child(panel)

func _set_mouse_filter_recursive(node: Control, filter: Control.MouseFilter) -> void:
	## 노드와 모든 자식 Control의 mouse_filter를 재귀적으로 설정한다.
	node.mouse_filter = filter
	for child in node.get_children():
		if child is Control:
			_set_mouse_filter_recursive(child, filter)


func _select_character(index: int) -> void:
	if not _character_list[index]["unlocked"]:
		return
	_selected_index = index
	start_button.disabled = false
	start_button.text = tr("CHARSEL_START_FMT") % _character_list[index]["name"]

	# v5: 선택 하이라이트 — 금박 테두리 강화 + 비선택 카드 어둡게
	for i in card_container.get_child_count():
		var panel: PanelContainer = card_container.get_child(i)
		if not _character_list[i]["unlocked"]:
			panel.modulate = Color(0.4, 0.4, 0.4)
		elif i == index:
			panel.modulate = Color(1.0, 1.0, 1.0)
			# 선택된 카드: 금박 테두리 두껍게
			var sel_style := StyleBoxFlat.new()
			sel_style.bg_color = Color(0.10, 0.08, 0.16, 0.95)
			sel_style.border_color = Color(0.83, 0.66, 0.26, 1.0)
			sel_style.set_border_width_all(4)
			sel_style.set_corner_radius_all(14)
			sel_style.shadow_color = Color(0.83, 0.66, 0.26, 0.3)
			sel_style.shadow_size = 10
			panel.add_theme_stylebox_override("panel", sel_style)
		else:
			panel.modulate = Color(0.65, 0.65, 0.65)
			# 비선택 카드: 기본 스타일 복원
			var dim_style := StyleBoxFlat.new()
			dim_style.bg_color = Color(0.08, 0.06, 0.14, 0.95)
			dim_style.border_color = Color(0.83, 0.66, 0.26, 0.4)
			dim_style.set_border_width_all(2)
			dim_style.set_corner_radius_all(14)
			panel.add_theme_stylebox_override("panel", dim_style)

	# 선택한 캐릭터의 상세 정보 패널 표시
	_show_detail_panel(_character_list[index])


func _show_detail_panel(character: Dictionary) -> void:
	## 카드 아래에 선택된 캐릭터의 스킬/유물 상세를 표시한다.
	if _detail_panel and is_instance_valid(_detail_panel):
		_detail_panel.queue_free()

	var vp_size := get_viewport().get_visible_rect().size
	var ui_scale := minf(vp_size.x / 1080.0, vp_size.y / 1920.0)
	var fs_header := maxi(int(28 * ui_scale), 26)
	var fs_desc := maxi(int(24 * ui_scale), 22)

	_detail_panel = PanelContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# v5: 단청 스타일 상세 패널 — 금박 테두리, 그림자
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.12, 0.95)
	style.border_color = Color(0.83, 0.66, 0.26, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	style.shadow_size = 4
	_detail_panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(20 * ui_scale))
	margin.add_theme_constant_override("margin_right", int(20 * ui_scale))
	margin.add_theme_constant_override("margin_top", int(10 * ui_scale))
	margin.add_theme_constant_override("margin_bottom", int(10 * ui_scale))

	# 세로 배치로 변경 — 좁은 화면에서 가독성 확보
	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", int(12 * ui_scale))

	# 패시브 스킬 영역
	if character["passive_name"] != "":
		var p_header := Label.new()
		p_header.text = tr("CHARSEL_PASSIVE_PREFIX") + character["passive_name"]
		p_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p_header.add_theme_font_size_override("font_size", fs_header)
		p_header.add_theme_color_override("font_color", Color(0.83, 0.66, 0.26))
		detail_vbox.add_child(p_header)
		var p_desc := Label.new()
		p_desc.text = character["passive_desc"]
		p_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p_desc.add_theme_font_size_override("font_size", fs_desc)
		detail_vbox.add_child(p_desc)

	# 액티브 스킬 영역
	if character["active_name"] != "":
		var a_header := Label.new()
		a_header.text = tr("CHARSEL_ACTIVE_PREFIX") + character["active_name"]
		a_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		a_header.add_theme_font_size_override("font_size", fs_header)
		a_header.add_theme_color_override("font_color", Color(0.23, 0.49, 0.27))
		detail_vbox.add_child(a_header)
		var a_desc := Label.new()
		a_desc.text = character["active_desc"]
		a_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		a_desc.add_theme_font_size_override("font_size", fs_desc)
		detail_vbox.add_child(a_desc)

	# 시작 유물 영역
	if character["starting_relic_name"] != "":
		var r_header := Label.new()
		r_header.text = tr("CHARSEL_STARTING_RELIC") + character["starting_relic_name"]
		r_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		r_header.add_theme_font_size_override("font_size", fs_header)
		r_header.add_theme_color_override("font_color", Color(0.77, 0.61, 0.22))
		detail_vbox.add_child(r_header)
		var r_desc := Label.new()
		r_desc.text = character["starting_relic_effect"]
		r_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		r_desc.add_theme_font_size_override("font_size", fs_desc)
		detail_vbox.add_child(r_desc)

	margin.add_child(detail_vbox)
	_detail_panel.add_child(margin)

	# BottomBar 내에 삽입 (캐릭터 카드 아래)
	$BottomBar/VBoxContainer.add_child(_detail_panel)
	$BottomBar/VBoxContainer.move_child(_detail_panel, 0)


func _on_start_pressed() -> void:
	if _selected_index < 0:
		return
	var character_id: String = _character_list[_selected_index]["id"]
	GameManager.start_new_run(character_id)


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.TITLE)


func _build_achievement_button() -> void:
	## 업적 목록 토글 버튼을 버튼 행에 추가한다.
	var unlocked_ids := AchievementManager.get_unlocked_ids()
	var total := AchievementManager.get_all_achievements().size()

	var ach_button := Button.new()
	ach_button.text = tr("CHARSEL_ACHIEVEMENT_FMT") % [unlocked_ids.size(), total]
	ach_button.add_theme_font_size_override("font_size", 32)
	ach_button.pressed.connect(_toggle_achievement_panel)
	$BottomBar/VBoxContainer/ButtonRow.add_child(ach_button)


func _toggle_achievement_panel() -> void:
	if _achievement_panel and is_instance_valid(_achievement_panel):
		_achievement_panel.queue_free()
		_achievement_panel = null
		_achievement_visible = false
		return

	_achievement_visible = true
	_achievement_panel = _create_achievement_panel()
	add_child(_achievement_panel)


func _create_achievement_panel() -> PanelContainer:
	# 뷰포트 비례 스케일링
	var vp_size := get_viewport().get_visible_rect().size
	var ach_ui_scale := minf(vp_size.x / 1080.0, vp_size.y / 1920.0)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.05
	panel.anchor_right = 0.95
	panel.anchor_top = 0.1
	panel.anchor_bottom = 0.9

	# v5: 단청 스타일 업적 패널 — 금박 테두리, 깊은 배경
	var ach_style := StyleBoxFlat.new()
	ach_style.bg_color = Color(0.05, 0.04, 0.10, 0.97)
	ach_style.set_corner_radius_all(14)
	ach_style.border_color = Color(0.83, 0.66, 0.26, 0.8)
	ach_style.set_border_width_all(3)
	ach_style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	ach_style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", ach_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 12)

	# 제목 행
	var title_row := HBoxContainer.new()
	var title := Label.new()
	title.text = tr("CHARSEL_ACHIEVEMENT_LIST")
	title.add_theme_font_size_override("font_size", int(30 * ach_ui_scale))
	title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.26))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = tr("UI_CLOSE")
	close_btn.add_theme_font_size_override("font_size", int(28 * ach_ui_scale))
	close_btn.pressed.connect(_toggle_achievement_panel)
	title_row.add_child(close_btn)
	outer_vbox.add_child(title_row)

	outer_vbox.add_child(HSeparator.new())

	# 스크롤 컨테이너
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var list_vbox := VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var all_achs := AchievementManager.get_all_achievements()
	var meta := SaveManager.load_meta()
	var unlocked_list: Array = meta.get("unlocked_achievements", [])

	for ach in all_achs:
		var ach_id: String = ach.get("id", "")
		var is_unlocked: bool = ach_id in unlocked_list
		var progress := AchievementManager.get_progress(ach_id)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		# 달성 표시
		var status_label := Label.new()
		if is_unlocked:
			status_label.text = "★"
			status_label.add_theme_color_override("font_color", Color(0.83, 0.66, 0.26))
		else:
			status_label.text = "☆"
			status_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		status_label.add_theme_font_size_override("font_size", int(28 * ach_ui_scale))
		row.add_child(status_label)

		# 업적 정보
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 2)

		var name_label := Label.new()
		name_label.text = TranslationManager.trd(ach, "name", "")
		name_label.add_theme_font_size_override("font_size", int(22 * ach_ui_scale))
		if is_unlocked:
			name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		else:
			name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		info_vbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = TranslationManager.trd(ach, "description", "")
		desc_label.add_theme_font_size_override("font_size", int(18 * ach_ui_scale))
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		info_vbox.add_child(desc_label)

		row.add_child(info_vbox)

		# 진행도 표시
		var progress_label := Label.new()
		progress_label.text = "%d / %d" % [progress["current"], progress["target"]]
		progress_label.add_theme_font_size_override("font_size", int(20 * ach_ui_scale))
		if is_unlocked:
			progress_label.add_theme_color_override("font_color", Color(0.23, 0.49, 0.27))
		else:
			progress_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		row.add_child(progress_label)

		list_vbox.add_child(row)

	scroll.add_child(list_vbox)
	outer_vbox.add_child(scroll)
	margin.add_child(outer_vbox)
	panel.add_child(margin)

	return panel


func _apply_start_button_style() -> void:
	## v8: 시작 버튼을 금색 CTA로 강조
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.83, 0.66, 0.26, 0.2)
	style.set_border_width_all(2)
	style.border_color = Color(0.83, 0.66, 0.26, 0.9)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.83, 0.66, 0.26, 0.15)
	style.shadow_size = 8
	start_button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.83, 0.66, 0.26, 0.3)
	start_button.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.83, 0.66, 0.26, 0.4)
	start_button.add_theme_stylebox_override("pressed", pressed)
	start_button.add_theme_color_override("font_color", Color(0.83, 0.66, 0.26))
	start_button.add_theme_color_override("font_hover_color", Color(0.93, 0.78, 0.36))
	start_button.add_theme_font_size_override("font_size", 34)
	# 비활성 상태 — 회색 톤
	var disabled := style.duplicate()
	disabled.bg_color = Color(0.15, 0.12, 0.10, 0.5)
	disabled.border_color = Color(0.4, 0.35, 0.30, 0.5)
	disabled.shadow_size = 0
	start_button.add_theme_stylebox_override("disabled", disabled)
	start_button.add_theme_color_override("font_disabled_color", Color(0.5, 0.45, 0.40))


func _show_first_play_guide() -> void:
	## 첫 플레이 시 인터랙티브 튜토리얼을 제안한다.
	## 튜토리얼 미완료 시 전투 튜토리얼 또는 건너뛰기를 선택할 수 있다.
	if not is_inside_tree():
		return
	if GameManager.is_tutorial_completed():
		return

	# 뷰포트 비례 스케일링
	var vp_size := get_viewport().get_visible_rect().size
	var scale_x := vp_size.x / 1080.0
	var scale_y := vp_size.y / 1920.0
	var ui_scale := minf(scale_x, scale_y)

	# 가이드가 열리는 동안 캐릭터 선택 UI 숨김 — 시각적 혼란 방지
	card_container.visible = false
	start_button.visible = false

	# CanvasLayer로 씬 트리 위에 독립 렌더링 (입력 우선순위 확보)
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", int(40 * scale_x))
	margin.add_theme_constant_override("margin_right", int(40 * scale_x))
	margin.add_theme_constant_override("margin_top", int(60 * scale_y))
	margin.add_theme_constant_override("margin_bottom", int(60 * scale_y))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(24 * ui_scale))
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var guide_title := Label.new()
	guide_title.text = tr("CHARSEL_WELCOME")
	guide_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_title.add_theme_font_size_override("font_size", int(40 * ui_scale))
	guide_title.add_theme_color_override("font_color", Color(0.83, 0.66, 0.26))
	guide_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(guide_title)

	var guide_text := Label.new()
	guide_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_text.add_theme_font_size_override("font_size", int(28 * ui_scale))
	guide_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide_text.text = tr("CHARSEL_GUIDE_TEXT")
	vbox.add_child(guide_text)

	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", int(20 * ui_scale))
	btn_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tutorial_btn := Button.new()
	tutorial_btn.text = tr("CHARSEL_TUTORIAL_START")
	tutorial_btn.add_theme_font_size_override("font_size", int(28 * ui_scale))
	tutorial_btn.custom_minimum_size = Vector2(280 * ui_scale, 80 * ui_scale)
	tutorial_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_btn.pressed.connect(func():
		card_container.visible = true
		start_button.visible = true
		canvas_layer.queue_free()
		GameManager.start_tutorial()
	)
	btn_container.add_child(tutorial_btn)

	var skip_btn := Button.new()
	skip_btn.text = tr("CHARSEL_SKIP")
	skip_btn.add_theme_font_size_override("font_size", int(24 * ui_scale))
	skip_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	skip_btn.custom_minimum_size = Vector2(200 * ui_scale, 70 * ui_scale)
	skip_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_btn.pressed.connect(func():
		# 튜토리얼 완료 플래그 설정
		var meta := SaveManager.load_meta()
		meta["tutorial_completed"] = true
		SaveManager.save_meta(meta)
		card_container.visible = true
		start_button.visible = true
		canvas_layer.queue_free()
	)
	btn_container.add_child(skip_btn)

	vbox.add_child(btn_container)
	margin.add_child(vbox)
	overlay.add_child(margin)
	canvas_layer.add_child(overlay)
	add_child(canvas_layer)
