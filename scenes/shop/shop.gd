extends Control

## 상점 씬. 카드 구매(3슬롯) + 카드 제거 + 새로고침 기능.
## economy.json 가격 기준표 참조.

const CARD_SLOTS := 3
const REFRESH_COST := 50

# 카드 등급별 기본가 (rarity → base_price)
const CARD_BASE_PRICES := {
	1: 75, 2: 75,       # common (rarity 1~2)
	3: 110,              # uncommon (rarity 3)
	4: 150, 5: 150,      # rare (rarity 4~5)
}
# 가격 변동 범위 (rarity → [min_offset, max_offset])
const CARD_PRICE_VARIANCE := {
	1: [-25, 25], 2: [-25, 25],
	3: [-25, 25],
	4: [-30, 25], 5: [-30, 25],
}

# 카드 제거 비용
const REMOVAL_BASE_COST := 50
const REMOVAL_COST_INCREASE := 25
const REMOVAL_MAX_COST := 200

# 카드 강화 비용
const UPGRADE_BASE_COST := 50
const UPGRADE_MAX_COST := 150

# 민심 매수 비용
const MINSHIM_BUY_COST := 100
const MINSHIM_BUY_AMOUNT := 10

# 시장 개방 비용 (저가 민심 획득)
const MARKET_OPEN_COST := 25
const MARKET_OPEN_MINSHIM := 8

# 청탁 비용 (신분 점수 상승)
const BRIBE_COST := 60
const BRIBE_JIBUN_AMOUNT := 20

# 군량미 비축 비용 (다음 전투 방어도 +8)
const RATIONS_COST := 30
const RATIONS_BLOCK := 8

# 등급별 출현 가중치
const RARITY_WEIGHTS := {
	"common": 50,     # rarity 1~2
	"uncommon": 35,   # rarity 3
	"rare": 15,       # rarity 4~5
}

var shop_cards: Array[Dictionary] = []  # [{card_id, price, sold}]
var shop_relics: Array[Dictionary] = []  # [{relic_id, price, sold}]
var removal_mode: bool = false
var upgrade_mode: bool = false
var deck_buttons: Array[Button] = []
var _price_modifier: float = 1.0  # 이벤트 효과에 의한 가격 배율

# 유물 등급별 상점 가격
const RELIC_PRICES := {
	1: 150,   # 일반
	2: 200,   # 고급
	3: 275,   # 희귀
}

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var gold_label: Label = $VBoxContainer/GoldLabel
@onready var card_container: HBoxContainer = $VBoxContainer/CardSection/CardContainer
@onready var card_section_label: Label = $VBoxContainer/CardSection/CardSectionLabel
@onready var refresh_button: Button = $VBoxContainer/CardSection/RefreshButton
@onready var remove_section: VBoxContainer = $VBoxContainer/RemoveSection
@onready var remove_button: Button = $VBoxContainer/RemoveSection/RemoveButton
@onready var remove_info: Label = $VBoxContainer/RemoveSection/RemoveInfo
@onready var deck_container: GridContainer = $VBoxContainer/RemoveSection/DeckScrollContainer/DeckContainer
@onready var deck_scroll: ScrollContainer = $VBoxContainer/RemoveSection/DeckScrollContainer
@onready var extra_section: VBoxContainer = $VBoxContainer/ExtraSection
@onready var upgrade_button: Button = $VBoxContainer/ExtraSection/UpgradeButton
@onready var upgrade_info: Label = $VBoxContainer/ExtraSection/UpgradeInfo
@onready var upgrade_scroll: ScrollContainer = $VBoxContainer/ExtraSection/UpgradeScrollContainer
@onready var upgrade_deck_container: GridContainer = $VBoxContainer/ExtraSection/UpgradeScrollContainer/UpgradeDeckContainer
@onready var minshim_button: Button = $VBoxContainer/ExtraSection/MinshimButton
@onready var market_open_button: Button = $VBoxContainer/ExtraSection/MarketOpenButton
@onready var bribe_button: Button = $VBoxContainer/ExtraSection/BribeButton
@onready var rations_button: Button = $VBoxContainer/ExtraSection/RationsButton
@onready var relic_container: HBoxContainer = $VBoxContainer/RelicSection/RelicContainer
@onready var leave_button: Button = $VBoxContainer/LeaveButton


func _ready() -> void:
	refresh_button.pressed.connect(_on_refresh_pressed)
	remove_button.pressed.connect(_on_remove_toggle_pressed)
	upgrade_button.pressed.connect(_on_upgrade_toggle_pressed)
	minshim_button.pressed.connect(_on_minshim_buy_pressed)
	market_open_button.pressed.connect(_on_market_open_pressed)
	bribe_button.pressed.connect(_on_bribe_pressed)
	rations_button.pressed.connect(_on_rations_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

	deck_scroll.visible = false
	upgrade_scroll.visible = false

	if GameManager.run_data == null:
		push_warning("Shop: run_data가 null — 맵으로 복귀")
		leave_button.visible = true
		return

	# 상점 입장 유물 트리거 (상단 장부)
	RelicManager.trigger_enter_shop()

	# 대기 효과 소비 (상점 가격 변동, 투자 회수 등)
	_price_modifier = _consume_shop_price_effects()
	# 민심 기반 가격 수정 (민심 낮으면 가격 상승)
	_price_modifier *= _get_minshim_price_modifier()

	_generate_shop_cards()
	_generate_shop_relics()
	_display_shop_cards()
	_display_shop_relics()
	_update_gold_display()
	_update_remove_section()
	_update_upgrade_section()
	_update_minshim_button()
	_update_market_open_button()
	_update_discount_badges()


func _generate_shop_cards() -> void:
	shop_cards.clear()
	if GameManager.run_data == null:
		return

	var character_id: String = GameManager.run_data.character_id
	var pool_cards: Array[CardData] = []
	pool_cards.append_array(DataLoader.get_cards_by_pool(character_id))
	pool_cards.append_array(DataLoader.get_cards_by_pool("common"))

	if pool_cards.is_empty():
		return

	# 가중치 기반 랜덤 카드 선택
	var selected: Array[CardData] = _weighted_card_select(pool_cards, CARD_SLOTS)
	for card in selected:
		var price := _calculate_card_price(card)
		shop_cards.append({"card_id": card.id, "price": price, "sold": false})


func _weighted_card_select(pool: Array[CardData], count: int) -> Array[CardData]:
	var result: Array[CardData] = []
	var available := pool.duplicate()
	available.shuffle()

	for _i in count:
		if available.is_empty():
			break
		# 가중치 적용하여 등급 결정
		var roll := randf() * 100.0
		var target_rarity_range: Array[int]
		if roll < RARITY_WEIGHTS["rare"]:
			target_rarity_range = [4, 5]
		elif roll < RARITY_WEIGHTS["rare"] + RARITY_WEIGHTS["uncommon"]:
			target_rarity_range = [3, 3]
		else:
			target_rarity_range = [1, 2]

		# 해당 등급의 카드 찾기
		var candidates: Array[CardData] = []
		for card in available:
			if card.rarity >= target_rarity_range[0] and card.rarity <= target_rarity_range[1]:
				candidates.append(card)

		if candidates.is_empty():
			# 등급 매칭 실패 시 아무거나
			candidates = available.duplicate()

		candidates.shuffle()
		var chosen: CardData = candidates[0]
		result.append(chosen)
		available.erase(chosen)

	return result


func _calculate_card_price(card: CardData) -> int:
	var base: int = CARD_BASE_PRICES.get(card.rarity, 75)
	var variance: Array = CARD_PRICE_VARIANCE.get(card.rarity, [-25, 25])
	var offset := randi_range(variance[0], variance[1])
	var raw_price := maxi(base + offset, 10)
	# 이벤트 효과에 의한 가격 변동 적용
	return maxi(int(raw_price * _price_modifier), 1)


func _get_removal_cost() -> int:
	if GameManager.run_data == null:
		return REMOVAL_BASE_COST
	var count: int = GameManager.run_data.card_removals_count
	var ascension_extra: int = GameManager.get_ascension_card_removal_extra_cost()
	return mini(REMOVAL_BASE_COST + count * REMOVAL_COST_INCREASE + ascension_extra, REMOVAL_MAX_COST)


func _display_shop_cards() -> void:
	for child in card_container.get_children():
		child.queue_free()

	for i in shop_cards.size():
		var entry: Dictionary = shop_cards[i]
		var card: CardData = DataLoader.get_card(entry["card_id"])
		if card == null:
			continue

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 280)

		if entry["sold"]:
			btn.text = tr("SHOP_SALE_COMPLETE")
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4)
		else:
			btn.text = _format_card_text(card, entry["price"])
			var can_afford: bool = GameManager.run_data != null and GameManager.run_data.gold >= entry["price"]
			if not can_afford:
				btn.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
			btn.pressed.connect(_on_buy_card.bind(i))

		card_container.add_child(btn)


func _format_card_text(card: CardData, price: int) -> String:
	var lines: Array[String] = []
	lines.append(card.get_display_name())
	lines.append("")
	# 할인 명세 표시: 할인 적용 시 원가 + 최종가 + 사유
	var base: int = CARD_BASE_PRICES.get(card.rarity, 75)
	var discount_info := _get_discount_breakdown()
	if discount_info["has_discount"] and base != price:
		lines.append("%s  ->  %d" % [tr("SHOP_ORIGINAL_PRICE_FMT") % base, price])
		lines.append(tr("SHOP_DISCOUNT_REASON_FMT") % discount_info["reasons"])
	else:
		lines.append(tr("SHOP_CARD_PRICE") % price)
	lines.append("")
	lines.append(tr("SHOP_CARD_COST") % card.cost)
	lines.append(tr("SHOP_CARD_BEAT") % card.beat)

	if card.damage > 0:
		var dmg_text := tr("SHOP_CARD_DAMAGE") % card.damage
		if card.is_aoe:
			dmg_text += " " + tr("SHOP_CARD_DAMAGE_AOE")
		lines.append(dmg_text)
	if card.block_value > 0:
		lines.append(tr("SHOP_CARD_BLOCK") % card.block_value)
	if card.draw_count > 0:
		lines.append(tr("SHOP_CARD_DRAW") % card.draw_count)
	if card.qi_gain > 0:
		lines.append(tr("SHOP_CARD_QI_GAIN") % card.qi_gain)

	var eff := card.get_current_effect()
	if eff != "":
		lines.append("")
		lines.append(eff)

	return "\n".join(lines)


func _on_buy_card(index: int) -> void:
	if removal_mode:
		return
	if index < 0 or index >= shop_cards.size():
		return
	var entry: Dictionary = shop_cards[index]
	if entry["sold"]:
		return
	if GameManager.run_data == null:
		return
	if GameManager.run_data.gold < entry["price"]:
		return

	# 구매 실행
	AudioManager.play_sfx_by_key("coin")
	GameManager.run_data.gold -= entry["price"]
	GameManager.run_data.deck.append(entry["card_id"])
	shop_cards[index]["sold"] = true

	_display_shop_cards()
	_update_gold_display()


func _on_refresh_pressed() -> void:
	if removal_mode:
		return
	if GameManager.run_data == null:
		return
	if GameManager.run_data.gold < REFRESH_COST:
		return

	AudioManager.play_sfx_by_key("coin")
	GameManager.run_data.gold -= REFRESH_COST
	_generate_shop_cards()
	_display_shop_cards()
	_update_gold_display()


func _on_remove_toggle_pressed() -> void:
	removal_mode = not removal_mode

	if removal_mode:
		remove_button.text = tr("UI_CANCEL")
		deck_scroll.visible = true
		leave_button.text = tr("SHOP_CANCEL_REMOVE_LEAVE")
		_display_deck_for_removal()
	else:
		remove_button.text = tr("SHOP_REMOVE_COST_FMT") % _get_removal_cost()
		deck_scroll.visible = false
		leave_button.text = tr("SHOP_LEAVE")


func _display_deck_for_removal() -> void:
	for child in deck_container.get_children():
		child.queue_free()
	deck_buttons.clear()

	if GameManager.run_data == null:
		return

	var removal_cost := _get_removal_cost()
	var can_afford: bool = GameManager.run_data.gold >= removal_cost

	for i in GameManager.run_data.deck.size():
		var card_id: String = GameManager.run_data.deck[i]
		var card: CardData = DataLoader.get_card(card_id)
		if card == null:
			continue

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(160, 60)
		btn.text = tr("SHOP_DECK_CARD_INFO") % [card.get_display_name(), card.cost]

		if not can_afford:
			btn.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
		else:
			btn.pressed.connect(_on_remove_card.bind(i))

		deck_container.add_child(btn)
		deck_buttons.append(btn)


func _on_remove_card(deck_index: int) -> void:
	if not removal_mode:
		return
	if GameManager.run_data == null:
		return

	var removal_cost := _get_removal_cost()
	if GameManager.run_data.gold < removal_cost:
		return
	if deck_index < 0 or deck_index >= GameManager.run_data.deck.size():
		return

	# 마지막 카드 제거 방지
	if GameManager.run_data.deck.size() <= 1:
		return

	# 제거 실행
	AudioManager.play_sfx_by_key("coin")
	GameManager.run_data.gold -= removal_cost
	GameManager.run_data.deck.remove_at(deck_index)
	GameManager.run_data.card_removals_count += 1

	# 제거 모드 종료 후 UI 갱신
	removal_mode = false
	remove_button.text = tr("SHOP_REMOVE_COST_FMT") % _get_removal_cost()
	deck_scroll.visible = false
	leave_button.text = tr("SHOP_LEAVE")
	_update_remove_section()
	_update_gold_display()


func _update_gold_display() -> void:
	var gold: int = GameManager.run_data.gold if GameManager.run_data else 0
	gold_label.text = tr("SHOP_GOLD_DISPLAY") % gold

	# 새로고침 버튼 갱신
	refresh_button.text = tr("SHOP_REFRESH_FMT") % REFRESH_COST
	if gold < REFRESH_COST:
		refresh_button.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
	else:
		refresh_button.remove_theme_color_override("font_color")

	# 추가 구매 버튼 색상 갱신
	_update_bribe_button()
	_update_rations_button()


func _update_remove_section() -> void:
	var cost := _get_removal_cost()
	remove_button.text = tr("SHOP_REMOVE_COST_FMT") % cost
	remove_info.text = tr("SHOP_REMOVE_CARD_INFO")

	if GameManager.run_data and GameManager.run_data.gold < cost:
		remove_button.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
	else:
		remove_button.remove_theme_color_override("font_color")


## 카드 강화 비용 계산 (중인 신분 시 -25% 할인)
func _get_upgrade_cost() -> int:
	var base_cost := UPGRADE_BASE_COST
	var discount: float = JibunSystem.get_upgrade_cost_discount(GameManager.run_data)
	return maxi(int(base_cost * discount), 1)


func _on_upgrade_toggle_pressed() -> void:
	if removal_mode:
		return
	upgrade_mode = not upgrade_mode

	if upgrade_mode:
		upgrade_button.text = tr("UI_CANCEL")
		upgrade_scroll.visible = true
		leave_button.text = tr("SHOP_CANCEL_UPGRADE_LEAVE")
		_display_deck_for_upgrade()
	else:
		upgrade_button.text = tr("SHOP_UPGRADE_COST_FMT") % _get_upgrade_cost()
		upgrade_scroll.visible = false
		leave_button.text = tr("SHOP_LEAVE")


func _display_deck_for_upgrade() -> void:
	for child in upgrade_deck_container.get_children():
		child.queue_free()

	if GameManager.run_data == null:
		return

	var cost := _get_upgrade_cost()
	var can_afford: bool = GameManager.run_data.gold >= cost

	for i in GameManager.run_data.deck.size():
		var card_id: String = GameManager.run_data.deck[i]
		# 이미 강화된 카드는 건너뜀
		if card_id.ends_with("+"):
			continue
		var card: CardData = DataLoader.get_card(card_id)
		if card == null:
			continue

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(160, 60)
		btn.text = tr("SHOP_DECK_CARD_INFO") % [card.get_display_name(), card.cost]

		if not can_afford:
			btn.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
		else:
			btn.pressed.connect(_on_upgrade_card.bind(i))

		upgrade_deck_container.add_child(btn)


func _on_upgrade_card(deck_index: int) -> void:
	if not upgrade_mode:
		return
	if GameManager.run_data == null:
		return

	var cost := _get_upgrade_cost()
	if GameManager.run_data.gold < cost:
		return
	if deck_index < 0 or deck_index >= GameManager.run_data.deck.size():
		return

	var card_id: String = GameManager.run_data.deck[deck_index]
	if card_id.ends_with("+"):
		return

	# 강화 실행
	AudioManager.play_sfx_by_key("coin")
	GameManager.run_data.gold -= cost
	GameManager.run_data.deck[deck_index] = card_id + "+"
	if not GameManager.run_data.upgraded_cards.has(card_id):
		GameManager.run_data.upgraded_cards.append(card_id)

	# 강화 모드 종료
	upgrade_mode = false
	upgrade_button.text = tr("SHOP_UPGRADE_COST_FMT") % _get_upgrade_cost()
	upgrade_scroll.visible = false
	leave_button.text = tr("SHOP_LEAVE")
	_update_upgrade_section()
	_update_gold_display()


func _update_upgrade_section() -> void:
	var cost := _get_upgrade_cost()
	upgrade_button.text = tr("SHOP_UPGRADE_COST_FMT") % cost
	upgrade_info.text = tr("SHOP_UPGRADE_CARD_INFO")

	if GameManager.run_data and GameManager.run_data.gold < cost:
		upgrade_button.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
	else:
		upgrade_button.remove_theme_color_override("font_color")


func _on_minshim_buy_pressed() -> void:
	if removal_mode or upgrade_mode:
		return
	if GameManager.run_data == null:
		return
	if GameManager.run_data.gold < MINSHIM_BUY_COST:
		return

	AudioManager.play_sfx_by_key("coin")
	GameManager.run_data.gold -= MINSHIM_BUY_COST
	var current: int = GameManager.run_data.narrative_state.get("minshim", 50)
	GameManager.run_data.narrative_state["minshim"] = clampi(current + MINSHIM_BUY_AMOUNT, 0, 100)

	_update_gold_display()
	_update_minshim_button()
	_update_market_open_button()


func _update_minshim_button() -> void:
	var minshim: int = 50
	if GameManager.run_data:
		minshim = GameManager.run_data.narrative_state.get("minshim", 50)
	minshim_button.text = tr("SHOP_MINSHIM_BUY_FMT") % [MINSHIM_BUY_COST, MINSHIM_BUY_AMOUNT, minshim]

	if minshim >= 100:
		minshim_button.disabled = true
		minshim_button.text = tr("SHOP_MINSHIM_MAX")
	elif GameManager.run_data and GameManager.run_data.gold < MINSHIM_BUY_COST:
		minshim_button.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
	else:
		minshim_button.remove_theme_color_override("font_color")


func _on_market_open_pressed() -> void:
	if removal_mode or upgrade_mode:
		return
	if GameManager.run_data == null:
		return
	if GameManager.run_data.gold < MARKET_OPEN_COST:
		return

	AudioManager.play_sfx_by_key("coin")
	GameManager.run_data.gold -= MARKET_OPEN_COST
	var current: int = GameManager.run_data.narrative_state.get("minshim", 50)
	GameManager.run_data.narrative_state["minshim"] = clampi(current + MARKET_OPEN_MINSHIM, 0, 100)

	_update_gold_display()
	_update_market_open_button()
	_update_minshim_button()


func _update_market_open_button() -> void:
	var minshim: int = 50
	if GameManager.run_data:
		minshim = GameManager.run_data.narrative_state.get("minshim", 50)
	market_open_button.text = tr("SHOP_MARKET_OPEN_FMT") % [MARKET_OPEN_COST, MARKET_OPEN_MINSHIM, minshim]

	if minshim >= 100:
		market_open_button.disabled = true
		market_open_button.text = tr("SHOP_MINSHIM_MAX")
	elif GameManager.run_data and GameManager.run_data.gold < MARKET_OPEN_COST:
		market_open_button.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
	else:
		market_open_button.remove_theme_color_override("font_color")


## 청탁 구매 (신분 점수 +20)
func _on_bribe_pressed() -> void:
	if removal_mode or upgrade_mode:
		return
	if GameManager.run_data == null:
		return
	if GameManager.run_data.gold < BRIBE_COST:
		return

	AudioManager.play_sfx_by_key("coin")
	GameManager.run_data.gold -= BRIBE_COST
	var rank_change = JibunSystem.add_score(GameManager.run_data, BRIBE_JIBUN_AMOUNT)

	_update_gold_display()

	# 승급 시 연출 표시
	if rank_change != null:
		_show_rankup_popup(rank_change[1])


func _update_bribe_button() -> void:
	var jibun_score: int = 0
	if GameManager.run_data:
		jibun_score = GameManager.run_data.jibun_score
	var rank: int = GameManager.run_data.jibun_rank if GameManager.run_data else 1
	var rank_name: String = JibunSystem.get_rank_name(rank)
	bribe_button.text = tr("SHOP_BRIBE_FMT") % [BRIBE_COST, BRIBE_JIBUN_AMOUNT, rank_name, jibun_score]

	if GameManager.run_data and GameManager.run_data.gold < BRIBE_COST:
		bribe_button.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
	else:
		bribe_button.remove_theme_color_override("font_color")


## 군량미 비축 구매 (다음 전투 방어도 +8)
func _on_rations_pressed() -> void:
	if removal_mode or upgrade_mode:
		return
	if GameManager.run_data == null:
		return
	if GameManager.run_data.gold < RATIONS_COST:
		return

	AudioManager.play_sfx_by_key("coin")
	GameManager.run_data.gold -= RATIONS_COST

	# pending_effects에 다음 전투 방어도 효과 추가
	if not GameManager.run_data.narrative_state.has("pending_effects"):
		GameManager.run_data.narrative_state["pending_effects"] = []
	GameManager.run_data.narrative_state["pending_effects"].append({
		"type": "next_battle_block",
		"block": RATIONS_BLOCK,
	})

	_update_gold_display()


func _update_rations_button() -> void:
	rations_button.text = tr("SHOP_RATIONS_FMT") % [RATIONS_COST, RATIONS_BLOCK]

	if GameManager.run_data and GameManager.run_data.gold < RATIONS_COST:
		rations_button.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
	else:
		rations_button.remove_theme_color_override("font_color")


## 상점 유물 생성 (등급 가중치 기반 3개)
func _generate_shop_relics() -> void:
	shop_relics.clear()
	if GameManager.run_data == null:
		return

	var character_id: String = GameManager.run_data.character_id
	for _i in 3:
		var relic_id := RelicManager.roll_relic_reward("shop")
		if relic_id == "":
			continue
		# 중복 방지
		var already := false
		for entry in shop_relics:
			if entry["relic_id"] == relic_id:
				already = true
				break
		if already:
			continue
		var relic_data := DataLoader.get_relic(relic_id)
		if relic_data.is_empty():
			continue
		var rarity: int = relic_data.get("rarity", 1)
		var base_price: int = RELIC_PRICES.get(rarity, 150)
		# 가격 변동 적용 (민심/이벤트 할인)
		var price := maxi(int(base_price * _price_modifier), 10)
		shop_relics.append({"relic_id": relic_id, "price": price, "sold": false})


## 상점 유물 UI 표시
func _display_shop_relics() -> void:
	for child in relic_container.get_children():
		child.queue_free()

	for i in shop_relics.size():
		var entry: Dictionary = shop_relics[i]
		var relic_data := DataLoader.get_relic(entry["relic_id"])
		if relic_data.is_empty():
			continue

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(220, 160)

		if entry["sold"]:
			btn.text = tr("SHOP_SALE_COMPLETE")
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4)
		else:
			var relic_name: String = TranslationManager.trd_name(relic_data)
			var effect_desc: String = TranslationManager.trd(relic_data, "effect_description", "")
			var rarity: int = relic_data.get("rarity", 1)
			var base_relic_price: int = RELIC_PRICES.get(rarity, 150)
			var discount_info := _get_discount_breakdown()
			if discount_info["has_discount"] and base_relic_price != entry["price"]:
				var price_line := "%s  ->  %d\n%s" % [tr("SHOP_ORIGINAL_PRICE_FMT") % base_relic_price, entry["price"], tr("SHOP_DISCOUNT_REASON_FMT") % discount_info["reasons"]]
				btn.text = "%s\n%s\n%s" % [relic_name, effect_desc, price_line]
			else:
				btn.text = tr("SHOP_RELIC_PRICE_FMT") % [relic_name, effect_desc, entry["price"]]
			var can_afford: bool = GameManager.run_data != null and GameManager.run_data.gold >= entry["price"]
			if not can_afford:
				btn.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
			btn.pressed.connect(_on_buy_relic.bind(i))

		relic_container.add_child(btn)


## 유물 구매 처리
func _on_buy_relic(index: int) -> void:
	if removal_mode or upgrade_mode:
		return
	if index < 0 or index >= shop_relics.size():
		return
	var entry: Dictionary = shop_relics[index]
	if entry["sold"]:
		return
	if GameManager.run_data == null:
		return
	if GameManager.run_data.gold < entry["price"]:
		return

	# 이미 보유한 유물인지 확인
	if RelicManager.has_relic(entry["relic_id"]):
		return

	# 구매 실행
	AudioManager.play_sfx_by_key("coin")
	GameManager.run_data.gold -= entry["price"]
	RelicManager.acquire_relic(entry["relic_id"])
	shop_relics[index]["sold"] = true

	_display_shop_relics()
	_update_gold_display()


func _on_leave_pressed() -> void:
	# 제거/강화 모드 중이어도 나갈 수 있도록 리셋
	removal_mode = false
	upgrade_mode = false
	GameManager.save_current_run()
	GameManager.change_state(GameManager.GameState.MAP)


## pending_effects에서 상점 관련 효과를 소비하고 가격 배율을 반환한다.
func _consume_shop_price_effects() -> float:
	var modifier: float = 1.0
	if not GameManager.run_data:
		return modifier
	var effects: Array = GameManager.run_data.narrative_state.get("pending_effects", [])
	var remaining: Array = []
	for eff in effects:
		if eff.get("type") == "shop_price_modifier":
			var pct: int = eff.get("percent", 0)
			modifier *= (1.0 + pct / 100.0)
			var dur: int = eff.get("duration_shops", 1) - 1
			if dur > 0:
				eff["duration_shops"] = dur
				remaining.append(eff)
		elif eff.get("type") == "gold_gain_after_shops":
			var shops_left: int = eff.get("shops_remaining", 1) - 1
			if shops_left <= 0:
				# 투자 회수 — 골드 지급
				GameManager.run_data.gold += eff.get("gold", 0)
			else:
				eff["shops_remaining"] = shops_left
				remaining.append(eff)
		else:
			remaining.append(eff)
	GameManager.run_data.narrative_state["pending_effects"] = remaining
	return modifier


## 민심 수치에 따른 상점 가격 수정자를 반환한다.
func _get_minshim_price_modifier() -> float:
	if not GameManager.run_data:
		return 1.0
	var minshim: int = GameManager.run_data.narrative_state.get("minshim", 50)
	var modifier: float = 1.0
	if minshim <= 29:
		modifier = 1.3   # +30% (민란 직전, 상인들 기피)
	elif minshim <= 49:
		modifier = 1.15  # +15%
	elif minshim >= 70:
		modifier = 0.8   # -20% (높은 민심 할인)
	# 양반 이상 신분 할인 적용 (-15%)
	modifier *= JibunSystem.get_shop_price_modifier(GameManager.run_data)
	return modifier


## 현재 활성 할인/할증 사유를 분석하여 반환한다.
func _get_discount_breakdown() -> Dictionary:
	var reasons: Array[String] = []
	var has_discount := false

	if not GameManager.run_data:
		return {"has_discount": false, "reasons": ""}

	# 신분 할인
	var jibun_mod := JibunSystem.get_shop_price_modifier(GameManager.run_data)
	if jibun_mod < 1.0:
		var rank_name := JibunSystem.get_rank_name(GameManager.run_data.jibun_rank)
		reasons.append("%s %s" % [rank_name, tr("SHOP_DISCOUNT_JIBUN")])
		has_discount = true

	# 민심 할인/할증
	var minshim: int = GameManager.run_data.narrative_state.get("minshim", 50)
	if minshim >= 70:
		reasons.append("%s %s" % [tr("MINSHIM_TOOLTIP_TITLE"), tr("SHOP_DISCOUNT_MINSHIM_HIGH")])
		has_discount = true
	elif minshim <= 29:
		reasons.append("%s %s" % [tr("MINSHIM_TOOLTIP_TITLE"), tr("SHOP_DISCOUNT_MINSHIM_CRISIS")])
		has_discount = true
	elif minshim <= 49:
		reasons.append("%s %s" % [tr("MINSHIM_TOOLTIP_TITLE"), tr("SHOP_DISCOUNT_MINSHIM_LOW")])
		has_discount = true

	# 당파 할인
	var faction_mod := FactionSystem.get_shop_discount(GameManager.run_data)
	if faction_mod < 1.0:
		reasons.append("%s %s" % [tr("MAP_FACTION_NONE").split(":")[0], tr("SHOP_DISCOUNT_FACTION")])
		has_discount = true

	return {"has_discount": has_discount, "reasons": ", ".join(reasons)}


## 상점 상단에 할인 배지를 표시한다.
func _update_discount_badges() -> void:
	# 기존 배지 제거
	var existing := title_label.get_parent().get_node_or_null("DiscountBadge")
	if existing:
		existing.queue_free()

	var info := _get_discount_breakdown()
	if not info["has_discount"]:
		return

	var badge := Label.new()
	badge.name = "DiscountBadge"
	badge.text = info["reasons"]
	badge.add_theme_font_size_override("font_size", 22)
	badge.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.get_parent().add_child(badge)
	title_label.get_parent().move_child(badge, 1)  # 타이틀 바로 아래


## 승급 팝업 연출: 골드 플래시 + 텍스트 (2초).
func _show_rankup_popup(new_rank: int) -> void:
	var rank_name := JibunSystem.get_rank_name(new_rank)

	# 골드 플래시 오버레이
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.85, 0.3, 0.4)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	# 승급 텍스트
	var popup_label := Label.new()
	popup_label.text = tr("JIBUN_RANKUP_POPUP_FMT") % rank_name
	popup_label.add_theme_font_size_override("font_size", 40)
	popup_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_label.anchors_preset = Control.PRESET_CENTER
	popup_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	popup_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	popup_label.custom_minimum_size = Vector2(400, 60)
	popup_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(popup_label)

	# 2초 후 페이드아웃
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.parallel().tween_property(popup_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)
	tween.tween_callback(popup_label.queue_free)
