class_name TutorialManager
extends Node

## 튜토리얼 전투를 관리하는 매니저.
## 전투 씬 위에 오버레이를 띄우고, 단계별로 플레이어를 안내한다.
## 전투 흐름(BattleManager)과 연동하여 특정 액션 시 다음 단계로 진행.

enum TutorialStep {
	INTRO,                  # 환영 메시지
	EXPLAIN_ENEMY,          # 적 소개
	EXPLAIN_HP_QI,          # HP/기(氣) 설명
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
			overlay.show_message(
				"시조전에 오신 것을 환영합니다!\n\n" +
				"이 튜토리얼에서 전투의 기본을 배우게 됩니다.\n" +
				"카드를 사용하여 적을 물리치는 방법을 알아보겠습니다."
			)

		TutorialStep.EXPLAIN_ENEMY:
			var enemy_area := battle_scene.get_node_or_null("EnemyArea")
			if enemy_area:
				var rect := Rect2(enemy_area.global_position, enemy_area.size)
				overlay.highlight_area(rect,
					"앞에 적이 나타났습니다!\n\n" +
					"적의 HP와 다음 행동(의도)이 표시됩니다.\n" +
					"적의 의도를 파악하고 대응하세요.",
					"down"
				)
			else:
				overlay.show_message("적이 나타났습니다! 적의 HP와 의도를 확인하세요.")

		TutorialStep.EXPLAIN_HP_QI:
			var player_info := battle_scene.get_node_or_null("BattleHUD/PlayerInfo")
			if player_info:
				var rect := Rect2(player_info.global_position, player_info.size)
				overlay.highlight_area(rect,
					"HP와 氣(기)가 표시됩니다.\n\n" +
					"• HP: 체력이 0이 되면 패배합니다\n" +
					"• 氣: 카드를 사용할 때 소비됩니다 (매 턴 회복)\n" +
					"• 방어: 받는 피해를 줄여줍니다 (매 턴 초기화)",
					"down"
				)
			else:
				overlay.show_message(
					"HP: 체력이 0이면 패배\n氣: 카드 사용 비용 (매 턴 회복)\n방어: 피해 감소 (매 턴 초기화)"
				)

		TutorialStep.EXPLAIN_HAND:
			var hand_area := battle_scene.get_node_or_null("HandArea")
			if hand_area:
				var rect := Rect2(hand_area.global_position, hand_area.size)
				overlay.highlight_area(rect,
					"이것이 당신의 손패입니다.\n\n" +
					"카드를 클릭하거나 위로 드래그하여 사용할 수 있습니다.\n" +
					"각 카드에는 비용(氣)과 음보(拍)가 표시됩니다.",
					"up"
				)
			else:
				overlay.show_message("손패의 카드를 클릭하거나 드래그하여 사용합니다.")

		TutorialStep.PLAY_FIRST_CARD:
			overlay.show_message(
				"이제 카드를 한 장 사용해보세요!\n\n" +
				"카드를 클릭한 후 적을 클릭하거나,\n" +
				"카드를 위로 드래그하면 됩니다.",
				true  # 액션 대기
			)

		TutorialStep.EXPLAIN_SIJO:
			var sijo_area := battle_scene.get_node_or_null("SijoArea")
			if sijo_area:
				var rect := Rect2(sijo_area.global_position, sijo_area.size)
				overlay.highlight_area(rect,
					"시조(時調) 리듬 시스템입니다!\n\n" +
					"6개의 슬롯이 있으며, [3,4,3,4,3,4] 패턴입니다.\n" +
					"카드의 음보(拍)가 다음 슬롯의 숫자와 일치하면 슬롯이 채워집니다.",
					"down"
				)
			else:
				overlay.show_message("시조 시스템: 6슬롯 [3,4,3,4,3,4] 패턴. 카드 음보가 일치하면 채워집니다.")

		TutorialStep.EXPLAIN_SIJO_BEAT:
			overlay.show_message(
				"시조 보상:\n\n" +
				"• 초장 완성 (3/6): 氣 +1 회복\n" +
				"• 중장 완성 (4/6): 카드 1장 추가 드로우\n" +
				"• 시조 완성 (6/6): 마지막 카드 효과 2배 + 氣 +1 + 카드 드로우!\n\n" +
				"손패에서 음보가 일치하는 카드는 밝게 표시됩니다."
			)

		TutorialStep.PLAY_SIJO_CARD:
			var next_beat := sijo_system.get_next_required_beat()
			if next_beat > 0:
				overlay.show_message(
					"다음 시조 슬롯에 필요한 음보는 [%d]입니다.\n\n" % next_beat +
					"음보가 일치하는 카드를 사용해보세요!\n" +
					"(일치하는 카드는 밝게 표시됩니다)",
					true
				)
			else:
				_advance_step()

		TutorialStep.EXPLAIN_DEFENSE:
			overlay.show_message(
				"방어 카드를 사용하면 방어도를 얻습니다.\n\n" +
				"방어도는 적의 공격 피해를 흡수합니다.\n" +
				"단, 방어도는 매 턴 초기화되므로 적의 공격 전에 사용하세요!",
				true
			)

		TutorialStep.PLAY_DEFENSE_CARD:
			# 방어 카드 사용 유도 (없으면 스킵)
			_advance_step()

		TutorialStep.EXPLAIN_END_TURN:
			var end_btn := battle_scene.get_node_or_null("BattleHUD/EndTurnButton")
			if end_btn:
				var rect := Rect2(end_btn.global_position, end_btn.size)
				overlay.highlight_area(rect,
					"카드를 다 사용했으면 '턴 종료' 버튼을 눌러주세요.\n\n" +
					"남은 氣가 있어도 턴을 종료할 수 있습니다.\n" +
					"전략적으로 氣를 아끼는 것도 중요합니다!",
					"left",
					true
				)
			else:
				overlay.show_message("턴 종료 버튼을 눌러 적에게 턴을 넘기세요.", true)

		TutorialStep.END_TURN_ACTION:
			# 턴 종료 대기 — _on_battle_state_changed에서 처리
			pass

		TutorialStep.EXPLAIN_ENEMY_TURN:
			overlay.show_message(
				"적의 턴입니다!\n\n" +
				"적은 표시된 의도대로 행동합니다.\n" +
				"공격을 받으면 방어도부터 소모되고, 남은 피해가 HP를 깎습니다.",
				true
			)

		TutorialStep.TURN2_INTRO:
			overlay.show_message(
				"잘하셨습니다! 2턴이 시작되었습니다.\n\n" +
				"이제부터 자유롭게 전투를 진행하세요.\n" +
				"시조 슬롯을 채우며 적을 물리쳐보세요!",
			)

		TutorialStep.FREE_PLAY:
			overlay.hide_overlay()

		TutorialStep.EXPLAIN_REWARD:
			overlay.show_message(
				"축하합니다! 첫 전투에서 승리했습니다!\n\n" +
				"전투 후에는 보상으로 금화와 새 카드를 획득할 수 있습니다.\n" +
				"강력한 카드를 선택하여 덱을 강화하세요."
			)

		TutorialStep.EXPLAIN_DECKBUILDING:
			overlay.show_message(
				"덱빌딩 팁:\n\n" +
				"• 카드를 많이 넣으면 핵심 카드를 뽑기 어려워집니다\n" +
				"• 상점에서 불필요한 카드를 제거할 수 있습니다\n" +
				"• 시조 패턴에 맞는 음보(3,4) 비율을 고려하세요\n\n" +
				"이제 본격적인 모험을 시작하세요!"
			)

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


func _on_sijo_slot_filled(_index: int, _card_id: String, _jang_name: String) -> void:
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
