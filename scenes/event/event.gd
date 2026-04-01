extends Control

## 랜덤 이벤트 씬.
## 현재 막(act)에 맞는 이벤트를 로드하고, 선택지 UI를 표시하며,
## 효과를 적용한 뒤 결과 텍스트를 보여준다.

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var flavor_label: Label = $VBoxContainer/FlavorLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var choice_container: VBoxContainer = $VBoxContainer/ChoiceContainer
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var hp_label: Label = $VBoxContainer/StatusBar/HPLabel
@onready var gold_label: Label = $VBoxContainer/StatusBar/GoldLabel

var _event_data: Dictionary = {}


func _ready() -> void:
	continue_button.pressed.connect(_return_to_map)
	continue_button.visible = false
	result_label.visible = false
	_load_random_event()
	_build_ui()
	_update_status_bar()


func _load_random_event() -> void:
	var act := 1
	if GameManager.run_data:
		act = GameManager.run_data.current_act

	var path := "res://data/events/act%d_events.json" % act
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		# 해당 막 이벤트 파일이 없으면 1막 폴백
		file = FileAccess.open("res://data/events/act1_events.json", FileAccess.READ)
	if file == null:
		_event_data = {"title": {"ko": "알 수 없는 사건"}, "description": {"ko": ""}, "choices": []}
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or not (json.data is Dictionary):
		_event_data = {"title": {"ko": "알 수 없는 사건"}, "description": {"ko": ""}, "choices": []}
		return

	var events: Array = json.data.get("events", [])
	if events.is_empty():
		_event_data = {"title": {"ko": "알 수 없는 사건"}, "description": {"ko": ""}, "choices": []}
		return

	_event_data = events[randi() % events.size()]


## 한국어 텍스트를 추출한다. Dictionary면 "ko" 키, String이면 그대로.
func _get_text(data) -> String:
	if data is Dictionary:
		return str(data.get("ko", ""))
	return str(data) if data != null else ""


## 설명 텍스트 추출. title 딕셔너리의 description 키 또는 별도 description 필드.
func _get_description() -> String:
	var title_data = _event_data.get("title", {})
	if title_data is Dictionary and title_data.has("description"):
		return str(title_data["description"])
	return _get_text(_event_data.get("description", ""))


func _build_ui() -> void:
	title_label.text = _get_text(_event_data.get("title", "사건"))
	description_label.text = _get_description()

	# 분위기 텍스트
	var flavor: String = _get_text(_event_data.get("flavor_text", ""))
	flavor_label.text = flavor
	flavor_label.visible = flavor != ""

	# 선택지 버튼 생성
	var choices: Array = _event_data.get("choices", [])
	if choices.is_empty():
		var btn := Button.new()
		btn.text = "돌아가기"
		btn.pressed.connect(_return_to_map)
		choice_container.add_child(btn)
	else:
		for choice in choices:
			var btn := Button.new()
			btn.text = _get_text(choice.get("text", "선택"))
			# 골드 부족 시 비활성화 (gold_loss 효과)
			if _is_gold_insufficient(choice):
				btn.disabled = true
				btn.tooltip_text = "엽전이 부족합니다"
			btn.pressed.connect(_on_choice_selected.bind(choice))
			choice_container.add_child(btn)


## 선택지의 골드 비용을 확인하여 부족하면 true 반환.
func _is_gold_insufficient(choice: Dictionary) -> bool:
	if not GameManager.run_data:
		return false
	var effect_type: String = str(choice.get("effect_type", ""))
	if effect_type == "gold_loss":
		var cost: int = int(choice.get("effect_value", 0))
		if GameManager.run_data.gold < cost:
			return true
	return false


func _on_choice_selected(choice: Dictionary) -> void:
	if not GameManager.run_data:
		_show_result("아무 일도 일어나지 않았다.")
		return

	var result_text: String = ""
	var effect_type: String = str(choice.get("effect_type", "none"))

	# 메인 효과 적용
	result_text = _apply_effect(choice, effect_type)

	# 보너스 효과 적용
	var bonus_type: String = str(choice.get("effect_type_bonus", ""))
	if bonus_type != "":
		var bonus_text := _apply_bonus_effect(choice, bonus_type)
		if bonus_text != "":
			result_text += "\n" + bonus_text

	# 결과 텍스트가 비어있으면 JSON의 result_text 사용
	if result_text == "":
		result_text = str(choice.get("result_text", "아무 일도 일어나지 않았다."))

	_show_result(result_text)
	_update_status_bar()


## 메인 효과를 적용하고 결과 텍스트를 반환한다.
func _apply_effect(choice: Dictionary, effect_type: String) -> String:
	var value: int = int(choice.get("effect_value", 0))
	var rd := GameManager.run_data

	match effect_type:
		"hp_gain":
			rd.current_hp = mini(rd.current_hp + value, rd.max_hp)
			return str(choice.get("result_text", "HP %d 회복." % value))

		"hp_loss":
			rd.current_hp = maxi(rd.current_hp - value, 0)
			var text: String = str(choice.get("result_text", "HP %d 손실." % value))
			if rd.current_hp <= 0:
				# 사망 처리는 맵 복귀 시 GameManager에서 체크
				text += "\n...의식이 아득해진다."
			return text

		"hp_full_heal":
			rd.current_hp = rd.max_hp
			return str(choice.get("result_text", "HP 완전 회복!"))

		"max_hp_gain":
			rd.max_hp += value
			rd.current_hp += value
			return str(choice.get("result_text", "최대 HP +%d." % value))

		"max_hp_loss":
			rd.max_hp = maxi(rd.max_hp - value, 1)
			rd.current_hp = mini(rd.current_hp, rd.max_hp)
			return str(choice.get("result_text", "최대 HP -%d." % value))

		"gold_gain":
			rd.gold += value
			return str(choice.get("result_text", "엽전 %d 획득." % value))

		"gold_loss":
			rd.gold = maxi(rd.gold - value, 0)
			return str(choice.get("result_text", "엽전 %d 소비." % value))

		"gold_random":
			return _apply_gold_random(choice)

		"relic_gain":
			var count: int = int(choice.get("effect_value", 1))
			for i in count:
				var relic_id := RelicManager.roll_relic_reward("event")
				if relic_id != "":
					RelicManager.acquire_relic(relic_id)
			return str(choice.get("result_text", "유물 획득!"))

		"card_gain":
			# TODO: 카드 선택 UI 추가 시 확장
			return str(choice.get("result_text", "카드 획득."))

		"debuff":
			# 다음 전투 시작 시 디버프 적용 — run_data에 저장
			var debuff_type: String = str(choice.get("debuff_type", "약화"))
			if not rd.has_meta("next_combat_debuffs"):
				rd.set_meta("next_combat_debuffs", [])
			var debuffs: Array = rd.get_meta("next_combat_debuffs")
			debuffs.append({"type": debuff_type, "stacks": value})
			rd.set_meta("next_combat_debuffs", debuffs)
			return str(choice.get("result_text", "다음 전투 시작 시 %s %d 적용." % [debuff_type, value]))

		"buff_next_combat":
			var bonus_val = choice.get("effect_value_bonus", {})
			if bonus_val is Dictionary:
				if not rd.has_meta("next_combat_buffs"):
					rd.set_meta("next_combat_buffs", [])
				var buffs: Array = rd.get_meta("next_combat_buffs")
				buffs.append(bonus_val)
				rd.set_meta("next_combat_buffs", buffs)
			return str(choice.get("result_text", "다음 전투에 버프가 적용된다."))

		"random":
			return _apply_random_outcome(choice)

		"none", "":
			return str(choice.get("result_text", "아무 일도 일어나지 않았다."))

	return str(choice.get("result_text", ""))


## 도박형 골드 랜덤 효과를 적용한다.
func _apply_gold_random(choice: Dictionary) -> String:
	var win_chance: float = float(choice.get("win_chance", 0.5))
	var rd := GameManager.run_data

	if randf() < win_chance:
		# 승리
		var win_value: int = int(choice.get("effect_value_win", 0))
		rd.gold += win_value
		return str(choice.get("result_text_win", "엽전 %d 획득!" % win_value))
	else:
		# 패배
		var lose_value: int = abs(int(choice.get("effect_value_lose", 0)))
		rd.gold = maxi(rd.gold - lose_value, 0)
		return str(choice.get("result_text_lose", "엽전 %d 소실." % lose_value))


## 가중치 기반 랜덤 결과를 적용한다.
func _apply_random_outcome(choice: Dictionary) -> String:
	var outcomes: Array = choice.get("outcomes", [])
	if outcomes.is_empty():
		return str(choice.get("result_text", "아무 일도 일어나지 않았다."))

	# 가중치 합산
	var total_weight := 0
	for outcome in outcomes:
		total_weight += int(outcome.get("weight", 1))

	# 랜덤 선택
	var roll := randi() % total_weight
	var cumulative := 0
	var selected: Dictionary = outcomes[0]
	for outcome in outcomes:
		cumulative += int(outcome.get("weight", 1))
		if roll < cumulative:
			selected = outcome
			break

	# 선택된 결과의 효과 적용
	var sub_type: String = str(selected.get("effect_type", "none"))
	var sub_value: int = int(selected.get("effect_value", 0))
	var rd := GameManager.run_data

	match sub_type:
		"gold_gain":
			rd.gold += sub_value
		"gold_loss":
			rd.gold = maxi(rd.gold - sub_value, 0)
		"hp_gain":
			rd.current_hp = mini(rd.current_hp + sub_value, rd.max_hp)
		"hp_loss":
			rd.current_hp = maxi(rd.current_hp - sub_value, 0)
		"card_gain":
			pass  # TODO: 카드 선택 UI
		"relic_gain":
			var relic_id := RelicManager.roll_relic_reward("event")
			if relic_id != "":
				RelicManager.acquire_relic(relic_id)

	return str(selected.get("text", "결과가 나왔다."))


## 보너스 효과를 적용하고 결과 텍스트를 반환한다.
func _apply_bonus_effect(choice: Dictionary, bonus_type: String) -> String:
	var bonus_value = choice.get("effect_value_bonus", 0)
	var rd := GameManager.run_data

	match bonus_type:
		"hp_gain":
			var val: int = int(bonus_value)
			rd.current_hp = mini(rd.current_hp + val, rd.max_hp)
			return ""  # result_text_full에 포함됨

		"hp_full_heal":
			rd.current_hp = rd.max_hp
			return ""

		"max_hp_gain":
			var val: int = int(bonus_value)
			rd.max_hp += val
			rd.current_hp += val
			return ""

		"max_hp_loss":
			var val: int = int(bonus_value)
			rd.max_hp = maxi(rd.max_hp - val, 1)
			rd.current_hp = mini(rd.current_hp, rd.max_hp)
			return ""

		"gold_gain":
			var val: int = int(bonus_value)
			rd.gold += val
			return ""

		"relic_gain":
			var count: int = int(bonus_value) if bonus_value is int or bonus_value is float else 1
			for i in count:
				var relic_id := RelicManager.roll_relic_reward("event")
				if relic_id != "":
					RelicManager.acquire_relic(relic_id)
			return ""

		"buff_next_combat":
			if bonus_value is Dictionary:
				if not rd.has_meta("next_combat_buffs"):
					rd.set_meta("next_combat_buffs", [])
				var buffs: Array = rd.get_meta("next_combat_buffs")
				buffs.append(bonus_value)
				rd.set_meta("next_combat_buffs", buffs)
			return ""

	return ""


## 결과 텍스트를 표시하고 선택지를 숨긴다.
func _show_result(text: String) -> void:
	# 선택지 숨기기
	for child in choice_container.get_children():
		child.queue_free()
	choice_container.visible = false

	# 결과 표시
	result_label.text = text
	result_label.visible = true
	continue_button.visible = true
	continue_button.grab_focus()


## 상태 바를 업데이트한다.
func _update_status_bar() -> void:
	if GameManager.run_data:
		hp_label.text = "HP: %d/%d" % [GameManager.run_data.current_hp, GameManager.run_data.max_hp]
		gold_label.text = "엽전: %d" % GameManager.run_data.gold
	else:
		hp_label.text = "HP: --/--"
		gold_label.text = "엽전: --"


func _return_to_map() -> void:
	GameManager.save_current_run()
	# HP가 0 이하면 런 종료
	if GameManager.run_data and GameManager.run_data.current_hp <= 0:
		GameManager.end_run(false)
	else:
		GameManager.change_state(GameManager.GameState.MAP)
