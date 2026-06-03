# Changelog

All notable changes to this project are documented in this file.

## Unreleased

### Added

### Fixed

### Changed

### Removed

## 2.0.0 - 2026-06-03

A ground-up rebuild bringing the depth of the classic Palm OS HandyShopper to
the app, on a new relational data model with zero-data-loss migration from 1.x.

### Added

- Multiple shopping lists ("databases"), each with its own items, categories,
  stores and settings; list styles (shopping / to-do / dated / check) and emoji
  icons.
- Copy a list, share it as readable text or an importable file, and back up /
  restore whole-app or per-list data as JSON.
- Custom categories with emoji icons; assign items and filter the list by
  category.
- Per-item notes via a dedicated note editor.
- A full-screen item detail editor (replacing the old add/edit dialog).
- Stores with a price and aisle per store, price comparison across stores
  (cheapest highlighted), and a store selector that re-prices the list.
- VAT / sales tax: per-list tax rate plus an optional second tax, in add-on
  (sales-tax) or inclusive (VAT) mode.
- Checkout screen that tallies subtotal, tax and total and marks items
  purchased.
- Item priority (1–5), units, base aisle, and per-item dates for dated lists.
- Configurable item-row columns and extra sort options (priority, aisle, date).
- Complete translations across all 20 supported languages.

### Changed

- Rebuilt on a relational SQLite schema (lists, categories, stores, items,
  per-store prices) owned by a single service, with versioned migrations
  (v1 → v4) and no data loss.
- Lists-as-home navigation and a per-list settings screen.
- Project license changed from 0BSD to MIT.
- README rewritten for 2.0.
- Flutter upgrade to 3.44.0.
- Added a test suite covering the data layer, migrations, providers, tax math,
  backup round-trips, and localization key parity.

### Fixed

- "All / Need" tab labels were invisible in dark mode.

### Dependencies

- Added `share_plus`, `file_picker`, and `sqflite_common_ffi` (dev).

## 1.4.0 - 2026-03-16

### Changed

- Flutter upgrade to 3.41.4
- Improved code quality
- Migration from flutter_markdown to flutter_markdown_plus

## 1.3.1 - 2025-12-31

### Changed

- Flutter upgrade to 3.38.5

## 1.3.0 - 2025-10-03

### Changed

- Flutter upgrade to 3.35.5
- Android 16k pages compatibility

## 1.2.0 - 2025-07-05

### Changed

- Flutter upgrade to 3.32.5

## 1.1.1 - 2024-06-24

### Changed

- Tutorial message for initial empty list
- Display full numbers for quantity as int

## 1.1.0 - 2024-06-14

### Added

- Privacy Policy available within the app
- Display sum of all product prices

### Changed

- Allow to enter float numbers for quantity instead of int only

## 1.0.1 - 2024-06-10

### Fixed

- Unable to enter decimal numbers for price
- Language settings are not loaded on app start (#1)

### Changed

- Flutter upgrade to 3.22.2
- archive package upgrade to 3.6.1
- flutter_launcher_icons package upgrade to 0.13.1
- flutter_lints package upgrade to 4.0.0
- image package upgrade to 4.2.0
- lints package upgrade to 4.0.0

## 1.0.0 - 2024-06-01

### Added

- Initial release.
- Database logic.
- Main UI elements and logic.
- Settings screen.
- Sorting functionality.
- Several translations.
