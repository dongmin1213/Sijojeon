# 시조전 — English Localization Specification

**버전**: 0.2
**최종 수정**: 2026-04-02
**작업 티켓**: [ZER-110](/ZER/issues/ZER-110)
**담당**: Document Specialist
**변경 내역**: locale/en.json 생성 완료. D008~D025 도사 카드, 2막/3막 이벤트, R004~R028 유물 효과 전체 추가.

---

## 목차

1. [번역 철학 및 원칙](#1-번역-철학-및-원칙)
2. [캐릭터 및 직업](#3-캐릭터-및-직업)
3. [카드 이름 번역표](#4-카드-이름-번역표)
4. [유물 이름 번역표](#5-유물-이름-번역표)
5. [적 이름 번역표](#6-적-이름-번역표)
6. [이벤트 제목 번역표](#7-이벤트-제목-번역표)
7. [상태이상 번역표](#8-상태이상-번역표)
8. [UI 텍스트 번역표](#9-ui-텍스트-번역표)
9. [언어 전환 UI 명세](#10-언어-전환-ui-명세)
10. [레이아웃 고려사항](#11-레이아웃-고려사항)

---

## 1. 번역 철학 및 원칙

### 1.1 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **문화 보존** | 조선 문화 고유 개념(시조, 기, 도깨비 등)은 로마자 표기를 유지하되 괄호 설명 추가 |
| **플레이어 우선** | 효과 설명은 간결하고 명확하게. 게임 메카닉 이해가 최우선 |
| **의역 허용** | 직역이 어색할 경우 의도에 충실한 자연스러운 영어로 의역 |
| **고유명사 처리** | 역사적 인물, 지명, 유물 이름은 로마자 표기 + 영문 설명 병기 |
| **길이 제한** | 카드 이름 15자 이내, 카드 효과 80자 이내 (모바일 세로 화면 기준) |

### 1.2 고유 개념 용어집

| 한국어 | 한자 | 영문 표기 | 주석 |
|--------|------|-----------|------|
| 기 | | Qi | 에너지 자원. 괄호 없이 "Qi"만 사용 |
| 도사 | | Daoist Sorcerer | 직업명 |
| 무관 | | Military Officer | 직업명 |
| 문관 | | Scholar Official | 직업명 |
| 방어도 | | Block | 턴 내 피해 방어 수치 |
| 약화 | | Weakened | 다음 공격 피해 감소 상태이상 |
| 화상 | | Burn | 지속 화염 피해 상태이상 |
| 독 | | Poison | 지속 독 피해 상태이상 |
| 부적 | | Talisman | 유물/아이템 |
| 도술 | | Daoist Arts | 도사 마법 계통 |

---

## 3. 캐릭터 및 직업

### 3.1 직업 이름 및 설명

| 한국어 | 한자 | 영문 이름 | 영문 설명 |
|--------|------|-----------|-----------|
| 도사 | | Daoist Sorcerer | Master of Qi arts and mystic spells. Amplifies energy, casts curses, and detonates Sijo with devastating force. |
| 무관 | | Military Officer | Commands soldiers and unleashes tactical formations. Uses Stamina to power overwhelming assaults. |
| 문관 | | Scholar Official | Wields the power of the written word and Confucian ritual. Weaves defensive rites and political gambits to outlast any foe. |

### 3.2 직업별 핵심 메카닉 영문 설명

**도사 (Daoist Sorcerer)**
```
Qi Mastery: Gain bonus Qi each turn.
Completing a Sijo restores 1 additional Qi (Heavenly Qi passive).
Burn [X]: Enemy takes X damage at end of their turn, then X decreases by 1.
Poison [X]: Enemy takes X damage at end of their turn, then X decreases by 1.
```

**무관 (Military Officer)**
```
Soldier Token: Absorbs one hit, then vanishes — recovering 1 Qi on death.
Stamina: Secondary resource (max 10). Carries between turns.
 Spend Stamina to power up attacks.
Formation cards generate Soldier Tokens and build Stamina.
```

**문관 (Scholar Official)**
```
Knowledge: Accumulates when Study cards are played.
 Spend Knowledge to amplify ritual defense cards.
Ritual Protocol: Reduces damage taken this turn.
```

---

## 4. 카드 이름 번역표

> **번역 기준**: 로마자 표기는 원본 유지. 영문 이름은 의미·기능·분위기를 반영한 자연스러운 번역.
> 효과 번역은 별도 구현 시 본 표의 이름을 사용할 것.

### 4.1 공통 카드 (이동)

| ID | 한국어 | 로마자 | 영문 이름 | 비고 |
|----|--------|--------|-----------|------|
| M001 | 회피 | Hoepi | Evasion | 방어도 카드 |
| M002 | 도약 | Doyak | Leap | 이동 오프너 |
| M003 | 후퇴 | Hutoe | Feigned Retreat | 0코스트 약화 |
| M004 | 측면 강타 | Eukmyeon Gangta | Flanking Strike | 조건부 공격 |
| M005 | 포복 | Pobok | Low Crawl | 방어+드로우 |

### 4.2 도사 카드

| ID | 한국어 | 로마자 | 영문 이름 | 비고 |
|----|--------|--------|-----------|------|
| D001 | 기공 | Gigong | Qi Cultivation | 0코스트 Qi+드로우 |
| D002 | 결인 | Gyeorin | Hand Seal | 공격 버프 |
| D003 | 진언 | Jineon | Mantra | 기 획득 조건 AoE |
| D004 | 부적 | Bujeok | Talisman Strike | 공격+화상 |
| D005 | 축지법 | Chukjibeop | Teleportation | 드로우+비용감소 |
| D006 | 태산붕 | Taesanbung | Mountain Collapse | 최강 단타, 다음 턴 기 패널티 |
| D007 | 수결 | Sugyeol | Qi Strike | 기본 공격 |
| D008 | 대기 | Daegi | Great Qi | 기 2 획득 |
| D009 | 기폭 | Gibok | Qi Explosion | 기 획득량 기반 피해 |
| D010 | 오기 | Ogi | Five Energies | 0코스트 기+다음 기공 카드 비용 감소 |
| D011 | 천기 | Cheongi | Heavenly Qi | 파워: 매 턴 기 영구 증가 |
| D012 | 기류 | Giryu | Qi Flow | 기+드로우 2 |
| D013 | 기집 | Gijip | Qi Gathering | 기 3 대량 획득 |
| D014 | 독안개 | Doganae | Poison Mist | 전체 독 DoT |
| D015 | 저주 | Jeochu | Hex | 단일 저주 DoT |
| D016 | 혼돈의 부적 | Hondon Bujeok | Chaos Talisman | 화상+약화 복합 |
| D017 | 흑염 | Heukyeom | Black Flame | 화상/독 조건부 강공격 |
| D018 | 오독 | Odok | Five Poisons | 전체 독+화상 최대 세팅 |
| D019 | 주박 | Jubak | Hex Binding | 취약+DoT 증폭 |
| D020 | 구미호 소환 | Gumiho Sowhan | Gumiho Summon | 소환 DoT |
| D021 | 청룡 기공 | Cheongnyong Gigong | Azure Dragon's Qi | 공격+기 회복 토큰 |
| D022 | 백호 강격 | Baekho Ganggyeok | White Tiger Strike | 소환 조건부 강공격 |
| D023 | 산신 강림 | Sansin Ganglim | Mountain God's Descent | 소환 방어+기 회복 |
| D024 | 허수아비 | Heosurabi | Scarecrow | 소환형 방어 |
| D025 | 도깨비 부름 | Dokkaebi Bureum | Dokkaebi's Call | 소환 조건부 전체 공격 |

### 4.3 무관 카드

| ID | 한국어 | 로마자 | 영문 이름 | 비고 |
|----|--------|--------|-----------|------|
| G001 | 진형 전환 | Jinhyeong Jeonhwan | Formation Shift | 토큰 생성 |
| G002 | 돌격 | Dolgyeok | Charge | 토큰 강화 공격 |
| G003 | 포위 | Powi | Encirclement | 디버프 |
| G004 | 학익진 | Hagikjin | Crane Wing Formation | 역사적 진법 |
| G005 | 천하무적진 | Cheonha Mujeokjin | Invincible Formation | 강력 방어진 |
| G006 | 보병 전진 | Bobyeong Jeonjin | Infantry Advance | 토큰 지원 |
| G007 | 복병 | Bokbyeong | Ambush | 기습 공격 |
| G008 | 삼군 배치 | Samgun Baechii | Three-Army Deploy | 대규모 토큰 |
| G009 | 진법 교본 | Jinbeop Gyobon | Tactics Manual | 드로우+기력 |
| G010 | 철기 돌격 | Cheolgi Dolgyeok | Iron Cavalry Charge | 강공격 |
| G011 | 연막 | Yeonmak | Smoke Screen | 방어 지원 |
| G012 | 총통 사격 | Chongtong Sagyeok | Cannon Volley | 원거리 AoE |
| G013 | 기합 | Gihap | Battle Cry | 기력 충전 |
| G014 | 역전의 기세 | Yeokjeon Gise | Tide Turner | 기력 소비 버프 |
| G015 | 불굴의 의지 | Bulgul Euiji | Unbreakable Will | 기력 소비 방어 |
| G016 | 마지막 도박 | Majimak Tobak | Last Gamble | 고위험 고보상 |
| G017 | 단신 돌격 | Dansin Dolgyeok | Solo Rush | 기력 소비 공격 |
| G018 | 무쌍 | Mussang | Peerless Strike | 기력 최대 소비 |
| G019 | 수비 대형 | Subi Daehyeong | Shield Wall | 방어 대형 |
| G020 | 찌르기 | Jjireureogi | Thrust | 단순 공격 |
| G021 | 반격 | Bangyeok | Counter | 피해 후 반격 |
| G022 | 연속 베기 | Yeonsok Baegi | Rapid Slash | 다중 타격 |
| G023 | 철벽 방어 | Cheolbyeok Bangeo | Iron Bulwark | 고방어도 |
| G024 | 격파 | Gyeokpa | Shatter | 방어도 관통 |
| G025 | 백전노장 | Baekjeon Nojang | Battle-Scarred Veteran | 패시브 버프 |

### 4.4 문관 카드

| ID | 한국어 | 로마자 | 영문 이름 | 비고 |
|----|--------|--------|-----------|------|
| W001 | 직언 | Jigeon | Bold Remonstrance | 적 디버프 |
| W002 | 탄핵 | Tanhaek | Impeachment | 강력 디버프 |
| W003 | 상소 | Sangso | Royal Petition | 지연/제어 |
| W004 | 경연 | Gyeongyeon | Royal Lecture | 방어 의식 |
| W005 | 예제 | Yeoje | Ritual Protocol | 방어+지식 |
| W006 | 독서 | Dokseo | Study | 지식 획득+드로우 |
| W007 | 격물치지 | Gyeongmul Chiji | Investigation of Things | 지식 폭발 |
| W008 | 박학다식 | Bakak Dasik | Encyclopedic Knowledge | 지식 소비 강화 |
| W009 | 행차 | Haengcha | Royal Procession | 방어+학식 |
| W010 | 피화 | Pihwa | Evasive Rhetoric | 방어+학식 |
| W011 | 고언 | Goeon | Loyal Counsel | 약한 공격+학식 |
| W012 | 논박 | Nonbak | Debate | 학식 소비 강공격 |
| W013 | 논리 | Nolli | Argumentation | 학식+드로우 증폭 |
| W014 | 문집 편찬 | Munjip Pyeonjhan | Anthology | 학식 최대치 확장 |
| W015 | 왕의 윤허 | Wang-ui Yunheo | Royal Permission | 학식 전소 강공격 |
| W016 | 탄안 | Tanan | Censure | 약화 부여 |
| W017 | 모함 | Moham | Bold Scheme | 약화+취약 복합 |
| W018 | 파직 | Pajik | Dismissal | 공격+파직 디버프 |
| W019 | 간언 | Ganeon | Remonstration | 드로우+취약 준비 |
| W020 | 유배 | Yubae | Exile | 버프 제거+약화 |
| W021 | 수신 제가 | Sujin Jega | Perfect Virtue | 방어+학식 |
| W022 | 군자 | Gunja | Noble Man | 학식 소비 방어 |
| W023 | 청렴 | Cheongnyeom | Clean Governance | 학식 0 조건 방어 |
| W024 | 정도 | Jeongdo | Right Path | 방어 카드 학식 패시브 |
| W025 | 대의 | Daeui | Great Righteousness | 학식+방어+드로우 복합 |

---

## 5. 유물 이름 번역표

| ID | 한국어 | 로마자 | 영문 이름 | 등급 | 영문 효과 요약 |
|----|--------|--------|-----------|------|----------------|
| R001 | 편자 | Pyeonja | Horseshoe | Common | Gain 5 Block at the start of each combat. |
| R002 | 평안 부적 | Pyeongan Bujeok | Peace Talisman | Common | Buffs applied to yourself last 1 extra turn. |
| R003 | 행운의 엽전 | Haengwun Yeopjeon | Lucky Coin | Common | Gain 10 extra Gold after each combat victory. |
| R004 | 봉황 깃털 | Bonghwang Gitteo | Phoenix Feather | Uncommon | Draw 1 extra card each time your draw pile is reshuffled. |
| R005 | 홍삼 뿌리 | Hongsam Ppuri | Red Ginseng Root | Common | Recover 8 HP after defeating an Elite. |
| R006 | 호신검 | Hosin Geom | Bodyguard Sword | Uncommon | Max Stamina +1 for this combat (start of combat). |
| R007 | 사서 | Saseo | The Four Books | Uncommon | Draw 1 extra card when you play your first card each turn. |
| R008 | 동의보감 | Dongui Bogam | Dongui Bogam | Uncommon | Apply 1 extra Poison stack when inflicting Poison. (Traditional Medical Encyclopedia) |
| R009 | 무당 방울 | Muring | Shaman's Bell | Uncommon | Gain 2 extra Spirit Power at the start of combat. |
| R010 | 각궁 | Gakgung | Horn Bow | Uncommon | Max Arrow capacity +3; gain 2 extra Arrows at combat start. |
| R011 | 상단 장부 | Sangdan Jangbu | Merchant Ledger | Uncommon | Gain 35 extra Gold each time you enter a shop. (Max 2× per run.) |
| R012 | 어사마패 | Eosamamapae | Royal Inspector's Plaque | Rare | At combat start, apply 2 Vulnerable to the enemy with the most HP. |
| R013 | 만파식적 | Manpasikjeok | Manpasikjeok | Rare | Recover 25% of max HP when entering Boss combat. (Mystical Flute of legend) |
| R014 | 저주받은 투구 | Juchu | Cursed Helmet | Rare | Attack cards apply 1 Bleed to the target. However, start each combat with 3 Poison on yourself. |
| R015 | 삼족오 깃털 | Samjogo Gitteo | Three-Legged Crow Feather | Legendary | Gain 1 extra Qi each turn. However, 2 Curse cards are added to your starting deck. (Samjogo = Sun Crow of legend) |
| R016 | 약재 꾸러미 | Yakmae Kkurumi | Herb Bundle | Common | Remove all Poison from yourself at the start of combat. |
| R017 | 낡은 방패 | Nalgeun Banpae | Worn Shield | Common | Gain 2 Block at the start of each turn. |
| R018 | 이름 없는 비수 | Ireum Eopneun Bisu | Nameless Dagger | Uncommon | Recover 1 Qi immediately each time you kill an enemy. |
| R019 | 도끼 부적 | Dokki Bujeok | Axe Talisman | Uncommon | Recover 1 extra Qi each time you complete the First Verse (2 slots). |
| R020 | 금강석 | Geumgangseok | Diamond | Uncommon | Gain 8 Block at the start of combat. |
| R021 | 용뇨 | Yongnyo | Dragon's Horn | Rare | Recover 1 Qi each time a card is Exhausted. |
| R022 | 흑요석 인장 | Heugyoseok Injang | Obsidian Seal | Rare | Reduce card removal cost at the shop by 25 Gold. |
| R023 | 달빛 거울 | Dalbich Geoul | Moonlight Mirror | Rare | Draw 1 extra card on each Sijo completion. (1 → 2 drawn.) |
| R024 | 혈맹 계약서 | Hyeolmaeng Gyeyakseo | Blood Oath | Uncommon | Gain 15 extra Gold after defeating an Elite. |
| R025 | 오행진 | Ohaengjin | Five Elements Formation | Rare | Gain Strength +1 and max Qi +1 for this combat. Resets after combat. |
| R026 | 천문도 | Cheonmundo | Star Map | Rare | Sijo completion bonus becomes ×2.5 instead of ×2. |
| R027 | 왕의 옥새 | Wangui Oksae | Royal Seal | Rare | Gain 15 Block at the start of Boss combat. |
| R028 | 불사신 부적 | Bulsasin Bujeok | Immortal Talisman | Legendary | Once per run: survive lethal damage with 1 HP. |
| RS001 | 부적 낭 | Bujeok Nang | Talisman Pouch | Uncommon | Add 1 random Talisman card to hand at combat start. |
| RS002 | 마패 | Mapae | Royal Warrant | Uncommon | Auto-summon 1 Soldier Token at combat start. |
| RS003 | 필연 | Pilyeon | Destiny | Uncommon | Gain 2 Scholarship at combat start. |
| | RM001 | 병서 | Byeongseo | Military Manual | Rare | Gain 1 extra Stamina each time you play a Formation card. (Officer only.) |
| RW001 | 어진 | Eojin | Royal Portrait | Rare | Recover 5% max HP each time you fully spend Scholarship. (Scholar only.) |
| RD001 | 선단 | Seondan | Immortal's Cinnabar | Rare | Gain 1 extra Qi each time you play a Spell card. (Sorcerer only.) |
| RD002 | 음양패 | Eumyang-pae | Yin-Yang Token | Rare | Draw 1 card each time a summoned token dies. (Sorcerer only.) |
| RB001 | 이무령 인장 | Yi Muryeong Injang | Yi Mu-ryeong's Seal | Boss | Card removal at shop costs 0 Gold. |
| RB002 | 쌍두호 가죽 | Ssangduho Gajuk | Twin-Head Tiger Hide | Boss | Gain Strength +3 at combat start. Resets after combat. |
| RB003 | 역적 대감 관인 | Yeokjeok Daegam Gwanin | Traitor Minister's Official Seal | Boss | Sijo completion bonus becomes ×3 (does not stack with R026; max ×3). |

---

## 6. 적 이름 번역표

### 6.1 1막 — 한양 (Hanyang, the Capital)

| ID | 한국어 | 로마자 | 영문 이름 | 유형 | 설명 |
|----|--------|--------|-----------|------|------|
| E001 | 불량배 | Bullyangbae | Street Thug | 일반 | 조선 시대 골목 건달 |
| E002 | 포졸 | Pojol | Royal Constable | 일반 | 포도청 하급 관리 |
| E003 | 원혼 | Wonhon | Vengeful Spirit | 일반 | 억울하게 죽은 귀신 |
| E004 | 도깨비 | Dokkaebi | Dokkaebi | 일반 | 고유명사 보존. 괄호로 "Trickster Goblin" 병기 |
| EL001 | 이무기 | Imugi | Imugi | 엘리트 | 고유명사 보존. 괄호로 "Serpent Wyrm" 병기 |
| B_ACT1_FINAL | 판서 이무령 | Panseo Yi Mu-ryeong | Minister Yi Mu-ryeong | 보스 | 판서(Panseo) = Senior Minister of the Board of Personnel |

### 6.2 2막 — 산속 (The Mountain)

| ID | 한국어 | 로마자 | 영문 이름 | 유형 |
|----|--------|--------|-----------|------|
| E201 | 산적 | Sanjok | Mountain Bandit | 일반 |
| E202 | 처녀귀신 | Cheonyeo Gwisin | Maiden Wraith | 일반 |
| E203 | 산사 승병 | Sansa Seungbyeong | Warrior Monk | 일반 |
| EL201 | 백호 | Baekho | White Tiger | 엘리트 |
| B_ACT2_FINAL | 쌍두 호랑이 | Ssangdu Horangi | Twin-Headed Tiger | 보스 |

### 6.3 3막 — 무덤/저승 (The Tomb / Underworld)

| ID | 한국어 | 로마자 | 영문 이름 | 유형 |
|----|--------|--------|-----------|------|
| E301 | 역적 무사 | Yeokjeok Musa | Rebel Warrior | 일반 |
| E302 | 역모 문관 | Yeokmo Mungwan | Treasonous Scholar | 일반 |
| E303 | 자객 | Jagaek | Assassin | 일반 |
| EL301 | 역적 장수 | Yeokjeok Jangsu | Rebel General | 엘리트 |
| B_ACT3_FINAL | 역적 대감 | Yeokjeok Daegam | Rebel High Minister | 보스 |

### 6.4 막 이름 번역

| 한국어 | 영문 |
|--------|------|
| 한양 | Hanyang — The Capital |
| 산속 | The Mountain Wilds |
| 무덤 | The Ancient Tomb |
| 저승 | The Underworld (후보, 미확정) |

---

## 7. 이벤트 제목 번역표

### 7.1 1막 이벤트

| ID | 한국어 제목 | 영문 제목 |
|----|------------|-----------|
| EVT_A1_001 | 늙은 행인 | The Old Traveler |
| EVT_A1_002 | 포졸의 검문 | Guard Checkpoint |
| EVT_A1_003 | 원혼의 한탄 | The Spirit's Lament |
| EVT_A1_004 | 길거리 상인 | Street Merchant |
| EVT_A1_005 | 신당 | The Roadside Shrine |
| EVT_A1_006 | 노박판 | The Gambling Den |
| EVT_A1_007 | 버려진 무기 | Abandoned Weapon |
| EVT_A1_008 | 거리의 의원 | The Street Healer |

| EVT_A1_009 | 버려진 카드 뭉치 | Discarded Card Bundle |
| EVT_A1_010 | 굶주린 걸인 | The Starving Beggar |
| EVT_A1_011 | 신령 나무 | The Sacred Tree |
| EVT_A1_012 | 떠돌이 상인 | The Wandering Merchant |

### 7.2 2막 이벤트

| ID | 한국어 제목 | 영문 제목 |
|----|------------|-----------|
| EVT_A2_001 | 산사의 승려 | The Mountain Monk |
| EVT_A2_002 | 산적의 매복 | Bandit Ambush |
| EVT_A2_003 | 약초 채집터 | Herb Gathering Spot |
| EVT_A2_004 | 산신령의 시련 | The Mountain God's Trial |
| EVT_A2_005 | 폭포 수련장 | Waterfall Training Ground |
| EVT_A2_006 | 버려진 광산 | Abandoned Mine |
| EVT_A2_007 | 산신의 시험 | The Mountain Spirit's Test |
| EVT_A2_008 | 독사의 굴 | Viper's Den |
| EVT_A2_009 | 도술 수련자 | Daoist Trainee |

### 7.3 3막 이벤트

| ID | 한국어 제목 | 영문 제목 |
|----|------------|-----------|
| EVT_A3_001 | 충신의 밀서 | Loyal Minister's Secret Letter |
| EVT_A3_002 | 궁녀의 부탁 | Court Lady's Request |
| EVT_A3_003 | 어의의 치료실 | Royal Physician's Chamber |
| EVT_A3_004 | 역적의 함정 | Traitor's Trap |
| EVT_A3_005 | 왕의 서재 | The King's Study |
| EVT_A3_006 | 전투 전야 | Eve of Battle |
| EVT_A3_007 | 왕의 밀명 | The King's Secret Command |
| EVT_A3_008 | 역모 문서 | Treasonous Document |
| EVT_A3_009 | 마지막 결전 전야 | Final Battle's Eve |

### 7.4 이벤트 선택지 공통 패턴

| 한국어 | 영문 |
|--------|------|
| (결과 텍스트) HP X 회복 | Recover X HP. |
| 엽전 X 소비 | Spend X Gold. |
| 유물 1개 획득 | Gain 1 Relic. |
| 카드 1장 획득 | Gain 1 Card. |
| 아무 일도 일어나지 않는다 | Nothing happens. |
| 거절/무시 선택지 | "Walk away." / "Ignore it." |

---

## 8. 상태이상 번역표

| 한국어 | 한자 | 영문 이름 | 영문 설명 |
|--------|------|-----------|-----------|
| 약화 | | Weakened | Next attack deals 25% less damage. Expires after 1 use. |
| 화상 | | Burn [X] | Take X damage at end of turn. X decreases by 1 each turn. |
| 독 | | Poison [X] | Take X damage at end of turn. X decreases by 1 each turn. |
| 방어도 | | Block | Absorbs incoming damage this turn. Lost at start of your turn. |
| 버프 | — | Buff | Positive status effect with a duration. |
| 디버프 | — | Debuff | Negative status effect applied to enemies. |
| 기 회복 | — | Qi +X | Recover X Qi immediately. |
| 병사 토큰 | — | Soldier Token | Absorbs 1 hit, then vanishes. Recover 1 Qi on death. |
| 기력 | | Stamina | Mugwan resource. Carries between turns. Max 10. |

---

## 9. UI 텍스트 번역표

### 9.1 전투 화면

| 한국어 | 영문 |
|--------|------|
| 기 | Qi |
| 기 : X | Qi: X |
| 방어도 | Block |
| 손패 | Hand |
| 드로우 | Draw |
| 버리기 | Discard |
| 턴 종료 | End Turn |
| 승리 | Victory! |
| 패배 | Defeated |
| 보스 처치 후 HP 20% 회복 | Recover 20% Max HP after boss. |

### 9.2 카드 텍스트 공통

| 한국어 | 영문 |
|--------|------|
| X 피해를 입힌다 | Deal X damage. |
| 모든 적에게 X 피해를 입힌다 | Deal X damage to ALL enemies. |
| 방어도 X를 획득한다 | Gain X Block. |
| 카드 X장을 드로우한다 | Draw X card(s). |
| 기 X를 획득한다 | Gain X Qi. |
| 업그레이드 | Upgrade |
| 강화됨 | Enhanced |
| 이번 턴 | This turn |
| 이미 카드를 1장 이상 사용했다면 | If you've already played a card this turn, |

### 9.3 맵/노드

| 한국어 | 영문 |
|--------|------|
| 전투 | Combat |
| 엘리트 | Elite |
| 보스 | Boss |
| 상점 | Shop |
| 이벤트 | Event |
| 휴식 | Rest |
| 보물 | Treasure |

### 9.4 상점

| 한국어 | 영문 |
|--------|------|
| 카드 제거 | Remove Card |
| 카드 업그레이드 | Upgrade Card |
| 구매 | Buy |
| 판매 | Sell |
| 엽전 | Gold |
| 잔여 엽전 | Gold: X |

### 9.5 보상 화면

| 한국어 | 영문 |
|--------|------|
| 전투 보상 | Combat Reward |
| 카드 선택 | Choose a Card |
| 유물 획득 | Relic Acquired |
| 건너뛰기 | Skip |

### 9.6 등급 표시

| 한국어 | 영문 |
|--------|------|
| 일반 | Common |
| 고급 | Uncommon |
| 희귀 | Rare |
| 전설 | Legendary |

### 9.7 시스템 / 설정

| 한국어 | 영문 |
|--------|------|
| 설정 | Settings |
| 음악 | Music |
| 효과음 | SFX |
| 진동 | Vibration |
| 언어 | Language |
| 한국어 | 한국어 (Korean) |
| 영어 | English |
| 저장 | Save |
| 나가기 | Quit |
| 포기 | Abandon Run |

---

## 10. 언어 전환 UI 명세

### 10.1 설정 화면 언어 선택 항목

```
[Settings]
 Language / 언어
 ┌─────────────────────────────┐
 │ ● 한국어 (Korean) │
 │ ○ English │
 └─────────────────────────────┘
 [확인 / Confirm]
```

- 언어 전환은 즉시 적용 (재시작 불필요)
- 전환 시 모든 UI, 카드 텍스트, 적 이름, 이벤트 텍스트가 즉시 교체됨
- 현재 런 도중 언어 전환 허용 (런 진행에 영향 없음)

### 10.2 언어 파일 구조

```
joseon-deckbuilder/
 locale/
 en.json ← 영어 (생성 완료 ✓)
 ko.json ← 한국어 (기본, 미생성)
```

> **✅ locale/en.json 생성 완료** (2026-04-02, ZER-110)
> 전체 87개 카드, 40개 유물, 30개 이벤트, 33개 적, UI 텍스트 전체 포함.

### 10.3 locale/en.json 최상위 구조

```json
{
 "_meta": { "language": "en", "version": "0.1" },
 "classes": { "dosa": {...}, "mugwan": {...}, "mungwan": {...} },
"labels": {...} },
 "resources": { "qi": {...}, "stamina": {...}, "scholarship": {...} },
 "status_conditions": { "burn": {...}, "poison": {...}, ... },
 "ui": { "main_menu": {...}, "hud": {...}, "combat": {...}, ... },
 "cards": { "M001": { "name": "...", "effect": "...", "effect_upgraded": "..." }, ... },
 "relics": { "R001": { "name": "...", "effect": "..." }, ... },
 "enemies": { "act_1": { "regular": {...}, "elite": {...}, "bosses": {...} }, ... },
 "events": { "EVT_A1_001": { "title": "..." }, ... },
 "game": { "title": "Sijojeon", "acts": {...} }
}
```

---

## 11. 레이아웃 고려사항

### 11.1 텍스트 길이 제한 (모바일 세로 기준)

| 요소 | 최대 글자 수 | 주의사항 |
|------|-------------|----------|
| 카드 이름 | 20자 | 영어는 한국어보다 길어질 수 있음 |
| 카드 효과 (1줄) | 80자 | 줄바꿈 허용 시 2줄 이내 |
| 유물 이름 | 25자 | — |
| 적 이름 | 20자 | — |
| 이벤트 제목 | 30자 | — |
| 이벤트 선택지 | 60자 | 버튼 텍스트 기준 |

### 11.2 줄바꿈 처리 원칙

- 카드 이름은 줄바꿈 없이 한 줄
- 카드 효과는 최대 2줄, 업그레이드 효과는 최대 2줄
- 조건부 효과는 "If [condition]," 패턴으로 시작

### 11.3 고유명사 병기 규칙

- 도깨비: **Dokkaebi** *(Trickster Goblin)* — 첫 등장 시만 병기
- 이무기: **Imugi** *(Serpent Wyrm)* — 첫 등장 시만 병기
- 동의보감: **Dongui Bogam** *(Traditional Medical Encyclopedia)* — 유물 설명에 병기
- 만파식적: **Manpasikjeok** *(Mystical Flute of Legend)* — 유물 설명에 병기

---

*이 문서는 ZER-110 작업의 결과물입니다. 구현 진행에 따라 추가 번역이 필요한 항목을 보완하십시오.*
*최종 번역 검수는 네이티브 영어 화자 리뷰를 권장합니다.*
