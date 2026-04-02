# -*- coding: utf-8 -*-
"""
플레이스홀더 오디오 파일 생성 스크립트.
한국 전통 음악 느낌의 5음 음계(궁상각치우) 기반 BGM과 게임 SFX를 WAV로 생성한다.
"""

import wave
import struct
import math
import os
import random

SAMPLE_RATE = 22050
CHANNELS = 1
SAMPLE_WIDTH = 2  # 16-bit

# 프로젝트 루트
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BGM_DIR = os.path.join(PROJECT_ROOT, "art", "audio", "bgm")
SFX_DIR = os.path.join(PROJECT_ROOT, "art", "audio", "sfx")


def ensure_dirs():
    os.makedirs(BGM_DIR, exist_ok=True)
    os.makedirs(SFX_DIR, exist_ok=True)


def write_wav(filepath: str, samples: list[float], sample_rate: int = SAMPLE_RATE):
    """float 샘플(-1.0~1.0)을 16-bit WAV로 저장한다."""
    with wave.open(filepath, "w") as wf:
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(SAMPLE_WIDTH)
        wf.setframerate(sample_rate)
        data = b""
        for s in samples:
            s = max(-1.0, min(1.0, s))
            data += struct.pack("<h", int(s * 32767))
        wf.writeframes(data)


def sine_wave(freq: float, duration: float, volume: float = 0.5, sr: int = SAMPLE_RATE) -> list[float]:
    """주파수 freq, 길이 duration초의 사인파 생성."""
    n = int(sr * duration)
    return [volume * math.sin(2 * math.pi * freq * i / sr) for i in range(n)]


def envelope(samples: list[float], attack: float = 0.01, release: float = 0.05) -> list[float]:
    """간단한 ADSR 엔벨로프(attack + release)."""
    n = len(samples)
    attack_samples = int(SAMPLE_RATE * attack)
    release_samples = int(SAMPLE_RATE * release)
    result = list(samples)
    for i in range(min(attack_samples, n)):
        result[i] *= i / attack_samples
    for i in range(min(release_samples, n)):
        idx = n - 1 - i
        result[idx] *= i / release_samples
    return result


def fade_out(samples: list[float], duration: float = 1.0) -> list[float]:
    """마지막 duration초를 페이드 아웃."""
    n = len(samples)
    fade_n = int(SAMPLE_RATE * duration)
    result = list(samples)
    for i in range(min(fade_n, n)):
        idx = n - 1 - i
        result[idx] *= i / fade_n
    return result


def mix(a: list[float], b: list[float]) -> list[float]:
    """두 샘플 리스트를 믹스."""
    length = max(len(a), len(b))
    result = [0.0] * length
    for i in range(len(a)):
        result[i] += a[i]
    for i in range(len(b)):
        result[i] += b[i]
    # 클리핑 방지
    peak = max(abs(s) for s in result) if result else 1.0
    if peak > 1.0:
        result = [s / peak for s in result]
    return result


def concat(*parts: list[float]) -> list[float]:
    """여러 샘플 리스트를 이어붙인다."""
    result = []
    for p in parts:
        result.extend(p)
    return result


def silence(duration: float) -> list[float]:
    return [0.0] * int(SAMPLE_RATE * duration)


# 5음 음계 (궁상각치우 = C D E G A, 한 옥타브)
PENTATONIC = [261.63, 293.66, 329.63, 392.00, 440.00]
PENTATONIC_LOW = [f / 2 for f in PENTATONIC]
PENTATONIC_HIGH = [f * 2 for f in PENTATONIC]


def make_melody(notes_freqs: list[float], note_dur: float = 0.4, gap: float = 0.05, volume: float = 0.35) -> list[float]:
    """노트 시퀀스를 멜로디로."""
    parts = []
    for freq in notes_freqs:
        note = envelope(sine_wave(freq, note_dur, volume), attack=0.02, release=0.08)
        parts.append(note)
        parts.append(silence(gap))
    return concat(*parts)


def loop_to_length(samples: list[float], target_seconds: float) -> list[float]:
    """샘플을 반복해서 target_seconds 길이로."""
    target_n = int(SAMPLE_RATE * target_seconds)
    if not samples:
        return silence(target_seconds)
    result = []
    while len(result) < target_n:
        result.extend(samples)
    return result[:target_n]


def drone(freq: float, duration: float, volume: float = 0.15) -> list[float]:
    """저음 드론 사운드."""
    n = int(SAMPLE_RATE * duration)
    return [volume * math.sin(2 * math.pi * freq * i / SAMPLE_RATE) *
            (1 + 0.3 * math.sin(2 * math.pi * 0.5 * i / SAMPLE_RATE)) for i in range(n)]


# === BGM 생성 ===

def generate_title_bgm() -> list[float]:
    """타이틀 BGM — 느리고 장엄한 느낌, 15초."""
    melody_notes = [PENTATONIC[0], PENTATONIC[2], PENTATONIC[4], PENTATONIC[3],
                    PENTATONIC[2], PENTATONIC[0], PENTATONIC[4], PENTATONIC[2]]
    melody = make_melody(melody_notes, note_dur=0.8, gap=0.2, volume=0.3)
    bg = drone(PENTATONIC_LOW[0], len(melody) / SAMPLE_RATE, 0.12)
    result = loop_to_length(mix(melody, bg), 15.0)
    return fade_out(result, 2.0)


def generate_map_bgm() -> list[float]:
    """맵 BGM — 탐색 느낌, 12초."""
    melody_notes = [PENTATONIC[2], PENTATONIC[3], PENTATONIC[4], PENTATONIC[2],
                    PENTATONIC[0], PENTATONIC[3], PENTATONIC[2], PENTATONIC[4]]
    melody = make_melody(melody_notes, note_dur=0.5, gap=0.1, volume=0.25)
    bg = drone(PENTATONIC_LOW[2], len(melody) / SAMPLE_RATE, 0.1)
    result = loop_to_length(mix(melody, bg), 12.0)
    return fade_out(result, 1.5)


def generate_battle_bgm() -> list[float]:
    """전투 BGM — 긴장감, 빠른 템포, 12초."""
    melody_notes = [PENTATONIC[4], PENTATONIC[3], PENTATONIC[4], PENTATONIC_HIGH[0],
                    PENTATONIC[3], PENTATONIC[2], PENTATONIC[4], PENTATONIC[3],
                    PENTATONIC[2], PENTATONIC[0], PENTATONIC[2], PENTATONIC[3]]
    melody = make_melody(melody_notes, note_dur=0.25, gap=0.05, volume=0.35)
    bg = drone(PENTATONIC_LOW[0], len(melody) / SAMPLE_RATE, 0.15)
    result = loop_to_length(mix(melody, bg), 12.0)
    return fade_out(result, 1.0)


def generate_boss_bgm() -> list[float]:
    """보스 BGM — 위압적, 낮은 음, 15초."""
    melody_notes = [PENTATONIC_LOW[0], PENTATONIC_LOW[2], PENTATONIC[0], PENTATONIC_LOW[4],
                    PENTATONIC_LOW[3], PENTATONIC_LOW[0], PENTATONIC[2], PENTATONIC[0]]
    melody = make_melody(melody_notes, note_dur=0.4, gap=0.1, volume=0.4)
    # 낮은 드론 두 개 겹침
    bg1 = drone(PENTATONIC_LOW[0] / 2, len(melody) / SAMPLE_RATE, 0.2)
    bg2 = drone(PENTATONIC_LOW[0] * 0.75, len(melody) / SAMPLE_RATE, 0.1)
    result = loop_to_length(mix(mix(melody, bg1), bg2), 15.0)
    return fade_out(result, 2.0)


def generate_shop_bgm() -> list[float]:
    """상점 BGM — 밝고 경쾌, 10초."""
    melody_notes = [PENTATONIC[4], PENTATONIC_HIGH[0], PENTATONIC[3], PENTATONIC[4],
                    PENTATONIC[2], PENTATONIC[3], PENTATONIC[4], PENTATONIC_HIGH[0]]
    melody = make_melody(melody_notes, note_dur=0.35, gap=0.08, volume=0.3)
    bg = drone(PENTATONIC[0], len(melody) / SAMPLE_RATE, 0.08)
    result = loop_to_length(mix(melody, bg), 10.0)
    return fade_out(result, 1.0)


def generate_rest_bgm() -> list[float]:
    """휴식 BGM — 고요하고 평화로운, 12초."""
    melody_notes = [PENTATONIC[0], PENTATONIC[2], PENTATONIC[4], PENTATONIC[3],
                    PENTATONIC[2], PENTATONIC[4], PENTATONIC[3], PENTATONIC[0]]
    melody = make_melody(melody_notes, note_dur=1.0, gap=0.3, volume=0.2)
    bg = drone(PENTATONIC_LOW[0], len(melody) / SAMPLE_RATE, 0.08)
    result = loop_to_length(mix(melody, bg), 12.0)
    return fade_out(result, 2.0)


# === SFX 생성 ===

def generate_card_play() -> list[float]:
    """카드 내는 효과음 — 짧은 스윕."""
    n = int(SAMPLE_RATE * 0.15)
    result = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 400 + 800 * (1 - t / 0.15)
        vol = 0.5 * (1 - t / 0.15)
        result.append(vol * math.sin(2 * math.pi * freq * t))
    return result


def generate_card_draw() -> list[float]:
    """카드 드로우 — 올라가는 스윕."""
    n = int(SAMPLE_RATE * 0.2)
    result = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 300 + 600 * (t / 0.2)
        vol = 0.4 * (1 - t / 0.2) ** 0.5
        result.append(vol * math.sin(2 * math.pi * freq * t))
    return result


def generate_damage() -> list[float]:
    """피해 효과음 — 노이즈 + 저음."""
    n = int(SAMPLE_RATE * 0.3)
    result = []
    random.seed(42)
    for i in range(n):
        t = i / SAMPLE_RATE
        env = max(0, 1 - t / 0.3)
        noise = (random.random() * 2 - 1) * 0.3
        low = 0.4 * math.sin(2 * math.pi * 80 * t)
        result.append(env * (noise + low))
    return result


def generate_heal() -> list[float]:
    """회복 효과음 — 부드러운 상승음."""
    n = int(SAMPLE_RATE * 0.5)
    result = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 440 + 220 * (t / 0.5)
        env = math.sin(math.pi * t / 0.5) * 0.4
        result.append(env * math.sin(2 * math.pi * freq * t))
    return result


def generate_block() -> list[float]:
    """방어 효과음 — 금속 타격."""
    n = int(SAMPLE_RATE * 0.2)
    result = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = max(0, 1 - t / 0.2) ** 2
        s = 0.3 * math.sin(2 * math.pi * 800 * t)
        s += 0.2 * math.sin(2 * math.pi * 1200 * t)
        s += 0.15 * math.sin(2 * math.pi * 2400 * t)
        result.append(env * s)
    return result


def generate_victory() -> list[float]:
    """승리 효과음 — 팡파르."""
    notes = [PENTATONIC[0], PENTATONIC[2], PENTATONIC[4], PENTATONIC_HIGH[0]]
    parts = []
    for freq in notes:
        note = envelope(sine_wave(freq, 0.3, 0.5), attack=0.01, release=0.05)
        parts.append(note)
    # 마지막 음 길게
    final = envelope(sine_wave(PENTATONIC_HIGH[0], 0.8, 0.5), attack=0.01, release=0.3)
    parts.append(final)
    return concat(*parts)


def generate_defeat() -> list[float]:
    """패배 효과음 — 하강하는 어두운 음."""
    notes = [PENTATONIC[4], PENTATONIC[2], PENTATONIC[0], PENTATONIC_LOW[4]]
    parts = []
    for freq in notes:
        note = envelope(sine_wave(freq, 0.4, 0.4), attack=0.02, release=0.1)
        parts.append(note)
    return concat(*parts)


def generate_button_click() -> list[float]:
    """버튼 클릭 — 짧은 틱."""
    n = int(SAMPLE_RATE * 0.05)
    result = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = max(0, 1 - t / 0.05) ** 3
        result.append(env * 0.4 * math.sin(2 * math.pi * 1000 * t))
    return result


def generate_coin() -> list[float]:
    """코인 효과음 — 밝은 띵."""
    n = int(SAMPLE_RATE * 0.3)
    result = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = max(0, 1 - t / 0.3) ** 1.5
        s = 0.3 * math.sin(2 * math.pi * 1500 * t)
        s += 0.2 * math.sin(2 * math.pi * 2000 * t)
        result.append(env * s)
    return result


def generate_buff() -> list[float]:
    """버프 효과음 - 상승하는 화음."""
    n = int(SAMPLE_RATE * 0.35)
    result = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * t / 0.35) * 0.4
        freq = 500 + 300 * (t / 0.35)
        s = math.sin(2 * math.pi * freq * t)
        s += 0.5 * math.sin(2 * math.pi * freq * 1.5 * t)
        result.append(env * s * 0.3)
    return result


def generate_debuff() -> list[float]:
    """디버프 효과음 - 하강하는 불협화음."""
    n = int(SAMPLE_RATE * 0.35)
    result = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = max(0, 1 - t / 0.35) * 0.4
        freq = 500 - 250 * (t / 0.35)
        s = math.sin(2 * math.pi * freq * t)
        s += 0.4 * math.sin(2 * math.pi * freq * 1.07 * t)
        result.append(env * s * 0.3)
    return result


def generate_enemy_attack() -> list[float]:
    """적 공격 효과음 - 둔탁한 타격."""
    n = int(SAMPLE_RATE * 0.25)
    result = []
    random.seed(99)
    for i in range(n):
        t = i / SAMPLE_RATE
        env = max(0, 1 - t / 0.25) ** 1.5
        noise = (random.random() * 2 - 1) * 0.2
        low = 0.5 * math.sin(2 * math.pi * 120 * t)
        result.append(env * (noise + low))
    return result


def generate_sijo_slot() -> list[float]:
    """시조 슬롯 배치 효과음 - 맑은 종소리."""
    n = int(SAMPLE_RATE * 0.2)
    result = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = max(0, 1 - t / 0.2) ** 1.2
        s = 0.3 * math.sin(2 * math.pi * 880 * t)
        s += 0.2 * math.sin(2 * math.pi * 1320 * t)
        result.append(env * s)
    return result


def generate_sijo_complete() -> list[float]:
    """시조 완성 효과음 - 화려한 팡파르."""
    notes = [PENTATONIC[2], PENTATONIC[4], PENTATONIC_HIGH[0], PENTATONIC_HIGH[0]]
    parts = []
    for i, freq in enumerate(notes):
        dur = 0.2 if i < 3 else 0.6
        note = envelope(sine_wave(freq, dur, 0.5), attack=0.01, release=0.1)
        parts.append(note)
    return concat(*parts)


def generate_end_turn() -> list[float]:
    """턴 종료 효과음 - 짧은 벨."""
    n = int(SAMPLE_RATE * 0.15)
    result = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = max(0, 1 - t / 0.15) ** 2
        s = 0.35 * math.sin(2 * math.pi * 600 * t)
        s += 0.15 * math.sin(2 * math.pi * 900 * t)
        result.append(env * s)
    return result


def generate_upgrade() -> list[float]:
    """업그레이드 효과음 - 빛나는 상승음."""
    notes = [PENTATONIC[0], PENTATONIC[2], PENTATONIC[4]]
    parts = []
    for freq in notes:
        note = envelope(sine_wave(freq, 0.15, 0.45), attack=0.01, release=0.03)
        parts.append(note)
    final = envelope(sine_wave(PENTATONIC_HIGH[0], 0.4, 0.45), attack=0.01, release=0.15)
    parts.append(final)
    return concat(*parts)


def main():
    ensure_dirs()

    print("BGM ...")
    bgm_generators = {
        "title": generate_title_bgm,
        "map": generate_map_bgm,
        "battle": generate_battle_bgm,
        "boss": generate_boss_bgm,
        "shop": generate_shop_bgm,
        "rest": generate_rest_bgm,
    }

    for name, gen_func in bgm_generators.items():
        filepath = os.path.join(BGM_DIR, f"{name}.wav")
        samples = gen_func()
        write_wav(filepath, samples)
        size_kb = os.path.getsize(filepath) / 1024
        print(f"  {name}.wav - {size_kb:.1f} KB")

    print("\nSFX ...")
    sfx_generators = {
        "card_play": generate_card_play,
        "card_draw": generate_card_draw,
        "damage": generate_damage,
        "heal": generate_heal,
        "block": generate_block,
        "victory": generate_victory,
        "defeat": generate_defeat,
        "button_click": generate_button_click,
        "coin": generate_coin,
        "buff": generate_buff,
        "debuff": generate_debuff,
        "enemy_attack": generate_enemy_attack,
        "sijo_slot": generate_sijo_slot,
        "sijo_complete": generate_sijo_complete,
        "end_turn": generate_end_turn,
        "upgrade": generate_upgrade,
    }

    for name, gen_func in sfx_generators.items():
        filepath = os.path.join(SFX_DIR, f"{name}.wav")
        samples = gen_func()
        write_wav(filepath, samples)
        size_kb = os.path.getsize(filepath) / 1024
        print(f"  {name}.wav - {size_kb:.1f} KB")

    # 총 용량 계산
    total_bytes = 0
    for d in [BGM_DIR, SFX_DIR]:
        for f in os.listdir(d):
            if f.endswith(".wav"):
                total_bytes += os.path.getsize(os.path.join(d, f))
    print(f"\nTotal: {total_bytes / 1024:.1f} KB ({total_bytes / (1024*1024):.2f} MB)")
    print("Done!")


if __name__ == "__main__":
    main()
