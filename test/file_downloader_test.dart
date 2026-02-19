import 'dart:io';

import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_manager/core/file_downloader.dart';

void main() {
  group('FileDownloader.cancelDownload', () {
    setUp(() {
      // Ensure no downloads start during these unit tests.
      DownloadManager(maxConcurrentTasks: 0);
    });

    tearDown(() {
      // Restore the default concurrency for any other tests.
      DownloadManager(maxConcurrentTasks: 4);
    });

    test('does not cancel completed tasks', () async {
      final tempDir =
          Directory.systemTemp.createTempSync('storage_manager_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final url =
          'https://example.com/${DateTime.now().microsecondsSinceEpoch}';
      final task = await DownloadManager().addDownload(url, tempDir.path);

      expect(task, isNotNull);
      task!.status.value = DownloadStatus.completed;

      FileDownloader.cancelDownload(url);

      expect(task.status.value, DownloadStatus.completed);

      await DownloadManager().removeDownload(url);
    });

    test('cancels queued tasks', () async {
      final tempDir =
          Directory.systemTemp.createTempSync('storage_manager_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final url =
          'https://example.com/${DateTime.now().microsecondsSinceEpoch}';
      final task = await DownloadManager().addDownload(url, tempDir.path);

      expect(task, isNotNull);
      expect(task!.status.value, DownloadStatus.queued);

      FileDownloader.cancelDownload(url);
      await Future<void>.delayed(Duration.zero);

      expect(task.status.value, DownloadStatus.canceled);

      await DownloadManager().removeDownload(url);
    });
  });
}
