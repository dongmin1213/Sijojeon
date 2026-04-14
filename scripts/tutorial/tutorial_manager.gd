class_name TutorialManager
extends Node

## 튜토리얼 전투를 관리하는 매니저.
## 전투 씬 위에 오버레이를 띄우고, 단계별로 플레이어를 안내한다.
## 전투 흐름(BattleManager)과 연동하여 특정 액션 시 다음 단계로 진행.

enum TutorialStep {
	INTRO,                  # 환영 메시지
	EXPLAIN_ENEMY,          # 적 소개
	EXPLAIN_HP_QI,          # HP/기 설명
	EXPLAIN_HAND,           # 손패 설명
	PLAY_FIRST_CARD,        # 첫 카드 사용 유도
	EXPLAIN_SIJO,           # 시조 시스템 설명
	EXPLAIN_SIJO_BEAT,      # 음보(beat) 매칭 설명
	PLAY_SIJO_CARD,         # 시조 슬롯에 맞는 카드 사용 유도
	EXPLAIN_DEFENSE,        # 방어 카드 설명
	PLAY_DEFENSE_CARD,      # 방어 카드 사용 유도
	EXPLAIN_END_TURN,       # 턴 종료 설명
	END_TURN_ACTION,        # 턴 종료 유도
	EXPLAIN_ENEMY_TURN,     # 적 턴 설명
	TURN2_INTRO,            # 2턴 시작 안내
	FREE_PLAY,              # 자유 플레이 (전투 종료까지)
	EXPLAIN_REWARD,         # 보상 설명
	EXPLAIN_DECKBUILDING,   # 덱빌딩 설명
	COMPLETE,               # 튜토리얼 완료
}

var current_step: TutorialStep = TutorialStep.INTRO
var overlay: TutorialOverlay = null
var battle_scene: Control = null  # 전투 씬 참조
var battle_manager: BattleManager = null
var sijo_system: SijoSystem = null
var _skipped: bool = false

signal tutorial_completed
signal tutorial_skipped


func start(p_battle_scene: Control, p_battle_manager: BattleManager, p_sijo_system: SijoSystem) -> void:
	battle_scene = p_battle_scene
	battle_manager = p_battle_manager
	sijo_system = p_sijo_system

	# 오버레이 생성
	overlay = TutorialOverlay.new()
	battle_scene.add_child(overlay)
	overlay.step_acknowledged.connect(_advance_step)
	overlay.connect_skip(_on_skip)

	# 전투 시그널 연결
	battle_manager.hand_changed.connect(_on_hand_changed)
	battle_manager.state_changed.connect(_on_battle_state_changed)
	battle_manager.turn_started.connect(_on_turn_started)
	battle_manager.battle_ended.connect(_on_battle_ended)
	sijo_system.slot_filled.connect(_on_sijo_slot_filled)

	# 첫 단계 시작
	current_step = TutorialStep.INTRO
	_show_current_step()


func _show_current_step() -> void:
	if _skipped:
		return

	match current_step:
		TutorialStep.INTRO:
			overlay.show_message(tr("TUTORIAL_MSG_INTRO"))

		TutorialStep.EXPLAIN_ENEMY:
			var enemy_area := battle_scene.get_node_or_null("EnemyZone")
			if enemy_area:
				var rect := Rect2(enemy_area.global_position, enemy_area.size)
				overlay.highlight_area(rect, tr("TUTORIAL_MSG_ENEMY"), "down")
			else:
				overlay.show_message(tr("TUTORIAL_MSG_ENEMY_SHORT"))

		TutorialStep.EXPLAIN_HP_QI:
			var player_info := battle_scene.get_node_or_null("PlayerHUD/StatusRow")
			if player_info:
				var rect := Rect2(player_info.global_position, player_info.size)
				overlay.highlight_area(rect, tr("TUTORIAL_MSG_HP_QI"), "down")
			else:
				overlay.show_message(tr("TUTORIAL_MSG_HP_QI_SHORT"))

		TutorialStep.EXPLAIN_HAND:
			var hand_area := battle_scene.get_node_or_null("HandZone")
			if hand_area:
				var rect := Rect2(hand_area.global_position, hand_area.size)
				overlay.highlight_area(rect, tr("TUTORIAL_MSG_HAND"), "up")
			else:
				overlay.show_message(tr("TUTORIAL_MSG_HAND_SHORT"))

		TutorialStep.PLAY_FIRST_CARD:
			overlay.show_message(tr("TUTORIAL_MSG_PLAY_FIRST"), true)

		TutorialStep.EXPLAIN_SIJO:
			var sijo_area := battle_scene.get_node_or_null("SijoBar")
			if sijo_area:
				var rect := Rect2(sijo_area.global_position, sijo_area.size)
				overlay.highlight_area(rect, tr("TUTORIAL_MSG_SIJO"), "down")
			else:
				overlay.show_message(tr("TUTORIAL_MSG_SIJO_SHORT"))

		TutorialStep.EXPLAIN_SIJO_BEAT:
			overlay.show_message(tr("TUTORIAL_MSG_SIJO_BEAT"))

		TutorialStep.PLAY_SIJO_CARD:
			var next_beat := sijo_system.get_next_required_beat()
			if next_beat > 0:
				overlay.show_message(tr("TUTORIAL_MSG_PLAY_SIJO_FMT") % next_beat, true)
			else:
				_advance_step()

		TutorialStep.EXPLAIN_DEFENSE:
			overlay.show_message(tr("TUTORIAL_MSG_DEFENSE"), true)

		TutorialStep.PLAY_DEFENSE_CARD:
			# 방어 카드 사용 유도 (없으면 스킵)
			_advance_step()

		TutorialStep.EXPLAIN_END_TURN:
			var end_btn: Button = battle_scene.end_turn_button if battle_scene.end_turn_button else battle_scene.get_node_or_null("HiddenRefs/EndTurnButton")
			if end_btn:
				var rect := Rect2(end_btn.global_position, end_btn.size)
				overlay.highlight_area(rect, tr("TUTORIAL_MSG_END_TURN"), "left", true)
			else:
				overlay.show_message(tr("TUTORIAL_MSG_END_TURN_SHORT"), true)

		TutorialStep.END_TURN_ACTION:
			# 턴 종료 대기 — _on_battle_state_changed에서 처리
			pass

		TutorialStep.EXPLAIN_ENEMY_TURN:
			overlay.show_message(tr("TUTORIAL_MSG_ENEMY_TURN"), true)

		TutorialStep.TURN2_INTRO:
			overlay.show_message(tr("TUTORIAL_MSG_TURN2"))

		TutorialStep.FREE_PLAY:
			overlay.hide_overlay()

		TutorialStep.EXPLAIN_REWARD:
			overlay.show_message(tr("TUTORIAL_MSG_REWARD"))

		TutorialStep.EXPLAIN_DECKBUILDING:
			overlay.show_message(tr("TUTORIAL_MSG_DECKBUILDING"))

		TutorialStep.COMPLETE:
			# 튜토리얼 완료 플래그 저장
			var meta := SaveManager.load_meta()
			meta["tutorial_completed"] = true
			SaveManager.save_meta(meta)

			if overlay:
				overlay.cleanup()
				overlay = null
			tutorial_completed.emit()


func _advance_step() -> void:
	if _skipped:
		return
	current_step = (current_step + 1) as TutorialStep
	_show_current_step()


func _on_skip() -> void:
	_skipped = true
	var meta := SaveManager.load_meta()
	meta["tutorial_completed"] = true
	SaveManager.save_meta(meta)

	if overlay:
		overlay.cleanup()
		overlay = null
	tutorial_skipped.emit()


func _on_hand_changed(_new_hand: Array[String]) -> void:
	# 카드가 사용되면(패가 줄면) 해당 단계에서 진행
	match current_step:
		TutorialStep.PLAY_FIRST_CARD:
			overlay.acknowledge_action()
		TutorialStep.PLAY_SIJO_CARD:
			overlay.acknowledge_action()
		TutorialStep.EXPLAIN_DEFENSE:
			overlay.acknowledge_action()


func _on_battle_state_changed(new_state: BattleManager.BattleState) -> void:
	match current_step:
		TutorialStep.END_TURN_ACTION, TutorialStep.EXPLAIN_END_TURN:
			if new_state == BattleManager.BattleState.ENEMY_TURN:
				current_step = TutorialStep.EXPLAIN_ENEMY_TURN
				# 적 턴 끝나고 보여주기 위해 약간 지연
				var timer := battle_scene.get_tree().create_timer(0.5)
				await timer.timeout
				if not _skipped:
					_show_current_step()
		TutorialStep.EXPLAIN_ENEMY_TURN:
			if new_state == BattleManager.BattleState.PLAYER_TURN_START:
				overlay.acknowledge_action()


func _on_turn_started(turn: int) -> void:
	if turn == 2 and current_step == TutorialStep.TURN2_INTRO:
		_show_current_step()


func _on_sijo_slot_filled(_index: int, _card_id: String, _jang_name: String, _beat_matched: bool) -> void:
	# 시조 슬롯이 채워지면 진행
	if current_step == TutorialStep.PLAY_SIJO_CARD:
		overlay.acknowledge_action()


func _on_battle_ended(victory: bool) -> void:
	if _skipped:
		return
	if victory:
		current_step = TutorialStep.EXPLAIN_REWARD
		_show_current_step()
	else:
		# 패배해도 튜토리얼은 완료 처리
		current_step = TutorialStep.COMPLETE
		_show_current_step()


## 튜토리얼이 이미 완료되었는지 확인
static func is_tutorial_completed() -> bool:
	var meta := SaveManager.load_meta()
	return meta.get("tutorial_completed", false)
