import 'package:path_provider/path_provider.dart';
import 'package:storage_manager/core/local_file.dart';
import 'package:universal_io/io.dart';

class NativeLocalFile implements LocalFile {
  @override
  Future<bool> fileExists(String localPath) {
    final file = File(localPath);
    return file.exists();
  }

  @override
  Future<DateTime?> lastModified(String localPath) {
    final file = File(localPath);
    return file.lastModified();
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

  String _getFileNameFromStoragePath(String storagePath) =>
      storagePath.substring(storagePath.lastIndexOf('/') + 1);
}
