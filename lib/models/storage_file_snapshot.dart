import 'package:flutter/foundation.dart';

import 'package:storage_manager/storage_manager.dart';

/// Immutable snapshot of a storage file's download state.
///
/// This DTO provides the current status, progress, and file path
/// for a file being managed by the storage system.
@immutable
class StorageFileSnapshot {
  /// Creates a new storage file snapshot.
  ///
  /// All parameters are required, but [filePath] and [progress]
  /// can be null when the file hasn't been downloaded yet.
  const StorageFileSnapshot({
    required this.status,
    required this.filePath,
    required this.progress,
  });

  /// Status of the download process.
  final StorageFileStatus status;

  /// Local path to the downloaded file, or null if not yet available.
  final String? filePath;

  /// Download progress from 0.0 to 1.0, or null if not downloading.
  final double? progress;

  /// Creates a copy of this snapshot with the specified fields replaced.
  ///
  /// Use the `clearFilePath` and `clearProgress` flags to explicitly
  /// set those fields to null.
  StorageFileSnapshot copyWith({
    StorageFileStatus? status,
    String? filePath,
    bool clearFilePath = false,
    double? progress,
    bool clearProgress = false,
  }) {
    return StorageFileSnapshot(
      status: status ?? this.status,
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      progress: clearProgress ? null : (progress ?? this.progress),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageFileSnapshot &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          filePath == other.filePath &&
          progress == other.progress;

  @override
  int get hashCode => Object.hash(status, filePath, progress);

  @override
  String toString() =>
      'StorageFileSnapshot(status: $status, filePath: $filePath, '
      'progress: $progress)';
}
