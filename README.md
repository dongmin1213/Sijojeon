# 시조전 (Sijojeon)

조선시대 배경의 모바일 덱빌딩 로그라이크. Godot 4 + GDScript.

Slay the Spire 스타일의 순수 덱빌딩 로그라이크를 조선시대 세계관으로 재해석.

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
2. **캐릭터 선택** → 직업 선택 후 런 시작 (의적 기본 해금, 5종 순차 해금)
3. **맵 탐색** → 전투(⚔), 이벤트(?), 상점(🏪), 휴식(💤), 정예(★), 보스(💀) 노드 탐색
4. **전투** → 매 턴 기(Qi) 3을 사용해 카드 플레이. 공격/방어/스킬/파워 카드로 적을 처치
5. **보상 → 다음 막** → 3막 보스 처치 시 클리어

---

## 핵심 시스템

### 전투 시스템
턴 기반 카드 전투. 매 턴 기(Qi) 3이 주어지며, 카드를 사용해 공격·방어·버프·디버프를 수행한다. 사용하지 않은 기는 이월되지 않는다. 방어도(Block)는 턴이 끝나면 초기화된다.

### 카드 타입
- **Attack** — 적에게 피해를 준다
- **Skill** — 방어도 획득, 드로우, 디버프 등 유틸리티
- **Power** — 전투 동안 영구 효과
- **Status / Curse** — 덱을 오염시키는 부정적 카드

### 직업 시스템 (6캐릭터)
| 직업 | HP | 기/턴 | 해금 조건 |
|------|-----|-------|-----------|
| 의적 | 80 | 3 | 기본 해금 |
| 선비 | 70 | 3 | 1막 보스 처치 |
| 의녀 | 70 | 3 | 5회 완주 |
| 무당 | 75 | 3 | 의녀로 보스 클리어 |
| 기생 | 70 | 3 | 의적으로 보스 클리어 |
| 승병 | 75 | 3 | 10회 완주 |

### 상태이상
- **DoT:** 독, 화상, 출혈
- **디버프:** 약화(공격 -25%), 취약(받는 피해 +25%), 냉기(드로우 -1)
- **버프:** 힘(Strength), 가시(Thorns), 갑주(영구 방어막)

### 유물 시스템
정예 처치·이벤트·상점에서 유물을 획득. 일반/고급/희귀/전설 등급별 패시브 효과.

### 맵 구조 (3막)
각 막은 분기 경로로 구성. 전투·정예·이벤트·상점·휴식 노드를 선택하며 보스를 향해 진행.

### 어센션 (난이도)
0~10 단계의 어센션 레벨. 적 HP 증가, 저주 카드 추가, 상점 가격 상승 등 난이도 수정자.

### 메타 진행
업적 시스템 + 캐릭터 해금. SaveManager가 메타 통계(총 런, 승리 등)를 영구 저장.

---

## 프로젝트 구조

```
Sijojeon/
├── project.godot              # Godot 4 프로젝트 설정
│
├── scripts/                   # GDScript 로직
│   ├── autoload/              # Autoload 싱글톤
│   │   ├── game_manager.gd    # 게임 상태 머신 (TITLE→MAP↔BATTLE 등)
│   │   ├── data_loader.gd     # JSON 데이터 로더
│   │   ├── relic_manager.gd   # 유물 효과 트리거
│   │   ├── save_manager.gd    # 세이브/로드 + 메타 통계
│   │   ├── audio_manager.gd   # 오디오 관리
│   │   └── achievement_manager.gd  # 업적 판정·해금
│   ├── battle/
│   │   ├── battle_manager.gd  # 전투 흐름 (턴 루프, 카드 플레이, 적 AI)
│   │   └── status_effect_manager.gd  # 상태이상 (버프/디버프/DoT)
│   ├── map/
│   │   └── map_generator.gd   # 맵 생성 (막별 노드 배치, 경로 연결)
│   └── data/
│       ├── card_data.gd       # 카드 데이터 클래스
│       ├── run_data.gd        # 런 상태 클래스
│       └── map_data.gd        # 맵 노드 데이터 클래스
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
│   ├── run_result/            # 런 결과 (클리어/사망 통계)
│   └── ui/                    # 카드 UI (손패, 개별 카드 위젯)
│
├── data/                      # 게임 데이터 JSON
│   ├── cards/                 # 카드 정의 (공통 54종 + 직업별 27종 × 6)
│   ├── enemies/               # 적 정의 (일반/정예/보스, 3막)
│   ├── events/                # 랜덤 이벤트 (막별)
│   ├── relics/                # 유물 풀
│   ├── achievements/          # 업적 정의
│   ├── shop/                  # 상점 가격표
│   └── keywords.json          # 게임 키워드 정의
│
├── art/                       # 아트 에셋 (캐릭터/적/배경/UI/오디오)
├── docs/                      # 게임 디자인 문서
├── fonts/                     # 고운바탕, 나눔명조 폰트
├── locale/                    # 영문 번역 (en.json)
├── translations/              # Godot 번역 리소스 (ko/en)
└── tools/                     # 유틸 스크립트 (에셋 생성, 밸런스 검증)
```

---

## 기술 스택

- **엔진:** Godot 4.6 (GL Compatibility)
- **언어:** GDScript
- **렌더러:** OpenGL ES 3.0
- **해상도:** 1080×1920 (세로 모드, canvas_items stretch)
- **로컬라이제이션:** 한국어(기본) / 영어
- **CI:** GitHub Actions (Android APK 빌드)

자세한 시스템 문서: `docs/systems.md`
카드 밸런스: `docs/cards.md`
코드 구조: `docs/code_structure.md`
데이터 스키마: `docs/data_schema.md`
