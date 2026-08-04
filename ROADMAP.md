# Roadmap

## Original Phase Plan

The project's original pre-implementation plan, checked against what actually
got built. Isar and Riverpod were dropped early in favor of Hive (plain boxes)
and `StatefulWidget` + `ValueListenableBuilder` — items below are marked done
where the *goal* was met, with a note where the tech diverged from the plan.

### Phase 1: Infrastructure & Data Modeling
- [x] Initialize Flutter project.
- [x] Define a schema for daily logs (Weight, Waist, Calories, Protein, Fasting, Steps) — as `VitalsEntry` over a Hive `Map`, not Isar. Blood pressure, sleep, and mood were dropped from scope.
- [ ] ~~Setup `build_runner` and generate database bindings~~ — doesn't apply; Hive box storage needs no codegen once Isar was dropped.
- [x] Initialize local profile storage for offline target tracking (goal weight, height, age) — `vitals_box`, not a separate table.

### Phase 2: Core Architecture (The Engine)
- [ ] ~~Configure Riverpod `ProviderScope`~~ — not adopted; state is plain `StatefulWidget`.
- [x] Build a repository to handle all reads/writes — `VitalsRepository` over Hive, not Isar.
- [x] Reactive stream for UI updates — `ValueListenableBuilder` on `historyBox.listenable()` / `vitalsBox.listenable()`, not a Riverpod stream provider.

### Phase 3: The MVP UI (Vertical Slice)
- [x] Implement global dark matte theme engine.
- [x] Build the Dashboard screen (Data read).
- [x] Implement the Floating Action Button (FAB).
- [x] Build the Bottom Sheet Micro-Form (Data write).
- [ ] Verify 15-second tracking loop functionality — never explicitly timed/verified.

### Phase 4: Fasting & Analytics
- [ ] Add the Intermittent Fasting toggle and Last Meal timestamp — only a raw "fasting hours" number field exists today, no toggle or timestamp.
- [ ] Build a trend service for 7-Day Moving Averages — sparklines currently plot raw chronological points, not smoothed.
- [ ] Integrate real trend indicators on the Dashboard — card subtitles like "TREND: -0.5cm" are hardcoded placeholder text, not computed.

### Phase 5: Testing & Hardening
- [ ] Setup `mocktail` for dependency-injection testing — not used; tests hit real Hive I/O in temp dirs instead (see test file header comments for why).
- [x] Widget tests for the dashboard — 4 regression tests cover quick-log, onboarding, CSV import, and restore; they test real data flows rather than an explicit Loading/Error/Data state matrix.
- [ ] Graceful error handling for local storage edge cases — partial: JSON parsing and spot generation are try/caught, not comprehensive.

### Phase 6: Clinical Export & Polish
- [ ] Integrate `pdf`, `csv`, `share_plus` packages — CSV import and JSON export exist but via paste/clipboard only; no packages, no PDF.
- [ ] Design a PDF layout with patient info and 30-day BP/Weight tables — no PDF export exists; BP isn't tracked at all.
- [ ] Compile a Release Build (Android/iOS) — only debug APKs have been built so far.
- [x] Deploy to physical device — informally: debug APKs sideloaded to your Vivo V30.

## Done

- **Architecture refactor** — split `lib/main.dart` (~1,500 lines) into `models/` (`VitalsEntry` instead of raw `Map` key-guessing), `services/` (`VitalsRepository` wrapping Hive as the single read/write surface), and `screens/`/`widgets/`.
- **Reactive data binding** — dashboard now drives its UI off `ValueListenableBuilder` on `vitalsBox.listenable()` / `historyBox.listenable()` instead of manual `_loadData()` + `setState()` calls after every write.
- **Repo cleanup** — removed `lib/models/vital_record.dart` and `vital_record.g.dart`, leftover unreferenced generated code from an earlier, abandoned Isar-based data-model attempt.

## Design

- Extend the dark-glass redesign's micro-interactions (press states, animated transitions) beyond the dashboard into the remaining dialogs (History, Presets, Analytics) for full visual consistency.
- Revisit typography — currently uses the platform's built-in `monospace` fallback for numerals; a bundled variable font (e.g. via `google_fonts`) would sharpen this further, at the cost of a new dependency.

## Platform

- Get USB or wireless `adb` debugging working reliably for on-device iteration (currently blocked by a Windows/Vivo USB driver issue) so `flutter run` can be used directly instead of build-and-sideload.
- iOS support/testing (currently untested on this project).

## Data

- File-based CSV/JSON export and import (currently clipboard-paste only, no direct file picker) — would need the `file_picker` package plus platform storage permissions.
