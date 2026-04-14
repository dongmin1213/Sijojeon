extends Control

## 막 전환 연출 씬. 수묵화 스틸컷 + 내레이션 + 막 이름 표시.
## 서사 프레임(암행어사의 여정) 텍스트를 함께 표시한다.
## ZER-332: 수묵화 컷신 연출 강화

var ACT_DESCRIPTIONS := {
	1: "ACT_DESC_1",
	2: "ACT_DESC_2",
	3: "ACT_DESC_3",
}

# 막별 컷신 내레이션 (수묵화 스틸컷 느낌)
var ACT_CUTSCENE_LINES := {
	1: [
		{"ko": "세상이 어지러우니 암행어사가 나섰도다.", "en": "In troubled times, the secret inspector sets forth."},
		{"ko": "한양의 거리에는 탐관오리의 그림자가 드리워져 있었다.", "en": "The streets of Hanyang lay under the shadow of corrupt officials."},
		{"ko": "왕명을 받들어, 백성의 눈물을 닦아줄 자 — 그대뿐이로다.", "en": "By royal decree, only you can wipe the tears of the people."},
	],
	2: [
		{"ko": "한양을 벗어나니 산하가 험하고 민심이 흉흉하다.", "en": "Beyond Hanyang, the mountains are steep and the people restless."},
		{"ko": "지리산 깊은 곳에서 기이한 기운이 솟아오른다.", "en": "A strange energy rises from deep within Jirisan."},
		{"ko": "이곳의 진상을 밝히지 않으면 나라가 위태로우리라.", "en": "If the truth here is not uncovered, the kingdom falls."},
	],
	3: [
		{"ko": "드디어 역모의 심장부에 다다랐도다.", "en": "At last, you have reached the heart of the treason."},
		{"ko": "경복궁 안에 도사린 역적의 흉계가 드러나려 한다.", "en": "The treasonous plot lurking within Gyeongbokgung is about to be revealed."},
		{"ko": "최후의 대결이 기다린다.", "en": "The final confrontation awaits."},
	],
}

@onready var overlay: ColorRect = $Overlay
@onready var act_number_label: Label = $CenterContainer/VBoxContainer/ActNumberLabel
@onready var act_name_label: Label = $CenterContainer/VBoxContainer/ActNameLabel
@onready var act_desc_label: Label = $CenterContainer/VBoxContainer/ActDescLabel

# 수묵화 컷신 UI 요소 (동적 생성)
var _cutscene_label: Label = null
var _ink_wash_rect: ColorRect = null
var _brush_line: ColorRect = null


func _ready() -> void:
	if GameManager.run_data == null:
		GameManager.change_state(GameManager.GameState.MAP)
		return

	var act: int = GameManager.run_data.current_act
	var act_name: String = MapGenerator.get_act_name(act)

	act_number_label.text = tr("ACT_TRANSITION_FMT") % act
	act_name_label.text = act_name

	# 막 설명
	var desc_key: String = ACT_DESCRIPTIONS.get(act, "")
	var desc: String = tr(desc_key) if desc_key != "" else ""
	act_desc_label.text = desc

	# 수묵화 컷신 UI 생성
	_create_cutscene_ui()

	# 수묵화 컷신 연출 시작
	_play_cutscene(act)


## 수묵화 컷신용 UI 요소 생성
func _create_cutscene_ui() -> void:
	# 먹색 배경 (수묵화 배경)
	_ink_wash_rect = ColorRect.new()
	_ink_wash_rect.color = Color(0.06, 0.06, 0.08, 0.0)
	_ink_wash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ink_wash_rect.z_index = 10
	add_child(_ink_wash_rect)

	# 붓 획 장식선 (수묵 느낌)
	_brush_line = ColorRect.new()
	_brush_line.color = Color(0.10, 0.10, 0.10, 0.0)
	_brush_line.set_anchors_preset(Control.PRESET_CENTER)
	_brush_line.custom_minimum_size = Vector2(500, 3)
	_brush_line.size = Vector2(500, 3)
	_brush_line.position = Vector2(-250, 40)
	_brush_line.z_index = 11
	_ink_wash_rect.add_child(_brush_line)

	# 내레이션 텍스트
	_cutscene_label = Label.new()
	_cutscene_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cutscene_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cutscene_label.set_anchors_preset(Control.PRESET_CENTER)
	_cutscene_label.custom_minimum_size = Vector2(600, 100)
	_cutscene_label.size = Vector2(600, 100)
	_cutscene_label.position = Vector2(-300, -50)
	_cutscene_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cutscene_label.modulate.a = 0.0
	_cutscene_label.add_theme_font_size_override("font_size", 22)
	_cutscene_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))  # 한지색 글씨
	_cutscene_label.z_index = 12
	_ink_wash_rect.add_child(_cutscene_label)


## 수묵화 컷신 연출 재생
func _play_cutscene(act: int) -> void:
	var lines: Array = ACT_CUTSCENE_LINES.get(act, [])
	if lines.is_empty():
		_play_fallback_transition(act)
		return

	# 기본 UI 숨김 (컷신 먼저 재생)
	overlay.modulate.a = 0.0
	act_number_label.modulate.a = 0.0
	act_name_label.modulate.a = 0.0
	act_desc_label.modulate.a = 0.0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# 1단계: 수묵화 배경 페이드인
	tween.tween_property(_ink_wash_rect, "color:a", 0.92, 0.8)
	tween.tween_property(_brush_line, "color:a", 0.4, 0.5)
	tween.tween_interval(0.3)

	# 2단계: 내레이션 라인 순차 표시
	var locale := TranslationServer.get_locale()
	for i in lines.size():
		var line_data: Dictionary = lines[i]
		var text: String = line_data.get(locale, line_data.get("ko", ""))

		# 텍스트 설정 + 페이드인
		tween.tween_callback(func():
			_cutscene_label.text = text
		)
		tween.tween_property(_cutscene_label, "modulate:a", 1.0, 0.8)
		tween.tween_interval(2.5)  # 읽기 시간

		# 마지막 라인이 아니면 페이드아웃
		if i < lines.size() - 1:
			tween.tween_property(_cutscene_label, "modulate:a", 0.0, 0.5)
			tween.tween_interval(0.3)

	# 3단계: 마지막 라인 페이드아웃 + 수묵화 배경 페이드아웃
	tween.tween_property(_cutscene_label, "modulate:a", 0.0, 0.6)
	tween.tween_property(_brush_line, "color:a", 0.0, 0.4)
	tween.tween_property(_ink_wash_rect, "color:a", 0.0, 0.8)
	tween.tween_interval(0.3)

	# 4단계: 기존 막 전환 연출
	tween.tween_property(overlay, "modulate:a", 0.85, 0.5)
	tween.tween_property(act_number_label, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.3)
	tween.tween_property(act_name_label, "modulate:a", 1.0, 0.8)
	tween.tween_interval(0.3)
	tween.tween_property(act_desc_label, "modulate:a", 1.0, 0.6)

	tween.tween_interval(2.0)
	tween.tween_callback(_go_to_map)


## 컷신 데이터가 없을 때 기존 전환 연출 사용
func _play_fallback_transition(act: int) -> void:
	overlay.modulate.a = 1.0
	act_number_label.modulate.a = 0.0
	act_name_label.modulate.a = 0.0
	act_desc_label.modulate.a = 0.0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(overlay, "modulate:a", 0.85, 0.5)
	tween.tween_property(act_number_label, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.3)
	tween.tween_property(act_name_label, "modulate:a", 1.0, 0.8)
	tween.tween_interval(0.3)
	tween.tween_property(act_desc_label, "modulate:a", 1.0, 0.6)

	tween.tween_interval(2.0)
	tween.tween_callback(_go_to_map)


func _go_to_map() -> void:
	GameManager.change_state(GameManager.GameState.MAP)
