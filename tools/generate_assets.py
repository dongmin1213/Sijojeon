#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
시조전 플레이스홀더 에셋 생성기
나중에 실제 일러스트로 교체 가능한 SVG 파일들을 생성합니다.

사용법:
    python tools/generate_assets.py

생성되는 파일들:
    art/backgrounds/  - 배경 이미지 (화면별)
    art/ui/           - UI 요소 (카드 프레임, 패널 등)
    art/cards/        - 카드 아트 플레이스홀더
    art/enemies/      - 적 실루엣 플레이스홀더
    art/characters/   - 캐릭터 초상화 플레이스홀더
"""

import os
import sys

# 프로젝트 루트 경로 설정
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(SCRIPT_DIR)
ART_DIR = os.path.join(BASE_DIR, "art")


def write_svg(relative_path: str, content: str) -> None:
    """SVG 파일 저장 (UTF-8 인코딩)"""
    full_path = os.path.join(ART_DIR, relative_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"생성됨: art/{relative_path}")


# ─────────────────────────────────────────
#  배경: 타이틀 화면 — 조선 궁궐 야경
# ─────────────────────────────────────────
def gen_title_bg():
    svg = '''\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">
  <defs>
    <linearGradient id="sky_grad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#080514"/>
      <stop offset="50%"  stop-color="#150e30"/>
      <stop offset="100%" stop-color="#0e0a22"/>
    </linearGradient>
    <radialGradient id="moon_glow" cx="72%" cy="18%" r="25%">
      <stop offset="0%"   stop-color="#f0e8c8" stop-opacity="0.35"/>
      <stop offset="60%"  stop-color="#8860a0" stop-opacity="0.08"/>
      <stop offset="100%" stop-color="#080514" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="ground_glow" cx="50%" cy="100%" r="60%">
      <stop offset="0%"   stop-color="#4a2060" stop-opacity="0.5"/>
      <stop offset="100%" stop-color="#080514" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="mist_grad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#2a1858" stop-opacity="0"/>
      <stop offset="100%" stop-color="#1a0f3a" stop-opacity="0.9"/>
    </linearGradient>
    <filter id="blur_sm">
      <feGaussianBlur stdDeviation="2"/>
    </filter>
    <filter id="blur_lg">
      <feGaussianBlur stdDeviation="6"/>
    </filter>
  </defs>

  <!-- 하늘 배경 -->
  <rect width="1080" height="1920" fill="url(#sky_grad)"/>

  <!-- 달빛 글로우 -->
  <rect width="1080" height="1920" fill="url(#moon_glow)"/>

  <!-- 지평 글로우 -->
  <rect width="1080" height="1920" fill="url(#ground_glow)"/>

  <!-- 별자리 -->
  <g fill="#f0e8c8" opacity="0.7">
    <!-- 북두칠성 -->
    <circle cx="200" cy="80"  r="2.5"/>
    <circle cx="230" cy="70"  r="2"/>
    <circle cx="265" cy="65"  r="2.5"/>
    <circle cx="300" cy="68"  r="2"/>
    <circle cx="330" cy="90"  r="2.5"/>
    <circle cx="350" cy="120" r="2"/>
    <circle cx="380" cy="100" r="2.5"/>
  </g>
  <g fill="#e8e0b8" opacity="0.5">
    <!-- 산재한 작은 별들 -->
    <circle cx="50"  cy="50"  r="1.5"/>
    <circle cx="110" cy="130" r="1"/>
    <circle cx="160" cy="90"  r="1.5"/>
    <circle cx="440" cy="55"  r="1.5"/>
    <circle cx="500" cy="140" r="1"/>
    <circle cx="560" cy="60"  r="2"/>
    <circle cx="620" cy="100" r="1.5"/>
    <circle cx="680" cy="40"  r="1"/>
    <circle cx="740" cy="150" r="1.5"/>
    <circle cx="900" cy="80"  r="1.5"/>
    <circle cx="950" cy="50"  r="1"/>
    <circle cx="1000" cy="130" r="1.5"/>
    <circle cx="1040" cy="70" r="1"/>
    <circle cx="80"  cy="200" r="1"/>
    <circle cx="400" cy="170" r="1.5"/>
    <circle cx="470" cy="220" r="1"/>
    <circle cx="830" cy="180" r="1.5"/>
    <circle cx="980" cy="200" r="1"/>
  </g>

  <!-- 달 (흰색 원 + 테두리 글로우) -->
  <circle cx="778" cy="270" r="85" fill="#f5f0dd" filter="url(#blur_sm)"/>
  <circle cx="778" cy="270" r="78" fill="#fffae8"/>
  <!-- 달 표면 음영 -->
  <circle cx="760" cy="255" r="60" fill="#f0eacc" opacity="0.4"/>
  <circle cx="800" cy="290" r="30" fill="#e8dfc0" opacity="0.2"/>
  <!-- 달 테두리 -->
  <circle cx="778" cy="270" r="78" fill="none" stroke="#f0e8c8" stroke-width="2" opacity="0.6"/>
  <circle cx="778" cy="270" r="96" fill="none" stroke="#f0e8c8" stroke-width="1" opacity="0.2"
    filter="url(#blur_lg)"/>

  <!-- 구름 (달 주변) -->
  <ellipse cx="900" cy="310" rx="160" ry="35" fill="#1e1445" opacity="0.85"/>
  <ellipse cx="880" cy="290" rx="100" ry="25" fill="#2a1c55" opacity="0.7"/>
  <ellipse cx="640" cy="330" rx="140" ry="30" fill="#1e1445" opacity="0.7"/>

  <!-- 뒤쪽 산맥 (먼 거리) -->
  <path d="M0,1200
    L80,1050 L160,1110 L240,980 L350,920 L440,990
    L520,860 L600,940 L680,870 L760,950 L840,820
    L920,900 L1000,830 L1080,900
    L1080,1920 L0,1920 Z"
    fill="#130d28"/>

  <!-- 중간 산맥 -->
  <path d="M0,1350
    L100,1200 L200,1280 L320,1150 L450,1250
    L560,1130 L660,1220 L780,1100 L880,1200
    L980,1120 L1080,1200
    L1080,1920 L0,1920 Z"
    fill="#0f0b20"/>

  <!-- 앞 산맥 + 소나무 실루엣 -->
  <path d="M0,1550
    L80,1420 L160,1480 L260,1380 L380,1450
    L500,1360 L620,1430 L740,1350 L860,1440
    L960,1360 L1080,1440
    L1080,1920 L0,1920 Z"
    fill="#0a0818"/>

  <!-- 소나무 실루엣들 (좌측) -->
  <g fill="#070616" opacity="0.95">
    <!-- 소나무 1 -->
    <polygon points="60,1380 50,1420 70,1420" />
    <polygon points="60,1360 45,1395 75,1395" />
    <polygon points="60,1340 42,1380 78,1380" />
    <rect x="57" y="1420" width="6" height="30"/>
    <!-- 소나무 2 -->
    <polygon points="130,1400 118,1445 142,1445" />
    <polygon points="130,1378 115,1415 145,1415" />
    <polygon points="130,1358 112,1400 148,1400" />
    <rect x="127" y="1445" width="6" height="25"/>
    <!-- 소나무 3 -->
    <polygon points="30,1500 18,1545 42,1545" />
    <polygon points="30,1478 15,1515 45,1515" />
    <rect x="27" y="1545" width="6" height="20"/>
  </g>

  <!-- 소나무 실루엣들 (우측) -->
  <g fill="#070616" opacity="0.95">
    <polygon points="990,1380 978,1425 1002,1425" />
    <polygon points="990,1358 975,1395 1005,1395" />
    <polygon points="990,1338 972,1380 1008,1380" />
    <rect x="987" y="1425" width="6" height="30"/>

    <polygon points="1050,1420 1038,1465 1062,1465" />
    <polygon points="1050,1398 1035,1435 1065,1435" />
    <rect x="1047" y="1465" width="6" height="25"/>
  </g>

  <!-- 궁궐 실루엣 -->
  <!-- 중앙 정문 (광화문 스타일) -->
  <g fill="#050412">
    <!-- 기단 -->
    <rect x="240" y="1720" width="600" height="200"/>
    <!-- 몸체 -->
    <rect x="300" y="1650" width="480" height="80"/>
    <!-- 중앙 탑 지붕 (팔작지붕) -->
    <path d="M340,1580 L540,1520 L740,1580 L760,1650 L320,1650 Z"/>
    <path d="M310,1595 L540,1510 L770,1595" fill="none" stroke="#050412" stroke-width="8"/>
    <!-- 지붕 처마 곡선 (반전) -->
    <path d="M340,1580 Q400,1570 540,1560 Q680,1570 740,1580 L760,1590 L320,1590 Z" fill="#070618"/>
    <!-- 용마루 -->
    <rect x="430" y="1518" width="220" height="10"/>
    <!-- 곁 건물 왼쪽 -->
    <rect x="160" y="1690" width="200" height="80"/>
    <path d="M150,1650 L260,1610 L370,1650 L380,1690 L140,1690 Z"/>
    <!-- 곁 건물 오른쪽 -->
    <rect x="720" y="1690" width="200" height="80"/>
    <path d="M710,1650 L820,1610 L930,1650 L940,1690 L700,1690 Z"/>
    <!-- 성벽 -->
    <rect x="0" y="1780" width="240" height="140"/>
    <rect x="840" y="1780" width="240" height="140"/>
  </g>

  <!-- 횃불/등불 효과 -->
  <g opacity="0.6">
    <circle cx="380" cy="1720" r="12" fill="#ff8c00" filter="url(#blur_sm)"/>
    <circle cx="380" cy="1720" r="5" fill="#ffdd00"/>
    <circle cx="700" cy="1720" r="12" fill="#ff8c00" filter="url(#blur_sm)"/>
    <circle cx="700" cy="1720" r="5" fill="#ffdd00"/>
  </g>

  <!-- 안개 레이어 (하단) -->
  <rect width="1080" height="300" y="1620" fill="url(#mist_grad)"/>

  <!-- 단청 문양 장식 테두리 (상단) -->
  <g fill="none" stroke="#8040a0" stroke-width="1" opacity="0.4">
    <rect x="10" y="10" width="1060" height="120" rx="5"/>
    <!-- 반복 회자 패턴 -->
    <g transform="translate(20,20)">
      <rect x="0"   y="0"  width="16" height="16"/>
      <rect x="2"   y="2"  width="12" height="12"/>
      <rect x="4"   y="4"  width="8"  height="8"/>
    </g>
    <g transform="translate(50,20)">
      <rect x="0"   y="0"  width="16" height="16"/>
      <rect x="2"   y="2"  width="12" height="12"/>
    </g>
  </g>

  <!-- 단청 색상 상단 줄 -->
  <rect x="0"   y="0" width="1080" height="6"  fill="#8b1a1a" opacity="0.7"/>
  <rect x="0"   y="6" width="1080" height="3"  fill="#4a7a4a" opacity="0.6"/>
  <rect x="0"   y="9" width="1080" height="3"  fill="#2a5a8a" opacity="0.6"/>
  <rect x="0"   y="12" width="1080" height="2" fill="#8b6a1a" opacity="0.5"/>

  <!-- 단청 색상 하단 줄 -->
  <rect x="0" y="1912" width="1080" height="2"  fill="#8b6a1a" opacity="0.5"/>
  <rect x="0" y="1914" width="1080" height="3"  fill="#2a5a8a" opacity="0.6"/>
  <rect x="0" y="1917" width="1080" height="3"  fill="#4a7a4a" opacity="0.6"/>
  <rect x="0" y="1920" width="1080" height="6"  fill="#8b1a1a" opacity="0.7"/>
</svg>
'''
    write_svg("backgrounds/title_bg.svg", svg)


# ─────────────────────────────────────────
#  배경: 전투 화면 — 조선 전각 내부
# ─────────────────────────────────────────
def gen_battle_bg():
    svg = '''\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">
  <defs>
    <linearGradient id="hall_sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#0a0c14"/>
      <stop offset="40%"  stop-color="#141825"/>
      <stop offset="100%" stop-color="#0e1018"/>
    </linearGradient>
    <linearGradient id="floor_grad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#1a1208"/>
      <stop offset="100%" stop-color="#0d0b06"/>
    </linearGradient>
    <radialGradient id="candle_glow" cx="50%" cy="65%" r="35%">
      <stop offset="0%"   stop-color="#805020" stop-opacity="0.4"/>
      <stop offset="100%" stop-color="#0a0c14" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="enemy_light" cx="50%" cy="20%" r="40%">
      <stop offset="0%"   stop-color="#1a2040" stop-opacity="0.6"/>
      <stop offset="100%" stop-color="#0a0c14" stop-opacity="0"/>
    </radialGradient>
    <filter id="blur2">
      <feGaussianBlur stdDeviation="3"/>
    </filter>
    <pattern id="hanji" x="0" y="0" width="40" height="40" patternUnits="userSpaceOnUse">
      <rect width="40" height="40" fill="#c8a870" opacity="0.05"/>
      <line x1="0" y1="0"  x2="40" y2="0"  stroke="#c8a870" stroke-width="0.3" opacity="0.15"/>
      <line x1="0" y1="20" x2="40" y2="20" stroke="#c8a870" stroke-width="0.2" opacity="0.1"/>
      <line x1="0"  y1="0" x2="0"  y2="40" stroke="#c8a870" stroke-width="0.3" opacity="0.15"/>
      <line x1="20" y1="0" x2="20" y2="40" stroke="#c8a870" stroke-width="0.2" opacity="0.1"/>
    </pattern>
    <linearGradient id="pillar_grad" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%"   stop-color="#2a1808"/>
      <stop offset="30%"  stop-color="#3c2010"/>
      <stop offset="70%"  stop-color="#301808"/>
      <stop offset="100%" stop-color="#1e1005"/>
    </linearGradient>
  </defs>

  <!-- 배경 -->
  <rect width="1080" height="1920" fill="url(#hall_sky)"/>

  <!-- 밖 풍경 (창문 너머) -->
  <rect x="0" y="0" width="1080" height="700" fill="#070a10"/>
  <!-- 달 -->
  <circle cx="540" cy="200" r="50" fill="#e8e0c0" opacity="0.4"/>
  <circle cx="540" cy="200" r="40" fill="#f0e8c8" opacity="0.5"/>
  <!-- 먼 산 -->
  <path d="M0,650 L200,480 L350,560 L540,420 L730,540 L880,460 L1080,580 L1080,700 L0,700 Z"
        fill="#0d1020" opacity="0.9"/>

  <!-- 전각 지붕 내부 (천장) -->
  <path d="M0,50 L540,0 L1080,50 L1080,200 L0,200 Z" fill="#1a1008"/>
  <!-- 천장 대들보 -->
  <rect x="0"   y="140" width="1080" height="25" fill="#251505"/>
  <rect x="0"   y="165" width="1080" height="10" fill="#1e1005"/>
  <!-- 가로 서까래 -->
  <g fill="#1c0f04" opacity="0.8">
    <rect x="100" y="50" width="12" height="100" rx="4"/>
    <rect x="220" y="50" width="12" height="100" rx="4"/>
    <rect x="340" y="50" width="12" height="100" rx="4"/>
    <rect x="460" y="50" width="12" height="100" rx="4"/>
    <rect x="580" y="50" width="12" height="100" rx="4"/>
    <rect x="700" y="50" width="12" height="100" rx="4"/>
    <rect x="820" y="50" width="12" height="100" rx="4"/>
    <rect x="940" y="50" width="12" height="100" rx="4"/>
  </g>
  <!-- 단청 채색 (서까래 끝) -->
  <g opacity="0.7">
    <rect x="100" y="50" width="12" height="15" fill="#8b1a1a"/>
    <rect x="220" y="50" width="12" height="15" fill="#2a5a8a"/>
    <rect x="340" y="50" width="12" height="15" fill="#4a7a4a"/>
    <rect x="460" y="50" width="12" height="15" fill="#8b6a1a"/>
    <rect x="580" y="50" width="12" height="15" fill="#8b1a1a"/>
    <rect x="700" y="50" width="12" height="15" fill="#2a5a8a"/>
    <rect x="820" y="50" width="12" height="15" fill="#4a7a4a"/>
    <rect x="940" y="50" width="12" height="15" fill="#8b6a1a"/>
  </g>

  <!-- 창호지 배경 (하늘 앞) -->
  <rect x="0" y="200" width="1080" height="500" fill="url(#hanji)" opacity="0.3"/>

  <!-- 좌측 기둥 -->
  <rect x="30"  y="200" width="70" height="1100" fill="url(#pillar_grad)"/>
  <!-- 좌측 기둥 단청 -->
  <rect x="30"  y="200" width="70" height="30" fill="#8b1a1a" opacity="0.8"/>
  <rect x="30"  y="230" width="70" height="15" fill="#4a7a4a" opacity="0.7"/>
  <rect x="30"  y="245" width="70" height="10" fill="#2a5a8a" opacity="0.7"/>

  <!-- 우측 기둥 -->
  <rect x="980" y="200" width="70" height="1100" fill="url(#pillar_grad)"/>
  <rect x="980" y="200" width="70" height="30" fill="#8b1a1a" opacity="0.8"/>
  <rect x="980" y="230" width="70" height="15" fill="#4a7a4a" opacity="0.7"/>
  <rect x="980" y="245" width="70" height="10" fill="#2a5a8a" opacity="0.7"/>

  <!-- 창호 격자 (좌측 배경) -->
  <g stroke="#a08050" stroke-width="1.5" opacity="0.25" fill="none">
    <rect x="100" y="250" width="200" height="350"/>
    <!-- 가로 격자 -->
    <line x1="100" y1="310" x2="300" y2="310"/>
    <line x1="100" y1="370" x2="300" y2="370"/>
    <line x1="100" y1="430" x2="300" y2="430"/>
    <line x1="100" y1="490" x2="300" y2="490"/>
    <line x1="100" y1="550" x2="300" y2="550"/>
    <!-- 세로 격자 -->
    <line x1="160" y1="250" x2="160" y2="600"/>
    <line x1="220" y1="250" x2="220" y2="600"/>
    <line x1="240" y1="250" x2="240" y2="600"/>
  </g>

  <!-- 창호 격자 (우측 배경) -->
  <g stroke="#a08050" stroke-width="1.5" opacity="0.25" fill="none">
    <rect x="780" y="250" width="200" height="350"/>
    <line x1="780" y1="310" x2="980" y2="310"/>
    <line x1="780" y1="370" x2="980" y2="370"/>
    <line x1="780" y1="430" x2="980" y2="430"/>
    <line x1="780" y1="490" x2="980" y2="490"/>
    <line x1="780" y1="550" x2="980" y2="550"/>
    <line x1="840" y1="250" x2="840" y2="600"/>
    <line x1="900" y1="250" x2="900" y2="600"/>
    <line x1="840" y1="250" x2="840" y2="600"/>
  </g>

  <!-- 적 영역 조명 -->
  <rect width="1080" height="1920" fill="url(#enemy_light)"/>

  <!-- 촛불 조명 (좌우) -->
  <circle cx="200" cy="760" r="60" fill="#a06020" opacity="0.3" filter="url(#blur2)"/>
  <circle cx="880" cy="760" r="60" fill="#a06020" opacity="0.3" filter="url(#blur2)"/>

  <!-- 바닥 (마루) -->
  <rect x="0" y="1200" width="1080" height="720" fill="url(#floor_grad)"/>
  <!-- 마루 판자 라인 -->
  <g stroke="#1a0e04" stroke-width="1.5" opacity="0.6">
    <line x1="0" y1="1260" x2="1080" y2="1260"/>
    <line x1="0" y1="1320" x2="1080" y2="1320"/>
    <line x1="0" y1="1380" x2="1080" y2="1380"/>
    <line x1="0" y1="1440" x2="1080" y2="1440"/>
    <line x1="0" y1="1500" x2="1080" y2="1500"/>
    <line x1="0" y1="1560" x2="1080" y2="1560"/>
    <line x1="0" y1="1620" x2="1080" y2="1620"/>
    <line x1="0" y1="1680" x2="1080" y2="1680"/>
    <line x1="0" y1="1740" x2="1080" y2="1740"/>
  </g>
  <!-- 마루 세로선 -->
  <g stroke="#160c03" stroke-width="1" opacity="0.4">
    <line x1="180" y1="1200" x2="180" y2="1920"/>
    <line x1="360" y1="1200" x2="360" y2="1920"/>
    <line x1="540" y1="1200" x2="540" y2="1920"/>
    <line x1="720" y1="1200" x2="720" y2="1920"/>
    <line x1="900" y1="1200" x2="900" y2="1920"/>
  </g>

  <!-- 마루~벽 경계 -->
  <rect x="0" y="1190" width="1080" height="20" fill="#2a1808"/>

  <!-- 촛불 글로우 (하단 중앙) -->
  <rect width="1080" height="1920" fill="url(#candle_glow)"/>
</svg>
'''
    write_svg("backgrounds/battle_bg.svg", svg)


# ─────────────────────────────────────────
#  배경: 지도 화면 — 조선 수묵 산수
# ─────────────────────────────────────────
def gen_map_bg():
    svg = '''\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1200" viewBox="0 0 1080 1200">
  <defs>
    <linearGradient id="sky_map" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#0e1420"/>
      <stop offset="50%"  stop-color="#141e2e"/>
      <stop offset="100%" stop-color="#1a1830"/>
    </linearGradient>
    <linearGradient id="mist1" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#8090b0" stop-opacity="0"/>
      <stop offset="100%" stop-color="#8090b0" stop-opacity="0.25"/>
    </linearGradient>
    <linearGradient id="mist2" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#b0c0d8" stop-opacity="0"/>
      <stop offset="100%" stop-color="#b0c0d8" stop-opacity="0.3"/>
    </linearGradient>
    <filter id="blur3">
      <feGaussianBlur stdDeviation="4"/>
    </filter>
    <filter id="blur6">
      <feGaussianBlur stdDeviation="8"/>
    </filter>
  </defs>

  <!-- 하늘 -->
  <rect width="1080" height="1200" fill="url(#sky_map)"/>

  <!-- 별 -->
  <g fill="#d0d8e8" opacity="0.4">
    <circle cx="80"  cy="60"  r="1.5"/>
    <circle cx="200" cy="40"  r="1"/>
    <circle cx="350" cy="80"  r="1.5"/>
    <circle cx="500" cy="30"  r="1"/>
    <circle cx="650" cy="70"  r="1.5"/>
    <circle cx="800" cy="45"  r="1"/>
    <circle cx="950" cy="65"  r="1.5"/>
    <circle cx="1020" cy="35" r="1"/>
  </g>

  <!-- 원경 산 (5겹, 수묵화 스타일) -->
  <!-- 5겹 - 가장 먼 산 (밝고 희미) -->
  <path d="M0,600 L120,480 L240,530 L380,450 L540,400 L700,460 L840,420 L960,490 L1080,440 L1080,650 L0,650 Z"
        fill="#2a3345" opacity="0.4" filter="url(#blur6)"/>

  <!-- 4겹 -->
  <path d="M0,680 L100,550 L220,610 L360,530 L500,490 L640,560 L780,510 L900,580 L1080,530 L1080,720 L0,720 Z"
        fill="#202838" opacity="0.55" filter="url(#blur3)"/>

  <!-- 3겹 -->
  <path d="M0,760 L80,630 L200,700 L340,620 L480,580 L600,650 L740,600 L860,670 L1000,620 L1080,660 L1080,800 L0,800 Z"
        fill="#1a2030" opacity="0.7"/>

  <!-- 2겹 -->
  <path d="M0,850 L60,720 L180,790 L300,710 L440,680 L580,740 L700,690 L820,760 L960,710 L1080,750 L1080,900 L0,900 Z"
        fill="#141820" opacity="0.8"/>

  <!-- 1겹 - 가장 가까운 산 (어둡고 선명) -->
  <path d="M0,950 L80,820 L200,890 L340,810 L480,780 L600,860 L720,800 L840,870 L1000,820 L1080,860 L1080,1000 L0,1000 Z"
        fill="#0e1015"/>

  <!-- 소나무들 (가까운 산 위) -->
  <g fill="#0a0c12" opacity="0.9">
    <!-- 소나무 그룹 1 -->
    <polygon points="150,820 140,855 160,855"/>
    <polygon points="150,802 137,835 163,835"/>
    <polygon points="150,785 134,818 166,818"/>
    <rect x="147" y="855" width="6" height="20"/>
    <!-- 소나무 그룹 2 -->
    <polygon points="500,780 490,815 510,815"/>
    <polygon points="500,762 487,795 513,795"/>
    <rect x="497" y="815" width="6" height="18"/>
    <!-- 소나무 그룹 3 -->
    <polygon points="850,800 840,835 860,835"/>
    <polygon points="850,782 837,815 863,815"/>
    <polygon points="850,765 834,800 866,800"/>
    <rect x="847" y="835" width="6" height="20"/>
  </g>

  <!-- 안개 레이어들 -->
  <rect x="0" y="550" width="1080" height="200" fill="url(#mist1)"/>
  <rect x="0" y="700" width="1080" height="250" fill="url(#mist2)"/>

  <!-- 지면 (강이나 평원) -->
  <rect x="0" y="1000" width="1080" height="200" fill="#0f0e18"/>

  <!-- 강 (물 반사) -->
  <path d="M0,1050 Q270,1020 540,1060 Q810,1100 1080,1050 L1080,1200 L0,1200 Z"
        fill="#141c28"/>
  <!-- 강 반사 빛 -->
  <path d="M200,1080 Q540,1060 880,1090" stroke="#2a3c54" stroke-width="3"
        fill="none" opacity="0.5"/>
  <path d="M100,1100 Q540,1075 980,1110" stroke="#2a3c54" stroke-width="2"
        fill="none" opacity="0.3"/>

  <!-- 가장 앞 지면 (어두운 언덕) -->
  <path d="M0,1150 L200,1080 L400,1120 L540,1090 L680,1115 L900,1080 L1080,1100 L1080,1200 L0,1200 Z"
        fill="#080a10"/>
</svg>
'''
    write_svg("backgrounds/map_bg.svg", svg)


# ─────────────────────────────────────────
#  배경: 상점 — 조선 저잣거리
# ─────────────────────────────────────────
def gen_shop_bg():
    svg = '''\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">
  <defs>
    <linearGradient id="shop_bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#0c0e18"/>
      <stop offset="100%" stop-color="#10100e"/>
    </linearGradient>
    <radialGradient id="lantern_glow" cx="50%" cy="30%" r="40%">
      <stop offset="0%"   stop-color="#c86820" stop-opacity="0.5"/>
      <stop offset="100%" stop-color="#0c0e18" stop-opacity="0"/>
    </radialGradient>
    <filter id="lantern_blur">
      <feGaussianBlur stdDeviation="8"/>
    </filter>
  </defs>

  <!-- 배경 -->
  <rect width="1080" height="1920" fill="url(#shop_bg)"/>

  <!-- 등불 글로우 -->
  <rect width="1080" height="1920" fill="url(#lantern_glow)"/>

  <!-- 처마 (상단) -->
  <path d="M0,80 L540,20 L1080,80 L1080,160 L0,160 Z" fill="#1a1005"/>
  <!-- 처마 단청 -->
  <rect x="0" y="155" width="1080" height="8" fill="#8b1a1a" opacity="0.8"/>
  <rect x="0" y="163" width="1080" height="5" fill="#4a7a4a" opacity="0.7"/>

  <!-- 등불들 -->
  <!-- 중앙 대형 등불 -->
  <g transform="translate(440,100)">
    <line x1="100" y1="20" x2="100" y2="60" stroke="#8b4010" stroke-width="3"/>
    <ellipse cx="100" cy="120" rx="60" ry="80" fill="#c86820" opacity="0.9"/>
    <ellipse cx="100" cy="120" rx="50" ry="70" fill="#e8a040" opacity="0.8"/>
    <ellipse cx="100" cy="120" rx="40" ry="60" fill="#ffd060" opacity="0.6"/>
    <ellipse cx="100" cy="120" rx="60" ry="80" fill="none" stroke="#6a3010" stroke-width="2"/>
    <!-- 등불 문양 -->
    <line x1="100" y1="60" x2="100" y2="180" stroke="#6a3010" stroke-width="1" opacity="0.5"/>
    <line x1="50"  y1="90" x2="150" y2="150" stroke="#6a3010" stroke-width="1" opacity="0.5"/>
    <line x1="50"  y1="150" x2="150" y2="90" stroke="#6a3010" stroke-width="1" opacity="0.5"/>
    <!-- 술 장식 -->
    <line x1="80"  y1="200" x2="75"  y2="240" stroke="#c84020" stroke-width="2"/>
    <line x1="100" y1="200" x2="100" y2="245" stroke="#c84020" stroke-width="2"/>
    <line x1="120" y1="200" x2="125" y2="240" stroke="#c84020" stroke-width="2"/>
  </g>

  <!-- 좌우 소형 등불 -->
  <g transform="translate(150,150)">
    <line x1="40" y1="0" x2="40" y2="30" stroke="#8b4010" stroke-width="2"/>
    <ellipse cx="40" cy="70" rx="35" ry="50" fill="#c86820" opacity="0.8"/>
    <ellipse cx="40" cy="70" rx="25" ry="38" fill="#ffd060" opacity="0.6"/>
    <ellipse cx="40" cy="70" rx="35" ry="50" fill="none" stroke="#6a3010" stroke-width="2"/>
  </g>
  <g transform="translate(870,150)">
    <line x1="40" y1="0" x2="40" y2="30" stroke="#8b4010" stroke-width="2"/>
    <ellipse cx="40" cy="70" rx="35" ry="50" fill="#c86820" opacity="0.8"/>
    <ellipse cx="40" cy="70" rx="25" ry="38" fill="#ffd060" opacity="0.6"/>
    <ellipse cx="40" cy="70" rx="35" ry="50" fill="none" stroke="#6a3010" stroke-width="2"/>
  </g>

  <!-- 좌우 기둥 -->
  <rect x="40"   y="160" width="60" height="1300" fill="#1c1008"/>
  <rect x="980"  y="160" width="60" height="1300" fill="#1c1008"/>

  <!-- 물건 선반 (배경) -->
  <rect x="80"  y="400"  width="920" height="15" fill="#2a1a08" opacity="0.7"/>
  <rect x="80"  y="700"  width="920" height="15" fill="#2a1a08" opacity="0.7"/>
  <rect x="80"  y="1000" width="920" height="15" fill="#2a1a08" opacity="0.7"/>

  <!-- 약재 항아리들 (장식) -->
  <g fill="#2a1a0a" opacity="0.6">
    <ellipse cx="180" cy="380" rx="30" ry="40"/>
    <ellipse cx="180" cy="380" rx="30" ry="8" fill="#3a2a14"/>
    <ellipse cx="300" cy="380" rx="25" ry="35"/>
    <ellipse cx="300" cy="380" rx="25" ry="7" fill="#3a2a14"/>
    <ellipse cx="780" cy="380" rx="28" ry="38"/>
    <ellipse cx="900" cy="380" rx="25" ry="35"/>
  </g>

  <!-- 바닥 -->
  <rect x="0" y="1500" width="1080" height="420" fill="#0e0c06"/>
  <!-- 바닥 타일 -->
  <g stroke="#1a1408" stroke-width="1.5" opacity="0.5">
    <line x1="0" y1="1560" x2="1080" y2="1560"/>
    <line x1="0" y1="1620" x2="1080" y2="1620"/>
    <line x1="0" y1="1680" x2="1080" y2="1680"/>
    <line x1="0" y1="1740" x2="1080" y2="1740"/>
    <line x1="0" y1="1800" x2="1080" y2="1800"/>
    <line x1="180" y1="1500" x2="180" y2="1920"/>
    <line x1="360" y1="1500" x2="360" y2="1920"/>
    <line x1="540" y1="1500" x2="540" y2="1920"/>
    <line x1="720" y1="1500" x2="720" y2="1920"/>
    <line x1="900" y1="1500" x2="900" y2="1920"/>
  </g>
</svg>
'''
    write_svg("backgrounds/shop_bg.svg", svg)


# ─────────────────────────────────────────
#  배경: 휴식 — 정자 (Pavilion)
# ─────────────────────────────────────────
def gen_rest_bg():
    svg = '''\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">
  <defs>
    <linearGradient id="rest_sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#0e1810"/>
      <stop offset="60%"  stop-color="#141e14"/>
      <stop offset="100%" stop-color="#0a1008"/>
    </linearGradient>
    <radialGradient id="fire_glow" cx="50%" cy="80%" r="40%">
      <stop offset="0%"   stop-color="#804010" stop-opacity="0.5"/>
      <stop offset="100%" stop-color="#0e1810" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="moon_rest" cx="30%" cy="15%" r="20%">
      <stop offset="0%"   stop-color="#d8f0d8" stop-opacity="0.3"/>
      <stop offset="100%" stop-color="#0e1810" stop-opacity="0"/>
    </radialGradient>
    <filter id="blur4">
      <feGaussianBlur stdDeviation="5"/>
    </filter>
  </defs>

  <!-- 하늘 -->
  <rect width="1080" height="1920" fill="url(#rest_sky)"/>
  <rect width="1080" height="1920" fill="url(#moon_rest)"/>

  <!-- 별 -->
  <g fill="#c8e0c8" opacity="0.5">
    <circle cx="100" cy="80"  r="1.5"/>
    <circle cx="250" cy="50"  r="1"/>
    <circle cx="420" cy="90"  r="1.5"/>
    <circle cx="600" cy="40"  r="1"/>
    <circle cx="750" cy="75"  r="1.5"/>
    <circle cx="900" cy="55"  r="1"/>
    <circle cx="1000" cy="85" r="1.5"/>
  </g>

  <!-- 달 -->
  <circle cx="320" cy="200" r="60" fill="#d8f0d0" opacity="0.4"/>
  <circle cx="320" cy="200" r="50" fill="#e8f8e0" opacity="0.5"/>

  <!-- 대나무 숲 (우측) -->
  <g fill="#0d1a0a" opacity="0.8">
    <!-- 대나무 줄기들 -->
    <rect x="780" y="200" width="12" height="900" rx="4"/>
    <rect x="810" y="150" width="10" height="950" rx="3"/>
    <rect x="840" y="220" width="12" height="900" rx="4"/>
    <rect x="870" y="180" width="10" height="920" rx="3"/>
    <rect x="900" y="210" width="12" height="890" rx="4"/>
    <rect x="930" y="160" width="10" height="940" rx="3"/>
    <rect x="960" y="230" width="12" height="870" rx="4"/>
    <rect x="990" y="190" width="10" height="910" rx="3"/>
    <rect x="1020" y="200" width="12" height="900" rx="4"/>
    <rect x="1050" y="170" width="10" height="930" rx="3"/>
  </g>
  <!-- 대나무 잎 -->
  <g fill="#0a1808" opacity="0.7">
    <ellipse cx="800" cy="300" rx="40" ry="8" transform="rotate(-30,800,300)"/>
    <ellipse cx="820" cy="280" rx="35" ry="7" transform="rotate(20,820,280)"/>
    <ellipse cx="860" cy="320" rx="40" ry="8" transform="rotate(-20,860,320)"/>
    <ellipse cx="900" cy="290" rx="38" ry="7" transform="rotate(25,900,290)"/>
    <ellipse cx="950" cy="310" rx="40" ry="8" transform="rotate(-15,950,310)"/>
  </g>

  <!-- 연못 (중하단) -->
  <ellipse cx="400" cy="1500" rx="300" ry="150" fill="#0e1c10"/>
  <!-- 연못 반사 -->
  <ellipse cx="400" cy="1500" rx="280" ry="130" fill="#0a1408"/>
  <!-- 연꽃 잎 -->
  <g fill="#0f1e0c" opacity="0.7">
    <ellipse cx="300" cy="1480" rx="50" ry="20" transform="rotate(-15,300,1480)"/>
    <ellipse cx="450" cy="1510" rx="45" ry="18" transform="rotate(10,450,1510)"/>
    <ellipse cx="360" cy="1540" rx="40" ry="16" transform="rotate(-5,360,1540)"/>
  </g>
  <!-- 연꽃 -->
  <g fill="#c84060" opacity="0.6">
    <circle cx="320" cy="1465" r="12"/>
    <circle cx="460" cy="1495" r="10"/>
  </g>

  <!-- 정자 (중앙 뒤편) -->
  <g fill="#0c1008">
    <!-- 지붕 -->
    <path d="M340,800 L540,730 L740,800 L760,850 L320,850 Z"/>
    <!-- 기둥 -->
    <rect x="350" y="850" width="20" height="250"/>
    <rect x="710" y="850" width="20" height="250"/>
    <!-- 마루 -->
    <rect x="320" y="1090" width="440" height="20"/>
    <!-- 마루 하부 -->
    <rect x="340" y="1110" width="400" height="40"/>
  </g>

  <!-- 불 (모닥불) -->
  <circle cx="540" cy="1400" r="40" fill="#804010" opacity="0.4" filter="url(#blur4)"/>
  <circle cx="540" cy="1400" r="20" fill="#c06020" opacity="0.5"/>
  <circle cx="540" cy="1400" r="10" fill="#ffa020" opacity="0.6"/>
  <rect width="1080" height="1920" fill="url(#fire_glow)"/>

  <!-- 땅 -->
  <path d="M0,1700 Q270,1680 540,1700 Q810,1720 1080,1700 L1080,1920 L0,1920 Z"
        fill="#080e08"/>
  <!-- 풀밭 -->
  <g fill="#0a1408" opacity="0.6">
    <line x1="100" y1="1700" x2="90"  y2="1670" stroke="#0a1408" stroke-width="3"/>
    <line x1="120" y1="1695" x2="115" y2="1660" stroke="#0a1408" stroke-width="2"/>
    <line x1="200" y1="1690" x2="195" y2="1655" stroke="#0a1408" stroke-width="3"/>
    <line x1="850" y1="1700" x2="845" y2="1665" stroke="#0a1408" stroke-width="3"/>
    <line x1="920" y1="1695" x2="915" y2="1660" stroke="#0a1408" stroke-width="2"/>
  </g>
</svg>
'''
    write_svg("backgrounds/rest_bg.svg", svg)


# ─────────────────────────────────────────
#  UI: 카드 프레임 (등급별)
# ─────────────────────────────────────────
def gen_card_frames():
    # 공통 카드 프레임 요소 (함수로 재사용)
    def card_frame_svg(
        name_kr: str,
        border_color: str,
        bg_color: str,
        accent_color: str,
        glow_color: str,
        corner_color: str
    ) -> str:
        return f'''\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="160" height="220" viewBox="0 0 160 220">
  <defs>
    <linearGradient id="card_bg_{name_kr}" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="{bg_color}"/>
      <stop offset="100%" stop-color="{bg_color}" stop-opacity="0.85"/>
    </linearGradient>
    <radialGradient id="card_glow_{name_kr}" cx="50%" cy="40%" r="50%">
      <stop offset="0%"   stop-color="{glow_color}" stop-opacity="0.2"/>
      <stop offset="100%" stop-color="{bg_color}"   stop-opacity="0"/>
    </radialGradient>
  </defs>

  <!-- 카드 배경 -->
  <rect x="2" y="2" width="156" height="216" rx="10" fill="url(#card_bg_{name_kr})"/>

  <!-- 글로우 효과 -->
  <rect x="2" y="2" width="156" height="216" rx="10" fill="url(#card_glow_{name_kr})"/>

  <!-- 외부 테두리 -->
  <rect x="1" y="1" width="158" height="218" rx="11"
    fill="none" stroke="{border_color}" stroke-width="2.5"/>

  <!-- 내부 테두리 (이중) -->
  <rect x="6" y="6" width="148" height="208" rx="8"
    fill="none" stroke="{accent_color}" stroke-width="1" opacity="0.5"/>

  <!-- 상단 이름 영역 -->
  <rect x="6" y="6" width="148" height="35" rx="7"
    fill="{accent_color}" opacity="0.15"/>
  <line x1="6" y1="41" x2="154" y2="41"
    stroke="{border_color}" stroke-width="1.5" opacity="0.7"/>

  <!-- 카드 아트 영역 -->
  <rect x="6" y="42" width="148" height="100" fill="{bg_color}" opacity="0.5"/>
  <!-- 아트 영역 패턴 (격자) -->
  <g stroke="{accent_color}" stroke-width="0.5" opacity="0.15">
    <line x1="6"  y1="62"  x2="154" y2="62"/>
    <line x1="6"  y1="82"  x2="154" y2="82"/>
    <line x1="6"  y1="102" x2="154" y2="102"/>
    <line x1="6"  y1="122" x2="154" y2="122"/>
    <line x1="34" y1="42" x2="34" y2="142"/>
    <line x1="62" y1="42" x2="62" y2="142"/>
    <line x1="90" y1="42" x2="90" y2="142"/>
    <line x1="118" y1="42" x2="118" y2="142"/>
  </g>

  <!-- 타입 구분선 -->
  <line x1="6" y1="142" x2="154" y2="142"
    stroke="{border_color}" stroke-width="1.5" opacity="0.7"/>

  <!-- 비용 영역 (좌상단) -->
  <circle cx="22" cy="22" r="14" fill="{accent_color}" opacity="0.8"/>
  <circle cx="22" cy="22" r="12" fill="{bg_color}"/>
  <circle cx="22" cy="22" r="12"
    fill="none" stroke="{border_color}" stroke-width="1.5"/>

  <!-- 코너 장식 (4개) -->
  <!-- 좌상 -->
  <path d="M6,16 L16,6 L6,6 Z"   fill="{corner_color}" opacity="0.7"/>
  <!-- 우상 -->
  <path d="M154,16 L144,6 L154,6 Z" fill="{corner_color}" opacity="0.7"/>
  <!-- 좌하 -->
  <path d="M6,204 L16,214 L6,214 Z"  fill="{corner_color}" opacity="0.7"/>
  <!-- 우하 -->
  <path d="M154,204 L144,214 L154,214 Z" fill="{corner_color}" opacity="0.7"/>

  <!-- 하단 효과 텍스트 영역 -->
  <rect x="6" y="143" width="148" height="71" rx="0"
    fill="{bg_color}" opacity="0.3"/>
  <!-- 텍스트 영역 줄 (플레이스홀더) -->
  <rect x="14" y="152" width="120" height="5" rx="2" fill="{accent_color}" opacity="0.2"/>
  <rect x="14" y="162" width="100" height="5" rx="2" fill="{accent_color}" opacity="0.2"/>
  <rect x="14" y="172" width="110" height="5" rx="2" fill="{accent_color}" opacity="0.2"/>
  <rect x="14" y="182" width="80"  height="5" rx="2" fill="{accent_color}" opacity="0.2"/>

  <!-- 하단 구분선 -->
  <line x1="6" y1="214" x2="154" y2="214"
    stroke="{border_color}" stroke-width="1" opacity="0.5"/>
</svg>
'''

    # 일반 (Common) - 회색/은색
    write_svg("ui/card_frame_common.svg", card_frame_svg(
        "common",
        border_color="#7a8898",
        bg_color="#1a2030",
        accent_color="#9aaabb",
        glow_color="#7a8898",
        corner_color="#9aaabb"
    ))

    # 고급 (Uncommon) - 청록/에메랄드
    write_svg("ui/card_frame_uncommon.svg", card_frame_svg(
        "uncommon",
        border_color="#2aaa80",
        bg_color="#0e2018",
        accent_color="#40cc99",
        glow_color="#2aaa80",
        corner_color="#40cc99"
    ))

    # 희귀 (Rare) - 금/호박
    write_svg("ui/card_frame_rare.svg", card_frame_svg(
        "rare",
        border_color="#cc9020",
        bg_color="#201808",
        accent_color="#f0c040",
        glow_color="#cc9020",
        corner_color="#f0c040"
    ))

    # 전설 (Legendary) - 보라/자주
    write_svg("ui/card_frame_legendary.svg", card_frame_svg(
        "legendary",
        border_color="#9a40cc",
        bg_color="#180820",
        accent_color="#cc80ff",
        glow_color="#9a40cc",
        corner_color="#cc80ff"
    ))


# ─────────────────────────────────────────
#  UI: 적 실루엣 플레이스홀더
# ─────────────────────────────────────────
def gen_enemy_placeholders():
    enemies = {
        "yangban": ("#1a1a3a", "#4060c0", "양반"),
        "posu":    ("#1a0a0a", "#c04040", "포수"),
        "doksa":   ("#0a1a0a", "#40a040", "독사"),
        "gumiho":  ("#1a0a1a", "#c040c0", "구미호"),
    }

    for key, (bg, color, name_kr) in enemies.items():
        svg = f'''\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="200" height="300" viewBox="0 0 200 300">
  <defs>
    <radialGradient id="glow_{key}" cx="50%" cy="40%" r="50%">
      <stop offset="0%"   stop-color="{color}" stop-opacity="0.3"/>
      <stop offset="100%" stop-color="{bg}"    stop-opacity="0"/>
    </radialGradient>
  </defs>

  <!-- 배경 글로우 -->
  <rect width="200" height="300" fill="{bg}"/>
  <rect width="200" height="300" fill="url(#glow_{key})"/>

  <!-- 실루엣 ({name_kr}) -->
  <!-- 머리 -->
  <circle cx="100" cy="70" r="35" fill="{color}" opacity="0.85"/>
  <!-- 갓/관모 -->
  <ellipse cx="100" cy="40" rx="30" ry="8" fill="{color}" opacity="0.9"/>
  <rect x="80" y="32" width="40" height="12" rx="3" fill="{color}" opacity="0.9"/>

  <!-- 몸통 -->
  <path d="M60,105 Q50,150 45,220 L155,220 Q150,150 140,105 Z"
        fill="{color}" opacity="0.8"/>

  <!-- 팔 (좌) -->
  <path d="M65,115 Q40,150 30,200 Q45,205 55,200 Q60,160 80,125 Z"
        fill="{color}" opacity="0.8"/>
  <!-- 팔 (우) -->
  <path d="M135,115 Q160,150 170,200 Q155,205 145,200 Q140,160 120,125 Z"
        fill="{color}" opacity="0.8"/>

  <!-- 다리 (좌) -->
  <path d="M75,218 Q70,255 65,280 L90,280 Q88,255 95,218 Z"
        fill="{color}" opacity="0.8"/>
  <!-- 다리 (우) -->
  <path d="M125,218 Q130,255 135,280 L110,280 Q112,255 105,218 Z"
        fill="{color}" opacity="0.8"/>

  <!-- 테두리 빛 -->
  <path d="M60,105 Q50,150 45,220 L155,220 Q150,150 140,105 Z"
        fill="none" stroke="{color}" stroke-width="2" opacity="0.4"/>
</svg>
'''
        write_svg(f"enemies/{key}.svg", svg)


# ─────────────────────────────────────────
#  UI: 캐릭터 초상화 플레이스홀더
# ─────────────────────────────────────────
def gen_character_portraits():
    characters = {
        "gisaeng":  ("#200a0a", "#e06080", "기생", "선홍"),
        "scholar":  ("#0a0a20", "#6080e0", "선비", "청람"),
        "warrior":  ("#0a1408", "#60c060", "무관", "청록"),
        "assassin": ("#0a0a0a", "#a0a0c0", "자객", "은회"),
    }

    for key, (bg, color, name_kr, color_name_kr) in characters.items():
        svg = f'''\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="240" height="320" viewBox="0 0 240 320">
  <defs>
    <radialGradient id="portrait_glow_{key}" cx="50%" cy="35%" r="55%">
      <stop offset="0%"   stop-color="{color}" stop-opacity="0.25"/>
      <stop offset="100%" stop-color="{bg}"    stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="portrait_bg_{key}" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="{bg}"/>
      <stop offset="100%" stop-color="{bg}" stop-opacity="0.7"/>
    </linearGradient>
  </defs>

  <!-- 배경 -->
  <rect width="240" height="320" fill="url(#portrait_bg_{key})" rx="8"/>
  <rect width="240" height="320" fill="url(#portrait_glow_{key})" rx="8"/>

  <!-- 테두리 -->
  <rect x="2" y="2" width="236" height="316" rx="7"
    fill="none" stroke="{color}" stroke-width="2" opacity="0.6"/>

  <!-- 실루엣 — {name_kr} ({color_name_kr}) -->
  <!-- 머리 -->
  <circle cx="120" cy="100" r="42" fill="{color}" opacity="0.85"/>

  <!-- 머리 장식 (캐릭터별 차별화) -->
  <!-- 상투/비녀 등 -->
  <ellipse cx="120" cy="62" rx="20" ry="6" fill="{color}" opacity="0.9"/>

  <!-- 어깨/상체 -->
  <path d="M40,160 Q50,145 80,140 L160,140 Q190,145 200,160 L210,280 L30,280 Z"
        fill="{color}" opacity="0.8"/>

  <!-- 목 -->
  <rect x="105" y="138" width="30" height="20" fill="{color}" opacity="0.85"/>

  <!-- 팔 라인 (도포 소매) -->
  <path d="M40,160 Q20,180 15,220 Q30,225 40,218 Q50,185 80,165 Z"
        fill="{color}" opacity="0.75"/>
  <path d="M200,160 Q220,180 225,220 Q210,225 200,218 Q190,185 160,165 Z"
        fill="{color}" opacity="0.75"/>

  <!-- 테두리 내부 장식 -->
  <rect x="8" y="8" width="224" height="304" rx="5"
    fill="none" stroke="{color}" stroke-width="0.8" opacity="0.3"/>

  <!-- 코너 문양 -->
  <g fill="{color}" opacity="0.5">
    <polygon points="8,8 22,8 8,22"/>
    <polygon points="232,8 218,8 232,22"/>
    <polygon points="8,312 22,312 8,298"/>
    <polygon points="232,312 218,312 232,298"/>
  </g>
</svg>
'''
        write_svg(f"characters/{key}.svg", svg)


# ─────────────────────────────────────────
#  UI: 카드 아트 플레이스홀더
# ─────────────────────────────────────────
def gen_card_art_placeholder():
    svg = '''\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="148" height="100" viewBox="0 0 148 100">
  <defs>
    <linearGradient id="art_bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%"   stop-color="#1a1828"/>
      <stop offset="100%" stop-color="#0e0c18"/>
    </linearGradient>
  </defs>

  <!-- 배경 -->
  <rect width="148" height="100" fill="url(#art_bg)"/>

  <!-- 대각선 X (플레이스홀더 표시) -->
  <line x1="0" y1="0"   x2="148" y2="100" stroke="#3a3850" stroke-width="1"/>
  <line x1="148" y1="0" x2="0"   y2="100" stroke="#3a3850" stroke-width="1"/>

  <!-- 수묵화 스타일 산 실루엣 -->
  <path d="M0,80 L40,40 L60,55 L90,25 L115,45 L148,35 L148,100 L0,100 Z"
        fill="#2a2838" opacity="0.6"/>
  <path d="M0,90 L30,65 L60,75 L90,55 L120,68 L148,58 L148,100 L0,100 Z"
        fill="#1e1c2a" opacity="0.8"/>

  <!-- 달 -->
  <circle cx="110" cy="20" r="12" fill="#3a3858" opacity="0.6"/>
  <circle cx="110" cy="20" r="9"  fill="#4a4868" opacity="0.5"/>
</svg>
'''
    write_svg("cards/placeholder.svg", svg)


# ─────────────────────────────────────────
#  UI: 패널 프레임 (단청 테두리)
# ─────────────────────────────────────────
def gen_panel_frame():
    svg = '''\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="400" height="200" viewBox="0 0 400 200">
  <defs>
    <linearGradient id="panel_bg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="#1a1828" stop-opacity="0.95"/>
      <stop offset="100%" stop-color="#12101e" stop-opacity="0.90"/>
    </linearGradient>
  </defs>

  <!-- 패널 배경 -->
  <rect width="400" height="200" rx="8" fill="url(#panel_bg)"/>

  <!-- 외부 테두리 (단청 색상) -->
  <rect x="0" y="0" width="400" height="200" rx="8"
    fill="none" stroke="#5a3860" stroke-width="2"/>

  <!-- 상단 단청 줄 -->
  <rect x="4" y="0" width="392" height="5" rx="0" fill="#8b1a1a" opacity="0.8"/>
  <rect x="4" y="5" width="392" height="3"           fill="#4a7a4a" opacity="0.7"/>
  <rect x="4" y="8" width="392" height="2"           fill="#2a5a8a" opacity="0.6"/>

  <!-- 하단 단청 줄 -->
  <rect x="4" y="192" width="392" height="3"         fill="#2a5a8a" opacity="0.6"/>
  <rect x="4" y="195" width="392" height="3"         fill="#4a7a4a" opacity="0.7"/>
  <rect x="4" y="198" width="392" height="5" rx="0"  fill="#8b1a1a" opacity="0.8"/>

  <!-- 내부 가는 테두리 -->
  <rect x="12" y="12" width="376" height="176" rx="5"
    fill="none" stroke="#5a3860" stroke-width="1" opacity="0.4"/>

  <!-- 코너 문양 -->
  <g fill="#8060a0" opacity="0.5">
    <!-- 좌상 -->
    <rect x="4"   y="10" width="6" height="6"/>
    <rect x="10"  y="4"  width="6" height="6"/>
    <!-- 우상 -->
    <rect x="390" y="10" width="6" height="6"/>
    <rect x="384" y="4"  width="6" height="6"/>
    <!-- 좌하 -->
    <rect x="4"   y="184" width="6" height="6"/>
    <rect x="10"  y="190" width="6" height="6"/>
    <!-- 우하 -->
    <rect x="390" y="184" width="6" height="6"/>
    <rect x="384" y="190" width="6" height="6"/>
  </g>
</svg>
'''
    write_svg("ui/panel_frame.svg", svg)


# ─────────────────────────────────────────
#  UI: 버튼 배경 (일반/호버/눌림)
# ─────────────────────────────────────────
def gen_button_styles():
    def button_svg(state_kr: str, bg: str, border: str, highlight: str) -> str:
        return f'''\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="300" height="80" viewBox="0 0 300 80">
  <defs>
    <linearGradient id="btn_grad_{state_kr}" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"   stop-color="{highlight}" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="{bg}"/>
    </linearGradient>
  </defs>

  <!-- 버튼 배경 -->
  <rect x="2" y="2" width="296" height="76" rx="8"
    fill="{bg}"/>
  <rect x="2" y="2" width="296" height="76" rx="8"
    fill="url(#btn_grad_{state_kr})"/>

  <!-- 외부 테두리 -->
  <rect x="1" y="1" width="298" height="78" rx="9"
    fill="none" stroke="{border}" stroke-width="2"/>

  <!-- 상단 하이라이트 선 -->
  <line x1="10" y1="3" x2="290" y2="3"
    stroke="{highlight}" stroke-width="1.5" opacity="0.4"/>

  <!-- 좌우 단청 색 포인트 -->
  <rect x="1" y="10" width="4" height="60" fill="{border}" opacity="0.6"/>
  <rect x="295" y="10" width="4" height="60" fill="{border}" opacity="0.6"/>
</svg>
'''

    write_svg("ui/button_normal.svg", button_svg(
        "normal", "#1e1a30", "#6a4a8a", "#9a7abb"))
    write_svg("ui/button_hover.svg", button_svg(
        "hover", "#2a2240", "#9a6acc", "#cc99ff"))
    write_svg("ui/button_pressed.svg", button_svg(
        "pressed", "#14101e", "#5a3a7a", "#7a5a9a"))


# ─────────────────────────────────────────
#  실행
# ─────────────────────────────────────────
if __name__ == "__main__":
    print("시조전 플레이스홀더 에셋 생성 시작...")
    print(f"출력 경로: {ART_DIR}")
    print()

    gen_title_bg()
    gen_battle_bg()
    gen_map_bg()
    gen_shop_bg()
    gen_rest_bg()
    gen_card_frames()
    gen_enemy_placeholders()
    gen_character_portraits()
    gen_card_art_placeholder()
    gen_panel_frame()
    gen_button_styles()

    print()
    print("완료! Godot에서 프로젝트를 열면 .import 파일이 자동 생성됩니다.")
    print("실제 에셋으로 교체할 때는 같은 이름의 파일을 덮어쓰면 됩니다.")
