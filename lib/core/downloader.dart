import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' show FirebaseStorage;
import 'package:flutter/foundation.dart';
import 'local_file.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';

abstract class Downloader {
  static Future<DownloadTask?> downloadFile(
    String storagePath, {
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

      return await dl.addDownload(url, localFilePath);
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
      return null;
    }
  }
}
