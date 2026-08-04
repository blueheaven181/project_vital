# Changelog

## [Unreleased] — 2026-08-04

### Fixed

- **Root cause of the dashboard showing `0`/`—`**: the quick-log FAB wrote a display string to `history_box` instead of a Map, silently breaking `_loadData()`. All daily-log writes now go through a single `_upsertHistoryEntry()` helper.
- Dashboard showed `0.0 kg` immediately after onboarding, before any daily log existed — onboarding now seeds a `history_box` entry for today.
- `_loadData()`'s "no data" fallback used `0`/`0.0` instead of `null`, defeating the UI's own `-- kg` placeholder logic.
- `_restoreFromBackupJson` used unawaited `clear()` immediately followed by `putAll()`, which didn't reliably clear old data before restoring — replaced with a key-by-key `_replaceBoxContents()`.
- "Restore from backup" was previously a non-functional placeholder; it now actually restores.

### Added

- Consolidated "More" menu (History, Progress Analysis, Meal Presets, Backup & Restore, Import CSV), replacing a 5-icon app bar.
- CSV bulk import (paste-based, `date,weight,waist,calories,protein,fasting,steps` rows).
- Automated regression test suite (`test/`, 4 tests) covering the FAB save path, onboarding seed, CSV import, and backup restore.
- Full dark-glass visual redesign: `VitalPalette` design tokens, real glassmorphism cards, amber accent + per-metric category colors, a working goal-progress ring, monospace tabular numerals — applied across onboarding, dashboard, and all dialogs.

### Changed

- Onboarding and Profile Settings no longer `await` Hive writes inside button handlers (Hive's single-key writes are synchronous in-memory; awaiting them was unnecessary and fragile under test).

## Earlier checkpoints

The following commits predate this changelog and are summarized from their commit messages:

- `76a80f9` — Fixed chronological weight chart sorting and latest-date dashboard loading.
- `8176289` — Fixed state data loading so input metrics instantly reflect on the dashboard.
- `466298a` — Checkpoint: working dashboard features restored.
- `ec34d27` — Initial commit: Project Vital core setup and documentation.
