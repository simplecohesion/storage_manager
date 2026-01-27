import 'dart:io';

import 'package:storage_manager/core/local_file.dart';

class WebLocalFile implements LocalFile {
  @override
  Future<bool> fileExists(String localPath) {
    // TODO(roscoemccord): Implement fileExists.
    throw UnimplementedError();
  }

  @override
  Future<Directory> getDownloadDirectory(Directory cacheDir) {
    // TODO(roscoemccord): Implement getDownloadDirectory.
    throw UnimplementedError();
  }

  @override
  Future<String> getPath({required String storagePath, Directory? cacheDir}) {
    // TODO(roscoemccord): Implement getPath.
    throw UnimplementedError();
  }

  @override
  Future<DateTime?> lastModified(String localPath) {
    // TODO(roscoemccord): Implement lastModified.
    throw UnimplementedError();
  }
}
