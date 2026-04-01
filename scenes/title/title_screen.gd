extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	continue_button.visible = SaveManager.has_run_save()
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)
	# TODO: character_select 씬으로 전환


func _on_continue_pressed() -> void:
	if SaveManager.load_run():
		GameManager.change_state(GameManager.GameState.MAP)
		# TODO: map 씬으로 전환


func _on_quit_pressed() -> void:
	get_tree().quit()
