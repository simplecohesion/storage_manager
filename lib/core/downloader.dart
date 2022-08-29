import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'constants.dart';

abstract class Downloader {
  static Future<String?> downloadFile(
    String storagePath, {
    required Function(int progress, int total) onProgress,
    Directory? cacheDir,
  }) async {
    try {
      final cacheDirectory = cacheDir ?? await getTemporaryDirectory();
      final downloadDir = await _getDownloadDirectory(cacheDirectory);

      final url =
          await FirebaseStorage.instance.ref(storagePath).getDownloadURL();

      String fileName = getFileNameFromStoragePath(storagePath);
      await Dio().download(
        url,
        '${downloadDir.path}/$fileName',
        onReceiveProgress: onProgress,
      );
      final filePath = '${downloadDir.path}/$fileName';
      return filePath;
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
      return null;
    }
  }

  static Future<Directory> _getDownloadDirectory(Directory cacheDir) async {
    final downloadDir = Directory('${cacheDir.path}/files');
    final isDirExist = await downloadDir.exists();
    if (!isDirExist) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  static Future<void> clearCachedFiles(Directory? cacheDir) async {
    final cacheDirectory = cacheDir ?? await getTemporaryDirectory();
    final dir = await _getDownloadDirectory(cacheDirectory);
    await dir.delete(recursive: true);
  }
}
