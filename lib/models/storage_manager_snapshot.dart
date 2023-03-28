import 'package:flutter/foundation.dart';

import '../storage_manager.dart';

/// DTO Class make it easy to fetch process snapshot ASAP.
@immutable
class StorageManagerSnapshot {
  /// Status of download process (Success, Error, Loading)
  final StorageManagerStatus status;

  /// File that you have downloaded.
  final String? filePath;

  /// Progress of download process.
  final double? progress;

  const StorageManagerSnapshot({
    required this.filePath,
    required this.progress,
    required this.status,
  });

  StorageManagerSnapshot copyWith({
    String? filePath,
    double? progress,
    StorageManagerStatus? status,
  }) {
    return StorageManagerSnapshot(
      filePath: filePath ?? this.filePath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
    );
  }
}
