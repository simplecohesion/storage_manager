import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' show FirebaseException;
import 'package:flutter/foundation.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:storage_manager/core/file_downloader.dart';
import 'package:storage_manager/core/local_file.dart';
import 'package:storage_manager/enums/storage_file_status.dart';
import 'package:storage_manager/models/storage_file_snapshot.dart';

class StorageFileController {
  StorageFileController({
    required this.snapshot,
    required this.onSnapshotChanged,
  });

  /// When snapshot changes this function will called and give you the new
  /// snapshot
  final void Function(StorageFileSnapshot) onSnapshotChanged;

  /// Provide us a 3 Variable
  /// 1 - Status : It's the status of the process (Success, Loading, Error).
  /// 2 - Progress : The progress if the file is downloading.
  /// 3 - FilePath : When Status is Success the FilePath won't be null;
  StorageFileSnapshot snapshot;

  DownloadTask? _downloadTask;
  bool _isDisposed = false;

  /// Detaches listeners from any in-progress download task.
  ///
  /// This should be called before starting a new download to prevent
  /// stale updates from previous downloads and avoid listener leaks.
  ///
  /// Note: do not cancel here — downloads may be shared across multiple
  /// controllers via the shared [DownloadManager] (keyed by URL).
  void _cleanupCurrentTask() {
    final task = _downloadTask;
    if (task != null) {
      task.progress.removeListener(progressUpdated);
      task.status.removeListener(statusUpdated);
      _downloadTask = null;
    }
  }

  @visibleForTesting
  DownloadTask? get downloadTaskForTesting => _downloadTask;

  @visibleForTesting
  set downloadTaskForTesting(DownloadTask? task) => _downloadTask = task;

  /// Try to get file path from cache,
  /// If it's not exists it will download the file and cache it.
  Future<void> getFile(
    String storagePath, {
    Directory? cacheDir,
    DateTime? updateDate,
  }) {
    return _getFileInternal(
      storagePath,
      cacheDir: cacheDir,
      updateDate: updateDate,
    ).catchError((Object _, StackTrace __) {
      if (_isDisposed) return;
      snapshot = snapshot.copyWith(
        status: StorageFileStatus.error,
      );
      onSnapshotChanged(snapshot);
    });
  }

  Future<void> _getFileInternal(
    String storagePath, {
    Directory? cacheDir,
    DateTime? updateDate,
  }) async {
    try {
      if (_isDisposed) return;

      // Clean up any previous download task before starting a new one
      _cleanupCurrentTask();

      // Get the filepath to the local cache
      // TODO(roscoemccord): Confirm behavior for web.
      final filePath = await LocalFile.instance.getPath(
        storagePath: storagePath,
        cacheDir: cacheDir,
      );

      // Check if the file exists
      final fileExists = await LocalFile.instance.fileExists(filePath);

      // Check if the file needs to be updated (redownloaded)
      // By comparing the supplied update date to the last modified date of
      // the local file
      var needsUpdate = false;
      if (fileExists && updateDate != null) {
        final lastModified = await LocalFile.instance.lastModified(filePath);
        if (lastModified != null) {
          needsUpdate = lastModified.isBefore(updateDate);
        } else {
          needsUpdate = true;
        }
      }

      // If the file exists and doesn't need to be updated, return the path
      // to the local cached file
      if (fileExists && !needsUpdate) {
        snapshot = snapshot.copyWith(
          filePath: filePath,
          status: StorageFileStatus.success,
        );
        onSnapshotChanged(snapshot);
        return;
      }

      // If the file doesn't exist or needs to be updated, download the file
      // and cache it

      if (_isDisposed) return;

      // Get the download task
      _downloadTask = await FileDownloader.downloadFile(
        storagePath,
        cacheDir: cacheDir,
      );

      if (_isDisposed) return;

      // Add listeners to the download task
      final task = _downloadTask;
      task?.progress.addListener(progressUpdated);
      task?.status.addListener(statusUpdated);

      // Sync snapshot with the current task state in case the status already
      // changed before listeners were attached.
      statusUpdated();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        snapshot = snapshot.copyWith(
          status: StorageFileStatus.missing,
        );
      } else {
        snapshot = snapshot.copyWith(
          status: StorageFileStatus.error,
        );
      }
      onSnapshotChanged(snapshot);
    } on Exception catch (_) {
      snapshot = snapshot.copyWith(
        status: StorageFileStatus.error,
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

    final status = task.status;

    if (status.value == DownloadStatus.completed) {
      snapshot = snapshot.copyWith(
        filePath: task.request.path,
        status: StorageFileStatus.success,
      );
      onSnapshotChanged(snapshot);
    }

    if (status.value == DownloadStatus.downloading) {
      snapshot = snapshot.copyWith(
        status: StorageFileStatus.loading,
      );
      onSnapshotChanged(snapshot);
    }

    if (status.value == DownloadStatus.failed) {
      snapshot = snapshot.copyWith(
        status: StorageFileStatus.error,
      );
      onSnapshotChanged(snapshot);
    }

    if (status.value == DownloadStatus.canceled) {
      snapshot = snapshot.copyWith(
        status: StorageFileStatus.error,
      );
      onSnapshotChanged(snapshot);
    }
  }

  /// Disposes of this controller and cleans up any active download.
  ///
  /// After calling dispose, no further snapshot updates will be emitted.
  void dispose() {
    _isDisposed = true;
    _cleanupCurrentTask();
  }
}
