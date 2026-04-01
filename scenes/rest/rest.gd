extends Control

## 휴식 씬: HP 회복 또는 카드 제거 선택.

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var hp_label: Label = $VBoxContainer/HPLabel
@onready var rest_button: Button = $VBoxContainer/RestButton
@onready var remove_button: Button = $VBoxContainer/RemoveButton

const HEAL_PERCENT := 0.3


func _ready() -> void:
	_update_hp_display()
	rest_button.pressed.connect(_on_rest)
	remove_button.pressed.connect(_on_remove_card)

	if GameManager.run_data == null or GameManager.run_data.deck.is_empty():
		remove_button.disabled = true


func _update_hp_display() -> void:
	if GameManager.run_data:
		var rd := GameManager.run_data
		hp_label.text = "HP: %d/%d" % [rd.current_hp, rd.max_hp]


func _on_rest() -> void:
	if GameManager.run_data:
		var rd := GameManager.run_data
		var heal_amount: int = int(rd.max_hp * HEAL_PERCENT)
		rd.current_hp = mini(rd.current_hp + heal_amount, rd.max_hp)
	_return_to_map()


func _on_remove_card() -> void:
	if GameManager.run_data and not GameManager.run_data.deck.is_empty():
		var deck := GameManager.run_data.deck
		var idx: int = randi() % deck.size()
		deck.remove_at(idx)
		GameManager.run_data.card_removals_count += 1
	_return_to_map()


func _return_to_map() -> void:
	GameManager.save_current_run()
	GameManager.change_state(GameManager.GameState.MAP)
