#!/usr/bin/env python3
import json

def escape_dart_string(s):
    if s is None:
        return "''"
    return "'" + str(s).replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n').replace('\r', '') + "'"

def main():
    with open('assets/data/unified_exercises_catalog.json', 'r') as f:
        catalog = json.load(f)

    with open('assets/data/exercise_mappings.json', 'r') as f:
        mappings = json.load(f)

    out_path = 'lib/features/workouts/data/datasources/unified_exercise_catalog_data.dart'

    lines = [
        "// Generated file - DO NOT MODIFY MANUALLY",
        "// Unified Fit Host Exercise Catalog containing 1,324 canonical exercise records",
        "// and legacy ID mappings.",
        "",
        "import '../../domain/models/workout_models.dart';",
        "",
        "const Map<String, String> kLegacyExerciseMappings = {",
    ]

    for old_id, m in mappings.items():
        lines.append(f"  '{old_id}': '{m['canonical_exercise_id']}',")

    lines.append("};")
    lines.append("")
    lines.append("final List<ExerciseEntity> kUnifiedExerciseCatalog = [")

    for ex in catalog:
        lines.append("  ExerciseEntity(")
        lines.append(f"    id: {escape_dart_string(ex['id'])},")
        lines.append(f"    canonicalId: {escape_dart_string(ex['canonical_id'])},")
        lines.append(f"    source: {escape_dart_string(ex['source'])},")
        lines.append(f"    originalSourceId: {escape_dart_string(ex['original_source_id'])},")
        lines.append(f"    name: {escape_dart_string(ex['name'])},")
        aliases_str = ", ".join(escape_dart_string(a) for a in ex['aliases'])
        lines.append(f"    aliases: const [{aliases_str}],")
        lines.append(f"    category: {escape_dart_string(ex['category'])},")
        lines.append(f"    bodyPart: {escape_dart_string(ex['body_part'])},")
        lines.append(f"    targetMuscle: {escape_dart_string(ex['target_muscle'])},")
        lines.append(f"    muscleGroup: {escape_dart_string(ex['muscle_group'])},")
        sec_muscles_str = ", ".join(escape_dart_string(m) for m in ex['secondary_muscles'])
        lines.append(f"    secondaryMuscles: const [{sec_muscles_str}],")
        lines.append(f"    instructions: {escape_dart_string(ex['instructions'])},")
        steps_str = ", ".join(escape_dart_string(s) for s in ex['instruction_steps'])
        lines.append(f"    instructionSteps: const [{steps_str}],")
        lines.append(f"    equipment: {escape_dart_string(ex['equipment'])},")
        lines.append(f"    exerciseType: {escape_dart_string(ex['exercise_type'])},")
        lines.append(f"    movementType: {escape_dart_string(ex['movement_type'])},")
        lines.append(f"    difficultyLevel: {escape_dart_string(ex['difficulty_level'])},")
        lines.append(f"    audienceSuitability: {escape_dart_string(ex['audience_suitability'])},")
        lines.append(f"    isCustom: false,")
        lines.append(f"    createdAt: DateTime.utc(2026, 1, 1),")
        lines.append(f"    mediaThumbnailUrl: {escape_dart_string(ex['media_thumbnail_url'])},")
        lines.append(f"    mediaAnimationUrl: {escape_dart_string(ex['media_animation_url'])},")
        lines.append(f"    mediaLicense: {escape_dart_string(ex['media_license'])},")
        lines.append(f"    mediaAttribution: {escape_dart_string(ex['media_attribution'])},")
        lines.append(f"    contentLicense: {escape_dart_string(ex['content_license'])},")
        lines.append(f"    contentAttribution: {escape_dart_string(ex['content_attribution'])},")
        langs_str = ", ".join(escape_dart_string(l) for l in ex['languages_available'])
        lines.append(f"    languagesAvailable: const [{langs_str}],")
        lines.append(f"    safetyNotes: {escape_dart_string(ex['safety_notes'])},")
        lines.append(f"    publicationStatus: 'published',")
        lines.append(f"    recommendedFor: const ['all'],")
        lines.append("  ),")

    lines.append("];")
    lines.append("")

    with open(out_path, 'w') as f:
        f.write('\n'.join(lines))

    print(f"Generated Dart catalog at {out_path} ({len(lines)} lines)")

if __name__ == '__main__':
    main()
