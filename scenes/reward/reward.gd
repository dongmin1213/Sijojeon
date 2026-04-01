extends Control

## 전투 보상 씬. 골드 획득 + 카드 3택 1 선택.

const CARD_OFFER_COUNT := 3

var reward_gold: int = 0
var card_offers: Array[String] = []  # 제시된 카드 ID 목록
var card_selected: bool = false
var relic_offer_id: String = ""  # 유물 보상 ID (빈 문자열이면 유물 없음)
var relic_claimed: bool = false

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

	if GameManager.run_data == null:
		push_warning("Reward: run_data가 null — 맵으로 복귀")
		proceed_button.visible = true
		skip_button.visible = false
		card_section.visible = false
		return

	_load_rewards()
	_apply_gold()
	_try_relic_reward()
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


func _try_relic_reward() -> void:
	## 전투 보상에서 유물 드롭을 시도한다.
	var rewards = GameManager.run_data.get_meta("battle_rewards", {}) if GameManager.run_data else {}
	var relic_chance: float = rewards.get("relic_chance", 0.0)
	if relic_chance <= 0.0:
		return

	# 확률 체크
	if randf() > relic_chance:
		return

	# 노드 타입에 따라 소스 결정
	var source := "elite"
	if GameManager.run_data and GameManager.run_data.current_node_type >= 0:
		if GameManager.run_data.current_node_type == MapData.NodeType.BOSS:
			source = "boss"

	relic_offer_id = RelicManager.roll_relic_reward(source)
	if relic_offer_id != "":
		_display_relic_offer()


func _display_relic_offer() -> void:
	## 유물 보상 UI를 카드 섹션 위에 추가한다.
	var relic_section := VBoxContainer.new()
	relic_section.name = "RelicSection"

	var relic_label := Label.new()
	relic_label.text = "유물 획득!"
	relic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_label.add_theme_font_size_override("font_size", 20)
	relic_label.add_theme_color_override("font_color", RelicManager.get_relic_rarity_color(relic_offer_id))
	relic_section.add_child(relic_label)

	var relic_btn := Button.new()
	relic_btn.custom_minimum_size = Vector2(300, 80)
	var relic_name := RelicManager.get_relic_display_name(relic_offer_id)
	var relic_desc := RelicManager.get_relic_description(relic_offer_id)
	relic_btn.text = "%s\n%s" % [relic_name, relic_desc]
	relic_btn.pressed.connect(_on_relic_claimed)
	relic_section.add_child(relic_btn)

	# 카드 섹션 앞에 삽입
	$VBoxContainer.add_child(relic_section)
	$VBoxContainer.move_child(relic_section, $VBoxContainer.get_children().find(card_section))


func _on_relic_claimed() -> void:
	if relic_claimed:
		return
	relic_claimed = true
	RelicManager.acquire_relic(relic_offer_id)

	# UI 비활성화
	var relic_section = $VBoxContainer.get_node_or_null("RelicSection")
	if relic_section:
		for child in relic_section.get_children():
			if child is Button:
				child.disabled = true
				child.add_theme_color_override("font_color", Color(1, 0.85, 0.3))


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
	var was_boss := false
	if GameManager.run_data:
		was_boss = (GameManager.run_data.current_node_type == MapData.NodeType.BOSS)
		if GameManager.run_data.has_meta("battle_rewards"):
			GameManager.run_data.remove_meta("battle_rewards")
		# 노드 메타 초기화
		GameManager.run_data.current_node_type = -1
		GameManager.run_data.current_encounter_id = ""

	GameManager.advance_floor()

	if was_boss:
		# 보스 처치: 막 전환 또는 런 승리
		if GameManager.run_data and GameManager.run_data.current_act >= GameManager.MAX_ACT:
			# 마지막 막 보스 처치 → 런 승리
			GameManager.end_run(true)
		else:
			# 다음 막으로 전환
			GameManager.advance_act()
			GameManager.save_current_run()
			GameManager.change_state(GameManager.GameState.ACT_TRANSITION)
	else:
		# 일반 전투 → 맵으로 복귀
		GameManager.save_current_run()
		GameManager.change_state(GameManager.GameState.MAP)
