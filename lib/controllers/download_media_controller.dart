import 'dart:io';

import '../core/downloader.dart';
import '../core/local_file.dart';
import '../enums/download_media_status.dart';
import '../models/download_media_snapshot.dart';

class DownloadMediaBuilderController {
  DownloadMediaBuilderController(
      {required DownloadMediaSnapshot snapshot,
      required Function(DownloadMediaSnapshot) onSnapshotChanged}) {
    _onSnapshotChanged = onSnapshotChanged;
    _snapshot = snapshot;
  }

  /// When snapshot changes this function will called and give you the new snapshot
  late final Function(DownloadMediaSnapshot) _onSnapshotChanged;

  /// Provide us a 3 Variable
  /// 1 - Status : It's the status of the process (Success, Loading, Error).
  /// 2 - Progress : The progress if the file is downloading.
  /// 3 - FilePath : When Status is Success the FilePath won't be null;
  late final DownloadMediaSnapshot _snapshot;

  /// Try to get file path from cache,
  /// If it's not exists it will download the file and cache it.
  Future<void> getFile(String storagePath, {Directory? cacheDir}) async {
    try {
      String filePath =
          await LocalFile.getPath(storagePath: storagePath, cacheDir: cacheDir);
      bool fileExists = await LocalFile.fileExists(filePath);
      if (fileExists) {
        _snapshot.filePath = filePath;
        _snapshot.status = DownloadMediaStatus.success;
        _onSnapshotChanged(_snapshot);
        return;
      }

      await Downloader.downloadFile(
        storagePath,
        onProgress: (progress, total) {
          _onSnapshotChanged(_snapshot..progress = (progress / total));
        },
      );

      _snapshot.filePath = filePath;
      _snapshot.status = DownloadMediaStatus.success;
      _onSnapshotChanged(_snapshot);
    } catch (error) {
      _onSnapshotChanged(_snapshot..status = DownloadMediaStatus.error);
    }
  }
}
