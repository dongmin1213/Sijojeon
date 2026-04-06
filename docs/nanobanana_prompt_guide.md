# 시조전 — NanoBanana 프롬프트 가이드

> 버전: 0.1 | 최종 업데이트: 2026-04-06
> Google NanoBanana 2 (Gemini Plus) 기반 에셋 생성 프롬프트 모음

---

## NanoBanana 프롬프트 작성 원칙

1. **주제(Subject)를 먼저** — 가장 중요한 요소를 앞에 배치
2. **스타일 일관성** — 모든 프롬프트에 동일한 스타일 접두사 사용
3. **구체적 묘사** — "멋진" 대신 "어두운 조명, 금박 하이라이트, 수묵 질감"
4. **모순 금지** — "미니멀"과 "복잡한 디테일"을 동시에 쓰지 않기
5. **기술 스펙 명시** — 해상도, 배경 투명도, 비율 등

---

## 공통 스타일 프리픽스

모든 프롬프트 앞에 붙이는 스타일 지정 문구:

```
[스타일 프리픽스 — 카드/캐릭터/적용]
Korean traditional ink wash painting meets modern digital illustration.
Joseon dynasty (1392-1910) era aesthetic.
Dancheong (단청) color palette: vermillion red, indigo blue, pine green, gold leaf, violet purple.
Dark and majestic atmosphere with subtle mystery.
Clean lines, semi-realistic style, suitable for mobile card game.
```

```
[스타일 프리픽스 — 아이콘용]
Flat icon style with Korean traditional color palette.
Dancheong (단청) colors: vermillion, indigo, gold, pine green.
Clean edges, no gradients, transparent background.
64x64 pixel art suitable for mobile UI.
```

---

## 1. 플레이어 캐릭터 프롬프트

### char_mugwan — 무관 (武官)

```
[스타일 프리픽스] 
A Joseon dynasty military officer (무관/武官) standing in a powerful stance.
Wearing dark iron-gray armor (갑옷) over a navy blue inner robe.
A Korean traditional sword (환도/環刀) at his waist, one hand resting on the pommel.
Strong jawline, determined eyes, short topknot (상투) under a warrior's headband.
Muscular build, battle scars on forearms.
Dark moody background with faint smoke and ember particles.
Portrait orientation, waist-up composition.
Resolution: 1024x1536, transparent background.
```

### char_dosa — 도사 (道士)

```
[스타일 프리픽스]
A Joseon dynasty Taoist mystic (도사/道士) in a meditative yet powerful pose.
Wearing flowing white and pale blue Taoist robes (도포) with yin-yang embroidery.
Holding a glowing paper talisman (부적) in one hand, mystical qi energy swirling around the other.
Long white beard, serene but piercing eyes, hair tied in a topknot with a jade pin.
Thin, wiry build suggesting inner strength.
Ethereal teal and purple energy wisps surrounding the figure.
Portrait orientation, waist-up composition.
Resolution: 1024x1536, transparent background.
```

### char_mungwan — 문관 (文官)

```
[스타일 프리픽스]
A Joseon dynasty civil scholar-official (문관/文官) with an air of intellectual authority.
Wearing a formal scholar's hat (사모/紗帽) and crimson official court robe (관복) with a rank badge (흉배).
Holding a calligraphy brush in one hand and an ancient text scroll in the other.
Sharp, intelligent eyes behind a calm expression. Neatly trimmed beard.
Slim, elegant build. Standing with refined posture.
Faint golden calligraphy characters floating in the background.
Portrait orientation, waist-up composition.
Resolution: 1024x1536, transparent background.
```

---

## 2. 적 캐릭터 프롬프트 — 1막 (한양)

### E001 — 불량배

```
[스타일 프리픽스]
A Joseon-era street thug (불량배) from the back alleys of Hanyang.
Rough, unkempt appearance. Torn and dirty hemp clothing.
Wielding a crude short knife, aggressive stance leaning forward.
Scar across the cheek, missing a tooth, wild eyes.
Muscular but lean build. Bare feet or straw sandals.
Full body, facing slightly left, dark alley atmosphere.
Resolution: 512x512, transparent background.
```

### E002 — 하급 포졸

```
[스타일 프리픽스]
A corrupt low-ranking Joseon constable (포졸) from the local magistrate's office.
Wearing a red military vest over dark clothes with a black hat.
Carrying a wooden cudgel (곤장) over one shoulder, smirking expression.
Pudgy build suggesting laziness, but menacing presence.
Full body pose, standing with authority.
Resolution: 512x512, transparent background.
```

### E003 — 전당포 주인

```
[스타일 프리픽스]
A sly Joseon-era pawnshop owner (전당포 주인) counting money.
Wearing merchant's clothing — a dark gray durumagi with a money pouch at the belt.
Holding a wooden abacus (주판) in one hand, cunning smile.
Thin face, narrow eyes, hunched posture suggesting greed.
Full body, slightly hunched forward.
Resolution: 512x512, transparent background.
```

### E004 — 떠돌이 도적

```
[스타일 프리픽스]
A wandering Joseon bandit (도적) from the mountain roads.
Ragged, patched clothing. A tattered cloak over the shoulders.
Wielding a short dagger, crouching in an ambush-ready stance.
Gaunt face with wild hair, desperate eyes.
Full body, dynamic crouching pose.
Resolution: 512x512, transparent background.
```

### E005 — 원혼

```
[스타일 프리픽스]
A Korean vengeful ghost (원혼/怨魂) — a spirit of someone who died unjustly.
Semi-transparent form with pale blue-white ethereal glow.
Wearing a tattered white Joseon mourning dress (소복).
Long black hair covering part of the face, hollow glowing eyes visible.
Floating slightly above the ground, wispy trails at the feet.
Full body, ghostly atmosphere with cold blue mist.
Resolution: 512x512, transparent background.
```

### E006 — 도깨비불

```
[스타일 프리픽스]
A Korean spirit fire (도깨비불) — a floating supernatural flame.
An orb of swirling blue-green and orange fire, approximately head-sized.
Faint face-like features visible within the flames — mischievous expression.
Trailing wisps of ghostly fire, floating in darkness.
Centered composition, ethereal glow illuminating surroundings.
Resolution: 512x512, transparent background.
```

### E007 — 관노

```
[스타일 프리픽스]
A Joseon government slave (관노/官奴) forced to fight.
Wearing rough hemp clothes with visible iron shackles on wrists.
Wielding a makeshift weapon — an iron pitchfork (쇠스랑).
Muscular build from forced labor, scarred back visible.
Desperate, haunted expression. Barefoot.
Full body, aggressive but reluctant stance.
Resolution: 512x512, transparent background.
```

### E008 — 기방 청객

```
[스타일 프리픽스]
A drunken Joseon-era patron (청객) from a gisaeng house.
Wearing disheveled noble clothing — untied sash, tilted hat.
Holding a folding fan (부채) as an improvised weapon, swaying stance.
Flushed red face from alcohol, bleary but aggressive eyes.
Portly build. Half-open robe revealing inner garments.
Full body, unsteady stance.
Resolution: 512x512, transparent background.
```

### E009 — 야경꾼

```
[스타일 프리픽스]
A Joseon night watchman (야경꾼) patrolling the city streets.
Wearing dark blue-black patrol clothing with a round hat.
Carrying a lantern on a pole in one hand and a short spear in the other.
Alert, stern expression. Lean, vigilant build.
Full body, walking patrol stance.
Resolution: 512x512, transparent background.
```

### E010 — 시전 상인

```
[스타일 프리픽스]
A corrupt Joseon market merchant (시전 상인) from the commercial district.
Wearing fine merchant clothing — silk durumagi with fur-lined collar.
Holding a weighted scale (저울) that's clearly rigged.
Calculating expression, thin mustache, well-fed build.
Gold and coin pouches visible at the belt.
Full body, standing behind implied counter.
Resolution: 512x512, transparent background.
```

### E011 — 나팔수

```
[스타일 프리픽스]
A Joseon government herald/trumpeter (나팔수) from the magistrate's office.
Wearing official minor clerk clothing — dark blue with red sash.
Holding a traditional Korean trumpet (나팔) ready to blow.
Young face, nervous but dutiful expression.
Slim build. Standing at attention.
Full body, formal stance.
Resolution: 512x512, transparent background.
```

---

## 3. 1막 엘리트 적 프롬프트

### EL001 — 양반

```
[스타일 프리픽스]
A tyrannical Joseon aristocrat (양반/兩班) of high social standing.
Wearing luxurious silk robes in dark purple with gold embroidery.
Holding a long smoking pipe (장죽/長竹) like a scepter.
Arrogant expression, looking down with contempt. Neatly groomed beard.
Tall, imposing presence. Servants implied in shadow behind.
Full body, authoritative standing pose. Larger than regular enemies.
Resolution: 768x768, transparent background.
```

### EL002 — 독사

```
[스타일 프리픽스]
A Joseon-era poison assassin (독사/毒蛇) — master of poisons.
Wearing all-black tight-fitting clothes with a dark face mask (복면).
Multiple hidden vials of green and purple poison strapped across the chest.
Only the eyes visible — cold, calculating, serpent-like.
Lean, agile build. Crouching in a strike-ready pose.
Faint green toxic mist around the hands.
Full body, dynamic assassin pose. Larger than regular enemies.
Resolution: 768x768, transparent background.
```

### EL003 — 포수

```
[스타일 프리픽스]
A Joseon-era elite hunter (포수/砲手) armed with bow and matchlock rifle.
Wearing practical hunting clothes — leather and fur, mountain style.
A Korean traditional bow (활) on the back, holding a matchlock musket (화승총).
Weathered face, sharp hawk-like eyes, stubble beard.
Sturdy, hardened build from mountain life.
Full body, aiming stance. Larger than regular enemies.
Resolution: 768x768, transparent background.
```

---

## 4. 보스 프롬프트

### B_ACT1_FINAL — 판서 이무령

```
[스타일 프리픽스]
A powerful corrupt Joseon Minister of Personnel (이조판서/吏曹判書) named Yi Mu-ryeong.
Wearing the highest rank court robes — crimson and gold, with a crane rank badge (흉배).
Sitting on an ornate chair as if it were a throne, one hand holding a red official seal (관인).
Cold, merciless eyes beneath a stiff official's hat (사모). White beard neatly trimmed.
Imposing presence radiating corrupt authority. Dark shadows and red/gold lighting.
The seal glows ominously — it represents his absolute power over life and death.
Full body, seated on throne-like chair. Boss-scale: much larger composition.
Resolution: 1024x1024, transparent background.
```

### B_ACT2_FINAL — 쌍두 호랑이

```
[스타일 프리픽스]
A monstrous twin-headed tiger (쌍두 호랑이/兩頭虎) — mountain god's wrathful avatar.
A massive Korean tiger (호랑이) with TWO heads, each bearing different expressions:
Left head (좌두): calculating, strategic, cold blue eyes.
Right head (우두): ferocious, roaring, fiery orange eyes.
Enormous muscular body with mystical markings glowing on the fur.
Standing on a rocky mountain ridge with swirling storm clouds behind.
Traditional Korean tiger stripes with supernatural golden glow.
Full body, facing forward. Boss-scale composition.
Resolution: 1024x1024, transparent background.
```

### B_ACT3_FINAL — 역적 대감

```
[스타일 프리픽스]
A treasonous Joseon lord (역적 대감/逆賊大監) who schemes to seize the throne.
Wearing court robes that are deliberately more regal than his station — dragon motifs instead of crane.
Face half-hidden in shadow, one eye gleaming with ambition. A sinister smile.
Holding a secret royal decree (밀서) in one hand, a hidden blade in the other.
Standing before a war map table with strategy pieces.
Dark crimson and black color scheme with flashes of imperial gold.
Aura of treachery — loyal-looking facade cracking to reveal the tyrant beneath.
Full body, standing pose with dramatic lighting. Boss-scale composition.
Resolution: 1024x1024, transparent background.
```

---

## 5. 공통 카드 일러스트 프롬프트 (주요 카드)

모든 카드 프롬프트 공통 설정:
```
[카드 공통]
Square composition suitable for a card game illustration panel.
Korean traditional ink painting style with vivid dancheong colors.
Dynamic action scene, dramatic lighting.
No text, no border, no frame — illustration only.
Resolution: 512x768, transparent background.
```

### M001 — 회피 (回避)

```
[카드 공통]
A Joseon warrior gracefully sidestepping a sword strike.
The blade passes inches from the body. Flowing robes trail behind the dodge.
Emphasis on fluid, circular evasion movement.
Cool blue and silver tones suggesting defensive skill.
```

### M002 — 도약 (跳躍)

```
[카드 공통]
A figure leaping powerfully upward, pushing off the ground with one foot.
Korean traditional robes billowing from the upward momentum.
Below, the enemy's attack passes through empty air.
Warm gold and green tones, sense of ascending energy.
```

### M003 — 베기

```
[카드 공통]
A decisive downward slash with a Korean sword (환도).
The blade catches light in a dramatic arc of motion.
Sparks and energy trail following the slash line.
Strong vermillion red and steel gray tones. Raw power.
```

### M004 — 수호

```
[카드 공통]
A defensive stance — arms crossed before the body, emanating a shield of qi energy.
Translucent indigo-blue barrier forming in front of the defender.
Solid, rooted posture. Calm, focused expression.
Cool indigo and white tones suggesting protection.
```

### M005 — 집중

```
[카드 공통]
A figure kneeling in meditation, eyes closed, hands in a mudra-like position.
Visible qi (기) energy gathering as golden wisps spiraling inward.
Calm, serene atmosphere. Faint glow around the body.
Gold and soft violet tones.
```

---

## 6. 무관 카드 일러스트 프롬프트 (주요 카드)

### G001 — 진형 전환 (陣形轉換)

```
[카드 공통]
A Joseon military officer commanding soldiers into a new battle formation.
From above, soldiers shift positions like chess pieces on a battlefield.
The officer's hand gesture directs the movement. Military flags waving.
Gold and dark navy tones. Tactical, strategic atmosphere.
```

### G002 — 돌격 진형

```
[카드 공통]
A V-shaped charging formation of Joseon soldiers.
The lead warrior charges forward with sword raised, soldiers flanking.
Dust and motion blur conveying speed and impact.
Fierce vermillion and iron gray tones.
```

---

## 7. 도사 카드 일러스트 프롬프트 (주요 카드)

### D001 — 부적 투척

```
[카드 공통]
A Taoist mystic throwing a burning paper talisman (부적) at an unseen enemy.
The talisman is mid-flight, trailing golden fire and mystical symbols.
The caster's robes billow with released energy.
Teal and gold tones with supernatural fire.
```

---

## 8. 문관 카드 일러스트 프롬프트 (주요 카드)

### W001 — 경연 (經筵)

```
[카드 공통]
A scholar-official delivering a passionate lecture from an ancient text.
The words from the book materialize as glowing Korean characters in the air.
Other scholars listen intently. Candle-lit study atmosphere.
Warm gold and deep brown tones. Scholarly, intellectual energy.
```

---

## 9. 배경 이미지 프롬프트

### bg_title — 타이틀 화면

```
[스타일 프리픽스]
A panoramic view of Joseon-era Hanyang (Seoul) at dramatic sunset.
Traditional Korean palace rooftops in the foreground, mountains behind.
The sky painted in vermillion, gold, and deep indigo — dancheong colors.
A lone figure silhouetted on a rooftop, looking toward the palace.
Ink wash painting style with vivid sunset colors. Majestic and mysterious.
Empty space in the upper third for game title placement.
Resolution: 1080x1920, portrait orientation.
```

### bg_battle — 전투 배경

```
[스타일 프리픽스]
A dark Joseon-era street at night, lit by scattered paper lanterns.
Wooden buildings with tiled roofs line both sides. Cobblestone path.
Fog rolling low across the ground. Moon visible through clouds.
Atmospheric, tense. Ready for a confrontation.
Muted colors — indigo night sky, warm orange lantern glow.
Resolution: 1080x1920, portrait orientation. Space for UI in top and bottom thirds.
```

### bg_map — 맵 배경

```
[스타일 프리픽스]
A Korean traditional landscape painting (산수화/山水畫) style map background.
Misty mountains, winding paths through pine forests, a river.
Small traditional buildings scattered across the landscape.
Ink wash painting style — black ink with subtle color washes.
Top-down perspective suggesting a journey through the land.
Resolution: 1080x1920, portrait orientation. Muted background for node overlay.
```

### bg_shop — 상점 배경

```
[스타일 프리픽스]
Interior of a bustling Joseon-era marketplace shop (시전/市廛).
Wooden shelves lined with goods — medicines, weapons, scrolls, talismans.
A merchant's counter in the center with an abacus and coin pile.
Warm, inviting lantern light. Rich wood tones and gold accents.
Resolution: 1080x1920, portrait orientation. Space for shop UI overlay.
```

### bg_rest — 휴식처 배경

```
[스타일 프리픽스]
A peaceful Joseon-era roadside inn (주막/酒幕) at twilight.
A small thatched-roof building with a wooden bench under an old tree.
A pot of rice wine (막걸리) on the table. Fireflies in the warm air.
Serene, healing atmosphere. Warm amber and soft green tones.
Resolution: 1080x1920, portrait orientation. Space for rest options UI.
```

---

## 10. 유물 아이콘 프롬프트

### R001 — 편자 (鞭子)

```
[아이콘 프리픽스]
A worn leather horse whip (편자) coiled in a circle.
Dark brown leather with a brass handle tip.
Faint golden glow suggesting protective energy.
Simple, clean icon composition. 128x128.
```

### R002 — 평안 부적

```
[아이콘 프리픽스]
A yellow paper talisman (부적) with red ink Korean characters.
Traditional rectangular shape with mystical symbols.
Soft golden aura around the edges.
Simple, clean icon composition. 128x128.
```

### R003 — 행운의 엽전

```
[아이콘 프리픽스]
A single Korean traditional coin (엽전) — round with a square hole.
Greenish bronze patina with golden highlights.
Faint luck sparkles around it.
Simple, clean icon composition. 128x128.
```

### R004 — 봉황 깃털

```
[아이콘 프리픽스]
A single phoenix feather (봉황 깃털) — iridescent rainbow colors.
Long, elegant feather with a golden quill.
Faint fire wisps at the tip. Warm glow.
Simple, clean icon composition. 128x128.
```

### R005 — 홍삼 뿌리

```
[아이콘 프리픽스]
A Korean red ginseng root (홍삼) — dark reddish-brown, humanoid shape.
Earthy, organic form with small rootlets.
Faint warm red healing aura.
Simple, clean icon composition. 128x128.
```

---

## 11. UI 상태이상 아이콘 프롬프트

```
[아이콘 프리픽스] — 각각 64x64

독 (Poison): Green bubbling vial, skull vapor rising.
화상 (Burn): Orange-red flame icon, sharp edges.
출혈 (Bleed): Dark red blood drops, three drops in a triangle.
사망각인 (Death Mark): Black skull with red X mark.
약화 (Weakness): Broken sword icon, gray and dull.
취약 (Vulnerable): Cracked shield icon, red cracks.
냉기 (Chill): Blue snowflake/ice crystal.
힘 (Strength): Red flexing arm/fist, power aura.
가시 (Thorns): Green thorny vine circle.
갑옷 (Armor): Iron chestplate icon, metallic gray.
```

---

## 사용법

1. Gemini Plus (gemini.google.com) 접속
2. 이미지 생성 모드 선택 (NanoBanana 2 기본 적용)
3. `[스타일 프리픽스]` + 개별 프롬프트를 결합하여 입력
4. 생성된 이미지 다운로드 → 배경 제거 (필요시) → `art/` 폴더의 해당 경로에 PNG로 저장
5. 스타일이 일관되지 않으면 첫 번째 결과물을 참조 이미지로 업로드하여 후속 생성에 활용

---

## 배치 생성 팁

- **캐릭터 일관성**: 첫 캐릭터 생성 후 결과물을 참조 이미지로 업로드하여 후속 캐릭터에 스타일 적용
- **카드 일러스트**: 같은 클래스 카드는 연속으로 생성하여 스타일 일관성 유지
- **아이콘**: 상태이상 아이콘은 한 세트로 프롬프트를 구성해서 통일감 확보
- **배경 제거**: 캐릭터/적 이미지는 remove.bg 등으로 배경 제거 후 게임 적용
- **해상도**: NanoBanana 2는 최대 4K 지원 — 큰 이미지 생성 후 축소하면 품질 향상
