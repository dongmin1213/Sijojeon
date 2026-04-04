extends Control

## 캐릭터 선택 화면.
## DataLoader와 SaveManager를 활용하여 해금 상태, 시작 유물, 전용 자원을 표시한다.

# 캐릭터 정의 순서 (표시 순서)
const CHARACTER_IDS := ["mugwan", "mungwan", "dosa"]

var _selected_index: int = -1
var _character_list: Array[Dictionary] = []
var _unlock_data: Array[Dictionary] = []

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var card_container: HBoxContainer = $VBoxContainer/CardContainer
@onready var start_button: Button = $VBoxContainer/ButtonRow/StartButton
@onready var back_button: Button = $VBoxContainer/ButtonRow/BackButton


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
				# 해당 캐릭터로 승리한 적이 있거나, best_act가 min_act 이상이면 해금
				var req_char_stats: Dictionary = char_stats.get(req_char, {})
				if req_char_stats.get("victories", 0) > 0:
					return true
				# 해당 캐릭터로 런을 진행하여 min_act를 넘긴 적이 있으면 해금
				return stats.get("best_act", 0) > min_act and req_char_stats.get("runs", 0) > 0
	# 해금 조건이 정의되지 않은 캐릭터는 기본 해금
	return true


func _get_unlock_description(character_id: String) -> String:
	for cond in _unlock_data:
		if cond.get("id", "") == character_id:
			return cond.get("unlock_description", "")
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
			class_resource_name = char_entry["class_resource"].get("id", "")
			class_resource_max = char_entry["class_resource"].get("max", 0)

		var starting_relic_name := ""
		var starting_relic_effect := ""
		if char_entry.has("starting_relic"):
			starting_relic_name = char_entry["starting_relic"].get("name", {}).get("ko", "")
			starting_relic_effect = char_entry["starting_relic"].get("effect", "")

		var passive_name := ""
		var passive_desc := ""
		if skills.has("passive"):
			passive_name = skills["passive"].get("ko", "")
			passive_desc = skills["passive"].get("description", "")

		var active_name := ""
		var active_desc := ""
		if skills.has("active_skill") and skills["active_skill"].has("name"):
			active_name = skills["active_skill"]["name"].get("ko", "")
			active_desc = skills["active_skill"]["name"].get("description", "")

		_character_list.append({
			"id": char_id,
			"name": class_ko + " (" + class_hanja + ")",
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

	# 카드 수에 따라 패널 너비 계산 (화면에 맞게)
	var card_count := _character_list.size()
	var separation := int(card_container.get_theme_constant("separation"))
	var available_w := vp_size.x - 80.0  # VBoxContainer offset 40*2
	var panel_min_w := minf(300.0 * scale_x, (available_w - separation * (card_count - 1)) / card_count)
	var panel_min_h := 420.0 * ui_scale

	# 스케일된 폰트 크기 계산 (모바일 가독성 확보)
	var fs_name := maxi(int(34 * ui_scale), 30)
	var fs_stat := maxi(int(28 * ui_scale), 26)
	var fs_skill_header := maxi(int(26 * ui_scale), 24)
	var fs_skill_desc := maxi(int(22 * ui_scale), 22)
	var fs_lock := maxi(int(36 * ui_scale), 30)
	var margin_h := int(16 * ui_scale)
	var margin_v := int(12 * ui_scale)

	if _character_list.is_empty():
		push_warning("CharacterSelect: _character_list 비어있음 — 카드 생성 건너뜀")
		return

	# CardContainer에 최소 높이 보장 및 오버플로 방지
	card_container.custom_minimum_size = Vector2(0, panel_min_h)
	card_container.clip_contents = true
	print("[CharacterSelect] 카드 생성 시작: %d개, vp=%s, ui_scale=%.2f" % [_character_list.size(), str(vp_size), ui_scale])

	for i in _character_list.size():
		var character: Dictionary = _character_list[i]
		var unlocked: bool = character["unlocked"]

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(panel_min_w, panel_min_h)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.clip_contents = true

		# 카드 패널에 명확한 테두리·배경 스타일 적용 (어두운 배경과 구별)
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
		card_style.border_color = Color(0.5, 0.4, 0.25)
		card_style.border_width_top = 2
		card_style.border_width_bottom = 2
		card_style.border_width_left = 2
		card_style.border_width_right = 2
		card_style.corner_radius_top_left = 8
		card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_left = 8
		card_style.corner_radius_bottom_right = 8
		panel.add_theme_stylebox_override("panel", card_style)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", margin_h)
		margin.add_theme_constant_override("margin_right", margin_h)
		margin.add_theme_constant_override("margin_top", margin_v)
		margin.add_theme_constant_override("margin_bottom", margin_v)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", int(8 * ui_scale))

		# 캐릭터 이름
		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", fs_name)
		if unlocked:
			name_label.text = character["name"]
		else:
			name_label.text = "??? (" + character["name"].split("(")[1] if "(" in character["name"] else "???"
		vbox.add_child(name_label)

		# HP / 기 정보
		var stat_label := Label.new()
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_label.add_theme_font_size_override("font_size", fs_stat)
		if unlocked:
			stat_label.text = "HP: %d | 기: %d" % [character["hp"], character["qi"]]
		else:
			stat_label.text = "HP: ?? | 기: ??"
		vbox.add_child(stat_label)

		# 전용 자원 표시
		if character["class_resource_name"] != "" and unlocked:
			var resource_label := Label.new()
			resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			resource_label.text = "전용 자원: %s (최대 %d)" % [character["class_resource_name"], character["class_resource_max"]]
			resource_label.add_theme_font_size_override("font_size", fs_stat)
			resource_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
			vbox.add_child(resource_label)

		vbox.add_child(HSeparator.new())

		if unlocked:
			# 패시브 스킬
			if character["passive_name"] != "":
				var passive_header := Label.new()
				passive_header.text = "▶ 패시브: " + character["passive_name"]
				passive_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				passive_header.add_theme_font_size_override("font_size", fs_skill_header)
				passive_header.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
				vbox.add_child(passive_header)

				var passive_desc := Label.new()
				passive_desc.text = character["passive_desc"]
				passive_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				passive_desc.add_theme_font_size_override("font_size", fs_skill_desc)
				vbox.add_child(passive_desc)

			# 액티브 스킬
			if character["active_name"] != "":
				var active_header := Label.new()
				active_header.text = "▶ 액티브: " + character["active_name"]
				active_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				active_header.add_theme_font_size_override("font_size", fs_skill_header)
				active_header.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
				vbox.add_child(active_header)

				var active_desc := Label.new()
				active_desc.text = character["active_desc"]
				active_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				active_desc.add_theme_font_size_override("font_size", fs_skill_desc)
				vbox.add_child(active_desc)

			vbox.add_child(HSeparator.new())

			# 시작 유물
			if character["starting_relic_name"] != "":
				var relic_label := Label.new()
				relic_label.text = "시작 유물: " + character["starting_relic_name"]
				relic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				relic_label.add_theme_font_size_override("font_size", fs_skill_header)
				relic_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
				vbox.add_child(relic_label)

				var relic_effect := Label.new()
				relic_effect.text = character["starting_relic_effect"]
				relic_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				relic_effect.add_theme_font_size_override("font_size", fs_skill_desc)
				vbox.add_child(relic_effect)

			# 선택 안내 레이블 (카드 전체가 터치 가능하므로 버튼 대신 안내 표시)
			var select_hint := Label.new()
			select_hint.text = "▶ 탭하여 선택"
			select_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			select_hint.add_theme_font_size_override("font_size", fs_stat)
			select_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
			select_hint.size_flags_vertical = Control.SIZE_SHRINK_END
			vbox.add_child(select_hint)
		else:
			# 잠금 상태 표시
			var lock_label := Label.new()
			lock_label.text = "[잠김]"
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_label.add_theme_font_size_override("font_size", fs_lock)
			lock_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			vbox.add_child(lock_label)

			var cond_label := Label.new()
			cond_label.text = "해금 조건: " + character["unlock_description"]
			cond_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cond_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cond_label.add_theme_font_size_override("font_size", fs_skill_desc)
			cond_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			vbox.add_child(cond_label)

		margin.add_child(vbox)
		panel.add_child(margin)

		# 카드 전체를 탭 가능하게 설정 (모바일 터치 대응)
		# 내부 레이블/컨테이너가 터치를 소비하지 않도록 IGNORE 설정
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
		print("[CharacterSelect] 카드 추가: %s (unlocked=%s, size=%s)" % [character["name"], str(unlocked), str(panel.custom_minimum_size)])

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
	start_button.text = "시작: %s" % _character_list[index]["name"]

	# 선택 하이라이트
	for i in card_container.get_child_count():
		var panel: PanelContainer = card_container.get_child(i)
		if not _character_list[i]["unlocked"]:
			panel.modulate = Color(0.5, 0.5, 0.5)
		elif i == index:
			panel.modulate = Color(1.0, 1.0, 0.7)
		else:
			panel.modulate = Color(1.0, 1.0, 1.0)


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
	ach_button.text = "업적 (%d/%d)" % [unlocked_ids.size(), total]
	ach_button.add_theme_font_size_override("font_size", 32)
	ach_button.pressed.connect(_toggle_achievement_panel)
	$VBoxContainer/ButtonRow.add_child(ach_button)


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

	# 반투명 배경용 스타일
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = Color(0.6, 0.5, 0.3)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	panel.add_theme_stylebox_override("panel", style)

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
	title.text = "업적 목록"
	title.add_theme_font_size_override("font_size", int(30 * ach_ui_scale))
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "닫기"
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
			status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
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
		name_label.text = ach.get("name", "")
		name_label.add_theme_font_size_override("font_size", int(22 * ach_ui_scale))
		if is_unlocked:
			name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		else:
			name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		info_vbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = ach.get("description", "")
		desc_label.add_theme_font_size_override("font_size", int(18 * ach_ui_scale))
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		info_vbox.add_child(desc_label)

		row.add_child(info_vbox)

		# 진행도 표시
		var progress_label := Label.new()
		progress_label.text = "%d / %d" % [progress["current"], progress["target"]]
		progress_label.add_theme_font_size_override("font_size", int(20 * ach_ui_scale))
		if is_unlocked:
			progress_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		else:
			progress_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		row.add_child(progress_label)

		list_vbox.add_child(row)

	scroll.add_child(list_vbox)
	outer_vbox.add_child(scroll)
	margin.add_child(outer_vbox)
	panel.add_child(margin)

	return panel


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
	guide_title.text = "시조전에 오신 것을 환영합니다!"
	guide_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_title.add_theme_font_size_override("font_size", int(40 * ui_scale))
	guide_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	guide_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(guide_title)

	var guide_text := Label.new()
	guide_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_text.add_theme_font_size_override("font_size", int(28 * ui_scale))
	guide_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guide_text.text = """조선 시대를 배경으로 한 덱빌딩 로그라이크입니다.

처음 플레이하시나요?
인터랙티브 튜토리얼에서 전투의 기본을 배울 수 있습니다.

• 카드 사용법과 기(氣) 관리
• 시조(時調) 리듬 시스템
• 방어와 전투 전략"""
	vbox.add_child(guide_text)

	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", int(20 * ui_scale))
	btn_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tutorial_btn := Button.new()
	tutorial_btn.text = "튜토리얼 시작"
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
	skip_btn.text = "건너뛰기"
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
