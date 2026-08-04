# Architecture

## Current structure

Project Vital is currently a single-file Flutter app (`lib/main.dart`, ~1,500 lines). This is a known limitation — see [ROADMAP.md](ROADMAP.md) for the planned split into `models/` / `services/` / `screens/`.

Screens:

- `OnboardingScreen` — first-run profile setup (name, age, height, starting weight, goal weight)
- `DashboardScreen` — main app: summary cards, goal ring, quick-log FAB, "More" menu (History, Analytics, Presets, Backup & Restore, Import CSV)

## Data model (Hive)

Three local Hive boxes, opened at startup in `main()`:

| Box | Purpose | Shape |
|---|---|---|
| `vitals_box` | Profile + settings | flat key-value: `user_name`, `user_age`, `user_height`, `user_goal_weight`, `profile_setup_complete` |
| `history_box` | Daily logs | keyed by `yyyy-MM-dd` date string → `Map` with optional `weight`, `waist`, `calories`, `protein`, `fasting`, `steps` |
| `presets_box` | Saved meal macros | keyed by meal name → `{cals, protein}` |

**Every write to `history_box` must produce a `Map`, and should go through `_upsertHistoryEntry()`**, which merges into whatever entry already exists for that date rather than overwriting it. This isn't a style preference — the app's core historical bug (dashboard permanently showing `0`/`—`) was caused by one code path writing a display **String** instead of a Map to this box, which silently broke `_loadData()`'s `rawLog is Map` check. Any new feature that logs daily data should reuse `_upsertHistoryEntry()`, not call `historyBox.put()` directly.

`_loadData()` reads the chronologically latest `history_box` entry and populates state fields as `null` when a field truly has no data — the UI relies on this to show `-- kg`/`--` placeholders instead of a misleading `0`.

## Design system

`VitalPalette` (top of `lib/main.dart`) defines the color tokens: an ink-navy base, one amber accent for primary actions/goal state, and a desaturated hue per metric category (rose/flame/violet/teal/sky) so the grid reads as biometric categories rather than one repeated color. Cards use real glassmorphism (`BackdropFilter` blur) over blurred background "glow" shapes — see `vitalGlassCard()` and `_backgroundGlow()`.

## Testing — a real Flutter/Hive gotcha

`test/` holds 4 widget tests, each in **its own file** (`quick_log_test.dart`, `onboarding_test.dart`, `csv_import_test.dart`, `restore_backup_test.dart`), sharing `test_helpers.dart`. This structure isn't arbitrary:

- Hive's real file I/O does not reliably complete inside `testWidgets`' fake-async zone once a frame has been pumped. If a real Hive write is initiated from inside a raw `tester.tap()` callback (unwrapped), its `Future` never resolves — no later `tester.runAsync()` or `.timeout()` rescues it.
- Bulk Hive lifecycle operations (`Box.clear()`, `Box.close()`, `Hive.deleteFromDisk()`) hit this far more often than simple single-key `put()`/`delete()` calls, which behave reliably (their in-memory keystore effect is synchronous).
- Running all tests in one file let state leak between tests via Hive's process-global box registry once one test's write got "stuck." Splitting into separate files sidesteps this entirely, since `flutter test` runs each file in its own isolate — fresh global `Hive` state every time.
- Any code that seeds Hive data before the first `pumpWidget()` call in a test must go through `tester.runAsync()`.

This also surfaced a real (non-test-only) bug: `_restoreFromBackupJson` originally called `box.clear()` immediately followed by `box.putAll()` without awaiting — since `clear()` isn't guaranteed synchronous the way `put()` is, this didn't reliably remove old data before the restore. Fixed via `_replaceBoxContents()`, which deletes and re-puts keys individually.
