import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract class LocalFile {
  static bool fileExists(
    String localPath, {
    Directory? cacheDir,
  }) {
    final file = File(localPath);
    // ignore: unnecessary_await_in_return
    return file.existsSync();
  }

  static DateTime? lastModified(String localPath) {
    final fileExists = LocalFile.fileExists(localPath);
    if (!fileExists) {
      return null;
    }
    final file = File(localPath);
    try {
      // return file.statSync().changed;
      return file.lastModifiedSync();
    } catch (e) {
      return null;
    }
  }

  static Future<String> getPath({
    required String storagePath,
    Directory? cacheDir,
  }) async {
    final cacheDirectory = cacheDir ?? await getTemporaryDirectory();
    final downloadDir = getDownloadDirectory(cacheDirectory);
    final fileName = _getFileNameFromStoragePath(storagePath);
    final filePath = '${downloadDir.path}/$fileName';
    return filePath;
  }

  static Directory getDownloadDirectory(Directory cacheDir) {
    final downloadDir = Directory('${cacheDir.path}/files');
    final isDirExist = downloadDir.existsSync();
    if (!isDirExist) {
      downloadDir.createSync(recursive: true);
    }
    return downloadDir;
  }

  static String _getFileNameFromStoragePath(String storagePath) =>
      storagePath.substring(storagePath.lastIndexOf('/') + 1);
}
