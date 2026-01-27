# Gemini Project Context: `storage_manager`

## Project Overview

`storage_manager` is a Flutter package designed to simplify file downloading and local storage management, with specific integration for Firebase Storage. It abstracts platform-specific file operations, providing a unified API for both web and native (iOS/Android/Desktop) platforms.

### Key Features
*   **Platform Agnostic:** Uses `LocalFile` abstraction to handle file system differences between Web and Native platforms.
*   **Firebase Integration:** Intended to work with `firebase_storage` for fetching files.
*   **Reactive UI:** Provides `StorageFileBuilder` widget to easily build UIs based on download status (loading, success, error) and progress.
*   **Cache Management:** Includes `StorageController` for managing global cache size and clearing cached files.

### Architecture
*   **Core (`lib/core/`):** Contains the `LocalFile` abstract class and its implementations (`WebLocalFile`, `NativeLocalFile`). This is the bridge to the underlying file system.
*   **Controllers (`lib/controllers/`):**
    *   `StorageController`: Singleton for global operations like clearing cache or checking cache size.
    *   `StorageFileController`: Manages the state and logic for individual file downloads/retrievals.
*   **Widgets (`lib/widgets/`):** `StorageFileBuilder` is the main consumer-facing widget.
*   **Models/Enums:** `StorageFileSnapshot` (DTO) and `StorageFileStatus`.

## Building and Running

This is a Flutter package. Use the standard Flutter toolchain.

*   **Install Dependencies:**
    ```bash
    flutter pub get
    ```
    *Note: This project depends on `flutter_download_manager` via a Git dependency.*

*   **Run Static Analysis:**
    ```bash
    flutter analyze
    ```
    *The project uses `very_good_analysis` for strict linting rules.*

*   **Run Tests:**
    ```bash
    flutter test
    ```

*   **Format Code:**
    ```bash
    dart format .
    ```

## Development Conventions

*   **Linting:** Adhere strictly to `very_good_analysis` rules. Run `flutter analyze` frequently.
*   **Code Style:**
    *   **Formatting:** 2-space indentation, trailing commas.
    *   **Naming:** `snake_case` for files, `PascalCase` for classes, `camelCase` for members.
*   **Platform Safety:** Be careful with `dart:io` imports. Use the `LocalFile` abstraction in `lib/core/` to ensure web compatibility. Do not import `dart:io` in files that are not guarded by platform checks or within the native implementation.
*   **Public API:** The entry point is `lib/storage_manager.dart`. Only export public-facing members here.
*   **Commits:** Follow conventional commits (e.g., `feat:`, `fix:`, `chore:`).

## Key Files

*   `pubspec.yaml`: Project dependencies and metadata.
*   `lib/storage_manager.dart`: Public library export file.
*   `lib/widgets/storage_manager_builder.dart`: Main UI widget.
*   `lib/core/local_file.dart`: Abstract base for platform-specific file handling.
*   `lib/controllers/storage_controller.dart`: Global cache management logic.
*   `test/storage_manager_test.dart`: Unit tests.
