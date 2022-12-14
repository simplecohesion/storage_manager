import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract class LocalFile {
  static Future<bool> fileExists(String localPath,
      {Directory? cacheDir}) async {
    final file = File(localPath);
    return await file.exists();
  }

  static Future<String> getPath(
      {required String storagePath, Directory? cacheDir}) async {
    final cacheDirectory = cacheDir ?? await getTemporaryDirectory();
    final downloadDir = await _getDownloadDirectory(cacheDirectory);
    final fileName = _getFileNameFromStoragePath(storagePath);
    final filePath = '${downloadDir.path}/$fileName';
    return filePath;
  }

  static Future<Directory> _getDownloadDirectory(Directory cacheDir) async {
    final downloadDir = Directory('${cacheDir.path}/files');
    final isDirExist = await downloadDir.exists();
    if (!isDirExist) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  static String _getFileNameFromStoragePath(String storagePath) =>
      storagePath.substring(storagePath.lastIndexOf("/") + 1);
}
