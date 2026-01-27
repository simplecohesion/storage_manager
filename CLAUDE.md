# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Run static analysis (uses very_good_analysis)
dart format .            # Format all Dart files
flutter test             # Run unit tests
flutter test --coverage  # Run tests with coverage report
```

## Architecture Overview

This is a Flutter package for managing local file storage with Firebase Storage integration. It handles downloading files from Firebase, caching them locally, and tracking download progress.

### Core Components

**Platform Abstraction (`lib/core/`)**
- `LocalFile` - Abstract singleton interface for platform-agnostic file operations
- `NativeLocalFile` / `WebLocalFile` - Platform-specific implementations selected at runtime via `kIsWeb`
- `FileDownloader` - Handles Firebase Storage downloads using `flutter_download_manager`

**State Management**
- `StorageFileController` - Manages file download lifecycle with `DownloadTask` listeners
- `StorageFileSnapshot` - Immutable DTO containing status, progress, and file path
- `StorageFileStatus` - Enum: `success`, `loading`, `error`, `missing`

**Widget Layer**
- `StorageFileBuilder` - StatefulWidget that wraps the download flow; provides `StorageFileSnapshot` to builder callback

### Data Flow

1. `StorageFileBuilder` creates a `StorageFileController` with a callback
2. Controller checks local cache via `LocalFile.instance`
3. If file missing or outdated, `FileDownloader` fetches from Firebase Storage
4. Progress/status updates flow through `DownloadTask` listeners → `StorageFileSnapshot` → widget rebuild

### Public API

Exports are defined in `lib/storage_manager.dart`. When adding new public APIs, update this file.

## Code Style

- Uses `very_good_analysis` lint rules (see `analysis_options.yaml`)
- Disabled rules: `public_member_api_docs`, `lines_longer_than_80_chars`, `avoid_final_parameters`, `avoid_slow_async_io`
- Keep `dart:io` usage isolated in platform-specific files under `lib/core/`

## Commit Style

Follow conventional commits: `feat:`, `fix:`, `chore(deps):`, `style:`. Use `feat!:`/`fix!:` for breaking changes.
