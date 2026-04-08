extends Control

## 연대기 (메타 진행) 화면.
## 전체 진행률, 캐릭터별 클리어 기록, 업적 목록을 표시한다.

# 캐릭터 표시 이름 매핑
var CHARACTER_NAMES := {
	"mugwan": "CHAR_NAME_MUGWAN",
	"mungwan": "CHAR_NAME_MUNGWAN",
	"dosa": "CHAR_NAME_DOSA",
}

# 캐릭터 ID 순서
const CHARACTER_ORDER := ["mugwan", "mungwan", "dosa"]

# 색상 상수 — v4: 단청 팔레트
const COLOR_GOLD := Color(0.76, 0.23, 0.13)
const COLOR_CREAM := Color(0.92, 0.88, 0.80)
const COLOR_DIM := Color(0.55, 0.50, 0.42)
const COLOR_GREEN := Color(0.24, 0.67, 0.43)
const COLOR_RED := Color(0.78, 0.29, 0.19)
const COLOR_LABEL := Color(0.62, 0.56, 0.46)
const COLOR_BG := Color(0.05, 0.04, 0.08, 0.95)

# 모바일 폰트 크기 스케일
const FONT_TITLE := 56
const FONT_SUBTITLE := 28
const FONT_SECTION := 38
const FONT_STAT_LABEL := 28
const FONT_STAT_VALUE := 30
const FONT_CHAR_NAME := 32
const FONT_CHAR_STAT := 24
const FONT_ACH_ICON := 32
const FONT_ACH_NAME := 28
const FONT_ACH_DESC := 22
const FONT_ACH_PROGRESS := 24


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 스크롤 컨테이너
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	# 메인 컨테이너 (마우스 이벤트 무시 → 스크롤 성능 개선)
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 24)
	main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(main)

	# 상단/하단 여백
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)

	# 제목
	var title := Label.new()
	title.text = tr("CHRONICLE_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", FONT_TITLE)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = ""
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", FONT_SUBTITLE)
	subtitle.add_theme_color_override("font_color", COLOR_DIM)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(subtitle)

	content.add_child(HSeparator.new())

	# 메타 데이터 로드
	var meta := SaveManager.load_meta()
	var stats: Dictionary = meta.get("stats", {})
	var char_stats: Dictionary = meta.get("character_stats", {})

	# ── 전체 통계 섹션 ──
	_add_section_header(content, tr("CHRONICLE_OVERALL"))
	_build_overall_stats(content, stats)

	content.add_child(HSeparator.new())

	# ── 캐릭터별 기록 섹션 ──
	_add_section_header(content, tr("CHRONICLE_CHARACTER_RECORDS"))
	_build_character_stats(content, char_stats)

	content.add_child(HSeparator.new())

	# ── 업적 섹션 ── (meta를 재사용하여 디스크 I/O 반복 방지)
	var achievements := AchievementManager.get_all_achievements()
	var unlocked_ids := AchievementManager.get_unlocked_ids(meta)
	_add_section_header(content, tr("CHRONICLE_ACHIEVEMENT_FMT") % [unlocked_ids.size(), achievements.size()])
	_build_achievements(content, achievements, unlocked_ids, meta)

	content.add_child(HSeparator.new())

	# 뒤로 가기 버튼
	var back_button := Button.new()
	back_button.text = tr("UI_BACK")
	back_button.custom_minimum_size = Vector2(200, 70)
	back_button.add_theme_font_size_override("font_size", 28)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(_on_back_pressed)
	content.add_child(back_button)


func _add_section_header(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SECTION)
	label.add_theme_color_override("font_color", COLOR_CREAM)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(grid)

	_add_stat_row(grid, tr("CHRONICLE_TOTAL_RUNS"), str(total_runs))
	_add_stat_row(grid, tr("CHRONICLE_VICTORIES"), str(victories), COLOR_GREEN)
	_add_stat_row(grid, tr("CHRONICLE_DEFEATS"), str(deaths), COLOR_RED)
	_add_stat_row(grid, tr("RESULT_ACT_REACHED"), "%d" % best_act if best_act > 0 else "-")

	# 승률 표시
	if total_runs > 0:
		var win_rate := float(victories) / float(total_runs) * 100.0
		_add_stat_row(grid, tr("CHRONICLE_WIN_RATE"), "%.1f%%" % win_rate)


func _add_stat_row(grid: GridContainer, label_text: String, value_text: String, value_color := COLOR_CREAM) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", FONT_STAT_LABEL)
	label.add_theme_color_override("font_color", COLOR_LABEL)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", FONT_STAT_VALUE)
	value.add_theme_color_override("font_color", value_color)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_child(value)


## 캐릭터 패널용 StyleBoxFlat 템플릿 생성
static func _create_char_style_template() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.14, 0.9)
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
	return style


## 캐릭터별 클리어 기록 표시
func _build_character_stats(parent: Control, char_stats: Dictionary) -> void:
	var style_template := _create_char_style_template()

	for char_id in CHARACTER_ORDER:
		var char_name_key: String = CHARACTER_NAMES.get(char_id, "")
		var char_name: String = tr(char_name_key) if char_name_key != "" else char_id
		var cstats: Dictionary = char_stats.get(char_id, {})
		var runs: int = cstats.get("runs", 0)
		var victories: int = cstats.get("victories", 0)

		var panel := PanelContainer.new()
		var style: StyleBoxFlat = style_template.duplicate()
		style.border_color = COLOR_DIM if victories == 0 else COLOR_GOLD
		panel.add_theme_stylebox_override("panel", style)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(panel)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(vbox)

		# 캐릭터 이름
		var name_label := Label.new()
		name_label.text = char_name
		name_label.add_theme_font_size_override("font_size", FONT_CHAR_NAME)
		name_label.add_theme_color_override("font_color", COLOR_GOLD if victories > 0 else COLOR_LABEL)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(name_label)

		# 통계 행
		var stats_row := HBoxContainer.new()
		stats_row.add_theme_constant_override("separation", 20)
		stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(stats_row)

		var runs_label := Label.new()
		runs_label.text = tr("CHRONICLE_RUNS_FMT") % runs
		runs_label.add_theme_font_size_override("font_size", FONT_CHAR_STAT)
		runs_label.add_theme_color_override("font_color", COLOR_CREAM)
		runs_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats_row.add_child(runs_label)

		var wins_label := Label.new()
		wins_label.text = tr("CHRONICLE_WINS_FMT") % victories
		wins_label.add_theme_font_size_override("font_size", FONT_CHAR_STAT)
		wins_label.add_theme_color_override("font_color", COLOR_GREEN if victories > 0 else COLOR_DIM)
		wins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats_row.add_child(wins_label)

		# 클리어 여부 표시
		if victories > 0:
			var clear_label := Label.new()
			clear_label.text = tr("CHRONICLE_CLEARED")
			clear_label.add_theme_font_size_override("font_size", FONT_CHAR_STAT)
			clear_label.add_theme_color_override("font_color", COLOR_GOLD)
			clear_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			clear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			clear_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stats_row.add_child(clear_label)


## 업적 패널용 StyleBoxFlat 템플릿 생성 (달성/미달성)
static func _create_ach_style_templates() -> Array[StyleBoxFlat]:
	var unlocked := StyleBoxFlat.new()
	unlocked.bg_color = Color(0.08, 0.07, 0.14, 0.9)
	unlocked.border_color = COLOR_GOLD
	unlocked.border_width_bottom = 1
	unlocked.border_width_top = 1
	unlocked.border_width_left = 1
	unlocked.border_width_right = 1
	unlocked.corner_radius_top_left = 4
	unlocked.corner_radius_top_right = 4
	unlocked.corner_radius_bottom_left = 4
	unlocked.corner_radius_bottom_right = 4
	unlocked.content_margin_left = 14.0
	unlocked.content_margin_right = 14.0
	unlocked.content_margin_top = 10.0
	unlocked.content_margin_bottom = 10.0

	var locked := StyleBoxFlat.new()
	locked.bg_color = Color(0.05, 0.04, 0.08, 0.7)
	locked.border_color = Color(0.3, 0.28, 0.25)
	locked.border_width_bottom = 1
	locked.border_width_top = 1
	locked.border_width_left = 1
	locked.border_width_right = 1
	locked.corner_radius_top_left = 4
	locked.corner_radius_top_right = 4
	locked.corner_radius_bottom_left = 4
	locked.corner_radius_bottom_right = 4
	locked.content_margin_left = 14.0
	locked.content_margin_right = 14.0
	locked.content_margin_top = 10.0
	locked.content_margin_bottom = 10.0

	return [unlocked, locked]


## 업적 목록 표시 (달성/미달성)
func _build_achievements(parent: Control, achievements: Array[Dictionary], unlocked_ids: Array[String], meta: Dictionary = {}) -> void:
	# 모든 업적 진행도를 한 번에 로드 (meta 재사용으로 디스크 I/O 제거)
	var all_progress := AchievementManager.get_all_progress(meta)
	# StyleBoxFlat 템플릿 생성 (달성/미달성 2개만 만들어 duplicate)
	var style_templates := _create_ach_style_templates()

	for ach in achievements:
		var ach_id: String = ach.get("id", "")
		var is_unlocked: bool = ach_id in unlocked_ids
		var progress: Dictionary = all_progress.get(ach_id, { "current": 0, "target": 1 })

		var panel := PanelContainer.new()
		var style: StyleBoxFlat = style_templates[0].duplicate() if is_unlocked else style_templates[1].duplicate()
		panel.add_theme_stylebox_override("panel", style)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(panel)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(hbox)

		# 달성 아이콘
		var icon_label := Label.new()
		icon_label.text = "★" if is_unlocked else "☆"
		icon_label.add_theme_font_size_override("font_size", FONT_ACH_ICON)
		icon_label.add_theme_color_override("font_color", COLOR_GOLD if is_unlocked else COLOR_DIM)
		icon_label.custom_minimum_size = Vector2(40, 0)
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon_label)

		# 업적 정보
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 2)
		info_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(info_vbox)

		var name_label := Label.new()
		name_label.text = TranslationManager.trd(ach, "name", "")
		name_label.add_theme_font_size_override("font_size", FONT_ACH_NAME)
		name_label.add_theme_color_override("font_color", COLOR_CREAM if is_unlocked else COLOR_DIM)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_vbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = TranslationManager.trd(ach, "description", "")
		desc_label.add_theme_font_size_override("font_size", FONT_ACH_DESC)
		desc_label.add_theme_color_override("font_color", COLOR_LABEL if is_unlocked else Color(0.45, 0.4, 0.35))
		desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_vbox.add_child(desc_label)

		# 진행도 표시
		var progress_label := Label.new()
		progress_label.text = "%d/%d" % [progress.get("current", 0), progress.get("target", 1)]
		progress_label.add_theme_font_size_override("font_size", FONT_ACH_PROGRESS)
		progress_label.add_theme_color_override("font_color", COLOR_GREEN if is_unlocked else COLOR_DIM)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_label.custom_minimum_size = Vector2(80, 0)
		progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(progress_label)


func _on_back_pressed() -> void:
	GameManager.reset_to_title()
