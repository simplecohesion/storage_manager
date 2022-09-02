import 'dart:io';

import 'package:flutter_download_manager/flutter_download_manager.dart';

import '../core/downloader.dart';
import '../core/local_file.dart';
import '../enums/storage_manager_status.dart';
import '../models/storage_manager_snapshot.dart';

class StorageManagerController {
  StorageManagerController({
    required StorageManagerSnapshot snapshot,
    required Function(StorageManagerSnapshot) onSnapshotChanged,
  }) {
    _onSnapshotChanged = onSnapshotChanged;
    _snapshot = snapshot;
  }

  /// When snapshot changes this function will called and give you the new snapshot
  late final Function(StorageManagerSnapshot) _onSnapshotChanged;

  /// Provide us a 3 Variable
  /// 1 - Status : It's the status of the process (Success, Loading, Error).
  /// 2 - Progress : The progress if the file is downloading.
  /// 3 - FilePath : When Status is Success the FilePath won't be null;
  late final StorageManagerSnapshot _snapshot;

  DownloadTask? _task;
  String? _filepath;
  bool _isDisposed = false;

  /// Try to get file path from cache,
  /// If it's not exists it will download the file and cache it.
  Future<void> getFile(String storagePath, {Directory? cacheDir}) async {
    try {
      String filePath =
          await LocalFile.getPath(storagePath: storagePath, cacheDir: cacheDir);

      bool fileExists = await LocalFile.fileExists(filePath);
      if (fileExists) {
        _snapshot.filePath = filePath;
        _snapshot.status = StorageManagerStatus.success;
        _onSnapshotChanged(_snapshot);
        return;
      }

      _filepath = filePath;
      _task = await Downloader.downloadFile(
        storagePath,
      );

      _task?.progress.addListener(progressUpdated);
    } catch (error) {
      _onSnapshotChanged(_snapshot..status = StorageManagerStatus.error);
    }
  }

  void progressUpdated() {
    if (_isDisposed || _filepath == null) return;

    final progress = _task?.progress.value ?? 1;
    if (progress == 1) {
      _snapshot.filePath = _filepath!;
      _snapshot.status = StorageManagerStatus.success;
      _onSnapshotChanged(_snapshot);
      return;
    }
    _onSnapshotChanged(_snapshot..progress = (progress));
  }

  void dispose() {
    _isDisposed = true;
    _task?.progress.removeListener(progressUpdated);
  }
}
