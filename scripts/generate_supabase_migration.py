#!/usr/bin/env python3
import json
import os

def sql_escape(s):
    if s is None:
        return 'NULL'
    return "'" + str(s).replace("'", "''") + "'"

def sql_array(arr):
    if not arr:
        return "'{}'::text[]"
    items = []
    for item in arr:
        escaped = str(item).replace('\\', '\\\\').replace('"', '\\"')
        items.append(f'"{escaped}"')
    return f"ARRAY[{', '.join(sql_escape(item) for item in arr)}]::text[]"

def main():
    with open('assets/data/unified_exercises_catalog.json', 'r') as f:
        unified_catalog = json.load(f)

    with open('assets/data/exercise_mappings.json', 'r') as f:
        mappings = json.load(f)

    migration_path = 'supabase/migrations/20261021000000_unified_exercise_catalog.sql'

    lines = [
        "-- Migration: 20261021000000_unified_exercise_catalog.sql",
        "-- Description: Replaces legacy exercise catalog with unified, legally compliant exercise catalog",
        "-- Preserves 100% of historical workout data and legacy foreign key references",
        "",
        "-- 1. Schema upgrades to public.exercises",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS canonical_id TEXT;",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'fit-host';",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS original_source_id TEXT;",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS aliases TEXT[] DEFAULT '{}'::text[];",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS body_part TEXT;",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS muscle_group TEXT;",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS secondary_muscles TEXT[] DEFAULT '{}'::text[];",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS instruction_steps TEXT[] DEFAULT '{}'::text[];",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS exercise_type TEXT NOT NULL DEFAULT 'strength';",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS movement_type TEXT NOT NULL DEFAULT 'compound';",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS difficulty_level TEXT NOT NULL DEFAULT 'intermediate';",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS audience_suitability TEXT NOT NULL DEFAULT 'universal';",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS media_thumbnail_url TEXT;",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS media_animation_url TEXT;",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS media_license TEXT;",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS media_attribution TEXT;",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS content_license TEXT;",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS content_attribution TEXT;",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS languages_available TEXT[] DEFAULT ARRAY['en']::text[];",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS safety_notes TEXT;",
        "ALTER TABLE public.exercises ADD COLUMN IF NOT EXISTS publication_status TEXT NOT NULL DEFAULT 'published';",
        "",
        "-- 2. Exercise ID Mappings table (Preserves historical foreign keys and routine lookups)",
        "CREATE TABLE IF NOT EXISTS public.exercise_id_mappings (",
        "    old_exercise_id TEXT PRIMARY KEY,",
        "    canonical_exercise_id TEXT NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,",
        "    old_name TEXT,",
        "    canonical_name TEXT,",
        "    confidence TEXT NOT NULL DEFAULT 'high',",
        "    mapped_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())",
        ");",
        "",
        "-- 3. Optimized indexes for search, filtering, and foreign key resolution",
        "CREATE INDEX IF NOT EXISTS idx_exercises_publication_status ON public.exercises(publication_status);",
        "CREATE INDEX IF NOT EXISTS idx_exercises_audience_suitability ON public.exercises(audience_suitability);",
        "CREATE INDEX IF NOT EXISTS idx_exercises_body_part ON public.exercises(body_part);",
        "CREATE INDEX IF NOT EXISTS idx_exercises_target_muscle ON public.exercises(target_muscle);",
        "CREATE INDEX IF NOT EXISTS idx_exercises_equipment ON public.exercises(equipment);",
        "CREATE INDEX IF NOT EXISTS idx_exercises_canonical_id ON public.exercises(canonical_id);",
        "CREATE INDEX IF NOT EXISTS idx_exercise_mappings_canonical ON public.exercise_id_mappings(canonical_exercise_id);",
        "",
        "-- 4. Hardened Row-Level Security (RLS)",
        "ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;",
        "ALTER TABLE public.exercise_id_mappings ENABLE ROW LEVEL SECURITY;",
        "",
        "-- Drop old policies",
        "DROP POLICY IF EXISTS \"exercises_select_public_or_own\" ON public.exercises;",
        "DROP POLICY IF EXISTS \"exercises_select_published_or_own\" ON public.exercises;",
        "DROP POLICY IF EXISTS \"exercises_insert_own\" ON public.exercises;",
        "DROP POLICY IF EXISTS \"exercises_insert_custom\" ON public.exercises;",
        "DROP POLICY IF EXISTS \"exercises_update_own\" ON public.exercises;",
        "DROP POLICY IF EXISTS \"exercises_update_custom\" ON public.exercises;",
        "DROP POLICY IF EXISTS \"exercises_delete_own\" ON public.exercises;",
        "DROP POLICY IF EXISTS \"exercises_delete_custom\" ON public.exercises;",
        "",
        "-- Read policy: Published catalog exercises and user custom exercises are readable",
        "CREATE POLICY \"exercises_select_published_or_own\" ON public.exercises",
        "    FOR SELECT",
        "    USING (publication_status = 'published' OR owner_id IS NULL OR (auth.uid() IS NOT NULL AND owner_id = auth.uid()));",
        "",
        "-- Write policy: Authenticated users can only create their own custom exercises",
        "CREATE POLICY \"exercises_insert_custom\" ON public.exercises",
        "    FOR INSERT",
        "    WITH CHECK (auth.uid() IS NOT NULL AND owner_id = auth.uid() AND is_custom = true);",
        "",
        "-- Update policy: Users can only modify their own custom exercises",
        "CREATE POLICY \"exercises_update_custom\" ON public.exercises",
        "    FOR UPDATE",
        "    USING (auth.uid() IS NOT NULL AND owner_id = auth.uid() AND is_custom = true);",
        "",
        "-- Delete policy: Users can only delete their own custom exercises",
        "CREATE POLICY \"exercises_delete_custom\" ON public.exercises",
        "    FOR DELETE",
        "    USING (auth.uid() IS NOT NULL AND owner_id = auth.uid() AND is_custom = true);",
        "",
        "-- Exercise mappings read policy: Everyone can resolve historical IDs",
        "DROP POLICY IF EXISTS \"exercise_mappings_select_all\" ON public.exercise_id_mappings;",
        "CREATE POLICY \"exercise_mappings_select_all\" ON public.exercise_id_mappings",
        "    FOR SELECT",
        "    USING (true);",
        "",
        "-- 5. Safe archiving of legacy exercise records (prevents orphaned FKs)",
        "UPDATE public.exercises SET publication_status = 'archived' WHERE id LIKE 'ex-%';",
        "",
    ]

    # Insert / Upsert unified catalog exercises
    lines.append("-- 6. Seed canonical unified exercise catalog (idempotent ON CONFLICT)")
    for ex in unified_catalog:
        sec_muscles = sql_array(ex['secondary_muscles'])
        inst_steps = sql_array(ex['instruction_steps'])
        langs = sql_array(ex['languages_available'])
        aliases = sql_array(ex['aliases'])
        rec_for = ','.join(ex['recommended_for'])

        stmt = f"""INSERT INTO public.exercises (
    id, canonical_id, source, original_source_id, name, aliases, category, body_part,
    target_muscle, muscle_group, secondary_muscles, equipment, instructions, instruction_steps,
    exercise_type, movement_type, difficulty_level, audience_suitability, recommended_for,
    media_thumbnail_url, media_animation_url, media_license, media_attribution,
    content_license, content_attribution, languages_available, safety_notes, publication_status,
    is_custom, created_at, updated_at
) VALUES (
    {sql_escape(ex['id'])}, {sql_escape(ex['canonical_id'])}, {sql_escape(ex['source'])},
    {sql_escape(ex['original_source_id'])}, {sql_escape(ex['name'])}, {aliases},
    {sql_escape(ex['category'])}, {sql_escape(ex['body_part'])}, {sql_escape(ex['target_muscle'])},
    {sql_escape(ex['muscle_group'])}, {sec_muscles}, {sql_escape(ex['equipment'])},
    {sql_escape(ex['instructions'])}, {inst_steps}, {sql_escape(ex['exercise_type'])},
    {sql_escape(ex['movement_type'])}, {sql_escape(ex['difficulty_level'])},
    {sql_escape(ex['audience_suitability'])}, {sql_escape(rec_for)},
    {sql_escape(ex['media_thumbnail_url'])}, {sql_escape(ex['media_animation_url'])},
    {sql_escape(ex['media_license'])}, {sql_escape(ex['media_attribution'])},
    {sql_escape(ex['content_license'])}, {sql_escape(ex['content_attribution'])},
    {langs}, {sql_escape(ex['safety_notes'])}, 'published', false, {sql_escape(ex['created_at'])}, {sql_escape(ex['updated_at'])}
) ON CONFLICT (id) DO UPDATE SET
    canonical_id = EXCLUDED.canonical_id,
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    target_muscle = EXCLUDED.target_muscle,
    equipment = EXCLUDED.equipment,
    instructions = EXCLUDED.instructions,
    instruction_steps = EXCLUDED.instruction_steps,
    audience_suitability = EXCLUDED.audience_suitability,
    publication_status = 'published',
    updated_at = EXCLUDED.updated_at;"""
        lines.append(stmt)

    lines.append("")
    lines.append("-- 7. Seed historical exercise ID mappings")
    for old_id, m in mappings.items():
        stmt = f"""INSERT INTO public.exercise_id_mappings (
    old_exercise_id, canonical_exercise_id, old_name, canonical_name, confidence, mapped_at
) VALUES (
    {sql_escape(old_id)}, {sql_escape(m['canonical_exercise_id'])},
    {sql_escape(m['old_name'])}, {sql_escape(m['canonical_name'])},
    {sql_escape(m['confidence'])}, {sql_escape(m['mapped_at'])}
) ON CONFLICT (old_exercise_id) DO UPDATE SET
    canonical_exercise_id = EXCLUDED.canonical_exercise_id,
    canonical_name = EXCLUDED.canonical_name;"""
        lines.append(stmt)

    with open(migration_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    print(f"Generated migration file: {migration_path} ({len(lines)} lines)")

if __name__ == '__main__':
    main()
