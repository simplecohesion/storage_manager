import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:storage_manager/core/local_file.dart';

class NativeLocalFile implements LocalFile {
  @override
  Future<bool> fileExists(String localPath) {
    final file = File(localPath);
    return file.exists();
  }

  @override
  Future<DateTime?> lastModified(String localPath) async {
    final file = File(localPath);
    try {
      return await file.lastModified();
    } on FileSystemException {
      // File may have been deleted between exists check and this call
      return null;
    }
  }

  @override
  Future<String> getPath({
    required String storagePath,
    Directory? cacheDir,
  }) async {
    final cacheDirectory = cacheDir ?? await getTemporaryDirectory();
    final downloadDir = await getDownloadDirectory(cacheDirectory);
    final fileName = _getFileNameFromStoragePath(storagePath);
    final filePath = '${downloadDir.path}/$fileName';
    return filePath;
  }

  @override
  Future<Directory> getDownloadDirectory(Directory cacheDir) async {
    final downloadDir = Directory('${cacheDir.path}/files');
    final isDirExist = await downloadDir.exists();
    if (!isDirExist) {
      downloadDir.createSync(recursive: true);
    }
    return downloadDir;
  }

  /// Creates a unique local filename from a storage path.
  ///
  /// Uses a hash of the full path combined with the original filename
  /// to avoid collisions when different storage paths have the same filename.
  String _getFileNameFromStoragePath(String storagePath) {
    final fileName = storagePath.substring(storagePath.lastIndexOf('/') + 1);
    final hash = _fnv1a64Hex(storagePath);
    return '${hash}_$fileName';
  }

  String _fnv1a64Hex(String input) {
    // Stable (process-independent) 64-bit FNV-1a hash.
    const fnvOffsetBasisHigh = 0xcbf29ce4;
    const fnvOffsetBasisLow = 0x84222325;
    const fnvOffsetBasis = (fnvOffsetBasisHigh << 32) | fnvOffsetBasisLow;
    const fnvPrime = 0x100000001b3;
    const mask64 = (0xFFFFFFFF << 32) | 0xFFFFFFFF;

    var hash = fnvOffsetBasis;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & mask64;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }
}
