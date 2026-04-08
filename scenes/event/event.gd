extends Control

## 랜덤 이벤트 씬.
## 현재 막(act)에 맞는 이벤트를 로드하고, 선택지 UI를 표시하며,
## 효과를 적용한 뒤 결과 텍스트를 보여준다.
## 특수 역사 사건 이벤트(special_events.json)를 우선 체크한다.

# v9: 제목은 상단 오버레이에 표시 (VN 스타일)
@onready var title_label: Label = $TitleOverlay
@onready var flavor_label: Label = $VBoxContainer/FlavorLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var choice_container: VBoxContainer = $VBoxContainer/ChoiceContainer
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var hp_label: Label = $StatusOverlay/StatusBar/HPLabel
@onready var gold_label: Label = $StatusOverlay/StatusBar/GoldLabel

var _event_data: Dictionary = {}


func _ready() -> void:
	continue_button.pressed.connect(_return_to_map)
	continue_button.visible = false
	result_label.visible = false

	if GameManager.run_data == null:
		push_warning("Event: run_data가 null — 맵으로 복귀")
		continue_button.visible = true
		continue_button.text = tr("EVENT_BACK")
		return

	_load_random_event()
	if _event_data.is_empty():
		push_warning("Event: 이벤트 데이터 로드 실패 — 맵으로 복귀")
		continue_button.visible = true
		continue_button.text = tr("EVENT_BACK")
		return
	_build_ui()
	_update_status_bar()


func _load_random_event() -> void:
	var act := 1
	var floor_num := 0
	if GameManager.run_data:
		act = GameManager.run_data.current_act
		floor_num = GameManager.run_data.current_floor

	var node_type_str := _get_current_node_type_str()

	# 1. 특수 이벤트 체크 (발동 조건 + 중복 방지)
	var special_event = _try_load_special_event(act, floor_num, node_type_str)
	if special_event != null:
		_event_data = special_event
		return

	# 2. 일반 이벤트 풀 (기존 로직 유지)
	var path := "res://data/events/act%d_events.json" % act
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		file = FileAccess.open("res://data/events/act1_events.json", FileAccess.READ)
	if file == null:
		_event_data = {"title": {"ko": "알 수 없는 사건", "en": "Unknown Event"}, "description": {"ko": "", "en": ""}, "choices": []}
		return

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK or not (json.data is Dictionary):
		_event_data = {"title": {"ko": "알 수 없는 사건", "en": "Unknown Event"}, "description": {"ko": "", "en": ""}, "choices": []}
		return

	var events: Array = json.data.get("events", [])
	if events.is_empty():
		_event_data = {"title": {"ko": "알 수 없는 사건", "en": "Unknown Event"}, "description": {"ko": "", "en": ""}, "choices": []}
		return

	_event_data = events[randi() % events.size()]


## 현재 노드 타입을 문자열로 반환한다.
func _get_current_node_type_str() -> String:
	if not GameManager.run_data:
		return "EVENT"
	match GameManager.run_data.current_node_type:
		MapData.NodeType.EVENT: return "EVENT"
		MapData.NodeType.SHOP:  return "SHOP"
		_: return "EVENT"


## 특수 이벤트 풀에서 발동 가능한 이벤트를 랜덤 선택한다.
func _try_load_special_event(act: int, floor_num: int, node_type: String) -> Variant:
	var file := FileAccess.open("res://data/events/special_events.json", FileAccess.READ)
	if file == null:
		return null
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return null
	file.close()

	var events: Array = json.data.get("events", [])
	var triggered: Array = GameManager.run_data.triggered_special_events
	var candidates: Array = []

	for evt in events:
		if not evt.get("special", false):
			continue
		# 이미 발동됨
		if evt.get("once_per_run", true) and triggered.has(evt["id"]):
			continue
		# 막 조건
		var trigger_acts: Array = evt.get("trigger_acts", [])
		if not trigger_acts.is_empty() and not trigger_acts.has(act):
			continue
		# 층 조건
		var min_floor: int = evt.get("trigger_min_floor", 0)
		var max_floor: int = evt.get("trigger_max_floor", -1)
		if floor_num < min_floor:
			continue
		if max_floor >= 0 and floor_num > max_floor:
			continue
		# 노드 타입 조건
		var node_types: Array = evt.get("trigger_node_types", [])
		if not node_types.is_empty() and not node_types.has(node_type):
			continue
		# 추가 조건
		if not _check_trigger_condition(evt.get("trigger_condition", "")):
			continue

		candidates.append(evt)

	if candidates.is_empty():
		return null

	# 랜덤 선택
	var selected: Dictionary = candidates[randi() % candidates.size()]
	# 발동 기록
	if selected.get("once_per_run", true):
		GameManager.run_data.triggered_special_events.append(selected["id"])

	return selected


## 트리거 조건을 체크한다.
func _check_trigger_condition(condition: String) -> bool:
	if condition == "":
		return true
	var rd := GameManager.run_data
	if not rd:
		return false
	match condition:
		"status_rank_ge_3":
			return rd.jibun_rank >= 3
		"status_rank_ge_4":
			return rd.jibun_rank >= 4
		"faction_climax":
			# 어느 한 당파 미터가 100에 도달했는지 체크
			for fid in rd.faction_pair:
				if FactionSystem.has_climax(rd, fid):
					return true
			return false
		"has_tag_amhaengosa_ally":
			var tags: Array = rd.narrative_state.get("run_tags", [])
			return tags.has("암행어사_동행")
		"minshim_le_20":
			return rd.narrative_state.get("minshim", 50) <= 20
		"minshim_ge_70":
			return rd.narrative_state.get("minshim", 50) >= 70
		"minshim_ge_50":
			return rd.narrative_state.get("minshim", 50) >= 50
		"sisang_ge_5":
			return SisangSystem.has_event_bonus(rd)
		"sisang_ge_10":
			return rd.sisang_count >= 10
		_:
			return true


## 로케일에 맞는 텍스트를 추출한다. Dictionary면 현재 로케일 키, String이면 그대로.
func _get_text(data) -> String:
	if data is Dictionary:
		var locale := TranslationServer.get_locale()
		if data.has(locale) and str(data[locale]) != "":
			return str(data[locale])
		# 폴백: ko → en → 첫 번째 값
		if data.has("ko"):
			return str(data["ko"])
		if data.has("en"):
			return str(data["en"])
		if not data.is_empty():
			return str(data.values()[0])
		return ""
	return str(data) if data != null else ""


## 설명 텍스트 추출. title 딕셔너리의 description 키 또는 별도 description 필드.
func _get_description() -> String:
	var title_data = _event_data.get("title", {})
	if title_data is Dictionary and title_data.has("description"):
		return _get_text(title_data["description"])
	return _get_text(_event_data.get("description", ""))


func _build_ui() -> void:
	title_label.text = _get_text(_event_data.get("title", tr("EVENT_DEFAULT_TITLE")))
	description_label.text = _get_description()

	# 분위기 텍스트
	var flavor: String = _get_text(_event_data.get("flavor_text", ""))
	flavor_label.text = flavor
	flavor_label.visible = flavor != ""

	# UI 상태 초기화 (이전 이벤트에서 숨겨진 상태 복원)
	choice_container.visible = true
	result_label.visible = false

	# 선택지 버튼 생성
	var choices: Array = _event_data.get("choices", [])
	if choices.is_empty():
		var btn := Button.new()
		btn.text = tr("EVENT_BACK")
		btn.pressed.connect(_return_to_map)
		choice_container.add_child(btn)
	else:
		for choice in choices:
			var btn := Button.new()
			btn.text = _get_text(choice.get("text", tr("EVENT_CHOICE_DEFAULT")))
			# 골드 부족 시 비활성화 (gold_loss 효과)
			if _is_gold_insufficient(choice):
				btn.disabled = true
				btn.tooltip_text = tr("TOOLTIP_GOLD_INSUFFICIENT")
			# 조건부 선택지 비활성화
			var cond: String = choice.get("trigger_condition", "")
			if cond != "" and not _check_trigger_condition(cond):
				btn.disabled = true
				btn.tooltip_text = _get_condition_tooltip(cond)
			btn.pressed.connect(_on_choice_selected.bind(choice))
			choice_container.add_child(btn)


## 조건 미충족 시 표시할 툴팁 텍스트.
func _get_condition_tooltip(condition: String) -> String:
	match condition:
		"status_rank_ge_3": return tr("EVENT_COND_RANK_GE_3")
		"status_rank_ge_4": return tr("EVENT_COND_RANK_GE_4")
		"minshim_ge_70": return tr("EVENT_COND_MINSHIM_GE_70")
		"minshim_ge_50": return tr("EVENT_COND_MINSHIM_GE_50")
		"sisang_ge_5": return tr("EVENT_COND_SISANG_GE_5")
		"sisang_ge_10": return tr("EVENT_COND_SISANG_GE_10")
		_: return tr("EVENT_COND_DEFAULT")


## 선택지의 골드 비용을 확인하여 부족하면 true 반환.
func _is_gold_insufficient(choice: Dictionary) -> bool:
	if not GameManager.run_data:
		return false
	var effect_type: String = str(choice.get("effect_type", ""))
	if effect_type == "gold_loss":
		var cost: int = int(choice.get("effect_value", 0))
		if GameManager.run_data.gold < cost:
			return true
	return false


func _on_choice_selected(choice: Dictionary) -> void:
	if not GameManager.run_data:
		_show_result(tr("EVENT_FALLBACK_NOTHING"))
		return

	var effect_type: String = str(choice.get("effect_type", "none"))

	# 강제 전투 효과는 즉시 전투 씬으로 전환
	if effect_type in ["forced_combat_with_reward", "forced_elite_immediate"]:
		_trigger_forced_combat(choice, effect_type)
		return

	# card_gain 효과는 카드 선택 UI를 별도로 표시
	if effect_type == "card_gain":
		_show_card_gain_selection(choice)
		return

	var result_text: String = ""

	# 메인 효과 적용
	result_text = _apply_effect(choice, effect_type)

	# 민심 30 미만: 20% 확률로 부정적 추가 효과 발생
	var minshim: int = GameManager.run_data.narrative_state.get("minshim", 50)
	if minshim < 30 and randf() < 0.2:
		var penalty_hp: int = randi_range(3, 8)
		GameManager.run_data.current_hp = maxi(GameManager.run_data.current_hp - penalty_hp, 1)
		result_text += "\n\n" + tr("MINSHIM_UNREST_FMT") % penalty_hp

	# 보너스 효과 적용
	var bonus_type: String = str(choice.get("effect_type_bonus", ""))
	if bonus_type != "":
		var bonus_text := _apply_bonus_effect(choice, bonus_type)
		if bonus_text != "":
			result_text += "\n" + bonus_text

	# 추가 효과 (effect_type_2, effect_type_3) 적용
	_apply_numbered_effects(choice)

	# 결과 텍스트가 비어있으면 JSON의 result_text 사용
	if result_text == "":
		result_text = _get_text(choice.get("result_text", tr("EVENT_FALLBACK_NOTHING")))

	_show_result(result_text)
	_update_status_bar()


## 번호가 붙은 추가 효과 (effect_type_2, effect_type_3 등)를 적용한다.
func _apply_numbered_effects(choice: Dictionary) -> void:
	for i in range(2, 6):
		var key := "effect_type_%d" % i
		var meta_key := "effect_meta_%d" % i
		var etype: String = str(choice.get(key, ""))
		if etype == "":
			break
		# 임시 choice 딕셔너리를 만들어 effect_meta를 전달
		var temp_choice := choice.duplicate()
		temp_choice["effect_meta"] = choice.get(meta_key, {})
		_apply_effect(temp_choice, etype)


## 메인 효과를 적용하고 결과 텍스트를 반환한다.
func _apply_effect(choice: Dictionary, effect_type: String) -> String:
	var value: int = int(choice.get("effect_value", 0))
	var rd := GameManager.run_data

	match effect_type:
		"hp_gain":
			rd.current_hp = mini(rd.current_hp + value, rd.max_hp)
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_HP_GAIN_FMT") % value))

		"hp_loss":
			rd.current_hp = maxi(rd.current_hp - value, 0)
			var text: String = _get_text(choice.get("result_text", tr("EVENT_FALLBACK_HP_LOSS_FMT") % value))
			if rd.current_hp <= 0:
				text += tr("EVENT_CONSCIOUSNESS")
			return text

		"hp_full_heal":
			rd.current_hp = rd.max_hp
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_HP_FULL")))

		"max_hp_gain":
			rd.max_hp += value
			rd.current_hp += value
			return _get_text(choice.get("result_text", tr("EVENT_RESULT_HP_UP") % value))

		"max_hp_loss":
			rd.max_hp = maxi(rd.max_hp - value, 1)
			rd.current_hp = mini(rd.current_hp, rd.max_hp)
			return _get_text(choice.get("result_text", tr("EVENT_RESULT_HP_DOWN") % value))

		"gold_gain":
			rd.gold += value
			return _get_text(choice.get("result_text", tr("EVENT_RESULT_GOLD_GAIN") % value))

		"gold_loss":
			rd.gold = maxi(rd.gold - value, 0)
			return _get_text(choice.get("result_text", tr("EVENT_RESULT_GOLD_LOSS") % value))

		"gold_random":
			return _apply_gold_random(choice)

		"relic_gain":
			var count: int = int(choice.get("effect_value", 1))
			for i in count:
				var relic_id := RelicManager.roll_relic_reward("event")
				if relic_id != "":
					RelicManager.acquire_relic(relic_id)
			return _get_text(choice.get("result_text", tr("EVENT_RESULT_RELIC")))

		"card_gain":
			return _get_text(choice.get("result_text", tr("EVENT_RESULT_CARD")))

		"debuff":
			var debuff_type: String = str(choice.get("debuff_type", "약화"))
			if not rd.has_meta("next_combat_debuffs"):
				rd.set_meta("next_combat_debuffs", [])
			var debuffs: Array = rd.get_meta("next_combat_debuffs")
			debuffs.append({"type": debuff_type, "stacks": value})
			rd.set_meta("next_combat_debuffs", debuffs)
			return _get_text(choice.get("result_text", tr("EVENT_RESULT_DEBUFF") % [debuff_type, value]))

		"buff_next_combat":
			var bonus_val = choice.get("effect_value_bonus", {})
			if bonus_val is Dictionary:
				if not rd.has_meta("next_combat_buffs"):
					rd.set_meta("next_combat_buffs", [])
				var buffs: Array = rd.get_meta("next_combat_buffs")
				buffs.append(bonus_val)
				rd.set_meta("next_combat_buffs", buffs)
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_DEBUFF")))

		"random":
			return _apply_random_outcome(choice)

		# === 신규 특수 이벤트 effect_type ===

		"faction_change":
			var effect_meta: Dictionary = choice.get("effect_meta", {})
			var faction: String = effect_meta.get("faction", "")
			var delta: int = effect_meta.get("delta", 0)
			# 기존 narrative_state 호환 유지
			if not rd.narrative_state.has("faction_scores"):
				rd.narrative_state["faction_scores"] = {"namin": 0, "noron": 0, "soron": 0, "soin": 0}
			var scores: Dictionary = rd.narrative_state["faction_scores"]
			if faction == "all":
				for key in scores:
					scores[key] = clampi(scores[key] + delta, -100, 100)
				# FactionSystem 연동: 런 당파 쌍 모두 변경
				for fid in rd.faction_pair:
					FactionSystem.change_meter(rd, fid, delta)
			elif scores.has(faction):
				scores[faction] = clampi(scores.get(faction, 0) + delta, -100, 100)
				# FactionSystem 연동
				FactionSystem.change_meter(rd, faction, delta)
			else:
				# 복합 키 (namin_soron 등)
				var parts := faction.split("_")
				for p in parts:
					if scores.has(p):
						scores[p] = clampi(scores.get(p, 0) + delta, -100, 100)
					FactionSystem.change_meter(rd, p, delta)
			rd.narrative_state["faction_scores"] = scores
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_FACTION")))

		"run_tag_add":
			var tag: String = choice.get("effect_meta", {}).get("tag", "")
			if tag != "":
				if not rd.narrative_state.has("run_tags"):
					rd.narrative_state["run_tags"] = []
				var tags: Array = rd.narrative_state["run_tags"]
				if not tags.has(tag):
					tags.append(tag)
				rd.narrative_state["run_tags"] = tags
			return _get_text(choice.get("result_text", ""))

		"narrative_flag_set":
			var key: String = choice.get("effect_meta", {}).get("key", "")
			var flag_value = choice.get("effect_meta", {}).get("value", false)
			if key != "":
				rd.narrative_state[key] = flag_value
			return _get_text(choice.get("result_text", ""))

		"shop_price_discount":
			var meta: Dictionary = choice.get("effect_meta", {})
			_add_pending_effect({
				"type": "shop_price_modifier",
				"percent": meta.get("percent", -30),
				"duration_shops": meta.get("duration_shops", 1)
			})
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_SHOP_DISCOUNT")))

		"shop_price_penalty":
			var meta: Dictionary = choice.get("effect_meta", {})
			_add_pending_effect({
				"type": "shop_price_modifier",
				"percent": meta.get("percent", 50),
				"duration_shops": meta.get("duration_shops", 1)
			})
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_SHOP_PENALTY")))

		"next_boss_hp_modifier":
			var meta: Dictionary = choice.get("effect_meta", {})
			_add_pending_effect({
				"type": "boss_hp_modifier",
				"percent": meta.get("percent", -20)
			})
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_BOSS_WEAKEN")))

		"gold_invest_deferred":
			var meta: Dictionary = choice.get("effect_meta", {})
			if meta.is_empty():
				meta = choice.get("effect_meta_bonus", {})
			_add_pending_effect({
				"type": "gold_gain_after_shops",
				"gold": meta.get("return_gold", 150),
				"shops_remaining": meta.get("after_shops", 3)
			})
			var tag: String = meta.get("tag_cost", "")
			if tag != "":
				if not rd.narrative_state.has("run_tags"):
					rd.narrative_state["run_tags"] = []
				rd.narrative_state["run_tags"].append(tag)
			return ""

		"status_rank_change":
			var meta: Dictionary = choice.get("effect_meta", {})
			var delta: int = meta.get("delta", 0)
			# JibunSystem과 연동 — 점수 기반 신분 변경
			var score_delta: int = delta * 100  # 단계 변화를 점수로 환산
			JibunSystem.add_score(rd, score_delta)
			# 하위호환: narrative_state도 동기화
			rd.narrative_state["status_rank"] = rd.jibun_rank
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_STATUS")))

		"card_remove_random":
			var meta: Dictionary = choice.get("effect_meta", {})
			var count: int = meta.get("count", 1)
			var starter_deck: Array = DataLoader.get_starter_deck(rd.character_id)
			# 덱에서 스타터 카드만 필터
			var removable: Array[String] = []
			for card_id in rd.deck:
				if starter_deck.has(card_id) and not removable.has(card_id):
					removable.append(card_id)
			removable.shuffle()
			for i in mini(count, removable.size()):
				var idx := rd.deck.find(removable[i])
				if idx >= 0:
					rd.deck.remove_at(idx)
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_CARD_VANISH")))

		"relic_gain_specific":
			var meta: Dictionary = choice.get("effect_meta", {})
			var relic_id: String = meta.get("relic_id", "")
			if relic_id != "" and not rd.relics.has(relic_id):
				rd.relics.append(relic_id)
				RelicManager.acquire_relic(relic_id)
			return _get_text(choice.get("result_text", tr("EVENT_RESULT_RELIC")))

		"minshim_change":
			var delta: int = int(choice.get("effect_value", 0))
			if delta == 0:
				var meta: Dictionary = choice.get("effect_meta", {})
				delta = meta.get("delta", 0)
			var current: int = rd.narrative_state.get("minshim", 50)
			rd.narrative_state["minshim"] = clampi(current + delta, 0, 100)
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_MINSHIM")))

		"card_choice":
			# 카드 선택 이벤트 — 풀에서 랜덤 카드 1장 덱에 추가
			var meta: Dictionary = choice.get("effect_meta", {})
			var card_class: String = meta.get("class", "")
			if card_class.is_empty():
				card_class = rd.character_id
			var pool_cards := DataLoader.get_cards_by_pool(card_class)
			if not pool_cards.is_empty():
				pool_cards.shuffle()
				rd.deck.append(pool_cards[0].id)
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_CARD_GAIN")))

		"card_remove_free":
			# 무료 카드 제거 — 랜덤 비스타터 카드 제거
			var starter_deck: Array = DataLoader.get_starter_deck(rd.character_id)
			var removable: Array[String] = []
			for card_id in rd.deck:
				if not starter_deck.has(card_id):
					removable.append(card_id)
			if removable.is_empty():
				# 스타터가 아닌 카드가 없으면 아무 카드나
				removable = rd.deck.duplicate()
			if not removable.is_empty() and rd.deck.size() > 1:
				removable.shuffle()
				var idx := rd.deck.find(removable[0])
				if idx >= 0:
					rd.deck.remove_at(idx)
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_CARD_REMOVE")))

		"card_upgrade_free":
			# 무료 카드 강화 — 강화 가능한 카드 중 첫 번째 강화
			for i in rd.deck.size():
				var cid: String = rd.deck[i]
				if not cid.ends_with("+"):
					rd.deck[i] = cid + "+"
					break
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_CARD_UPGRADE")))

		"next_battle_block":
			# 다음 전투 시작 시 방어도 추가
			_add_pending_effect({
				"type": "next_battle_block",
				"block": value
			})
			return _get_text(choice.get("result_text", tr("EVENT_RESULT_BLOCK") % value))

		"reveal_map":
			# 맵 공개 — 다음 2층의 노드 공개
			_add_pending_effect({
				"type": "reveal_map",
				"floors": value if value > 0 else 2
			})
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_MAP_REVEAL")))

		"none", "":
			return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_NOTHING")))

	return _get_text(choice.get("result_text", ""))


## pending_effects 배열에 대기 효과를 추가한다.
func _add_pending_effect(effect: Dictionary) -> void:
	if not GameManager.run_data:
		return
	if not GameManager.run_data.narrative_state.has("pending_effects"):
		GameManager.run_data.narrative_state["pending_effects"] = []
	GameManager.run_data.narrative_state["pending_effects"].append(effect)


## 강제 전투를 트리거한다.
func _trigger_forced_combat(choice: Dictionary, _effect_type: String) -> void:
	var meta: Dictionary = choice.get("effect_meta", {})
	var encounter_id: String = meta.get("encounter_id", "")
	if encounter_id == "" or not GameManager.run_data:
		_show_result(tr("EVENT_FALLBACK_NOTHING"))
		return
	# 승리 시 보상을 pending_effects에 저장
	var victory_reward: Dictionary = meta.get("victory_reward", {})
	if not victory_reward.is_empty():
		_add_pending_effect({
			"type": "post_battle_reward",
			"trigger": "on_battle_victory",
			"encounter_id": encounter_id,
			"reward": victory_reward
		})
	# 보너스/추가 효과도 먼저 적용
	var bonus_type: String = str(choice.get("effect_type_bonus", ""))
	if bonus_type != "":
		_apply_bonus_effect(choice, bonus_type)
	_apply_numbered_effects(choice)
	# 전투 씬으로 전환
	GameManager.run_data.current_encounter_id = encounter_id
	GameManager.save_current_run()
	GameManager.change_state(GameManager.GameState.BATTLE)


## 도박형 골드 랜덤 효과를 적용한다.
func _apply_gold_random(choice: Dictionary) -> String:
	var win_chance: float = float(choice.get("win_chance", 0.5))
	var rd := GameManager.run_data

	if randf() < win_chance:
		var win_value: int = int(choice.get("effect_value_win", 0))
		rd.gold += win_value
		return str(choice.get("result_text_win", tr("EVENT_RESULT_GAMBLE_WIN") % win_value))
	else:
		var lose_value: int = abs(int(choice.get("effect_value_lose", 0)))
		rd.gold = maxi(rd.gold - lose_value, 0)
		return str(choice.get("result_text_lose", tr("EVENT_RESULT_GAMBLE_LOSE") % lose_value))


## 가중치 기반 랜덤 결과를 적용한다.
func _apply_random_outcome(choice: Dictionary) -> String:
	var outcomes: Array = choice.get("outcomes", [])
	if outcomes.is_empty():
		return _get_text(choice.get("result_text", tr("EVENT_FALLBACK_NOTHING")))

	var total_weight := 0
	for outcome in outcomes:
		total_weight += int(outcome.get("weight", 1))

	var roll := randi() % total_weight
	var cumulative := 0
	var selected: Dictionary = outcomes[0]
	for outcome in outcomes:
		cumulative += int(outcome.get("weight", 1))
		if roll < cumulative:
			selected = outcome
			break

	var sub_type: String = str(selected.get("effect_type", "none"))
	var sub_value: int = int(selected.get("effect_value", 0))
	var rd := GameManager.run_data

	match sub_type:
		"gold_gain":
			rd.gold += sub_value
		"gold_loss":
			rd.gold = maxi(rd.gold - sub_value, 0)
		"hp_gain":
			rd.current_hp = mini(rd.current_hp + sub_value, rd.max_hp)
		"hp_loss":
			rd.current_hp = maxi(rd.current_hp - sub_value, 0)
		"card_gain":
			var rand_offers := _generate_card_offers(1)
			if not rand_offers.is_empty():
				rd.deck.append(rand_offers[0])
				AudioManager.play_sfx_by_key("card_draw")
		"relic_gain":
			var relic_id := RelicManager.roll_relic_reward("event")
			if relic_id != "":
				RelicManager.acquire_relic(relic_id)

	return str(selected.get("text", tr("EVENT_FALLBACK_RESULT")))


## 보너스 효과를 적용하고 결과 텍스트를 반환한다.
func _apply_bonus_effect(choice: Dictionary, bonus_type: String) -> String:
	var bonus_value = choice.get("effect_value_bonus", 0)
	var rd := GameManager.run_data

	match bonus_type:
		"hp_gain":
			var val: int = int(bonus_value)
			rd.current_hp = mini(rd.current_hp + val, rd.max_hp)
			return ""

		"hp_full_heal":
			rd.current_hp = rd.max_hp
			return ""

		"max_hp_gain":
			var val: int = int(bonus_value)
			rd.max_hp += val
			rd.current_hp += val
			return ""

		"max_hp_loss":
			var val: int = int(bonus_value)
			rd.max_hp = maxi(rd.max_hp - val, 1)
			rd.current_hp = mini(rd.current_hp, rd.max_hp)
			return ""

		"gold_gain":
			var val: int = int(bonus_value)
			rd.gold += val
			return ""

		"relic_gain":
			var count: int = int(bonus_value) if bonus_value is int or bonus_value is float else 1
			for i in count:
				var relic_id := RelicManager.roll_relic_reward("event")
				if relic_id != "":
					RelicManager.acquire_relic(relic_id)
			return ""

		"buff_next_combat":
			if bonus_value is Dictionary:
				if not rd.has_meta("next_combat_buffs"):
					rd.set_meta("next_combat_buffs", [])
				var buffs: Array = rd.get_meta("next_combat_buffs")
				buffs.append(bonus_value)
				rd.set_meta("next_combat_buffs", buffs)
			return ""

		"next_battle_block":
			var val: int = int(bonus_value)
			_add_pending_effect({"type": "next_battle_block", "block": val})
			return ""

		"card_choice_class":
			# 보너스 효과: 클래스별 카드 선택
			var card_class: String = str(bonus_value) if bonus_value is String else rd.character_id
			var pool_cards := DataLoader.get_cards_by_pool(card_class)
			if not pool_cards.is_empty():
				pool_cards.shuffle()
				rd.deck.append(pool_cards[0].id)
			return ""

		# 보너스 슬롯에서도 신규 효과 지원
		"faction_change", "run_tag_add", "narrative_flag_set", \
		"shop_price_discount", "shop_price_penalty", "gold_invest_deferred", \
		"status_rank_change", "relic_gain_specific", "minshim_change":
			# 보너스 meta는 effect_meta_bonus에 저장됨
			var temp_choice := choice.duplicate()
			temp_choice["effect_meta"] = choice.get("effect_meta_bonus", {})
			_apply_effect(temp_choice, bonus_type)
			return ""

	return ""


## 결과 텍스트를 표시하고 선택지를 숨긴다.
func _show_result(text: String) -> void:
	for child in choice_container.get_children():
		child.queue_free()
	choice_container.visible = false

	result_label.text = text
	result_label.visible = true
	continue_button.visible = true
	continue_button.grab_focus()


## 상태 바를 업데이트한다.
func _update_status_bar() -> void:
	if GameManager.run_data:
		hp_label.text = "HP: %d/%d" % [GameManager.run_data.current_hp, GameManager.run_data.max_hp]
		gold_label.text = tr("EVENT_GOLD_FMT") % GameManager.run_data.gold
	else:
		hp_label.text = "HP: --/--"
		gold_label.text = tr("EVENT_GOLD_FMT").replace("%d", "--")


## 카드 획득 이벤트: 3장 중 1장 선택 UI를 표시한다.
func _show_card_gain_selection(choice: Dictionary) -> void:
	for child in choice_container.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = tr("EVENT_CARD_SELECT_HEADER")
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(0.83, 0.63, 0.09))
	choice_container.add_child(header)

	var offers := _generate_card_offers(3)
	var base_result: String = _get_text(choice.get("result_text", tr("EVENT_FALLBACK_CARD_ADD")))

	if offers.is_empty():
		_show_result(base_result)
		return

	for card_id in offers:
		var card: CardData = DataLoader.get_card(card_id)
		if card == null:
			continue
		var btn := Button.new()
		btn.text = _format_card_choice_text(card)
		btn.custom_minimum_size = Vector2(240, 110)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var cid := card_id
		var cname := card.get_display_name()
		btn.pressed.connect(func():
			GameManager.run_data.deck.append(cid)
			AudioManager.play_sfx_by_key("card_draw")
			_show_result("%s\n[%s]를 덱에 추가했습니다." % [base_result, cname])
		)
		choice_container.add_child(btn)


## 카드 풀에서 count장의 랜덤 카드 ID 목록을 반환한다.
func _generate_card_offers(count: int) -> Array[String]:
	if not GameManager.run_data:
		return []
	var character_id: String = GameManager.run_data.character_id
	var pool: Array[CardData] = []
	pool.append_array(DataLoader.get_cards_by_pool(character_id))
	pool.append_array(DataLoader.get_cards_by_pool("common"))
	pool.shuffle()
	var result: Array[String] = []
	for i in mini(count, pool.size()):
		result.append(pool[i].id)
	return result


## 카드 선택 버튼에 표시할 텍스트를 포맷한다.
func _format_card_choice_text(card: CardData) -> String:
	var lines: Array[String] = []
	lines.append(card.get_display_name())
	lines.append(tr("EVENT_CARD_STAT_FMT") % [card.cost, card.beat])
	if card.damage > 0:
		lines.append(tr("EVENT_CARD_DAMAGE_FMT") % [card.damage, " " + tr("SHOP_CARD_DAMAGE_AOE") if card.is_aoe else ""])
	if card.block_value > 0:
		lines.append(tr("EVENT_CARD_BLOCK_FMT") % card.block_value)
	var eff := card.get_current_effect()
	if eff != "":
		lines.append(eff)
	return "\n".join(lines)


func _return_to_map() -> void:
	GameManager.save_current_run()
	if GameManager.run_data and GameManager.run_data.current_hp <= 0:
		GameManager.end_run(false)
	else:
		GameManager.change_state(GameManager.GameState.MAP)
