import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' show FirebaseStorage;
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:storage_manager/core/local_file.dart';

/// Handles downloading files from Firebase Storage to local cache.
///
/// Uses a shared [DownloadManager] instance to respect concurrency limits
/// across all downloads in the application.
class FileDownloader {
  /// Shared download manager instance to enforce concurrency limits.
  static final DownloadManager _downloadManager =
      DownloadManager(maxConcurrentTasks: 4);

  /// Cancels a queued or in-progress download for the given [url].
  ///
  /// Uses [DownloadManager.cancelDownload] so the task is marked as canceled
  /// (instead of failed) and removed from the queue.
  static void cancelDownload(String url) {
    final task = _downloadManager.getDownload(url);
    if (task == null) {
      return;
    }

    final status = task.status.value;
    if (status == DownloadStatus.completed ||
        status == DownloadStatus.failed ||
        status == DownloadStatus.canceled) {
      return;
    }

    unawaited(_downloadManager.cancelDownload(url));
  }

  /// Cancels the provided [task] via the shared [DownloadManager].
  static void cancelTask(DownloadTask task) {
    cancelDownload(task.request.url);
  }

  /// Downloads a file from Firebase Storage to the local cache.
  ///
  /// [storagePath] is the path to the file in Firebase Storage.
  /// [cacheDir] is an optional directory for caching files.
  ///
  /// Returns a [DownloadTask] that can be used to track progress,
  /// or `null` if the download could not be started.
  static Future<DownloadTask?> downloadFile(
    String storagePath, {
    Directory? cacheDir,
  }) async {
    final localFilePath = await LocalFile.instance.getPath(
      storagePath: storagePath,
      cacheDir: cacheDir,
    );

    final storageRef = FirebaseStorage.instance.ref(storagePath);
    final url = await storageRef.getDownloadURL();

    return _downloadManager.addDownload(url, localFilePath);
  }
}
