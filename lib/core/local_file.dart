import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract class LocalFile {
  static Future<bool> fileExists(
    String localPath, {
    Directory? cacheDir,
  }) {
    final file = File(localPath);
    // ignore: unnecessary_await_in_return
    return file.exists();
  }

  static Future<DateTime?> lastModified(String localPath) async {
    final fileExists = await LocalFile.fileExists(localPath);
    if (!fileExists) {
      return null;
    }
    final file = File(localPath);
    try {
      // return file.statSync().changed;
      return await file.lastModified();
    } catch (e) {
      return null;
    }
  }

  static Future<String> getPath({
    required String storagePath,
    Directory? cacheDir,
  }) async {
    final cacheDirectory = cacheDir ?? await getTemporaryDirectory();
    final downloadDir = await getDownloadDirectory(cacheDirectory);
    final fileName = _getFileNameFromStoragePath(storagePath);
    final filePath = '${downloadDir.path}/$fileName';
    return filePath;
  }

  static Future<Directory> getDownloadDirectory(Directory cacheDir) async {
    final downloadDir = Directory('${cacheDir.path}/files');
    final isDirExist = await downloadDir.exists();
    if (!isDirExist) {
      downloadDir.createSync(recursive: true);
    }
    return downloadDir;
  }

  static String _getFileNameFromStoragePath(String storagePath) =>
      storagePath.substring(storagePath.lastIndexOf('/') + 1);
}
