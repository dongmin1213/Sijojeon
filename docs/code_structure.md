# 시조전 코드 구조 가이드

> 최종 업데이트: Sprint 7 (2026-04-01)

---

## 1. 아키텍처 개요

```
타이틀 화면
    └→ 캐릭터 선택
           └→ 맵 탐색 (RunData 주도)
                  ├→ 전투 (BattleManager)
                  ├→ 이벤트 (선택지 텍스트)
                  ├→ 상점 (골드 지출)
                  ├→ 휴식 (HP 회복 / 카드 강화)
                  ├→ 막 전환 (ActTransition)
                  └→ 런 결과 (RunResult)
                         └→ 연대기 (메타 통계·업적)
```

**GameManager** 오토로드가 상태 머신으로 씬 전환을 주도한다.
**RunData** 리소스가 한 런의 모든 상태(덱, HP, 골드, 유물, 맵)를 담는다.

---

## 2. Autoload 싱글톤

`project.godot`에 등록된 전역 오토로드 목록.

| 파일 | class_name | 역할 |
|------|-----------|------|
| `scripts/autoload/game_manager.gd` | — | 게임 상태 머신, 씬 전환, RunData 생성 |
| `scripts/autoload/data_loader.gd` | — | JSON 데이터 로드·캐시 (카드·적·유물·스킬·이벤트) |
| `scripts/autoload/relic_manager.gd` | — | 유물 획득, 효과 트리거, 발동 횟수 추적 |
| `scripts/autoload/achievement_manager.gd` | — | 업적 로드, 달성 판정, 해금 신호 발생 |
| `scripts/autoload/save_manager.gd` | — | 런 세이브/로드, 메타 통계 영구 저장 |
| `scripts/autoload/audio_manager.gd` | — | BGM·SFX 재생 관리 |

### GameManager 상태 열거형

```gdscript
enum GameState {
    TITLE, CHARACTER_SELECT, CHRONICLE,
    MAP, BATTLE, EVENT, SHOP, REST, REWARD,
    ACT_TRANSITION, RUN_OVER, RUN_WIN,
}
```

---

## 3. 핵심 스크립트

### 3.1 BattleManager (`scripts/battle/battle_manager.gd`)

전투 흐름 전체를 제어하는 씬 노드.

**주요 상태 변수:**

| 변수 | 타입 | 설명 |
|------|------|------|
| `state` | `BattleState` | 현재 전투 단계 |
| `current_qi` / `max_qi` | int | 기 현재/최대 |
| `current_class_resource` | int | 직업 고유 자원 (무관: 기력, 문관: 학식) |
| `draw_pile` / `hand` / `discard_pile` | Array[String] | 카드 ID 배열 |
| `enemies` | Array[Dictionary] | 적 인스턴스 목록 |
| `sijo_system` | SijoSystem | 시조 슬롯 참조 |
| `status_effects` | StatusEffectManager | 상태이상 참조 |

**전투 상태 머신:**

```
BATTLE_START
    └→ PLAYER_TURN_START (카드 드로우, 기 충전)
           └→ PLAYER_ACTION (카드 플레이 대기)
                  └→ PLAYER_TURN_END (버린 패 처리)
                         └→ ENEMY_TURN (적 AI 행동)
                                └→ PLAYER_TURN_START (루프)
                                       ├→ BATTLE_WIN
                                       └→ BATTLE_LOSE
```

### 3.2 SijoSystem (`scripts/battle/sijo_system.gd`)

시조 리듬 슬롯 6개를 관리한다.

- 슬롯 구조: `[초장3, 초장4, 중장3, 중장4, 종장3, 종장4]`
- 카드의 `beat` 값(3 또는 4)이 순서대로 일치해야 채워짐
- 완성 시: 마지막 카드 효과 ×2 + 기 1 회복 + 카드 1장 드로우

### 3.3 StatusEffectManager (`scripts/battle/status_effect_manager.gd`)

플레이어·적 양측의 버프/디버프/DoT를 관리한다.

**상태이상 카테고리:**

| 종류 | 목록 |
|------|------|
| DoT | 독, 화상, 출혈, 사망표식 |
| 디버프 | 약화(-25% 공격), 취약(+25% 받는 피해), 냉기(드로우 -1), 사망선고 |
| 버프 | 힘(strength), 가시(thorns), 갑주(영구 방어막) |

### 3.4 MapGenerator (`scripts/map/map_generator.gd`)

절차적 맵 생성 (Slay the Spire 스타일).

**막별 설정:**

| 막 | 배경 | 행 수 | 노드 수 |
|----|------|-------|---------|
| 1 | 한양 | 7 | 15~17 |
| 2 | 지리산 | 8 | 17~20 |
| 3 | 경복궁 | 8 | 17~20 |

**노드 타입:** BATTLE, EVENT, SHOP, REST, ELITE, BOSS
행 위치에 따른 가중치로 노드 타입 결정. 3막으로 갈수록 전투/정예 비중 증가.

### 3.5 RunData (`scripts/data/run_data.gd`)

한 런의 상태 전체를 담는 `Resource`.

```gdscript
@export var character_id: String       # 직업 ID
@export var current_hp / max_hp: int   # HP
@export var gold: int                  # 골드 (시작: 99)
@export var qi_per_turn: int           # 턴당 기
@export var current_act: int           # 현재 막 (1~3)
@export var deck: Array[String]        # 카드 ID 목록
@export var relics: Array[String]      # 유물 ID 목록
@export var upgraded_cards: Array[String]  # 강화된 카드 ID
var run_map: MapData.RunMap            # 현재 맵
var previous_maps: Array              # 이전 막 맵 보존
```

---

## 4. 씬 구성

### 씬 목록

| 씬 경로 | 설명 |
|---------|------|
| `scenes/title/title_screen.tscn` | 타이틀 (새 게임 / 연대기) |
| `scenes/character_select/character_select.tscn` | 직업 선택, 해금 조건 표시 |
| `scenes/map/run_map.tscn` | 맵 탐색 (노드 클릭 이동) |
| `scenes/battle/battle.tscn` | 전투 (BattleManager 포함) |
| `scenes/event/event.tscn` | 랜덤 이벤트 선택지 |
| `scenes/shop/shop.tscn` | 상점 (카드 구매/제거, 유물) |
| `scenes/rest/rest.tscn` | 휴식 거점 (HP +30% 또는 카드 강화) |
| `scenes/reward/reward.tscn` | 전투 후 보상 (카드 3선택) |
| `scenes/act_transition/act_transition.tscn` | 막 전환 연출 |
| `scenes/run_result/run_result.tscn` | 런 결과 (클리어/사망 통계) |
| `scenes/chronicle/chronicle.tscn` | 연대기 (메타 통계, 업적 목록) |

### 카드 UI (`scenes/ui/`)

- `card_ui.tscn` / `card_ui.gd` — 개별 카드 위젯 (이름, 코스트, 타입, 효과 텍스트)
- `card_hand.tscn` / `card_hand.gd` — 손패 컨테이너 (부채꼴 배치, 드래그/클릭 플레이)

---

## 5. 데이터 흐름

```
data/*.json
    └─ DataLoader (오토로드, 캐시)
           ├─ BattleManager.card_data  → 카드 효과 계산
           ├─ BattleManager.enemy_data → 적 AI 스케줄
           ├─ RelicManager.get_relic   → 유물 효과 트리거
           └─ EventScene.load_event    → 이벤트 텍스트·선택지
```

---

## 6. 저장 시스템

**SaveManager** 는 두 가지 데이터를 관리한다.

| 데이터 | 내용 | 영속성 |
|--------|------|--------|
| 런 세이브 | RunData 직렬화 | 런 종료 시 삭제 |
| 메타 통계 | 총 런·승리·처치 수 등 | 영구 보존 |

메타 통계 키 예시: `total_runs`, `total_victories`, `total_kills`, `mugwan_act1_clear`

**AchievementManager** 는 메타 통계를 읽어 업적 달성 여부를 판정하고 `achievement_unlocked` 신호를 발생시킨다.

---

## 7. 렌더러 설정

- **렌더러:** GL Compatibility (OpenGL ES 3.0)
- **이유:** Vulkan 미지원 Android 에뮬레이터 및 Galaxy Z Flip 3 호환
- **기준 해상도:** 1080 × 1920 (세로 Portrait)
- **스트레치 모드:** `canvas_items` (UI 포함 전체 스케일링)
- **비율 유지:** `keep_width` (가로폭 고정, 세로 여백 허용)
- **방향:** `orientation = 1` (세로 고정)
- **멀티 해상도 대응:** Sprint 7 작업 (Galaxy Z Flip 3 등 다양한 종횡비 지원)

---

## 8. 의존 관계 요약

```
GameManager
  ├── RunData (상태 보관)
  ├── SaveManager (저장/로드)
  └── DataLoader (데이터 접근)

BattleManager
  ├── SijoSystem
  ├── StatusEffectManager
  ├── RelicManager (효과 트리거)
  └── DataLoader (카드·적 데이터)

CharacterSelect
  └── DataLoader (직업 정보, 해금 조건)

AchievementManager
  └── SaveManager (메타 통계)
```
