extends Control

## 런 결과 화면. 클리어/사망 통계를 표시하고 메인메뉴로 복귀.

var CHARACTER_NAMES := {
	"dosa": "CHAR_NAME_DOSA",
	"mugwan": "CHAR_NAME_MUGWAN",
	"mungwan": "CHAR_NAME_MUNGWAN",
	"uiwon": "CHAR_NAME_UIWON",
	"gungsu": "CHAR_NAME_GUNGSU",
	"sangin": "CHAR_NAME_SANGIN",
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
	_check_card_unlocks()
	_populate_achievements()
	_play_entrance_animation()


func _setup_display() -> void:
	# v5: 단청 팔레트 결과 화면 + 엔딩 분기
	if _is_victory:
		title_label.text = tr("RESULT_VICTORY")
		title_label.add_theme_color_override("font_color", Color(0.83, 0.63, 0.09))
		# 엔딩 제목 표시
		var ending_name := _get_ending_display_name()
		if ending_name != "":
			subtitle_label.text = ending_name
		else:
			subtitle_label.text = tr("RESULT_VICTORY_SUBTITLE")
		overlay.color = Color(0.04, 0.04, 0.08, 0.92)
	else:
		title_label.text = tr("RESULT_DEFEAT")
		title_label.add_theme_color_override("font_color", Color(0.78, 0.29, 0.19))
		subtitle_label.text = tr("RESULT_DEFEAT_SUBTITLE_ALT")
		overlay.color = Color(0.08, 0.04, 0.04, 0.92)


func _populate_stats() -> void:
	var rd: RunData = GameManager.run_data
	if rd == null:
		_add_stat_row(tr("RESULT_NO_DATA"), "-")
		return

	var char_name_key: String = CHARACTER_NAMES.get(rd.character_id, "")
	var char_name: String = tr(char_name_key) if char_name_key != "" else rd.character_id
	_add_stat_row(tr("RESULT_CHARACTER"), char_name)
	_add_stat_row(tr("RESULT_ACT_REACHED"), tr("RESULT_ACT_FMT") % rd.current_act)
	_add_stat_row(tr("RESULT_NODES_VISITED"), tr("RESULT_NODES_FMT") % rd.visited_nodes.size())
	_add_stat_row(tr("RESULT_HP"), "%d / %d" % [rd.current_hp, rd.max_hp])
	_add_stat_row(tr("RESULT_GOLD_HELD"), tr("RESULT_GOLD_FMT") % rd.gold)
	_add_stat_row(tr("RESULT_DECK_SIZE"), tr("RESULT_UNIT_CARDS") % rd.deck.size())
	_add_stat_row(tr("RESULT_UPGRADED"), tr("RESULT_UNIT_CARDS") % rd.upgraded_cards.size())
	_add_stat_row(tr("RESULT_REMOVED"), tr("RESULT_UNIT_CARDS") % rd.card_removals_count)
	_add_stat_row(tr("RESULT_RELICS"), tr("RESULT_UNIT_COUNT") % rd.relics.size())

	# 누적 런 통계
	var meta := SaveManager.load_meta()
	if meta.has("stats"):
		var s: Dictionary = meta["stats"]
		_add_stat_row("", "")  # 빈 줄 구분
		_add_stat_row(tr("RESULT_TOTAL_RUNS"), tr("RESULT_UNIT_TIMES") % s.get("total_runs", 0))
		_add_stat_row(tr("RESULT_TOTAL_VICTORIES"), tr("RESULT_UNIT_TIMES") % s.get("victories", 0))
		_add_stat_row(tr("RESULT_TOTAL_DEFEATS"), tr("RESULT_UNIT_TIMES") % s.get("deaths", 0))


func _populate_achievements() -> void:
	## 이번 런에서 달성된 업적을 표시한다.
	var meta := SaveManager.load_meta()
	var unlocked_ids: Array = meta.get("unlocked_achievements", [])
	if unlocked_ids.is_empty():
		return

	_add_stat_row("", "")
	_add_stat_row(tr("RESULT_ACHIEVEMENTS"), "")

	var all_achs := AchievementManager.get_all_achievements()
	var unlocked_count := 0
	for ach in all_achs:
		var ach_id: String = ach.get("id", "")
		if ach_id in unlocked_ids:
			unlocked_count += 1
			var name_text: String = "★ " + TranslationManager.trd(ach, "name", "")
			_add_stat_row(name_text, TranslationManager.trd(ach, "description", ""))

	_add_stat_row(tr("RESULT_ACHIEVEMENT_RATE"), "%d / %d" % [unlocked_count, all_achs.size()])


func _check_card_unlocks() -> void:
	## 런 종료 시 카드 해금 조건 체크 + 시조 메타 누적
	var rd: RunData = GameManager.run_data
	if rd == null:
		return
	# 시조 완성 수를 메타에 누적
	if rd.sisang_count > 0:
		CardUnlockSystem.add_sijo_completion_to_meta(rd.sisang_count)
	# 카드 해금 체크
	var newly_unlocked := CardUnlockSystem.check_and_unlock(_is_victory, rd.character_id)
	if newly_unlocked.is_empty():
		return
	# 해금된 카드 표시
	_add_stat_row("", "")
	_add_stat_row(tr("RESULT_CARDS_UNLOCKED"), "")
	for card_id in newly_unlocked:
		var card: CardData = DataLoader.get_card(card_id)
		var card_name := card_id
		if card:
			card_name = card.get_display_name()
		_add_stat_row("★ " + card_name, tr("RESULT_CARD_UNLOCKED_DESC"))


func _add_stat_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.65, 0.58, 0.48))
	label.add_theme_font_size_override("font_size", 24)

	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_color_override("font_color", Color(0.90, 0.85, 0.72))
	value.add_theme_font_size_override("font_size", 24)

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


## 엔딩 이름 표시용 — endings.json에서 결정된 엔딩의 한국어 이름을 가져온다.
func _get_ending_display_name() -> String:
	var rd: RunData = GameManager.run_data
	if rd == null:
		return ""
	var ending_id: String = rd.narrative_state.get("determined_ending", "")
	if ending_id == "":
		return ""
	# endings.json 로딩
	var file := FileAccess.open("res://data/narrative/endings.json", FileAccess.READ)
	if file == null:
		return ""
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return ""
	var data: Dictionary = json.data
	for ending in data.get("endings", []):
		if ending.get("id", "") == ending_id:
			var name_dict: Dictionary = ending.get("name", {})
			return name_dict.get("ko", ending_id)
	return ""
