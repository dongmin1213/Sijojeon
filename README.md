# 시조전 (Sijojeon)

조선시대 배경의 모바일 덱빌딩 로그라이크. Godot 4 + GDScript.

**핵심 메카닉:** 카드를 플레이하여 시조(時調) 리듬 슬롯(초장-중장-종장)을 채우면 시조 완성 보너스 발동.

---

## 실행 방법

**요구사항:** Godot 4.3+

```
# Godot Editor에서 열기
godot project.godot

# 또는 CLI 실행
godot --path . scenes/title/title_screen.tscn
```

Android 빌드: Godot Editor → Project → Export → Android (export_presets.cfg 참조)

---

## 프로젝트 구조

```
joseon-deckbuilder/
├── project.godot              # Godot 4 프로젝트 설정
│
├── scripts/                   # GDScript 로직
│   ├── autoload/              # Autoload 싱글톤
│   │   ├── game_manager.gd    # 게임 상태 머신 (TITLE→MAP→BATTLE 등)
│   │   ├── data_loader.gd     # JSON 데이터 로더 (카드·적·스킬)
│   │   ├── audio_manager.gd   # 오디오 관리
│   │   └── save_manager.gd    # 세이브/로드
│   ├── battle/
│   │   ├── battle_manager.gd  # 전투 흐름 (턴 루프, 카드 플레이, 적 AI)
│   │   ├── sijo_system.gd     # 시조 리듬 시스템 (6슬롯)
│   │   └── status_effect_manager.gd  # 상태이상 (버프/디버프/DoT)
│   └── data/
│       ├── card_data.gd       # 카드 데이터 클래스
│       ├── run_data.gd        # 런 상태 클래스
│       └── status_effect_data.gd  # 상태이상 메타데이터 레지스트리
│
├── scenes/                    # Godot 씬 파일
│   ├── title/                 # 타이틀 화면
│   ├── battle/                # 전투 씬
│   ├── reward/                # 보상 선택 씬
│   └── ui/
│       ├── card_hand.*        # 손패 UI (부채꼴 배치, 드래그/클릭 플레이)
│       └── card_ui.*          # 개별 카드 위젯
│
├── data/                      # 게임 데이터 JSON
│   ├── cards/
│   │   ├── common.json        # 공통 이동 카드 5종 (M001-M005)
│   │   ├── dosa.json          # 도사 전용 카드 6종 (D001-D007)
│   │   └── mugwan.json        # 무관 전용 진형 카드 5종 (G001-G005)
│   ├── enemies/
│   │   ├── act1.json          # Act 1 일반/정예 몬스터 (E001-E004, EL001)
│   │   └── act1_boss.json     # Act 1 최종 보스: 판서 이무령 (3페이즈)
│   ├── events/
│   │   └── act1_events.json   # Act 1 랜덤 이벤트 8종
│   ├── shop/
│   │   └── economy.json       # 상점 가격표, 골드 보상 공식
│   └── skills/
│       └── special_skills.json  # 캐릭터별 패시브/액티브 스킬
│
└── docs/                      # 게임 디자인 문서 (XML)
    ├── concept.xml            # 컨셉, 확정 결정사항, 세계관
    ├── cards.xml              # 카드 목록 및 밸런스 참조
    ├── enemies.xml            # 적 목록 (일반/정예/보스)
    ├── systems.xml            # 구현 시스템 문서 (Sprint 1-2)
    ├── classes.xml            # 직업 설계 (도사/무관)
    ├── skills.xml             # 스킬/패시브 설계
    ├── sijo.xml               # 시조 리듬 시스템 상세
    └── monetization.xml       # 수익화 모델
```

---

## 핵심 시스템 요약

### 시조 리듬 시스템
6슬롯 (초장 3→4, 중장 3→4, 종장 3→4). 카드의 음보(beat: 3 또는 4)가 슬롯 순서와 일치해야 채워진다.
**완성 보너스:** 마지막 카드 효과 ×2 + 기 1 회복 + 카드 1장 드로우.

### 직업 시스템
| 직업 | HP | 기(氣)/턴 | 고유 메카닉 |
|------|-----|-----------|------------|
| 도사(道士) | 70 | 3 | 천지기(시조 3슬롯 이상 시 기 1 회복) |
| 무관(武官) | 80 | 3 | 기력(氣力) 시스템, 병사 토큰 |

### 상태이상
- **DoT:** 독, 화상, 출혈, 사망표식
- **디버프:** 약화(공격 -25%), 취약(받는 피해 +25%), 냉기(드로우 -1), 사망선고
- **버프:** 힘(strength), 가시(thorns), 갑주(영구 방어막)

### Act 1 구조 (한양)
일반 몬스터(E001-E004) → 정예(EL001) → 보스: 판서 이무령(3페이즈, HP 115)

---

## 개발 현황

- **Sprint 1:** GameManager 상태 머신, DataLoader, BattleManager, SijoSystem, CardHand UI
- **Sprint 2:** StatusEffectManager(버프/디버프), 무관 기력 시스템, Act 1 보스(판서 이무령), 상점 경제 설계, 특수 스킬 설계

자세한 시스템 문서: `docs/systems.xml`
카드 밸런스: `docs/cards.xml`
게임 컨셉: `docs/concept.xml`
