# 시조전 (Sijojeon)

조선시대 배경의 모바일 덱빌딩 로그라이크. Godot 4 + GDScript.

**핵심 메카닉:** 카드를 플레이하여 시조 리듬 슬롯(초장-중장-종장)을 채우면 시조 완성 보너스 발동.

---

## 실행 방법

**요구사항:** Godot 4.3+

```bash
# Godot Editor에서 프로젝트 열기
godot project.godot

# 또는 CLI로 타이틀 화면부터 실행
godot --path . scenes/title/title_screen.tscn
```

**Android 빌드:** Godot Editor → Project → Export → Android (`export_presets.cfg` 참조)

> 렌더러: GL Compatibility (OpenGL ES 3.0) — Vulkan 미지원 에뮬레이터/기기 호환

---

## 플레이 방법

1. **타이틀 화면** → 새 게임 시작
2. **캐릭터 선택** → 직업 선택 후 런 시작 (의적 기본 해금, 선비/의녀/무당/기생/승병 순차 해금)
3. **맵 탐색** → 전투(⚔), 이벤트(?), 상점(🏪), 휴식(💤), 정예(★), 보스(💀) 노드 탐색
4. **전투** → 카드 드래그/클릭으로 플레이. 시조 슬롯을 채워 완성 보너스 발동
5. **보상 → 다음 막** → 3막 보스 처치 시 클리어

---

## 프로젝트 구조

```
joseon-deckbuilder/
├── project.godot              # Godot 4 프로젝트 설정 (GL Compatibility 렌더러)
│
├── scripts/                   # GDScript 로직
│   ├── autoload/              # Autoload 싱글톤 (project.godot에 등록)
│   │   ├── game_manager.gd    # 게임 상태 머신 (TITLE→CHARACTER_SELECT→MAP↔BATTLE 등)
│   │   ├── data_loader.gd     # JSON 데이터 로더 (카드·적·유물·스킬)
│   │   ├── relic_manager.gd   # 유물 획득·효과 트리거
│   │   ├── achievement_manager.gd  # 업적 판정·해금
│   │   ├── audio_manager.gd   # 오디오 관리
│   │   └── save_manager.gd    # 세이브/로드 + 메타 통계
│   ├── battle/
│   │   ├── battle_manager.gd  # 전투 흐름 (턴 루프, 카드 플레이, 적 AI)
│   │   ├── sijo_system.gd     # 시조 리듬 시스템 (6슬롯)
│   │   └── status_effect_manager.gd  # 상태이상 (버프/디버프/DoT)
│   ├── map/
│   │   └── map_generator.gd   # 맵 생성 (막별 노드 배치, 경로 연결)
│   ├── card/
│   │   └── (카드 UI 로직 — scenes/ui/ 참조)
│   └── data/
│       ├── card_data.gd       # 카드 데이터 클래스
│       ├── map_data.gd        # 맵 노드 데이터 클래스
│       ├── run_data.gd        # 런 상태 클래스 (HP·덱·유물·골드·맵)
│       └── status_effect_data.gd  # 상태이상 메타데이터 레지스트리
│
├── scenes/                    # Godot 씬 파일
│   ├── title/                 # 타이틀 화면
│   ├── character_select/      # 캐릭터 선택 (해금 조건 표시)
│   ├── map/                   # 런 맵 (노드 선택, 경로 시각화)
│   ├── battle/                # 전투 씬
│   ├── event/                 # 랜덤 이벤트 (선택지 UI)
│   ├── shop/                  # 상점 (카드 구매/제거, 유물 판매)
│   ├── rest/                  # 휴식 거점 (HP 회복, 카드 업그레이드)
│   ├── reward/                # 보상 선택 (카드 3장 중 선택)
│   ├── act_transition/        # 막 전환 연출
│   ├── run_result/            # 런 결과 (클리어/사망 통계)
│   ├── chronicle/             # 연대기 — 메타 통계·업적 화면
│   └── ui/
│       ├── card_hand.*        # 손패 UI (부채꼴 배치, 드래그/클릭 플레이)
│       └── card_ui.*          # 개별 카드 위젯
│
├── data/                      # 게임 데이터 JSON
│   ├── cards/
│   │   ├── common.json        # 공통 카드 54종 (M001-M054)
│   │   ├── dosa.json          # 무당 전용 카드 27종 (D001-D027)
│   │   ├── mugwan.json        # 의적 전용 카드 27종 (G001-G027)
│   │   ├── mungwan.json       # 선비 전용 카드 27종 (W001-W027)
│   │   ├── uinyeo.json        # 의녀 전용 카드 27종
│   │   ├── gisaeng.json       # 기생 전용 카드 27종
│   │   └── seungbyeong.json   # 승병 전용 카드 27종
│   ├── enemies/
│   │   ├── act1.json          # Act 1 일반 11종 (E001-E011) + 정예 3종 (EL001-EL003)
│   │   ├── act1_boss.json     # Act 1 보스: 판서 이무령 (3페이즈, HP 115)
│   │   ├── act1_boss_mid.json # Act 1 중간 보스
│   │   ├── act1_boss_alt.json # Act 1 대체 보스
│   │   ├── act1_boss_tamhak.json  # Act 1 특수 보스 (탐학)
│   │   ├── act2.json          # Act 2 일반/정예 몬스터
│   │   ├── act2_boss.json     # Act 2 보스
│   │   ├── act2_boss_mid.json # Act 2 중간 보스
│   │   ├── act2_boss_alt.json # Act 2 대체 보스
│   │   ├── act2_boss_mid_gungan.json  # Act 2 중간 보스 (군관)
│   │   ├── act2_boss_tamgwan.json     # Act 2 특수 보스 (탐관)
│   │   ├── act2_minions.json  # Act 2 수하
│   │   ├── act3.json          # Act 3 일반/정예 몬스터
│   │   ├── act3_boss.json     # Act 3 최종 보스
│   │   ├── act3_boss_mid.json # Act 3 중간 보스
│   │   └── special_elites.json # 특수 정예 몬스터
│   ├── events/
│   │   ├── act1_events.json   # Act 1 랜덤 이벤트
│   │   ├── act2_events.json   # Act 2 랜덤 이벤트
│   │   ├── act3_events.json   # Act 3 랜덤 이벤트
│   │   ├── build_variant_events.json  # 빌드 변형 이벤트
│   │   └── special_events.json # 특수 이벤트
│   ├── relics/
│   │   └── relics.json        # 유물 풀 15종 (일반 3·고급 6·희귀 4·전설 2)
│   ├── achievements/
│   │   └── achievements.json  # 업적 정의 목록
│   ├── unlock/
│   │   └── unlock_conditions.json  # 캐릭터 해금 조건
│   ├── shop/
│   │   └── economy.json       # 상점 가격표, 골드 보상 공식
│   ├── characters/
│   │   └── unlock_conditions.json  # 캐릭터 해금 조건
│   ├── narrative/
│   │   └── amhaengosa_journey.json # 암행어사 서사 데이터
│   ├── skills/
│   │   └── special_skills.json  # 캐릭터별 패시브/액티브 스킬
│   └── keywords.json            # 게임 키워드 정의
│
├── docs/                      # 게임 디자인 문서
│   ├── concept.md             # 컨셉, 확정 결정사항, 세계관
│   ├── cards.md               # 카드 목록 및 밸런스 참조
│   ├── enemies.md             # 적 목록 (일반/정예/보스)
│   ├── systems.md             # 구현 시스템 문서
│   ├── classes.md             # 직업 설계 (6캐릭터: 의적/선비/의녀/무당/기생/승병)
│   ├── skills.md              # 스킬/패시브 설계
│   ├── sijo.md                # 시조 리듬 시스템 상세
│   ├── monetization.md        # 수익화 모델
│   ├── code_structure.md      # 코드 구조 가이드
│   ├── data_schema.md         # JSON 데이터 스키마
│   ├── balance_sheet.md       # 밸런스 수치 시트
│   ├── asset_list.md          # 그래픽 에셋 리스트
│   ├── localization_en.md     # 영문 로컬라이제이션
│   ├── nanobanana_prompt_guide.md  # NanoBanana 프롬프트 가이드
│   └── store_listing.md       # 스토어 등록 정보
│
└── art/                       # 아트 에셋
```

---

## 핵심 시스템 요약

### 시조 리듬 시스템
6슬롯 (초장 3→4, 중장 3→4, 종장 3→4). 카드의 음보(beat: 3 또는 4)가 슬롯 순서와 일치해야 채워진다.
**완성 보너스:** 마지막 카드 효과 ×2 + 기 1 회복 + 카드 1장 드로우.

### 직업 시스템 (6캐릭터 확정)
| 직업 | HP | 기/턴 | 고유 자원 | 해금 조건 |
|------|-----|-------|----------|-----------|
| 의적 | 80 | 3 | 기력 (max 8) | 기본 해금 |
| 선비 | 70 | 3 | 학식 (max 8) | 1막 보스 처치 |
| 의녀 | - | 3 | 약재 (max 8) | 5회 완주 |
| 무당 | 75 | 3 | 영력 (max 8) | 의녀로 보스 클리어 |
| 기생 | - | 3 | 흥 (max 8) | 의적으로 보스 클리어 |
| 승병 | - | 3 | 인과 (max 6) | 10회 완주 |

### 유물 시스템
15종 유물 (일반 3 / 고급 6 / 희귀 4 / 전설 2). 정예 처치·이벤트·상점에서 획득.
- **일반:** 전투 시작 방어도, 버프 연장, 골드 보너스
- **전설:** 보스 처치 전용 드롭

### 맵 구조 (3막)
각 막은 9~12개 노드로 구성. 분기 경로 선택. 막 클리어 후 보상 및 다음 막 전환.
- **Act 1 (한양):** 일반 몬스터 11종(E001-E011) → 정예 3종(EL001-EL003) → 보스: 판서 이무령(3페이즈, HP 115)
- **Act 2·3:** 난이도 스케일링 적용

### 상태이상
- **DoT:** 독, 화상, 출혈, 사망표식
- **디버프:** 약화(공격 -25%), 취약(받는 피해 +25%), 냉기(드로우 -1), 사망선고
- **버프:** 힘(strength), 가시(thorns), 갑주(영구 방어막)

### 메타 진행 (연대기)
업적 시스템 + 캐릭터 해금. SaveManager가 메타 통계(총 런, 승리, 처치 수 등)를 영구 저장.

---

## 개발 현황

| 스프린트 | 주요 내용 |
|---------|----------|
| Sprint 1 | GameManager 상태 머신, DataLoader, BattleManager, SijoSystem, CardHand UI |
| Sprint 2 | StatusEffectManager, 무관 기력 시스템, Act 1 보스, 상점 경제, 특수 스킬 |
| Sprint 3 | 밸런스 조정 (무관 카드·Act1 적·유물 수치) |
| Sprint 4 | 맵 생성 (2~3막), 이벤트 씬, 상점 씬, 휴식 씬, 유물 시스템, 런 결과 씬 |
| Sprint 5 | SaveManager 강화 (런 통계, 맵 보존), Act2/3 적·보스 데이터, 유물 JSON |
| Sprint 6 | 문관 캐릭터, 캐릭터 선택 화면 (해금 시스템), 업적 시스템, 연대기 화면 |
| Sprint 7 | 멀티 해상도 대응 (Galaxy Z Flip 3), 문서 최종 정리 |

자세한 시스템 문서: `docs/systems.md`
카드 밸런스: `docs/cards.md`
코드 구조: `docs/code_structure.md`
데이터 스키마: `docs/data_schema.md`
밸런스 수치: `docs/balance_sheet.md`
게임 컨셉: `docs/concept.md`
