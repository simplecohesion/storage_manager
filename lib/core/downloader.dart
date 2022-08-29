import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'local_file.dart';

abstract class Downloader {
  static Future<void> downloadFile(
    String storagePath, {
    required Function(int progress, int total) onProgress,
    Directory? cacheDir,
  }) async {
    try {
      final localFilePath = await LocalFile.getPath(
        storagePath: storagePath,
        cacheDir: cacheDir,
      );

      final url =
          await FirebaseStorage.instance.ref(storagePath).getDownloadURL();

      await Dio().download(
        url,
        localFilePath,
        onReceiveProgress: onProgress,
      );
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
  }
}
