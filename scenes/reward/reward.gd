extends Control

## 전투 보상 씬. 골드 획득 + 카드 3택 1 선택.

const CARD_OFFER_COUNT := 5

var reward_gold: int = 0
var card_offers: Array[String] = []  # 제시된 카드 ID 목록
var card_selected: bool = false
var relic_offer_id: String = ""  # 유물 보상 ID (빈 문자열이면 유물 없음)
var boss_relic_offers: Array[String] = []  # 보스 유물 3택 목록
var relic_claimed: bool = false

@onready var title_label: Label = $RewardPanel/VBoxContainer/TitleLabel
@onready var gold_label: Label = $RewardPanel/VBoxContainer/GoldLabel
@onready var card_section: VBoxContainer = $RewardPanel/VBoxContainer/CardSection
@onready var card_scroll: ScrollContainer = $RewardPanel/VBoxContainer/CardSection/CardScroll
@onready var card_container: HBoxContainer = $RewardPanel/VBoxContainer/CardSection/CardScroll/CardContainer
@onready var skip_button: Button = $RewardPanel/VBoxContainer/SkipButton
@onready var proceed_button: Button = $RewardPanel/VBoxContainer/ProceedButton


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
	_try_potion_drop()
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


func _try_potion_drop() -> void:
	## 전투 후 확률적으로 포션을 드롭한다.
	if GameManager.run_data == null:
		return
	# 빈 슬롯이 있는지 확인
	var has_slot := false
	for p in GameManager.run_data.potions:
		if p == "":
			has_slot = true
			break
	if not has_slot:
		return
	# 드롭 확률 (일반 40%, 정예 60%, 보스 100%)
	var drop_chance := 0.4
	if GameManager.run_data.current_node_type == MapData.NodeType.ELITE:
		drop_chance = 0.6
	elif GameManager.run_data.current_node_type == MapData.NodeType.BOSS:
		drop_chance = 1.0
	if randf() > drop_chance:
		return
	var potion_id := DataLoader.get_random_potion()
	if potion_id == "":
		return
	for i in GameManager.run_data.potions.size():
		if GameManager.run_data.potions[i] == "":
			GameManager.run_data.potions[i] = potion_id
			break


func _try_relic_reward() -> void:
	## 전투 보상에서 유물 드롭을 시도한다.
	## StS 표준: 엘리트/보스는 100% 유물 드롭, 일반 전투는 `relic_chance` 메타 기반.
	if not GameManager.run_data:
		return

	# 노드 타입에 따라 소스 결정 및 보장 드롭 여부 판단
	var source := ""
	var guaranteed := false
	if GameManager.run_data.current_node_type >= 0:
		match GameManager.run_data.current_node_type:
			MapData.NodeType.BOSS:
				source = "boss"
				guaranteed = true
			MapData.NodeType.ELITE:
				source = "elite"
				guaranteed = true
			_:
				source = "elite"  # 이벤트/특수 보상의 기본 풀

	# 보장 드롭이 아니면 전투 보상 메타의 확률 체크
	if not guaranteed:
		var rewards = GameManager.run_data.get_meta("battle_rewards", {})
		var relic_chance: float = rewards.get("relic_chance", 0.0)
		if relic_chance <= 0.0 or randf() > relic_chance:
			return

	if source == "boss":
		# 보스 처치 시 3개 유물 중 1택 (StS 방식)
		boss_relic_offers.clear()
		for _i in 3:
			var rolled := RelicManager.roll_relic_reward("boss")
			if rolled != "" and rolled not in boss_relic_offers:
				boss_relic_offers.append(rolled)
		if not boss_relic_offers.is_empty():
			_display_boss_relic_choice()
		return

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
	relic_btn.add_theme_font_size_override("font_size", 22)
	relic_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# v5: 단청 스타일 유물 버튼
	var relic_color := RelicManager.get_relic_rarity_color(relic_offer_id)
	var relic_style := StyleBoxFlat.new()
	relic_style.bg_color = Color(0.08, 0.07, 0.06, 0.95)
	relic_style.border_color = relic_color
	relic_style.set_border_width_all(2)
	relic_style.set_corner_radius_all(14)
	relic_style.set_content_margin_all(14)
	relic_style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	relic_style.shadow_size = 4
	relic_btn.add_theme_stylebox_override("normal", relic_style)

	var relic_hover := relic_style.duplicate()
	relic_hover.bg_color = Color(0.12, 0.11, 0.10, 0.95)
	relic_hover.set_border_width_all(3)
	relic_hover.shadow_size = 6
	relic_btn.add_theme_stylebox_override("hover", relic_hover)

	relic_btn.pressed.connect(_on_relic_claimed)
	relic_section.add_child(relic_btn)

	# 카드 섹션 앞에 삽입
	$RewardPanel/VBoxContainer.add_child(relic_section)
	$RewardPanel/VBoxContainer.move_child(relic_section, $RewardPanel/VBoxContainer.get_children().find(card_section))


func _display_boss_relic_choice() -> void:
	## 보스 유물 3택 UI (StS 방식: 보스 처치 후 3개 중 1개 선택)
	var section := VBoxContainer.new()
	section.name = "BossRelicSection"

	var label := Label.new()
	label.text = tr("REWARD_BOSS_RELIC")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	section.add_child(label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	section.add_child(hbox)

	for i in boss_relic_offers.size():
		var rid: String = boss_relic_offers[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(280, 120)
		var rname := RelicManager.get_relic_display_name(rid)
		var rdesc := RelicManager.get_relic_description(rid)
		btn.text = "✦ %s\n%s" % [rname, rdesc]
		btn.add_theme_font_size_override("font_size", 20)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var rcolor := RelicManager.get_relic_rarity_color(rid)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.07, 0.06, 0.95)
		style.border_color = rcolor
		style.set_border_width_all(2)
		style.set_corner_radius_all(14)
		style.set_content_margin_all(12)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style := style.duplicate()
		hover_style.bg_color = Color(0.14, 0.12, 0.10, 0.95)
		hover_style.set_border_width_all(3)
		btn.add_theme_stylebox_override("hover", hover_style)

		btn.pressed.connect(_on_boss_relic_chosen.bind(i))
		hbox.add_child(btn)

	$RewardPanel/VBoxContainer.add_child(section)
	$RewardPanel/VBoxContainer.move_child(section, $RewardPanel/VBoxContainer.get_children().find(card_section))


func _on_boss_relic_chosen(index: int) -> void:
	if relic_claimed:
		return
	relic_claimed = true
	var chosen_id: String = boss_relic_offers[index]
	RelicManager.acquire_relic(chosen_id)

	var section = $RewardPanel/VBoxContainer.get_node_or_null("BossRelicSection")
	if section:
		for child in section.get_children():
			if child is HBoxContainer:
				for btn in child.get_children():
					if btn is Button:
						btn.disabled = true


func _on_relic_claimed() -> void:
	if relic_claimed or card_selected:
		return
	relic_claimed = true
	card_selected = true  # 유물과 카드 동시 획득 방지
	RelicManager.acquire_relic(relic_offer_id)

	# UI 비활성화
	var relic_section = $RewardPanel/VBoxContainer.get_node_or_null("RelicSection")
	if relic_section:
		for child in relic_section.get_children():
			if child is Button:
				child.disabled = true
				child.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))


func _apply_gold() -> void:
	if GameManager.run_data:
		# Act 1 기본 전투 골드 +25% (초반 경제 보강)
		if GameManager.run_data.current_act == 1 and GameManager.run_data.current_node_type == MapData.NodeType.BATTLE:
			reward_gold = int(reward_gold * 1.25)
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

	# 캐릭터 클래스 카드 + 공용 카드 풀에서 선택 (해금된 카드만)
	var class_cards := DataLoader.get_cards_by_pool(character_id)
	var common_cards := DataLoader.get_cards_by_pool("common")
	for card in class_cards:
		if CardUnlockSystem.is_card_unlocked(card.id):
			pool_cards.append(card)
	for card in common_cards:
		if CardUnlockSystem.is_card_unlocked(card.id):
			pool_cards.append(card)

	var offer_count: int = CARD_OFFER_COUNT

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

	# 카드 크기 — 화면 너비 기반 자동 계산 (여백 고려)
	var available_width: float = get_viewport_rect().size.x - 80  # 좌우 패딩
	var gap := 10.0
	var count := card_offers.size()
	var card_width := minf(160.0, (available_width - gap * (count - 1)) / count)
	var card_height := card_width * 1.5  # 2:3 비율

	for i in card_offers.size():
		var card_id: String = card_offers[i]
		var card: CardData = DataLoader.get_card(card_id)
		if card == null:
			continue

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(card_width, card_height)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = _format_card_text(card)
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", Color(0.92, 0.88, 0.80))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		btn.pressed.connect(_on_card_chosen.bind(i))

		# 카드 프레임 스타일
		var rarity_color := _get_rarity_color(card.rarity)
		var frame_path := _get_frame_path(card.rarity)
		var frame_tex = load(frame_path) as Texture2D if ResourceLoader.exists(frame_path) else null

		var stylebox: StyleBox
		if frame_tex:
			var tex_sb := StyleBoxTexture.new()
			tex_sb.texture = frame_tex
			tex_sb.texture_margin_left = 12
			tex_sb.texture_margin_right = 12
			tex_sb.texture_margin_top = 42
			tex_sb.texture_margin_bottom = 12
			tex_sb.content_margin_left = 8
			tex_sb.content_margin_right = 8
			tex_sb.content_margin_top = 6
			tex_sb.content_margin_bottom = 6
			stylebox = tex_sb
		else:
			var flat_sb := StyleBoxFlat.new()
			flat_sb.bg_color = Color(0.10, 0.08, 0.18, 0.95)
			flat_sb.border_color = rarity_color
			flat_sb.set_border_width_all(2)
			flat_sb.set_corner_radius_all(10)
			flat_sb.content_margin_left = 8
			flat_sb.content_margin_right = 8
			flat_sb.content_margin_top = 6
			flat_sb.content_margin_bottom = 6
			flat_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
			flat_sb.shadow_size = 4
			stylebox = flat_sb
		btn.add_theme_stylebox_override("normal", stylebox)

		# 호버/눌림 피드백
		if stylebox is StyleBoxTexture:
			var hover_st := stylebox.duplicate()
			hover_st.modulate_color = Color(1.2, 1.2, 1.2)
			btn.add_theme_stylebox_override("hover", hover_st)
			var press_st := stylebox.duplicate()
			press_st.modulate_color = Color(0.9, 0.9, 0.9)
			btn.add_theme_stylebox_override("pressed", press_st)
		else:
			var hover_style := (stylebox as StyleBoxFlat).duplicate()
			hover_style.bg_color = Color(0.14, 0.12, 0.24, 0.95)
			hover_style.set_border_width_all(3)
			btn.add_theme_stylebox_override("hover", hover_style)
			var pressed_style := (stylebox as StyleBoxFlat).duplicate()
			pressed_style.bg_color = Color(0.18, 0.14, 0.28, 0.95)
			btn.add_theme_stylebox_override("pressed", pressed_style)

		card_container.add_child(btn)


func _format_card_text(card: CardData) -> String:
	var lines: Array[String] = []

	# 카드 이름 (가장 중요)
	lines.append(card.get_display_name())

	# 타입 · 희귀도 한 줄
	var type_str := _get_card_type_label(card.type)
	var rarity_str := _get_card_rarity_label(card.rarity)
	lines.append("%s · %s" % [rarity_str, type_str])

	# 코스트
	lines.append(tr("REWARD_CARD_COST_FMT") % card.cost)

	# 핵심 수치만 간결하게
	var stats: Array[String] = []
	if card.damage > 0:
		var dmg_text := tr("REWARD_CARD_DMG_FMT") % card.damage
		if card.is_aoe:
			dmg_text += tr("REWARD_CARD_DMG_AOE")
		stats.append(dmg_text)
	if card.block_value > 0:
		stats.append(tr("REWARD_CARD_BLOCK_FMT") % card.block_value)
	if card.draw_count > 0:
		stats.append(tr("REWARD_CARD_DRAW_FMT") % card.draw_count)
	if card.qi_gain > 0:
		stats.append(tr("REWARD_CARD_QI_FMT") % card.qi_gain)
	if not stats.is_empty():
		lines.append(" / ".join(stats))

	# 상태이상 — 있을 때만 한 줄로 요약
	var debuffs: Array[String] = []
	if card.burn_stacks > 0:
		debuffs.append(tr("REWARD_CARD_BURN_FMT") % card.burn_stacks)
	if card.poison_stacks > 0:
		debuffs.append(tr("REWARD_CARD_POISON_FMT") % card.poison_stacks)
	if card.weaken_stacks > 0:
		debuffs.append(tr("REWARD_CARD_WEAKEN_FMT") % card.weaken_stacks)
	if card.vulnerable_stacks > 0:
		debuffs.append(tr("REWARD_CARD_VULNERABLE_FMT") % card.vulnerable_stacks)
	if not debuffs.is_empty():
		lines.append(" / ".join(debuffs))

	# 효과 텍스트 (있으면)
	var eff := card.get_current_effect()
	if eff != "":
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


func _get_frame_path(rarity_level: int) -> String:
	## v6: 희귀도별 카드 프레임 SVG 경로
	match rarity_level:
		2: return "res://art/ui/card_frame_uncommon.svg"
		3: return "res://art/ui/card_frame_rare.svg"
		4: return "res://art/ui/card_frame_rare.svg"
		5: return "res://art/ui/card_frame_legendary.svg"
	return "res://art/ui/card_frame_common.svg"


func _get_rarity_color(rarity_level: int) -> Color:
	# v5: 단청 팔레트 희귀도
	match rarity_level:
		2:
			return Color(0.17, 0.30, 0.50)  # 고급: 남색
		3:
			return Color(0.76, 0.23, 0.13)  # 희귀: 금색
	return Color(0.60, 0.55, 0.50)  # 일반: 따뜻한 회색


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
				buttons[i].add_theme_color_override("font_color", Color(0.96, 0.94, 0.91))
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
