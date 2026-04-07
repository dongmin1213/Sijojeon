# 시조전 — NanoBanana 프롬프트 가이드

> 버전: 2.0 | 최종 업데이트: 2026-04-06
> Google NanoBanana 2 (Gemini Plus) 기반 에셋 생성 프롬프트 모음
> **아트 스타일: SD(슈퍼디폼) 하이브리드 도트 일러스트**
> 참조: 가디언테일즈, 메이플스토리, 월드플리퍼

---

## 프롬프트 작성 원칙 (리서치 기반)

1. **문장형 서술** — 태그 나열이 아닌 일러스트레이터에게 브리핑하듯 자연어로 작성
2. **6요소 순서** — 주제 → 구도 → 액션 → 세팅 → 스타일 → 기술 스펙
3. **200단어 이내** — 너무 긴 프롬프트는 뒷부분이 무시됨. 핵심을 앞에 배치
4. **모순 금지** — "미니멀"과 "복잡한 디테일" 동시 사용 X
5. **흰 배경 + rembg** — NanoBanana는 투명 배경(alpha) 미지원. `plain white background`로 생성 후 rembg로 AI 배경 제거 (흰 배경이 테두리 잔상 최소)
6. **참조 이미지 활용** — 첫 결과물을 참조 이미지로 업로드하면 스타일 편차 대폭 감소
7. **2~4턴 반복 수정** — 첫 결과물을 바로 쓰지 말고, 대화형으로 수정 요청하여 퀄리티 향상
8. **참조 게임명 명시** — NanoBanana가 실제 게임 스타일 지식을 활용하여 캘리브레이션
9. **방향 규칙** — 플레이어 캐릭터는 **오른쪽(facing right)**, 적/몬스터는 **왼쪽(facing left)** 바라봄. Slay the Spire 구도 (플레이어 좌측, 적 우측)
10. **플레이어 톤** — 플레이어 캐릭터는 "cute" 대신 "fierce/powerful/commanding" 등 강인한 톤. 적보다 위엄 있게

---

## 한국 vs 중국 구분 핵심 (필독)

AI 도구는 "Joseon"만으로는 중국풍을 생성하는 경향이 있다. 반드시 아래 한국 고유 키워드를 사용할 것:

| 한국 (사용) | 중국 (금지) |
|---|---|
| Korean hanbok (저고리+바지/치마) | Chinese hanfu, long flowing robes |
| Gat (갓, 검은 말총 모자), sangtu topknot | Chinese guanmao, queue hairstyle |
| Dopo (도포), durumagi (두루마기) | Changshan, tangzhuang |
| Korean curved roof (완만한 곡선, 처마) | Chinese dramatic upturned roof corners |
| Obangsaek 5-color (백/흑/적/청/황) | Chinese red-gold dominant |
| Dancheong wooden bracket painting | Chinese dougong bracket system |
| Korean jangot/norigae accessories | Chinese jade pendants/tassels |
| Stone walls with low gates | Chinese red lacquered pillars/gates |

프롬프트에 **반드시** "Korean (NOT Chinese)" 또는 "distinctly Korean, not Chinese style"을 포함할 것.

---

## 공통 스타일 프리픽스

모든 캐릭터/적 프롬프트 앞에 붙이는 스타일 지정 문구:

```
A chibi game character sprite in the style of Guardian Tales and MapleStory.
Super-deformed proportions — the head is about 40% of the total character height, with a large expressive face, stubby limbs, and a compact body approximately 2.5 heads tall.
High-resolution pixel art illustration with smooth shading and vibrant colors.
Korean Joseon dynasty costume — NOT Chinese. Specifically Korean hanbok-based clothing: jeogori (저고리) short jacket, baji (바지) trousers or chima (치마) skirt, dopo (도포) overcoat. Korean gat (갓) horsehair hat or sangtu (상투) topknot hairstyle. Obangsaek color palette (white, black, vermillion red, indigo blue, golden yellow) with dancheong accents.
Full body character on a plain white background with no shadows, no ground, and no other elements.
No text, no watermark, no border, no frame. Not Chinese style.
```

아이콘 프리픽스:

```
A crisp game icon in pixel art illustration style.
Korean traditional obangsaek and dancheong color palette: vermillion, indigo, gold, pine green, white.
Korean Joseon dynasty aesthetic — NOT Chinese.
Clean edges, sharp silhouette readable at small sizes.
Plain white background with no shadows.
No text, no border, no frame.
```

---

## 1. 플레이어 캐릭터

### char_mugwan — 무관 (武官)

```
[스타일 프리픽스]
Draw a fierce chibi Korean Joseon military officer (무관) ready for battle. He wears Korean-style lamellar armor (두정갑) over a dark navy blue jeogori jacket and baji trousers. He carries a Korean hwando (환도) single-edged curved sword drawn and ready. He has a fierce determined expression with sharp eyes, a Korean sangtu topknot under a Korean warrior's headband (전립 or 벙거지 military hat). Compact sturdy body in an aggressive battle-ready stance facing slightly right. Korean armor differs from Chinese — it uses riveted plates over fabric, not scales or lacquer. NOT Chinese style.
```

### char_dosa — 도사 (道士)

```
[스타일 프리픽스]
Draw a powerful chibi Korean Joseon Taoist mystic (도사) channeling supernatural energy. He wears a white Korean dopo (도포) overcoat with wide sleeves over a blue jeogori, tied with a Korean cloth belt (대대). He holds a glowing Korean paper talisman (부적) with red ink characters in one hand. He has a long white beard, intense piercing eyes, a Korean sangtu topknot with a jade binyeo pin, and wears a Korean jeongjagwan (정자관) horsehair hat. He faces slightly right. Ethereal teal glow. NOT Chinese robes.
```

### char_mungwan — 문관 (文官)

```
[스타일 프리픽스]
Draw a commanding chibi Korean Joseon civil scholar-official (문관) with an aura of authority. He wears a Korean samo (사모) black winged hat and a crimson dallyeong (달령) court robe with a Korean rank badge (흉배) on the chest — a square embroidered panel showing a crane. He holds a calligraphy brush with glowing hanja characters floating around. He has sharp intelligent eyes, a neatly trimmed beard, and a dignified stance facing slightly right. Korean samo hat has horizontal "wings" on the sides — NOT a Chinese guanmao. NOT Chinese official robes.
```

---

## 2. 적 캐릭터 — 1막 (한양)

### E001 — 불량배

```
[스타일 프리픽스]
Draw a cute chibi Korean Joseon street thug (불량배). He wears torn and dirty Korean hemp jeogori and baji with visible patches, straw sandals (짚신). He wields a crude short knife in an aggressive forward-leaning stance. Scar across cheek, missing tooth, wild menacing eyes. NOT Chinese clothing.
```

### E002 — 하급 포졸

```
[스타일 프리픽스]
Draw a cute chibi corrupt Korean Joseon constable (포졸) facing slightly left. He wears a Korean red jeonbok (전복) military vest over dark jeogori and baji, with a Korean jeonrip (전립) round military hat with a tassel. He carries a wooden cudgel (곤장) over one shoulder with a smirking expression. Pudgy compact build. Korean military uniform — NOT Chinese.
```

### E003 — 전당포 주인

```
[스타일 프리픽스]
Draw a cute chibi sly Korean Joseon pawnshop owner (전당포 주인) facing slightly left. He wears a dark gray Korean durumagi (두루마기) overcoat with a Korean cloth belt, a Korean gat (갓) horsehair hat. He holds a Korean wooden abacus (주판). Thin face, narrow cunning eyes, calculating hunched posture. NOT Chinese merchant.
```

### E004 — 떠돌이 도적

```
[스타일 프리픽스]
Draw a cute chibi Korean Joseon mountain bandit (도적) facing slightly left. He wears ragged patched Korean hemp clothing with a tattered cloak. Hair in a messy undone sangtu topknot. Wields a short dagger in a crouching ambush-ready stance with wild desperate eyes. Korean peasant clothing style. NOT Chinese.
```

### E005 — 원혼

```
[스타일 프리픽스]
Draw a cute chibi Korean vengeful ghost (원혼) facing slightly left. She wears a tattered Korean white sobok (소복) mourning hanbok — jeogori and chima. Long straight black hair covers part of her face, glowing hollow eyes. Semi-transparent pale blue-white form floating above ground with wispy spirit trails. Korean ghost (귀신) aesthetic — NOT Chinese jiangshi.
```

### E006 — 도깨비불

```
[스타일 프리픽스]
Draw a Korean spirit fire (도깨비불) — a distinctly Korean folklore spirit, NOT Chinese. Swirling blue-green and orange flame orb about the size of a head. Faint mischievous face-like features within the flames, trailing fire wisps and vivid glow. Dynamic flickering motion. Korean folk art (민화) style influence.
```

### E007 — 관노

```
[스타일 프리픽스]
Draw a cute chibi Korean Joseon government slave (관노) facing slightly left, forced to fight. He wears rough Korean hemp jeogori and baji with iron shackles on wrists. Wields a makeshift iron pitchfork. Compact sturdy build, desperate haunted expression, barefoot. Korean commoner (상민) clothing. NOT Chinese.
```

### E008 — 기방 청객

```
[스타일 프리픽스]
Draw a cute chibi drunken Korean Joseon gisaeng house patron (청객) facing slightly left. He wears disheveled Korean dopo (도포) nobleman's overcoat with untied cloth belt, a tilted Korean gat (갓) hat askew. He holds a Korean folding fan (합죽선) as weapon. Flushed red face, bleary aggressive eyes, portly build. Korean nobleman clothing. NOT Chinese.
```

### E009 — 야경꾼

```
[스타일 프리픽스]
Draw a cute chibi Korean Joseon night watchman (야경꾼) facing slightly left. He wears dark blue-black Korean patrol jeogori and baji with a Korean jeonrip (전립) round hat. He carries a Korean paper lantern (등롱) on a pole with warm glow and a short spear (창). Alert stern expression, lean vigilant build. NOT Chinese guard.
```

### E010 — 시전 상인

```
[스타일 프리픽스]
Draw a cute chibi corrupt Korean Joseon market merchant (시전 상인) facing slightly left. He wears a fine silk Korean durumagi (두루마기) with a Korean gat (갓) hat. He holds a rigged weighted scale, calculating expression, thin mustache. Korean yeop-jeon (엽전) square-holed coins in pouches at belt. NOT Chinese merchant.
```

### E011 — 나팔수

```
[스타일 프리픽스]
Draw a cute chibi Korean Joseon government herald (나팔수) facing slightly left. He wears dark blue Korean official jeogori and baji with a red sash and a Korean jeonrip hat. He holds a Korean traditional trumpet (나팔) ready to blow. Young face, nervous dutiful expression, slim build. NOT Chinese.
```

---

## 3. 1막 엘리트 적

### EL001 — 양반

```
[스타일 프리픽스]
Draw a larger cute chibi tyrannical Korean Joseon aristocrat (양반) facing slightly left. He wears a luxurious silk Korean dopo (도포) in dark purple with gold embroidery over a white jeogori. He wears a tall Korean gat (갓) horsehair hat — the wide-brimmed black hat distinctive to Korean yangban class. He holds a long Korean bamboo smoking pipe (곰방대) like a scepter with arrogant expression. Groomed beard, aura of authority. Korean nobleman, NOT Chinese mandarin. Larger and more detailed than regular sprites.
```

### EL002 — 독사

```
[스타일 프리픽스]
Draw a larger cute chibi Korean Joseon poison assassin (독사) facing slightly left. He wears all-black Korean-style tight clothing (자객복) with a dark face mask — only cold calculating serpent-like eyes visible. Multiple green and purple poison vials strapped across chest with glow effect. Korean-style stealthy assassin with a short Korean dagger (비수). Crouches in strike-ready pose with toxic mist around hands. NOT Chinese wuxia assassin. Larger and more detailed.
```

### EL003 — 포수

```
[스타일 프리픽스]
Draw a larger cute chibi Korean Joseon elite hunter (포수) facing slightly left. He wears practical Korean hunting clothes — a short jeogori with leather chest guard, Korean-style leggings. He carries a Korean gakgung (각궁) composite bow on his back and holds a Korean matchlock musket (조총) with smoke wisps. Weathered face, sharp hawk-like eyes, stubble beard. Korean hunter, NOT Chinese. Larger and more detailed.
```

---

## 4. 보스

### B_ACT1_FINAL — 판서 이무령

```
[스타일 프리픽스]
Draw a boss-scale cute chibi corrupt Korean Joseon Minister (이조판서) facing slightly left. He sits on a Korean-style official's chair (교의) wearing the highest rank Korean dallyeong (달령) crimson court robe with a Korean crane hyungbae (흉배) rank badge — a square embroidered panel on the chest. He wears a Korean samo (사모) hat with wide horizontal wings. He holds a glowing red royal seal (어인) in one hand. Cold merciless eyes, white trimmed beard. Korean government official aesthetic — NOT Chinese imperial. Much larger and more imposing.
```

### B_ACT2_FINAL — 쌍두 호랑이

```
[스타일 프리픽스]
Draw a boss-scale chibi monstrous twin-headed Korean tiger (쌍두 호랑이) — the tiger is a sacred animal in Korean folklore (호랑이). Two distinct heads: left is calculating with cold blue eyes, right is ferocious and roaring with fiery orange eyes. Enormous muscular body with Korean minhwa (민화 folk painting) style markings on fur, supernatural golden glow on tiger stripes. Korean folk art tiger aesthetic with playful-yet-fierce quality. NOT Chinese dragon. Much larger than regular sprites.
```

### B_ACT3_FINAL — 역적 대감

```
[스타일 프리픽스]
Draw a boss-scale cute chibi treasonous Korean Joseon lord (역적 대감) facing slightly left. He wears a Korean dallyeong court robe with forbidden dragon embroidery (only the king may wear dragons) and a Korean samo hat. Face half in shadow, one eye gleaming with ambition, sinister smile. He holds a forged royal decree (교서) in one hand and a hidden Korean dagger (비수) in the other. Dark crimson and black aura. Korean power aesthetics — NOT Chinese emperor robes. Much larger and more imposing.
```

---

## 5. 카드 일러스트 (주요 카드)

카드 공통 프리픽스:
```
A dynamic action scene illustration for a card game panel in high-resolution pixel art illustration style.
Korean Joseon dynasty setting — characters wear Korean hanbok clothing, NOT Chinese.
Obangsaek and dancheong color palette with dramatic lighting and smooth shading.
No text, no border, no frame — illustration only.
Plain white background with no shadows and no other elements.
```

### M001 — 회피 (回避)

```
[카드 공통]
A Korean Joseon warrior in hanbok gracefully sidestepping a sword strike. Korean dopo robes trail behind the dodge with motion blur. Fluid circular evasion movement. Cool blue and silver tones.
```

### M002 — 도약 (跳躍)

```
[카드 공통]
A Korean warrior in hanbok leaping powerfully upward, pushing off with one foot. Korean dopo robes billowing from upward momentum. Below, enemy attack passes through empty air. Warm gold and green tones with ascending energy trails.
```

### M003 — 베기

```
[카드 공통]
A decisive downward slash with a Korean hwando (환도) single-edged curved sword. The blade catches light in a dramatic arc with energy trail. Korean warrior in jeogori and baji. Strong vermillion red and steel gray tones.
```

### M004 — 수호

```
[카드 공통]
A Korean warrior in hanbok in defensive stance with arms crossed, emanating a qi shield. Translucent indigo-blue barrier forms in front with ripple effects. Solid rooted posture, calm determined expression. Cool indigo and white tones.
```

### M005 — 집중

```
[카드 공통]
A Korean figure in white dopo kneeling in meditation with eyes closed. Golden qi energy wisps spiral inward toward the body. Calm serene atmosphere with soft glowing aura. Korean Joseon scholar meditation pose. Gold and soft violet tones.
```

### G001 — 진형 전환 (陣形轉換)

```
[카드 공통]
A Korean Joseon military officer in jeonbok vest and jeonrip hat commanding a formation change. Korean soldiers in hanbok uniforms shift like chess pieces with motion trails. Korean military flags (독기) waving with Korean characters. Gold and dark navy tones. Korean military aesthetic.
```

### G002 — 돌격 진형

```
[카드 공통]
A V-shaped charging formation of Korean Joseon soldiers in jeonbok military vests and jeonrip hats. Lead warrior charges with Korean hwando sword raised, soldiers flanking behind with Korean spears. Dust clouds and motion blur. Fierce vermillion and iron gray tones.
```

### D001 — 부적 투척

```
[카드 공통]
A Korean Joseon Taoist mystic in white dopo overcoat throwing a burning Korean paper talisman (부적) with red ink characters. Talisman mid-flight trailing golden fire and Korean mystical symbols. Korean dopo robes billow with supernatural energy. Teal and gold tones. NOT Chinese Taoist.
```

### W001 — 경연 (經筵)

```
[카드 공통]
A Korean Joseon scholar-official in dallyeong court robe and samo hat delivering a lecture from an ancient text. Korean hanja characters from the book materialize as glowing text floating in air. Other Korean scholars in dopo overcoats listen in a Korean study room (서재) with hanji paper walls. Warm gold and deep brown tones.
```

---

## 6. 배경 이미지

배경 프리픽스:
```
A detailed high-resolution pixel art illustration scene for a mobile RPG game.
Korean Joseon dynasty historical setting — distinctly Korean architecture, NOT Chinese.
Korean features: giwa (기와) gray clay roof tiles with gentle curves (NOT dramatic Chinese upturned corners), dancheong painted wooden eaves, stone foundations, ondol underfloor heating chimneys, jangdokdae (장독대) clay pot platforms in courtyards.
Obangsaek and dancheong color palette.
No text, no watermark.
```

### bg_title — 타이틀 화면

```
[배경 프리픽스]
A majestic panoramic view of Korean Joseon-era Hanyang (Seoul) at sunset. Korean palace (경복궁 Gyeongbokgung style) rooftops with distinctive Korean giwa tiles and dancheong painted eaves in the foreground. Bukhansan mountains behind with atmospheric depth. Korean stone walls and gates visible. The sky transitions through vermillion, gold, and deep indigo. A lone figure wearing a Korean gat hat is silhouetted on a rooftop. Leave empty space in the upper third for a game title. Korean cityscape — NOT Chinese. Portrait orientation 1080x1920.
```

### bg_battle — 전투 배경

```
[배경 프리픽스]
A dark Korean Joseon-era street at night with Korean paper lanterns (등롱) casting warm volumetric glow. Korean wooden buildings with gray giwa clay tile roofs (gentle curves, NOT dramatic Chinese upturns) and dancheong painted eaves line both sides of a stone-paved path. Low fog, moon visible through clouds. Korean architectural details: wooden lattice windows (살창), stone walls, simple wooden doors. NOT Chinese red-lacquered buildings. Leave space for UI. Portrait 1080x1920.
```

### bg_map — 맵 배경

```
[배경 프리픽스]
A landscape map in Korean traditional painting style (산수화 sansuhua). Misty Korean mountains, winding paths through Korean pine forests (소나무), and a river with reflections. Small Korean hanok (한옥) buildings with gray tile roofs scattered across the landscape. Korean-style stone bridges. Muted Korean ink wash painting palette with subtle color and atmospheric depth. Korean landscape — NOT Chinese. Portrait 1080x1920.
```

### bg_shop — 상점 배경

```
[배경 프리픽스]
The warm interior of a Korean Joseon-era marketplace shop (시전). Korean-style wooden shelves display medicines in Korean ceramic jars (약항아리), Korean swords, scrolls, and talismans. Merchant's counter has a Korean abacus (주판) and pile of Korean yeop-jeon (엽전) square-holed brass coins. Warm Korean paper lantern (등잔) light fills the space. Korean wooden lattice windows, hanji paper walls. NOT Chinese shop. Leave space for UI. Portrait 1080x1920.
```

### bg_rest — 휴식처 배경

```
[배경 프리픽스]
A peaceful Korean Joseon-era roadside inn (주막) at twilight. A Korean thatched-roof (초가집) building with a wooden maru (마루) elevated wooden floor porch under an old pine tree. A Korean rice wine pot (막걸리 항아리) sits on a low wooden table (소반). Jangdokdae clay pots nearby. Fireflies glow in warm air. Serene atmosphere in warm amber and soft green tones. Korean countryside architecture — NOT Chinese. Leave space for UI. Portrait 1080x1920.
```

### bg_event — 이벤트 배경

```
[배경 프리픽스]
A mysterious Korean Joseon-era forest path at night for a random encounter scene. A narrow dirt road winding through dense Korean pine trees (소나무) and bamboo. A Korean jangseung (장승) wooden guardian totem stands at the roadside with a carved fierce face. A Korean stone lantern (석등) emits faint warm light nearby. Low fog and mist drift across the path. Fireflies float in the air. Distant mountains barely visible through haze. Eerie yet beautiful atmosphere in deep teal, dark green, and pale moonlight tones. Korean folk road — NOT Chinese. Leave upper portion for event text UI. Portrait 1080x1920.
```

### bg_reward — 보상 배경

```
[배경 프리픽스]
A Korean Joseon-era treasure room or reward alcove. An open Korean wooden chest (궤) overflowing with scrolls, Korean brass coins (엽전), talismans (부적), and a glowing sword. Warm golden light emanates from within. Korean hanji paper sliding doors frame the scene. Korean dancheong painted wooden beams overhead. Rich warm gold, amber, and deep brown tones with volumetric light rays. Korean traditional interior — NOT Chinese. Leave space for card selection UI. Portrait 1080x1920.
```

### bg_gwageo — 과거시험 배경

```
[배경 프리픽스]
A Korean Joseon-era civil service examination hall (과거 시험장). Rows of low wooden desks with ink, brushes, and hanji paper under a large open-air Korean pavilion with gray giwa tile roof and dancheong painted eaves. Korean examiners in samo hats observe from an elevated platform. Korean paper lanterns hang overhead for evening lighting. Tension and formality in the atmosphere. Cool indigo, warm gold, and stone gray tones. Korean examination aesthetic — NOT Chinese imperial exam. Leave center space for minigame UI. Portrait 1080x1920.
```

---

## 7. 유물 아이콘

### R001 — 편자 (鞭子)

```
[아이콘 프리픽스]
A worn leather horse whip (편자) coiled in a circle with a dark brown leather and brass handle tip. Faint golden glow. 128x128.
```

### R002 — 평안 부적

```
[아이콘 프리픽스]
A yellow paper talisman (부적) with red ink characters. Traditional rectangular shape with mystical symbols. Soft golden aura. 128x128.
```

### R003 — 행운의 엽전

```
[아이콘 프리픽스]
A Korean traditional coin (엽전), round with a square hole. Greenish bronze patina with golden highlights and faint sparkles. 128x128.
```

### R004 — 봉황 깃털

```
[아이콘 프리픽스]
A phoenix feather (봉황 깃털) with iridescent rainbow shimmer. Long elegant shape with a golden quill and fire wisps at the tip. 128x128.
```

### R005 — 홍삼 뿌리

```
[아이콘 프리픽스]
A Korean red ginseng root (홍삼) in dark reddish-brown. Earthy organic form with small rootlets and a faint warm red healing aura. 128x128.
```

---

## 8. 상태이상 아이콘

```
[아이콘 프리픽스] — 각각 64x64

독 (Poison): Green bubbling vial with skull vapor rising.
화상 (Burn): Orange-red flame with dynamic fire effect.
출혈 (Bleed): Three dark red blood drops in triangle formation.
사망각인 (Death Mark): Black skull with red X mark and ominous glow.
약화 (Weakness): Broken sword, gray and dull with crack detail.
취약 (Vulnerable): Cracked shield with red glowing cracks.
냉기 (Chill): Blue snowflake with frost effect.
힘 (Strength): Red flexing fist with power aura.
가시 (Thorns): Green thorny vine circle with sharp detail.
갑옷 (Armor): Iron chestplate, metallic gray with shine highlight.
```

---

## 사용법

1. Gemini Plus (gemini.google.com) 접속
2. `[스타일 프리픽스]` + 개별 프롬프트를 결합하여 입력
3. **첫 결과물이 완벽하지 않으면 대화형으로 2~4턴 수정 요청** — "머리를 더 크게", "몸을 더 짧게" 등
4. 생성된 이미지 PNG 다운로드
5. **배경 제거 (rembg)**:
   ```
   cd C:\rembg
   venv\Scripts\python process.py [이미지파일 또는 폴더]
   ```
   또는 `run.bat` 위에 이미지/폴더를 드래그 앤 드롭
6. `_done.png` (투명 배경 + 크롭) → `art/` 폴더의 해당 경로에 저장
7. **스타일 일관성**: 첫 번째 결과물을 참조 이미지로 업로드하여 후속 생성에 활용

---

## rembg 배경 제거 셋업

### 설치 (1회)
```
mkdir C:\rembg
cd C:\rembg
python -m venv venv
venv\Scripts\pip install "rembg[cpu]"
```
> 첫 실행 시 u2net 모델 자동 다운로드 (~176MB). CPU 기준 1장당 2~3초.

### 스크립트
`C:\rembg\process.py` — 배경 제거 + 투명 영역 크롭 자동화 스크립트.
`C:\rembg\run.bat` — 드래그 앤 드롭용 배치 파일.

### 사용법
```bash
# 단일 파일
venv\Scripts\python process.py C:\path\to\image.png

# 폴더 일괄 처리
venv\Scripts\python process.py C:\path\to\input_folder

# 출력 폴더 지정
venv\Scripts\python process.py C:\path\to\input_folder C:\path\to\output_folder
```

### 왜 흰 배경 + rembg인가?
- **흰 배경**: 테두리 잔상 최소화 — 크로마키 그린/블루는 가장자리에 색상 번짐 발생
- **rembg (AI 기반)**: 색상이 아닌 피사체 인식으로 분리하므로 배경 색상 무관하게 정확
- **자동 크롭**: 투명 영역을 자동으로 잘라서 스프라이트 사이즈 최적화

---

## 배치 생성 팁

- **참조 이미지가 핵심**: 첫 캐릭터 생성 후 해당 결과물을 모든 후속 프롬프트에 참조 이미지로 첨부 (최대 14장)
- **같은 세션에서 연속 생성**: 동일 대화에서 연속으로 만들면 스타일 일관성 유지
- **rembg 일괄 처리**: 폴더에 모아서 한번에 처리 가능
- **해상도**: NanoBanana의 "512x512" 등 해상도 지정은 구도에만 영향. 실제 출력 사이즈는 API 파라미터로 제어
- **"HD" 키워드**: 해상도가 아닌 디테일 스타일에만 영향
- **아이콘은 한 세트로**: 상태이상 아이콘은 한 프롬프트에 여러 개 구성하여 통일된 스타일 확보
