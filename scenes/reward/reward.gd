extends Control

## 전투 보상 씬. 골드 획득 + 카드 3택 1 선택.

const CARD_OFFER_COUNT := 3

var reward_gold: int = 0
var card_offers: Array[String] = []  # 제시된 카드 ID 목록
var card_selected: bool = false

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var gold_label: Label = $VBoxContainer/GoldLabel
@onready var card_section: VBoxContainer = $VBoxContainer/CardSection
@onready var card_container: HBoxContainer = $VBoxContainer/CardSection/CardContainer
@onready var skip_button: Button = $VBoxContainer/SkipButton
@onready var proceed_button: Button = $VBoxContainer/ProceedButton


func _ready() -> void:
	skip_button.pressed.connect(_on_skip_pressed)
	proceed_button.pressed.connect(_on_proceed_pressed)
	proceed_button.visible = false

	_load_rewards()
	_apply_gold()
	_generate_card_offers()
	_display_card_offers()


func _load_rewards() -> void:
	if GameManager.run_data == null:
		return
	var rewards = GameManager.run_data.get_meta("battle_rewards", {})
	if rewards is Dictionary:
		reward_gold = rewards.get("gold", 0)
		# card_chance는 항상 카드 선택 제공 (Slay the Spire 스타일)
		# relic_chance는 향후 확장


func _apply_gold() -> void:
	if GameManager.run_data:
		GameManager.run_data.gold += reward_gold
	gold_label.text = "금화 +%d (보유: %d)" % [reward_gold, GameManager.run_data.gold if GameManager.run_data else 0]


func _generate_card_offers() -> void:
	card_offers.clear()
	if GameManager.run_data == null:
		return

	var character_id: String = GameManager.run_data.character_id
	var pool_cards: Array[CardData] = []

	# 캐릭터 클래스 카드 + 공용 카드 풀에서 선택
	var class_cards := DataLoader.get_cards_by_pool(character_id)
	var common_cards := DataLoader.get_cards_by_pool("common")
	pool_cards.append_array(class_cards)
	pool_cards.append_array(common_cards)

	# 스타터 덱에 이미 있는 카드 제외하지 않음 (중복 허용 — StS 스타일)
	# 셔플 후 상위 3장 선택
	var shuffled: Array[CardData] = pool_cards.duplicate()
	shuffled.shuffle()

	for i in mini(CARD_OFFER_COUNT, shuffled.size()):
		card_offers.append(shuffled[i].id)


func _display_card_offers() -> void:
	for child in card_container.get_children():
		child.queue_free()

	if card_offers.is_empty():
		card_section.visible = false
		skip_button.visible = false
		proceed_button.visible = true
		return

	for i in card_offers.size():
		var card_id: String = card_offers[i]
		var card: CardData = DataLoader.get_card(card_id)
		if card == null:
			continue

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 280)
		btn.text = _format_card_text(card)
		btn.pressed.connect(_on_card_chosen.bind(i))
		card_container.add_child(btn)


func _format_card_text(card: CardData) -> String:
	var lines: Array[String] = []
	lines.append(card.get_display_name())
	lines.append("비용: %d 기" % card.cost)
	lines.append("음보: %d" % card.beat)

	if card.damage > 0:
		var dmg_text := "피해: %d" % card.damage
		if card.is_aoe:
			dmg_text += " (전체)"
		lines.append(dmg_text)
	if card.block_value > 0:
		lines.append("방어: %d" % card.block_value)
	if card.draw_count > 0:
		lines.append("드로우: +%d" % card.draw_count)
	if card.qi_gain > 0:
		lines.append("기 회복: +%d" % card.qi_gain)

	if card.effect != "":
		lines.append("")
		lines.append(card.effect)

	return "\n".join(lines)


func _on_card_chosen(index: int) -> void:
	if card_selected:
		return
	card_selected = true

	if index >= 0 and index < card_offers.size():
		var card_id: String = card_offers[index]
		if GameManager.run_data:
			GameManager.run_data.deck.append(card_id)

		# 선택한 카드 하이라이트
		var buttons := card_container.get_children()
		for i in buttons.size():
			if i == index:
				buttons[i].add_theme_color_override("font_color", Color(1, 0.85, 0.3))
				buttons[i].disabled = true
			else:
				buttons[i].modulate = Color(0.4, 0.4, 0.4)
				buttons[i].disabled = true

	skip_button.visible = false
	proceed_button.visible = true


func _on_skip_pressed() -> void:
	if card_selected:
		return
	card_selected = true
	skip_button.visible = false
	proceed_button.visible = true


func _on_proceed_pressed() -> void:
	# 메타 데이터 정리
	if GameManager.run_data and GameManager.run_data.has_meta("battle_rewards"):
		GameManager.run_data.remove_meta("battle_rewards")

	# 층 진행 후 맵으로 복귀
	GameManager.advance_floor()
	GameManager.save_current_run()
	GameManager.change_state(GameManager.GameState.MAP)
