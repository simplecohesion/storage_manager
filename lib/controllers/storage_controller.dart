import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:storage_manager/core/local_file.dart';

// TODO: May need to make this an abstract class, and have implementations for
// web and native, like the local file
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
    // TODO: Implement for web, this may need a kisweb check conditional
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
