# 시조전 데이터 스키마

> 최종 업데이트: 2026-04-09 (6캐릭터 확정 반영)
> 모든 JSON 파일은 `data/` 디렉터리에 위치. 인코딩: UTF-8.

---

## 1. 카드 (`data/cards/*.json`)

### 1.1 파일 목록

| 파일 | class | 설명 |
|------|-------|------|
| `common.json` | `common` | 공통 카드 54종 (M001-M054) — 이동/지원 + 와일드카드 |
| `dosa.json` | `dosa` | 무당 전용 카드 27종 (D001-D027) |
| `mugwan.json` | `mugwan` | 의적 전용 진형 카드 27종 (G001-G027) |
| `mungwan.json` | `mungwan` | 선비 전용 학식 카드 27종 (W001-W027) |
| `uinyeo.json` | `uiwon` | 의녀 전용 카드 27종 |
| `gisaeng.json` | `gungsu` | 기생 전용 카드 27종 |
| `seungbyeong.json` | `sangin` | 승병 전용 카드 27종 |

### 1.2 파일 루트 스키마

```json
{
  "version": "0.1",
  "type": "card_pool",
  "class": "mugwan",
  "class_ko": "무관",
  "class_hanja": "",
  "category": "movement",
  "description": "...",
  "balance_ref": "...",
  "cards": [ /* Card[] */ ]
}
```

### 1.3 Card 오브젝트

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 카드 ID (예: `M001`, `G002`) |
| `name.ko` | string | 한국어 이름 |
| `name.hanja` | string | 한자 표기 |
| `name.romanized` | string | 로마자 표기 |
| `beat` | int | 음보 (3 또는 4) — 시조 슬롯 매칭 기준. **0 = 와일드카드** (어느 슬롯에나 배치 가능, ZER-101) |
| `beat_note` | string | (선택) 와일드카드 등 beat 값에 대한 추가 설명 |
| `cost` | int | 기 소모량 |
| `type` | string | `attack`, `defense`, `formation`, `skill`, `power` |
| `subtypes` | string[] | 보조 타입 (예: `movement`, `token`) |
| `rarity` | int | 1~5 등급 (1=일반, 5=전설) |
| `rarity_stars` | string | 별 표기 (예: `★★☆☆☆`) |
| `effect` | string | 기본 효과 텍스트 |
| `effect_upgraded` | string | 강화 후 효과 텍스트 |
| `flavor_text` | string | 풍미 텍스트 |
| `balance_rationale` | string | 밸런스 근거 설명 |
| `sijo_position` | string | 추천 시조 슬롯 위치 |
| `upgrade_cost` | int | 강화 골드 비용 |
| `values` | object | 수치 변수 (예: `{"block": 5}`) |
| `class_synergy` | string[] | 시너지 카드 ID 목록 (선택) |

---

## 2. 적 (`data/enemies/*.json`)

### 2.1 파일 목록

| 파일 | 내용 |
|------|------|
| `act1.json` | 1막 일반 11종 (E001-E011) + 정예 3종 (EL001-EL003) |
| `act1_boss.json` | 1막 메인 보스: 판서 이무령 (3페이즈) |
| `act1_boss_mid.json` | 1막 중간 보스 |
| `act1_boss_alt.json` | 1막 대체 보스 |
| `act1_boss_tamhak.json` | 1막 특수 보스 (탐학) |
| `act2.json` | 2막 일반+정예 몬스터 |
| `act2_boss.json` | 2막 메인 보스 |
| `act2_boss_mid.json` | 2막 중간 보스 |
| `act2_boss_alt.json` | 2막 대체 보스 |
| `act2_boss_mid_gungan.json` | 2막 중간 보스 (군관) |
| `act2_boss_tamgwan.json` | 2막 특수 보스 (탐관) |
| `act2_minions.json` | 2막 수하 몬스터 |
| `act3.json` | 3막 일반+정예 몬스터 |
| `act3_boss.json` | 3막 최종 보스 |
| `act3_boss_mid.json` | 3막 중간 보스 |
| `special_elites.json` | 특수 정예 몬스터 |

### 2.2 Enemy 파일 루트 스키마

```json
{
  "version": "0.1",
  "type": "enemy_pool",
  "act": 1,
  "act_name": { "ko": "한양", "description": "..." },
  "balance_ref": "...",
  "balance_targets": { /* 밸런스 기준 수치 */ },
  "regular_enemies": [ /* Enemy[] */ ],
  "elite_enemies": [ /* Enemy[] */ ]
}
```

### 2.3 Enemy 오브젝트

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 적 ID (예: `E001`, `EL001`) |
| `name.ko` / `name.hanja` | string | 이름 |
| `description` | string | 설명 |
| `hp.min` / `hp.max` | int | HP 범위 (랜덤 선택) |
| `moves` | Move[] | 행동 패턴 목록 |
| `ai_pattern` | string | AI 행동 알고리즘 설명 |
| `reward` | object | 처치 보상 (gold, relic_chance 등) |

### 2.4 Move 오브젝트

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 행동 ID |
| `name` | string | 행동 이름 |
| `intent` | string | `attack`, `defend`, `buff`, `debuff`, `special` |
| `damage` | int | 피해량 (공격 시) |
| `times` | int | 반복 횟수 |
| `block` | int | 방어도 (방어 시) |
| `description` | string | 행동 설명 |

### 2.5 보스 스키마 (act1_boss.json 예시)

보스는 `phases` 배열로 페이즈별 HP와 행동 패턴을 정의한다.

```json
{
  "id": "BOSS_ACT1",
  "name": { "ko": "판서 이무령" },
  "total_hp": 115,
  "phases": [
    { "phase": 1, "hp_threshold": 115, "moves": [...] },
    { "phase": 2, "hp_threshold": 70, "moves": [...] },
    { "phase": 3, "hp_threshold": 30, "moves": [...] }
  ]
}
```

---

## 3. 유물 (`data/relics/relics.json`)

### 3.1 파일 루트 스키마

```json
{
  "version": "0.1",
  "type": "relic_pool",
  "description": "...",
  "rarity_table": { /* 등급별 드롭 가중치 */ },
  "relics": [ /* Relic[] */ ]
}
```

### 3.2 Rarity Table

```json
{
  "1_common":    { "label_ko": "일반",  "drop_weight": { "elite": 50, "event": 30, "shop": 20 } },
  "2_uncommon":  { "label_ko": "고급",  "drop_weight": { "elite": 35, "event": 40, "shop": 30 } },
  "3_rare":      { "label_ko": "희귀",  "drop_weight": { "elite": 15, "event": 25, "shop": 35 } },
  "4_legendary": { "label_ko": "전설",  "drop_weight": { "boss": 100 } }
}
```

### 3.3 Relic 오브젝트

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 유물 ID (예: `R001`) |
| `name.ko` / `name.hanja` / `name.romanized` | string | 이름 |
| `rarity` | int | 1~4 등급 |
| `class_restriction` | string\|null | 직업 제한 (null=공통) |
| `trigger` | string | 발동 조건 (예: `battle_start`, `on_buff_apply_to_self`) |
| `effect` | string | 효과 텍스트 |
| `effect_description` | string | 간략 설명 |
| `flavor_text` | string | 풍미 텍스트 |
| `balance_rationale` | string | 밸런스 근거 |
| `obtain_from` | string[] | 획득 경로 (`elite_reward`, `event`, `shop`, `boss`) |
| `values` | object | 수치 변수 |

---

## 4. 업적 (`data/achievements/achievements.json`)

### 4.1 파일 스키마

```json
{
  "achievements": [ /* Achievement[] */ ]
}
```

### 4.2 Achievement 오브젝트

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 업적 ID (예: `ACH_FIRST_RUN`) |
| `name` | string | 업적 이름 |
| `description` | string | 달성 조건 설명 |
| `type` | string | 판정 타입 (예: `total_runs`, `total_victories`) |
| `params` | object | 판정 파라미터 (예: `{"min_runs": 3}`) |
| `icon` | string | 아이콘 키 |

**판정 타입 목록:**

| type | params 키 | 설명 |
|------|-----------|------|
| `total_runs` | `min_runs` | 총 런 완료 수 |
| `total_victories` | `min_victories` | 총 승리 수 |
| `character_act_clear` | `character_id`, `min_act` | 특정 캐릭터로 막 클리어 |

---

## 5. 캐릭터 해금 조건 (`data/unlock/unlock_conditions.json`)

### 5.1 파일 스키마

```json
{
  "version": "0.1",
  "type": "unlock_conditions",
  "characters": [ /* UnlockEntry[] */ ]
}
```

### 5.2 UnlockEntry 오브젝트

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 캐릭터 ID (`mugwan`, `mungwan`, `dosa`, `uiwon`, `gungsu`, `sangin`) |
| `class_ko` | string | 한국어 이름 |
| `unlock_type` | string | `default`, `act_clear`, `boss_clear`, `run_count` |
| `unlock_condition` | object | 해금 파라미터 |
| `unlock_description` | string | 조건 설명 |
| `resource` | string | 고유 자원명 |

**해금 조건 요약 (6캐릭터):**

| ID | 직업 | 조건 | 고유 자원 |
|----|------|------|----------|
| mugwan | 의적 | 기본 해금 | 기력 (max 8) |
| mungwan | 선비 | 1막 보스 처치 | 학식 (max 8) |
| uiwon | 의녀 | 5회 완주 | 약재 (max 8) |
| mudang | 무당 | 의녀로 보스 클리어 | 영력 (max 8) |
| gungsu | 기생 | 의적으로 보스 클리어 | 흥 (max 8) |
| sangin | 승병 | 10회 완주 | 인과 (max 6) |

---

## 6. 이벤트 (`data/events/act*_events.json`)

### 6.1 파일 목록

| 파일 | 막 |
|------|----|
| `act1_events.json` | 1막 (한양) |
| `act2_events.json` | 2막 (지리산) |
| `act3_events.json` | 3막 (경복궁) |

### 6.2 Event 오브젝트 (공통 구조)

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 이벤트 ID |
| `title` | string | 이벤트 제목 |
| `description` | string | 상황 설명 |
| `choices` | Choice[] | 선택지 목록 |

### 6.3 Choice 오브젝트

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 선택지 ID |
| `text` | string | 선택지 텍스트 |
| `effect` | object | 효과 (gold, hp, card, relic 등) |
| `condition` | object\|null | 선택 가능 조건 (null=항상 가능) |

---

## 7. 상점 경제 (`data/shop/economy.json`)

```json
{
  "shop": {
    "card_prices": {
      "common":   { "base_price": 75,  "price_range": {"min": 50,  "max": 100} },
      "uncommon": { "base_price": 110, "price_range": {"min": 85,  "max": 135} },
      "rare":     { "base_price": 150, "price_range": {"min": 120, "max": 180} }
    },
    "card_removal_price": {
      "base_price": 75,
      "increment": 25
    },
    "relic_prices": { /* 등급별 유물 가격 */ }
  }
}
```

**골드 흐름 (Act 1 추정):**
- 시작 골드: 99
- 일반 전투 9회 × 평균 17g = 153g
- 정예 전투 2회 × 평균 32g = 64g
- 보스 1회 × 평균 70g = 70g
- 이벤트 보너스: 30g
- **Act 1 총 약 416g**

---

## 8. 스킬 (`data/skills/special_skills.json`)

캐릭터별 기본 수치(HP, 기/턴)와 패시브·액티브 스킬을 정의한다.

**기본 수치:**

| 직업 | class_id | HP | 기/턴 | 고유 자원 |
|------|----------|----|-------|----------|
| 의적 | mugwan | 80 | 3 | 기력 (max 8) |
| 선비 | mungwan | 70 | 3 | 학식 (max 8) |
| 무당 | dosa | 75 | 3 | 영력 (max 8) |
| 의녀 | uiwon | - | 3 | 약재 (max 8) |
| 기생 | gungsu | - | 3 | 흥 (max 8) |
| 승병 | sangin | - | 3 | 인과 (max 6) |

---

## 9. 공통 규칙

- 모든 JSON은 `"version": "0.1"` 필드를 포함한다.
- `balance_ref` 필드는 관련 태스크 ID를 참조한다 (예: `ZER-12`).
- 다국어 이름은 항상 `{ko, hanja, romanized}` 구조를 사용한다.
- ID 체계:
  - 공통 카드: `M001~`
  - 도사 카드: `D001~`
  - 의적 카드: `G001~` (진형 카드)
  - 선비 카드: `W001~`
  - 의녀 카드: `uinyeo.json`
  - 기생 카드: `gisaeng.json`
  - 승병 카드: `seungbyeong.json`
  - 일반 적: `E001~`
  - 정예 적: `EL001~`
  - 보스: `BOSS_ACT{n}`
  - 유물: `R001~`
  - 업적: `ACH_*`
