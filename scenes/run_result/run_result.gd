extends Control

## 런 결과 화면. 클리어/사망 통계를 표시하고 메인메뉴로 복귀.

const CHARACTER_NAMES := {
	"dosa": "도사 (道士)",
	"mugwan": "무관 (武官)",
}

var _is_victory: bool = false

@onready var overlay: ColorRect = $Overlay
@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var stats_container: VBoxContainer = $CenterContainer/VBoxContainer/StatsContainer
@onready var button_container: HBoxContainer = $CenterContainer/VBoxContainer/ButtonContainer
@onready var title_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/TitleButton
@onready var retry_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/RetryButton


func _ready() -> void:
	_is_victory = GameManager.current_state == GameManager.GameState.RUN_WIN
	title_button.pressed.connect(_on_title_pressed)
	retry_button.pressed.connect(_on_retry_pressed)

	_setup_display()
	_populate_stats()
	_play_entrance_animation()


func _setup_display() -> void:
	if _is_victory:
		title_label.text = "승리"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		subtitle_label.text = "역모를 물리치고 왕조를 지켜냈다!"
		overlay.color = Color(0.02, 0.05, 0.08, 0.9)
	else:
		title_label.text = "패배"
		title_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
		subtitle_label.text = "어둠 속에 쓰러졌다..."
		overlay.color = Color(0.08, 0.02, 0.02, 0.9)


func _populate_stats() -> void:
	var rd: RunData = GameManager.run_data
	if rd == null:
		_add_stat_row("데이터 없음", "-")
		return

	var char_name: String = CHARACTER_NAMES.get(rd.character_id, rd.character_id)
	_add_stat_row("캐릭터", char_name)
	_add_stat_row("도달한 막", "제 %d 막" % rd.current_act)
	_add_stat_row("방문한 노드", "%d 개" % rd.visited_nodes.size())
	_add_stat_row("체력", "%d / %d" % [rd.current_hp, rd.max_hp])
	_add_stat_row("소지 금화", "%d 냥" % rd.gold)
	_add_stat_row("덱 카드 수", "%d 장" % rd.deck.size())
	_add_stat_row("강화한 카드", "%d 장" % rd.upgraded_cards.size())
	_add_stat_row("제거한 카드", "%d 장" % rd.card_removals_count)
	_add_stat_row("획득 유물", "%d 개" % rd.relics.size())

	# 누적 런 통계
	var meta := SaveManager.load_meta()
	if meta.has("stats"):
		var s: Dictionary = meta["stats"]
		_add_stat_row("", "")  # 빈 줄 구분
		_add_stat_row("총 도전 횟수", "%d 회" % s.get("total_runs", 0))
		_add_stat_row("총 승리", "%d 회" % s.get("victories", 0))
		_add_stat_row("총 패배", "%d 회" % s.get("deaths", 0))


func _add_stat_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	label.add_theme_font_size_override("font_size", 20)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	value.add_theme_font_size_override("font_size", 20)

	row.add_child(label)
	row.add_child(value)
	stats_container.add_child(row)


func _play_entrance_animation() -> void:
	# 초기 상태: 모두 투명
	overlay.modulate.a = 0.0
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	stats_container.modulate.a = 0.0
	button_container.modulate.a = 0.0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# 배경 페이드인
	tween.tween_property(overlay, "modulate:a", 1.0, 0.5)
	# 제목
	tween.tween_property(title_label, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.2)
	# 부제
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(0.3)
	# 통계
	tween.tween_property(stats_container, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.3)
	# 버튼
	tween.tween_property(button_container, "modulate:a", 1.0, 0.4)


func _on_title_pressed() -> void:
	GameManager.reset_to_title()


func _on_retry_pressed() -> void:
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)
