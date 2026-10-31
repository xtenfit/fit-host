# Fit Host Exercise Platform Architecture & Source Migration Audit

**Document Status:** Complete & Verified  
**Date:** 2026-10-21  
**Project:** Fit Host Mobile (Flutter/Dart), Web (Next.js/React), Backend (Supabase/PostgreSQL)  
**Supabase Reference:** `eedubttdylyqrhyeikwb`  
**Production Domain:** `https://fithost.amitrana.tech`

---

## 1. Executive Summary

Fit Host has executed a comprehensive, non-destructive migration and modernization of its exercise catalog, training engine, body tracking, nutrition intelligence, and community wiki platform. 

Rather than relying on disjointed third-party APIs or creating duplicate demo codebases, Fit Host integrated audited exercise taxonomy from two primary open source repositories:
1. `hasaneyldrm/exercises-dataset` (JSON dataset with multilingual instructions)
2. `wger-project/wger` (scientific taxonomy, exercise fixtures, and workout logic)

All user-facing and backend features have been implemented using clean-room engineering to strictly satisfy open-source licenses (MIT, AGPL-3.0, Gym visual copyright restrictions). Historical user workouts, custom exercises, food entries, and profile data remain completely preserved through database-level compatibility mapping.

---

## 2. Source Repositories & Pinned Revisions

| Source Repository | Local Path | Pinned Commit | Content Inspected | Primary License |
|---|---|---|---|---|
| `hasaneyldrm/exercises-dataset` | `reference/exercises-dataset` | `7455efae41b330c265e7cd4b78dfa848e7ce5ebd` | 1,324 exercise JSON objects, steps, muscle targets, media references | MIT (text/code) / **© Gym visual** (media) |
| `wger-project/wger` | `reference/wger` | `48e02bfe45e83b87781058261986cda88ff2e6d5` | Django backend, database fixtures, translations, exercise comments | **AGPL-3.0-or-later** (app) / CC-BY-SA 4.0 (fixtures) |

### 2.1 License & Copyright Boundaries
- **exercises-dataset Media Notice:** The repository README and LICENSE explicitly clarify that the MIT license does not extend to thumbnail images and animated GIFs located in `images/` and `videos/`. These assets are proprietary works belonging to **© Gym visual** (`https://gymvisual.com/`) and require separate commercial authorization. Fit Host does not redistribute or hotlink these assets without documented commercial permission; the mobile client gracefully falls back to branded vector illustrations and verified placeholders.
- **wger AGPL-3.0-or-later Boundary:** wger's core server application is licensed under AGPLv3. Copying wger application code directly into Fit Host's proprietary codebase would trigger copyleft obligations. Fit Host treats wger as an architectural reference and clean-room specification. Reusable fixture data (such as aliases and biomechanical safety comments) is integrated under CC-BY-SA attribution rules with full TASL (Title, Author, Source, License) manifests recorded in `assets/data/exercise_provenance_manifest.json`.

---

## 3. Data Model Comparison & Canonical Schema

### 3.1 Source vs. Canonical Comparison

| Field / Attribute | `exercises-dataset` | `wger` Fixtures | Fit Host Canonical Model (`CanonicalExercise`) |
|---|---|---|---|
| **Primary Key** | Sequential numeric string (e.g. `"0001"`) | Integer PK (e.g. `123`) & UUID | UUIDv5 deterministically derived via `d5c7b396-848e-4a87-b27e-859a4bb33107` |
| **Name** | English title string | Multilingual translation table | Title-cased English name + multilingual alias array |
| **Category** | Freeform string (10 types) | Relational `Category` model | 7 Canonical Categories (`Chest`, `Back`, `Legs`, `Arms`, `Shoulders`, `Core`, `Cardio`) |
| **Equipment** | Raw string (16 types) | Relational `Equipment` model | Normalized Equipment Enum (`Barbell`, `Dumbbell`, `Cable`, `Machine`, `Bodyweight`, etc.) |
| **Muscles** | `target` & `secondary_muscles` string arrays | Relational `Muscle` IDs | Primary target muscle + secondary synergist list (proper anatomical names) |
| **Movement Pattern** | Implicit | Stored in exercise comments | Explicitly derived (`compound` vs `isolation`) |
| **Audience Filter** | Not specified | Not specified | `universal` (default), `male_specific`, `female_specific`, `unverified` |
| **Instructions** | Multilingual dictionary & step array | HTML text in translation table | Clean formatted string & structured step-by-step guidance list |
| **Safety Notes** | Absent | Freeform `ExerciseComment` records | Biomechanical safety cues and form checkpoints |
| **Attribution** | Contributor list | Author/license metadata | Machine-readable `provenance` manifest + TASL UI footer |

### 3.2 Canonical Entity Architecture
The production database schema incorporates the canonical catalog while preserving foreign key references:
- `exercises`: Canonical catalog with columns `id`, `name`, `aliases`, `category`, `equipment`, `target_muscle`, `secondary_muscles`, `instructions`, `instruction_steps`, `safety_notes`, `audience_suitability`, `provenance_source`, `text_license`.
- `exercise_id_mappings`: Backward-compatibility table linking legacy exercise IDs (`legacy_id`) to new canonical UUIDs (`canonical_id`), ensuring zero breakage in user workout logs.
- `exercise_submissions`: Unmoderated staging table for community proposals and exercise corrections.
- `exercise_moderation_logs`: Immutable audit trail of reviewer approvals, rejections, and rationale.

---

## 4. Exercise Count & Data Quality Audit

- **Total Source Records in `exercises-dataset`:** 1,324
- **Normalized Canonical Records in Fit Host:** 1,324
- **Unique Deterministic UUIDs:** 1,324
- **Cross-Referenced wger Matches:** 187 exercises enriched with wger biomechanical safety comments and aliases.
- **Duplicate Detection Findings:** Zero internal collisions in the normalized 1,324 set. All UUIDs are generated with namespace UUIDv5 (`exercises-dataset:<orig_id>`), guaranteeing stable cross-platform ID generation.
- **Language Coverage:**
  - English: 1,324 (100%)
  - Secondary translations present in source: Spanish, German, French, Italian, Turkish, Chinese, Portuguese.

### 4.1 Audience & Gender Specificity Audit
In accordance with modern sports science and evidence-based biomechanics:
- **Default Classification:** `universal` (1,324 / 1,324).
- **Rule:** Exercises are not artificially segmented by gender based on muscle groups (e.g. glute exercises are not categorized as female-only; chest exercises are not categorized as male-only).
- **Specific Flags:** `male_specific` and `female_specific` are reserved strictly for genuine sex-specific anatomical conditions (e.g., pelvic floor rehabilitation postpartum, clinical scrotal hernia adaptations).

---

## 5. Platform Feature Matrix & Implementation

| Feature Domain | Existing Fit Host State | Source Inspiration / Spec | Implemented Architecture in Fit Host |
|---|---|---|---|
| **Exercise Catalog** | Static mock list (~20 items) | `exercises-dataset` & `wger` | 1,324 canonical exercises in Drift SQLite + Supabase with search, muscle/equipment filters, and audience toggles. |
| **Workout Routines** | Ad-hoc workout logging | wger workout manager | Relational routines in Drift v9 + Supabase, routine duplication, routine day templates, and reorderable exercise sets. |
| **Training Engine** | Basic set logging | Progressive overload theory | Pure Dart `ProgressiveOverloadService` implementing double progression, warmup exclusion, 10% deload recommendation, and kg/lb rounding. |
| **Active Workout Lifecycle** | Volatile in-memory state | Crash-resilient tracker | SQLite-backed active workout persistence, timestamp elapsed timer recovery, and duplicate session submission prevention. |
| **Body Measurements** | Weight-only tracking | wger measurement module | Drift v10 + Supabase `body_measurements` (waist, hips, chest, arms, thighs, calves, neck) with historical trend deltas. |
| **Progress Photo Gallery** | None | wger user media | Private progress photo gallery with side-by-side comparison slider and authenticated owner RLS isolation. |
| **Nutrition Engine** | Local calorie tracker | Open Food Facts & USDA FoodData | Multi-source food catalog (USDA + OpenFoodFacts + custom), Next.js AI parsing API with 900 kcal/100g fat boundary clamping. |
| **Exercise Wiki & Contributions** | None | wger community database | Drift v11 + Supabase `exercise_submissions` with SHA-256 deduplication hashing and moderation review audit trails. |

---

## 6. Migration, Compatibility & Rollback Strategy

### 6.1 Safe Migration Pipeline
1. **Catalog Seeding:** The 1,324 canonical exercises are seeded into SQLite and Supabase using idempotent `ON CONFLICT (id) DO NOTHING` or `upsert` semantics.
2. **Legacy ID Translation:** When rendering historical workouts, the app executes a lookup on `ExerciseIdMappings`. If a legacy ID matches, the canonical model is displayed; if not found, the historical name is displayed without loss.
3. **Rollback Safety:**
   - No historical tables were dropped or modified destructively.
   - All migrations (`20261021000000`, `20261021000001`, `20261021000002`, `20261021000003`) are forward-additive.
   - If a rollback is required, existing routines and workouts remain valid because they reference standard UUID foreign keys.

---

## 7. Verification Evidence & Test Summary

| Test Suite | Total Tests | Passed | Failed | Status |
|---|---|---|---|---|
| **Flutter Full Test Suite (`flutter test`)** | 255 | 255 | 0 | **100% Pass** |
| **Next.js Web Test Suite (`npm test`)** | 40 | 40 | 0 | **100% Pass** |
| **Dart Static Analysis (`dart analyze lib/`)** | N/A | 0 issues | 0 issues | **Clean** |
| **Focused Unit & Widget Tests:** | | | | |
| - `unified_exercise_catalog_test.dart` | 8 | 8 | 0 | Pass |
| - `progressive_overload_test.dart` | 7 | 7 | 0 | Pass |
| - `active_workout_lifecycle_test.dart` | 6 | 6 | 0 | Pass |
| - `body_measurements_test.dart` | 7 | 7 | 0 | Pass |
| - `progress_gallery_test.dart` | 3 | 3 | 0 | Pass |
| - `exercise_submission_test.dart` | 5 | 5 | 0 | Pass |
| - `exercise_wiki_contribution_test.dart` | 2 | 2 | 0 | Pass |
| - `routines_and_builder_test.dart` | 2 | 2 | 0 | Pass |
| - `nutrition_upgrade_test.dart` | 13 | 13 | 0 | Pass |

---

## 8. Release & Deployment Recommendations

1. **Remote Supabase Migrations:**
   Apply the additive SQL migrations in sequence:
   - `supabase/migrations/20261021000000_unified_exercise_catalog.sql`
   - `supabase/migrations/20261021000001_advanced_workout_routines_engine.sql`
   - `supabase/migrations/20261021000002_progress_gallery_body_measurements.sql`
   - `supabase/migrations/20261021000003_exercise_wiki_and_submissions.sql`
2. **Supabase Storage Provisioning:**
   Ensure bucket `progress-photos` exists with `public: false` and the RLS policy defined in migration `20261021000002` enabled.
3. **Website Environment Variables:**
   Confirm `USDA_API_KEY` and `GEMINI_API_KEY` are configured in Vercel project settings for live AI meal parsing and USDA FoodData querying.
