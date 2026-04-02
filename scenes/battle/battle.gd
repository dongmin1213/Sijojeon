extends Control

## 전투 씬 메인 스크립트. UI와 BattleManager를 연결한다.

@onready var hp_label: Label = $BattleHUD/PlayerInfo/HPLabel
@onready var qi_label: Label = $BattleHUD/PlayerInfo/QiLabel
@onready var block_label: Label = $BattleHUD/PlayerInfo/BlockLabel
@onready var turn_label: Label = $BattleHUD/TurnLabel
@onready var card_hand: CardHand = $HandArea/CardHand
@onready var enemy_container: HBoxContainer = $EnemyArea/EnemyContainer
@onready var sijo_container: HBoxContainer = $SijoArea/SijoContainer
@onready var end_turn_button: Button = $BattleHUD/EndTurnButton
@onready var draw_pile_label: Label = $BattleHUD/DeckInfo/DrawPileLabel
@onready var discard_pile_label: Label = $BattleHUD/DeckInfo/DiscardPileLabel

var battle_manager: BattleManager
var sijo_system: SijoSystem

# 시조 슬롯 UI 라벨
var sijo_slot_labels: Array[Label] = []
var _sijo_collapsed: bool = false  # 시조 슬롯 축약 상태
var _sijo_toggle_button: Button = null
var _sijo_summary_label: Label = null  # 축약 모드에서 진행률 표시

# 플레이어 상태이상 UI 컨테이너
var _player_status_container: HBoxContainer = null

# 클래스 고유 자원 UI (무관: 기력, 문관: 학식)
var _class_resource_label: Label = null

# 액티브 스킬 버튼
var _active_skill_button: Button = null

# 적 UI 캐시 (index → {panel, name_label, hp_label, block_label, intent_label, status_hbox})
var _enemy_ui_cache: Dictionary = {}


func _ready() -> void:
	# 매니저 초기화
	battle_manager = BattleManager.new()
	sijo_system = SijoSystem.new()
	battle_manager.sijo_system = sijo_system
	add_child(battle_manager)
	add_child(sijo_system)

	# 시그널 연결
	battle_manager.hand_changed.connect(_on_hand_changed)
	battle_manager.qi_changed.connect(_on_qi_changed)
	battle_manager.hp_changed.connect(_on_hp_changed)
	battle_manager.block_changed.connect(_on_block_changed)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.enemy_hp_changed.connect(_on_enemy_hp_changed)
	battle_manager.enemy_intent_shown.connect(_on_enemy_intent_shown)
	battle_manager.battle_ended.connect(_on_battle_ended)
	sijo_system.slot_filled.connect(_on_sijo_slot_filled)
	sijo_system.sijo_completed.connect(_on_sijo_completed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# CardHand 시그널 연결
	card_hand.card_played.connect(_on_card_played)
	card_hand.card_zoom_requested.connect(_on_card_zoom_requested)

	# 상태이상 시그널 연결
	battle_manager.status_effect_changed.connect(_on_status_effect_changed)

	# 클래스 고유 자원 시그널 연결
	battle_manager.class_resource_changed.connect(_on_class_resource_changed)

	# 패시브/액티브 스킬 시그널 연결
	battle_manager.passive_triggered.connect(_on_passive_triggered)

	# 시조 슬롯 UI 초기화 (토글 버튼 포함)
	_init_sijo_toggle()
	_init_sijo_slots()

	# 유물 바 UI 추가
	_init_relic_bar()

	# 유물 트리거 시그널 연결
	RelicManager.relic_triggered.connect(_on_relic_triggered)

	# 전투 시작
	_start_battle()


func _start_battle() -> void:
	if GameManager.run_data == null:
		return

	var rd := GameManager.run_data
	var deck := rd.deck.duplicate()

	# 맵 노드에서 전달된 encounter_id 사용, 없으면 랜덤 적 선택
	var enemy_data: Array[Dictionary] = []
	var encounter_id: String = ""
	if rd.current_encounter_id != "":
		encounter_id = rd.current_encounter_id

	if encounter_id != "":
		var enemy := DataLoader.get_enemy(encounter_id)
		if not enemy.is_empty():
			enemy_data.append(enemy)

	# encounter_id가 비어있거나 로드 실패 시 랜덤 적 선택
	if enemy_data.is_empty():
		var fallback := DataLoader.get_enemy("E001")
		if not fallback.is_empty():
			enemy_data.append(fallback)

	# 보스 전투 진입 시 유물 트리거 (만파식적 등)
	var is_boss := false
	is_boss = (rd.current_node_type == MapData.NodeType.BOSS)
	if is_boss:
		RelicManager.trigger_boss_enter()

	battle_manager.start_battle(deck, enemy_data, rd.current_hp, rd.max_hp, rd.qi_per_turn, rd.character_id)

	# 전투 시작 유물 트리거 (편자, 호신검, 어사마패 등)
	RelicManager.trigger_battle_start(battle_manager)

	# 클래스 고유 자원 UI 초기화 (무관: 기력, 문관: 학식)
	if battle_manager.has_class_resource:
		_init_class_resource_ui()

	# 액티브 스킬 버튼 초기화 (도사 제외 — 방술 개방은 자동 발동)
	if battle_manager.character_id != "dosa":
		_init_active_skill_button()


func _init_sijo_toggle() -> void:
	## 시조 슬롯 토글 버튼 + 요약 라벨 초기화
	var sijo_area := $SijoArea
	_sijo_toggle_button = Button.new()
	_sijo_toggle_button.text = "▼"
	_sijo_toggle_button.custom_minimum_size = Vector2(40, 40)
	_sijo_toggle_button.add_theme_font_size_override("font_size", 16)
	_sijo_toggle_button.pressed.connect(_on_sijo_toggle_pressed)
	sijo_area.add_child(_sijo_toggle_button)
	sijo_area.move_child(_sijo_toggle_button, 0)

	_sijo_summary_label = Label.new()
	_sijo_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sijo_summary_label.add_theme_font_size_override("font_size", 14)
	_sijo_summary_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_sijo_summary_label.visible = false
	sijo_area.add_child(_sijo_summary_label)


func _on_sijo_toggle_pressed() -> void:
	_sijo_collapsed = not _sijo_collapsed
	sijo_container.visible = not _sijo_collapsed
	_sijo_summary_label.visible = _sijo_collapsed
	_sijo_toggle_button.text = "▶" if _sijo_collapsed else "▼"
	if _sijo_collapsed:
		_update_sijo_summary()


func _update_sijo_summary() -> void:
	## 축약 모드에서 시조 진행률을 한 줄로 표시
	if not _sijo_summary_label:
		return
	var filled := sijo_system.current_slot_index if sijo_system else 0
	var total := SijoSystem.PATTERN.size()
	_sijo_summary_label.text = "시조 %d/%d" % [filled, total]


func _init_sijo_slots() -> void:
	sijo_slot_labels.clear()
	for child in sijo_container.get_children():
		child.queue_free()

	for i in SijoSystem.PATTERN.size():
		var label := Label.new()
		label.text = "[%d]" % SijoSystem.PATTERN[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(120, 60)
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		sijo_container.add_child(label)
		sijo_slot_labels.append(label)

	if _sijo_collapsed:
		_update_sijo_summary()


func _refresh_hand_ui() -> void:
	var sijo_beat := sijo_system.get_next_required_beat() if sijo_system else -1
	card_hand.update_hand(battle_manager.hand, battle_manager.current_qi, sijo_beat, battle_manager)

	# 덱 정보 갱신
	draw_pile_label.text = "드로우: %d" % battle_manager.draw_pile.size()
	discard_pile_label.text = "버림: %d" % battle_manager.discard_pile.size()


func _update_enemy_ui() -> void:
	## 적 UI를 캐시 기반으로 업데이트. 노드를 매번 재생성하지 않는다.
	var alive_indices: Array[int] = []
	for i in battle_manager.enemies.size():
		var enemy: Dictionary = battle_manager.enemies[i]
		if enemy["current_hp"] <= 0:
			# 죽은 적 패널 숨기기
			if _enemy_ui_cache.has(i):
				_enemy_ui_cache[i]["panel"].visible = false
			continue
		alive_indices.append(i)

		if _enemy_ui_cache.has(i):
			# 기존 캐시 업데이트
			var cache: Dictionary = _enemy_ui_cache[i]
			cache["panel"].visible = true
			cache["hp_label"].text = "HP: %d/%d" % [enemy["current_hp"], enemy["max_hp"]]
			var block_val: int = enemy.get("block", 0)
			cache["block_label"].text = "방어: %d" % block_val
			cache["block_label"].visible = block_val > 0
			var intent := battle_manager._get_enemy_intent(i)
			cache["intent_label"].text = _format_intent(intent)
			_build_status_icons(cache["status_hbox"], "enemy_%d" % i)
		else:
			# 새 적 패널 생성
			var name_data = enemy.get("name", {})
			var enemy_name: String = ""
			if name_data is Dictionary:
				enemy_name = name_data.get("ko", "적")
			elif name_data is String:
				enemy_name = name_data

			var panel := PanelContainer.new()
			var vbox := VBoxContainer.new()
			var name_label := Label.new()
			name_label.text = enemy_name
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var hp_lbl := Label.new()
			hp_lbl.text = "HP: %d/%d" % [enemy["current_hp"], enemy["max_hp"]]
			hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

			var intent_label := Label.new()
			intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			intent_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
			var intent := battle_manager._get_enemy_intent(i)
			intent_label.text = _format_intent(intent)

			var block_val: int = enemy.get("block", 0)
			var enemy_block_label := Label.new()
			enemy_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			enemy_block_label.text = "방어: %d" % block_val
			enemy_block_label.visible = block_val > 0

			var status_hbox := HBoxContainer.new()
			status_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			_build_status_icons(status_hbox, "enemy_%d" % i)

			vbox.add_child(name_label)
			vbox.add_child(hp_lbl)
			vbox.add_child(enemy_block_label)
			vbox.add_child(status_hbox)
			vbox.add_child(intent_label)
			panel.add_child(vbox)
			panel.custom_minimum_size = Vector2(200, 180)
			enemy_container.add_child(panel)

			_enemy_ui_cache[i] = {
				"panel": panel,
				"name_label": name_label,
				"hp_label": hp_lbl,
				"block_label": enemy_block_label,
				"intent_label": intent_label,
				"status_hbox": status_hbox,
			}


func _format_intent(intent: Dictionary) -> String:
	var intent_type: String = intent.get("intent", intent.get("type", ""))
	var name_str: String = intent.get("name", "")
	match intent_type:
		"attack", "attack_debuff":
			var dmg: int = intent.get("damage", 0)
			var times: int = intent.get("times", 1)
			if times > 1:
				return "%s %d×%d" % [name_str, dmg, times] if name_str else "공격 %d×%d" % [dmg, times]
			return "%s %d" % [name_str, dmg] if name_str else "공격 %d" % dmg
		"defend", "defend_buff", "buff_defend":
			var blk: int = intent.get("block", 0)
			return "%s %d" % [name_str, blk] if name_str else "방어 %d" % blk
		"buff":
			return name_str if name_str else "강화"
		"debuff":
			return name_str if name_str else "디버프"
		_:
			return name_str if name_str else "???"


# --- 시그널 핸들러 ---

func _on_hand_changed(_new_hand: Array[String]) -> void:
	_refresh_hand_ui()


func _on_qi_changed(current: int, max_val: int) -> void:
	qi_label.text = "氣: %d/%d" % [current, max_val]
	_refresh_hand_ui()


func _on_hp_changed(current: int, max_val: int) -> void:
	hp_label.text = "HP: %d/%d" % [current, max_val]


func _on_block_changed(new_block: int) -> void:
	block_label.text = "방어: %d" % new_block
	block_label.visible = new_block > 0


func _on_turn_started(turn: int) -> void:
	turn_label.text = "%d턴" % turn
	# 매 턴 시작 유물 트리거 (삼족오 깃털 등)
	RelicManager.trigger_turn_start(battle_manager)


func _on_enemy_hp_changed(_enemy_index: int, _current: int, _max_val: int) -> void:
	_update_enemy_ui()


func _on_enemy_intent_shown(_enemy_index: int, _intent: Dictionary) -> void:
	_update_enemy_ui()


func _on_card_played(hand_index: int, target_enemy_index: int) -> void:
	battle_manager.try_play_card(hand_index, target_enemy_index)


func _on_card_zoom_requested(card_data: CardData) -> void:
	## 카드 상세보기 팝업 표시
	var popup := CardZoomPopup.new()
	add_child(popup)
	popup.show_card(card_data)


func _on_end_turn_pressed() -> void:
	AudioManager.play_sfx_by_key("end_turn")
	battle_manager.end_player_turn()


func _on_sijo_slot_filled(index: int, card_id: String, _jang_name: String) -> void:
	AudioManager.play_sfx_by_key("sijo_slot")
	if index < sijo_slot_labels.size():
		var card: CardData = DataLoader.get_card(card_id)
		if card:
			sijo_slot_labels[index].text = card.name_ko
		else:
			sijo_slot_labels[index].text = card_id
		sijo_slot_labels[index].add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	if _sijo_collapsed:
		_update_sijo_summary()


func _on_sijo_completed(final_card_id: String) -> void:
	AudioManager.play_sfx_by_key("sijo_complete")
	# 시조 완성 보상: 마지막 카드 효과 2배 + 기 1 회복 + 카드 1장 드로우
	var card: CardData = battle_manager._get_battle_card(final_card_id)
	if card:
		# 마지막 카드 효과를 한 번 더 적용 (정상 플레이 + 보너스 = 2배)
		var target_index := 0
		for i in battle_manager.enemies.size():
			if battle_manager.enemies[i]["current_hp"] > 0:
				target_index = i
				break
		battle_manager._resolve_card_effect(card, target_index)
	battle_manager.current_qi += 1
	battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
	battle_manager.draw_cards(1)
	sijo_system.reset()
	_init_sijo_slots()


func _on_class_resource_changed(current: int, max_val: int) -> void:
	if _class_resource_label:
		var name := battle_manager.get_class_resource_name()
		_class_resource_label.text = "%s: %d/%d" % [name, current, max_val]
	_refresh_hand_ui()


func _init_relic_bar() -> void:
	var relic_bar := RelicBar.new()
	relic_bar.name = "RelicBar"
	$BattleHUD.add_child(relic_bar)


func _on_relic_triggered(relic_id: String, description: String) -> void:
	# 유물 발동 시 간단한 플래시 텍스트 표시
	var relic_name := RelicManager.get_relic_display_name(relic_id)
	var popup := Label.new()
	popup.text = "%s: %s" % [relic_name, description]
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.anchors_preset = Control.PRESET_CENTER_TOP
	popup.position.y = 60
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", RelicManager.get_relic_rarity_color(relic_id))
	add_child(popup)
	# 1.5초 후 자동 제거
	var tween := create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(popup.queue_free)


func _init_class_resource_ui() -> void:
	_class_resource_label = Label.new()
	var res_name := battle_manager.get_class_resource_name()
	_class_resource_label.text = "%s: 0/%d" % [res_name, battle_manager.max_class_resource]
	_class_resource_label.add_theme_color_override("font_color", battle_manager.get_class_resource_color())
	$BattleHUD/PlayerInfo.add_child(_class_resource_label)


func _init_active_skill_button() -> void:
	_active_skill_button = Button.new()
	var skill_name := battle_manager.get_active_skill_name()
	_active_skill_button.text = skill_name
	_active_skill_button.pressed.connect(_on_active_skill_pressed)
	_active_skill_button.custom_minimum_size = Vector2(120, 40)
	$BattleHUD.add_child(_active_skill_button)


func _on_active_skill_pressed() -> void:
	if battle_manager.use_active_skill():
		_active_skill_button.disabled = true
		_active_skill_button.text = "%s (사용됨)" % battle_manager.get_active_skill_name()


func _on_passive_triggered(skill_name: String, description: String) -> void:
	# 패시브 발동 시 플래시 텍스트 표시
	var popup := Label.new()
	popup.text = "[패시브] %s: %s" % [skill_name, description]
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.anchors_preset = Control.PRESET_CENTER_TOP
	popup.position.y = 90
	popup.add_theme_font_size_override("font_size", 14)
	popup.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	add_child(popup)
	var tween := create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(popup.queue_free)


func _on_status_effect_changed(_target: String, _effect_id: String, _stacks: int) -> void:
	_update_player_status_ui()
	_update_enemy_ui()


func _update_player_status_ui() -> void:
	block_label.text = "방어: %d" % battle_manager.player_block
	block_label.visible = battle_manager.player_block > 0

	# 플레이어 상태이상 표시 (전용 컨테이너)
	if not is_instance_valid(_player_status_container):
		_player_status_container = HBoxContainer.new()
		_player_status_container.alignment = BoxContainer.ALIGNMENT_CENTER
		$BattleHUD/PlayerInfo.add_child(_player_status_container)
	_build_status_icons(_player_status_container, "player")


func _build_status_icons(container: HBoxContainer, target: String) -> void:
	## 상태이상 아이콘 + 턴 카운터를 HBoxContainer에 배치
	for child in container.get_children():
		child.queue_free()

	if battle_manager.status_effects == null:
		return
	var effects := battle_manager.status_effects.get_all_effects(target)
	if effects.is_empty():
		return

	for effect_id in effects:
		var stacks: int = effects[effect_id]
		var def := StatusEffectData.get_definition(effect_id)

		var icon_panel := PanelContainer.new()
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = Color(0.15, 0.15, 0.15, 0.9)
		stylebox.border_color = def.color if def else Color.GRAY
		stylebox.set_border_width_all(1)
		stylebox.set_corner_radius_all(4)
		stylebox.set_content_margin_all(4)
		icon_panel.add_theme_stylebox_override("panel", stylebox)

		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)

		if def:
			label.add_theme_color_override("font_color", def.color)
			if def.is_permanent:
				label.text = "%s%d" % [def.icon_text, stacks]
			elif def.show_duration:
				label.text = "%s%d" % [def.icon_text, stacks]
			else:
				label.text = def.icon_text
			label.tooltip_text = "%s: %s" % [def.name_ko, def.description]
		else:
			label.text = "%s×%d" % [effect_id, stacks]
			label.add_theme_color_override("font_color", Color.GRAY)

		icon_panel.add_child(label)
		container.add_child(icon_panel)


func _format_status_effects(target: String) -> String:
	if battle_manager.status_effects == null:
		return ""
	var effects := battle_manager.status_effects.get_all_effects(target)
	if effects.is_empty():
		return ""

	var parts: Array[String] = []
	for effect_id in effects:
		var stacks: int = effects[effect_id]
		var def := StatusEffectData.get_definition(effect_id)
		if def:
			if def.is_permanent:
				parts.append("%s%s %d" % [def.icon_text, def.name_ko, stacks])
			elif def.show_duration:
				parts.append("%s%s (%d)" % [def.icon_text, def.name_ko, stacks])
			else:
				parts.append("%s%s" % [def.icon_text, def.name_ko])
		else:
			parts.append("%s×%d" % [effect_id, stacks])

	return " ".join(parts)


func _on_battle_ended(victory: bool) -> void:
	end_turn_button.disabled = true
	card_hand.visible = false

	# HP 동기화
	if GameManager.run_data:
		GameManager.run_data.current_hp = battle_manager.player_hp

	# 전투 결과 오버레이 표시
	_show_battle_result(victory)

	# 1.5초 후 씬 전환
	var timer := get_tree().create_timer(1.5)
	await timer.timeout
	if victory:
		# 유물 트리거: 전투 승리
		RelicManager.trigger_combat_victory()
		# 정예 전투 승리 유물 트리거
		if GameManager.run_data and GameManager.run_data.current_node_type == MapData.NodeType.ELITE:
			RelicManager.trigger_elite_victory()

		# 적 보상 데이터 수집 → 보상 씬으로 전달
		var rewards := _collect_enemy_rewards()
		if GameManager.run_data:
			GameManager.run_data.set_meta("battle_rewards", rewards)
		GameManager.change_state(GameManager.GameState.REWARD)
	else:
		GameManager.end_run(false)


func _show_battle_result(victory: bool) -> void:
	var overlay := ColorRect.new()
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.color = Color(0, 0, 0, 0.6)
	add_child(overlay)

	var label := Label.new()
	label.text = "승리!" if victory else "패배..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if victory else Color(1, 0.3, 0.3))
	overlay.add_child(label)


func _collect_enemy_rewards() -> Dictionary:
	var total_gold := 0
	var card_chance := 0.0
	var relic_chance := 0.0
	for enemy in battle_manager.enemies:
		var rewards = enemy.get("rewards", {})
		if rewards is Dictionary:
			var gold_data = rewards.get("gold", {})
			if gold_data is Dictionary:
				total_gold += randi_range(gold_data.get("min", 10), gold_data.get("max", 20))
			elif gold_data is int:
				total_gold += gold_data
			card_chance = maxf(card_chance, rewards.get("card_chance", 0.0))
			relic_chance = maxf(relic_chance, rewards.get("relic_chance", 0.0))
	return {
		"gold": total_gold,
		"card_chance": card_chance,
		"relic_chance": relic_chance,
	}
