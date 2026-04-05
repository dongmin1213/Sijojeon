extends Control

## 전투 씬 메인 스크립트. UI와 BattleManager를 연결한다.

var vfx: VfxManager = null
var _prev_player_hp: int = 0  # HP 변화 감지용
var _keyword_tooltip: KeywordTooltip = null  # 키워드 툴팁

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

# 상태이상 아이콘 캐시 (target → {effect_id → {panel, label}})
var _status_icon_cache: Dictionary = {}

# 적 UI 업데이트 배칭용 dirty flag
var _enemy_ui_dirty: bool = false

# 손패 UI 업데이트 배칭용 dirty flag (try_play_card 중 중복 rebuild 방지)
var _hand_ui_dirty: bool = false

# 시조 완성 가능 알림 라벨
var _sijo_alert_label: Label = null
var _sijo_alert_visible: bool = false


func _ready() -> void:
	# VFX 매니저 초기화
	vfx = VfxManager.new()
	add_child(vfx)
	vfx.setup(self)

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
	sijo_system.sijo_chapter_completed.connect(_on_sijo_chapter_completed)
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

	# 키워드 툴팁 초기화
	_keyword_tooltip = KeywordTooltip.new()
	add_child(_keyword_tooltip)

	# 주요 UI 요소 툴팁 설정
	hp_label.tooltip_text = tr("TOOLTIP_HP")
	qi_label.tooltip_text = tr("TOOLTIP_QI")
	block_label.tooltip_text = tr("TOOLTIP_BLOCK")
	end_turn_button.tooltip_text = tr("TOOLTIP_END_TURN")
	draw_pile_label.tooltip_text = tr("TOOLTIP_DRAW_PILE")
	discard_pile_label.tooltip_text = tr("TOOLTIP_DISCARD_PILE")

	# 시조 슬롯 UI 초기화 (토글 버튼 포함)
	_init_sijo_toggle()
	_init_sijo_slots()

	# 유물 바 UI 추가
	_init_relic_bar()

	# 유물 트리거 시그널 연결
	RelicManager.relic_triggered.connect(_on_relic_triggered)

	# 지속 피해 시그널 연결
	battle_manager.dot_damage_dealt.connect(_on_dot_damage_dealt)

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
		# 이벤트 대기 효과 — 보스 HP 변동 적용
		var boss_mod := _consume_boss_hp_modifier()
		if boss_mod != 1.0:
			for e in enemy_data:
				var orig_hp: int = e.get("hp", 100)
				e["hp"] = maxi(int(orig_hp * boss_mod), 1)

		# 민심 구간별 보스 전투 영향
		var minshim: int = rd.narrative_state.get("minshim", 50)
		if minshim >= 80:
			# 민심 80~100: 보스 HP -20%, 플레이어 매 턴 HP +1 회복
			for e in enemy_data:
				var orig_hp: int = e.get("hp", 100)
				e["hp"] = maxi(int(orig_hp * 0.8), 1)
			rd.set_meta("minshim_boss_heal", true)
		elif minshim >= 30 and minshim <= 49:
			# 민심 30~49: 보스 HP +10%
			for e in enemy_data:
				var orig_hp: int = e.get("hp", 100)
				e["hp"] = int(orig_hp * 1.1)
		elif minshim >= 10 and minshim <= 29:
			# 민심 10~29: 보스에 저항군 추가 페이즈 삽입
			_inject_resistance_phase(enemy_data)
		elif minshim < 10:
			# 민심 0~9: 보스에 민란군 강화 페이즈 삽입
			_inject_minran_phase(enemy_data)

	# 신분 등급별 적 HP 보정
	if rd.current_node_type == MapData.NodeType.ELITE:
		var elite_hp_mod: float = JibunSystem.get_elite_hp_modifier(rd)
		if elite_hp_mod != 1.0:
			for e in enemy_data:
				var orig_hp: int = e.get("hp", 100)
				e["hp"] = int(orig_hp * elite_hp_mod)
	elif is_boss:
		var boss_hp_mod: float = JibunSystem.get_boss_hp_modifier(rd)
		if boss_hp_mod != 1.0:
			for e in enemy_data:
				var orig_hp: int = e.get("hp", 100)
				e["hp"] = int(orig_hp * boss_hp_mod)

	_prev_player_hp = rd.current_hp
	battle_manager.start_battle(deck, enemy_data, rd.current_hp, rd.max_hp, rd.qi_per_turn, rd.character_id)

	# 전투 시작 유물 트리거 (편자, 호신검, 어사마패 등)
	RelicManager.trigger_battle_start(battle_manager)

	# 보스 전투 시작 유물 트리거 (R027 왕의 옥새 등)
	if is_boss:
		RelicManager.trigger_boss_battle_start(battle_manager)

	# 어센션 전투 시작 디버프 (정예전 약화 등)
	if rd.ascension_level > 0:
		for mod in rd.ascension_modifiers:
			if mod is Dictionary and mod.get("type", "") == "combat_start_effect":
				var combat_type: String = mod.get("combat_type", "")
				var should_apply := false
				if combat_type == "elite" and rd.current_node_type == MapData.NodeType.ELITE:
					should_apply = true
				elif combat_type == "all":
					should_apply = true
				if should_apply:
					var effect: String = mod.get("effect", "")
					var duration: int = mod.get("duration", 1)
					if effect == "weaken":
						battle_manager.status_effects.apply_effect("player", "약화", duration)

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
	_sijo_toggle_button.custom_minimum_size = Vector2(56, 56)
	_sijo_toggle_button.add_theme_font_size_override("font_size", 24)
	_sijo_toggle_button.pressed.connect(_on_sijo_toggle_pressed)
	sijo_area.add_child(_sijo_toggle_button)
	sijo_area.move_child(_sijo_toggle_button, 0)

	_sijo_summary_label = Label.new()
	_sijo_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sijo_summary_label.add_theme_font_size_override("font_size", 22)
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
	var total := sijo_system.pattern.size()
	_sijo_summary_label.text = tr("BATTLE_SIJO_SUMMARY_FMT") % [filled, total]


func _init_sijo_slots() -> void:
	sijo_slot_labels.clear()
	for child in sijo_container.get_children():
		child.queue_free()

	for i in sijo_system.pattern.size():
		var label := Label.new()
		label.text = "[%d]" % sijo_system.pattern[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(140, 70)
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		sijo_container.add_child(label)
		sijo_slot_labels.append(label)

	if _sijo_collapsed:
		_update_sijo_summary()


func _refresh_hand_ui() -> void:
	## 손패 UI 갱신을 다음 프레임으로 지연하여 같은 프레임 내 중복 rebuild를 방지한다.
	## try_play_card 실행 중 qi_changed / hand_changed 시그널이 여러 번 발생해도
	## 실제 UI 갱신은 한 번만 수행된다.
	if not _hand_ui_dirty:
		_hand_ui_dirty = true
		call_deferred("_deferred_refresh_hand_ui")


func _deferred_refresh_hand_ui() -> void:
	if not is_inside_tree():
		return
	_hand_ui_dirty = false
	var sijo_beat := sijo_system.get_next_required_beat() if sijo_system else -1
	card_hand.update_hand(battle_manager.hand, battle_manager.current_qi, sijo_beat, battle_manager)

	# 덱 정보 갱신
	draw_pile_label.text = tr("BATTLE_DRAW_PILE_FMT") % battle_manager.draw_pile.size()
	discard_pile_label.text = tr("BATTLE_DISCARD_PILE_FMT") % battle_manager.discard_pile.size()

	# 시조 완성 가능 여부 체크
	_check_sijo_completable()


func _check_sijo_completable() -> void:
	## 현재 손패로 남은 시조 슬롯을 모두 채울 수 있는지 체크
	if not sijo_system or sijo_system.is_complete():
		_hide_sijo_alert()
		return

	var remaining_slots := sijo_system.pattern.size() - sijo_system.current_slot_index
	if remaining_slots <= 0:
		_hide_sijo_alert()
		return

	# 남은 슬롯 패턴에 맞는 비트를 손패에서 찾기
	var hand_beats: Array[int] = []
	for card_id in battle_manager.hand:
		var card: CardData = DataLoader.get_card(card_id)
		if card and battle_manager.can_play_card(card):
			hand_beats.append(card.beat)

	# 순서대로 매칭 가능한지 그리디 체크
	var available_beats := hand_beats.duplicate()
	var can_complete := true
	for slot_idx in range(sijo_system.current_slot_index, sijo_system.pattern.size()):
		var needed_beat: int = sijo_system.pattern[slot_idx]
		var found := available_beats.find(needed_beat)
		if found == -1:
			can_complete = false
			break
		available_beats.remove_at(found)

	if can_complete:
		_show_sijo_alert()
	else:
		_hide_sijo_alert()


func _show_sijo_alert() -> void:
	if _sijo_alert_visible:
		return
	_sijo_alert_visible = true

	if not _sijo_alert_label:
		_sijo_alert_label = Label.new()
		_sijo_alert_label.text = tr("SIJO_ALERT")
		_sijo_alert_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_sijo_alert_label.add_theme_font_size_override("font_size", 22)
		_sijo_alert_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		_sijo_alert_label.anchors_preset = Control.PRESET_CENTER_TOP
		_sijo_alert_label.position.y = 150
		add_child(_sijo_alert_label)

		# 펄스 애니메이션
		var tween := create_tween().set_loops()
		tween.tween_property(_sijo_alert_label, "modulate:a", 0.4, 0.5)
		tween.tween_property(_sijo_alert_label, "modulate:a", 1.0, 0.5)
	else:
		_sijo_alert_label.visible = true


func _hide_sijo_alert() -> void:
	_sijo_alert_visible = false
	if _sijo_alert_label:
		_sijo_alert_label.visible = false


func _mark_enemy_ui_dirty() -> void:
	## 적 UI 업데이트를 예약. 같은 프레임 내 중복 호출을 방지한다.
	if not _enemy_ui_dirty:
		_enemy_ui_dirty = true
		call_deferred("_deferred_update_enemy_ui")


func _deferred_update_enemy_ui() -> void:
	## call_deferred로 호출되어 프레임당 1회만 실행된다.
	if not is_inside_tree():
		return
	_enemy_ui_dirty = false
	_update_enemy_ui()


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
			cache["block_label"].text = tr("BATTLE_ENEMY_BLOCK_FMT") % block_val
			cache["block_label"].visible = block_val > 0
			var intent := battle_manager._get_enemy_intent(i)
			cache["intent_label"].text = _format_intent(intent)
			cache["intent_label"].add_theme_color_override("font_color", _get_intent_color(intent))
			_build_status_icons(cache["status_hbox"], "enemy_%d" % i)
		else:
			# 새 적 패널 생성
			var enemy_name: String = TranslationManager.trd_name(enemy)
			if enemy_name == "":
				enemy_name = tr("BATTLE_ENEMY_FALLBACK")

			var panel := PanelContainer.new()
			var vbox := VBoxContainer.new()

			# 적 실루엣 심볼 — 이미지 없이 텍스트로 시각적 존재감 확보
			var silhouette := Label.new()
			silhouette.text = _get_enemy_silhouette(enemy)
			silhouette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			silhouette.add_theme_font_size_override("font_size", 48)
			silhouette.add_theme_color_override("font_color", Color(0.8, 0.5, 0.5, 0.9))

			var name_label := Label.new()
			name_label.text = enemy_name
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.add_theme_font_size_override("font_size", 24)
			var hp_lbl := Label.new()
			hp_lbl.text = "HP: %d/%d" % [enemy["current_hp"], enemy["max_hp"]]
			hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hp_lbl.add_theme_font_size_override("font_size", 22)

			var intent_label := Label.new()
			intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			intent_label.add_theme_font_size_override("font_size", 22)
			var intent := battle_manager._get_enemy_intent(i)
			intent_label.text = _format_intent(intent)
			intent_label.add_theme_color_override("font_color", _get_intent_color(intent))

			var block_val: int = enemy.get("block", 0)
			var enemy_block_label := Label.new()
			enemy_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			enemy_block_label.add_theme_font_size_override("font_size", 22)
			enemy_block_label.text = tr("BATTLE_ENEMY_BLOCK_FMT") % block_val
			enemy_block_label.visible = block_val > 0

			var status_hbox := HBoxContainer.new()
			status_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			_build_status_icons(status_hbox, "enemy_%d" % i)

			vbox.add_child(silhouette)
			vbox.add_child(name_label)
			vbox.add_child(hp_lbl)
			vbox.add_child(enemy_block_label)
			vbox.add_child(status_hbox)
			vbox.add_child(intent_label)
			panel.add_child(vbox)
			panel.custom_minimum_size = Vector2(200, 200)
			enemy_container.add_child(panel)

			_enemy_ui_cache[i] = {
				"panel": panel,
				"name_label": name_label,
				"hp_label": hp_lbl,
				"block_label": enemy_block_label,
				"intent_label": intent_label,
				"status_hbox": status_hbox,
			}


func _get_enemy_silhouette(enemy: Dictionary) -> String:
	## 적 데이터에서 시각적 실루엣 심볼을 반환한다.
	var combat_type: String = enemy.get("combat_type", "")
	if combat_type == "boss":
		return "{{X}}"
	if combat_type == "elite":
		return "[*]"
	# 일반 적: 이름 첫 글자 기반
	var disp_name: String = TranslationManager.trd_name(enemy, false)
	if disp_name.length() > 0:
		return "<%s>" % disp_name[0]
	return "<X>"


func _format_intent(intent: Dictionary) -> String:
	var intent_type: String = intent.get("intent", intent.get("type", ""))
	var name_str: String = intent.get("name", "")
	match intent_type:
		"attack", "attack_debuff":
			var dmg: int = intent.get("damage", 0)
			var times: int = intent.get("times", 1)
			var icon := "⚔"
			if times > 1:
				return "%s %s %d×%d" % [icon, name_str, dmg, times] if name_str else "%s %s" % [icon, tr("BATTLE_ATTACK_MULTI_FMT") % [dmg, times]]
			return "%s %s %d" % [icon, name_str, dmg] if name_str else "%s %s" % [icon, tr("BATTLE_ATTACK_FMT") % dmg]
		"defend", "defend_buff", "buff_defend":
			var blk: int = intent.get("block", 0)
			return "🛡 %s %d" % [name_str, blk] if name_str else "🛡 %s" % (tr("BATTLE_DEFEND_FMT") % blk)
		"buff":
			return "⬆ %s" % name_str if name_str else "⬆ %s" % tr("BATTLE_BUFF")
		"debuff":
			return "⬇ %s" % name_str if name_str else "⬇ %s" % tr("BATTLE_DEBUFF")
		"special":
			return "✦ %s" % name_str if name_str else "✦ %s" % tr("BATTLE_SPECIAL")
		_:
			return "❓ %s" % name_str if name_str else "❓ ???"


func _get_intent_color(intent: Dictionary) -> Color:
	## 인텐트 타입과 위협도에 따른 색상 반환
	var intent_type: String = intent.get("intent", intent.get("type", ""))
	match intent_type:
		"attack", "attack_debuff":
			var dmg: int = intent.get("damage", 0)
			var times: int = intent.get("times", 1)
			var total := dmg * times
			if total >= 20:
				return Color(1.0, 0.15, 0.15)  # 고위협: 밝은 빨강
			elif total >= 10:
				return Color(1.0, 0.4, 0.3)    # 중위협: 주황빨강
			else:
				return Color(1.0, 0.6, 0.5)    # 저위협: 연한 빨강
		"defend", "defend_buff", "buff_defend":
			return Color(0.4, 0.7, 1.0)        # 방어: 파랑
		"buff":
			return Color(1.0, 0.85, 0.3)       # 강화: 노랑
		"debuff":
			return Color(0.8, 0.4, 1.0)        # 디버프: 보라
		"special":
			return Color(1.0, 0.7, 0.2)        # 특수: 주황
		_:
			return Color(0.7, 0.7, 0.7)        # 알 수 없음: 회색


# --- 시그널 핸들러 ---

func _on_hand_changed(_new_hand: Array[String]) -> void:
	_refresh_hand_ui()


func _on_qi_changed(current: int, max_val: int) -> void:
	qi_label.text = tr("BATTLE_QI_FMT") % [current, max_val]
	_refresh_hand_ui()


func _on_hp_changed(current: int, max_val: int) -> void:
	# HP 변화 시 VFX
	if vfx and _prev_player_hp > 0:
		var diff := _prev_player_hp - current
		if diff > 0:
			# 데미지: 숫자 팝업 + 화면 흔들림
			var hp_pos := hp_label.global_position + Vector2(hp_label.size.x / 2.0, 0)
			vfx.spawn_damage_number(self, hp_pos, diff)
			vfx.screen_shake(clampf(diff * 1.5, 4.0, 15.0))
		elif diff < 0:
			# 회복
			var hp_pos := hp_label.global_position + Vector2(hp_label.size.x / 2.0, 0)
			vfx.spawn_damage_number(self, hp_pos, -diff, true)
		# HP 바 스무스 애니메이션
		vfx.animate_hp_bar(hp_label, _prev_player_hp, current, max_val)
	else:
		hp_label.text = "HP: %d/%d" % [current, max_val]
	_prev_player_hp = current


func _on_block_changed(new_block: int) -> void:
	var old_block_text := block_label.text
	var old_block := 0
	var block_prefix := tr("BATTLE_BLOCK_FMT").split("%d")[0]
	if old_block_text.begins_with(block_prefix):
		old_block = old_block_text.substr(block_prefix.length()).strip_edges().to_int()
	block_label.text = tr("BATTLE_BLOCK_FMT") % new_block
	block_label.visible = new_block > 0
	# 방어도 획득 시 VFX
	if vfx and new_block > old_block:
		var gained := new_block - old_block
		var pos := block_label.global_position + Vector2(block_label.size.x / 2.0, 0)
		vfx.spawn_block_number(self, pos, gained)
		# 실드 이펙트 (파란색 원형 오버레이)
		vfx.shield_effect(self, block_label.global_position + block_label.size / 2.0)


func _on_turn_started(turn: int) -> void:
	turn_label.text = tr("BATTLE_TURN_FMT") % turn
	# 턴 전환 배너 VFX
	if vfx and turn > 1:
		vfx.turn_transition(self, tr("BATTLE_TURN_FMT") % turn)
	# 첫 턴에 카드 꾹 누르기 힌트 표시 (한 번만)
	if turn == 1:
		var meta := SaveManager.load_meta()
		if not meta.get("card_zoom_hint_shown", false):
			meta["card_zoom_hint_shown"] = true
			SaveManager.save_meta(meta)
			_show_card_zoom_hint()
	# 매 턴 시작 유물 트리거 (삼족오 깃털 등)
	RelicManager.trigger_turn_start(battle_manager)

	# 민심 80+ 보스전: 매 턴 HP +1 회복
	if GameManager.run_data and GameManager.run_data.has_meta("minshim_boss_heal"):
		if battle_manager.player_hp < battle_manager.player_max_hp:
			battle_manager.player_hp += 1
			battle_manager.hp_changed.emit(battle_manager.player_hp, battle_manager.player_max_hp)
			if turn == 1:
				battle_manager.passive_triggered.emit(tr("PASSIVE_MINSHIM_TITLE"), tr("PASSIVE_MINSHIM_DESC"))


func _on_enemy_hp_changed(enemy_index: int, current: int, max_val: int) -> void:
	# 적 데미지 숫자 팝업 + 히트 애니메이션
	if vfx and _enemy_ui_cache.has(enemy_index):
		var cache: Dictionary = _enemy_ui_cache[enemy_index]
		var prev_text: String = cache["hp_label"].text
		# 이전 HP 파싱
		var prev_hp := max_val
		if prev_text.begins_with("HP: "):
			var parts := prev_text.substr(4).split("/")
			if parts.size() > 0:
				prev_hp = parts[0].to_int()
		var diff := prev_hp - current
		if diff > 0:
			var panel: Control = cache["panel"]
			var pos: Vector2 = panel.global_position + Vector2(panel.size.x / 2.0, 30)
			vfx.spawn_damage_number(self, pos, diff)
			vfx.shake_node(panel)
			# 피격 플래시 (빨간색 깜빡임)
			vfx.flash_node(panel, Color(1.0, 0.3, 0.2, 0.5))
			# 강공격 시 화면 쉐이크 (데미지 10 이상)
			if diff >= 10:
				vfx.screen_shake(clampf(diff * 0.8, 5.0, 12.0))
	_mark_enemy_ui_dirty()


func _on_enemy_intent_shown(_enemy_index: int, _intent: Dictionary) -> void:
	_mark_enemy_ui_dirty()


func _on_card_played(hand_index: int, target_enemy_index: int) -> void:
	battle_manager.try_play_card(hand_index, target_enemy_index)


func _on_card_zoom_requested(card_data: CardData) -> void:
	## 카드 상세보기 팝업 표시
	var popup := CardZoomPopup.new()
	add_child(popup)
	popup.show_card(card_data)


func _show_card_zoom_hint() -> void:
	## 카드 꾹 누르기 힌트를 2초간 표시
	var hint_label := Label.new()
	hint_label.text = tr("BATTLE_CARD_ZOOM_HINT")
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 20)
	hint_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	hint_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
	hint_label.position.y -= 160
	add_child(hint_label)
	# 2초 후 페이드아웃 제거
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(hint_label.queue_free)


func _on_end_turn_pressed() -> void:
	AudioManager.play_sfx_by_key("end_turn")
	battle_manager.end_player_turn()


func _on_sijo_slot_filled(index: int, card_id: String, _jang_name: String) -> void:
	AudioManager.play_sfx_by_key("sijo_slot")
	if index < sijo_slot_labels.size():
		var card: CardData = DataLoader.get_card(card_id)
		if card:
			sijo_slot_labels[index].text = card.get_display_name()
		else:
			sijo_slot_labels[index].text = card_id
		sijo_slot_labels[index].add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	if _sijo_collapsed:
		_update_sijo_summary()

	# 유물 트리거: 시조 슬롯 마일스톤 (R019 등)
	RelicManager.trigger_on_sijo_milestone(battle_manager, index + 1)
	# 유물 트리거: 시조 슬롯 채움 (RS105 무관의 갑주 등)
	RelicManager.trigger_on_sijo_slot_fill(battle_manager)

	# 부분 완성 보상
	match index:
		2:  # 3/6 슬롯 완성 (초장 완성): 기 +1
			battle_manager.current_qi = mini(battle_manager.current_qi + 1, battle_manager.max_qi)
			battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
			_show_sijo_reward_popup(tr("BATTLE_CHOJANG_REWARD"))
		3:  # 4/6 슬롯 완성 (중장 완성): 카드 1장 드로우
			battle_manager.draw_cards(1)
			_show_sijo_reward_popup(tr("BATTLE_JUNGJANG_REWARD"))


## 시조 부분 완성 보상 팝업 텍스트를 표시한다.
func _show_sijo_reward_popup(text: String) -> void:
	var popup := Label.new()
	popup.text = text
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.anchors_preset = Control.PRESET_CENTER_TOP
	popup.position.y = 120
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_color_override("font_color", Color(0.6, 1.0, 0.5))
	add_child(popup)
	var tween := create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(popup.queue_free)


## 시선/절창 콤보 판정. 시조 완성 시점에 직업 자원 소비량 또는 기 획득량을 확인한다.
## 시선 (Tier 1): 자원 2+ 소비 (도사: 기 2+ 획득) → 다음 카드 코스트 -1 + 직업별 보너스
## 절창 (Tier 2): 자원 3+ 소비 (도사: 기 3+ 획득) → 시선 보상 +100% + 직업별 강력한 보너스 (ZER-259)
func _check_sijo_combo() -> void:
	var consumed := battle_manager.resources_consumed_this_turn
	var job := battle_manager.character_id

	# 도사: 기(qi) 획득량으로 시선/절창 판정 (ZER-259)
	if not battle_manager.has_class_resource:
		var qi_gained := battle_manager.qi_gained_this_turn
		if qi_gained < 2:
			return
		var tier := 1  # 시선
		if qi_gained >= 3:
			tier = 2  # 절창
		battle_manager.combo_triggered.emit(tier, job)
		if tier == 2:
			_apply_jeolchang_reward(job)
			if vfx:
				vfx.combo_vfx(self, tr("COMBO_JEOLCHANG"), Color(1.0, 0.3, 0.1))
			AudioManager.play_sfx_by_key("sijo_complete")
		else:
			_apply_siseon_reward(job)
			if vfx:
				vfx.combo_vfx(self, tr("COMBO_SISEON"), Color(0.3, 0.8, 1.0))
			AudioManager.play_sfx_by_key("card_play")
		return

	if consumed < 2:
		return

	var tier := 1  # 시선
	if consumed >= 3:
		tier = 2  # 절창 (ZER-259: 5→3으로 완화)

	# 콤보 시그널 발행
	battle_manager.combo_triggered.emit(tier, job)

	if tier == 2:
		# 절창 보상
		_apply_jeolchang_reward(job)
		if vfx:
			vfx.combo_vfx(self, tr("COMBO_JEOLCHANG"), Color(1.0, 0.3, 0.1))
		AudioManager.play_sfx_by_key("sijo_complete")  # 강한 효과음 재사용
	else:
		# 시선 보상
		_apply_siseon_reward(job)
		if vfx:
			vfx.combo_vfx(self, tr("COMBO_SISEON"), Color(0.3, 0.8, 1.0))
		AudioManager.play_sfx_by_key("card_play")


func _apply_siseon_reward(job: String) -> void:
	## 시선 (Tier 1) 보상: 공통 + 직업별
	# 공통: 다음 카드 코스트 -1
	battle_manager._next_card_cost_reduce += 1
	var reward_text := tr("BATTLE_SISEON_REWARD")

	match job:
		"mugwan":
			# 무관: 기력 +2
			battle_manager.current_class_resource = mini(
				battle_manager.current_class_resource + 2,
				battle_manager.max_class_resource)
			battle_manager.class_resource_changed.emit(
				battle_manager.current_class_resource,
				battle_manager.max_class_resource)
			reward_text += ", " + tr("BATTLE_SISEON_STAMINA") % 2
		"mungwan":
			# 문관: 카드 1장 드로우
			battle_manager.draw_cards(1)
			reward_text += ", " + tr("BATTLE_SISEON_CARD") % 1
		"dosa":
			# 도사: 기 +1 (ZER-259)
			battle_manager.current_qi = mini(
				battle_manager.current_qi + 1,
				battle_manager.max_qi)
			battle_manager.qi_changed.emit(
				battle_manager.current_qi, battle_manager.max_qi)
			reward_text += ", " + tr("BATTLE_SISEON_QI")

	_show_sijo_reward_popup(reward_text)
	battle_manager.passive_triggered.emit(tr("PASSIVE_SISEON"), reward_text)


func _apply_jeolchang_reward(job: String) -> void:
	## 절창 (Tier 2) 보상: 공통 + 직업별 강력한 보너스
	# 공통: 시선 보상(다음 카드 -1) + 100% 추가 = 다음 카드 무료
	battle_manager._next_card_cost_reduce += 99  # 사실상 무료

	var reward_text := tr("BATTLE_JEOLCHANG_TEXT")
	match job:
		"mugwan":
			# 무관: 적 전체 기절 1턴
			for i in battle_manager.enemies.size():
				if battle_manager.enemies[i]["current_hp"] > 0:
					var target_id := "enemy_%d" % i
					battle_manager.status_effects.apply_effect(target_id, "기절", 1)
			reward_text += " " + tr("BATTLE_JEOLCHANG_STUN")
		"mungwan":
			# 문관: 카드 2장 드로우 + 무료
			battle_manager.draw_cards(2)
			reward_text += " " + tr("BATTLE_JEOLCHANG_CARD_FREE") % 2
		"dosa":
			# 도사 절창: 모든 적에 독3+화상3 + 기 최대치 회복 (ZER-259)
			for i in battle_manager.enemies.size():
				if battle_manager.enemies[i]["current_hp"] > 0:
					var target_id := "enemy_%d" % i
					battle_manager.status_effects.apply_effect(target_id, "독", 3)
					battle_manager.status_effects.apply_effect(target_id, "화상", 3)
			battle_manager.current_qi = battle_manager.max_qi
			battle_manager.qi_changed.emit(
				battle_manager.current_qi, battle_manager.max_qi)
			reward_text += " " + tr("BATTLE_JEOLCHANG_DOSA")

	_show_sijo_reward_popup(reward_text)
	battle_manager.passive_triggered.emit(tr("PASSIVE_JEOLCHANG"), reward_text)


## 시조 장 완성 시 직업별 자원 보너스 지급.
func _on_sijo_chapter_completed(chapter: String) -> void:
	if battle_manager.state == BattleManager.BattleState.BATTLE_WIN or battle_manager.state == BattleManager.BattleState.BATTLE_LOSE:
		return
	var job := battle_manager.character_id
	var reward_text := ""

	match chapter:
		"초장":
			match job:
				"mugwan":
					# 무관: 기력 +1
					battle_manager.current_class_resource = mini(
						battle_manager.current_class_resource + 1,
						battle_manager.max_class_resource)
					battle_manager.class_resource_changed.emit(
						battle_manager.current_class_resource,
						battle_manager.max_class_resource)
					reward_text = tr("BATTLE_CHOJANG_COMPLETE_STAMINA")
				"mungwan":
					# 문관: 학식 +1
					battle_manager.current_class_resource = mini(
						battle_manager.current_class_resource + 1,
						battle_manager.max_class_resource)
					battle_manager.class_resource_changed.emit(
						battle_manager.current_class_resource,
						battle_manager.max_class_resource)
					reward_text = tr("BATTLE_CHOJANG_COMPLETE_SCHOLAR")
				_:
					reward_text = tr("BATTLE_CHOJANG_COMPLETE")

		"중장":
			# 공통: 기 +1 + 다음 카드 피해/방어 +30%
			battle_manager.current_qi = mini(
				battle_manager.current_qi + 1,
				battle_manager.max_qi)
			battle_manager.qi_changed.emit(
				battle_manager.current_qi,
				battle_manager.max_qi)
			battle_manager._next_card_power_bonus += 0.3
			reward_text = tr("BATTLE_JUNGJANG_COMPLETE_POWER")

		"종장":
			# 공통: 기 +2 + 카드 1장 드로우 + 적 전체 취약 1턴
			battle_manager.current_qi = mini(
				battle_manager.current_qi + 2,
				battle_manager.max_qi)
			battle_manager.qi_changed.emit(
				battle_manager.current_qi,
				battle_manager.max_qi)
			battle_manager.draw_cards(1)
			# 적 전체에 취약 1턴 부여
			for i in battle_manager.enemies.size():
				if battle_manager.enemies[i]["current_hp"] > 0:
					battle_manager.status_effects.apply_effect(
						"enemy_%d" % i, "취약", 1)
			reward_text = tr("BATTLE_JONGJANG_COMPLETE_POWER")

	# 유물 트리거: 장 완성 (RS104 청사 붓, RS106 오얏나무 가지, RS107 해시계 조각)
	RelicManager.trigger_on_sijo_chapter_complete(battle_manager, chapter)

	if reward_text != "":
		_show_sijo_reward_popup(reward_text)
		battle_manager.passive_triggered.emit(tr("PASSIVE_SIJO_CHAPTER") % chapter, reward_text)


func _on_sijo_completed(final_card_id: String, all_slot_card_ids: Array) -> void:
	# 전투가 이미 종료된 상태면 추가 효과 적용하지 않음
	if battle_manager.state == BattleManager.BattleState.BATTLE_WIN or battle_manager.state == BattleManager.BattleState.BATTLE_LOSE:
		return
	AudioManager.play_sfx_by_key("sijo_complete")
	# 시조 완성 VFX — 완성에 사용된 6장 카드명으로 한시 구절 연출
	if vfx:
		var slot_names: Array[String] = []
		for slot_id in all_slot_card_ids:
			var slot_card: CardData = DataLoader.get_card(slot_id)
			if slot_card:
				slot_names.append(slot_card.get_display_name())
			else:
				slot_names.append("…")
		vfx.sijo_complete_vfx(self, slot_names)
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
	# 시조 완성 보상 강화 (ZER-259): 기 +2, 드로우 +2
	battle_manager.current_qi += 2
	battle_manager.current_qi = mini(battle_manager.current_qi, battle_manager.max_qi)
	battle_manager.qi_changed.emit(battle_manager.current_qi, battle_manager.max_qi)
	# 기본 드로우 2 + 유물 추가 드로우 (R023 등)
	var extra_draw := RelicManager.trigger_on_sijo_complete(battle_manager)
	battle_manager.draw_cards(2 + extra_draw)

	# 시선/절창 콤보 판정 (시조 완성 + 직업 자원 소비)
	_check_sijo_combo()

	sijo_system.reset()
	_init_sijo_slots()

	# RS102 호패: 시조 완성 후 초장 자동 채움
	if battle_manager.has_meta("sijo_auto_fill_chojang"):
		battle_manager.remove_meta("sijo_auto_fill_chojang")
		# 손패에서 beat 3, 4인 카드를 찾아 자동 채움
		var filled_chojang := false
		for card_id in battle_manager.hand:
			var auto_card: CardData = DataLoader.get_card(card_id)
			if auto_card and auto_card.beat == 3 and sijo_system.current_slot_index == 0:
				sijo_system.try_fill_slot(3, card_id)
			elif auto_card and auto_card.beat == 4 and sijo_system.current_slot_index == 1:
				sijo_system.try_fill_slot(4, card_id)
				filled_chojang = true
				break
		if not filled_chojang and sijo_system.current_slot_index < 2:
			# 손패에 적합한 카드가 없으면 가상 카드로 채움
			sijo_system.try_fill_slot(3, "AUTO_FILL")
			sijo_system.try_fill_slot(4, "AUTO_FILL")


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
	popup.add_theme_font_size_override("font_size", 24)
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
	_class_resource_label.add_theme_font_size_override("font_size", 28)
	_class_resource_label.add_theme_color_override("font_color", battle_manager.get_class_resource_color())
	$BattleHUD/PlayerInfo.add_child(_class_resource_label)


func _init_active_skill_button() -> void:
	_active_skill_button = Button.new()
	var skill_name := battle_manager.get_active_skill_name()
	_active_skill_button.text = skill_name
	_active_skill_button.tooltip_text = battle_manager.get_active_skill_description()
	_active_skill_button.pressed.connect(_on_active_skill_pressed)
	_active_skill_button.custom_minimum_size = Vector2(160, 56)
	_active_skill_button.add_theme_font_size_override("font_size", 24)
	$BattleHUD.add_child(_active_skill_button)


func _on_active_skill_pressed() -> void:
	if battle_manager.use_active_skill():
		_active_skill_button.disabled = true
		_active_skill_button.text = tr("SKILL_USED_FMT") % battle_manager.get_active_skill_name()


func _on_passive_triggered(skill_name: String, description: String) -> void:
	# 패시브 발동 시 배너 형태로 표시 (중앙 상단)
	var banner := ColorRect.new()
	banner.color = Color(0.1, 0.2, 0.1, 0.85)
	banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top = 4
	banner.offset_bottom = 36
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 50
	add_child(banner)

	var popup := Label.new()
	popup.text = tr("PASSIVE_TRIGGER_FMT") % [skill_name, description]
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_theme_font_size_override("font_size", 20)
	popup.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	banner.add_child(popup)

	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 0.0, 1.2).set_delay(1.0)
	tween.tween_callback(banner.queue_free)


func _on_status_effect_changed(target: String, _effect_id: String, _stacks: int) -> void:
	# 대상에 따라 필요한 UI만 업데이트
	if target == "player":
		_update_player_status_ui()
	elif target.begins_with("enemy_"):
		_mark_enemy_ui_dirty()
	# 상태효과 적용 시 바운스 VFX
	if vfx:
		if target == "player" and is_instance_valid(_player_status_container):
			vfx.bounce_node(_player_status_container)
		elif target.begins_with("enemy_"):
			var idx := target.substr(6).to_int()
			if _enemy_ui_cache.has(idx):
				vfx.bounce_node(_enemy_ui_cache[idx]["panel"], 1.15)


func _on_dot_damage_dealt(target: String, _effect_id: String, amount: int) -> void:
	## 지속 피해(독, 화상 등) VFX
	if not vfx:
		return
	if target == "player":
		var pos := hp_label.global_position + Vector2(hp_label.size.x / 2.0, 0)
		vfx.spawn_damage_number(self, pos, amount)
	elif target.begins_with("enemy_"):
		var idx := target.substr(6).to_int()
		if _enemy_ui_cache.has(idx):
			var cache: Dictionary = _enemy_ui_cache[idx]
			var panel: Control = cache["panel"]
			var pos: Vector2 = panel.global_position + Vector2(panel.size.x / 2.0, 30)
			vfx.spawn_damage_number(self, pos, amount)


func _update_player_status_ui() -> void:
	block_label.text = tr("BATTLE_BLOCK_FMT") % battle_manager.player_block
	block_label.visible = battle_manager.player_block > 0

	# 플레이어 상태이상 표시 (전용 컨테이너)
	if not is_instance_valid(_player_status_container):
		_player_status_container = HBoxContainer.new()
		_player_status_container.alignment = BoxContainer.ALIGNMENT_CENTER
		$BattleHUD/PlayerInfo.add_child(_player_status_container)
	_build_status_icons(_player_status_container, "player")


func _build_status_icons(container: HBoxContainer, target: String) -> void:
	## 상태이상 아이콘을 캐시 기반으로 업데이트. 변경된 부분만 갱신한다.
	if battle_manager.status_effects == null:
		# 효과 없음 — 기존 아이콘 모두 숨기기
		if _status_icon_cache.has(target):
			for eid in _status_icon_cache[target]:
				_status_icon_cache[target][eid]["panel"].visible = false
		return

	var effects := battle_manager.status_effects.get_all_effects(target)

	if not _status_icon_cache.has(target):
		_status_icon_cache[target] = {}
	var cache: Dictionary = _status_icon_cache[target]

	# 사라진 효과 숨기기
	for cached_eid in cache:
		if not effects.has(cached_eid):
			cache[cached_eid]["panel"].visible = false

	for effect_id in effects:
		var stacks: int = effects[effect_id]
		var def := StatusEffectData.get_definition(effect_id)

		if cache.has(effect_id):
			# 캐시된 아이콘 텍스트만 업데이트
			var entry: Dictionary = cache[effect_id]
			entry["panel"].visible = true
			var label: Label = entry["label"]
			if def:
				if def.is_permanent or def.show_duration:
					label.text = "%s%d" % [def.icon_text, stacks]
				else:
					label.text = def.icon_text
			else:
				label.text = "%s×%d" % [effect_id, stacks]
		else:
			# 새 아이콘 생성
			var icon_panel := PanelContainer.new()
			var stylebox := StyleBoxFlat.new()
			stylebox.bg_color = Color(0.15, 0.15, 0.15, 0.9)
			stylebox.border_color = def.color if def else Color.GRAY
			stylebox.set_border_width_all(1)
			stylebox.set_corner_radius_all(4)
			stylebox.set_content_margin_all(4)
			icon_panel.add_theme_stylebox_override("panel", stylebox)
			icon_panel.mouse_filter = Control.MOUSE_FILTER_STOP

			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 18)

			if def:
				label.add_theme_color_override("font_color", def.color)
				if def.is_permanent or def.show_duration:
					label.text = "%s%d" % [def.icon_text, stacks]
				else:
					label.text = def.icon_text
				label.tooltip_text = "%s: %s" % [def.name_ko, def.description]
			else:
				label.text = "%s×%d" % [effect_id, stacks]
				label.add_theme_color_override("font_color", Color.GRAY)

			icon_panel.add_child(label)
			container.add_child(icon_panel)
			cache[effect_id] = {"panel": icon_panel, "label": label}

			# 클릭/탭으로 키워드 툴팁 표시
			var eid: String = effect_id  # 클로저 캡처용
			icon_panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed:
					if _keyword_tooltip:
						_keyword_tooltip.show_tooltip(eid, icon_panel.global_position + Vector2(0, icon_panel.size.y + 5))
			)


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
	$HandArea.visible = false

	# 민심 보스전 회복 메타 정리
	if GameManager.run_data and GameManager.run_data.has_meta("minshim_boss_heal"):
		GameManager.run_data.remove_meta("minshim_boss_heal")

	# 상태 효과 아이콘 캐시 정리 (메모리 누수 방지)
	for target in _status_icon_cache:
		for eid in _status_icon_cache[target]:
			var panel = _status_icon_cache[target][eid].get("panel")
			if panel and is_instance_valid(panel):
				panel.queue_free()
	_status_icon_cache.clear()

	# HP 동기화
	if GameManager.run_data:
		GameManager.run_data.current_hp = battle_manager.player_hp

	# 전투 결과 오버레이 표시
	_show_battle_result(victory)

	# 1.0초 후 씬 전환 (VFX 플래시 0.3초 + 결과 텍스트 읽기 시간)
	var timer := get_tree().create_timer(1.0)
	await timer.timeout
	if victory:
		# 유물 트리거: 전투 승리
		RelicManager.trigger_combat_victory()
		# 정예 전투 승리 유물 트리거
		if GameManager.run_data and GameManager.run_data.current_node_type == MapData.NodeType.ELITE:
			RelicManager.trigger_elite_victory()

		# 전투 승리 시 신분 점수 부여
		if GameManager.run_data:
			var rank_change = JibunSystem.on_battle_victory(
				GameManager.run_data,
				GameManager.run_data.current_node_type
			)
			# 승급 발생 시 보상 정보를 메타에 저장
			if rank_change is Array and rank_change[1] > rank_change[0]:
				GameManager.run_data.set_meta("jibun_rank_up", rank_change[1])

		# 보스 처치 시 민심 변동 + 골드 환급
		_apply_post_battle_minshim()

		# 적 보상 데이터 수집 → 보상 씬으로 전달
		var rewards := _collect_enemy_rewards()
		if GameManager.run_data:
			GameManager.run_data.set_meta("battle_rewards", rewards)
		GameManager.change_state(GameManager.GameState.REWARD)
	else:
		GameManager.end_run(false)


func _show_battle_result(victory: bool) -> void:
	# 승리/패배 시 화면 플래시
	if vfx:
		if victory:
			vfx.flash_screen(self, Color(1.0, 0.85, 0.3, 0.3), 0.3)
		else:
			vfx.flash_screen(self, Color(1.0, 0.2, 0.2, 0.3), 0.3)
			vfx.screen_shake(10.0)

	var overlay := ColorRect.new()
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.color = Color(0, 0, 0, 0.6)
	add_child(overlay)

	var label := Label.new()
	label.text = tr("BATTLE_VICTORY_TEXT") if victory else tr("BATTLE_DEFEAT_TEXT")
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


## pending_effects에서 boss_hp_modifier를 소비하고 HP 배율을 반환한다.
func _consume_boss_hp_modifier() -> float:
	var modifier: float = 1.0
	if not GameManager.run_data:
		return modifier
	var effects: Array = GameManager.run_data.narrative_state.get("pending_effects", [])
	var remaining: Array = []
	for eff in effects:
		if eff.get("type") == "boss_hp_modifier":
			modifier *= (1.0 + eff.get("percent", 0) / 100.0)
		else:
			remaining.append(eff)
	GameManager.run_data.narrative_state["pending_effects"] = remaining
	return modifier


## 민심 10~29 시 보스에 "저항군" 추가 페이즈를 삽입한다.
## 보스 HP 25% 구간에서 발동하며, 민란보다 약한 버전이다.
func _inject_resistance_phase(enemy_data: Array[Dictionary]) -> void:
	for enemy in enemy_data:
		var phases: Array = enemy.get("phases", [])
		if phases.is_empty():
			continue

		var resist_phase := {
			"phase": phases.size() + 1,
			"hp_threshold_label": "25% → 0% (저항군)",
			"hp_threshold_min": 0,
			"description": "저항군이 전장에 합류한다!",
			"phase_trigger": {
				"type": "hp_threshold",
				"hp_percent": 25,
				"on_trigger": [
					{"type": "dialogue", "text": "저항군이 나타났다! 혼란이 가중된다!"},
					{"type": "apply_buff", "buff": "strength", "stacks": 2}
				]
			},
			"moves": [
				{
					"id": "resist_charge",
					"name": {"ko": "저항군 습격"},
					"intent": "attack",
					"damage": 12,
					"effects": []
				},
				{
					"id": "resist_rally",
					"name": {"ko": "결집"},
					"intent": "defend",
					"block": 10,
					"effects": []
				}
			],
			"move_pattern": {"type": "sequential", "sequence": [0, 1]}
		}
		phases.append(resist_phase)
		enemy["phases"] = phases


## 민심 0~9 시 보스에 "민란" 추가 페이즈를 삽입한다.
## 마지막 페이즈로 추가되며, 보스 HP 15% 구간에서 발동한다.
func _inject_minran_phase(enemy_data: Array[Dictionary]) -> void:
	for enemy in enemy_data:
		var phases: Array = enemy.get("phases", [])
		if phases.is_empty():
			continue  # 페이즈가 없는 적은 스킵

		# 민란 페이즈 — HP 15% 이하에서 발동
		var minran_phase := {
			"phase": phases.size() + 1,
			"hp_threshold_label": "15% → 0% (민란)",
			"hp_threshold_min": 0,
			"description": "분노한 백성들이 전장에 난입한다!",
			"phase_trigger": {
				"type": "hp_threshold",
				"hp_percent": 15,
				"on_trigger": [
					{"type": "dialogue", "text": "백성들의 분노가 폭발한다! 민란이다!"},
					{"type": "apply_buff", "buff": "strength", "stacks": 3},
					{"type": "apply_buff", "buff": "thorns", "stacks": 3}
				]
			},
			"moves": [
				{
					"id": "minran_charge",
					"name": {"ko": "민란 돌격"},
					"intent": "attack",
					"damage": 18,
					"effects": []
				},
				{
					"id": "minran_fury",
					"name": {"ko": "민중의 분노"},
					"intent": "attack",
					"damage": 12,
					"hit_count": 2,
					"effects": []
				},
				{
					"id": "minran_barricade",
					"name": {"ko": "바리케이드"},
					"intent": "defend",
					"block": 15,
					"effects": []
				}
			],
			"move_pattern": {"type": "sequential", "sequence": [0, 1, 2]}
		}
		phases.append(minran_phase)
		enemy["phases"] = phases


## 전투 승리 후 적 데이터에 따라 민심 변동 + 골드 환급을 처리한다.
func _apply_post_battle_minshim() -> void:
	if not GameManager.run_data:
		return
	var rd := GameManager.run_data
	if not rd.narrative_state.has("minshim"):
		rd.narrative_state["minshim"] = 50

	# 양반 이상 민심 획득 배율
	var minshim_mult: float = JibunSystem.get_minshim_gain_multiplier(rd)

	for enemy in battle_manager.enemies:
		# minshim_on_defeat 필드가 있으면 민심 변동
		var minshim_delta: int = enemy.get("minshim_on_defeat", 0)
		if minshim_delta != 0:
			# 양반 보너스 적용 (양수 획득에만)
			if minshim_delta > 0:
				minshim_delta = int(minshim_delta * minshim_mult)
			var current: int = rd.narrative_state.get("minshim", 50)
			rd.narrative_state["minshim"] = clampi(current + minshim_delta, 0, 100)

		# 탐학한 수령 전용: 강탈당한 골드 50% 환급
		var rewards: Dictionary = enemy.get("rewards", {})
		if rewards.get("gold_bonus_from_drained", false):
			var drained: int = rd.narrative_state.get("gold_drained_this_run", 0)
			var bonus: int = mini(int(drained * 0.5), 60)
			if bonus > 0:
				rd.gold += bonus
			# 추적 값 초기화
			rd.narrative_state.erase("gold_drained_this_run")

	# 일반 정예 적 처치 민심 +3 (양반 보너스 적용)
	if rd.current_node_type == MapData.NodeType.ELITE:
		var elite_delta: int = int(3 * minshim_mult)
		var current: int = rd.narrative_state.get("minshim", 50)
		rd.narrative_state["minshim"] = clampi(current + elite_delta, 0, 100)
