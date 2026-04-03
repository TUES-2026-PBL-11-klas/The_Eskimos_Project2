# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Велосипедна навигация за София (Bicycle Navigation for Sofia) — a Flutter mobile app for cyclists to find safe, bike-lane-optimized routes through Sofia, Bulgaria. Currently in the design/documentation phase; source code has not yet been implemented.

## Tech Stack

- **Mobile:** Flutter (Dart), flutter_map, geolocator, Riverpod (state management), get_it (DI)
- **Routing:** Valhalla routing engine (Docker), chosen for bike-specific routing with slope awareness
- **Data:** Sofiaplan GIS API (GeoJSON bike lane data), SQLite (sqflite) for local caching, MBTiles for offline maps
- **Infrastructure:** Docker + Kubernetes, GitHub Actions CI/CD

## Dependency Installation

**All dependencies (Flutter, Dart, Valhalla, backend services) must be installed inside Docker containers only — never on the local machine.** Use Docker Compose or Kubernetes manifests to spin up services. Do not run `flutter pub get`, `dart pub get`, or any package manager install commands directly on the host.

## Flutter Commands

Run these inside the appropriate container:

```bash
dart analyze                        # Static analysis
dart format .                       # Format code
dart format --set-exit-if-changed . # Check formatting (used in pre-commit)
flutter test                        # Run all tests
flutter test test/path/to_test.dart # Run a single test file
flutter build apk                   # Build Android
flutter build ios                   # Build iOS
```

## Architecture

The app follows **Clean Architecture** with three layers:

**Presentation** — Flutter UI: `MapScreen`, `SearchScreen`, `NavigationScreen` with Riverpod providers. No direct HTTP or SQLite access.

**Domain** — Business logic entities (`Route`, `BikeWay`, `Location`) and use cases (`GetBikeWayUseCase`). No Flutter dependencies. Repository interfaces defined here.

**Data** — Concrete implementations: `ValhallRoutingRepository` (routes via Valhalla), `SofiaplanRepository` (bike lane GeoJSON), `LocalCacheDataSource` (SQLite).

### Request Flow

```
User input (address or GPS)
  → NavigationScreen / SearchScreen
  → GetBikeWayUseCase (domain)
  → ValhallRoutingRepository (data)
  → Valhalla engine (Docker)
  → Route prioritizing: bike lanes → parks → quiet streets
  → MapScreen via Riverpod state
  → flutter_map PolylineLayer rendering
```

### Routing Priority

Routes prefer bike lanes → parks → quiet streets. Avoid boulevards and major roads. Valhalla handles dynamic costing and rerouting on deviation.

### Offline Support

`sofia.mbtiles` (~50–100 MB) provides offline vector tile rendering via `vector_map_tiles_mbtiles`. SQLite caches routes, bike lane data, and user favorites locally.

## CI Pipeline

Defined in [.github/workflows/checks.yml](.github/workflows/checks.yml), runs on every push and pull request. Three parallel jobs:

| Job | Tool | Blocks on |
|-----|------|-----------|
| **Secret Scanning** | `gitleaks/gitleaks-action@v2` (full history scan) | API keys, JWT tokens, private keys, hardcoded credentials |
| **Debug Artifacts** | `grep` | `print()` statements; `TODO`/`FIXME` with hardcoded string literals |
| **Dart Lint & Format** | `ghcr.io/cirruslabs/flutter:stable` container | `dart analyze --fatal-infos` errors; `dart format --set-exit-if-changed` violations |

No local Dart or Flutter installation required — the lint/format job runs entirely inside the Flutter container on the GitHub runner.

## Documentation

- [README.md](README.md) — Project overview (Bulgarian)
- [DOCUMENTATION.md](DOCUMENTATION.md) — Full design docs including architecture diagrams, DB schema, UML (Bulgarian)
- [context/](context/) — Project specification notes
- Architecture diagrams: [app-architecture.png](app-architecture.png), [clean-architecture.png](clean-architecture.png), [infrastructure-diagram.png](infrastructure-diagram.png), [ER-diagram.png](ER-diagram.png), [mobile-UML.png](mobile-UML.png), [backend-UML.png](backend-UML.png), [routing-UML.png](routing-UML.png)
