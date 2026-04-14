extends Control

## 디버그 전용 씬 진입 메뉴.
## 각 게임 씬으로 바로 이동할 수 있는 버튼을 제공한다.
## OS.is_debug_build() == true 일 때만 접근 가능.

const SCENES := [
	{"label": "전투 (Battle)", "state": "BATTLE"},
	{"label": "상점 (Shop)", "state": "SHOP"},
	{"label": "휴식처 (Rest)", "state": "REST"},
	{"label": "이벤트 (Event)", "state": "EVENT"},
	{"label": "맵 (Map)", "state": "MAP"},
	{"label": "보상 (Reward)", "state": "REWARD"},
	{"label": "막 전환 (Act Transition)", "state": "ACT_TRANSITION"},
	{"label": "설정 (Settings)", "state": "SETTINGS"},
	{"label": "튜토리얼 (Tutorial)", "state": "TUTORIAL"},
	{"label": "런 결과 - 승리", "state": "RUN_WIN"},
	{"label": "런 결과 - 패배", "state": "RUN_OVER"},
]

## 디버그 런에 사용할 캐릭터 ID
var debug_character_id: String = "dosa"

@onready var scroll: ScrollContainer = $ScrollContainer
@onready var vbox: VBoxContainer = $ScrollContainer/VBoxContainer


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# 제목
	var title := Label.new()
	title.text = "디버그 메뉴"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
	vbox.add_child(title)

	# 캐릭터 선택
	var char_label := Label.new()
	char_label.text = "캐릭터:"
	char_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(char_label)

	var char_hbox := HBoxContainer.new()
	char_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(char_hbox)

	# 6캐릭터 전체 지원 + 한국어 표시명
	var char_display := {
		"mugwan": "CHAR_NAME_MUGWAN",
		"mungwan": "CHAR_NAME_MUNGWAN",
		"dosa": "CHAR_NAME_DOSA",
		"uiwon": "CHAR_NAME_UIWON",
		"gungsu": "CHAR_NAME_GUNGSU",
		"sangin": "CHAR_NAME_SANGIN",
	}
	for char_id in ["mugwan", "mungwan", "dosa", "uiwon", "gungsu", "sangin"]:
		var btn := Button.new()
		var name_key: String = char_display.get(char_id, "")
		btn.text = tr(name_key) if name_key != "" else char_id
		btn.custom_minimum_size = Vector2(140, 56)
		btn.pressed.connect(_on_char_selected.bind(char_id))
		char_hbox.add_child(btn)

	# 구분선
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 16)
	vbox.add_child(sep)

	# 씬 버튼들
	for entry in SCENES:
		var btn := Button.new()
		btn.text = entry["label"]
		btn.custom_minimum_size = Vector2(0, 64)
		btn.add_theme_font_size_override("font_size", 26)
		btn.pressed.connect(_on_scene_pressed.bind(entry["state"]))
		vbox.add_child(btn)

	# 구분선
	var sep2 := HSeparator.new()
	sep2.add_theme_constant_override("separation", 16)
	vbox.add_child(sep2)

	# 돌아가기 버튼
	var back_btn := Button.new()
	back_btn.text = "타이틀로 돌아가기"
	back_btn.custom_minimum_size = Vector2(0, 64)
	back_btn.add_theme_font_size_override("font_size", 26)
	back_btn.pressed.connect(_on_back_pressed)
	vbox.add_child(back_btn)


func _on_char_selected(char_id: String) -> void:
	debug_character_id = char_id
	# 선택된 캐릭터 피드백 — 번역된 이름으로 비교
	var selected_name := tr("CHAR_NAME_" + char_id.to_upper())
	for child in $ScrollContainer/VBoxContainer.get_children():
		if child is HBoxContainer:
			for btn in child.get_children():
				if btn is Button:
					if btn.text == selected_name:
						btn.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
					else:
						btn.remove_theme_color_override("font_color")


func _on_scene_pressed(state_name: String) -> void:
	var state: GameManager.GameState = GameManager.GameState.get(state_name, GameManager.GameState.TITLE)
	# 런 데이터가 없으면 디버그용으로 생성 (씬 전환은 아래에서 직접 수행)
	if GameManager.run_data == null:
		GameManager.start_new_run(debug_character_id, 0, false)
	GameManager.change_state(state)


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.TITLE)
