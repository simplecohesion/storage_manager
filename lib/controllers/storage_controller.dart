import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:storage_manager/core/local_file.dart';

// TODO(roscoemccord): Consider an abstract web/native implementation.
class StorageController {
  factory StorageController() {
    return _instance;
  }

  StorageController._internal();
  static final StorageController _instance = StorageController._internal();

  Future<void> clearCache({Directory? cacheDir}) async {
    final cacheDirectory = cacheDir ?? await getTemporaryDirectory();
    final downloadDir =
        await LocalFile.instance.getDownloadDirectory(cacheDirectory);

    await downloadDir.list().forEach((element) {
      element.deleteSync();
    });
  }

  Future<int> getCacheSize() async {
    // TODO(roscoemccord): Implement for web; may need a kIsWeb conditional.
    final cacheDirectory = await getTemporaryDirectory();
    final downloadDir =
        await LocalFile.instance.getDownloadDirectory(cacheDirectory);

    var totalSize = 0;
    if (await downloadDir.exists()) {
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
