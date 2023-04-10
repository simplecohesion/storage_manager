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
    return cacheDirectory.statSync().size;
  }
}
