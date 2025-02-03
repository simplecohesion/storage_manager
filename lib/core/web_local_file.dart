import 'dart:async';
import 'package:file_system_access_api/file_system_access_api.dart';
import 'package:flutter/foundation.dart';
import 'package:storage_manager/core/local_file.dart';
import 'package:storage_manager/core/opfs_helper.dart';
import 'package:universal_io/io.dart';

class WebLocalFile implements LocalFile {
  @override
  Future<bool> fileExists(String localPath) async {
    try {
      final fileHandle = await OpfsHelper.getFileHandle(localPath);
      return fileHandle != null;
    } on NotFoundError {
      return false;
    } catch (e) {
      debugPrint('Error in fileExists: $e');
      return false;
    }
  }

  @override
  Future<DateTime?> lastModified(String localPath) async {
    try {
      final fileHandle = await OpfsHelper.getFileHandle(localPath);
      if (fileHandle == null) {
        return null;
      }
      final file = await fileHandle.getFile();
      final lastModifiedTimestamp = file.lastModified;
      if (lastModifiedTimestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(lastModifiedTimestamp);
      }
      return null;
    } catch (e) {
      debugPrint('Error in lastModified: $e');
      return null;
    }
  }

  @override
  Future<String> getPath({
    required String storagePath,
    Directory? cacheDir,
  }) async {
    try {
      final fileName = storagePath.split('/').last;
      return fileName;
    } catch (e) {
      debugPrint('Error in getPath: $e');
      return '';
    }
  }

  @override
  Future<Directory> getDownloadDirectory(Directory cacheDir) async {
    throw UnimplementedError();
  }
}
