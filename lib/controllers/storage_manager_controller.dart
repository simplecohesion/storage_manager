import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' show FirebaseException;
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:storage_manager/core/download_manager.dart';
import 'package:storage_manager/core/local_file.dart';
import 'package:storage_manager/enums/storage_manager_status.dart';
import 'package:storage_manager/models/storage_manager_snapshot.dart';

class StorageManagerController {
  StorageManagerController({
    required this.snapshot,
    required this.onSnapshotChanged,
  });

  /// When snapshot changes this function will called and give you the new
  /// snapshot
  final void Function(StorageManagerSnapshot) onSnapshotChanged;

  /// Provide us a 3 Variable
  /// 1 - Status : It's the status of the process (Success, Loading, Error).
  /// 2 - Progress : The progress if the file is downloading.
  /// 3 - FilePath : When Status is Success the FilePath won't be null;
  StorageManagerSnapshot snapshot;

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
      final filePath =
          await LocalFile.getPath(storagePath: storagePath, cacheDir: cacheDir);

      final fileExists = LocalFile.fileExists(filePath);
      var needsUpdate = false;

      if (fileExists && updateDate != null) {
        final lastModified = LocalFile.lastModified(filePath);
        if (lastModified != null) {
          needsUpdate = lastModified.isBefore(updateDate);
        } else {
          needsUpdate = true;
        }
      }

      if (fileExists && !needsUpdate) {
        snapshot = snapshot.copyWith(
          filePath: filePath,
          status: StorageManagerStatus.success,
        );
        onSnapshotChanged(snapshot);
        return;
      }

      _downloadTask = await Downloader.downloadFile(
        storagePath,
      );

      _downloadTask?.progress.addListener(progressUpdated);
      _downloadTask?.status.addListener(statusUpdated);
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        snapshot = snapshot.copyWith(
          status: StorageManagerStatus.missing,
        );
      } else {
        snapshot = snapshot.copyWith(
          status: StorageManagerStatus.error,
        );
      }
      onSnapshotChanged(snapshot);
    } catch (error) {
      snapshot = snapshot.copyWith(
        status: StorageManagerStatus.error,
      );
      onSnapshotChanged(snapshot);
    }
  }

  void progressUpdated() {
    if (_isDisposed) return;

    final task = _downloadTask;
    if (task == null) return;

    final progress = task.progress.value;

    snapshot = snapshot.copyWith(progress: progress);
    onSnapshotChanged(snapshot);
  }

  void statusUpdated() {
    if (_isDisposed) return;

    final task = _downloadTask;
    if (task == null) return;
    final filePath = task.request.path;

    final status = task.status;

    if (status.value == DownloadStatus.completed) {
      snapshot = snapshot.copyWith(
        filePath: filePath,
        status: StorageManagerStatus.success,
      );
      onSnapshotChanged(snapshot);
    }

    if (status.value == DownloadStatus.downloading) {
      snapshot = snapshot.copyWith(
        status: StorageManagerStatus.loading,
      );
      onSnapshotChanged(snapshot);
    }

    if (status.value == DownloadStatus.failed) {
      task.request.cancelToken.cancel();
      snapshot = snapshot.copyWith(
        status: StorageManagerStatus.error,
      );
      onSnapshotChanged(snapshot);
    }
  }

  void dispose() {
    _isDisposed = true;
    _downloadTask?.progress.removeListener(progressUpdated);
    _downloadTask?.status.removeListener(statusUpdated);
  }
}
