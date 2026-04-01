# Paperclip 셋팅 가이드

## 1. 사전 준비

- Node.js 20+
- pnpm 9.15+
- Docker
- Windows 개발자 모드 켜기 (설정 → 시스템 → 개발자용 → 토글 ON)

## 2. 설치 & 실행

```bash
# 반드시 UTF-8 설정 후 실행 (한글 깨짐 방지)
chcp 65001
npx paperclipai onboard --yes
npx paperclipai run
```

서버 주소: http://127.0.0.1:3100

## 3. 한글 깨짐 방지

start-paperclip.bat 파일을 만들어서 항상 이걸로 실행:

```bat
@echo off
chcp 65001 >nul
set LANG=en_US.UTF-8
set LC_ALL=en_US.UTF-8
set PYTHONIOENCODING=utf-8
set PYTHONUTF8=1
npx paperclipai run
```

## 4. Company 설정

| 항목 | 값 |
|------|-----|
| Company name | ⚠️ NineArk는 기존 게임회사와 겹침 — 새 이름 정해서 입력 |
| Mission / goal | 아홉 번의 도전 끝에 완성되는 게임을 만든다. 로그라이크 전문 1인 스튜디오로, Godot/Flutter + AI(Claude, Gemini) 기반 개발. 현재 운영 중인 Soul Dungeon(텍스트 카드 로그라이크)과 신규 조선시대 덱빌딩 로그라이크를 포함한 전체 게임 포트폴리오를 관리한다. |

## 5. Agent 설정

| 항목 | 값 |
|------|-----|
| Agent name | CEO |
| Adapter type | Claude Code |
| Model | Default |

## 6. Projects 구성

온보딩 완료 후 대시보드 왼쪽 PROJECTS 옆 + 버튼으로 추가.
각 프로젝트 → Configuration → Codebase → **Set local folder**로 작업 디렉토리 지정.

| 프로젝트 | Local Folder | 용도 | 우선순위 |
|----------|-------------|------|----------|
| 조선 덱빌딩 | `C:\Users\DamonKim\Desktop\claude\Side\new` | 신규 기획 — 차별점 확정, 게임 루프 설계, 전투 구조 | 중간 (기획 단계) |
| Soul Dungeon | `C:\Users\DamonKim\Desktop\claude\Side\00.soul-dungeon` | 상용 운영 — 리뷰 모니터링, 버그 수정, 업데이트 | 높음 (출시 중) |
| Verdant Abyss | `C:\Users\DamonKim\Desktop\claude\Side\0.verdant-abyss` | 보류 — 필요 시 재개 | 낮음 |

## 7. Agent 확장 (나중에 추가)

| Agent | 역할 | 주요 업무 |
|-------|------|-----------|
| CEO | 전체 총괄 | 우선순위 결정, 태스크 분배 |
| 게임 디자이너 | 메카닉 설계 | 차별점 분석, 게임 루프, 직업 설계 |
| QA/운영 | Soul Dungeon 운영 | 리뷰 확인, 버그 이슈 생성, 수정 검증 |

## 8. 첫 번째 Task

| 항목 | 값 |
|------|-----|
| Task title | 신규 조선 덱빌딩 로그라이크 핵심 차별점 확정 |
| Description | 아래 참고 |

```
NineArk의 신규 프로젝트: 조선시대 배경 모바일 덱빌딩 로그라이크 (Slay the Spire 스타일, Godot 4).

CONCEPT.md에 정리된 핵심 차별점 후보 3가지를 분석하라:
- A. 시조(時調) 리듬 시스템 (카드에 음보 3/4 부여, 패턴 완성 시 증폭)
- B. 부적(符籍) 덧그리기 시스템 (카드 간 드래그 합성)
- C. 오행(五行) 상성 시스템 (목화토금수 속성 상극)

각 후보별로 장단점, 1인 개발 난이도, 모바일 UX 적합성, Slay the Spire 대비 차별화 정도를 비교 분석하고 추천안을 제시하라.
```

## 9. Gemini 에이전트 추가 (나중에)

```bash
npm install -g @google/gemini-cli
gemini  # Google 로그인 (Plus 계정)
```

대시보드 → AGENTS + → Gemini 선택

## 10. 트러블슈팅

- symlink 에러 (`EPERM: operation not permitted, symlink`) → Windows 개발자 모드 켜기
- 포트 충돌 → 기존 node 프로세스 종료 후 재시작
- DB 꼬임 → `~/.paperclip/instances/default/db` 삭제 후 재설치
