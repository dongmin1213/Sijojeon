extends Node

## 게임 전체 상태를 관리하는 오토로드 싱글톤.

enum GameState {
	TITLE,
	CHARACTER_SELECT,
	MAP,
	BATTLE,
	REWARD,
	SHOP,
	EVENT,
	REST,
	RUN_RESULT,
}

var current_state: GameState = GameState.TITLE

# 런 데이터
var current_character: String = ""
var current_act: int = 1
var max_acts: int = 3
var player_hp: int = 80
var player_max_hp: int = 80
var player_gold: int = 99
var deck: Array = []
var relics: Array = []

signal state_changed(new_state: GameState)


func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)


func start_new_run(character: String) -> void:
	current_character = character
	current_act = 1
	player_hp = player_max_hp
	player_gold = 99
	deck.clear()
	relics.clear()
	# 기본 덱은 DataLoader에서 로드
	deck = DataLoader.get_starter_deck(character)
	change_state(GameState.MAP)


func reset_to_title() -> void:
	current_character = ""
	current_act = 1
	player_hp = player_max_hp
	player_gold = 99
	deck.clear()
	relics.clear()
	change_state(GameState.TITLE)
