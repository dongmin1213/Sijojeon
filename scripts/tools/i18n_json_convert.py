#!/usr/bin/env python3
"""
Phase 3: JSON 데이터 파일 다국어 구조 확장 스크립트.
기존 flat string 필드를 { "ko": "...", "en": "" } 딕셔너리 구조로 변환.
이미 딕셔너리인 name 필드에는 "en": "" 키만 추가.
"""

import json
import os
import sys

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "data")


def to_i18n(value):
    """flat string -> { "ko": value, "en": "" }. 이미 dict면 그대로."""
    if isinstance(value, str):
        return {"ko": value, "en": ""}
    return value


def add_en_to_name(name_dict):
    """name dict에 en 키가 없으면 추가."""
    if isinstance(name_dict, dict) and "en" not in name_dict:
        name_dict["en"] = ""
    return name_dict


def convert_card(card):
    """카드 엔트리 다국어 변환."""
    if "name" in card and isinstance(card["name"], dict):
        add_en_to_name(card["name"])
    for field in ["effect", "effect_upgraded", "flavor_text"]:
        if field in card and isinstance(card[field], str):
            card[field] = to_i18n(card[field])
    return card


def convert_enemy(enemy):
    """적 엔트리 다국어 변환."""
    if "name" in enemy and isinstance(enemy["name"], dict):
        add_en_to_name(enemy["name"])
    if "description" in enemy and isinstance(enemy["description"], str):
        enemy["description"] = to_i18n(enemy["description"])
    # moves 내부
    if "moves" in enemy and isinstance(enemy["moves"], list):
        for move in enemy["moves"]:
            if isinstance(move, dict):
                for field in ["name", "description"]:
                    if field in move and isinstance(move[field], str):
                        move[field] = to_i18n(move[field])
    # phases 내부 (보스)
    if "phases" in enemy and isinstance(enemy["phases"], list):
        for phase in enemy["phases"]:
            if isinstance(phase, dict):
                if "name" in phase and isinstance(phase["name"], str):
                    phase["name"] = to_i18n(phase["name"])
                if "moves" in phase and isinstance(phase["moves"], list):
                    for move in phase["moves"]:
                        if isinstance(move, dict):
                            for field in ["name", "description"]:
                                if field in move and isinstance(move[field], str):
                                    move[field] = to_i18n(move[field])
    return enemy


def convert_event(event):
    """이벤트 엔트리 다국어 변환."""
    # title: { "ko": "...", "description": "..." } -> title에 en 추가, description을 분리
    if "title" in event and isinstance(event["title"], dict):
        add_en_to_name(event["title"])
        # description 필드가 title 안에 있으면 다국어로 변환
        if "description" in event["title"] and isinstance(event["title"]["description"], str):
            event["title"]["description"] = to_i18n(event["title"]["description"])

    if "flavor_text" in event and isinstance(event["flavor_text"], str):
        event["flavor_text"] = to_i18n(event["flavor_text"])

    # choices
    if "choices" in event and isinstance(event["choices"], list):
        for choice in event["choices"]:
            if isinstance(choice, dict):
                for field in ["text", "result_text", "result_text_full",
                              "result_text_win", "result_text_lose"]:
                    if field in choice and isinstance(choice[field], str):
                        choice[field] = to_i18n(choice[field])
                # 중첩 outcomes
                if "outcomes" in choice and isinstance(choice["outcomes"], list):
                    for outcome in choice["outcomes"]:
                        if isinstance(outcome, dict):
                            if "text" in outcome and isinstance(outcome["text"], str):
                                outcome["text"] = to_i18n(outcome["text"])

    # build_variant_events의 특수 구조: stages
    if "stages" in event and isinstance(event["stages"], list):
        for stage in event["stages"]:
            convert_event(stage)  # 재귀

    return event


def convert_relic(relic):
    """유물 엔트리 다국어 변환."""
    if "name" in relic and isinstance(relic["name"], dict):
        add_en_to_name(relic["name"])
    for field in ["effect", "effect_description", "flavor_text"]:
        if field in relic and isinstance(relic[field], str):
            relic[field] = to_i18n(relic[field])
    return relic


def convert_keyword(kw):
    """키워드 엔트리 다국어 변환."""
    for field in ["name", "description"]:
        if field in kw and isinstance(kw[field], str):
            kw[field] = to_i18n(kw[field])
    return kw


def convert_achievement(ach):
    """업적 엔트리 다국어 변환."""
    for field in ["name", "description"]:
        if field in ach and isinstance(ach[field], str):
            ach[field] = to_i18n(ach[field])
    return ach


def convert_narrative_stage(stage):
    """내러티브 스테이지 다국어 변환."""
    for field in ["title", "text", "title_ally", "text_ally",
                   "title_no_ally", "text_no_ally"]:
        if field in stage and isinstance(stage[field], str):
            stage[field] = to_i18n(stage[field])
    return stage


def convert_ascension_level(level):
    """어센션 레벨 다국어 변환."""
    if "name_ko" in level and isinstance(level["name_ko"], str):
        # name_ko -> name: { "ko": value, "en": "" }
        level["name"] = {"ko": level.pop("name_ko"), "en": ""}
    if "description" in level and isinstance(level["description"], str):
        level["description"] = to_i18n(level["description"])
    # modifiers 내부
    if "modifiers" in level and isinstance(level["modifiers"], list):
        for mod in level["modifiers"]:
            if isinstance(mod, dict):
                if "description_ko" in mod and isinstance(mod["description_ko"], str):
                    mod["description"] = {"ko": mod.pop("description_ko"), "en": ""}
    return level


def convert_skill_entry(entry):
    """스킬 엔트리 다국어 변환."""
    # passive_name
    if "passive_name" in entry and isinstance(entry["passive_name"], dict):
        add_en_to_name(entry["passive_name"])
        if "description" in entry["passive_name"] and isinstance(entry["passive_name"]["description"], str):
            entry["passive_name"]["description"] = to_i18n(entry["passive_name"]["description"])
    # active_skill
    if "active_skill" in entry and isinstance(entry["active_skill"], dict):
        skill = entry["active_skill"]
        if "name" in skill and isinstance(skill["name"], dict):
            add_en_to_name(skill["name"])
            if "description" in skill["name"] and isinstance(skill["name"]["description"], str):
                skill["name"]["description"] = to_i18n(skill["name"]["description"])
    # starting_relic
    if "starting_relic" in entry and isinstance(entry["starting_relic"], dict):
        sr = entry["starting_relic"]
        if "name" in sr and isinstance(sr["name"], dict):
            add_en_to_name(sr["name"])
        for field in ["effect", "flavor"]:
            if field in sr and isinstance(sr[field], str):
                sr[field] = to_i18n(sr[field])
    return entry


def process_card_file(filepath):
    """카드 JSON 파일 처리."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    if "cards" in data and isinstance(data["cards"], list):
        for card in data["cards"]:
            convert_card(card)
    return data


def process_enemy_file(filepath):
    """적 JSON 파일 처리."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    if isinstance(data, dict):
        # act_name 다국어
        if "act_name" in data and isinstance(data["act_name"], dict):
            add_en_to_name(data["act_name"])
            if "description" in data["act_name"] and isinstance(data["act_name"]["description"], str):
                data["act_name"]["description"] = to_i18n(data["act_name"]["description"])

        # 보스 파일: 루트에 id가 있는 경우
        if "id" in data:
            convert_enemy(data)
        else:
            for key in ["regular_enemies", "elite_enemies", "bosses"]:
                if key in data and isinstance(data[key], list):
                    for enemy in data[key]:
                        convert_enemy(enemy)
    elif isinstance(data, list):
        for enemy in data:
            convert_enemy(enemy)
    return data


def process_event_file(filepath):
    """이벤트 JSON 파일 처리."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    if "act_name" in data and isinstance(data["act_name"], dict):
        add_en_to_name(data["act_name"])
        if "description" in data["act_name"] and isinstance(data["act_name"]["description"], str):
            data["act_name"]["description"] = to_i18n(data["act_name"]["description"])

    if "events" in data and isinstance(data["events"], list):
        for event in data["events"]:
            convert_event(event)
    return data


def process_keywords(filepath):
    """키워드 JSON 처리."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    if "keywords" in data and isinstance(data["keywords"], list):
        for kw in data["keywords"]:
            convert_keyword(kw)
    return data


def process_relics(filepath):
    """유물 JSON 처리."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    # rarity_table 내 label_ko → label: { ko, en }
    if "rarity_table" in data:
        for key, val in data["rarity_table"].items():
            if isinstance(val, dict) and "label_ko" in val:
                val["label"] = {"ko": val.pop("label_ko"), "en": ""}
    if "relics" in data and isinstance(data["relics"], list):
        for relic in data["relics"]:
            convert_relic(relic)
    return data


def process_achievements(filepath):
    """업적 JSON 처리."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    if "achievements" in data and isinstance(data["achievements"], list):
        for ach in data["achievements"]:
            convert_achievement(ach)
    return data


def process_narrative(filepath):
    """내러티브 JSON 처리."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    if "stages" in data and isinstance(data["stages"], list):
        for stage in data["stages"]:
            convert_narrative_stage(stage)
    return data


def process_ascension(filepath):
    """어센션 JSON 처리."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    # system_name
    if "system_name" in data and isinstance(data["system_name"], dict):
        add_en_to_name(data["system_name"])
        if "description" in data["system_name"] and isinstance(data["system_name"]["description"], str):
            data["system_name"]["description"] = to_i18n(data["system_name"]["description"])

    # curse_card
    if "curse_card" in data and isinstance(data["curse_card"], dict):
        convert_card(data["curse_card"])

    # levels
    if "levels" in data and isinstance(data["levels"], list):
        for level in data["levels"]:
            convert_ascension_level(level)

    return data


def process_skills(filepath):
    """스킬 JSON 처리."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    if "character_special_skills" in data and isinstance(data["character_special_skills"], list):
        for entry in data["character_special_skills"]:
            convert_skill_entry(entry)
    return data


def write_json(filepath, data):
    """JSON 파일 저장 (UTF-8, indent=2)."""
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"  [OK] {os.path.relpath(filepath, DATA_DIR)}")


def main():
    data_dir = os.path.abspath(DATA_DIR)
    print(f"데이터 디렉토리: {data_dir}")
    print()

    # 1. 카드 파일
    print("=== 카드 ===")
    for fname in ["common.json", "dosa.json", "mugwan.json", "mungwan.json"]:
        fp = os.path.join(data_dir, "cards", fname)
        if os.path.exists(fp):
            write_json(fp, process_card_file(fp))

    # 2. 적 파일
    print("\n=== 적 ===")
    enemies_dir = os.path.join(data_dir, "enemies")
    for fname in os.listdir(enemies_dir):
        if fname.endswith(".json"):
            fp = os.path.join(enemies_dir, fname)
            write_json(fp, process_enemy_file(fp))

    # 3. 이벤트 파일
    print("\n=== 이벤트 ===")
    events_dir = os.path.join(data_dir, "events")
    for fname in os.listdir(events_dir):
        if fname.endswith(".json"):
            fp = os.path.join(events_dir, fname)
            write_json(fp, process_event_file(fp))

    # 4. 키워드
    print("\n=== 키워드 ===")
    fp = os.path.join(data_dir, "keywords.json")
    if os.path.exists(fp):
        write_json(fp, process_keywords(fp))

    # 5. 유물
    print("\n=== 유물 ===")
    fp = os.path.join(data_dir, "relics", "relics.json")
    if os.path.exists(fp):
        write_json(fp, process_relics(fp))

    # 6. 업적
    print("\n=== 업적 ===")
    fp = os.path.join(data_dir, "achievements", "achievements.json")
    if os.path.exists(fp):
        write_json(fp, process_achievements(fp))

    # 7. 내러티브
    print("\n=== 내러티브 ===")
    fp = os.path.join(data_dir, "narrative", "amhaengosa_journey.json")
    if os.path.exists(fp):
        write_json(fp, process_narrative(fp))

    # 8. 어센션
    print("\n=== 어센션 ===")
    fp = os.path.join(data_dir, "unlock", "ascension.json")
    if os.path.exists(fp):
        write_json(fp, process_ascension(fp))

    # 9. 스킬
    print("\n=== 스킬 ===")
    fp = os.path.join(data_dir, "skills", "special_skills.json")
    if os.path.exists(fp):
        write_json(fp, process_skills(fp))

    print("\n완료! 모든 데이터 파일이 다국어 구조로 변환되었습니다.")


if __name__ == "__main__":
    main()
