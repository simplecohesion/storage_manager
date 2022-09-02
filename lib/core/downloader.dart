import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'local_file.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';

abstract class Downloader {
  static Future<void> downloadFile(
    String storagePath, {
    required Function(double progress) onProgress,
    Directory? cacheDir,
  }) async {
    try {
      final localFilePath = await LocalFile.getPath(
        storagePath: storagePath,
        cacheDir: cacheDir,
      );

      final url =
          await FirebaseStorage.instance.ref(storagePath).getDownloadURL();

      final dl = DownloadManager();
      final task = await dl.addDownload(url, localFilePath);

      task?.progress.addListener(() {
        onProgress(task.progress.value);
      });
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
  }
}
