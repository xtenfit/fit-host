# Exercise Catalog Source and License Record

Last audited: 2026-10-21

This document records the source revisions and license boundaries for the
generated exercise catalog. It is intentionally conservative: a source license
for text or structured data does not grant rights to the source repository's
images, GIFs, videos, or other media.

## Pinned source revisions

| Source | Local path | Commit | License evidence |
|---|---|---|---|
| `hasaneyldrm/exercises-dataset` | `reference/exercises-dataset` | `7455efae41b330c265e7cd4b78dfa848e7ce5ebd` | `LICENSE`, `NOTICE.md` |
| `wger-project/wger` | `reference/wger` | `48e02bfe45e83b87781058261986cda88ff2e6d5` | `LICENSE.txt` and repository component metadata |

These commits are the revisions present in the local reference checkouts at
the time of this audit. The import pipeline should be rerun and this record
updated whenever either source revision changes.

## Generated catalog evidence

- `assets/data/unified_exercises_catalog.json` contains 1,324 records.
- `assets/data/exercise_provenance_manifest.json` contains 1,324 provenance
  records.
- `lib/features/workouts/data/datasources/unified_exercise_catalog_data.dart`
  is generated from the normalized catalog.
- `scripts/build_unified_catalog.py` is the normalization/import entry point.
- `scripts/generate_dart_catalog.py` generates the Dart data source.
- `scripts/generate_supabase_migration.py` generates the SQL import.
- The generated records currently identify `MIT` as the content license.

## Media restriction

The `exercises-dataset` `LICENSE` explicitly states that its MIT license does
not cover exercise media in `images/` and `videos/`. It identifies that media
as © Gym visual and requires separate permission under Gym visual's terms.
The generated provenance manifest currently reports:

```text
media_license: © Gym visual
```

Therefore, the current catalog must **not** be described as 100% CC-BY-SA,
public domain, or unrestricted media. Media may be shipped only when Fit Host
has independently verified permission for the specific assets and preserved
the required attribution. Otherwise, the media reference must be excluded or
replaced with an original or separately licensed asset.

The wger repository is AGPL-licensed. This project may inspect wger data and
implement compatible functionality, but it must not copy AGPL application code
into Fit Host without a deliberate license review.

## Required follow-up

- `[ ]` Produce per-asset media decisions: included with permission,
  replaced, or excluded.
- `[ ]` Preserve required attribution in the application and distribution
  notices for every included third-party asset.
- `[ ]` Add an automated import check that rejects restricted or unknown media
  licenses from release artifacts.
- `[ ]` Obtain legal approval before distributing any media whose permission
  is not documented in the repository.
