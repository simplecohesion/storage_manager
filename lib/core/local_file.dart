import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:storage_manager/core/native_local_file.dart';
import 'package:storage_manager/core/web_local_file.dart';

/// A platform-agnostic interface for handling local file operations.
///
/// This abstract class provides a common API for file operations that work across
/// both web and native platforms. It uses the factory singleton pattern to return
/// the appropriate implementation ([WebLocalFile] or [NativeLocalFile]) based on
/// the platform.
abstract class LocalFile {
  // Internal constructor
  LocalFile._();

  /// Checks if a file exists at the specified local path.
  ///
  /// Returns `true` if the file exists, `false` otherwise.
  Future<bool> fileExists(String localPath);

  /// Gets the last modification timestamp of a file.
  ///
  /// Returns `null` if the file doesn't exist or the timestamp cannot be retrieved.
  Future<DateTime?> lastModified(String localPath);

  /// Resolves the full path for a file based on the storage path.
  ///
  /// [storagePath] is the relative path within the storage system.
  /// [cacheDir] is an optional directory for caching files (typically used in native platforms).
  Future<String> getPath({
    required String storagePath,
    Directory? cacheDir,
  });

  /// Gets the directory used for downloading files.
  ///
  /// [cacheDir] is the base cache directory to use for downloads.
  Future<Directory> getDownloadDirectory(Directory cacheDir);

  static LocalFile? _instance;

  /// Returns the singleton instance of [LocalFile].
  ///
  /// Creates and returns a [WebLocalFile] for web platforms or
  /// [NativeLocalFile] for native platforms on first access.
  static LocalFile get instance {
    if (_instance != null) {
      return _instance!;
    }

    _instance = kIsWeb ? WebLocalFile() : NativeLocalFile();

    return _instance!;
  }
}
