extends Control

## 연대기 (메타 진행) 화면.
## 전체 진행률, 캐릭터별 클리어 기록, 업적 목록을 표시한다.

# 캐릭터 표시 이름 매핑
const CHARACTER_NAMES := {
	"mugwan": "무관 (武官)",
	"mungwan": "문관 (文官)",
	"dosa": "도사 (道士)",
}

# 캐릭터 ID 순서
const CHARACTER_ORDER := ["mugwan", "mungwan", "dosa"]

# 색상 상수
const COLOR_GOLD := Color(1.0, 0.85, 0.3)
const COLOR_CREAM := Color(1.0, 0.95, 0.8)
const COLOR_DIM := Color(0.6, 0.55, 0.45)
const COLOR_GREEN := Color(0.5, 0.9, 0.5)
const COLOR_RED := Color(0.9, 0.3, 0.3)
const COLOR_LABEL := Color(0.7, 0.65, 0.55)
const COLOR_BG := Color(0.05, 0.05, 0.1, 0.95)


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 스크롤 컨테이너
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	# 메인 컨테이너
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 24)
	scroll.add_child(main)

	# 상단/하단 여백
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	margin.add_child(content)

	# 제목
	var title := Label.new()
	title.text = "연대기"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Chronicle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", COLOR_DIM)
	content.add_child(subtitle)

	content.add_child(HSeparator.new())

	# 메타 데이터 로드
	var meta := SaveManager.load_meta()
	var stats: Dictionary = meta.get("stats", {})
	var char_stats: Dictionary = meta.get("character_stats", {})

	# ── 전체 통계 섹션 ──
	_add_section_header(content, "전체 진행률")
	_build_overall_stats(content, stats)

	content.add_child(HSeparator.new())

	# ── 캐릭터별 기록 섹션 ──
	_add_section_header(content, "캐릭터별 기록")
	_build_character_stats(content, char_stats)

	content.add_child(HSeparator.new())

	# ── 업적 섹션 ──
	var achievements := AchievementManager.get_all_achievements()
	var unlocked_ids := AchievementManager.get_unlocked_ids()
	_add_section_header(content, "업적 (%d/%d)" % [unlocked_ids.size(), achievements.size()])
	_build_achievements(content, achievements, unlocked_ids)

	content.add_child(HSeparator.new())

	# 뒤로 가기 버튼
	var back_button := Button.new()
	back_button.text = "돌아가기"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(_on_back_pressed)
	content.add_child(back_button)


func _add_section_header(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", COLOR_CREAM)
	parent.add_child(label)


## 전체 통계 표시
func _build_overall_stats(parent: Control, stats: Dictionary) -> void:
	var total_runs: int = stats.get("total_runs", 0)
	var victories: int = stats.get("victories", 0)
	var deaths: int = stats.get("deaths", 0)
	var best_act: int = stats.get("best_act", 0)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(grid)

	_add_stat_row(grid, "총 도전 횟수", str(total_runs))
	_add_stat_row(grid, "승리", str(victories), COLOR_GREEN)
	_add_stat_row(grid, "패배", str(deaths), COLOR_RED)
	_add_stat_row(grid, "최고 도달 막", "%d막" % best_act if best_act > 0 else "-")

	# 승률 표시
	if total_runs > 0:
		var win_rate := float(victories) / float(total_runs) * 100.0
		_add_stat_row(grid, "승률", "%.1f%%" % win_rate)


func _add_stat_row(grid: GridContainer, label_text: String, value_text: String, value_color := COLOR_CREAM) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", COLOR_LABEL)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 20)
	value.add_theme_color_override("font_color", value_color)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(value)


## 캐릭터별 클리어 기록 표시
func _build_character_stats(parent: Control, char_stats: Dictionary) -> void:
	for char_id in CHARACTER_ORDER:
		var char_name: String = CHARACTER_NAMES.get(char_id, char_id)
		var cstats: Dictionary = char_stats.get(char_id, {})
		var runs: int = cstats.get("runs", 0)
		var victories: int = cstats.get("victories", 0)

		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.07, 0.14, 0.9)
		style.border_color = COLOR_DIM if victories == 0 else COLOR_GOLD
		style.border_width_bottom = 1
		style.border_width_top = 1
		style.border_width_left = 1
		style.border_width_right = 1
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.content_margin_left = 16.0
		style.content_margin_right = 16.0
		style.content_margin_top = 12.0
		style.content_margin_bottom = 12.0
		panel.add_theme_stylebox_override("panel", style)
		parent.add_child(panel)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		panel.add_child(vbox)

		# 캐릭터 이름
		var name_label := Label.new()
		name_label.text = char_name
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", COLOR_GOLD if victories > 0 else COLOR_LABEL)
		vbox.add_child(name_label)

		# 통계 행
		var stats_row := HBoxContainer.new()
		stats_row.add_theme_constant_override("separation", 20)
		vbox.add_child(stats_row)

		var runs_label := Label.new()
		runs_label.text = "도전: %d회" % runs
		runs_label.add_theme_font_size_override("font_size", 16)
		runs_label.add_theme_color_override("font_color", COLOR_CREAM)
		stats_row.add_child(runs_label)

		var wins_label := Label.new()
		wins_label.text = "승리: %d회" % victories
		wins_label.add_theme_font_size_override("font_size", 16)
		wins_label.add_theme_color_override("font_color", COLOR_GREEN if victories > 0 else COLOR_DIM)
		stats_row.add_child(wins_label)

		# 클리어 여부 표시
		if victories > 0:
			var clear_label := Label.new()
			clear_label.text = "★ 클리어"
			clear_label.add_theme_font_size_override("font_size", 16)
			clear_label.add_theme_color_override("font_color", COLOR_GOLD)
			clear_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			clear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			stats_row.add_child(clear_label)


## 업적 목록 표시 (달성/미달성)
func _build_achievements(parent: Control, achievements: Array[Dictionary], unlocked_ids: Array[String]) -> void:
	for ach in achievements:
		var ach_id: String = ach.get("id", "")
		var is_unlocked: bool = ach_id in unlocked_ids
		var progress := AchievementManager.get_progress(ach_id)

		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.07, 0.14, 0.9) if is_unlocked else Color(0.05, 0.04, 0.08, 0.7)
		style.border_color = COLOR_GOLD if is_unlocked else Color(0.3, 0.28, 0.25)
		style.border_width_bottom = 1
		style.border_width_top = 1
		style.border_width_left = 1
		style.border_width_right = 1
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		style.content_margin_left = 14.0
		style.content_margin_right = 14.0
		style.content_margin_top = 10.0
		style.content_margin_bottom = 10.0
		panel.add_theme_stylebox_override("panel", style)
		parent.add_child(panel)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		panel.add_child(hbox)

		# 달성 아이콘
		var icon_label := Label.new()
		icon_label.text = "★" if is_unlocked else "☆"
		icon_label.add_theme_font_size_override("font_size", 22)
		icon_label.add_theme_color_override("font_color", COLOR_GOLD if is_unlocked else COLOR_DIM)
		icon_label.custom_minimum_size = Vector2(30, 0)
		hbox.add_child(icon_label)

		# 업적 정보
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(info_vbox)

		var name_label := Label.new()
		name_label.text = ach.get("name", "")
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", COLOR_CREAM if is_unlocked else COLOR_DIM)
		info_vbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = ach.get("description", "")
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", COLOR_LABEL if is_unlocked else Color(0.45, 0.4, 0.35))
		info_vbox.add_child(desc_label)

		# 진행도 표시
		var progress_label := Label.new()
		progress_label.text = "%d/%d" % [progress.get("current", 0), progress.get("target", 1)]
		progress_label.add_theme_font_size_override("font_size", 16)
		progress_label.add_theme_color_override("font_color", COLOR_GREEN if is_unlocked else COLOR_DIM)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(progress_label)


func _on_back_pressed() -> void:
	GameManager.reset_to_title()
