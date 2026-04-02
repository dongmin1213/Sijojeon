#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
시조전 밸런스 자동 검증 스크립트
ZER-129: [P1] 밸런스 자동 검증 테스트 코드

사용법:
    python tools/validate_balance.py
    python tools/validate_balance.py --verbose
    python tools/validate_balance.py --check cards
    python tools/validate_balance.py --check relics
    python tools/validate_balance.py --check enemies
    python tools/validate_balance.py --check balance

종료 코드:
    0 = 모든 검증 통과
    1 = 검증 실패 있음
"""

import io
import json
import os
import re
import sys
import argparse
from pathlib import Path

# Windows CP949 콘솔에서도 UTF-8 출력 강제
if sys.stdout.encoding and sys.stdout.encoding.lower() not in ("utf-8", "utf8"):
    sys.stdout = io.TextIOWrapper(
        sys.stdout.buffer, encoding="utf-8", errors="replace"
    )

# ── 경로 설정 ──────────────────────────────────────────────────────────────
REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data"
DOCS_DIR = REPO_ROOT / "docs"

CARD_FILES = {
    "common":  DATA_DIR / "cards" / "common.json",
    "dosa":    DATA_DIR / "cards" / "dosa.json",
    "mugwan":  DATA_DIR / "cards" / "mugwan.json",
    "mungwan": DATA_DIR / "cards" / "mungwan.json",
}

ENEMY_FILES = sorted((DATA_DIR / "enemies").glob("*.json"))
RELIC_FILE  = DATA_DIR / "relics" / "relics.json"
BALANCE_MD  = DOCS_DIR / "balance_sheet.md"

# ── relic_manager.gd 에서 실제 처리되는 트리거 목록 (코드 분석 기반) ──────────
HANDLED_TRIGGERS = {
    "battle_start",
    "dual",
    "on_turn_start",
    "turn_start",
    "on_combat_victory",
    "on_elite_victory",
    "on_enter_boss_combat",
    "on_enter_shop",
    "on_buff_apply_to_self",
    "on_deck_shuffle",
    "on_kill_enemy",
    "on_card_exhaust",
    "sijo_milestone_2",
    "sijo_complete",
    "passive",
    "on_first_card_play_per_turn",
    "on_apply_poison",
    "boss_battle_start",
    "on_lethal_damage",
    "on_formation_card_play",
    "on_scholarship_exhaust",
    "on_spell_card_play",
    "on_summon_token_death",
    "on_wildcard_play",
}


# ── 공통 헬퍼 ─────────────────────────────────────────────────────────────
class ValidationResult:
    def __init__(self, suite: str):
        self.suite = suite
        self.errors:   list[str] = []
        self.warnings: list[str] = []
        self.passed:   int = 0

    def err(self, msg: str):
        self.errors.append(msg)

    def warn(self, msg: str):
        self.warnings.append(msg)

    def ok(self, count: int = 1):
        self.passed += count

    @property
    def failed(self) -> int:
        return len(self.errors)

    def summary(self, verbose: bool = False) -> str:
        lines = [f"\n{'='*60}", f"[{self.suite}]"]
        if verbose or self.errors:
            for e in self.errors:
                lines.append(f"  [FAIL] {e}")
        if verbose and self.warnings:
            for w in self.warnings:
                lines.append(f"  [WARN] {w}")
        status = "PASS" if not self.errors else "FAIL"
        lines.append(
            f"  결과: {status} -- "
            f"통과 {self.passed}, 실패 {self.failed}, 경고 {len(self.warnings)}"
        )
        return "\n".join(lines)


def load_json(path: Path) -> dict | list | None:
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        return None


# ── 1. 카드 데이터 무결성 ──────────────────────────────────────────────────
CARD_REQUIRED_FIELDS = ["id", "name", "beat", "cost", "type", "effect", "values"]
VALID_BEAT_VALUES    = {0, 3, 4}   # 0 = 와일드카드 (ZER-101)
VALID_CARD_TYPES     = {"attack", "defense", "formation", "skill", "power",
                         "movement", "curse", "spell"}
COST_RANGE           = (0, 4)      # 현행 스펙: 기 0~4


def validate_cards(verbose: bool = False) -> ValidationResult:
    r = ValidationResult("카드 데이터 무결성")
    all_ids: set[str] = set()

    for pool, path in CARD_FILES.items():
        data = load_json(path)
        if data is None:
            r.err(f"{path.name} 로드 실패")
            continue

        cards = data.get("cards", [])
        if not cards:
            r.err(f"{path.name}: cards 배열 비어있음")
            continue

        for card in cards:
            cid = card.get("id", "(id없음)")

            # 필수 필드 존재 확인
            for field in CARD_REQUIRED_FIELDS:
                if field not in card:
                    r.err(f"카드 {cid} — 필수 필드 누락: {field}")
                else:
                    r.ok()

            # name 구조 검증
            name = card.get("name", {})
            if isinstance(name, dict):
                for lang in ("ko", "hanja", "romanized"):
                    if not name.get(lang):
                        r.warn(f"카드 {cid} — name.{lang} 비어있음")
            else:
                r.err(f"카드 {cid} — name 필드가 object 아님")

            # beat 값 검증
            beat = card.get("beat")
            if beat is not None:
                if beat not in VALID_BEAT_VALUES:
                    r.err(f"카드 {cid} — beat={beat} (허용값: {VALID_BEAT_VALUES})")
                else:
                    r.ok()

            # cost 범위 검증
            cost = card.get("cost")
            if cost is not None:
                if not (COST_RANGE[0] <= cost <= COST_RANGE[1]):
                    r.err(f"카드 {cid} — cost={cost} (허용범위: {COST_RANGE})")
                else:
                    r.ok()

            # type 검증
            ctype = card.get("type")
            if ctype and ctype not in VALID_CARD_TYPES:
                r.warn(f"카드 {cid} — 알 수 없는 type: {ctype}")

            # values 필드 존재 (빈 dict 허용)
            if "values" in card and not isinstance(card["values"], dict):
                r.err(f"카드 {cid} — values가 object 아님")
            else:
                r.ok()

            # 중복 ID 검사
            if cid in all_ids:
                r.err(f"카드 ID 중복: {cid}")
            else:
                all_ids.add(cid)
                r.ok()

    return r


# ── 2. 유물 트리거 검증 ────────────────────────────────────────────────────
RELIC_REQUIRED_FIELDS = ["id", "name", "rarity", "trigger", "effect", "values"]
VALID_RARITIES        = {1, 2, 3, 4}


def validate_relics(verbose: bool = False) -> ValidationResult:
    r = ValidationResult("유물 트리거 검증")
    data = load_json(RELIC_FILE)
    if data is None:
        r.err(f"{RELIC_FILE.name} 로드 실패")
        return r

    relics = data.get("relics", [])
    if not relics:
        r.err("relics 배열 비어있음")
        return r

    all_ids: set[str] = set()
    unhandled_triggers: set[str] = set()

    for relic in relics:
        rid = relic.get("id", "(id없음)")

        # 필수 필드 확인
        for field in RELIC_REQUIRED_FIELDS:
            if field not in relic:
                r.err(f"유물 {rid} — 필수 필드 누락: {field}")
            else:
                r.ok()

        # rarity 범위 검증
        rarity = relic.get("rarity")
        if rarity is not None and rarity not in VALID_RARITIES:
            r.err(f"유물 {rid} — rarity={rarity} (허용값: {VALID_RARITIES})")
        else:
            r.ok()

        # trigger → relic_manager.gd 커버리지 검증
        trigger = relic.get("trigger", "")
        if trigger not in HANDLED_TRIGGERS:
            unhandled_triggers.add(trigger)
            r.warn(
                f"유물 {rid} — trigger '{trigger}'가 "
                f"relic_manager.gd에 핸들러 없음 (미구현 가능성)"
            )
        else:
            r.ok()

        # values는 dict
        if "values" in relic and not isinstance(relic["values"], dict):
            r.err(f"유물 {rid} — values가 object 아님")
        else:
            r.ok()

        # 중복 ID
        if rid in all_ids:
            r.err(f"유물 ID 중복: {rid}")
        else:
            all_ids.add(rid)
            r.ok()

    if unhandled_triggers:
        r.warn(
            f"relic_manager.gd 미구현 트리거 목록: {sorted(unhandled_triggers)} "
            f"— 해당 유물 효과가 게임에서 발동되지 않을 수 있음"
        )

    return r


# ── 3. 적 데이터 검증 ──────────────────────────────────────────────────────
VALID_INTENTS = {
    "attack", "defend", "buff", "debuff", "unknown",
    "sleep", "special", "escape",
    # 복합 intent (공격+디버프, 버프+방어, 소환 등)
    "attack_debuff", "attack_buff", "buff_defend", "buff_debuff",
    "debuff_buff", "summon",
}


def validate_enemies(verbose: bool = False) -> ValidationResult:
    r = ValidationResult("적 데이터 검증")
    all_ids: set[str] = set()

    for path in ENEMY_FILES:
        data = load_json(path)
        if data is None:
            r.err(f"{path.name} 로드 실패")
            continue

        for category in ("regular_enemies", "elite_enemies", "bosses"):
            for enemy in data.get(category, []):
                eid = enemy.get("id", "(id없음)")

                # hp 필드 (min/max 구조 or 단일 int)
                hp = enemy.get("hp")
                if hp is None:
                    r.err(f"적 {eid} ({path.name}) — hp 필드 누락")
                elif isinstance(hp, dict):
                    if "min" not in hp or "max" not in hp:
                        r.err(f"적 {eid} — hp에 min/max 없음")
                    elif hp["min"] <= 0:
                        r.err(f"적 {eid} — hp.min={hp['min']} (0 이하 불가)")
                    elif hp["max"] < hp["min"]:
                        r.err(f"적 {eid} — hp.max < hp.min")
                    else:
                        r.ok()
                elif isinstance(hp, int):
                    if hp <= 0:
                        r.err(f"적 {eid} — hp={hp} (0 이하 불가)")
                    else:
                        r.ok()

                # moves 필드
                moves = enemy.get("moves", [])
                if not moves:
                    r.err(f"적 {eid} ({path.name}) — moves 배열 비어있음")
                else:
                    r.ok()
                    for move in moves:
                        mid = move.get("id", "(id없음)")

                        # intent 필드
                        intent = move.get("intent")
                        if intent is None:
                            r.err(f"적 {eid} move {mid} — intent 필드 누락")
                        elif intent not in VALID_INTENTS:
                            r.warn(
                                f"적 {eid} move {mid} — "
                                f"알 수 없는 intent: {intent}"
                            )
                        else:
                            r.ok()

                        # 공격 의도가 있으면 damage 확인
                        if intent == "attack":
                            damage = move.get("damage")
                            if damage is None:
                                r.err(
                                    f"적 {eid} move {mid} — "
                                    f"intent=attack인데 damage 필드 없음"
                                )
                            elif not isinstance(damage, (int, float)) or damage < 0:
                                r.err(
                                    f"적 {eid} move {mid} — "
                                    f"damage={damage} (음수 불가)"
                                )
                            else:
                                r.ok()

                # 중복 ID
                if eid in all_ids:
                    r.err(f"적 ID 중복: {eid}")
                else:
                    all_ids.add(eid)
                    r.ok()

    return r


# ── 4. 밸런스 코너케이스 검증 ──────────────────────────────────────────────
# 스펙 기준값 (docs/balance_sheet.md 및 data_schema.md 기반)
BALANCE_SPEC = {
    "attack_1cost_base":  6,    # 1코스트 공격 기준 피해
    "defense_1cost_base": 5,    # 1코스트 방어 기준 방어도
    "energy_per_turn":    3,    # 기/턴 기본값
    "hp": {
        "dosa":    70,
        "mugwan":  80,
        "mungwan": 65,
    },
    "max_status_stack":    999, # 게임 내 최대 스택 (무한 루프 방지)
    "wildcard_beat":       0,   # 와일드카드 beat 값 (ZER-101)
}


def validate_balance_corner_cases(verbose: bool = False) -> ValidationResult:
    r = ValidationResult("밸런스 코너케이스")

    # 카드 로드
    all_cards: list[dict] = []
    for path in CARD_FILES.values():
        data = load_json(path)
        if data:
            all_cards.extend(data.get("cards", []))

    # 공격 카드 1코스트 피해 검증 (±40% 허용 범위)
    base_atk = BALANCE_SPEC["attack_1cost_base"]
    atk_tolerance = 0.40
    atk_lower = base_atk * (1 - atk_tolerance)
    atk_upper = base_atk * (1 + atk_tolerance) * 3   # 연타, 콤보 카드 고려

    # 방어 카드 1코스트 방어도 검증
    base_def = BALANCE_SPEC["defense_1cost_base"]
    def_upper = base_def * 4   # 조건부 카드 고려

    for card in all_cards:
        cid    = card.get("id", "?")
        cost   = card.get("cost", -1)
        ctype  = card.get("type", "")
        values = card.get("values", {}) or {}

        # 0코스트 카드에 과도한 직접 피해가 있으면 경고
        if cost == 0 and ctype == "attack":
            dmg = values.get("damage", 0) or values.get("damage_per_hit", 0)
            if dmg > base_atk:
                r.warn(
                    f"카드 {cid} — 0코스트 공격 피해={dmg} > 기준({base_atk}). "
                    f"밸런스 재검토 권장."
                )
            else:
                r.ok()

        # 방어도 과잉 검증 (1코스트 방어도 기준 4배 초과)
        if ctype in ("defense",) and cost == 1:
            blk = values.get("block", 0) or 0
            if blk > def_upper:
                r.warn(
                    f"카드 {cid} — 1코스트 방어도={blk} > 기준×4({def_upper}). "
                    f"조건부 효과가 없다면 과잉."
                )
            elif blk > 0:
                r.ok()

        # 와일드카드 beat=0: balance_rationale 또는 sijo_position 에 설명 있는지 확인 (ZER-101)
        beat = card.get("beat")
        if beat == BALANCE_SPEC["wildcard_beat"]:
            combined = (
                str(card.get("effect", "")) +
                str(card.get("balance_rationale", "")) +
                str(card.get("sijo_position", ""))
            )
            if "wildcard" not in combined.lower() and "와일드" not in combined:
                r.warn(
                    f"카드 {cid} — beat=0(와일드카드)이지만 "
                    f"어떤 필드에도 와일드카드 설명 없음."
                )
            else:
                r.ok()

    # 스타터 덱 ID 유효성 검증
    starter_decks = {
        "dosa":    ["M003", "M003", "M005", "D001", "D001", "D002", "D003",
                    "D007", "D007", "D007"],
        "mugwan":  ["M003", "M003", "M005", "G001", "G001", "G002", "G002",
                    "G003", "M002", "M002"],
        "mungwan": ["M003", "M003", "M005", "W001", "W001", "W004", "W004",
                    "W006", "W005", "W007"],
    }
    all_card_ids = {c["id"] for c in all_cards}
    for char, deck in starter_decks.items():
        for card_id in deck:
            if card_id not in all_card_ids:
                r.err(
                    f"스타터 덱 오류: {char} 덱의 카드 '{card_id}' 가 "
                    f"JSON 데이터에 존재하지 않음"
                )
            else:
                r.ok()

    # 적 최대 피해 vs 플레이어 HP 비율 검증 (1턴 즉사 방지)
    for path in ENEMY_FILES:
        data = load_json(path)
        if not data:
            continue
        for category in ("regular_enemies", "elite_enemies", "bosses"):
            for enemy in data.get(category, []):
                eid = enemy.get("id", "?")
                for move in enemy.get("moves", []):
                    if move.get("intent") != "attack":
                        continue
                    dmg   = move.get("damage", 0) or 0
                    times = move.get("times", 1) or 1
                    total = dmg * times
                    # 문관 HP(최저) 65. 한 번의 이동으로 즉사 불가 원칙
                    min_hp = min(BALANCE_SPEC["hp"].values())  # 65
                    if total >= min_hp:
                        r.warn(
                            f"적 {eid} move '{move.get('id','?')}' — "
                            f"총 피해 {total} >= 최소 플레이어 HP {min_hp}. "
                            f"단일 이동 즉사 가능. 설계 의도 확인 필요."
                        )
                    else:
                        r.ok()

    return r


# ── 5. balance_sheet.md 와 JSON 정합성 비교 ───────────────────────────────
def _extract_ids_from_md(text: str) -> set[str]:
    """balance_sheet.md에서 카드/유물 ID 패턴 추출 (예: M001, D012, R005)"""
    return set(re.findall(r'\b([MDGWR][A-Z]*\d{3}|CURSE_\d{3})\b', text))


def validate_balance_sheet(verbose: bool = False) -> ValidationResult:
    r = ValidationResult("balance_sheet.md ↔ JSON 정합성")

    if not BALANCE_MD.exists():
        r.err(f"{BALANCE_MD.name} 파일 없음")
        return r

    with open(BALANCE_MD, encoding="utf-8") as f:
        md_text = f.read()

    # JSON에서 실제 존재하는 ID 수집
    json_card_ids:  set[str] = set()
    for path in CARD_FILES.values():
        data = load_json(path)
        if data:
            for c in data.get("cards", []):
                if c.get("id"):
                    json_card_ids.add(c["id"])

    json_relic_ids: set[str] = set()
    data = load_json(RELIC_FILE)
    if data:
        for rel in data.get("relics", []):
            if rel.get("id"):
                json_relic_ids.add(rel["id"])

    all_json_ids = json_card_ids | json_relic_ids

    # balance_sheet.md에 언급된 ID 목록
    md_ids = _extract_ids_from_md(md_text)

    # balance_sheet에는 있지만 JSON에 없는 ID
    md_only = md_ids - all_json_ids
    if md_only:
        for mid in sorted(md_only):
            r.warn(
                f"balance_sheet.md에 '{mid}' 언급 — JSON에는 없음 "
                f"(삭제되었거나 ID 변경 가능성)"
            )
    else:
        r.ok()

    # JSON에는 있지만 balance_sheet에 언급 안 된 카드/유물
    json_only = (json_card_ids - md_ids)
    if json_only:
        for jid in sorted(json_only):
            r.warn(
                f"JSON에 '{jid}' 존재 — balance_sheet.md에 미기재 "
                f"(신규 추가 후 문서 업데이트 필요)"
            )
    else:
        r.ok()

    # 전체 카드/유물 수 보고
    r.ok(len(all_json_ids))

    return r


# ── 메인 ──────────────────────────────────────────────────────────────────
SUITES = {
    "cards":   validate_cards,
    "relics":  validate_relics,
    "enemies": validate_enemies,
    "balance": validate_balance_corner_cases,
    "sheet":   validate_balance_sheet,
}


def main():
    parser = argparse.ArgumentParser(
        description="시조전 밸런스 자동 검증 (ZER-129)"
    )
    parser.add_argument(
        "--check",
        choices=list(SUITES.keys()) + ["all"],
        default="all",
        help="실행할 검증 항목 (기본: all)",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="경고 포함 상세 출력",
    )
    args = parser.parse_args()

    suites_to_run = list(SUITES.items()) if args.check == "all" \
        else [(args.check, SUITES[args.check])]

    total_pass = 0
    total_fail = 0
    total_warn = 0
    results = []

    for name, fn in suites_to_run:
        result = fn(verbose=args.verbose)
        results.append(result)
        total_pass += result.passed
        total_fail += result.failed
        total_warn += len(result.warnings)
        print(result.summary(verbose=args.verbose))

    print(f"\n{'='*60}")
    print(f"전체 결과: 통과 {total_pass}  실패 {total_fail}  경고 {total_warn}")
    if total_fail == 0:
        print("[OK] 모든 검증 통과")
    else:
        print(f"[FAIL] {total_fail}건 실패 -- 수정 필요")

    sys.exit(0 if total_fail == 0 else 1)


if __name__ == "__main__":
    main()
