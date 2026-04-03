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
		continue_button.text = "돌아가기"
		return

	# 덱 카드 로드 및 셔플
	_load_deck_cards()
	# 시험관 결정
	_examiner = GwageoScorer.roll_examiner()
	if _examiner.is_empty():
		_examiner = {"id": "scholar", "name": "학자", "bonus": "none"}
	examiner_label.text = "시험관: %s" % _examiner.get("name", "학자")

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
			phase_label.text = "초장(初章) — 카드 3장 선택"
			instruction_label.text = "채점 기준: 공격·방어·기술 비율 균형\n만점 조건: 각 유형 1장씩 포함"
			_max_select = 3
			_offer_cards(5)
		Phase.JUNGJANG:
			phase_label.text = "중장(中章) — 카드 3장 선택"
			instruction_label.text = "채점 기준: 초장 카드와 키워드 시너지\n만점 조건: 시너지 태그 2개 이상 연계"
			_max_select = 3
			_offer_cards(5)
		Phase.JONGJANG:
			phase_label.text = "종장(終章) — 카드 2장 선택"
			instruction_label.text = "채점 기준: 합산 피해량\n만점 조건: 합산 피해 12+"
			_max_select = 2
			_offer_cards(4)
		Phase.RESULT:
			_show_result()


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
		btn.custom_minimum_size = Vector2(0, 80)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.toggle_mode = true
		btn.pressed.connect(_on_card_toggled.bind(i, btn))
		card_container.add_child(btn)


func _format_card_text(card: CardData) -> String:
	var lines: Array[String] = []
	var type_label := ""
	match card.type:
		"attack": type_label = "[공격]"
		"defense": type_label = "[방어]"
		"spell": type_label = "[주문]"
		"movement": type_label = "[이동]"
		"formation": type_label = "[진형]"
		_: type_label = "[%s]" % card.type

	lines.append("%s %s  비용:%d" % [type_label, card.get_display_name(), card.cost])
	if card.damage > 0:
		lines.append("피해:%d%s" % [card.damage, " (전체)" if card.is_aoe else ""])
	if card.block_value > 0:
		lines.append("방어:%d" % card.block_value)
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

	selected_label.text = "선택: %d/%d" % [_selected_indices.size(), _max_select]
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
	phase_label.text = "채점 결과"
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
	result_lines.append("점수: %d / 100" % final_score)
	result_lines.append("등급: %s" % grade_name)
	result_lines.append("")
	result_lines.append(reward_text)

	# 암행어사 시험관 특수: 낙방해도 엽전 손실 없음
	if _examiner.get("id", "") == "amhaengosa" and grade == "nakbang":
		result_lines.append("(암행어사 시험관: 엽전 손실 없음)")

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
			var text := "장원 급제! 전설 카드를 획득합니다."
			if _examiner.get("id", "") == "amhaengosa":
				# 특수 유물 지급 (기존 유물 시스템 활용)
				var relic_id := RelicManager.roll_relic_reward("event")
				if relic_id != "":
					RelicManager.acquire_relic(relic_id)
					text += "\n암행어사의 추천장 — 유물 획득!"
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
			return "급제! 희귀 카드 %d장 획득." % offers.size()

		"hapgyeok":
			# 합격: 일반 카드 3장 선택
			var offers := _generate_card_offers_by_rarity(3, 1)
			for card_id in offers:
				rd.deck.append(card_id)
			return "합격. 카드 %d장 획득." % offers.size()

		"nakbang":
			# 낙방: 엽전 30 손실 + 신분 -10 (이미 적용됨)
			if _examiner.get("id", "") != "amhaengosa":
				rd.gold = maxi(rd.gold - 30, 0)
				return "낙방... 엽전 30 손실."
			return "낙방... 하지만 암행어사가 지켜보고 있었다."

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
	phase_label.text = "뇌물 수수"
	instruction_label.text = ""
	confirm_button.visible = false
	selected_label.text = ""
	bribe_button.visible = false

	result_label.text = "뇌물로 합격을 샀다.\n엽전 -50, 민심 -20\n카드 %d장 획득." % offers.size()
	result_label.visible = true
	continue_button.visible = true
	_update_status_bar()


func _clear_card_buttons() -> void:
	for child in card_container.get_children():
		child.queue_free()


func _update_status_bar() -> void:
	var rd := GameManager.run_data
	if rd:
		hp_label.text = "HP: %d/%d" % [rd.current_hp, rd.max_hp]
		gold_label.text = "엽전: %d" % rd.gold
		jibun_label.text = "신분: %s" % JibunSystem.get_rank_name(rd.jibun_rank)
	else:
		hp_label.text = "HP: --/--"
		gold_label.text = "엽전: --"
		jibun_label.text = "신분: --"


func _return_to_map() -> void:
	GameManager.save_current_run()
	GameManager.change_state(GameManager.GameState.MAP)
