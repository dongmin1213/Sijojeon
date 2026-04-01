class_name BattleManager
extends Node

## 전투 흐름을 제어하는 매니저. 턴 루프와 상태 전환을 관리한다.

enum BattleState {
	BATTLE_START,
	PLAYER_TURN_START,
	PLAYER_ACTION,
	PLAYER_TURN_END,
	ENEMY_TURN,
	BATTLE_WIN,
	BATTLE_LOSE,
}

const HAND_SIZE := 5
const STARTING_QI := 3

var state: BattleState = BattleState.BATTLE_START
var current_qi: int = 0
var max_qi: int = STARTING_QI
var turn_number: int = 0

# 카드 더미
var draw_pile: Array[String] = []   # 드로우 파일 (card IDs)
var hand: Array[String] = []         # 손패
var discard_pile: Array[String] = [] # 버린 카드 더미
var exhaust_pile: Array[String] = [] # 소멸 카드 더미

# 전투 참여자
var player_hp: int = 70
var player_max_hp: int = 70
var player_block: int = 0
var enemies: Array[Dictionary] = []

# 시조 시스템
var sijo_system: SijoSystem = null

signal state_changed(new_state: BattleState)
signal qi_changed(current: int, max_val: int)
signal hand_changed(new_hand: Array[String])
signal block_changed(new_block: int)
signal hp_changed(current: int, max_val: int)
signal card_drawn(card_id: String)
signal turn_started(turn: int)
signal enemy_intent_shown(enemy_index: int, intent: Dictionary)
signal battle_ended(victory: bool)


func start_battle(deck: Array[String], enemy_data: Array[Dictionary], hp: int, max_hp: int, qi: int) -> void:
	player_hp = hp
	player_max_hp = max_hp
	max_qi = qi
	turn_number = 0
	player_block = 0
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()

	# 덱 셔플
	draw_pile = deck.duplicate()
	_shuffle_draw_pile()

	# 적 초기화
	enemies.clear()
	for e in enemy_data:
		var enemy := e.duplicate(true)
		var hp_data = enemy.get("hp", {})
		if hp_data is Dictionary:
			enemy["current_hp"] = randi_range(hp_data.get("min", 20), hp_data.get("max", 30))
			enemy["max_hp"] = enemy["current_hp"]
		elif hp_data is int:
			enemy["current_hp"] = hp_data
			enemy["max_hp"] = hp_data
		enemy["block"] = 0
		enemy["move_index"] = 0
		enemies.append(enemy)

	# 시조 시스템 초기화
	if sijo_system:
		sijo_system.reset()

	_change_state(BattleState.BATTLE_START)
	begin_player_turn()


func begin_player_turn() -> void:
	turn_number += 1
	player_block = 0
	block_changed.emit(player_block)
	current_qi = max_qi
	qi_changed.emit(current_qi, max_qi)
	turn_started.emit(turn_number)

	_change_state(BattleState.PLAYER_TURN_START)

	# 카드 드로우
	draw_cards(HAND_SIZE)

	# 적 인텐트 표시
	for i in enemies.size():
		if enemies[i]["current_hp"] > 0:
			var intent := _get_enemy_intent(i)
			enemy_intent_shown.emit(i, intent)

	_change_state(BattleState.PLAYER_ACTION)


func try_play_card(hand_index: int, target_enemy_index: int = 0) -> bool:
	if state != BattleState.PLAYER_ACTION:
		return false
	if hand_index < 0 or hand_index >= hand.size():
		return false

	var card_id: String = hand[hand_index]
	var card: CardData = DataLoader.get_card(card_id)
	if card == null:
		return false

	# 기(氣) 확인
	if card.cost > current_qi:
		return false

	# 기 소비
	current_qi -= card.cost
	qi_changed.emit(current_qi, max_qi)

	# 시조 슬롯 시도
	if sijo_system:
		sijo_system.try_fill_slot(card.beat, card_id)

	# 손패에서 제거 → 버린 카드로
	hand.remove_at(hand_index)
	discard_pile.append(card_id)
	hand_changed.emit(hand)

	return true


func end_player_turn() -> void:
	if state != BattleState.PLAYER_ACTION:
		return

	_change_state(BattleState.PLAYER_TURN_END)

	# 손패 → 버린 카드 더미
	for card_id in hand:
		discard_pile.append(card_id)
	hand.clear()
	hand_changed.emit(hand)

	# 적 턴 시작
	execute_enemy_turn()


func execute_enemy_turn() -> void:
	_change_state(BattleState.ENEMY_TURN)

	for i in enemies.size():
		var enemy := enemies[i]
		if enemy["current_hp"] <= 0:
			continue

		enemy["block"] = 0
		var intent := _get_enemy_intent(i)
		_execute_enemy_action(i, intent)

		# 행동 인덱스 진행
		var moves: Array = enemy.get("moves", [])
		if moves.size() > 0:
			enemy["move_index"] = (enemy["move_index"] + 1) % moves.size()

	# 전투 종료 확인
	if player_hp <= 0:
		_change_state(BattleState.BATTLE_LOSE)
		battle_ended.emit(false)
		return

	if _all_enemies_dead():
		_change_state(BattleState.BATTLE_WIN)
		battle_ended.emit(true)
		return

	# 다음 플레이어 턴
	begin_player_turn()


func draw_cards(count: int) -> void:
	for i in count:
		if draw_pile.is_empty():
			_reshuffle_discard()
		if draw_pile.is_empty():
			break
		var card_id: String = draw_pile.pop_back()
		hand.append(card_id)
		card_drawn.emit(card_id)
	hand_changed.emit(hand)


func take_damage(amount: int) -> void:
	var remaining := amount
	if player_block > 0:
		var blocked := mini(player_block, remaining)
		player_block -= blocked
		remaining -= blocked
		block_changed.emit(player_block)
	if remaining > 0:
		player_hp -= remaining
		player_hp = maxi(player_hp, 0)
		hp_changed.emit(player_hp, player_max_hp)


func gain_block(amount: int) -> void:
	player_block += amount
	block_changed.emit(player_block)


# --- 내부 함수 ---

func _change_state(new_state: BattleState) -> void:
	state = new_state
	state_changed.emit(new_state)


func _shuffle_draw_pile() -> void:
	for i in range(draw_pile.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var temp: String = draw_pile[i]
		draw_pile[i] = draw_pile[j]
		draw_pile[j] = temp


func _reshuffle_discard() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	_shuffle_draw_pile()


func _get_enemy_intent(enemy_index: int) -> Dictionary:
	var enemy := enemies[enemy_index]
	var moves: Array = enemy.get("moves", [])
	if moves.is_empty():
		return {"type": "attack", "damage": 6}
	var idx: int = enemy.get("move_index", 0) % moves.size()
	return moves[idx]


func _execute_enemy_action(enemy_index: int, intent: Dictionary) -> void:
	var action_type: String = intent.get("type", "attack")
	match action_type:
		"attack":
			var damage: int = intent.get("damage", 0)
			take_damage(damage)
		"multi_attack":
			var damage: int = intent.get("damage", 0)
			var hits: int = intent.get("hits", 1)
			for h in hits:
				take_damage(damage)
		"defend":
			var block: int = intent.get("block", 0)
			enemies[enemy_index]["block"] += block
		"buff":
			pass  # TODO: 상태이상 시스템에서 처리
		"debuff":
			pass  # TODO: 플레이어 디버프 적용


func _all_enemies_dead() -> bool:
	for enemy in enemies:
		if enemy["current_hp"] > 0:
			return false
	return true
