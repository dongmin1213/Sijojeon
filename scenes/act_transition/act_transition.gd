extends Control

## 막 전환 연출 씬. 새로운 막 이름과 설명을 표시한 후 맵으로 이동.

const ACT_DESCRIPTIONS := {
	1: "왕조의 수도, 한양.\n거리에는 불온한 기운이 감돌고 있다.",
	2: "험준한 산세의 지리산.\n산적과 요괴가 도사리는 위험한 길.",
	3: "왕좌를 노리는 역모의 심장부.\n경복궁의 내전에 최후의 결전이 기다린다.",
}

@onready var overlay: ColorRect = $Overlay
@onready var act_number_label: Label = $CenterContainer/VBoxContainer/ActNumberLabel
@onready var act_name_label: Label = $CenterContainer/VBoxContainer/ActNameLabel
@onready var act_desc_label: Label = $CenterContainer/VBoxContainer/ActDescLabel


func _ready() -> void:
	if GameManager.run_data == null:
		GameManager.change_state(GameManager.GameState.MAP)
		return

	var act: int = GameManager.run_data.current_act
	var act_name: String = MapGenerator.get_act_name(act)

	act_number_label.text = "제 %d 막" % act
	act_name_label.text = act_name
	act_desc_label.text = ACT_DESCRIPTIONS.get(act, "")

	# 페이드인 연출
	overlay.modulate.a = 1.0
	act_number_label.modulate.a = 0.0
	act_name_label.modulate.a = 0.0
	act_desc_label.modulate.a = 0.0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	# 배경 페이드
	tween.tween_property(overlay, "modulate:a", 0.85, 0.5)

	# 막 번호 등장
	tween.tween_property(act_number_label, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.3)

	# 막 이름 등장
	tween.tween_property(act_name_label, "modulate:a", 1.0, 0.8)
	tween.tween_interval(0.3)

	# 설명 등장
	tween.tween_property(act_desc_label, "modulate:a", 1.0, 0.6)

	# 2초 대기 후 맵으로 이동
	tween.tween_interval(2.0)
	tween.tween_callback(_go_to_map)


func _go_to_map() -> void:
	GameManager.change_state(GameManager.GameState.MAP)
