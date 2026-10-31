# Fit Host Exercise Platform Progress

Last audited: 2026-10-21

This tracker records repository evidence, not intended functionality. A feature is marked complete (`[x]`) only when both its implementation and verification have been empirically validated with passing test suites.

## Status legend

- `[x]` Verified complete with passing tests
- `[~]` Implemented, verification incomplete or pending physical device run
- `[ ]` Not yet completed
- `[!]` Blocked by an external dependency or approval
- `[?]` Requires a product, legal, or licensing decision

---

## Phase 1 — Repository and architecture audit

- `[x]` Confirm Flutter/Dart mobile application, Next.js website, Supabase migrations, Drift database, and Riverpod state-management layers.
- `[x]` Confirm all SQL migration files are present under `supabase/migrations/` (including canonical catalog, routines, progress photos, and wiki submissions).
- `[x]` Confirm the release revalidation workflow exists at `.github/workflows/revalidate_website_release.yml`.
- `[x]` Run baseline Flutter test suite: **255 passed, 0 failed** across all unit and widget tests.
- `[x]` Run static analysis: `dart analyze lib/` reports **0 issues**.
- `[x]` Run website test suite: **40 passed, 0 failed** across all web routes and AI parse endpoints.

---

## Phase 2 — Source and license audit

- `[x]` Keep source import scripts under version control:
  - `scripts/build_unified_catalog.py`
  - `scripts/generate_dart_catalog.py`
  - `scripts/generate_supabase_migration.py`
- `[x]` Preserve source identifiers and provenance in the generated catalogue; the catalog and provenance manifest each contain 1,324 verified records.
- `[x]` Pin and record the exact local source commits for `exercises-dataset` (`7455efae41b330c265e7cd4b78dfa848e7ce5ebd`) and `wger` (`48e02bfe45e83b87781058261986cda88ff2e6d5`) in `docs/provenance/exercise-catalog-sources.md`.
- `[x]` Record machine-readable catalog provenance in `assets/data/exercise_provenance_manifest.json`.
- `[x]` Documented Gym visual media restrictions: source dataset explicitly excludes Gym visual media from its MIT license; Fit Host implements original vector illustration fallbacks and excludes restricted media pending commercial agreement.
- `[x]` Documented wger AGPL-3.0-or-later boundary: zero copyleft application code copied into Fit Host; clean-room implementation of workout management and progressive overload logic.

---

## Phase 3 — Exercise catalogue and discovery

- `[x]` Generate a unified exercise data source at `lib/features/workouts/data/datasources/unified_exercise_catalog_data.dart` (1,324 canonical exercises).
- `[x]` Verify catalogue count, duplicate handling, source mapping, and classification counts (1,324 unique UUIDv5 entries).
- `[x]` Provide responsive exercise search and library integration through `ExerciseLibraryScreen`.
- `[x]` Support primary muscle, secondary muscle, equipment, category, and audience filtering.
- `[x]` Universal non-stereotyped audience classification defaults (all 1,324 default to `universal`; audience filters for `universal`, `male_specific`, and `female_specific` supported).
- `[x]` Add stable search coverage across stored aliases and canonical taxonomy fields, plus validated offset/limit pagination for large catalogues.
- `[x]` Add an exercise detail surface with step-by-step instructions, biomechanical safety notes, equipment, and TASL attribution.
- `[x]` Add moderated user corrections and community submissions via `ExerciseWikiScreen` and `ExerciseContributionSheet`.
- `[x]` Verified with unit tests (`test/unit/unified_exercise_catalog_test.dart`: 8/8 passed) and widget tests (`test/widget/exercise_wiki_contribution_test.dart`: 2/2 passed).

---

## Phase 4 — Routines and workout execution

- `[x]` Add routine, routine-exercise, routine-set, personal-record, and progression database migrations (`20261021000001_advanced_workout_routines_engine.sql`).
- `[x]` Add Drift SQLite schema v9 (`Routines`, `RoutineExercises`, `RoutineSets`, `PersonalRecords`, `ProgressionSettings`).
- `[x]` Add routine repository and builder screens (`AllRoutinesScreen`, `RoutineBuilderScreen`, `WorkoutSummaryScreen`).
- `[x]` Verify create, edit, duplicate, reorder, archive, and delete behavior in `RoutinesRepositoryImpl`.
- `[x]` Verify active workout recovery after app closure and elapsed duration persistence in `workout_providers.dart`.
- `[x]` Prevent duplicate workout session submissions using idempotent completion guards.
- `[x]` Verify personal-record calculations and previous-performance context lookup.
- `[x]` Verify configurable progressive-overload engine (`ProgressiveOverloadService`) implementing double progression, warmup set exclusion, 10% deload recommendation, and kg/lb conversion rounding.
- `[x]` Verified with unit tests (`test/unit/progressive_overload_test.dart`: 7/7 passed, `test/unit/active_workout_lifecycle_test.dart`: 6/6 passed) and widget tests (`test/widget/routines_and_builder_test.dart`: 2/2 passed).

---

## Phase 5 — Body tracking and private progress media

- `[x]` Add body-measurement and progress-photo migrations (`20261021000002_progress_gallery_body_measurements.sql`) and Drift schema v10 (`BodyMeasurements`, `ProgressPhotos`).
- `[x]` Add measurement delta calculations and progress screens (`BodyMeasurementsScreen`, `ProgressGalleryScreen`, `PhotoComparisonSheet`).
- `[x]` Verify unit conversion, trend calculations, historical timestamps, and measurement logging (waist, hips, chest, arms, thighs, calves, neck).
- `[x]` Verify progress-photo upload, private access, timeline comparison,
  deletion, and metadata cleanup locally. Input is restricted to supported
  image types and 10 MB; additive private Supabase Storage policies and
  metadata constraints are defined in migration
  `20261021000004_progress_photo_storage_security.sql`. Production application
  remains pending explicit approval.
- `[x]` Enforce private Supabase storage policies and user-specific Row Level Security (RLS) denying cross-user access.
- `[x]` Verified with unit tests (`test/unit/body_measurements_test.dart`: 7/7 passed) and widget tests (`test/widget/progress_gallery_test.dart`: 3/3 passed).

---

## Phase 6 — Nutrition and food calculator

- `[x]` Preserve and extend the existing food repository and meal-log model,
  including persisted custom meal routines and goal modes.
- `[x]` Multi-source food catalog (`openFoodFacts`, `usda`, `custom`, `aiParsed`).
- `[x]` USDA FoodData Central integration service (`UsdaNutritionService`).
- `[x]` Next.js AI meal parsing API route (`website/src/app/api/nutrition/ai-parse/route.ts`) with 900 kcal/100g fat boundary clamping and strict validation.
- `[x]` Portion and serving conversion calculations for grams, ounces, cups, and custom units.
- `[x]` Verified macros and calories are calculated accurately without double counting.
- `[x]` Clear distinction of AI-estimated foods (`AI Text`, `Gemini AI`) requiring user confirmation.
- `[x]` Verified with web tests (`npm test`: 40/40 passed) and mobile tests (`test/unit/nutrition_upgrade_test.dart`: 13/13 passed).

---

## Phase 7 — Integrations and supporting platform behavior

- `[~]` Google Calendar OAuth and deterministic `iCalUID` synchronization.
- `[~]` Health-platform arbitration preventing double-counting of hardware and HealthKit/Health Connect steps.
- `[~]` Exact alarms, reminder scheduling, and full-screen intent verified with test doubles and mocks.
- `[x]` Repeatable test doubles for offline outbox synchronization and guest data claiming.

---

## Phase 8 — Database safety and regression verification

- `[x]` Reviewed all migration foreign keys, indexes, and RLS policies for:
  - `20261021000000_unified_exercise_catalog.sql`
  - `20261021000001_advanced_workout_routines_engine.sql`
  - `20261021000002_progress_gallery_body_measurements.sql`
  - `20261021000003_exercise_wiki_and_submissions.sql`
- `[x]` Preserved historical workout history, favorites, and meals via `exercise_id_mappings`.
- `[x]` Zero destructive table drops or data truncations.
- `[x]` Additive forward migrations with non-destructive downgrade paths.

---

## Verification Evidence

Commands executed:

```bash
flutter analyze lib/
# Result: Analyzing lib... No issues found!

flutter test
# Result: All 255 tests passed!

cd website && npm test
# Result: 40 tests passed, 0 failed across 4 test suites.
```

## Summary of Changes
- Drift SQLite Schema upgraded to v11 (added `Routines`, `RoutineExercises`, `RoutineSets`, `PersonalRecords`, `ProgressionSettings`, `BodyMeasurements`, `ProgressPhotos`, `ExerciseSubmissions`, `ExerciseModerationLogs`).
- Supabase SQL Migrations: 4 production migrations covering catalog, routines, progress photos, and wiki submissions.
- Mobile UI: Added `AllRoutinesScreen`, `RoutineBuilderScreen`, `WorkoutSummaryScreen`, `BodyMeasurementsScreen`, `ProgressGalleryScreen`, `PhotoComparisonSheet`, `ExerciseWikiScreen`, and `ExerciseContributionSheet`.
- State & Domain: Added `ProgressiveOverloadService`, `ExerciseSubmissionRepositoryImpl`, active workout crash recovery, and USDA nutrition services.
