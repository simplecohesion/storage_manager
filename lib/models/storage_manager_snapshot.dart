import '../storage_manager.dart';

/// DTO Class make it easy to fetch process snapshot ASAP.
class StorageManagerSnapshot {
  /// Status of download process (Success, Error, Loading)
  late StorageManagerStatus status;

  /// File that you have downloaded.
  late String? filePath;

  /// Progress of download process.
  late double? progress;

  StorageManagerSnapshot({
    required this.filePath,
    required this.progress,
    required this.status,
  });
}
