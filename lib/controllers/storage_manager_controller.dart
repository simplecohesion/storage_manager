import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' show FirebaseException;
import 'package:flutter_download_manager/flutter_download_manager.dart';

import '../core/download_manager.dart';
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

  DownloadTask? _downloadTask;
  bool _isDisposed = false;

  /// Try to get file path from cache,
  /// If it's not exists it will download the file and cache it.
  Future<void> getFile(
    String storagePath, {
    Directory? cacheDir,
    DateTime? updateDate,
  }) async {
    try {
      String filePath =
          await LocalFile.getPath(storagePath: storagePath, cacheDir: cacheDir);

      bool fileExists = await LocalFile.fileExists(filePath);
      bool needsUpdate = false;

      if (fileExists && updateDate != null) {
        final lastModified = await LocalFile.lastModified(filePath);
        if (lastModified != null) {
          needsUpdate = lastModified.isBefore(updateDate);
        } else {
          needsUpdate = true;
        }
      }

      if (fileExists && !needsUpdate) {
        _snapshot.filePath = filePath;
        _snapshot.status = StorageManagerStatus.success;
        _onSnapshotChanged(_snapshot);
        return;
      }

      _downloadTask = await Downloader.downloadFile(
        storagePath,
      );

      _downloadTask?.progress.addListener(progressUpdated);
      _downloadTask?.status.addListener(statusUpdated);
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        _onSnapshotChanged(_snapshot..status = StorageManagerStatus.missing);
      } else {
        _onSnapshotChanged(_snapshot..status = StorageManagerStatus.error);
      }
    } catch (error) {
      _onSnapshotChanged(_snapshot..status = StorageManagerStatus.error);
    }
  }

  void progressUpdated() {
    if (_isDisposed) return;

    final task = _downloadTask;
    if (task == null) return;

    final progress = task.progress.value;

    _onSnapshotChanged(_snapshot..progress = (progress));
  }

  void statusUpdated() {
    if (_isDisposed) return;

    final task = _downloadTask;
    if (task == null) return;
    final filePath = task.request.path;

    final status = task.status;

    if (status.value == DownloadStatus.completed) {
      _snapshot.filePath = filePath;
      _snapshot.status = StorageManagerStatus.success;
      _onSnapshotChanged(_snapshot);
    }

    if (status.value == DownloadStatus.downloading) {
      _snapshot.status = StorageManagerStatus.loading;
      _onSnapshotChanged(_snapshot);
    }

    if (status.value == DownloadStatus.failed) {
      task.request.cancelToken.cancel();
      _snapshot.status = StorageManagerStatus.error;
      _onSnapshotChanged(_snapshot);
    }
  }

  void dispose() {
    _isDisposed = true;
    _downloadTask?.progress.removeListener(progressUpdated);
    _downloadTask?.status.removeListener(statusUpdated);
  }
}
