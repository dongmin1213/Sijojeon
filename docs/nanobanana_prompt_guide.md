# 시조전 — NanoBanana 프롬프트 가이드

> 버전: 1.0 | 최종 업데이트: 2026-04-06
> Google NanoBanana 2 (Gemini Plus) 기반 에셋 생성 프롬프트 모음
> **아트 스타일: SD(슈퍼디폼) 하이브리드 도트 일러스트**
> 참조: 가디언테일즈, 메이플스토리, 월드플리퍼

---

## 프롬프트 작성 원칙 (리서치 기반)

1. **문장형 서술** — 태그 나열이 아닌 일러스트레이터에게 브리핑하듯 자연어로 작성
2. **6요소 순서** — 주제 → 구도 → 액션 → 세팅 → 스타일 → 기술 스펙
3. **200단어 이내** — 너무 긴 프롬프트는 뒷부분이 무시됨. 핵심을 앞에 배치
4. **모순 금지** — "미니멀"과 "복잡한 디테일" 동시 사용 X
5. **크로마키 그린 배경** — NanoBanana는 투명 배경(alpha) 미지원. #00FF00 단색 배경으로 생성 후 후처리로 제거
6. **참조 이미지 활용** — 첫 결과물을 참조 이미지로 업로드하면 스타일 편차 대폭 감소
7. **2~4턴 반복 수정** — 첫 결과물을 바로 쓰지 말고, 대화형으로 수정 요청하여 퀄리티 향상
8. **참조 게임명 명시** — NanoBanana가 실제 게임 스타일 지식을 활용하여 캘리브레이션

---

## 공통 스타일 프리픽스

모든 캐릭터/적 프롬프트 앞에 붙이는 스타일 지정 문구:

```
A cute chibi game character sprite in the style of Guardian Tales and MapleStory.
Super-deformed proportions — the head is about 40% of the total character height, with a large round expressive face, stubby limbs, and a compact body approximately 2.5 heads tall.
High-resolution pixel art illustration with smooth shading and vibrant colors.
Joseon dynasty Korean historical costume design with dancheong color palette (vermillion, indigo, pine green, gold).
Full body character on a flat solid bright green (#00FF00) background with no gradients, no shadows, and no lighting on the background.
The character has a thin 2-pixel white outline for clean edge separation.
No text, no watermark, no border, no frame.
```

아이콘 프리픽스:

```
A crisp game icon in pixel art illustration style.
Korean traditional dancheong color palette: vermillion, indigo, gold, pine green.
Clean edges, sharp silhouette readable at small sizes.
Flat solid bright green (#00FF00) background.
No text, no border, no frame.
```

---

## 1. 플레이어 캐릭터

### char_mugwan — 무관 (武官)

```
[스타일 프리픽스]
Draw a cute chibi Joseon military officer (무관). He wears dark iron-gray armor over a navy blue inner robe, with a Korean sword (환도) drawn and held at the ready. He has a strong determined expression, a topknot under a warrior's headband, and a compact sturdy body in a battle-ready stance facing slightly left. The armor plates have detailed smooth shading with metallic highlights.
```

### char_dosa — 도사 (道士)

```
[스타일 프리픽스]
Draw a cute chibi Joseon Taoist mystic (도사). He wears flowing white and pale blue robes with yin-yang embroidery that billow with mystical energy. He holds a glowing paper talisman in one hand with vivid qi energy swirling around the other. He has a long white beard, serene piercing eyes, and a topknot with a jade pin. Ethereal teal glow effect surrounds the figure.
```

### char_mungwan — 문관 (文官)

```
[스타일 프리픽스]
Draw a cute chibi Joseon civil scholar-official (문관). He wears a formal scholar's hat (사모) and crimson court robe with a detailed rank badge. He holds a calligraphy brush in one hand with glowing ink characters floating around the other. He has sharp intelligent eyes, a calm expression, a neatly trimmed beard, and an elegant refined posture with a faint golden scholarly aura.
```

---

## 2. 적 캐릭터 — 1막 (한양)

### E001 — 불량배

```
[스타일 프리픽스]
Draw a cute chibi Joseon street thug (불량배). He has torn and dirty hemp clothing with visible patches, and wields a crude short knife in an aggressive forward-leaning stance. He has a scar across his cheek, a missing tooth, and wild menacing eyes. He is barefoot with straw sandals, in a dynamic threatening pose facing slightly left.
```

### E002 — 하급 포졸

```
[스타일 프리픽스]
Draw a cute chibi corrupt Joseon constable (포졸). He wears a red military vest over dark clothes with a black hat. He carries a wooden cudgel over one shoulder with a smirking expression. He has a pudgy compact build with a menacing presence.
```

### E003 — 전당포 주인

```
[스타일 프리픽스]
Draw a cute chibi sly Joseon pawnshop owner (전당포 주인). He wears a dark gray durumagi with a money pouch at his belt and holds a wooden abacus with gleaming beads. He has a thin face, narrow cunning eyes, and a calculating hunched-forward posture.
```

### E004 — 떠돌이 도적

```
[스타일 프리픽스]
Draw a cute chibi Joseon mountain bandit (도적). He wears ragged patched clothing with a tattered cloak that billows behind him. He wields a short dagger in a crouching ambush-ready stance with wild desperate hair and eyes.
```

### E005 — 원혼

```
[스타일 프리픽스]
Draw a cute chibi Korean vengeful ghost (원혼). She has a semi-transparent pale blue-white glowing form wearing a tattered white mourning dress (소복). Long black hair covers part of her face, with glowing hollow eyes. She floats above the ground with wispy spirit trails at her feet.
```

### E006 — 도깨비불

```
[스타일 프리픽스]
Draw a Korean spirit fire (도깨비불) as a swirling blue-green and orange flame orb about the size of a head. It has faint mischievous face-like features within the flames, with trailing fire wisps and a vivid glow effect. Dynamic flickering motion feeling.
```

### E007 — 관노

```
[스타일 프리픽스]
Draw a cute chibi Joseon government slave (관노) forced to fight. He wears rough hemp clothes with iron shackles on his wrists and wields a makeshift iron pitchfork. He has a compact sturdy build, a desperate haunted expression, and is barefoot in an aggressive but reluctant stance.
```

### E008 — 기방 청객

```
[스타일 프리픽스]
Draw a cute chibi drunken Joseon gisaeng house patron (청객). He has disheveled noble clothing with an untied sash and a tilted hat. He holds a folding fan as a weapon in a swaying unsteady stance. He has a flushed red face and bleary aggressive eyes with a portly build.
```

### E009 — 야경꾼

```
[스타일 프리픽스]
Draw a cute chibi Joseon night watchman (야경꾼). He wears dark blue-black patrol clothing with a round hat. He carries a lantern on a pole in one hand with a warm glow effect and a short spear in the other. He has an alert stern expression with a lean vigilant build.
```

### E010 — 시전 상인

```
[스타일 프리픽스]
Draw a cute chibi corrupt Joseon market merchant (시전 상인). He wears a fine silk durumagi with a fur-lined collar. He holds a rigged weighted scale with a calculating expression and a thin mustache. He has gold and coin pouches at his belt with a gleam effect.
```

### E011 — 나팔수

```
[스타일 프리픽스]
Draw a cute chibi Joseon government herald (나팔수). He wears dark blue official clothing with a red sash. He holds a traditional Korean trumpet ready to blow. He has a young face with a nervous but dutiful expression and a slim build.
```

---

## 3. 1막 엘리트 적

### EL001 — 양반

```
[스타일 프리픽스]
Draw a larger cute chibi tyrannical Joseon aristocrat (양반). He wears luxurious silk robes in dark purple with gold embroidery. He holds a long smoking pipe like a scepter with an arrogant expression, looking down with contempt. He has a groomed beard and an aura of authority. Make this sprite visibly larger and more detailed than regular enemy sprites.
```

### EL002 — 독사

```
[스타일 프리픽스]
Draw a larger cute chibi Joseon poison assassin (독사). He wears all-black tight clothing with a dark face mask — only cold calculating serpent-like eyes visible. Multiple green and purple poison vials are strapped across his chest with a glow effect. He crouches in a strike-ready pose with toxic mist around his hands. Make this sprite visibly larger and more detailed than regular enemy sprites.
```

### EL003 — 포수

```
[스타일 프리픽스]
Draw a larger cute chibi Joseon elite hunter (포수). He wears practical leather and fur hunting clothes. He has a Korean bow on his back and holds a matchlock musket with smoke wisps. He has a weathered face with sharp hawk-like eyes and stubble beard. Make this sprite visibly larger and more detailed than regular enemy sprites.
```

---

## 4. 보스

### B_ACT1_FINAL — 판서 이무령

```
[스타일 프리픽스]
Draw a boss-scale cute chibi corrupt Joseon Minister (이조판서). He sits on an ornate throne-like chair wearing the highest rank crimson and gold court robes with a crane rank badge. He holds a glowing red seal of power in one hand. He has cold merciless eyes beneath a stiff official's hat and a white trimmed beard. The seal radiates intense red energy. Make this sprite much larger and more imposing than regular sprites.
```

### B_ACT2_FINAL — 쌍두 호랑이

```
[스타일 프리픽스]
Draw a boss-scale chibi monstrous twin-headed Korean tiger (쌍두 호랑이). It has two distinct heads: the left head is calculating with cold blue eyes, and the right head is ferocious and roaring with fiery orange eyes. It has an enormous muscular body with glowing mystical markings on its fur and supernatural golden glow effects on its tiger stripes. Make this sprite much larger than regular sprites.
```

### B_ACT3_FINAL — 역적 대감

```
[스타일 프리픽스]
Draw a boss-scale cute chibi treasonous Joseon lord (역적 대감). He wears court robes with dragon motifs and detailed embroidery. His face is half in shadow with one eye gleaming with ambition and a sinister smile. He holds a secret royal decree in one hand and a hidden blade in the other. He has a dark crimson and black aura with flashes of imperial gold. Make this sprite much larger and more imposing than regular sprites.
```

---

## 5. 카드 일러스트 (주요 카드)

카드 공통 프리픽스:
```
A dynamic action scene illustration for a card game panel in high-resolution pixel art illustration style.
Dancheong color palette with dramatic lighting and smooth shading.
No text, no border, no frame — illustration only.
Flat solid bright green (#00FF00) background.
```

### M001 — 회피 (回避)

```
[카드 공통]
A Joseon warrior gracefully sidestepping a sword strike. The blade passes inches from the body as robes trail behind the dodge with motion blur. Fluid circular evasion movement in cool blue and silver tones.
```

### M002 — 도약 (跳躍)

```
[카드 공통]
A figure leaping powerfully upward, pushing off with one foot. Robes billowing from upward momentum. Below, the enemy's attack passes through empty air. Warm gold and green tones with ascending energy trails.
```

### M003 — 베기

```
[카드 공통]
A decisive downward slash with a Korean sword (환도). The blade catches light in a dramatic arc with an energy trail. Sparks and slash effects follow the blade line. Strong vermillion red and steel gray tones.
```

### M004 — 수호

```
[카드 공통]
A warrior in a defensive stance with arms crossed, emanating a qi shield. A translucent indigo-blue barrier forms in front with ripple effects. Solid rooted posture with a calm determined expression. Cool indigo and white tones.
```

### M005 — 집중

```
[카드 공통]
A figure kneeling in meditation with eyes closed and mudra hands. Golden qi energy wisps spiral inward toward the body. Calm serene atmosphere with a soft glowing aura. Gold and soft violet tones.
```

### G001 — 진형 전환 (陣形轉換)

```
[카드 공통]
A Joseon military officer commanding a formation change. Seen from above, soldiers shift like chess pieces on a battlefield with motion trails. The officer's hand gesture directs movement with military flags waving. Gold and dark navy tones.
```

### G002 — 돌격 진형

```
[카드 공통]
A V-shaped charging formation of Joseon soldiers. The lead warrior charges forward with sword raised and soldiers flanking behind. Dust clouds and motion blur convey speed and impact. Fierce vermillion and iron gray tones.
```

### D001 — 부적 투척

```
[카드 공통]
A Taoist mystic throwing a burning paper talisman. The talisman is mid-flight trailing golden fire and glowing mystical symbols. The caster's robes billow with released supernatural energy. Teal and gold tones.
```

### W001 — 경연 (經筵)

```
[카드 공통]
A scholar-official delivering a lecture from an ancient text. Words from the book materialize as glowing Korean characters floating in the air. Other scholars listen intently in a candle-lit study atmosphere. Warm gold and deep brown tones.
```

---

## 6. 배경 이미지

배경 프리픽스:
```
A detailed high-resolution pixel art illustration scene for a mobile RPG game.
Joseon dynasty Korean historical setting with dancheong color palette.
No text, no watermark.
```

### bg_title — 타이틀 화면

```
[배경 프리픽스]
A majestic panoramic view of Joseon-era Hanyang (Seoul) at sunset. Palace rooftops in the foreground with mountains behind and atmospheric depth. The sky transitions through vermillion, gold, and deep indigo. A lone figure is silhouetted on a rooftop looking toward the palace. Leave empty space in the upper third for a game title. Portrait orientation 1080x1920.
```

### bg_battle — 전투 배경

```
[배경 프리픽스]
A dark Joseon-era street at night with scattered paper lanterns casting warm volumetric glow. Wooden buildings with tiled roofs line both sides of a cobblestone path. Low fog rolls through the scene with the moon visible through clouds. Leave space for UI in the top and bottom thirds. Portrait orientation 1080x1920.
```

### bg_map — 맵 배경

```
[배경 프리픽스]
A landscape map in Korean traditional painting style (산수화). Misty mountains, winding paths through pine forests, and a river with reflections. Small traditional buildings are scattered across the landscape. Muted palette with subtle color and atmospheric depth. Top-down perspective. Portrait orientation 1080x1920.
```

### bg_shop — 상점 배경

```
[배경 프리픽스]
The warm interior of a Joseon-era marketplace shop. Wooden shelves display medicines, weapons, scrolls, and talismans. A merchant's counter has an abacus and coin pile. Warm lantern light fills the space with rich wood tones and gold accents. Leave space for a shop UI overlay. Portrait orientation 1080x1920.
```

### bg_rest — 휴식처 배경

```
[배경 프리픽스]
A peaceful Joseon-era roadside inn (주막) at twilight. A thatched-roof building with a wooden bench under an old tree. A rice wine pot sits on the table with fireflies glowing in warm air. Serene healing atmosphere in warm amber and soft green tones with a twilight sky. Leave space for a rest UI. Portrait orientation 1080x1920.
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
4. 생성된 이미지 다운로드
5. **배경 제거**: 크로마키 그린(#00FF00) 배경을 remove.bg 또는 Photopea 등으로 제거 → 투명 PNG 변환
6. `art/` 폴더의 해당 경로에 PNG로 저장
7. **스타일 일관성**: 첫 번째 결과물을 참조 이미지로 업로드하여 후속 생성에 활용

---

## 배치 생성 팁

- **참조 이미지가 핵심**: 첫 캐릭터 생성 후 해당 결과물을 모든 후속 프롬프트에 참조 이미지로 첨부 (최대 14장)
- **같은 세션에서 연속 생성**: 동일 대화에서 연속으로 만들면 스타일 일관성 유지
- **크로마키 그린 후처리**: OpenCV/Pillow 스크립트 또는 remove.bg로 일괄 처리 가능
- **해상도**: NanoBanana의 "512x512" 등 해상도 지정은 구도에만 영향. 실제 출력 사이즈는 API 파라미터로 제어
- **"HD" 키워드**: 해상도가 아닌 디테일 스타일에만 영향
- **아이콘은 한 세트로**: 상태이상 아이콘은 한 프롬프트에 여러 개 구성하여 통일된 스타일 확보
