extends Control

## 막 전환 연출 씬. 새로운 막 이름과 설명을 표시한 후 맵으로 이동.
## 서사 프레임(암행어사의 여정) 텍스트를 함께 표시한다.

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

	# 막 설명 + 서사 텍스트 결합
	var desc: String = ACT_DESCRIPTIONS.get(act, "")
	var narrative := _get_narrative_text_for_act(act)
	if narrative != "":
		desc += "\n\n" + narrative
	act_desc_label.text = desc

	# 1막 시작 시 서사 stage 초기화
	_update_narrative_stage(act)

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

	# 서사 텍스트가 있으면 추가 대기 시간
	var wait_time := 2.0 if narrative == "" else 3.5
	tween.tween_interval(wait_time)
	tween.tween_callback(_go_to_map)


## 현재 막에 맞는 서사 텍스트를 반환한다.
func _get_narrative_text_for_act(act: int) -> String:
	if not GameManager.run_data:
		return ""
	var rd := GameManager.run_data
	var stage: int = rd.narrative_state.get("amhaengosa_stage", 0)

	# 이미 표시한 서사는 스킵
	var shown: Array = rd.narrative_state.get("shown_narrative_stages", [])

	var file := FileAccess.open("res://data/narrative/amhaengosa_journey.json", FileAccess.READ)
	if file == null:
		return ""
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return ""
	file.close()

	var stages: Array = json.data.get("stages", [])

	# 1막 시작 — stage 0 표시
	if act == 1 and not shown.has(0):
		for s in stages:
			if s.get("stage") == 0:
				shown.append(0)
				rd.narrative_state["shown_narrative_stages"] = shown
				return "— %s —\n%s" % [TranslationManager.trd(s, "title", ""), TranslationManager.trd(s, "text", "")]

	# 3막 진입 — stage 3 표시
	if act == 3 and not shown.has(3):
		for s in stages:
			if s.get("stage") == 3:
				shown.append(3)
				rd.narrative_state["shown_narrative_stages"] = shown
				return "— %s —\n%s" % [TranslationManager.trd(s, "title", ""), TranslationManager.trd(s, "text", "")]

	# stage 2 (조사 단계 진입 직후) — 2막 전환 시 표시
	if stage >= 2 and not shown.has(2):
		for s in stages:
			if s.get("stage") == 2:
				shown.append(2)
				rd.narrative_state["shown_narrative_stages"] = shown
				return "— %s —\n%s" % [TranslationManager.trd(s, "title", ""), TranslationManager.trd(s, "text", "")]

	return ""


## 막 전환 시 서사 stage를 업데이트한다.
func _update_narrative_stage(act: int) -> void:
	if not GameManager.run_data:
		return
	var rd := GameManager.run_data
	# 1막 시작: stage 0 → 1 (탐문)
	if act == 1 and rd.narrative_state.get("amhaengosa_stage", 0) == 0:
		rd.narrative_state["amhaengosa_stage"] = 1
	# 3막 진입: stage → 3 (처단)
	if act == 3:
		var current_stage: int = rd.narrative_state.get("amhaengosa_stage", 0)
		if current_stage < 3:
			rd.narrative_state["amhaengosa_stage"] = 3


func _go_to_map() -> void:
	GameManager.change_state(GameManager.GameState.MAP)
