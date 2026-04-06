# 시조전 — NanoBanana 프롬프트 가이드

> 버전: 0.5 | 최종 업데이트: 2026-04-06
> Google NanoBanana 2 (Gemini Plus) 기반 에셋 생성 프롬프트 모음
> **아트 스타일: 하이브리드 도트 일러스트 (High-Res Pixel Art Illustration)**
> 참조: 가디언테일즈, 월드플리퍼, Raid 류 한국 모바일 게임 캐릭터 스타일

---

## NanoBanana 프롬프트 작성 원칙

1. **주제(Subject)를 먼저** — 가장 중요한 요소를 앞에 배치
2. **스타일 일관성** — 모든 프롬프트에 동일한 스타일 접두사 사용
3. **구체적 묘사** — "멋진" 대신 "어두운 조명, 금박 하이라이트, 부드러운 셰이딩"
4. **모순 금지** — "미니멀"과 "복잡한 디테일"을 동시에 쓰지 않기
5. **기술 스펙 명시** — 해상도, 배경 투명도, 비율 등
6. **하이브리드 스타일 핵심** — 픽셀아트 기반이되 고해상도 + 부드러운 셰이딩 + 다이나믹 포즈

---

## 공통 스타일 프리픽스

모든 프롬프트 앞에 붙이는 스타일 지정 문구:

```
[스타일 프리픽스 — 캐릭터/적 스프라이트용]
High-resolution pixel art illustration sprite, modern Korean mobile RPG style.
Inspired by Guardian Tales, World Flipper — detailed pixel-based character with smooth shading and vibrant colors.
Chibi / super-deformed proportions: 2.5-head-tall character with large expressive head and compact body.
Joseon dynasty (1392-1910) Korean historical aesthetic.
Color palette inspired by dancheong (단청): vermillion red, indigo blue, pine green, gold, violet purple.
Full body character sprite, dynamic pose, detailed outfit and weapon rendering.
Transparent background, no background elements — character sprite only.
Suitable for a mobile roguelike card game.
```

```
[스타일 프리픽스 — 아이콘용]
Crisp pixel art icon style, modern mobile RPG aesthetic.
Korean traditional dancheong (단청) color palette: vermillion, indigo, gold, pine green.
Clean edges, minimal dithering, transparent background.
Sharp silhouette readable at small sizes.
```

---

## 1. 플레이어 캐릭터 프롬프트

### char_mugwan — 무관 (武官)

```
[스타일 프리픽스] 
High-resolution pixel art illustration sprite of a Joseon dynasty military officer (무관/武官).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, powerful battle-ready stance, facing slightly left.
Dark iron-gray armor (갑옷) over a navy blue inner robe, smooth shading on metal plates with highlights.
Korean traditional sword (환도/環刀) drawn and held at the ready, blade catching light.
Strong jawline, determined eyes, topknot (상투) under a warrior's headband.
Compact sturdy build. Dynamic pose suggesting motion.
Modern mobile RPG character sprite. Vibrant colors with smooth pixel shading.
Resolution: 512x512, transparent background. No background elements.
```

### char_dosa — 도사 (道士)

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a Joseon dynasty Taoist mystic (도사/道士).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, powerful casting pose with one hand raised, facing slightly left.
Flowing white and pale blue Taoist robes (도포) with yin-yang embroidery detail, robes billowing with energy.
Holding a glowing paper talisman (부적) in one hand, vivid qi energy swirling around the other.
Long white beard, serene but piercing eyes, topknot with a jade pin.
Compact build with flowing robes. Ethereal glow effect around figure.
Modern mobile RPG character sprite. Vibrant colors with smooth pixel shading.
Resolution: 512x512, transparent background. No background elements.
```

### char_mungwan — 문관 (文官)

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a Joseon dynasty civil scholar-official (문관/文官).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, intellectual authority stance with one arm extended, facing slightly left.
Formal scholar's hat (사모/紗帽) and crimson court robe (관복) with detailed rank badge (흉배).
Holding a calligraphy brush in one hand, glowing ink characters floating around the other.
Sharp, intelligent eyes, calm expression. Neatly trimmed beard.
Compact elegant build with refined posture. Faint golden scholarly aura.
Modern mobile RPG character sprite. Vibrant colors with smooth pixel shading.
Resolution: 512x512, transparent background. No background elements.
```

---

## 2. 적 캐릭터 프롬프트 — 1막 (한양)

### E001 — 불량배

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a Joseon-era street thug (불량배) from Hanyang back alleys.
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, aggressive forward-leaning stance, facing slightly left.
Rough, unkempt character. Torn and dirty hemp clothing with visible wear and patches.
Wielding a crude short knife, menacing expression.
Scar across cheek, missing tooth, wild eyes.
Bare feet or straw sandals. Dynamic threatening pose.
Modern mobile RPG enemy sprite. Vibrant colors with smooth pixel shading.
Resolution: 512x512, transparent background.
```

### E002 — 하급 포졸

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a corrupt low-ranking Joseon constable (포졸).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, intimidating stance.
Red military vest over dark clothes, black hat with detailed fabric rendering.
Carrying a wooden cudgel (곤장) over one shoulder, smirking expression.
Compact pudgy build, menacing presence. Smooth shading on uniform details.
Modern mobile RPG enemy sprite. Vibrant colors.
Resolution: 512x512, transparent background.
```

### E003 — 전당포 주인

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a sly Joseon-era pawnshop owner (전당포 주인).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, hunched greedy posture.
Dark gray durumagi with money pouch at belt. Holding wooden abacus (주판) with gleaming beads.
Thin face, narrow cunning eyes. Calculating expression.
Slightly hunched forward, grasping pose. Smooth fabric shading.
Modern mobile RPG enemy sprite. Vibrant colors.
Resolution: 512x512, transparent background.
```

### E004 — 떠돌이 도적

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a wandering Joseon bandit (도적) from mountain roads.
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, crouching ambush-ready stance.
Ragged, patched clothing with tattered cloak billowing.
Wielding a short dagger, desperate wild expression.
Wild hair, desperate eyes. Dynamic action pose.
Modern mobile RPG enemy sprite. Vibrant colors with smooth shading.
Resolution: 512x512, transparent background.
```

### E005 — 원혼

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a Korean vengeful ghost (원혼/怨魂).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, floating ethereal pose.
Semi-transparent form with pale blue-white glow effect.
Tattered white Joseon mourning dress (소복), flowing unnaturally.
Long black hair covering part of face, glowing hollow eyes.
Floating above ground with wispy spirit trails at feet. Eerie atmosphere.
Modern mobile RPG ghost enemy sprite. Ethereal glow and transparency effects.
Resolution: 512x512, transparent background.
```

### E006 — 도깨비불

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a Korean spirit fire (도깨비불).
Swirling blue-green and orange flame orb, head-sized, centered composition.
Faint mischievous face-like features within the flames.
Trailing fire wisps, vivid glow effect. Dynamic flickering motion.
Modern mobile RPG magical enemy sprite. Vibrant fire effects.
Resolution: 512x512, transparent background.
```

### E007 — 관노

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a Joseon government slave (관노/官奴) forced to fight.
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, aggressive but reluctant stance.
Rough hemp clothes with iron shackles on wrists, detailed chain rendering.
Wielding makeshift iron pitchfork (쇠스랑). Compact sturdy build.
Desperate, haunted expression. Barefoot.
Modern mobile RPG enemy sprite. Vibrant colors with smooth shading.
Resolution: 512x512, transparent background.
```

### E008 — 기방 청객

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a drunken Joseon-era gisaeng house patron (청객).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, swaying unsteady stance.
Disheveled noble clothing — untied sash, tilted hat. Rich fabric detail with smooth shading.
Holding folding fan (부채) as weapon, flushed red face.
Bleary aggressive eyes. Portly build.
Modern mobile RPG enemy sprite. Vibrant colors.
Resolution: 512x512, transparent background.
```

### E009 — 야경꾼

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a Joseon night watchman (야경꾼).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, alert patrol stance.
Dark blue-black patrol clothing, round hat. Detailed uniform rendering.
Carrying lantern on pole in one hand with warm glow effect, short spear in other.
Alert, stern expression. Lean, vigilant build.
Modern mobile RPG enemy sprite. Lantern glow lighting effect.
Resolution: 512x512, transparent background.
```

### E010 — 시전 상인

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a corrupt Joseon market merchant (시전 상인).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, calculating pose.
Fine silk durumagi with fur-lined collar, smooth fabric sheen rendering.
Holding rigged weighted scale (저울). Calculating expression, thin mustache.
Well-fed build. Gold and coin pouches at belt with gleam effect.
Modern mobile RPG enemy sprite. Vibrant colors with rich detail.
Resolution: 512x512, transparent background.
```

### E011 — 나팔수

```
[스타일 프리픽스]
High-resolution pixel art illustration sprite of a Joseon government herald/trumpeter (나팔수).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, formal attention stance.
Dark blue official clothing with red sash. Detailed uniform rendering.
Holding traditional Korean trumpet (나팔) ready to blow.
Young face, nervous but dutiful expression. Slim build.
Modern mobile RPG enemy sprite. Vibrant colors.
Resolution: 512x512, transparent background.
```

---

## 3. 1막 엘리트 적 프롬프트

### EL001 — 양반

```
[스타일 프리픽스]
Large high-resolution pixel art illustration sprite of a tyrannical Joseon aristocrat (양반/兩班).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, authoritative stance. Larger and more detailed than regular enemies.
Luxurious silk robes in dark purple with gold embroidery, rich fabric shading.
Holding a long smoking pipe (장죽/長竹) like a scepter.
Arrogant expression, looking down with contempt. Groomed beard. Aura of authority.
Modern mobile RPG elite enemy sprite. Rich color palette with detailed shading.
Resolution: 768x768, transparent background.
```

### EL002 — 독사

```
[스타일 프리픽스]
Large high-resolution pixel art illustration sprite of a Joseon-era poison assassin (독사/毒蛇).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, crouching strike-ready pose. Larger and more detailed than regular enemies.
All-black tight clothing with dark face mask (복면). Sleek stealth aesthetic.
Multiple green and purple poison vials strapped across chest with glow effect.
Only eyes visible — cold, calculating, serpent-like. Toxic mist around hands.
Lean, agile build. Dynamic action pose.
Modern mobile RPG elite enemy sprite. Poison glow effects.
Resolution: 768x768, transparent background.
```

### EL003 — 포수

```
[스타일 프리픽스]
Large high-resolution pixel art illustration sprite of a Joseon-era elite hunter (포수/砲手).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, aiming stance. Larger and more detailed than regular enemies.
Practical leather and fur hunting clothes, mountain style with detailed texture.
Korean bow (활) on back, holding matchlock musket (화승총) with detailed weapon rendering.
Weathered face, sharp hawk-like eyes, stubble beard.
Sturdy, hardened build. Smoke wisps from musket.
Modern mobile RPG elite enemy sprite. Detailed weapon and armor rendering.
Resolution: 768x768, transparent background.
```

---

## 4. 보스 프롬프트

### B_ACT1_FINAL — 판서 이무령

```
[스타일 프리픽스]
Boss-scale high-resolution pixel art illustration sprite of a corrupt Joseon Minister of Personnel (이조판서/吏曹判書) Yi Mu-ryeong.
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, seated on ornate throne-like chair.
Highest rank court robes — crimson and gold with crane rank badge (흉배), rich fabric shading.
One hand holding a glowing red seal (관인) with power aura effect.
Cold, merciless eyes beneath stiff official's hat (사모). White trimmed beard.
The seal glows with intense red energy — absolute power.
Boss-scale: much larger and more detailed than regular sprites. Imposing presence.
Modern mobile RPG final boss sprite. Rich detail and dramatic lighting effects.
Resolution: 768x768, transparent background. No background elements.
```

### B_ACT2_FINAL — 쌍두 호랑이

```
[스타일 프리픽스]
Boss-scale high-resolution pixel art illustration sprite of a monstrous twin-headed tiger (쌍두 호랑이/兩頭虎).
Chibi / super-deformed proportions: 2.5-head-tall with large heads and compact body.
Full body sprite, facing forward. Massive scale.
Two distinct heads: left head (좌두) calculating with cold blue eyes, right head (우두) ferocious roaring with fiery orange eyes.
Enormous muscular body with glowing mystical markings on fur.
Korean tiger stripes with supernatural golden glow effect.
Boss-scale: much larger and more detailed than regular sprites.
Modern mobile RPG boss monster sprite. Vivid supernatural glow effects.
Resolution: 768x768, transparent background. No background elements.
```

### B_ACT3_FINAL — 역적 대감

```
[스타일 프리픽스]
Boss-scale high-resolution pixel art illustration sprite of a treasonous Joseon lord (역적 대감/逆賊大監).
Chibi / super-deformed proportions: 2.5-head-tall with large expressive head and compact body.
Full body sprite, standing in dramatic power pose.
Court robes with dragon motifs instead of crane — detailed embroidery rendering.
Face half in shadow, one eye gleaming with ambition. Sinister smile.
Holding secret royal decree (밀서) in one hand, hidden blade in other.
Dark crimson and black palette with flashes of imperial gold. Dark energy aura.
Boss-scale: much larger and more detailed than regular sprites.
Modern mobile RPG final boss sprite. Dramatic lighting and aura effects.
Resolution: 768x768, transparent background. No background elements.
```

---

## 5. 공통 카드 일러스트 프롬프트 (주요 카드)

모든 카드 프롬프트 공통 설정:
```
[카드 공통]
High-resolution pixel art illustration for a card game.
Square composition suitable for a card game panel.
Dancheong color palette, dynamic action scene, dramatic lighting with smooth shading.
No text, no border, no frame — illustration only.
Modern mobile RPG spell/ability card art style. Detailed and vibrant.
Resolution: 512x768, transparent background.
```

### M001 — 회피 (回避)

```
[카드 공통]
Pixel art illustration of a Joseon warrior gracefully sidestepping a sword strike.
Blade passes inches from the body. Robes trail behind the dodge with motion effect.
Fluid, circular evasion movement. Speed lines and motion blur.
Cool blue and silver tones. Defensive skill energy.
```

### M002 — 도약 (跳躍)

```
[카드 공통]
Pixel art illustration of a figure leaping powerfully upward, pushing off with one foot.
Robes billowing from upward momentum, dynamic vertical composition.
Below, enemy's attack passes through empty air.
Warm gold and green tones, ascending energy effect with light trails.
```

### M003 — 베기

```
[카드 공통]
Pixel art illustration of a decisive downward slash with a Korean sword (환도).
Blade catches light in dramatic arc of motion with energy trail.
Sparks and slash effect following the blade line.
Strong vermillion red and steel gray. Raw power with impact effect.
```

### M004 — 수호

```
[카드 공통]
Pixel art illustration of a defensive stance — arms crossed, emanating qi shield.
Translucent indigo-blue barrier forming in front with ripple effect.
Solid, rooted posture. Calm determined expression.
Cool indigo and white tones. Glowing shield energy.
```

### M005 — 집중

```
[카드 공통]
Pixel art illustration of a figure kneeling in meditation, eyes closed, mudra hands.
Visible qi energy gathering as golden wisps spiraling inward toward the body.
Calm, serene atmosphere. Soft glow surrounding the figure.
Gold and soft violet tones. Inner power charging effect.
```

---

## 6. 무관 카드 일러스트 프롬프트 (주요 카드)

### G001 — 진형 전환 (陣形轉換)

```
[카드 공통]
Pixel art illustration of a Joseon military officer commanding formation change.
From above, soldiers shift like chess pieces on battlefield with motion trails.
Officer's hand gesture directs movement. Military flags waving.
Gold and dark navy tones. Tactical, strategic atmosphere with glowing command lines.
```

### G002 — 돌격 진형

```
[카드 공통]
Pixel art illustration of a V-shaped charging formation of Joseon soldiers.
Lead warrior charges forward with sword raised, soldiers flanking behind.
Dust clouds and motion blur conveying speed and devastating impact.
Fierce vermillion and iron gray tones. Charging energy effect.
```

---

## 7. 도사 카드 일러스트 프롬프트 (주요 카드)

### D001 — 부적 투척

```
[카드 공통]
Pixel art illustration of a Taoist mystic throwing a burning paper talisman (부적).
Talisman mid-flight, trailing golden fire and mystical glowing symbols.
Caster's robes billow with released supernatural energy.
Teal and gold tones with vivid supernatural fire effect.
```

---

## 8. 문관 카드 일러스트 프롬프트 (주요 카드)

### W001 — 경연 (經筵)

```
[카드 공통]
Pixel art illustration of a scholar-official delivering a lecture from ancient text.
Words from the book materialize as glowing Korean characters floating in air.
Other scholars listen intently. Candle-lit study atmosphere with warm glow.
Warm gold and deep brown tones. Scholarly energy radiating outward.
```

---

## 9. 배경 이미지 프롬프트

### bg_title — 타이틀 화면

```
[스타일 프리픽스]
High-resolution pixel art illustration panoramic view of Joseon-era Hanyang (Seoul) at sunset.
Palace rooftops in foreground, mountains behind with atmospheric depth.
Sky in vermillion, gold, deep indigo gradients — dancheong palette with smooth color transitions.
Lone figure silhouetted on a rooftop, looking toward the palace.
Modern mobile RPG title screen art. Majestic, atmospheric with detailed lighting.
Empty space in upper third for game title.
Resolution: 1080x1920, portrait orientation.
```

### bg_battle — 전투 배경

```
[스타일 프리픽스]
High-resolution pixel art illustration of a dark Joseon-era street at night.
Scattered paper lanterns casting warm volumetric glow.
Wooden buildings with tiled roofs on both sides. Cobblestone path with reflections.
Fog rolling low. Moon visible through clouds with atmospheric haze.
Modern mobile RPG battle background. Rich atmospheric lighting.
Resolution: 1080x1920, portrait orientation. Space for UI in top and bottom thirds.
```

### bg_map — 맵 배경

```
[스타일 프리픽스]
High-resolution pixel art illustration landscape map in Korean traditional style (산수화/山水畫).
Misty mountains, winding paths through pine forests, a river with reflections.
Small traditional buildings scattered across the landscape.
Modern mobile RPG overworld map style. Muted palette with subtle color and depth.
Top-down perspective, journey through the land.
Resolution: 1080x1920, portrait orientation. Muted for node overlay.
```

### bg_shop — 상점 배경

```
[스타일 프리픽스]
High-resolution pixel art illustration interior of a Joseon-era marketplace shop (시전/市廛).
Wooden shelves with detailed goods — medicines, weapons, scrolls, talismans.
Merchant's counter with abacus and coin pile. Rich material textures.
Warm lantern light with volumetric glow. Rich wood tones and gold accents.
Modern mobile RPG shop interior. Detailed item sprites on shelves.
Resolution: 1080x1920, portrait orientation. Space for shop UI overlay.
```

### bg_rest — 휴식처 배경

```
[스타일 프리픽스]
High-resolution pixel art illustration of a peaceful Joseon-era roadside inn (주막/酒幕) at twilight.
Thatched-roof building, wooden bench under old tree with detailed foliage.
Rice wine pot (막걸리) on table. Fireflies with soft glow in warm air.
Serene, healing atmosphere. Warm amber and soft green tones with twilight sky.
Modern mobile RPG rest area. Cozy atmosphere with detailed lighting.
Resolution: 1080x1920, portrait orientation. Space for rest UI.
```

---

## 10. 유물 아이콘 프롬프트

### R001 — 편자 (鞭子)

```
[아이콘 프리픽스]
Pixel art icon of a worn leather horse whip (편자) coiled in a circle.
Dark brown leather with brass handle tip. Detailed texture.
Faint golden glow effect. Clean icon. 128x128.
```

### R002 — 평안 부적

```
[아이콘 프리픽스]
Pixel art icon of a yellow paper talisman (부적) with red ink characters.
Traditional rectangular shape with mystical symbols. Soft paper texture.
Soft golden aura glow. Clean icon. 128x128.
```

### R003 — 행운의 엽전

```
[아이콘 프리픽스]
Pixel art icon of a Korean traditional coin (엽전) — round with square hole.
Greenish bronze patina with golden highlights. Metallic sheen.
Faint sparkle effects. Clean icon. 128x128.
```

### R004 — 봉황 깃털

```
[아이콘 프리픽스]
Pixel art icon of a phoenix feather (봉황 깃털) — iridescent rainbow shimmer.
Long, elegant feather with golden quill. Vibrant color gradient.
Fire wisps at tip with glow. Clean icon. 128x128.
```

### R005 — 홍삼 뿌리

```
[아이콘 프리픽스]
Pixel art icon of Korean red ginseng root (홍삼) — dark reddish-brown.
Earthy organic form with small rootlets. Detailed texture.
Faint warm red healing aura glow. Clean icon. 128x128.
```

---

## 11. UI 상태이상 아이콘 프롬프트

```
[아이콘 프리픽스] — 각각 64x64 pixel art icons

독 (Poison): Green bubbling vial with skull vapor rising. Vivid glow.
화상 (Burn): Orange-red flame icon with dynamic fire effect.
출혈 (Bleed): Dark red blood drops, three drops in triangle formation.
사망각인 (Death Mark): Black skull with red X mark. Ominous glow.
약화 (Weakness): Broken sword icon, gray and dull with crack detail.
취약 (Vulnerable): Cracked shield icon with red glowing cracks.
냉기 (Chill): Blue snowflake/ice crystal with frost effect.
힘 (Strength): Red flexing arm/fist with power aura glow.
가시 (Thorns): Green thorny vine circle with sharp detail.
갑옷 (Armor): Iron chestplate icon, metallic gray with shine highlight.
```

---

## 사용법

1. Gemini Plus (gemini.google.com) 접속
2. 이미지 생성 모드 선택 (NanoBanana 2 기본 적용)
3. `[스타일 프리픽스]` + 개별 프롬프트를 결합하여 입력
4. 생성된 이미지 다운로드 → 배경 제거 (필요시) → `art/` 폴더의 해당 경로에 PNG로 저장
5. 스타일이 일관되지 않으면 첫 번째 결과물을 참조 이미지로 업로드하여 후속 생성에 활용
6. **스타일 일관성 확인**: 결과물이 너무 사실적이면 "pixel art illustration" 강조, 너무 도트면 "smooth shading, high-resolution" 강조하여 재생성

---

## 배치 생성 팁

- **스타일 일관성**: 첫 캐릭터(불량배) 생성 결과를 참조 이미지로 업로드 — 이후 캐릭터도 동일 스타일 유지
- **카드 일러스트**: 같은 클래스 카드는 연속으로 생성하여 스타일 일관성 유지
- **아이콘**: 상태이상 아이콘은 한 세트로 프롬프트를 구성해서 통일된 스타일 확보
- **배경 제거**: 투명 배경 지정했더라도 실제 결과물 확인 필요 — remove.bg 등으로 후처리
- **해상도**: 고해상도로 생성 후 게임 내에서 축소 사용 — 원본은 항상 큰 사이즈로 보관
- **참조 이미지 활용**: NanoBanana에서 이전 결과물을 참조 이미지로 첨부하면 스타일 편차가 크게 줄어듦
