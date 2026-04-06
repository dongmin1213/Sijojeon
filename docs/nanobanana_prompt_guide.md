# 시조전 — NanoBanana 프롬프트 가이드

> 버전: 0.2 | 최종 업데이트: 2026-04-06
> Google NanoBanana 2 (Gemini Plus) 기반 에셋 생성 프롬프트 모음
> **아트 스타일: 고품질 픽셀아트 (High-Quality Pixel Art)**

---

## NanoBanana 프롬프트 작성 원칙

1. **주제(Subject)를 먼저** — 가장 중요한 요소를 앞에 배치
2. **스타일 일관성** — 모든 프롬프트에 동일한 스타일 접두사 사용
3. **구체적 묘사** — "멋진" 대신 "어두운 조명, 금박 하이라이트, 픽셀 디더링"
4. **모순 금지** — "미니멀"과 "복잡한 디테일"을 동시에 쓰지 않기
5. **기술 스펙 명시** — 해상도, 배경 투명도, 비율 등
6. **픽셀아트 특성** — anti-aliasing 최소화, 제한된 팔레트, 명확한 실루엣

---

## 공통 스타일 프리픽스

모든 프롬프트 앞에 붙이는 스타일 지정 문구:

```
[스타일 프리픽스 — 카드/캐릭터/적용]
High-quality pixel art in the style of classic 16-bit SNES/GBA RPGs.
Joseon dynasty (1392-1910) Korean historical aesthetic.
Limited color palette inspired by dancheong (단청): vermillion red, indigo blue, pine green, gold, violet purple.
Dark and atmospheric with dramatic pixel shading and dithering.
Clean pixel edges, no anti-aliasing, detailed sprite work.
Suitable for a mobile roguelike card game.
```

```
[스타일 프리픽스 — 아이콘용]
Crisp pixel art icon style, 16-bit RPG aesthetic.
Korean traditional dancheong (단청) color palette: vermillion, indigo, gold, pine green.
Clean pixel edges, minimal dithering, transparent background.
Sharp silhouette readable at small sizes.
```

---

## 1. 플레이어 캐릭터 프롬프트

### char_mugwan — 무관 (武官)

```
[스타일 프리픽스] 
High-quality pixel art portrait of a Joseon dynasty military officer (무관/武官).
Powerful standing stance, waist-up composition.
Dark iron-gray pixel armor (갑옷) over a navy blue inner robe, detailed pixel shading on metal plates.
Korean traditional sword (환도/環刀) at his waist, one hand on the pommel.
Strong jawline, determined eyes, topknot (상투) under a warrior's headband.
Muscular build with visible battle scars rendered in pixel detail.
Dark background with pixel smoke and ember particle effects.
16-bit RPG character portrait style. No anti-aliasing.
Resolution: 1024x1536, transparent background.
```

### char_dosa — 도사 (道士)

```
[스타일 프리픽스]
High-quality pixel art portrait of a Joseon dynasty Taoist mystic (도사/道士).
Meditative yet powerful pose, waist-up composition.
Flowing white and pale blue Taoist robes (도포) with pixel yin-yang embroidery detail.
Holding a glowing paper talisman (부적) in one hand, pixel qi energy swirling around the other.
Long white beard, serene but piercing eyes, topknot with a jade pin.
Thin, wiry build suggesting inner strength.
Ethereal teal and purple pixel energy wisps surrounding the figure.
16-bit RPG character portrait style. Dithered glow effects.
Resolution: 1024x1536, transparent background.
```

### char_mungwan — 문관 (文官)

```
[스타일 프리픽스]
High-quality pixel art portrait of a Joseon dynasty civil scholar-official (문관/文官).
Intellectual authority, waist-up composition.
Formal scholar's hat (사모/紗帽) and crimson court robe (관복) with pixel rank badge (흉배).
Holding a calligraphy brush in one hand and an ancient text scroll in the other.
Sharp, intelligent eyes, calm expression. Neatly trimmed beard.
Slim, elegant build with refined posture.
Faint golden pixel calligraphy characters floating in background.
16-bit RPG character portrait style. No anti-aliasing.
Resolution: 1024x1536, transparent background.
```

---

## 2. 적 캐릭터 프롬프트 — 1막 (한양)

### E001 — 불량배

```
[스타일 프리픽스]
Pixel art sprite of a Joseon-era street thug (불량배) from Hanyang back alleys.
Rough, unkempt pixel character. Torn and dirty hemp clothing with visible pixel wear.
Wielding a crude short knife, aggressive forward-leaning stance.
Scar across cheek, missing tooth, wild eyes. Lean muscular build.
Bare feet or straw sandals. Full body sprite, facing slightly left.
16-bit RPG enemy sprite style. Clean pixel edges, no anti-aliasing.
Resolution: 512x512, transparent background.
```

### E002 — 하급 포졸

```
[스타일 프리픽스]
Pixel art sprite of a corrupt low-ranking Joseon constable (포졸).
Red military vest over dark clothes, black hat. Pixel fabric detail.
Carrying a wooden cudgel (곤장) over one shoulder, smirking.
Pudgy build, menacing presence. Full body sprite.
16-bit RPG enemy sprite style. Clean pixel edges.
Resolution: 512x512, transparent background.
```

### E003 — 전당포 주인

```
[스타일 프리픽스]
Pixel art sprite of a sly Joseon-era pawnshop owner (전당포 주인).
Dark gray durumagi with money pouch at belt. Holding wooden abacus (주판).
Thin face, narrow eyes, hunched greedy posture. Cunning pixel expression.
Full body sprite, slightly hunched forward.
16-bit RPG enemy sprite style. Clean pixel edges.
Resolution: 512x512, transparent background.
```

### E004 — 떠돌이 도적

```
[스타일 프리픽스]
Pixel art sprite of a wandering Joseon bandit (도적) from mountain roads.
Ragged, patched clothing with pixel tattered cloak.
Wielding a short dagger, crouching ambush-ready stance.
Gaunt face, wild hair, desperate eyes. Dynamic pixel pose.
Full body sprite.
16-bit RPG enemy sprite style. Clean pixel edges.
Resolution: 512x512, transparent background.
```

### E005 — 원혼

```
[스타일 프리픽스]
Pixel art sprite of a Korean vengeful ghost (원혼/怨魂).
Semi-transparent pixel form with pale blue-white dithered glow effect.
Tattered white Joseon mourning dress (소복).
Long black pixel hair covering part of face, glowing hollow eyes.
Floating above ground with pixel wispy trails at feet.
Full body sprite. Pixel dithering for transparency effect.
16-bit RPG ghost enemy style. 
Resolution: 512x512, transparent background.
```

### E006 — 도깨비불

```
[스타일 프리픽스]
Pixel art sprite of a Korean spirit fire (도깨비불).
Swirling blue-green and orange pixel flame orb, head-sized.
Faint face-like features within the flames — mischievous pixel expression.
Trailing pixel fire wisps, floating in darkness.
Centered composition with pixel glow effect using dithering.
16-bit RPG magical enemy sprite style.
Resolution: 512x512, transparent background.
```

### E007 — 관노

```
[스타일 프리픽스]
Pixel art sprite of a Joseon government slave (관노/官奴) forced to fight.
Rough hemp clothes with pixel iron shackles on wrists.
Wielding makeshift iron pitchfork (쇠스랑). Muscular build from forced labor.
Desperate, haunted pixel expression. Barefoot.
Full body sprite, aggressive but reluctant stance.
16-bit RPG enemy sprite style. Clean pixel edges.
Resolution: 512x512, transparent background.
```

### E008 — 기방 청객

```
[스타일 프리픽스]
Pixel art sprite of a drunken Joseon-era gisaeng house patron (청객).
Disheveled noble clothing — untied sash, tilted hat. Pixel fabric detail.
Holding folding fan (부채) as weapon, swaying unsteady stance.
Flushed red pixel face, bleary aggressive eyes. Portly build.
Full body sprite.
16-bit RPG enemy sprite style. Clean pixel edges.
Resolution: 512x512, transparent background.
```

### E009 — 야경꾼

```
[스타일 프리픽스]
Pixel art sprite of a Joseon night watchman (야경꾼).
Dark blue-black patrol clothing, round hat. Pixel uniform detail.
Carrying pixel lantern on pole in one hand, short spear in other.
Alert, stern expression. Lean, vigilant build.
Full body sprite, walking patrol stance.
16-bit RPG enemy sprite style. Pixel lantern glow effect.
Resolution: 512x512, transparent background.
```

### E010 — 시전 상인

```
[스타일 프리픽스]
Pixel art sprite of a corrupt Joseon market merchant (시전 상인).
Fine silk durumagi with fur-lined collar, pixel fabric sheen.
Holding rigged weighted scale (저울). Calculating expression, thin mustache.
Well-fed build. Gold and coin pouches at belt with pixel gleam.
Full body sprite.
16-bit RPG enemy sprite style. Clean pixel edges.
Resolution: 512x512, transparent background.
```

### E011 — 나팔수

```
[스타일 프리픽스]
Pixel art sprite of a Joseon government herald/trumpeter (나팔수).
Dark blue official clothing with red sash. Pixel uniform detail.
Holding traditional Korean trumpet (나팔) ready to blow.
Young face, nervous but dutiful pixel expression. Slim build.
Full body sprite, formal attention stance.
16-bit RPG enemy sprite style. Clean pixel edges.
Resolution: 512x512, transparent background.
```

---

## 3. 1막 엘리트 적 프롬프트

### EL001 — 양반

```
[스타일 프리픽스]
Large pixel art sprite of a tyrannical Joseon aristocrat (양반/兩班).
Luxurious silk robes in dark purple with pixel gold embroidery detail.
Holding a long smoking pipe (장죽/長竹) like a scepter.
Arrogant pixel expression, looking down with contempt. Groomed beard.
Tall, imposing presence. Larger sprite than regular enemies.
Full body, authoritative stance. Detailed pixel shading.
16-bit RPG elite enemy sprite. Rich color palette.
Resolution: 768x768, transparent background.
```

### EL002 — 독사

```
[스타일 프리픽스]
Large pixel art sprite of a Joseon-era poison assassin (독사/毒蛇).
All-black tight clothing with dark face mask (복면). Pixel stealth aesthetic.
Multiple green and purple poison vials strapped across chest, pixel glow.
Only eyes visible — cold, calculating, serpent-like pixel detail.
Lean, agile crouching strike-ready pose. Pixel toxic mist around hands.
Full body, dynamic pose. Larger sprite than regular enemies.
16-bit RPG elite enemy sprite. Dithered poison effect.
Resolution: 768x768, transparent background.
```

### EL003 — 포수

```
[스타일 프리픽스]
Large pixel art sprite of a Joseon-era elite hunter (포수/砲手).
Practical leather and fur hunting clothes, mountain style pixel detail.
Korean bow (활) on back, holding matchlock musket (화승총). Pixel weapon detail.
Weathered face, sharp hawk-like eyes, stubble beard.
Sturdy, hardened build. Larger sprite than regular enemies.
Full body, aiming stance. Detailed pixel shading.
16-bit RPG elite enemy sprite.
Resolution: 768x768, transparent background.
```

---

## 4. 보스 프롬프트

### B_ACT1_FINAL — 판서 이무령

```
[스타일 프리픽스]
Boss-scale pixel art of a corrupt Joseon Minister of Personnel (이조판서/吏曹判書) Yi Mu-ryeong.
Highest rank court robes — crimson and gold pixels, crane rank badge (흉배) with pixel detail.
Seated on ornate throne-like chair, one hand holding a glowing red seal (관인).
Cold, merciless pixel eyes beneath stiff official's hat (사모). White trimmed beard.
Imposing presence, dark pixel shadows with red/gold pixel lighting.
The seal glows with pixel dithering effect — absolute power.
Full body, seated. Boss-scale: much larger and more detailed than regular sprites.
16-bit RPG final boss sprite. Rich pixel shading and dithering.
Resolution: 1024x1024, transparent background.
```

### B_ACT2_FINAL — 쌍두 호랑이

```
[스타일 프리픽스]
Boss-scale pixel art of a monstrous twin-headed tiger (쌍두 호랑이/兩頭虎).
Massive Korean tiger with TWO pixel heads:
Left head (좌두): calculating, cold blue pixel eyes.
Right head (우두): ferocious roaring, fiery orange pixel eyes.
Enormous muscular pixel body with glowing mystical markings on fur.
Standing on rocky mountain ridge, pixel storm clouds behind.
Korean tiger stripes with supernatural golden pixel glow effect.
Full body, facing forward. Boss-scale sprite.
16-bit RPG boss monster. Detailed pixel art with dithered glow.
Resolution: 1024x1024, transparent background.
```

### B_ACT3_FINAL — 역적 대감

```
[스타일 프리픽스]
Boss-scale pixel art of a treasonous Joseon lord (역적 대감/逆賊大監).
Court robes with dragon motifs instead of crane — pixel embroidery detail.
Face half in pixel shadow, one eye gleaming with ambition. Sinister smile.
Holding secret royal decree (밀서) in one hand, hidden blade in other.
Standing before war map table with pixel strategy pieces.
Dark crimson and black pixel palette with flashes of imperial gold.
Full body, dramatic pixel lighting. Boss-scale sprite.
16-bit RPG final boss. Rich pixel shading, atmospheric dithering.
Resolution: 1024x1024, transparent background.
```

---

## 5. 공통 카드 일러스트 프롬프트 (주요 카드)

모든 카드 프롬프트 공통 설정:
```
[카드 공통]
High-quality pixel art card illustration.
Square composition suitable for a card game panel.
Dancheong color palette, dynamic action scene, dramatic pixel lighting.
No text, no border, no frame — pixel illustration only.
16-bit RPG spell/ability card art style. Detailed pixel work.
Resolution: 512x768, transparent background.
```

### M001 — 회피 (回避)

```
[카드 공통]
Pixel art of a Joseon warrior gracefully sidestepping a sword strike.
Blade passes inches from the body. Pixel robes trail behind the dodge.
Fluid, circular evasion movement. Pixel motion blur effect.
Cool blue and silver pixel tones. Defensive skill.
```

### M002 — 도약 (跳躍)

```
[카드 공통]
Pixel art of a figure leaping powerfully upward, pushing off with one foot.
Pixel robes billowing from upward momentum.
Below, enemy's attack passes through empty air.
Warm gold and green pixel tones, ascending energy effect.
```

### M003 — 베기

```
[카드 공통]
Pixel art of a decisive downward slash with a Korean sword (환도).
Blade catches pixel light in dramatic arc of motion.
Pixel sparks and energy trail following the slash line.
Strong vermillion red and steel gray. Raw pixel power.
```

### M004 — 수호

```
[카드 공통]
Pixel art of a defensive stance — arms crossed, emanating pixel qi shield.
Translucent indigo-blue pixel barrier forming in front.
Solid, rooted posture. Calm pixel expression.
Cool indigo and white tones. Dithered shield glow.
```

### M005 — 집중

```
[카드 공통]
Pixel art of a figure kneeling in meditation, eyes closed, mudra hands.
Visible pixel qi energy gathering as golden wisps spiraling inward.
Calm, serene. Dithered glow around the body.
Gold and soft violet pixel tones.
```

---

## 6. 무관 카드 일러스트 프롬프트 (주요 카드)

### G001 — 진형 전환 (陣形轉換)

```
[카드 공통]
Pixel art of a Joseon military officer commanding formation change.
From above, pixel soldiers shift like chess pieces on battlefield.
Officer's hand gesture directs movement. Pixel military flags waving.
Gold and dark navy pixel tones. Tactical, strategic atmosphere.
```

### G002 — 돌격 진형

```
[카드 공통]
Pixel art of a V-shaped charging formation of Joseon soldiers.
Lead warrior charges forward with sword raised, pixel soldiers flanking.
Pixel dust and motion blur conveying speed and impact.
Fierce vermillion and iron gray pixel tones.
```

---

## 7. 도사 카드 일러스트 프롬프트 (주요 카드)

### D001 — 부적 투척

```
[카드 공통]
Pixel art of a Taoist mystic throwing a burning paper talisman (부적).
Talisman mid-flight, trailing pixel golden fire and mystical symbols.
Caster's pixel robes billow with released energy.
Teal and gold pixel tones with supernatural pixel fire effect.
```

---

## 8. 문관 카드 일러스트 프롬프트 (주요 카드)

### W001 — 경연 (經筵)

```
[카드 공통]
Pixel art of a scholar-official delivering a lecture from ancient text.
Words from the book materialize as glowing pixel Korean characters in air.
Other pixel scholars listen. Pixel candle-lit study atmosphere.
Warm gold and deep brown pixel tones. Scholarly energy.
```

---

## 9. 배경 이미지 프롬프트

### bg_title — 타이틀 화면

```
[스타일 프리픽스]
Detailed pixel art panoramic view of Joseon-era Hanyang (Seoul) at sunset.
Pixel palace rooftops in foreground, pixel mountains behind.
Sky in vermillion, gold, deep indigo pixel gradients — dancheong palette.
Lone pixel figure silhouetted on a rooftop, looking toward the palace.
16-bit RPG title screen pixel art. Majestic, atmospheric pixel dithering.
Empty space in upper third for game title.
Resolution: 1080x1920, portrait orientation.
```

### bg_battle — 전투 배경

```
[스타일 프리픽스]
Detailed pixel art of a dark Joseon-era street at night.
Scattered pixel paper lanterns casting warm glow.
Pixel wooden buildings with tiled roofs on both sides. Cobblestone pixel path.
Pixel fog rolling low. Moon visible through pixel clouds.
16-bit RPG battle background. Atmospheric pixel dithering.
Resolution: 1080x1920, portrait orientation. Space for UI in top and bottom thirds.
```

### bg_map — 맵 배경

```
[스타일 프리픽스]
Pixel art landscape map in Korean traditional style (산수화/山水畫).
Pixel misty mountains, winding paths through pine forests, a river.
Small pixel traditional buildings scattered across the landscape.
16-bit RPG overworld map style. Muted pixel palette with subtle color.
Top-down perspective, journey through the land.
Resolution: 1080x1920, portrait orientation. Muted for node overlay.
```

### bg_shop — 상점 배경

```
[스타일 프리픽스]
Detailed pixel art interior of a Joseon-era marketplace shop (시전/市廛).
Pixel wooden shelves with goods — medicines, weapons, scrolls, talismans.
Merchant's counter with pixel abacus and coin pile.
Warm pixel lantern light. Rich wood tones and gold accents.
16-bit RPG shop interior. Detailed pixel item sprites on shelves.
Resolution: 1080x1920, portrait orientation. Space for shop UI overlay.
```

### bg_rest — 휴식처 배경

```
[스타일 프리픽스]
Detailed pixel art of a peaceful Joseon-era roadside inn (주막/酒幕) at twilight.
Pixel thatched-roof building, wooden bench under old pixel tree.
Rice wine pot (막걸리) on table. Pixel fireflies in warm air.
Serene, healing. Warm amber and soft green pixel tones.
16-bit RPG rest area. Cozy pixel atmosphere with dithered twilight.
Resolution: 1080x1920, portrait orientation. Space for rest UI.
```

---

## 10. 유물 아이콘 프롬프트

### R001 — 편자 (鞭子)

```
[아이콘 프리픽스]
Pixel art icon of a worn leather horse whip (편자) coiled in a circle.
Dark brown pixel leather with brass handle tip.
Faint golden pixel glow. Clean pixel icon. 128x128.
```

### R002 — 평안 부적

```
[아이콘 프리픽스]
Pixel art icon of a yellow paper talisman (부적) with red ink characters.
Traditional rectangular shape with pixel mystical symbols.
Soft golden pixel aura. Clean pixel icon. 128x128.
```

### R003 — 행운의 엽전

```
[아이콘 프리픽스]
Pixel art icon of a Korean traditional coin (엽전) — round with square hole.
Greenish bronze pixel patina with golden highlights.
Faint pixel sparkles. Clean pixel icon. 128x128.
```

### R004 — 봉황 깃털

```
[아이콘 프리픽스]
Pixel art icon of a phoenix feather (봉황 깃털) — iridescent pixel rainbow.
Long, elegant pixel feather with golden quill.
Pixel fire wisps at tip. Clean pixel icon. 128x128.
```

### R005 — 홍삼 뿌리

```
[아이콘 프리픽스]
Pixel art icon of Korean red ginseng root (홍삼) — dark reddish-brown.
Earthy pixel form with small rootlets.
Faint warm red pixel healing aura. Clean pixel icon. 128x128.
```

---

## 11. UI 상태이상 아이콘 프롬프트

```
[아이콘 프리픽스] — 각각 64x64 pixel art icons

독 (Poison): Pixel green bubbling vial, skull vapor rising. Clean pixel edges.
화상 (Burn): Pixel orange-red flame icon, sharp pixel edges.
출혈 (Bleed): Pixel dark red blood drops, three drops in triangle.
사망각인 (Death Mark): Pixel black skull with red X mark.
약화 (Weakness): Pixel broken sword icon, gray and dull.
취약 (Vulnerable): Pixel cracked shield icon, red pixel cracks.
냉기 (Chill): Pixel blue snowflake/ice crystal.
힘 (Strength): Pixel red flexing arm/fist, power aura.
가시 (Thorns): Pixel green thorny vine circle.
갑옷 (Armor): Pixel iron chestplate icon, metallic gray.
```

---

## 사용법

1. Gemini Plus (gemini.google.com) 접속
2. 이미지 생성 모드 선택 (NanoBanana 2 기본 적용)
3. `[스타일 프리픽스]` + 개별 프롬프트를 결합하여 입력
4. 생성된 이미지 다운로드 → 배경 제거 (필요시) → `art/` 폴더의 해당 경로에 PNG로 저장
5. 스타일이 일관되지 않으면 첫 번째 결과물을 참조 이미지로 업로드하여 후속 생성에 활용
6. **픽셀아트 품질 확인**: 생성된 이미지에 anti-aliasing이 섞여있으면 "no anti-aliasing, clean pixel edges" 강조하여 재생성

---

## 배치 생성 팁

- **픽셀아트 일관성**: 첫 캐릭터 생성 후 결과물을 참조 이미지로 업로드 — 픽셀 크기와 팔레트가 동일하게 유지됨
- **카드 일러스트**: 같은 클래스 카드는 연속으로 생성하여 픽셀 스타일 일관성 유지
- **아이콘**: 상태이상 아이콘은 한 세트로 프롬프트를 구성해서 통일된 픽셀 그리드 확보
- **배경 제거**: 투명 배경 지정했더라도 실제 결과물 확인 필요 — remove.bg 등으로 후처리
- **해상도 주의**: 픽셀아트는 정수배 스케일링 필수 (2x, 3x, 4x) — 비정수배 축소 시 픽셀이 깨짐
- **팔레트 제한**: NanoBanana에 "limited color palette, maximum 32 colors" 추가하면 더 클래식한 픽셀아트 느낌
