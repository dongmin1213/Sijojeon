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


func _ready() -> void:
	start_button.disabled = true
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_load_unlock_conditions()
	_build_character_list()
	_build_character_cards()
	_build_achievement_button()


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


func _build_character_list() -> void:
	## DataLoader에서 캐릭터 스킬 데이터를 가져와 표시용 목록을 구성한다.
	_character_list.clear()
	for char_id in CHARACTER_IDS:
		var skills: Dictionary = DataLoader.get_character_skills(char_id)
		var unlocked := _is_character_unlocked(char_id)

		# special_skills.json에서 상세 정보 추출
		var char_entry := _find_skill_entry(char_id)
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
			"name": char_entry.get("class_ko", char_id) + " (" + char_entry.get("class_hanja", "") + ")",
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
	for i in _character_list.size():
		var character: Dictionary = _character_list[i]
		var unlocked: bool = character["unlocked"]

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(300, 420)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_bottom", 12)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)

		# 캐릭터 이름
		var name_label := Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 22)
		if unlocked:
			name_label.text = character["name"]
		else:
			name_label.text = "??? (" + character["name"].split("(")[1] if "(" in character["name"] else "???"
		vbox.add_child(name_label)

		# HP / 기 정보
		var stat_label := Label.new()
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
			resource_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
			vbox.add_child(resource_label)

		vbox.add_child(HSeparator.new())

		if unlocked:
			# 패시브 스킬
			if character["passive_name"] != "":
				var passive_header := Label.new()
				passive_header.text = "▶ 패시브: " + character["passive_name"]
				passive_header.add_theme_font_size_override("font_size", 14)
				passive_header.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
				vbox.add_child(passive_header)

				var passive_desc := Label.new()
				passive_desc.text = character["passive_desc"]
				passive_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				passive_desc.add_theme_font_size_override("font_size", 13)
				vbox.add_child(passive_desc)

			# 액티브 스킬
			if character["active_name"] != "":
				var active_header := Label.new()
				active_header.text = "▶ 액티브: " + character["active_name"]
				active_header.add_theme_font_size_override("font_size", 14)
				active_header.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
				vbox.add_child(active_header)

				var active_desc := Label.new()
				active_desc.text = character["active_desc"]
				active_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				active_desc.add_theme_font_size_override("font_size", 13)
				vbox.add_child(active_desc)

			vbox.add_child(HSeparator.new())

			# 시작 유물
			if character["starting_relic_name"] != "":
				var relic_label := Label.new()
				relic_label.text = "시작 유물: " + character["starting_relic_name"]
				relic_label.add_theme_font_size_override("font_size", 14)
				relic_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
				vbox.add_child(relic_label)

				var relic_effect := Label.new()
				relic_effect.text = character["starting_relic_effect"]
				relic_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				relic_effect.add_theme_font_size_override("font_size", 12)
				vbox.add_child(relic_effect)

			# 선택 버튼
			var select_btn := Button.new()
			select_btn.text = "선택"
			select_btn.size_flags_vertical = Control.SIZE_SHRINK_END
			var idx := i
			select_btn.pressed.connect(func(): _select_character(idx))
			vbox.add_child(select_btn)
		else:
			# 잠금 상태 표시
			var lock_label := Label.new()
			lock_label.text = "[잠김]"
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_label.add_theme_font_size_override("font_size", 28)
			lock_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			vbox.add_child(lock_label)

			var cond_label := Label.new()
			cond_label.text = "해금 조건: " + character["unlock_description"]
			cond_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cond_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cond_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			vbox.add_child(cond_label)

		margin.add_child(vbox)
		panel.add_child(margin)

		# 잠금 캐릭터는 어둡게 표시
		if not unlocked:
			panel.modulate = Color(0.5, 0.5, 0.5)

		card_container.add_child(panel)


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
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "닫기"
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
		status_label.add_theme_font_size_override("font_size", 24)
		row.add_child(status_label)

		# 업적 정보
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 2)

		var name_label := Label.new()
		name_label.text = ach.get("name", "")
		name_label.add_theme_font_size_override("font_size", 18)
		if is_unlocked:
			name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		else:
			name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		info_vbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = ach.get("description", "")
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		info_vbox.add_child(desc_label)

		row.add_child(info_vbox)

		# 진행도 표시
		var progress_label := Label.new()
		progress_label.text = "%d / %d" % [progress["current"], progress["target"]]
		progress_label.add_theme_font_size_override("font_size", 16)
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
