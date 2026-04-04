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
const REMOVAL_BASE_COST := 75
const REMOVAL_COST_INCREASE := 25
const REMOVAL_MAX_COST := 200

# 카드 강화 비용
const UPGRADE_BASE_COST := 100
const UPGRADE_MAX_COST := 150

# 민심 매수 비용
const MINSHIM_BUY_COST := 100
const MINSHIM_BUY_AMOUNT := 10

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
@onready var relic_container: HBoxContainer = $VBoxContainer/RelicSection/RelicContainer
@onready var leave_button: Button = $VBoxContainer/LeaveButton


func _ready() -> void:
	refresh_button.pressed.connect(_on_refresh_pressed)
	remove_button.pressed.connect(_on_remove_toggle_pressed)
	upgrade_button.pressed.connect(_on_upgrade_toggle_pressed)
	minshim_button.pressed.connect(_on_minshim_buy_pressed)
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
			btn.text = "판매 완료"
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
	lines.append("💰 %d 금화" % price)
	lines.append("")
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
		remove_button.text = "취소"
		deck_scroll.visible = true
		leave_button.text = "제거 취소하고 나가기"
		_display_deck_for_removal()
	else:
		remove_button.text = "카드 제거 (%d 금화)" % _get_removal_cost()
		deck_scroll.visible = false
		leave_button.text = "상점 나가기"


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
		btn.text = "%s (비용:%d)" % [card.get_display_name(), card.cost]

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
	remove_button.text = "카드 제거 (%d 금화)" % _get_removal_cost()
	deck_scroll.visible = false
	leave_button.text = "상점 나가기"
	_update_remove_section()
	_update_gold_display()


func _update_gold_display() -> void:
	var gold: int = GameManager.run_data.gold if GameManager.run_data else 0
	gold_label.text = "보유 금화: %d" % gold

	# 새로고침 버튼 갱신
	refresh_button.text = "새로고침 (%d 금화)" % REFRESH_COST
	if gold < REFRESH_COST:
		refresh_button.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
	else:
		refresh_button.remove_theme_color_override("font_color")


func _update_remove_section() -> void:
	var cost := _get_removal_cost()
	remove_button.text = "카드 제거 (%d 금화)" % cost
	remove_info.text = "덱에서 카드 1장을 영구 제거합니다"

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
		upgrade_button.text = "취소"
		upgrade_scroll.visible = true
		leave_button.text = "강화 취소하고 나가기"
		_display_deck_for_upgrade()
	else:
		upgrade_button.text = "카드 강화 (%d 금화)" % _get_upgrade_cost()
		upgrade_scroll.visible = false
		leave_button.text = "상점 나가기"


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
		btn.text = "%s (비용:%d)" % [card.get_display_name(), card.cost]

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
	upgrade_button.text = "카드 강화 (%d 금화)" % _get_upgrade_cost()
	upgrade_scroll.visible = false
	leave_button.text = "상점 나가기"
	_update_upgrade_section()
	_update_gold_display()


func _update_upgrade_section() -> void:
	var cost := _get_upgrade_cost()
	upgrade_button.text = "카드 강화 (%d 금화)" % cost
	upgrade_info.text = "덱의 카드 1장을 강화합니다"

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


func _update_minshim_button() -> void:
	var minshim: int = 50
	if GameManager.run_data:
		minshim = GameManager.run_data.narrative_state.get("minshim", 50)
	minshim_button.text = "민심 매수 (%d 금화 → 민심 +%d) [현재: %d]" % [MINSHIM_BUY_COST, MINSHIM_BUY_AMOUNT, minshim]

	if minshim >= 100:
		minshim_button.disabled = true
		minshim_button.text = "민심 최대 (100)"
	elif GameManager.run_data and GameManager.run_data.gold < MINSHIM_BUY_COST:
		minshim_button.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
	else:
		minshim_button.remove_theme_color_override("font_color")


## 상점 유물 생성 (등급 가중치 기반 2개)
func _generate_shop_relics() -> void:
	shop_relics.clear()
	if GameManager.run_data == null:
		return

	var character_id: String = GameManager.run_data.character_id
	for _i in 2:
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
			btn.text = "판매 완료"
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4)
		else:
			var relic_name: String = ""
			var name_data = relic_data.get("name", {})
			if name_data is Dictionary:
				relic_name = str(name_data.get("ko", entry["relic_id"]))
			else:
				relic_name = str(name_data)
			var effect_desc: String = str(relic_data.get("effect_description", ""))
			btn.text = "%s\n%s\n\n%d 금화" % [relic_name, effect_desc, entry["price"]]
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
