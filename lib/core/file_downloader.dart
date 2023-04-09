import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' show FirebaseStorage;
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:storage_manager/core/local_file.dart';

abstract class FileDownloader {
  static Future<DownloadTask?> downloadFile(
    String storagePath, {
    Directory? cacheDir,
  }) async {
    final localFilePath = await LocalFile.getPath(
      storagePath: storagePath,
      cacheDir: cacheDir,
    );

    final storageRef = FirebaseStorage.instance.ref(storagePath);
    final url = await storageRef.getDownloadURL();

    final dl = DownloadManager(maxConcurrentTasks: 4);

    return dl.addDownload(url, localFilePath);
  }
}
