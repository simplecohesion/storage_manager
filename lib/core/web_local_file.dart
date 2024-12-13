import 'dart:io';

import 'package:storage_manager/core/local_file.dart';

class WebLocalFile implements LocalFile {
  @override
  Future<bool> fileExists(String localPath) {
    // TODO: implement fileExists
    throw UnimplementedError();
  }

  @override
  Future<Directory> getDownloadDirectory(Directory cacheDir) {
    // TODO: implement getDownloadDirectory
    throw UnimplementedError();
  }

  @override
  Future<String> getPath({required String storagePath, Directory? cacheDir}) {
    // TODO: implement getPath
    throw UnimplementedError();
  }

  @override
  Future<DateTime?> lastModified(String localPath) {
    // TODO: implement lastModified
    throw UnimplementedError();
  }
}
