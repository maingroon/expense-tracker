# Expense Tracker

A personal finance app for tracking income and expenses, built with Flutter. Organise spending into categories, record transactions, and review monthly summaries in the analytics view.

## Features

- **Categories** — create, reorder (drag & drop), archive, or delete spending/income categories with a custom icon and colour
- **Transactions** — log amounts against a category with an optional note and date/time; swipe to delete
- **Analytics** — monthly income, expense, and balance summary with a per-category breakdown
- **Theme** — light, dark, or system-default colour mode, persisted across sessions

## Tech stack

| Layer | Library |
|---|---|
| UI framework | Flutter |
| State / DI | provider |
| Local database | sqflite (SQLite) |
| Settings | shared_preferences |
| Date helpers | jiffy, intl |
| IDs | uuid |

## Getting started

### Prerequisites

- Flutter SDK (tested with the SDK at `/var/home/maingroon/Dev/flutter` — add `bin/` to `PATH` or use the full path)
- JDK 21 and Android SDK for Android builds

### Install dependencies

```bash
flutter pub get
```

### Run

```bash
flutter run
```

### Build

```bash
flutter build apk          # Android APK
flutter build appbundle    # Android App Bundle
```

## Project structure

```
lib/
  main.dart                  # Entry point; sequential service init + Provider setup
  constants/
    theme_constants.dart     # Light and dark ThemeData definitions
  models/
    category_model.dart      # Category, CategoryType, CategorySaveMode
    transaction_model.dart   # Transaction (amounts stored in cents as int)
  services/
    database_service.dart    # Raw SQLite access; schema + seed data
    categories_service.dart  # In-memory category list backed by DB
    transactions_service.dart# In-memory transaction list backed by DB
    settings_service.dart    # SharedPreferences wrapper (theme mode)
    theme_provider.dart      # ChangeNotifier; drives MaterialApp.themeMode
  screens/
    categories/              # Draggable category grid + save/edit bottom sheet
    transactions/            # Monthly transaction list + save/edit bottom sheet
    analytics/               # Monthly summary card + per-category chart list
    settings/                # Theme mode toggle
    widgets/                 # Shared button presets
```

## Forecasting

The app includes infrastructure for an offline-trained expense-forecasting module.
Aggregation, persistence, and UI are wired up; the model artefact and feature builder
body are produced by a separate research repository.
See [`docs/forecasting.md`](docs/forecasting.md) for details.

## Linting

```bash
flutter analyze
```
