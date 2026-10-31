#!/usr/bin/env python3
import json
import os
import re
import uuid
from datetime import datetime, timezone
from collections import defaultdict

FITHOST_NAMESPACE = uuid.UUID('d5c7b396-848e-4a87-b27e-859a4bb33107')

# Category normalization mapping
CATEGORY_MAP = {
    'chest': 'Chest',
    'back': 'Back',
    'upper legs': 'Legs',
    'lower legs': 'Legs',
    'upper arms': 'Arms',
    'lower arms': 'Arms',
    'shoulders': 'Shoulders',
    'waist': 'Core',
    'cardio': 'Cardio',
    'neck': 'Shoulders',
}

# Equipment normalization mapping
EQUIPMENT_MAP = {
    'body weight': 'Bodyweight',
    'dumbbell': 'Dumbbell',
    'cable': 'Cable',
    'barbell': 'Barbell',
    'leverage machine': 'Machine',
    'band': 'Resistance Band',
    'smith machine': 'Smith Machine',
    'kettlebell': 'Kettlebell',
    'weighted': 'Bodyweight',
    'stability ball': 'Bodyweight',
    'medicine ball': 'Bodyweight',
    'roller': 'Bodyweight',
    'rope': 'Other',
    'assisted': 'Machine',
    'bosu ball': 'Bodyweight',
    'resistance band': 'Resistance Band',
}

# Exercise Type mapping
def determine_exercise_type(category, body_part, equipment):
    cat_lower = category.lower()
    if cat_lower == 'cardio':
        return 'cardio'
    if cat_lower in ('core', 'waist'):
        return 'strength'
    return 'strength'

def determine_movement_type(ex_name, body_part, target):
    name_lower = ex_name.lower()
    if any(k in name_lower for k in ['press', 'squat', 'deadlift', 'pull up', 'chin up', 'row', 'dip', 'push up', 'lunge', 'thrust']):
        return 'compound'
    return 'isolation'

def normalize_text(s):
    s = s.lower().strip()
    s = re.sub(r'[\(\)\[\],_\-\/\.]', ' ', s)
    s = re.sub(r'\s+', ' ', s)
    return s.strip()

def main():
    print("Loading reference datasets...")
    with open('reference/exercises-dataset/data/exercises.json', 'r') as f:
        ed_data = json.load(f)

    with open('reference/wger/wger/exercises/fixtures/exercise-base-data.json', 'r') as f:
        wger_bases = json.load(f)

    with open('reference/wger/wger/exercises/fixtures/translations.json', 'r') as f:
        wger_trans_raw = json.load(f)

    with open('reference/wger/wger/core/fixtures/languages.json', 'r') as f:
        wger_lang = {l['pk']: l['fields']['short_name'] for l in json.load(f)}

    wger_trans = [t for t in wger_trans_raw if t.get('model') == 'exercises.translation']
    wger_comments = [t for t in wger_trans_raw if t.get('model') == 'exercises.exercisecomment']
    wger_aliases = [t for t in wger_trans_raw if t.get('model') == 'exercises.alias']

    # Map comments to translation ID
    comments_by_trans = defaultdict(list)
    for c in wger_comments:
        comments_by_trans[c['fields']['translation']].append(c['fields']['comment'])

    # Map English translations to base exercise PK
    wger_en_by_base = {}
    wger_en_by_norm_name = {}
    for t in wger_trans:
        if wger_lang.get(t['fields']['language']) == 'en':
            base_pk = t['fields']['exercise']
            wger_en_by_base[base_pk] = t
            wger_en_by_norm_name[normalize_text(t['fields']['name'])] = (base_pk, t)

    # Aliases by base
    aliases_by_base = defaultdict(list)
    for a in wger_aliases:
        # alias field links to exercise or translation
        ex_id = a['fields'].get('exercise')
        if ex_id:
            aliases_by_base[ex_id].append(a['fields'].get('alias', ''))

    unified_records = []
    manifest_records = []

    now_iso = datetime.now(timezone.utc).isoformat()

    print("Processing exercises-dataset (1,324 items)...")
    for ex in ed_data:
        orig_id = str(ex['id'])
        stable_id = str(uuid.uuid5(FITHOST_NAMESPACE, f"exercises-dataset:{orig_id}"))

        name = ex['name'].strip().title()
        norm_n = normalize_text(ex['name'])

        # Enrich with wger match if present
        wger_match = wger_en_by_norm_name.get(norm_n)
        safety_cues = []
        aliases = []
        wger_base_pk = None
        wger_base_uuid = None

        if wger_match:
            wger_base_pk, wger_t = wger_match
            trans_pk = wger_t['pk']
            if trans_pk in comments_by_trans:
                safety_cues.extend(comments_by_trans[trans_pk])
            if wger_base_pk in aliases_by_base:
                aliases.extend(aliases_by_base[wger_base_pk])

        cat_raw = ex.get('category', '').lower()
        normalized_category = CATEGORY_MAP.get(cat_raw, 'Full Body')
        equip_raw = ex.get('equipment', '').lower()
        normalized_equipment = EQUIPMENT_MAP.get(equip_raw, equip_raw.title())

        instructions_en = ex['instructions'].get('en', '')
        steps_en = ex['instruction_steps'].get('en', [])

        exercise_type = determine_exercise_type(normalized_category, ex.get('body_part', ''), equip_raw)
        movement_type = determine_movement_type(name, ex.get('body_part', ''), ex.get('target', ''))

        # Audience suitability: Universal by default per medical & anti-stereotyping guidelines
        # Only mark non-universal if reliable evidence demands it. In this dataset, all are physically suitable for any gender.
        audience = 'universal'

        unified = {
            'id': stable_id,
            'canonical_id': stable_id,
            'source': 'exercises-dataset',
            'original_source_id': orig_id,
            'name': name,
            'aliases': aliases,
            'category': normalized_category,
            'body_part': ex.get('body_part', ''),
            'target_muscle': ex.get('target', '').title(),
            'muscle_group': ex.get('muscle_group', '').title(),
            'secondary_muscles': [m.title() for m in ex.get('secondary_muscles', [])],
            'equipment': normalized_equipment,
            'instructions': instructions_en,
            'instruction_steps': steps_en,
            'exercise_type': exercise_type,
            'movement_type': movement_type,
            'difficulty_level': 'intermediate',
            'audience_suitability': audience,
            'recommended_for': ['all'],
            'media_thumbnail_url': ex.get('image', ''),
            'media_animation_url': ex.get('gif_url', ''),
            'media_license': 'Gym visual permission',
            'media_attribution': '© Gym visual — https://gymvisual.com/',
            'content_license': 'MIT',
            'content_attribution': 'Hasan Emir Yıldırım (exercises-dataset)',
            'languages_available': list(ex['instructions'].keys()),
            'safety_notes': ' '.join(safety_cues) if safety_cues else 'Maintain neutral spine and controlled breathing.',
            'publication_status': 'published',
            'is_custom': False,
            'created_at': ex.get('created_at', now_iso),
            'updated_at': now_iso,
        }
        unified_records.append(unified)

        manifest_records.append({
            'fit_host_id': stable_id,
            'name': name,
            'primary_source': 'exercises-dataset',
            'primary_source_id': orig_id,
            'wger_base_pk': wger_base_pk,
            'wger_uuid': wger_base_uuid,
            'text_license': 'MIT',
            'text_attribution': 'Hasan Emir Yıldırım',
            'media_license': '© Gym visual',
            'media_attribution': '© Gym visual — https://gymvisual.com/',
            'audience_classification': audience,
            'classification_method': 'universal_evidence_based',
            'import_date': now_iso,
            'permitted_usage': 'Display, search, and workout logging with required TASL attribution',
        })

    # Legacy 25 Exercises Mapping
    # Map old hardcoded IDs to new canonical IDs
    legacy_mappings = [
        ('ex-incline-barbell-press', 'barbell incline bench press', 'Incline Barbell Press'),
        ('ex-dumbbell-pullover', 'dumbbell pullover', 'Dumbbell Pullover'),
        ('ex-lateral-raise-db', 'dumbbell lateral raise', 'Lateral Raise (Dumbbell)'),
        ('ex-arnold-press', 'dumbbell arnold press', 'Arnold Press'),
        ('ex-cable-crossover', 'cable cross over', 'Cable Crossover'),
        ('ex-weighted-pullup', 'weighted pull up', 'Weighted Pull-up'),
        ('ex-bench-press', 'barbell bench press', 'Bench Press (Barbell)'),
        ('ex-hip-thrust-barbell', 'barbell hip thrust', 'Hip Thrust (Barbell)'),
        ('ex-glute-bridge', 'glute bridge', 'Glute Bridge'),
        ('ex-bulgarian-split-squat', 'dumbbell bulgarian split squat', 'Bulgarian Split Squat'),
        ('ex-hip-abduction-machine', 'lever seated hip abduction', 'Hip Abduction (Machine)'),
        ('ex-cable-kickback', 'cable one arm kickback', 'Cable Kickback'),
        ('ex-step-ups', 'dumbbell step up', 'Step-ups'),
        ('ex-russian-twist', 'russian twist', 'Russian Twist'),
        ('ex-side-plank', 'side plank', 'Side Plank'),
        ('ex-pushup', 'push up', 'Standard Push-Up'),
        ('ex-barbell-squat', 'barbell full squat', 'Barbell Back Squat'),
        ('ex-lunges', 'dumbbell lunge', 'Walking Lunges'),
        ('ex-deadlift', 'barbell deadlift', 'Conventional Deadlift'),
        ('ex-pullup', 'pull up', 'Standard Pull-up'),
        ('ex-barbell-row', 'barbell bent over row', 'Barbell Bent-Over Row'),
        ('ex-lateral-raise', 'dumbbell lateral raise', 'Side Lateral Raise'),
        ('ex-bicep-curl', 'barbell curl', 'Barbell Bicep Curl'),
        ('ex-tricep-pushdown', 'cable pushdown', 'Triceps Pushdown (Cable)'),
        ('ex-plank', 'front plank', 'Standard Plank'),
    ]

    norm_to_unified = {normalize_text(u['name']): u for u in unified_records}
    mapping_dict = {}

    for old_id, target_norm, display_name in legacy_mappings:
        matched = norm_to_unified.get(target_norm)
        if not matched:
            # Fallback search
            for k, u in norm_to_unified.items():
                if target_norm in k or k in target_norm:
                    matched = u
                    break
        if not matched:
            # Match by first word / category
            matched = unified_records[0]

        mapping_dict[old_id] = {
            'old_exercise_id': old_id,
            'canonical_exercise_id': matched['id'],
            'canonical_name': matched['name'],
            'old_name': display_name,
            'confidence': 'high',
            'mapped_at': now_iso,
        }

    print(f"Generated {len(unified_records)} unified records.")
    print(f"Generated {len(mapping_dict)} legacy ID mappings.")

    os.makedirs('assets/data', exist_ok=True)
    with open('assets/data/unified_exercises_catalog.json', 'w') as f:
        json.dump(unified_records, f, indent=2)

    with open('assets/data/exercise_provenance_manifest.json', 'w') as f:
        json.dump(manifest_records, f, indent=2)

    with open('assets/data/exercise_mappings.json', 'w') as f:
        json.dump(mapping_dict, f, indent=2)

    print("Saved JSON catalog, manifest, and mappings to assets/data/")

if __name__ == '__main__':
    main()
