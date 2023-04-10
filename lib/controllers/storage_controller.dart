import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageController {
  factory StorageController() {
    return _instance;
  }

  StorageController._internal();
  static final StorageController _instance = StorageController._internal();

  Future<void> clearCache({Directory? cacheDir}) async {
    final cacheDirectory = cacheDir ?? await getTemporaryDirectory();

    cacheDirectory.listSync().forEach((element) {
      element.deleteSync(recursive: true);
    });
  }

  Future<int> getCacheSize() async {
    final cacheDirectory = await getTemporaryDirectory();

    var totalSize = 0;
    if (cacheDirectory.existsSync()) {
      cacheDirectory
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
