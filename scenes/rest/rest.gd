extends Control

## 휴식 씬: HP 회복 또는 카드 강화 선택.
## 메인 선택 → 카드 강화 시 덱에서 미강화 카드 목록 표시 → 선택 → 강화 적용.

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var hp_label: Label = $VBoxContainer/StatusBar/HPLabel
@onready var gold_label: Label = $VBoxContainer/StatusBar/GoldLabel
@onready var rest_button: Button = $VBoxContainer/ActionContainer/RestButton
@onready var upgrade_button: Button = $VBoxContainer/ActionContainer/UpgradeButton
@onready var action_container: VBoxContainer = $VBoxContainer/ActionContainer
@onready var card_list_container: VBoxContainer = $VBoxContainer/CardListContainer
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton

const HEAL_PERCENT := 0.3


func _ready() -> void:
	rest_button.pressed.connect(_on_rest)
	upgrade_button.pressed.connect(_on_show_upgrade_list)
	back_button.pressed.connect(_on_back_to_actions)
	continue_button.pressed.connect(_return_to_map)

	# 초기 상태
	card_list_container.visible = false
	back_button.visible = false
	result_label.visible = false
	continue_button.visible = false

	_update_status_bar()
	_update_action_states()


## 액션 버튼 활성화 상태를 갱신한다.
func _update_action_states() -> void:
	if GameManager.run_data == null:
		rest_button.disabled = true
		upgrade_button.disabled = true
		return

	var rd := GameManager.run_data
	# HP가 이미 최대면 휴식 비활성화
	rest_button.disabled = rd.current_hp >= rd.max_hp
	# 강화 가능한 카드가 없으면 비활성화
	upgrade_button.disabled = _get_upgradeable_cards().is_empty()


## 덱에서 아직 강화되지 않은 카드 목록을 반환한다.
func _get_upgradeable_cards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if GameManager.run_data == null:
		return result

	var rd := GameManager.run_data
	# 덱 내 카드별로 중복 ID 인덱스를 추적
	var seen_ids: Dictionary = {}
	for i in rd.deck.size():
		var card_id: String = rd.deck[i]
		# 동일 ID 카드가 여러 장일 수 있으므로, 이미 강화된 횟수 확인
		if not seen_ids.has(card_id):
			seen_ids[card_id] = 0
		seen_ids[card_id] += 1

		# 해당 카드 ID가 upgraded_cards에 등록된 횟수보다 현재 인덱스의 등장 횟수가 많으면 미강화
		var upgraded_count: int = rd.upgraded_cards.count(card_id)
		if seen_ids[card_id] > upgraded_count:
			var card_data: CardData = DataLoader.get_card(card_id)
			if card_data:
				result.append({"deck_index": i, "card_id": card_id, "card_data": card_data})
	return result


# --- 휴식 (HP 회복) ---

func _on_rest() -> void:
	if GameManager.run_data == null:
		return

	var rd := GameManager.run_data
	var heal_amount: int = int(rd.max_hp * HEAL_PERCENT)
	var actual_heal: int = mini(heal_amount, rd.max_hp - rd.current_hp)
	rd.current_hp = mini(rd.current_hp + actual_heal, rd.max_hp)

	AudioManager.play_sfx_by_key("heal")
	_show_result("휴식을 취해 HP %d 회복. (%d/%d)" % [actual_heal, rd.current_hp, rd.max_hp])


# --- 카드 강화 ---

func _on_show_upgrade_list() -> void:
	var cards := _get_upgradeable_cards()
	if cards.is_empty():
		return

	# 메인 액션 버튼 숨기고 카드 목록 표시
	action_container.visible = false
	card_list_container.visible = true
	back_button.visible = true
	description_label.text = "강화할 카드를 선택하세요."

	# 기존 카드 버튼 정리
	for child in card_list_container.get_children():
		child.queue_free()

	# 카드 목록 버튼 생성
	for entry in cards:
		var card: CardData = entry["card_data"]
		var btn := Button.new()
		btn.text = "%s — %s → %s" % [
			card.get_display_name(),
			card.effect,
			card.effect_upgraded if card.effect_upgraded != "" else "(강화 효과 없음)"
		]
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_upgrade_card.bind(entry))
		card_list_container.add_child(btn)


func _on_upgrade_card(entry: Dictionary) -> void:
	if GameManager.run_data == null:
		return

	var card_id: String = entry["card_id"]
	var card: CardData = entry["card_data"]

	# 강화 목록에 추가
	AudioManager.play_sfx_by_key("upgrade")
	GameManager.run_data.upgraded_cards.append(card_id)

	_show_result("『%s』 강화 완료!\n%s" % [
		card.get_display_name(),
		card.effect_upgraded if card.effect_upgraded != "" else card.effect
	])


func _on_back_to_actions() -> void:
	card_list_container.visible = false
	back_button.visible = false
	action_container.visible = true
	description_label.text = "모닥불 앞에서 잠시 쉬어간다."
	_update_action_states()


# --- 결과 표시 및 맵 복귀 ---

func _show_result(text: String) -> void:
	action_container.visible = false
	card_list_container.visible = false
	back_button.visible = false

	result_label.text = text
	result_label.visible = true
	continue_button.visible = true
	continue_button.grab_focus()
	_update_status_bar()


func _update_status_bar() -> void:
	if GameManager.run_data:
		hp_label.text = "HP: %d/%d" % [GameManager.run_data.current_hp, GameManager.run_data.max_hp]
		gold_label.text = "엽전: %d" % GameManager.run_data.gold
	else:
		hp_label.text = "HP: --/--"
		gold_label.text = "엽전: --"


func _return_to_map() -> void:
	GameManager.save_current_run()
	GameManager.change_state(GameManager.GameState.MAP)
