extends Control

## 캐릭터 선택 화면. 도사/무관/문관 중 하나를 선택하여 새 런을 시작한다.

const CHARACTERS := [
	{
		"id": "dosa",
		"name": "도사 (道士)",
		"hp": 70,
		"description": "기(氣) 관리와 술법으로 싸우는 수행자.\n패시브: 천지기 — 턴 종료 시 시조 슬롯 3칸 이상이면 기 1 회복.",
	},
	{
		"id": "mugwan",
		"name": "무관 (武官)",
		"hp": 80,
		"description": "병사 토큰과 진형으로 전장을 지배하는 장수.\n패시브: 지휘통솔 — 병사 토큰 보유 시 매 턴 방어도 +2.",
	},
	{
		"id": "mungwan",
		"name": "문관 (文官)",
		"hp": 65,
		"description": "학식(學識)을 쌓아 지략으로 적을 제압하는 관료.\n패시브: 학식충전 — 턴 종료 시 카드 3장 이상 사용 시 학식 1 획득.",
	},
]

var _selected_index: int = -1

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var card_container: HBoxContainer = $VBoxContainer/CardContainer
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready() -> void:
	start_button.disabled = true
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_build_character_cards()


func _build_character_cards() -> void:
	for i in CHARACTERS.size():
		var character: Dictionary = CHARACTERS[i]
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(280, 320)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 12)

		var name_label := Label.new()
		name_label.text = character["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 22)
		vbox.add_child(name_label)

		var hp_label := Label.new()
		hp_label.text = "HP: %d" % character["hp"]
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(hp_label)

		var sep := HSeparator.new()
		vbox.add_child(sep)

		var desc_label := Label.new()
		desc_label.text = character["description"]
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(desc_label)

		var select_btn := Button.new()
		select_btn.text = "선택"
		var idx := i
		select_btn.pressed.connect(func(): _select_character(idx))
		vbox.add_child(select_btn)

		panel.add_child(vbox)
		card_container.add_child(panel)


func _select_character(index: int) -> void:
	_selected_index = index
	start_button.disabled = false
	start_button.text = "시작: %s" % CHARACTERS[index]["name"]

	# Update visual highlight
	for i in card_container.get_child_count():
		var panel: PanelContainer = card_container.get_child(i)
		if i == index:
			panel.modulate = Color(1.0, 1.0, 0.7)
		else:
			panel.modulate = Color(1.0, 1.0, 1.0)


func _on_start_pressed() -> void:
	if _selected_index < 0:
		return
	var character_id: String = CHARACTERS[_selected_index]["id"]
	GameManager.start_new_run(character_id)


func _on_back_pressed() -> void:
	GameManager.change_state(GameManager.GameState.TITLE)
