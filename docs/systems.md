# 시조전 — 시스템 API 레퍼런스

> 버전: 0.3 | 최종 업데이트: 2026-04-15
> 아키텍처 개요 및 씬 목록은 `code_structure.md` 참조.
> 삭제된 시스템: 시조, 당파, 신분, 시상, 과거시험, 서사/엔딩, 연대기, 민심, 액티브 스킬, 클래스 고유 자원, 병사 토큰, 콤보, 카드 비트값

---

## GameManager

**파일:** `scripts/autoload/game_manager.gd` (Autoload Singleton)

### 주요 변수

| 변수 | 타입 | 설명 |
|------|------|------|
| `current_state` | GameState | 현재 게임 상태 |
| `run_data` | RunData | 현재 런 상태 (null이면 런 없음) |

### 시그널

| 시그널 | 설명 |
|--------|------|
| `state_changed(new_state: GameState)` | 상태 전이 시 발생 |

### 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `start_new_run(character_id)` | 새 런 시작. RunData 초기화, 덱/HP/에너지 설정 후 MAP 전환 |
| `load_saved_run` | SaveManager에서 런 데이터 복원. 성공 시 true 반환 |
| `end_run(victory)` | 런 종료. victory=true면 RUN_WIN, false면 RUN_OVER. 세이브 삭제 |
| `save_current_run` | 현재 run_data를 SaveManager를 통해 저장 |
| `change_state(new_state)` | 상태 전이 + 해당 씬으로 전환 |
| `advance_floor` | `run_data.current_floor += 1` |
| `advance_act` | act 증가, floor 초기화, visited_nodes 초기화 |

---

## BattleManager

**파일:** `scripts/battle/battle_manager.gd` (씬에 추가)

### 주요 변수

| 변수 | 타입 | 설명 |
|------|------|------|
| `current_energy` / `max_energy` | int | 에너지 현재/최대. 턴 시작 시 max_energy로 회복, 이월 없음 |
| `draw_pile` / `hand` / `discard_pile` / `exhaust_pile` | Array[String] | 카드 더미 (String = card_id) |
| `player_hp` / `player_max_hp` / `player_block` | int | 플레이어 HP와 방어도 |
| `enemies` | Array[Dictionary] | 적 데이터 배열 |
| `status_effects` | StatusEffectManager | 상태이상 관리자 (자동 생성) |

### 상수

| 상수 | 값 | 설명 |
|------|----|------|
| `HAND_SIZE` | 5 | 기본 드로우 장 수 |
| `STARTING_ENERGY` | 3 | 턴당 에너지 기본값 |

### 시그널

| 시그널 | 설명 |
|--------|------|
| `state_changed(new_state)` | |
| `energy_changed(current, max_val)` | |
| `hand_changed(new_hand)` | |
| `block_changed(new_block)` | |
| `hp_changed(current, max_val)` | |
| `card_drawn(card_id)` | |
| `turn_started(turn)` | |
| `enemy_intent_shown(enemy_index, intent)` | |
| `enemy_hp_changed(enemy_index, current, max_val)` | |
| `battle_ended(victory)` | |
| `status_effect_changed(target, effect_id, stacks)` | |
| `dot_damage_dealt(target, effect_id, amount)` | |

### 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `start_battle(deck, enemy_data, hp, max_hp, energy, character_id)` | 전투 시작 |
| `try_play_card(hand_index, target_enemy_index)` | 에너지 확인 후 카드 효과 적용. 성공 시 true |
| `end_player_turn` | 손패 버리고 적 턴 실행 |
| `draw_cards(count)` | 드로우. 파일 소진 시 discard 재셔플 |
| `take_damage(amount)` | 취약 수정 -> 방어도 차감 -> HP 감소 |
| `gain_block(amount)` | 방어도 획득. 출혈 상태이면 추가 피해 처리 |
| `deal_damage_to_enemy(enemy_index, amount)` | strength/약화 + 취약 보정 후 피해 적용 |
| `can_play_card(card)` | 에너지 충분 여부 확인 |

---

## StatusEffectManager

**파일:** `scripts/battle/status_effect_manager.gd` (BattleManager가 자동 생성)

target 키: `"player"`, `"enemy_0"`, `"enemy_1"`, ...

### 시그널

| 시그널 | 설명 |
|--------|------|
| `effect_applied(target, effect_id, stacks)` | |
| `effect_removed(target, effect_id)` | |
| `effect_triggered(target, effect_id, value)` | DoT 피해 발생, 사망 카운트다운 발동 등 |

### 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `apply_effect(target, effect_id, stacks)` | 스택 누적 적용 |
| `remove_effect(target, effect_id)` | 효과 제거 |
| `process_turn_start(target)` | DoT 처리 + 갑주 반환. `{damage: int, armor: int}` 반환 |
| `process_turn_end(target)` | 취약/냉기 등 턴 기반 디버프 기간 감소 |
| `calculate_outgoing_damage(attacker, base_damage)` | strength 보정 + 약화 -25% |
| `calculate_incoming_damage(defender, damage)` | 취약 +25% |
| `calculate_bleed_on_block(target, block_amount)` | 출혈 상태에서 방어도 획득 시 추가 피해 |
| `get_thorns_damage(defender)` | 가시 반사 피해량 |
| `get_draw_modifier(target)` | 냉기 시 -1 등 드로우 수 수정자 |

### 상태이상 전체 목록

| ID | 타입 | 설명 |
|----|------|------|
| 독 | DOT | 턴 시작 시 N 피해, 매 턴 1씩 감소. 0이면 소멸 |
| 화상 | DOT | 턴 시작 시 N 피해, 매 턴 1씩 감소 |
| 출혈 | DOT | 턴 시작 시 N 피해. 방어도 획득 시 스택만큼 추가 피해 |
| death_mark | DOT | 매 턴 5 피해, 스택 1씩 감소 |
| 약화 | DEBUFF | 다음 공격 피해 25% 감소. 1회 발동 후 소멸 |
| 취약 | DEBUFF | 받는 피해 25% 증가. 턴 종료 시 1 감소 |
| 냉기 | DEBUFF | 드로우 1장 감소. 1턴 후 자동 해제 |
| death_countdown | DEBUFF | N턴 후 HP 40% 강제 감소. 매 턴 1씩 감소 |
| strength | BUFF | 공격 피해 +N (영구) |
| thorns | BUFF | 피격 시 공격자에게 N 피해 반사 (영구) |
| 갑주 | BUFF | 턴 시작 시 사라지지 않는 방어막 (영구) |

---

## StatusEffectData

**파일:** `scripts/data/status_effect_data.gd` (class_name RefCounted)

각 상태이상의 UI 메타데이터(이름, 아이콘, 색상, 설명)를 정의하는 정적 레지스트리.

| 메서드 | 설명 |
|--------|------|
| `get_definition(effect_id)` | (static) effect_id에 해당하는 StatusEffectData 반환 |
| `get_all_definitions` | (static) 전체 레지스트리 Dictionary 반환 |

---

## CardData

**파일:** `scripts/data/card_data.gd` (class_name Resource)

JSON에서 파싱된 카드 한 장의 데이터. DataLoader가 `from_dict`로 생성.

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | String | 카드 고유 ID |
| `name_ko` / `name_romanized` | String | 카드 이름 |
| `cost` | int | 에너지 소비량 |
| `type` | String | attack, skill, defense, power, status, curse |
| `subtypes` | Array[String] | 부가 타입 |
| `rarity` | int | 1~5 희귀도 |
| `pool` | String | common, dosa, mugwan 등 |
| `effect` / `effect_upgraded` | String | 카드 효과 텍스트 |
| `damage` / `block_value` / `draw_count` / `energy_gain` | int | 수치 효과 |
| `is_aoe` | bool | 광역 피해 여부 |

---

## CardHand UI

**파일:** `scenes/ui/card_hand.gd + card_hand.tscn` (class_name Control)

### 레이아웃 파라미터

| 파라미터 | 기본값 | 설명 |
|----------|--------|------|
| `fan_spread_degrees` | 5.0 | 카드 간 회전 각도 |
| `fan_y_curve` | 20.0 | 부채꼴 높이 커브 |
| `card_spacing` | 145.0 | 카드 간 가로 간격 |
| `hover_lift` | 30.0 | 호버 시 위로 올라가는 높이 |
| `select_lift` | 50.0 | 선택 시 위로 올라가는 높이 |

### 인터랙션 모드

- **클릭 선택:** 카드 클릭 -> 선택됨. 두 번째 클릭 또는 적 클릭 -> 플레이.
- **드래그 플레이:** 카드를 드래그하여 플레이 존 위에 드롭 -> 플레이.

### 시그널

| 시그널 | 설명 |
|--------|------|
| `card_played(hand_index, target_enemy_index)` | battle.gd에서 수신하여 BattleManager.try_play_card 호출 |

| 메서드 | 설명 |
|--------|------|
| `update_hand(hand_ids, energy, bm)` | 손패 전체 업데이트 |

---

## DataLoader

**파일:** `scripts/autoload/data_loader.gd` (Autoload Singleton)

### 데이터 소스

| 경로 | 대상 | 설명 |
|------|------|------|
| `data/cards/*.json` | `_cards: Dictionary` | id -> CardData 매핑 |
| `data/enemies/act1.json` | `_enemies: Dictionary` | id -> Dictionary |
| `data/enemies/act1_boss.json` | `_enemies: Dictionary` | 보스 데이터 |

### 스타터 덱

| 직업 | 카드 구성 |
|------|----------|
| 의적 | 베기(C001)x5, 수호(C002)x5 (총 10장) |
| 선비 | 베기(C001)x5, 수호(C002)x5 (총 10장) |

> 스타터 덱은 Slay the Spire 방식으로 표준화. 직업 전용 카드는 보상/상점에서 획득.

### 주요 메서드

| 메서드 | 설명 |
|--------|------|
| `get_card(card_id)` | 캐시에서 CardData 반환. 없으면 null |
| `get_enemy(enemy_id)` | 적 데이터 Dictionary 반환 |
| `get_starter_deck(character_id)` | 스타터 덱 카드 ID 배열 반환 |

---

## RunData

**파일:** `scripts/data/run_data.gd` (class_name Resource)

`to_dict` / `from_dict`로 직렬화.

| 필드 | 타입 | 설명 |
|------|------|------|
| `character_id` | String | 직업 ID |
| `current_hp` / `max_hp` | int | 플레이어 HP |
| `gold` | int | 시작 골드 99 |
| `energy_per_turn` | int | 턴당 에너지. 기본 3 |
| `current_act` / `current_floor` | int | 현재 막/층 |
| `deck` | Array[String] | 현재 덱 카드 ID 목록 |
| `relics` | Array[String] | 획득한 유물 ID 목록 |
| `map_seed` | int | 맵 생성 시드 |
| `visited_nodes` | Array[int] | 방문한 맵 노드 인덱스 |
