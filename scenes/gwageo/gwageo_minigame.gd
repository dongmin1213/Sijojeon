extends Control

## 과거시험 미니게임 씬.
## 덱에서 카드를 골라 시조 3장(초장·중장·종장)을 구성하고 채점한다.

enum Phase { CHOJANG, JUNGJANG, JONGJANG, RESULT }

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var examiner_label: Label = $VBoxContainer/ExaminerLabel
@onready var phase_label: Label = $VBoxContainer/PhaseLabel
@onready var instruction_label: Label = $VBoxContainer/InstructionLabel
@onready var card_container: VBoxContainer = $VBoxContainer/CardContainer
@onready var selected_label: Label = $VBoxContainer/SelectedLabel
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var bribe_button: Button = $VBoxContainer/BribeButton
@onready var hp_label: Label = $VBoxContainer/StatusBar/HPLabel
@onready var gold_label: Label = $VBoxContainer/StatusBar/GoldLabel
@onready var jibun_label: Label = $VBoxContainer/StatusBar/JibunLabel

var _phase: Phase = Phase.CHOJANG
var _examiner: Dictionary = {}
var _offered_cards: Array[CardData] = []
var _selected_indices: Array[int] = []
var _max_select: int = 3

# 각 단계에서 선택한 카드
var _chojang_cards: Array[CardData] = []
var _jungjang_cards: Array[CardData] = []
var _jongjang_cards: Array[CardData] = []

# 덱에서 뽑을 카드 풀 (중복 방지)
var _available_cards: Array[CardData] = []


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm)
	continue_button.pressed.connect(_return_to_map)
	bribe_button.pressed.connect(_on_bribe)
	continue_button.visible = false
	result_label.visible = false
	bribe_button.visible = false

	if GameManager.run_data == null:
		continue_button.visible = true
		continue_button.text = tr("GWAGEO_BACK")
		return

	# 덱 카드 로드 및 셔플
	_load_deck_cards()
	# 시험관 결정
	_examiner = GwageoScorer.roll_examiner()
	if _examiner.is_empty():
		_examiner = {"id": "scholar", "name": tr("GWAGEO_EXAMINER_DEFAULT"), "bonus": "none"}
	examiner_label.text = tr("GWAGEO_EXAMINER_FMT") % _examiner.get("name", tr("GWAGEO_EXAMINER_DEFAULT"))

	# 탐관 시험관: 뇌물 옵션
	if _examiner.get("id", "") == "corrupt" and GameManager.run_data.gold >= 50:
		bribe_button.visible = true

	_update_status_bar()
	_start_phase(Phase.CHOJANG)


func _load_deck_cards() -> void:
	_available_cards.clear()
	var rd := GameManager.run_data
	if rd == null:
		return
	# 덱의 모든 카드를 CardData로 로드
	var deck_copy := rd.deck.duplicate()
	deck_copy.shuffle()
	for card_id in deck_copy:
		var card: CardData = DataLoader.get_card(card_id)
		if card != null:
			# 강화된 카드 반영
			if rd.upgraded_cards.has(card_id):
				card = card.duplicate_card()
				card.upgraded = true
			_available_cards.append(card)


func _start_phase(phase: Phase) -> void:
	_phase = phase
	_selected_indices.clear()
	_clear_card_buttons()
	confirm_button.visible = false
	selected_label.text = ""

	match phase:
		Phase.CHOJANG:
			_max_select = 3
			_offer_cards(5)
			_max_select = mini(_max_select, _offered_cards.size())
			phase_label.text = tr("GWAGEO_PHASE_CHOJANG") % _max_select
			instruction_label.text = tr("GWAGEO_HINT_CHOJANG")
		Phase.JUNGJANG:
			_max_select = 3
			_offer_cards(5)
			_max_select = mini(_max_select, _offered_cards.size())
			phase_label.text = tr("GWAGEO_PHASE_JUNGJANG") % _max_select
			instruction_label.text = tr("GWAGEO_HINT_JUNGJANG")
		Phase.JONGJANG:
			_max_select = 2
			_offer_cards(4)
			_max_select = mini(_max_select, _offered_cards.size())
			phase_label.text = tr("GWAGEO_PHASE_JONGJANG") % _max_select
			instruction_label.text = tr("GWAGEO_HINT_JONGJANG")
		Phase.RESULT:
			_show_result()
			return

	# 카드가 0장이면 바로 다음 단계로 건너뜀
	if _offered_cards.is_empty():
		_on_confirm()
		return

	selected_label.text = tr("GWAGEO_SELECT_FMT") % [0, _max_select]
	# 선택할 카드가 1장뿐이고 필요 수도 1이면 자동 선택 처리
	if _max_select == 1 and _offered_cards.size() == 1:
		_selected_indices.append(0)
		var btns := card_container.get_children()
		if btns.size() > 0 and btns[0] is Button:
			btns[0].button_pressed = true
		selected_label.text = tr("GWAGEO_SELECT_FMT") % [1, 1]
		confirm_button.visible = true


func _offer_cards(count: int) -> void:
	_offered_cards.clear()
	var take := mini(count, _available_cards.size())
	for i in take:
		_offered_cards.append(_available_cards[i])
	# 사용한 카드를 풀에서 제거
	for i in range(take - 1, -1, -1):
		_available_cards.remove_at(i)

	_build_card_buttons()


func _build_card_buttons() -> void:
	_clear_card_buttons()
	for i in _offered_cards.size():
		var card := _offered_cards[i]
		var btn := Button.new()
		btn.text = _format_card_text(card)
		btn.custom_minimum_size = Vector2(0, 90)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 22)
		btn.toggle_mode = true
		btn.pressed.connect(_on_card_toggled.bind(i, btn))
		card_container.add_child(btn)


func _format_card_text(card: CardData) -> String:
	var lines: Array[String] = []
	var type_label := ""
	match card.type:
		"attack": type_label = tr("GWAGEO_CARD_TYPE_ATTACK")
		"defense": type_label = tr("GWAGEO_CARD_TYPE_DEFENSE")
		"spell": type_label = tr("GWAGEO_CARD_TYPE_SPELL")
		"movement": type_label = tr("GWAGEO_CARD_TYPE_MOVEMENT")
		"formation": type_label = tr("GWAGEO_CARD_TYPE_FORMATION")
		_: type_label = "[%s]" % card.type

	lines.append(tr("GWAGEO_CARD_INFO_FMT") % [type_label, card.get_display_name(), card.cost])
	if card.damage > 0:
		lines.append(tr("GWAGEO_CARD_DAMAGE_FMT") % [card.damage, " " + tr("SHOP_CARD_DAMAGE_AOE") if card.is_aoe else ""])
	if card.block_value > 0:
		lines.append(tr("GWAGEO_CARD_BLOCK_FMT") % card.block_value)
	if card.effect != "":
		lines.append(card.get_current_effect())
	return " | ".join(lines)


func _on_card_toggled(index: int, btn: Button) -> void:
	if btn.button_pressed:
		if _selected_indices.size() >= _max_select:
			btn.button_pressed = false
			return
		_selected_indices.append(index)
	else:
		_selected_indices.erase(index)

	selected_label.text = tr("GWAGEO_SELECT_FMT") % [_selected_indices.size(), _max_select]
	confirm_button.visible = _selected_indices.size() == _max_select


func _on_confirm() -> void:
	var selected_cards: Array[CardData] = []
	for idx in _selected_indices:
		if idx < 0 or idx >= _offered_cards.size():
			continue
		selected_cards.append(_offered_cards[idx])

	match _phase:
		Phase.CHOJANG:
			_chojang_cards = selected_cards
			_start_phase(Phase.JUNGJANG)
		Phase.JUNGJANG:
			_jungjang_cards = selected_cards
			_start_phase(Phase.JONGJANG)
		Phase.JONGJANG:
			_jongjang_cards = selected_cards
			_start_phase(Phase.RESULT)


func _show_result() -> void:
	_clear_card_buttons()
	phase_label.text = tr("GWAGEO_RESULT_TITLE")
	instruction_label.text = ""
	confirm_button.visible = false
	selected_label.text = ""
	bribe_button.visible = false

	# 채점
	var base_score := GwageoScorer.calculate_score(
		_chojang_cards, _jungjang_cards, _jongjang_cards
	)
	var final_score := GwageoScorer.apply_examiner_bonus(
		base_score, _examiner.get("id", "scholar"), GameManager.run_data
	)
	final_score = clampi(final_score, 0, 100)
	var grade := GwageoScorer.get_grade(final_score)
	var grade_name := GwageoScorer.get_grade_name(grade)

	# 보상 적용
	var reward_text := _apply_rewards(grade, final_score)

	# 결과 표시
	var result_lines: Array[String] = []
	result_lines.append(tr("GWAGEO_SCORE_FMT") % final_score)
	result_lines.append(tr("GWAGEO_GRADE_FMT") % grade_name)
	result_lines.append("")
	result_lines.append(reward_text)

	# 암행어사 시험관 특수: 낙방해도 엽전 손실 없음
	if _examiner.get("id", "") == "amhaengosa" and grade == "nakbang":
		result_lines.append(tr("GWAGEO_AMHAENGOSA_NOTE"))

	result_label.text = "\n".join(result_lines)
	result_label.visible = true
	continue_button.visible = true
	continue_button.grab_focus()

	_update_status_bar()


func _apply_rewards(grade: String, _score: int) -> String:
	var rd := GameManager.run_data
	if rd == null:
		return ""

	# 신분 점수 변동
	JibunSystem.on_gwageo_result(rd, grade)

	match grade:
		"jangwon":
			# 장원 급제: 전설 카드 1장 선택 + 신분 +50 (이미 적용됨)
			# 암행어사 시험관이면 특수 유물 추가
			var text := tr("GWAGEO_JANGWON")
			if _examiner.get("id", "") == "amhaengosa":
				# 특수 유물 지급 (기존 유물 시스템 활용)
				var relic_id := RelicManager.roll_relic_reward("event")
				if relic_id != "":
					RelicManager.acquire_relic(relic_id)
					text += "\n" + tr("GWAGEO_JANGWON_RELIC")
			# 카드 추가 (높은 레어리티)
			var offers := _generate_card_offers_by_rarity(3, 3)
			if not offers.is_empty():
				rd.deck.append(offers[0])
			return text

		"geupje":
			# 급제: 희귀 카드 2장 선택
			var offers := _generate_card_offers_by_rarity(2, 2)
			for card_id in offers:
				rd.deck.append(card_id)
			return tr("GWAGEO_GEUPJE_FMT") % offers.size()

		"hapgyeok":
			# 합격: 일반 카드 3장 선택
			var offers := _generate_card_offers_by_rarity(3, 1)
			for card_id in offers:
				rd.deck.append(card_id)
			return tr("GWAGEO_HAPGYEOK_FMT") % offers.size()

		"nakbang":
			# 낙방: 엽전 30 손실 + 신분 -10 (이미 적용됨)
			if _examiner.get("id", "") != "amhaengosa":
				rd.gold = maxi(rd.gold - 30, 0)
				return tr("GWAGEO_NAKBANG_LOSS")
			return tr("GWAGEO_NAKBANG_SAFE")

	return ""


func _generate_card_offers_by_rarity(count: int, min_rarity: int) -> Array[String]:
	if not GameManager.run_data:
		return []
	var character_id: String = GameManager.run_data.character_id
	var pool: Array[CardData] = []
	pool.append_array(DataLoader.get_cards_by_pool(character_id))
	pool.append_array(DataLoader.get_cards_by_pool("common"))

	# 레어리티 필터
	var filtered: Array[CardData] = []
	for card in pool:
		if card.rarity >= min_rarity:
			filtered.append(card)
	filtered.shuffle()

	var result: Array[String] = []
	for i in mini(count, filtered.size()):
		result.append(filtered[i].id)
	return result


func _on_bribe() -> void:
	# 뇌물 50냥으로 합격 보장
	var rd := GameManager.run_data
	if rd == null or rd.gold < 50:
		return
	rd.gold -= 50
	# 민심 -20
	var minshim: int = rd.narrative_state.get("minshim", 50)
	rd.narrative_state["minshim"] = clampi(minshim - 20, 0, 100)
	# 합격 보상 적용
	JibunSystem.on_gwageo_result(rd, "hapgyeok")
	var offers := _generate_card_offers_by_rarity(3, 1)
	for card_id in offers:
		rd.deck.append(card_id)

	_clear_card_buttons()
	phase_label.text = tr("GWAGEO_BRIBE_TITLE")
	instruction_label.text = ""
	confirm_button.visible = false
	selected_label.text = ""
	bribe_button.visible = false

	result_label.text = tr("GWAGEO_BRIBE_RESULT_FMT") % offers.size()
	result_label.visible = true
	continue_button.visible = true
	_update_status_bar()


func _clear_card_buttons() -> void:
	for child in card_container.get_children():
		child.queue_free()


func _update_status_bar() -> void:
	var rd := GameManager.run_data
	if rd:
		hp_label.text = tr("GWAGEO_STATUS_HP") % [rd.current_hp, rd.max_hp]
		gold_label.text = tr("GWAGEO_STATUS_GOLD") % rd.gold
		jibun_label.text = tr("GWAGEO_STATUS_JIBUN") % JibunSystem.get_rank_name(rd.jibun_rank)
	else:
		hp_label.text = "HP: --/--"
		gold_label.text = tr("GWAGEO_STATUS_GOLD").replace("%d", "--")
		jibun_label.text = tr("GWAGEO_STATUS_JIBUN").replace("%s", "--")


func _return_to_map() -> void:
	GameManager.save_current_run()
	GameManager.change_state(GameManager.GameState.MAP)
