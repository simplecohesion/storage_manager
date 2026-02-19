import 'dart:async';
import 'dart:io';

import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage_manager/controllers/storage_file_controller.dart';
import 'package:storage_manager/core/local_file.dart';
import 'package:storage_manager/enums/storage_file_status.dart';
import 'package:storage_manager/models/storage_file_snapshot.dart';

class MockLocalFile extends Mock implements LocalFile {}

class MockDirectory extends Mock implements Directory {}

void main() {
  late MockLocalFile mockLocalFile;
  late List<StorageFileSnapshot> capturedSnapshots;
  late StorageFileController controller;

  setUp(() {
    mockLocalFile = MockLocalFile();
    LocalFile.instance = mockLocalFile;
    capturedSnapshots = [];
  });

  tearDown(() {
    LocalFile.instance = null;
  });

  group('StorageFileController', () {
    test('initializes with provided snapshot', () {
      const initialSnapshot = StorageFileSnapshot(
        status: StorageFileStatus.loading,
        filePath: null,
        progress: null,
      );

      controller = StorageFileController(
        snapshot: initialSnapshot,
        onSnapshotChanged: capturedSnapshots.add,
      );

      expect(controller.snapshot, equals(initialSnapshot));
    });

    group('getFile', () {
      test('returns cached file if exists and no update needed', () async {
        const initialSnapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        controller = StorageFileController(
          snapshot: initialSnapshot,
          onSnapshotChanged: capturedSnapshots.add,
        );

        when(
          () => mockLocalFile.getPath(
            storagePath: any(named: 'storagePath'),
            cacheDir: any(named: 'cacheDir'),
          ),
        ).thenAnswer((_) async => '/cache/files/test.png');

        when(
          () => mockLocalFile.fileExists('/cache/files/test.png'),
        ).thenAnswer((_) async => true);

        await controller.getFile('folder/test.png');

        expect(capturedSnapshots, hasLength(1));
        expect(capturedSnapshots.last.status, StorageFileStatus.success);
        expect(capturedSnapshots.last.filePath, '/cache/files/test.png');
      });

      test('returns cached file if newer than updateDate', () async {
        const initialSnapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        controller = StorageFileController(
          snapshot: initialSnapshot,
          onSnapshotChanged: capturedSnapshots.add,
        );

        final updateDate = DateTime(2024);
        final fileDate = DateTime(2025); // File is newer

        when(
          () => mockLocalFile.getPath(
            storagePath: any(named: 'storagePath'),
            cacheDir: any(named: 'cacheDir'),
          ),
        ).thenAnswer((_) async => '/cache/files/test.png');

        when(
          () => mockLocalFile.fileExists('/cache/files/test.png'),
        ).thenAnswer((_) async => true);

        when(
          () => mockLocalFile.lastModified('/cache/files/test.png'),
        ).thenAnswer((_) async => fileDate);

        await controller.getFile('folder/test.png', updateDate: updateDate);

        expect(capturedSnapshots, hasLength(1));
        expect(capturedSnapshots.last.status, StorageFileStatus.success);
        expect(capturedSnapshots.last.filePath, '/cache/files/test.png');
      });

      test('does nothing if controller is disposed before getFile', () async {
        const initialSnapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        controller = StorageFileController(
          snapshot: initialSnapshot,
          onSnapshotChanged: capturedSnapshots.add,
        )
          ..dispose()
          ..getFile('folder/test.png').ignore();

        // Wait for any async operations to complete
        await Future<void>.delayed(Duration.zero);

        expect(capturedSnapshots, isEmpty);
        verifyNever(
          () => mockLocalFile.getPath(
            storagePath: any(named: 'storagePath'),
            cacheDir: any(named: 'cacheDir'),
          ),
        );
      });

      test('uses custom cache directory when provided', () async {
        const initialSnapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        controller = StorageFileController(
          snapshot: initialSnapshot,
          onSnapshotChanged: capturedSnapshots.add,
        );

        final customDir = MockDirectory();

        when(
          () => mockLocalFile.getPath(
            storagePath: 'folder/test.png',
            cacheDir: customDir,
          ),
        ).thenAnswer((_) async => '/custom/files/test.png');

        when(
          () => mockLocalFile.fileExists('/custom/files/test.png'),
        ).thenAnswer((_) async => true);

        await controller.getFile('folder/test.png', cacheDir: customDir);

        verify(
          () => mockLocalFile.getPath(
            storagePath: 'folder/test.png',
            cacheDir: customDir,
          ),
        ).called(1);
      });

      test('handles non-Exception errors by emitting error snapshot', () async {
        // Regression test: LocalFile's web implementation currently throws
        // UnimplementedError (an Error). This should not escape getFile().
        const initialSnapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        controller = StorageFileController(
          snapshot: initialSnapshot,
          onSnapshotChanged: capturedSnapshots.add,
        );

        when(
          () => mockLocalFile.getPath(
            storagePath: any(named: 'storagePath'),
            cacheDir: any(named: 'cacheDir'),
          ),
        ).thenThrow(UnimplementedError());

        await controller.getFile('folder/test.png');

        expect(capturedSnapshots, hasLength(1));
        expect(capturedSnapshots.last.status, StorageFileStatus.error);
      });

      test('cleans up when getFile is called multiple times', () async {
        // Regression test: calling getFile repeatedly (e.g., from didUpdateWidget)
        // should not accumulate listeners or cause stale updates
        const initialSnapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        controller = StorageFileController(
          snapshot: initialSnapshot,
          onSnapshotChanged: capturedSnapshots.add,
        );

        // Setup mocks for first file
        when(
          () => mockLocalFile.getPath(
            storagePath: 'folder/file1.png',
            cacheDir: any(named: 'cacheDir'),
          ),
        ).thenAnswer((_) async => '/cache/files/file1.png');

        when(
          () => mockLocalFile.fileExists('/cache/files/file1.png'),
        ).thenAnswer((_) async => true);

        // Setup mocks for second file
        when(
          () => mockLocalFile.getPath(
            storagePath: 'folder/file2.png',
            cacheDir: any(named: 'cacheDir'),
          ),
        ).thenAnswer((_) async => '/cache/files/file2.png');

        when(
          () => mockLocalFile.fileExists('/cache/files/file2.png'),
        ).thenAnswer((_) async => true);

        // Call getFile for first file
        await controller.getFile('folder/file1.png');

        expect(capturedSnapshots, hasLength(1));
        expect(capturedSnapshots.last.filePath, '/cache/files/file1.png');

        // Call getFile for second file (simulating prop change in widget)
        await controller.getFile('folder/file2.png');

        expect(capturedSnapshots, hasLength(2));
        expect(capturedSnapshots.last.filePath, '/cache/files/file2.png');

        // Verify old listeners don't fire - progressUpdated/statusUpdated
        // should only emit for the current file, not old ones
        controller.progressUpdated();

        // Since there's no active download task after cache hit,
        // progressUpdated should not emit anything
        expect(capturedSnapshots, hasLength(2));
      });

      test(
        'keeps latest task when overlapping getFile calls finish out of order',
        () async {
          const initialSnapshot = StorageFileSnapshot(
            status: StorageFileStatus.loading,
            filePath: null,
            progress: null,
          );

          final firstPathCompleter = Completer<String>();
          final firstTask = DownloadTask(
            DownloadRequest(
              'https://example.com/file1.png',
              '/tmp/file1.png',
            ),
          );
          final secondTask = DownloadTask(
            DownloadRequest(
              'https://example.com/file2.png',
              '/tmp/file2.png',
            ),
          );

          controller = StorageFileController(
            snapshot: initialSnapshot,
            onSnapshotChanged: capturedSnapshots.add,
            downloadFile: (storagePath, {cacheDir}) async {
              if (storagePath == 'folder/file1.png') {
                return firstTask;
              }
              if (storagePath == 'folder/file2.png') {
                return secondTask;
              }
              return null;
            },
          );

          when(
            () => mockLocalFile.getPath(
              storagePath: 'folder/file1.png',
              cacheDir: any(named: 'cacheDir'),
            ),
          ).thenAnswer((_) => firstPathCompleter.future);

          when(
            () => mockLocalFile.getPath(
              storagePath: 'folder/file2.png',
              cacheDir: any(named: 'cacheDir'),
            ),
          ).thenAnswer((_) async => '/cache/files/file2.png');

          when(
            () => mockLocalFile.fileExists('/cache/files/file1.png'),
          ).thenAnswer((_) async => false);

          when(
            () => mockLocalFile.fileExists('/cache/files/file2.png'),
          ).thenAnswer((_) async => false);

          final firstCall = controller.getFile('folder/file1.png');
          final secondCall = controller.getFile('folder/file2.png');

          await Future<void>.delayed(Duration.zero);
          firstPathCompleter.complete('/cache/files/file1.png');
          await Future.wait([firstCall, secondCall]);

          expect(controller.downloadTaskForTesting, same(secondTask));

          secondTask.status.value = DownloadStatus.completed;
          expect(capturedSnapshots.last.status, StorageFileStatus.success);
          expect(capturedSnapshots.last.filePath, '/tmp/file2.png');

          final beforeStaleCompletion = capturedSnapshots.length;
          firstTask.status.value = DownloadStatus.completed;
          expect(capturedSnapshots, hasLength(beforeStaleCompletion));

          expect(
            capturedSnapshots
                .any((snapshot) => snapshot.filePath == '/tmp/file1.png'),
            isFalse,
          );
        },
      );

      test('redownloads when lastModified returns null', () async {
        // If lastModified is null (e.g., file deleted), it must re-download
        // instead of using the stale local cache.
        const initialSnapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        var downloadInvoked = false;
        final downloadTask = DownloadTask(
          DownloadRequest(
            'https://example.com/file.png',
            '/cache/files/redownloaded.png',
          ),
        );

        controller = StorageFileController(
          snapshot: initialSnapshot,
          onSnapshotChanged: capturedSnapshots.add,
          downloadFile: (storagePath, {cacheDir}) async {
            downloadInvoked = true;
            return downloadTask;
          },
        );

        when(
          () => mockLocalFile.getPath(
            storagePath: 'folder/test.png',
            cacheDir: any(named: 'cacheDir'),
          ),
        ).thenAnswer((_) async => '/cache/files/test.png');

        when(
          () => mockLocalFile.fileExists('/cache/files/test.png'),
        ).thenAnswer((_) async => true);

        // Simulates file deleted race condition
        when(() => mockLocalFile.lastModified('/cache/files/test.png'))
            .thenAnswer((_) async => null);

        await controller.getFile(
          'folder/test.png',
          updateDate: DateTime(2024),
        );

        expect(downloadInvoked, isTrue);
        expect(controller.downloadTaskForTesting, same(downloadTask));
        expect(
          capturedSnapshots
              .where(
                (snapshot) =>
                    snapshot.status == StorageFileStatus.success &&
                    snapshot.filePath == '/cache/files/test.png',
              )
              .isEmpty,
          isTrue,
        );

        // Verify lastModified was called
        verify(
          () => mockLocalFile.lastModified('/cache/files/test.png'),
        ).called(1);

        downloadTask.status.value = DownloadStatus.completed;
        expect(capturedSnapshots.last.status, StorageFileStatus.success);
        expect(
          capturedSnapshots.last.filePath,
          '/cache/files/redownloaded.png',
        );
      });
    });

    group('dispose', () {
      test('prevents snapshot changes after dispose', () async {
        const initialSnapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        controller = StorageFileController(
          snapshot: initialSnapshot,
          onSnapshotChanged: capturedSnapshots.add,
        )
          ..dispose()
          ..progressUpdated()
          ..statusUpdated();

        expect(capturedSnapshots, isEmpty);
      });
    });

    group('progressUpdated', () {
      test('does nothing when download task is null', () {
        const initialSnapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        controller = StorageFileController(
          snapshot: initialSnapshot,
          onSnapshotChanged: capturedSnapshots.add,
        )..progressUpdated();

        expect(capturedSnapshots, isEmpty);
      });
    });

    group('statusUpdated', () {
      test('does nothing when download task is null', () {
        const initialSnapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        controller = StorageFileController(
          snapshot: initialSnapshot,
          onSnapshotChanged: capturedSnapshots.add,
        )..statusUpdated();

        expect(capturedSnapshots, isEmpty);
      });

      test('emits error when download is canceled', () {
        const initialSnapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        controller = StorageFileController(
          snapshot: initialSnapshot,
          onSnapshotChanged: capturedSnapshots.add,
        );

        final task = DownloadTask(
          DownloadRequest(
            'https://example.com/file.png',
            '/tmp/file.png',
          ),
        );

        controller.downloadTaskForTesting = task;
        task.status.addListener(controller.statusUpdated);

        task.status.value = DownloadStatus.canceled;

        expect(capturedSnapshots, hasLength(1));
        expect(capturedSnapshots.last.status, StorageFileStatus.error);
      });
    });
  });
}
