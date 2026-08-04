# Project Vital

A personal, offline-first health & vitals tracker built with Flutter. Log daily weight, waistline, calories, protein, fasting windows, and steps — see trends, sparklines, and progress toward your goal weight, all stored locally on-device.

## Features

- Daily vitals logging via a quick-log sheet (weight, waistline, calories, protein, fasting hours, steps)
- Dashboard with per-metric cards, sparkline trends, and a goal-progress ring
- Meal macro presets — stack a saved meal's calories/protein into today's total in one tap
- Full historical timeline view
- CSV bulk import (paste rows of `date,weight,waist,calories,protein,fasting,steps`)
- JSON backup export/restore
- 100% offline — all data stored locally via Hive, no account, no network required

## Tech stack

- Flutter (Dart)
- [Hive](https://pub.dev/packages/hive) for local key-value storage
- [fl_chart](https://pub.dev/packages/fl_chart) for sparkline charts

## Getting started

```bash
flutter pub get
flutter run
```

To build a debug APK for sideloading onto an Android device:

```bash
flutter build apk --debug
```

The output lands at `build/app/outputs/flutter-apk/app-debug.apk`.

## Running tests

```bash
flutter test test/
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for a note on a Hive/`flutter_test` interaction that shapes how these tests are structured.

## Project docs

- [ARCHITECTURE.md](ARCHITECTURE.md) — data model, design system, known constraints
- [ROADMAP.md](ROADMAP.md) — planned work
- [CHANGELOG.md](CHANGELOG.md) — release history
