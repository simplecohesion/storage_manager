import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage_manager/core/file_downloader.dart';

Future<void> _waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final stopwatch = Stopwatch()..start();
  while (!predicate()) {
    if (stopwatch.elapsed > timeout) {
      throw TimeoutException('Condition was not met before timeout.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<void> _removeAllDownloads(DownloadManager manager) async {
  for (final task in manager.getAllDownloads().toList()) {
    await manager.removeDownload(task.request.url);
  }
}

int _parseRangeStart(String? rangeHeader) {
  if (rangeHeader == null) {
    return 0;
  }
  final match = RegExp(r'^bytes=(\d+)-$').firstMatch(rangeHeader);
  if (match == null) {
    return 0;
  }
  return int.parse(match.group(1)!);
}

Future<void> _writeChunked(
  HttpResponse response,
  List<int> data, {
  int start = 0,
  int chunkSize = 8192,
  Duration delay = Duration.zero,
}) async {
  for (var offset = start; offset < data.length; offset += chunkSize) {
    final end = math.min(offset + chunkSize, data.length);
    response.add(data.sublist(offset, end));
    await response.flush();
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }
}

Future<void> _closeResponseSafely(HttpResponse response) async {
  try {
    await response.close();
  } on IOException {
    // Ignore client disconnects during cancellation/pause tests.
  }
}

void main() {
  group('FileDownloader.cancelDownload', () {
    late DownloadManager manager;

    setUp(() {
      // Ensure no downloads start during these unit tests.
      manager = DownloadManager(maxConcurrentTasks: 0);
    });

    tearDown(() async {
      await _removeAllDownloads(manager);
      // Restore the default concurrency for any other tests.
      DownloadManager(maxConcurrentTasks: 4);
    });

    test('does not cancel completed tasks', () async {
      final tempDir =
          Directory.systemTemp.createTempSync('storage_manager_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final url =
          'https://example.com/${DateTime.now().microsecondsSinceEpoch}';
      final task = await manager.addDownload(url, tempDir.path);

      expect(task, isNotNull);
      task!.status.value = DownloadStatus.completed;

      FileDownloader.cancelDownload(url);

      expect(task.status.value, DownloadStatus.completed);
    });

    test('cancels queued tasks', () async {
      final tempDir =
          Directory.systemTemp.createTempSync('storage_manager_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final url =
          'https://example.com/${DateTime.now().microsecondsSinceEpoch}';
      final task = await manager.addDownload(url, tempDir.path);

      expect(task, isNotNull);
      expect(task!.status.value, DownloadStatus.queued);

      FileDownloader.cancelDownload(url);
      await Future<void>.delayed(Duration.zero);

      expect(task.status.value, DownloadStatus.canceled);
    });

    test('cancelTask delegates to URL cancellation', () async {
      final tempDir =
          Directory.systemTemp.createTempSync('storage_manager_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final url =
          'https://example.com/${DateTime.now().microsecondsSinceEpoch}';
      final task = await manager.addDownload(url, tempDir.path);

      expect(task, isNotNull);
      expect(task!.status.value, DownloadStatus.queued);

      FileDownloader.cancelTask(task);
      await Future<void>.delayed(Duration.zero);

      expect(task.status.value, DownloadStatus.canceled);
    });

    test('reuses same task for same URL and path while active', () async {
      final tempDir =
          Directory.systemTemp.createTempSync('storage_manager_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final url =
          'https://example.com/${DateTime.now().microsecondsSinceEpoch}';
      final task1 = await manager.addDownload(url, tempDir.path);
      final task2 = await manager.addDownload(url, tempDir.path);

      expect(task1, isNotNull);
      expect(identical(task1, task2), isTrue);
    });
  });

  group('DownloadManager integration', () {
    late DownloadManager manager;
    late Directory tempDir;
    HttpServer? server;

    setUp(() async {
      manager = DownloadManager(maxConcurrentTasks: 1);
      tempDir = await Directory.systemTemp.createTemp('storage_manager_dl_');
    });

    tearDown(() async {
      await _removeAllDownloads(manager);
      await server?.close(force: true);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      DownloadManager(maxConcurrentTasks: 4);
    });

    test('downloads bytes from local server to directory path', () async {
      final payload = utf8.encode('storage-manager download integration');

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) async {
        if (request.uri.path == '/file.txt') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.text;
          request.response.contentLength = payload.length;
          request.response.add(payload);
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await _closeResponseSafely(request.response);
      });

      final url = 'http://${server!.address.host}:${server!.port}/file.txt';
      final task = await manager.addDownload(url, tempDir.path);

      expect(task, isNotNull);
      final status = await task!.whenDownloadComplete(
        timeout: const Duration(seconds: 10),
      );
      expect(status, DownloadStatus.completed);
      expect(task.progress.value, 1.0);

      final outputFile = File(
        '${tempDir.path}${Platform.pathSeparator}file.txt',
      );
      expect(await outputFile.exists(), isTrue);
      expect(await outputFile.readAsBytes(), payload);
    });

    test('downloads bytes to explicit file path', () async {
      final payload = List<int>.generate(4096, (i) => (i * 11) % 255);

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) async {
        if (request.uri.path == '/explicit.bin') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.binary;
          request.response.contentLength = payload.length;
          request.response.add(payload);
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await _closeResponseSafely(request.response);
      });

      final url = 'http://${server!.address.host}:${server!.port}/explicit.bin';
      final outputPath =
          '${tempDir.path}${Platform.pathSeparator}deep${Platform.pathSeparator}explicit.bin';
      final task = await manager.addDownload(url, outputPath);

      expect(task, isNotNull);
      final status = await task!.whenDownloadComplete(
        timeout: const Duration(seconds: 10),
      );
      expect(status, DownloadStatus.completed);

      final outputFile = File(outputPath);
      expect(await outputFile.exists(), isTrue);
      expect(await outputFile.readAsBytes(), payload);
    });

    test('marks task as failed when server returns error response', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) async {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('server error');
        await _closeResponseSafely(request.response);
      });

      final url = 'http://${server!.address.host}:${server!.port}/fail.bin';
      final outputPath =
          '${tempDir.path}${Platform.pathSeparator}failed${Platform.pathSeparator}fail.bin';
      final task = await manager.addDownload(url, outputPath);

      expect(task, isNotNull);
      final status = await task!.whenDownloadComplete(
        timeout: const Duration(seconds: 10),
      );
      expect(status, DownloadStatus.failed);
    });

    test('returns expected values for unknown tasks', () async {
      const unknownUrl = 'http://127.0.0.1:1/not-found.bin';

      expect(await manager.pauseDownload(unknownUrl), isFalse);
      expect(await manager.resumeDownload(unknownUrl), isFalse);
      expect(await manager.cancelDownload(unknownUrl), isFalse);
      expect(await manager.removeDownload(unknownUrl), isFalse);
      expect(manager.getDownload(unknownUrl), isNull);
      expect(manager.getBatchDownloads([unknownUrl]), [null]);
      expect(manager.getBatchDownloadProgress([unknownUrl]).value, equals(0));

      await expectLater(
        manager.whenDownloadComplete(
          unknownUrl,
          timeout: const Duration(milliseconds: 200),
        ),
        throwsA(isA<Object>()),
      );

      expect(
        await manager.whenBatchDownloadsComplete(
          [unknownUrl],
          timeout: const Duration(seconds: 1),
        ),
        isNull,
      );
    });

    test('cancels active download from local server', () async {
      final started = Completer<void>();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) async {
        if (request.uri.path == '/slow.bin') {
          if (!started.isCompleted) {
            started.complete();
          }
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.binary;

          try {
            for (var i = 0; i < 240; i++) {
              request.response.add(List<int>.filled(4096, i % 256));
              await request.response.flush();
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
          } on IOException {
            // Client cancellation is expected in this test.
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await _closeResponseSafely(request.response);
      });

      final url = 'http://${server!.address.host}:${server!.port}/slow.bin';
      final outputPath =
          '${tempDir.path}${Platform.pathSeparator}nested${Platform.pathSeparator}slow.bin';
      final task = await manager.addDownload(url, outputPath);

      expect(task, isNotNull);
      final activeTask = task!;
      await started.future.timeout(const Duration(seconds: 5));
      await _waitFor(
        () => activeTask.status.value == DownloadStatus.downloading,
      );

      FileDownloader.cancelDownload(url);
      await _waitFor(
        () => activeTask.status.value == DownloadStatus.canceled,
      );

      expect(activeTask.status.value, DownloadStatus.canceled);
      expect(activeTask.status.value, isNot(DownloadStatus.completed));
    });

    test('pauses and resumes using HTTP range support', () async {
      final payload = List<int>.generate(1024 * 512, (i) => i % 251);
      var sawRangeResumeRequest = false;
      final started = Completer<void>();

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) async {
        if (request.uri.path != '/range.bin') {
          request.response.statusCode = HttpStatus.notFound;
          await _closeResponseSafely(request.response);
          return;
        }

        if (!started.isCompleted) {
          started.complete();
        }

        final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
        final start = _parseRangeStart(rangeHeader);

        if (start > 0) {
          sawRangeResumeRequest = true;
          request.response.statusCode = HttpStatus.partialContent;
          request.response.headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes $start-${payload.length - 1}/${payload.length}',
          );
        } else {
          request.response.statusCode = HttpStatus.ok;
        }

        request.response.contentLength = payload.length - start;
        request.response.headers.contentType = ContentType.binary;

        try {
          await _writeChunked(
            request.response,
            payload,
            start: start,
            chunkSize: 4096,
            delay: const Duration(milliseconds: 2),
          );
        } on IOException {
          // Pause/cancel can interrupt connection.
        }

        await _closeResponseSafely(request.response);
      });

      final url = 'http://${server!.address.host}:${server!.port}/range.bin';
      final outputPath =
          '${tempDir.path}${Platform.pathSeparator}range${Platform.pathSeparator}range.bin';
      final task = await manager.addDownload(url, outputPath);

      expect(task, isNotNull);
      final activeTask = task!;
      await started.future.timeout(const Duration(seconds: 5));
      await _waitFor(
        () => activeTask.status.value == DownloadStatus.downloading,
      );
      await _waitFor(() => activeTask.progress.value > 0);

      final paused = await manager.pauseDownload(url);
      expect(paused, isTrue);
      await _waitFor(() => activeTask.status.value == DownloadStatus.paused);

      final partialFile = File('$outputPath.partial');
      expect(await partialFile.exists(), isTrue);

      final completion = activeTask.whenDownloadComplete(
        timeout: const Duration(seconds: 15),
      );
      final resumed = await manager.resumeDownload(url);
      expect(resumed, isTrue);

      final status = await completion;
      expect(status, DownloadStatus.completed);
      expect(activeTask.progress.value, 1.0);
      expect(sawRangeResumeRequest, isTrue);

      final outputFile = File(outputPath);
      expect(await outputFile.exists(), isTrue);
      expect(await outputFile.readAsBytes(), payload);
    });

    test('resumes when server ignores range and returns full response',
        () async {
      final payload = List<int>.generate(1024 * 384, (i) => (i * 7) % 253);
      var sawRangeHeader = false;
      final started = Completer<void>();

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) async {
        if (request.uri.path != '/ignore-range.bin') {
          request.response.statusCode = HttpStatus.notFound;
          await _closeResponseSafely(request.response);
          return;
        }

        if (!started.isCompleted) {
          started.complete();
        }

        final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
        if (rangeHeader != null) {
          sawRangeHeader = true;
        }

        // Intentionally ignore Range and always return the full file.
        request.response.statusCode = HttpStatus.ok;
        request.response.contentLength = payload.length;
        request.response.headers.contentType = ContentType.binary;

        try {
          await _writeChunked(
            request.response,
            payload,
            chunkSize: 4096,
            delay: const Duration(milliseconds: 2),
          );
        } on IOException {
          // Pause/cancel can interrupt connection.
        }

        await _closeResponseSafely(request.response);
      });

      final url =
          'http://${server!.address.host}:${server!.port}/ignore-range.bin';
      final outputPath =
          '${tempDir.path}${Platform.pathSeparator}ignore${Platform.pathSeparator}ignore-range.bin';
      final task = await manager.addDownload(url, outputPath);

      expect(task, isNotNull);
      final activeTask = task!;
      await started.future.timeout(const Duration(seconds: 5));
      await _waitFor(
        () => activeTask.status.value == DownloadStatus.downloading,
      );
      await _waitFor(() => activeTask.progress.value > 0);

      final paused = await manager.pauseDownload(url);
      expect(paused, isTrue);
      await _waitFor(() => activeTask.status.value == DownloadStatus.paused);

      final completion = activeTask.whenDownloadComplete(
        timeout: const Duration(seconds: 15),
      );
      final resumed = await manager.resumeDownload(url);
      expect(resumed, isTrue);

      final status = await completion;
      expect(status, DownloadStatus.completed);
      expect(sawRangeHeader, isTrue);

      final outputFile = File(outputPath);
      final partialFile = File('$outputPath.partial');
      final tempPartialFile = File('$outputPath.partial.temp');

      expect(await outputFile.exists(), isTrue);
      expect(await outputFile.readAsBytes(), payload);
      expect(await partialFile.exists(), isFalse);
      expect(await tempPartialFile.exists(), isFalse);
    });

    test('batch download completion and aggregate progress', () async {
      final payloadA = utf8.encode('batch-A');
      final payloadB = utf8.encode('batch-B');

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) async {
        if (request.uri.path == '/a.txt') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.text;
          request.response.contentLength = payloadA.length;
          request.response.add(payloadA);
        } else if (request.uri.path == '/b.txt') {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.text;
          request.response.contentLength = payloadB.length;
          request.response.add(payloadB);
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await _closeResponseSafely(request.response);
      });

      final baseUrl = 'http://${server!.address.host}:${server!.port}';
      final urls = ['$baseUrl/a.txt', '$baseUrl/b.txt'];
      final tasks = await manager.addBatchDownloads(urls, tempDir.path);

      expect(tasks, hasLength(2));
      expect(tasks.whereType<DownloadTask>(), hasLength(2));

      final progress = manager.getBatchDownloadProgress(urls);
      final completed = await manager.whenBatchDownloadsComplete(
        urls,
        timeout: const Duration(seconds: 10),
      );
      expect(completed, isNotNull);
      expect(
        completed!
            .every((task) => task?.status.value == DownloadStatus.completed),
        isTrue,
      );
      expect(progress.value, 1.0);

      final fileA = File('${tempDir.path}${Platform.pathSeparator}a.txt');
      final fileB = File('${tempDir.path}${Platform.pathSeparator}b.txt');
      expect(await fileA.readAsBytes(), payloadA);
      expect(await fileB.readAsBytes(), payloadB);
    });

    test('pauses and resumes batch downloads (state transitions)', () async {
      manager = DownloadManager(maxConcurrentTasks: 0);

      final urls = [
        'https://example.com/batch1-${DateTime.now().microsecondsSinceEpoch}.bin',
        'https://example.com/batch2-${DateTime.now().microsecondsSinceEpoch}.bin',
      ];

      final tasks = await manager.addBatchDownloads(urls, tempDir.path);
      final nonNullTasks = tasks.whereType<DownloadTask>().toList();
      expect(nonNullTasks, hasLength(2));
      expect(
        nonNullTasks
            .every((task) => task.status.value == DownloadStatus.queued),
        isTrue,
      );

      await manager.pauseBatchDownloads(urls);
      expect(
        nonNullTasks
            .every((task) => task.status.value == DownloadStatus.paused),
        isTrue,
      );

      await manager.resumeBatchDownloads(urls);
      expect(
        nonNullTasks.every(
          (task) => task.status.value == DownloadStatus.downloading,
        ),
        isTrue,
      );
    });

    test('cancels batch downloads', () async {
      final started = Completer<void>();

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) async {
        if (request.uri.path != '/cancel1.bin' &&
            request.uri.path != '/cancel2.bin') {
          request.response.statusCode = HttpStatus.notFound;
          await _closeResponseSafely(request.response);
          return;
        }

        if (!started.isCompleted) {
          started.complete();
        }
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.binary;

        try {
          for (var i = 0; i < 200; i++) {
            request.response.add(List<int>.filled(4096, i % 251));
            await request.response.flush();
            await Future<void>.delayed(const Duration(milliseconds: 3));
          }
        } on IOException {
          // Expected when download gets canceled.
        }
        await _closeResponseSafely(request.response);
      });

      final baseUrl = 'http://${server!.address.host}:${server!.port}';
      final urls = ['$baseUrl/cancel1.bin', '$baseUrl/cancel2.bin'];
      final tasks = await manager.addBatchDownloads(urls, tempDir.path);
      final nonNullTasks = tasks.whereType<DownloadTask>().toList();
      expect(nonNullTasks, hasLength(2));

      await started.future.timeout(const Duration(seconds: 5));
      await manager.cancelBatchDownloads(urls);

      await _waitFor(
        () => nonNullTasks.every(
          (task) => task.status.value == DownloadStatus.canceled,
        ),
      );
      expect(
        nonNullTasks
            .every((task) => task.status.value == DownloadStatus.canceled),
        isTrue,
      );
    });
  });
}
