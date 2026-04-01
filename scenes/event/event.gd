extends Control

## 랜덤 이벤트 씬 (임시 구현).

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var choice_container: VBoxContainer = $VBoxContainer/ChoiceContainer

var _event_data: Dictionary = {}


func _ready() -> void:
	_load_random_event()
	_build_ui()


func _load_random_event() -> void:
	var file := FileAccess.open("res://data/events/act1_events.json", FileAccess.READ)
	if file == null:
		_event_data = {"title": "알 수 없는 사건", "description": "아무 일도 일어나지 않았다.", "choices": []}
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or not (json.data is Dictionary):
		_event_data = {"title": "알 수 없는 사건", "description": "아무 일도 일어나지 않았다.", "choices": []}
		return

	var events: Array = json.data.get("events", [])
	if events.is_empty():
		_event_data = {"title": "알 수 없는 사건", "description": "아무 일도 일어나지 않았다.", "choices": []}
		return

	_event_data = events[randi() % events.size()]


func _build_ui() -> void:
	var name_data = _event_data.get("name", _event_data.get("title", "사건"))
	if name_data is Dictionary:
		title_label.text = name_data.get("ko", "사건")
	else:
		title_label.text = str(name_data)

	var desc_data = _event_data.get("description", "")
	if desc_data is Dictionary:
		description_label.text = desc_data.get("ko", "")
	else:
		description_label.text = str(desc_data)

	var choices: Array = _event_data.get("choices", [])
	if choices.is_empty():
		var btn := Button.new()
		btn.text = "돌아가기"
		btn.pressed.connect(_return_to_map)
		choice_container.add_child(btn)
	else:
		for choice in choices:
			var btn := Button.new()
			var choice_text = choice.get("text", choice.get("label", "선택"))
			if choice_text is Dictionary:
				btn.text = choice_text.get("ko", "선택")
			else:
				btn.text = str(choice_text)
			btn.pressed.connect(_on_choice_selected.bind(choice))
			choice_container.add_child(btn)


func _on_choice_selected(choice: Dictionary) -> void:
	var effects: Dictionary = choice.get("effects", {})
	if GameManager.run_data:
		var hp_change: int = effects.get("hp", 0)
		var gold_change: int = effects.get("gold", 0)
		GameManager.run_data.current_hp = clampi(
			GameManager.run_data.current_hp + hp_change, 0, GameManager.run_data.max_hp
		)
		GameManager.run_data.gold += gold_change

		# 유물 획득 처리
		var effect_type: String = effects.get("effect_type", "")
		if effect_type == "relic_gain":
			var count: int = effects.get("count", 1)
			for i in count:
				var relic_id := RelicManager.roll_relic_reward("event")
				if relic_id != "":
					RelicManager.acquire_relic(relic_id)
	_return_to_map()


func _return_to_map() -> void:
	GameManager.save_current_run()
	GameManager.change_state(GameManager.GameState.MAP)
