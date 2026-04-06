#!/usr/bin/env python3
import json
import os
import sys

# UTF-8 인코딩으로 설정
sys.stdout.reconfigure(encoding='utf-8')

base_path = "data"

json_files = [
    "achievements/achievements.json",
    "cards/common.json",
    "cards/dosa.json",
    "cards/mugwan.json",
    "cards/mungwan.json",
    "characters/unlock_conditions.json",
    "enemies/act1.json",
    "enemies/act1_boss.json",
    "enemies/act1_boss_alt.json",
    "enemies/act1_boss_mid.json",
    "enemies/act1_boss_tamhak.json",
    "enemies/act2.json",
    "enemies/act2_boss.json",
    "enemies/act2_boss_alt.json",
    "enemies/act2_boss_mid.json",
    "enemies/act2_boss_mid_gungan.json",
    "enemies/act2_boss_tamgwan.json",
    "enemies/act2_minions.json",
    "enemies/act3.json",
    "enemies/act3_boss.json",
    "enemies/act3_boss_mid.json",
    "enemies/special_elites.json",
    "events/act1_events.json",
    "events/act2_events.json",
    "events/act3_events.json",
    "events/special_events.json",
    "keywords.json",
    "narrative/amhaengosa_journey.json",
    "relics/relics.json",
    "shop/economy.json",
    "skills/special_skills.json",
    "unlock/ascension.json",
    "unlock/unlock_conditions.json",
]

parsing_errors = []
all_cards = {}
all_enemies = {}
cross_ref_errors = []

print("=" * 80)
print("JSON 파일 무결성 검증 시작")
print("=" * 80)

print("\n[1단계] JSON 파싱 유효성 검사\n")

for json_file in json_files:
    file_path = os.path.join(base_path, json_file)
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"[OK] {json_file}")
        
        if isinstance(data, dict) and 'cards' in data:
            for card in data.get('cards', []):
                if 'id' in card:
                    all_cards[card['id']] = {
                        'name': card.get('name', {}).get('ko', 'N/A') if isinstance(card.get('name'), dict) else card.get('name'),
                        'file': json_file,
                        'upgrade_id': card.get('upgrade_id'),
                        'data': card
                    }
        
        if isinstance(data, dict):
            if 'enemies' in data:
                for enemy in data.get('enemies', []):
                    if 'id' in enemy:
                        all_enemies[enemy['id']] = {
                            'name': enemy.get('name', 'N/A'),
                            'file': json_file,
                            'data': enemy
                        }
    except json.JSONDecodeError as e:
        print(f"[ERROR] {json_file} - JSON 파싱 에러: {str(e)}")
        parsing_errors.append((json_file, str(e)))
    except Exception as e:
        print(f"[ERROR] {json_file} - 예상치 못한 에러: {str(e)}")
        parsing_errors.append((json_file, str(e)))

print(f"\n검사 완료: {len(json_files) - len(parsing_errors)}/{len(json_files)} 파일 유효")

print("\n[2단계] 카드 데이터 검증\n")

for card_id, card_info in all_cards.items():
    card = card_info['data']
    
    if not card.get('id'):
        cross_ref_errors.append(f"카드 {card_id} ({card_info['file']}): 'id' 필드 누락")
    if not card.get('name'):
        cross_ref_errors.append(f"카드 {card_id} ({card_info['file']}): 'name' 필드 누락")
    if 'cost' not in card:
        cross_ref_errors.append(f"카드 {card_id} ({card_info['file']}): 'cost' 필드 누락")
    if not card.get('type'):
        cross_ref_errors.append(f"카드 {card_id} ({card_info['file']}): 'type' 필드 누락")
    
    if card.get('upgrade_id'):
        upgrade_id = card['upgrade_id']
        if upgrade_id not in all_cards:
            cross_ref_errors.append(f"카드 {card_id} ({card_info['file']}): upgrade_id '{upgrade_id}'가 존재하지 않음")
    
    if isinstance(card.get('subtypes'), list) and len(card['subtypes']) == 0:
        cross_ref_errors.append(f"카드 {card_id} ({card_info['file']}): 'subtypes'가 빈 배열")
    
    for key in ['effect', 'effect_upgraded', 'flavor_text']:
        if key in card and card[key] is None:
            cross_ref_errors.append(f"카드 {card_id} ({card_info['file']}): '{key}'가 null")
    
    if 'values' in card and isinstance(card['values'], dict):
        for val_key, val in card['values'].items():
            if isinstance(val, (int, float)) and val < 0:
                cross_ref_errors.append(f"카드 {card_id} ({card_info['file']}): values.{val_key}가 음수 ({val})")

print(f"총 {len(all_cards)}개 카드 검증 완료")

print("\n[3단계] 적 데이터 검증\n")

for enemy_id, enemy_info in all_enemies.items():
    enemy = enemy_info['data']
    
    if not enemy.get('id'):
        cross_ref_errors.append(f"적 {enemy_id} ({enemy_info['file']}): 'id' 필드 누락")
    if not enemy.get('name'):
        cross_ref_errors.append(f"적 {enemy_id} ({enemy_info['file']}): 'name' 필드 누락")

print(f"총 {len(all_enemies)}개 적 검증 완료")

print("\n" + "=" * 80)
print("검증 결과 요약")
print("=" * 80)

print(f"\n파싱 에러: {len(parsing_errors)}")
if parsing_errors:
    for file, error in parsing_errors:
        print(f"  - {file}: {error}")

print(f"\n데이터 무결성 오류: {len(cross_ref_errors)}")
if cross_ref_errors:
    for error in sorted(cross_ref_errors)[:50]:
        print(f"  - {error}")
    if len(cross_ref_errors) > 50:
        print(f"  ... 그 외 {len(cross_ref_errors) - 50}개")
else:
    print("  - 데이터 무결성 오류 없음")

print(f"\n카드 총 개수: {len(all_cards)}")
print(f"적 총 개수: {len(all_enemies)}")
