extends Control

## 전투 보상 씬. 골드 획득 + 카드 3택 1 선택.

const CARD_OFFER_COUNT := 5

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
	_check_rank_up_reward()


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
	relic_label.text = tr("REWARD_RELIC")
	relic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_label.add_theme_font_size_override("font_size", 28)
	relic_label.add_theme_color_override("font_color", RelicManager.get_relic_rarity_color(relic_offer_id))
	relic_section.add_child(relic_label)

	var relic_btn := Button.new()
	relic_btn.custom_minimum_size = Vector2(400, 100)
	var relic_name := RelicManager.get_relic_display_name(relic_offer_id)
	var relic_desc := RelicManager.get_relic_description(relic_offer_id)
	relic_btn.text = "✦ %s\n%s" % [relic_name, relic_desc]
	relic_btn.add_theme_font_size_override("font_size", 20)
	relic_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# 유물 버튼 스타일
	var relic_color := RelicManager.get_relic_rarity_color(relic_offer_id)
	var relic_style := StyleBoxFlat.new()
	relic_style.bg_color = Color(0.18, 0.15, 0.22, 1.0)
	relic_style.border_color = relic_color
	relic_style.set_border_width_all(2)
	relic_style.set_corner_radius_all(8)
	relic_style.set_content_margin_all(12)
	relic_btn.add_theme_stylebox_override("normal", relic_style)

	var relic_hover := relic_style.duplicate()
	relic_hover.bg_color = Color(0.23, 0.2, 0.28, 1.0)
	relic_hover.set_border_width_all(3)
	relic_btn.add_theme_stylebox_override("hover", relic_hover)

	relic_btn.pressed.connect(_on_relic_claimed)
	relic_section.add_child(relic_btn)

	# 카드 섹션 앞에 삽입
	$VBoxContainer.add_child(relic_section)
	$VBoxContainer.move_child(relic_section, $VBoxContainer.get_children().find(card_section))


func _on_relic_claimed() -> void:
	if relic_claimed or card_selected:
		return
	relic_claimed = true
	card_selected = true  # 유물과 카드 동시 획득 방지
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
		# Act 1 기본 전투 골드 +25% (초반 경제 보강)
		if GameManager.run_data.current_act == 1 and GameManager.run_data.current_node_type == MapData.NodeType.BATTLE:
			reward_gold = int(reward_gold * 1.25)
		# 천민 신분: 전투 보상 금화 +50%
		var gold_mult: float = JibunSystem.get_gold_reward_multiplier(GameManager.run_data)
		# 판서/정승(5등급): 모든 전투 보상 +30%
		gold_mult *= JibunSystem.get_all_reward_multiplier(GameManager.run_data)
		reward_gold = int(reward_gold * gold_mult)
		GameManager.run_data.gold += reward_gold
		if reward_gold > 0:
			AudioManager.play_sfx_by_key("coin")
	gold_label.text = tr("REWARD_GOLD_DISPLAY_FMT") % [reward_gold, GameManager.run_data.gold if GameManager.run_data else 0]


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

	# 상민 신분: 카드 보상 선택지 +1
	var offer_count: int = CARD_OFFER_COUNT + JibunSystem.get_card_offer_bonus(GameManager.run_data)

	# 아키타입 가중치: 덱 내 카드 아키타입과 일치하는 카드를 50% 확률로 1장 이상 포함
	var archetype_card := _pick_archetype_weighted_card(pool_cards)
	if archetype_card != "" and randf() < 0.5:
		card_offers.append(archetype_card)

	# 나머지 슬롯 — 셔플 후 선택
	var shuffled: Array[CardData] = pool_cards.duplicate()
	shuffled.shuffle()

	for i in shuffled.size():
		if card_offers.size() >= offer_count:
			break
		if shuffled[i].id not in card_offers:
			card_offers.append(shuffled[i].id)


## 덱 내 카드 아키타입을 분석하여 해당 아키타입의 카드를 1장 반환한다.
func _pick_archetype_weighted_card(pool: Array[CardData]) -> String:
	if GameManager.run_data == null:
		return ""
	var character_id: String = GameManager.run_data.character_id
	var archetypes: Array = DataLoader.get_archetypes(character_id)
	if archetypes.is_empty():
		return ""

	# 덱 카드 ID 수집
	var deck_ids: Array = GameManager.run_data.deck.duplicate()

	# 아키타입별 덱 내 존재 카드 수 집계
	var archetype_scores: Dictionary = {}
	for arch in archetypes:
		var arch_id: String = arch.get("id", "")
		var key_cards: Array = arch.get("key_cards", [])
		var count := 0
		for kid in key_cards:
			for did in deck_ids:
				if did == kid or did == kid + "+":
					count += 1
		if count > 0:
			archetype_scores[arch_id] = count

	if archetype_scores.is_empty():
		return ""

	# 가장 많은 아키타입 선택
	var best_arch := ""
	var best_count := 0
	for arch_id in archetype_scores:
		if archetype_scores[arch_id] > best_count:
			best_count = archetype_scores[arch_id]
			best_arch = arch_id

	# 해당 아키타입의 key_cards에서 덱에 없는 카드를 반환
	for arch in archetypes:
		if arch.get("id", "") == best_arch:
			var candidates: Array[String] = []
			for kid in arch.get("key_cards", []):
				if kid not in deck_ids and (kid + "+") not in deck_ids:
					candidates.append(kid)
			if not candidates.is_empty():
				candidates.shuffle()
				return candidates[0]
	return ""


func _display_card_offers() -> void:
	for child in card_container.get_children():
		child.queue_free()

	if card_offers.is_empty():
		card_section.visible = false
		skip_button.visible = false
		proceed_button.visible = true
		return

	# 뷰포트 비례 카드 크기 계산
	var vp_width := get_viewport().get_visible_rect().size.x
	var available_width := vp_width * 0.8  # VBoxContainer 앵커 0.1~0.9
	var card_count := card_offers.size()
	var card_spacing := 20
	var card_width := (available_width - card_spacing * (card_count - 1)) / card_count

	for i in card_offers.size():
		var card_id: String = card_offers[i]
		var card: CardData = DataLoader.get_card(card_id)
		if card == null:
			continue

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(card_width, 320)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = _format_card_text(card)
		btn.add_theme_font_size_override("font_size", 20)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_card_chosen.bind(i))

		# 희귀도에 따른 테두리 색상
		var rarity_color := _get_rarity_color(card.rarity)
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = Color(0.15, 0.17, 0.25, 1.0)
		stylebox.border_color = rarity_color
		stylebox.set_border_width_all(2)
		stylebox.set_corner_radius_all(8)
		stylebox.set_content_margin_all(12)
		btn.add_theme_stylebox_override("normal", stylebox)

		# 호버 스타일
		var hover_style := stylebox.duplicate()
		hover_style.bg_color = Color(0.2, 0.22, 0.32, 1.0)
		hover_style.set_border_width_all(3)
		btn.add_theme_stylebox_override("hover", hover_style)

		# 눌림 스타일
		var pressed_style := stylebox.duplicate()
		pressed_style.bg_color = Color(0.25, 0.27, 0.37, 1.0)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		card_container.add_child(btn)


func _format_card_text(card: CardData) -> String:
	var lines: Array[String] = []

	# 카드 이름
	lines.append(card.get_display_name())

	# 타입 + 희귀도 태그
	var type_str := _get_card_type_label(card.type)
	var rarity_str := _get_card_rarity_label(card.rarity)
	lines.append("[%s · %s]" % [rarity_str, type_str])

	# 기본 수치
	lines.append(tr("REWARD_CARD_STAT_FMT") % [card.cost, card.beat])

	if card.damage > 0:
		var dmg_text := tr("REWARD_CARD_DMG_FMT") % card.damage
		if card.is_aoe:
			dmg_text += tr("REWARD_CARD_DMG_AOE")
		lines.append(dmg_text)
	if card.block_value > 0:
		lines.append(tr("REWARD_CARD_BLOCK_FMT") % card.block_value)
	if card.draw_count > 0:
		lines.append(tr("REWARD_CARD_DRAW_FMT") % card.draw_count)
	if card.qi_gain > 0:
		lines.append(tr("REWARD_CARD_QI_FMT") % card.qi_gain)
	if card.tokens > 0:
		lines.append(tr("REWARD_CARD_TOKEN_FMT") % card.tokens)

	# 상태이상 부여
	if card.burn_stacks > 0:
		lines.append(tr("REWARD_CARD_BURN_FMT") % card.burn_stacks)
	if card.poison_stacks > 0:
		lines.append(tr("REWARD_CARD_POISON_FMT") % card.poison_stacks)
	if card.weaken_stacks > 0:
		lines.append(tr("REWARD_CARD_WEAKEN_FMT") % card.weaken_stacks)
	if card.vulnerable_stacks > 0:
		lines.append(tr("REWARD_CARD_VULNERABLE_FMT") % card.vulnerable_stacks)

	# 자원 소비/획득
	if card.stamina_cost > 0:
		lines.append(tr("REWARD_CARD_RESOURCE_COST_FMT") % card.stamina_cost)
	if card.stamina_gain > 0:
		lines.append(tr("REWARD_CARD_RESOURCE_GAIN_FMT") % card.stamina_gain)

	# 효과 텍스트
	var eff := card.get_current_effect()
	if eff != "":
		lines.append("")
		lines.append(eff)

	return "\n".join(lines)


func _get_card_type_label(card_type: String) -> String:
	match card_type:
		"attack":
			return tr("CARD_TYPE_ATTACK")
		"defense":
			return tr("CARD_TYPE_DEFENSE")
		"skill":
			return tr("CARD_TYPE_SKILL")
	return card_type


func _get_card_rarity_label(rarity_level: int) -> String:
	match rarity_level:
		1:
			return tr("CARD_RARITY_COMMON")
		2:
			return tr("CARD_RARITY_UNCOMMON")
		3:
			return tr("CARD_RARITY_RARE")
	return tr("CARD_RARITY_COMMON")


func _get_rarity_color(rarity_level: int) -> Color:
	match rarity_level:
		2:
			return Color(0.3, 0.7, 1.0)  # 고급: 파랑
		3:
			return Color(1.0, 0.85, 0.2)  # 희귀: 금색
	return Color(0.75, 0.75, 0.75)  # 일반: 회색


func _on_card_chosen(index: int) -> void:
	if card_selected:
		return
	card_selected = true

	if index >= 0 and index < card_offers.size():
		var card_id: String = card_offers[index]
		if GameManager.run_data:
			GameManager.run_data.deck.append(card_id)
			AudioManager.play_sfx_by_key("card_draw")

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


func _check_rank_up_reward() -> void:
	## 신분 승급 즉각 보상을 확인하고 UI를 표시한다.
	if not GameManager.run_data or not GameManager.run_data.has_meta("jibun_rank_up"):
		return

	var new_rank: int = GameManager.run_data.get_meta("jibun_rank_up")
	GameManager.run_data.remove_meta("jibun_rank_up")

	var reward_type: String = JibunSystem.RANK_UP_REWARDS.get(new_rank, "")
	if reward_type == "":
		return

	var rank_name: String = JibunSystem.get_rank_name(new_rank)
	var desc_key: String = JibunSystem.RANK_UP_REWARD_KEYS.get(new_rank, "")
	var desc: String = tr(desc_key) if desc_key != "" else ""

	# 승급 보상 섹션 UI 생성
	var rank_section := VBoxContainer.new()
	rank_section.name = "RankUpSection"

	var rank_label := Label.new()
	rank_label.text = tr("REWARD_RANK_UP_FMT") % rank_name
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 30)
	rank_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	rank_section.add_child(rank_label)

	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 20)
	rank_section.add_child(desc_label)

	match reward_type:
		"card_select":
			_build_rank_card_select(rank_section)
		"card_remove_free":
			_build_rank_card_remove(rank_section)
		"relic_select":
			_build_rank_relic_select(rank_section)
		"card_upgrade":
			_build_rank_card_upgrade(rank_section)

	# 카드 섹션 앞에 삽입
	$VBoxContainer.add_child(rank_section)
	$VBoxContainer.move_child(rank_section, $VBoxContainer.get_children().find(card_section))


func _build_rank_card_select(parent: VBoxContainer) -> void:
	## 중인 승급 보상: 카드 1장 추가 선택 UI
	var offers: Array[String] = []
	if GameManager.run_data:
		var character_id: String = GameManager.run_data.character_id
		var pool: Array[CardData] = DataLoader.get_cards_by_pool(character_id)
		pool.append_array(DataLoader.get_cards_by_pool("common"))
		pool.shuffle()
		for i in mini(3, pool.size()):
			offers.append(pool[i].id)

	var container := HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	for card_id in offers:
		var card: CardData = DataLoader.get_card(card_id)
		if card == null:
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 120)
		btn.text = "%s\n%s" % [card.get_display_name(), tr("REWARD_CARD_COST_FMT") % card.cost]
		btn.add_theme_font_size_override("font_size", 18)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_rank_card_chosen.bind(card_id, container))
		container.add_child(btn)
	parent.add_child(container)


func _on_rank_card_chosen(card_id: String, container: HBoxContainer) -> void:
	if GameManager.run_data:
		GameManager.run_data.deck.append(card_id)
		AudioManager.play_sfx_by_key("card_draw")
	for btn in container.get_children():
		if btn is Button:
			btn.disabled = true


func _build_rank_card_remove(parent: VBoxContainer) -> void:
	## 양반 승급 보상: 카드 제거 1회 무료
	if not GameManager.run_data or GameManager.run_data.deck.is_empty():
		return

	var container := HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER

	# 덱에서 최대 5장까지 선택지 표시
	var deck_sample: Array[String] = GameManager.run_data.deck.duplicate()
	deck_sample.shuffle()
	for i in mini(5, deck_sample.size()):
		var card_id: String = deck_sample[i]
		var card: CardData = DataLoader.get_card(card_id)
		if card == null:
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 100)
		btn.text = tr("REWARD_REMOVE_FMT") % card.get_display_name()
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_rank_card_removed.bind(card_id, container))
		container.add_child(btn)
	parent.add_child(container)


func _on_rank_card_removed(card_id: String, container: HBoxContainer) -> void:
	if GameManager.run_data:
		var idx: int = GameManager.run_data.deck.find(card_id)
		if idx >= 0:
			GameManager.run_data.deck.remove_at(idx)
			AudioManager.play_sfx_by_key("card_draw")
	for btn in container.get_children():
		if btn is Button:
			btn.disabled = true


func _build_rank_relic_select(parent: VBoxContainer) -> void:
	## 당상관 승급 보상: 유물 선택 1회 추가
	var relic_id: String = RelicManager.roll_relic_reward("elite")
	if relic_id == "":
		return

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(300, 80)
	var relic_name := RelicManager.get_relic_display_name(relic_id)
	var relic_desc := RelicManager.get_relic_description(relic_id)
	btn.text = "%s\n%s" % [relic_name, relic_desc]
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(func():
		RelicManager.acquire_relic(relic_id)
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	)
	parent.add_child(btn)


func _build_rank_card_upgrade(parent: VBoxContainer) -> void:
	## 판서/정승 승급 보상: 덱 카드 1장 강화 선택
	if not GameManager.run_data or GameManager.run_data.deck.is_empty():
		return

	var container := HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER

	# 업그레이드 가능한 카드 중 최대 5장 표시
	var upgradeable: Array[String] = []
	for cid in GameManager.run_data.deck:
		if not cid.ends_with("_plus"):
			upgradeable.append(cid)
	upgradeable.shuffle()

	for i in mini(5, upgradeable.size()):
		var card_id: String = upgradeable[i]
		var card: CardData = DataLoader.get_card(card_id)
		if card == null:
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 100)
		btn.text = tr("REWARD_UPGRADE_FMT") % card.get_display_name()
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_rank_card_upgraded.bind(card_id, container))
		container.add_child(btn)
	parent.add_child(container)


func _on_rank_card_upgraded(card_id: String, container: HBoxContainer) -> void:
	if GameManager.run_data:
		var idx: int = GameManager.run_data.deck.find(card_id)
		if idx >= 0:
			GameManager.run_data.deck[idx] = card_id + "_plus"
			AudioManager.play_sfx_by_key("card_draw")
	for btn in container.get_children():
		if btn is Button:
			btn.disabled = true


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
		# 보스 처치 후 HP 최대치의 20% 회복
		if GameManager.run_data:
			var heal_amount: int = int(GameManager.run_data.max_hp * 0.2)
			GameManager.run_data.current_hp = mini(
				GameManager.run_data.current_hp + heal_amount,
				GameManager.run_data.max_hp
			)

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
