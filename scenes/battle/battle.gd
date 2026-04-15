extends Control

## 전투 씬 메인 스크립트. UI와 BattleManager를 연결한다.

var vfx: VfxManager = null
var _prev_player_hp: int = 0  # HP 변화 감지용
var _keyword_tooltip: KeywordTooltip = null  # 키워드 툴팁

@onready var hp_label: Label = $PlayerHUD/StatusRow/HPLabel
@onready var qi_label: Label = $PlayerHUD/StatusRow/QiLabel
@onready var block_label: Label = $PlayerHUD/StatusRow/BlockLabel
@onready var turn_label: Label = $HiddenRefs/TurnLabel
@onready var card_hand: CardHand = $HandZone/CardHand
@onready var enemy_container: HBoxContainer = $EnemyZone/EnemyContainer
@onready var _hud_end_turn_button: Button = $HiddenRefs/EndTurnButton  # 숨김 처리, 실제는 플로팅
@onready var draw_pile_label: Label = $HiddenRefs/DrawPileLabel
@onready var discard_pile_label: Label = $HiddenRefs/DiscardPileLabel

# 플로팅 턴 종료 버튼 (HUD 외부, 화면 우측 하단)
var end_turn_button: Button = null

# 턴 표시 오버레이 (HUD 외부, 화면 상단)
var _turn_overlay_label: Label = null

# 덱 정보 오버레이 (HandArea 양쪽 하단)
var _draw_pile_overlay: PanelContainer = null
var _discard_pile_overlay: PanelContainer = null

var battle_manager: BattleManager

# 플레이어 상태이상 UI 컨테이너
var _player_status_container: HBoxContainer = null

# 적 UI 캐시 (index → {panel, name_label, hp_label, block_label, intent_label, status_hbox})
var _enemy_ui_cache: Dictionary = {}

# 상태이상 아이콘 캐시 (target → {effect_id → {panel, label}})
var _status_icon_cache: Dictionary = {}

# 적 UI 업데이트 배칭용 dirty flag
var _enemy_ui_dirty: bool = false

# 손패 UI 업데이트 배칭용 dirty flag (try_play_card 중 중복 rebuild 방지)
var _hand_ui_dirty: bool = false


func _ready() -> void:
	# v9: HandZone 클립 비활성화 — 카드가 위로 올라올 수 있도록
	var hand_zone := $HandZone as PanelContainer
	if hand_zone:
		hand_zone.clip_contents = false
		# CardHand도 클립 비활성화
		card_hand.clip_contents = false

	# VFX 매니저 초기화
	vfx = VfxManager.new()
	add_child(vfx)
	vfx.setup(self)

	# 매니저 초기화
	battle_manager = BattleManager.new()
	add_child(battle_manager)

	# 플로팅 UI 요소 생성
	_create_floating_ui()

	# 시그널 연결
	battle_manager.hand_changed.connect(_on_hand_changed)
	battle_manager.qi_changed.connect(_on_qi_changed)
	battle_manager.hp_changed.connect(_on_hp_changed)
	battle_manager.block_changed.connect(_on_block_changed)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.enemy_hp_changed.connect(_on_enemy_hp_changed)
	battle_manager.enemy_intent_shown.connect(_on_enemy_intent_shown)
	battle_manager.battle_ended.connect(_on_battle_ended)
	end_turn_button.pressed.connect(_on_end_turn_pressed)

	# CardHand 시그널 연결
	card_hand.card_played.connect(_on_card_played)
	card_hand.card_zoom_requested.connect(_on_card_zoom_requested)

	# 상태이상 시그널 연결
	battle_manager.status_effect_changed.connect(_on_status_effect_changed)

	# 패시브 스킬 시그널 연결
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

	# encounter_id가 비어있거나 로드 실패 시 현재 act 기반 랜덤 적 선택
	if enemy_data.is_empty():
		var is_elite := (rd.current_node_type == MapData.NodeType.ELITE)
		var act: int = rd.current_act
		var pool: Array[String]
		if is_elite:
			pool = DataLoader.get_elite_enemy_ids_for_act(act)
		else:
			pool = DataLoader.get_regular_enemy_ids_for_act(act)
		if not pool.is_empty():
			var fallback := DataLoader.get_enemy(pool[randi() % pool.size()])
			if not fallback.is_empty():
				enemy_data.append(fallback)
		# 최종 fallback: 풀이 비어있는 경우
		if enemy_data.is_empty():
			var last_resort := DataLoader.get_enemy("E001")
			if not last_resort.is_empty():
				enemy_data.append(last_resort)

	# 보스 전투 진입 시 유물 트리거 (만파식적 등)
	var is_boss := false
	is_boss = (rd.current_node_type == MapData.NodeType.BOSS)
	if is_boss:
		RelicManager.trigger_boss_enter()

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



func _create_deck_pill_label(font_color: Color) -> PanelContainer:
	## v10: 반투명 배경 pill 컨테이너 + 라벨 — 배경 위에서도 확실한 가시성
	var pill := PanelContainer.new()
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color(0.03, 0.02, 0.06, 0.85)
	pill_style.set_border_width_all(1)
	pill_style.border_color = Color(font_color.r, font_color.g, font_color.b, 0.4)
	pill_style.set_corner_radius_all(14)
	pill_style.content_margin_left = 14.0
	pill_style.content_margin_right = 14.0
	pill_style.content_margin_top = 4.0
	pill_style.content_margin_bottom = 4.0
	pill.add_theme_stylebox_override("panel", pill_style)

	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", font_color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(lbl)
	return pill


func _create_floating_ui() -> void:
	## 플로팅 UI 요소 생성: 턴 종료 버튼, 턴 표시, 덱 정보
	# 턴 종료 버튼 — 화면 우측, HandArea 상단에 플로팅
	# v8: 턴 종료 버튼 — 크고 눈에 띄는 배치, 넓은 터치 영역
	end_turn_button = Button.new()
	end_turn_button.text = tr("BATTLE_END_TURN")
	end_turn_button.custom_minimum_size = Vector2(200, 80)
	end_turn_button.add_theme_font_size_override("font_size", 30)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.78, 0.29, 0.19, 0.95)
	btn_style.set_border_width_all(2)
	btn_style.border_color = Color(0.76, 0.23, 0.13, 0.9)
	btn_style.set_corner_radius_all(18)
	btn_style.set_content_margin_all(12)
	btn_style.shadow_color = Color(0.78, 0.15, 0.10, 0.4)
	btn_style.shadow_size = 10
	btn_style.shadow_offset = Vector2(0, 4)
	end_turn_button.add_theme_stylebox_override("normal", btn_style)
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.88, 0.38, 0.25, 1.0)
	btn_hover.shadow_color = Color(0.76, 0.23, 0.13, 0.3)
	btn_hover.shadow_size = 12
	end_turn_button.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed := btn_style.duplicate()
	btn_pressed.bg_color = Color(0.60, 0.20, 0.12, 0.95)
	btn_pressed.shadow_size = 4
	end_turn_button.add_theme_stylebox_override("pressed", btn_pressed)
	end_turn_button.add_theme_color_override("font_color", Color(0.98, 0.94, 0.86))
	end_turn_button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.90))
	# v14 앵커: 액션바 우측 (55-61%)
	end_turn_button.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	end_turn_button.anchor_left = 0.60
	end_turn_button.anchor_right = 0.98
	end_turn_button.anchor_top = 0.55
	end_turn_button.anchor_bottom = 0.61
	end_turn_button.z_index = 12
	add_child(end_turn_button)

	# v12: 턴 표시 오버레이 — HUD 좌측 (노치 아래)
	_turn_overlay_label = Label.new()
	_turn_overlay_label.add_theme_font_size_override("font_size", 16)
	_turn_overlay_label.add_theme_color_override("font_color", Color(0.70, 0.64, 0.50, 0.85))
	_turn_overlay_label.anchor_left = 0.02
	_turn_overlay_label.anchor_top = 0.035
	_turn_overlay_label.anchor_right = 0.15
	_turn_overlay_label.anchor_bottom = 0.06
	_turn_overlay_label.z_index = 15
	add_child(_turn_overlay_label)

	# v14: 드로우/버림 더미 — 핸드존 좌/우 상단 (61% 라인)
	_draw_pile_overlay = _create_deck_pill_label(Color(0.45, 0.65, 0.90))
	_draw_pile_overlay.anchor_left = 0.02
	_draw_pile_overlay.anchor_top = 0.61
	_draw_pile_overlay.anchor_right = 0.18
	_draw_pile_overlay.anchor_bottom = 0.65
	_draw_pile_overlay.z_index = 12
	add_child(_draw_pile_overlay)

	_discard_pile_overlay = _create_deck_pill_label(Color(0.90, 0.50, 0.40))
	_discard_pile_overlay.anchor_left = 0.82
	_discard_pile_overlay.anchor_top = 0.61
	_discard_pile_overlay.anchor_right = 0.98
	_discard_pile_overlay.anchor_bottom = 0.65
	_discard_pile_overlay.z_index = 12
	add_child(_discard_pile_overlay)


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
	card_hand.update_hand(battle_manager.hand, battle_manager.current_qi, battle_manager)

	# 덱 정보 갱신
	draw_pile_label.text = tr("BATTLE_DRAW_PILE_FMT") % battle_manager.draw_pile.size()
	discard_pile_label.text = tr("BATTLE_DISCARD_PILE_FMT") % battle_manager.discard_pile.size()
	# 플로팅 덱 오버레이 갱신
	if _draw_pile_overlay:
		_draw_pile_overlay.get_child(0).text = tr("BATTLE_DRAW_PILE_FMT") % battle_manager.draw_pile.size()
	if _discard_pile_overlay:
		_discard_pile_overlay.get_child(0).text = tr("BATTLE_DISCARD_PILE_FMT") % battle_manager.discard_pile.size()


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
			cache["hp_label"].text = "%d/%d" % [enemy["current_hp"], enemy["max_hp"]]
			if cache.has("hp_bar") and is_instance_valid(cache["hp_bar"]):
				cache["hp_bar"].value = enemy["current_hp"]
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
			# v12: 적 패널 — 투명 배경, 배경 이미지가 보이게
			var panel_style := StyleBoxEmpty.new()
			panel.add_theme_stylebox_override("panel", panel_style)

			var vbox := VBoxContainer.new()
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox.add_theme_constant_override("separation", 1)

			var combat_type: String = enemy.get("combat_type", "")

			# v6: 적 일러스트 — TextureManager에서 SVG/placeholder 로드
			var enemy_id: String = enemy.get("id", "")
			var enemy_art := TextureRect.new()
			enemy_art.custom_minimum_size = Vector2(120, 100)
			enemy_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			enemy_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			enemy_art.texture = TextureManager.get_enemy_texture(enemy_id)
			# 보스/엘리트는 더 크게
			if combat_type == "boss":
				enemy_art.custom_minimum_size = Vector2(160, 130)
			elif combat_type == "elite":
				enemy_art.custom_minimum_size = Vector2(140, 110)

			# 적 이름
			var name_label := Label.new()
			name_label.text = enemy_name
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.add_theme_font_size_override("font_size", 22)
			# v6: 보스/엘리트 이름 색상 구분
			if combat_type == "boss":
				name_label.add_theme_color_override("font_color", Color(0.78, 0.29, 0.19, 0.95))
			elif combat_type == "elite":
				name_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91, 0.95))
			else:
				name_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.80))

			# HP 바 (ProgressBar + 오버레이 텍스트)
			var hp_container := Control.new()
			hp_container.custom_minimum_size = Vector2(180, 22)
			var hp_bar := ProgressBar.new()
			hp_bar.min_value = 0
			hp_bar.max_value = enemy["max_hp"]
			hp_bar.value = enemy["current_hp"]
			hp_bar.show_percentage = false
			hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
			hp_bar.add_theme_stylebox_override("background", _make_hp_bar_bg())
			hp_bar.add_theme_stylebox_override("fill", _make_hp_bar_fill(combat_type))
			hp_container.add_child(hp_bar)
			var hp_lbl := Label.new()
			hp_lbl.text = "%d/%d" % [enemy["current_hp"], enemy["max_hp"]]
			hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			hp_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			hp_lbl.add_theme_font_size_override("font_size", 16)
			hp_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
			hp_container.add_child(hp_lbl)

			# 인텐트 — 배경색 있는 라벨
			var intent_panel := PanelContainer.new()
			var intent_style := StyleBoxFlat.new()
			intent_style.bg_color = Color(0.1, 0.08, 0.15, 0.6)
			intent_style.set_corner_radius_all(4)
			intent_style.set_content_margin_all(3)
			intent_panel.add_theme_stylebox_override("panel", intent_style)
			var intent_label := Label.new()
			intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			intent_label.add_theme_font_size_override("font_size", 18)
			var intent := battle_manager._get_enemy_intent(i)
			intent_label.text = _format_intent(intent)
			intent_label.add_theme_color_override("font_color", _get_intent_color(intent))
			intent_panel.add_child(intent_label)

			var block_val: int = enemy.get("block", 0)
			var enemy_block_label := Label.new()
			enemy_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			enemy_block_label.add_theme_font_size_override("font_size", 18)
			enemy_block_label.text = tr("BATTLE_ENEMY_BLOCK_FMT") % block_val
			enemy_block_label.visible = block_val > 0

			var status_hbox := HBoxContainer.new()
			status_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			_build_status_icons(status_hbox, "enemy_%d" % i)

			vbox.add_child(enemy_art)
			vbox.add_child(name_label)
			vbox.add_child(hp_container)
			vbox.add_child(enemy_block_label)
			vbox.add_child(status_hbox)
			vbox.add_child(intent_panel)
			panel.add_child(vbox)
			panel.custom_minimum_size = Vector2(200, 0)
			enemy_container.add_child(panel)

			_enemy_ui_cache[i] = {
				"panel": panel,
				"name_label": name_label,
				"hp_label": hp_lbl,
				"hp_bar": hp_bar,
				"block_label": enemy_block_label,
				"intent_label": intent_label,
				"status_hbox": status_hbox,
			}


func _make_hp_bar_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.15, 0.1, 0.1, 0.8)
	s.set_corner_radius_all(4)
	return s


func _make_hp_bar_fill(combat_type: String) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	if combat_type == "boss":
		s.bg_color = Color(0.8, 0.2, 0.15)
	elif combat_type == "elite":
		s.bg_color = Color(0.76, 0.23, 0.13)
	else:
		s.bg_color = Color(0.6, 0.2, 0.2)
	s.set_corner_radius_all(4)
	return s


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
	# v5: 오방색 팔레트 기반 인텐트 색상 — 보라색 제거
	match intent_type:
		"attack", "attack_debuff":
			var dmg: int = intent.get("damage", 0)
			var times: int = intent.get("times", 1)
			var total := dmg * times
			if total >= 20:
				return Color(0.90, 0.20, 0.15)  # 고위협: 진한 적
			elif total >= 10:
				return Color(0.76, 0.23, 0.13)  # 중위협: 적 (#C23B22)
			else:
				return Color(0.85, 0.50, 0.40)  # 저위협: 연한 적
		"defend", "defend_buff", "buff_defend":
			return Color(0.18, 0.31, 0.56)     # 방어: 청 (#2E5090)
		"buff":
			return Color(0.76, 0.23, 0.13)     # 강화: 황 (#D4A017)
		"debuff":
			return Color(0.17, 0.17, 0.17)     # 디버프: 흑 (#2C2C2C)
		"special":
			return Color(0.76, 0.23, 0.13)     # 특수: 주황금
		_:
			return Color(0.55, 0.50, 0.42)     # 알 수 없음: 흐린 먹


# --- 시그널 핸들러 ---

func _on_hand_changed(_new_hand: Array[String]) -> void:
	_refresh_hand_ui()


func _on_qi_changed(current: int, max_val: int) -> void:
	# v9: 기를 간결한 오브 스타일로 표시
	qi_label.text = tr("BATTLE_QI_FMT") % [current, max_val]
	# 기력 부족 시 색상 변경
	if current == 0:
		qi_label.add_theme_color_override("font_color", Color(0.5, 0.4, 0.2, 0.7))
	else:
		qi_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91, 1.0))
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
	if _turn_overlay_label:
		_turn_overlay_label.text = tr("BATTLE_TURN_FMT") % turn
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
	hint_label.add_theme_font_size_override("font_size", 26)
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


func _init_relic_bar() -> void:
	var relic_bar := RelicBar.new()
	relic_bar.name = "RelicBar"
	# v12: 유물 바: HUD 우측 내부에 자연스럽게 배치
	relic_bar.anchor_left = 0.55
	relic_bar.anchor_right = 0.98
	relic_bar.anchor_top = 0.035
	relic_bar.anchor_bottom = 0.075
	relic_bar.z_index = 5
	relic_bar.alignment = BoxContainer.ALIGNMENT_END
	add_child(relic_bar)


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


func _on_passive_triggered(skill_name: String, description: String) -> void:
	# 패시브 발동 시 배너 형태로 표시 (PlayerHUD 아래, 여러 개 발동 시 세로 스택)
	var banner_height := 36.0
	var banner_gap := 4.0

	# 기존 패시브 배너 수를 세서 Y 오프셋 결정
	var existing_banners := 0
	for child in get_children():
		if child is ColorRect and child.has_meta("passive_banner"):
			existing_banners += 1

	# 노치 안전영역 확보: PlayerHUD 하단(화면 9%) 아래에 배치
	var vp_h := get_viewport().get_visible_rect().size.y
	var safe_top := vp_h * 0.09
	var y_offset := safe_top + banner_gap + existing_banners * (banner_height + banner_gap)

	var banner := ColorRect.new()
	banner.set_meta("passive_banner", true)
	banner.color = Color(0.1, 0.2, 0.1, 0.85)
	banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top = y_offset
	banner.offset_bottom = y_offset + banner_height
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 50
	add_child(banner)

	var popup := Label.new()
	popup.text = tr("PASSIVE_TRIGGER_FMT") % [skill_name, description]
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_theme_font_size_override("font_size", 22)
	popup.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	popup.clip_text = true
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
		$PlayerHUD/StatusRow.add_child(_player_status_container)
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
			label.add_theme_font_size_override("font_size", 26)

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
	$HandZone.visible = false

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
			vfx.flash_screen(self, Color(0.76, 0.23, 0.13, 0.3), 0.3)
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
	label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.91) if victory else Color(1, 0.3, 0.3))
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

