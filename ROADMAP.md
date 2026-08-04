# Roadmap

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
