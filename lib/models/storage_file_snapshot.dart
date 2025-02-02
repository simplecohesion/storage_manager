import 'package:flutter/foundation.dart';

import 'package:storage_manager/storage_manager.dart';

/// DTO Class make it easy to fetch process snapshot ASAP.
@immutable
class StorageFileSnapshot {
  const StorageFileSnapshot({
    this.filePath,
    this.progress,
    this.status = StorageFileStatus.loading,
  });

  /// Status of download process (Success, Error, Loading)
  final StorageFileStatus status;

  /// File that you have downloaded.
  final String? filePath;

  /// Progress of download process.
  final double? progress;

  StorageFileSnapshot copyWith({
    String? filePath,
    double? progress,
    StorageFileStatus? status,
  }) {
    return StorageFileSnapshot(
      filePath: filePath ?? this.filePath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StorageFileSnapshot &&
        other.status == status &&
        other.filePath == filePath &&
        other.progress == progress;
  }

  @override
  int get hashCode => Object.hash(status, filePath, progress);
}
