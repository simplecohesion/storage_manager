import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:storage_manager/core/local_file.dart';

class StorageController {
  factory StorageController() {
    return _instance;
  }

  StorageController._internal();
  static final StorageController _instance = StorageController._internal();

  Future<void> clearCache({Directory? cacheDir}) async {
    final cacheDirectory = cacheDir ?? await getTemporaryDirectory();
    final downloadDir = LocalFile.getDownloadDirectory(cacheDirectory);

    downloadDir.listSync().forEach((element) {
      element.deleteSync();
    });
  }

  Future<int> getCacheSize() async {
    final cacheDirectory = await getTemporaryDirectory();
    final downloadDir = LocalFile.getDownloadDirectory(cacheDirectory);

    var totalSize = 0;
    if (downloadDir.existsSync()) {
      downloadDir
          .listSync(recursive: true, followLinks: false)
          .forEach((FileSystemEntity entity) {
        if (entity is File) {
          totalSize += entity.lengthSync();
        }
      });
    }

    return totalSize;
  }
}
