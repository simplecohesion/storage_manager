import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:storage_manager/core/native_local_file.dart';

void main() {
  late NativeLocalFile nativeLocalFile;

  setUp(() {
    nativeLocalFile = NativeLocalFile();
  });

  group('NativeLocalFile', () {
    group('getPath', () {
      test('generates different paths for same filename in different dirs',
          () async {
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        final path1 = await nativeLocalFile.getPath(
          storagePath: 'folder1/image.png',
          cacheDir: tempDir,
        );

        final path2 = await nativeLocalFile.getPath(
          storagePath: 'folder2/image.png',
          cacheDir: tempDir,
        );

        // Paths should be different due to hash prefix
        expect(path1, isNot(equals(path2)));
        // Both should still end with the original filename (with hash prefix)
        expect(path1, endsWith('image.png'));
        expect(path2, endsWith('image.png'));
        // Both should be in the files subdirectory
        expect(path1, contains('/files/'));
        expect(path2, contains('/files/'));
      });

      test('generates same path for same storage path', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        final path1 = await nativeLocalFile.getPath(
          storagePath: 'folder/image.png',
          cacheDir: tempDir,
        );

        final path2 = await nativeLocalFile.getPath(
          storagePath: 'folder/image.png',
          cacheDir: tempDir,
        );

        expect(path1, equals(path2));
      });

      test('handles path without slashes', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        final path = await nativeLocalFile.getPath(
          storagePath: 'image.png',
          cacheDir: tempDir,
        );

        expect(path, endsWith('image.png'));
        expect(path, contains('/files/'));
      });

      test('handles deeply nested paths', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        final path = await nativeLocalFile.getPath(
          storagePath: 'a/b/c/d/e/f/image.png',
          cacheDir: tempDir,
        );

        expect(path, endsWith('image.png'));
        expect(path, contains('/files/'));
      });

      test('uses a stable 64-bit hash prefix', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        final path = await nativeLocalFile.getPath(
          storagePath: 'folder/image.png',
          cacheDir: tempDir,
        );

        final fileName = path.split('/').last;
        expect(
          RegExp(r'^[0-9a-f]{16}_image\.png$').hasMatch(fileName),
          isTrue,
        );
      });
    });

    group('getDownloadDirectory', () {
      test('creates files subdirectory if not exists', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        final downloadDir = await nativeLocalFile.getDownloadDirectory(tempDir);

        expect(downloadDir.path, contains('/files'));
        expect(await downloadDir.exists(), isTrue);
      });

      test('returns existing files subdirectory', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        // Create the directory first
        final filesDir = Directory('${tempDir.path}/files');
        await filesDir.create();

        final downloadDir = await nativeLocalFile.getDownloadDirectory(tempDir);

        expect(downloadDir.path, equals(filesDir.path));
        expect(await downloadDir.exists(), isTrue);
      });
    });

    group('fileExists', () {
      test('returns true for existing file', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        final file = File('${tempDir.path}/test.txt');
        await file.writeAsString('test content');

        final exists = await nativeLocalFile.fileExists(file.path);

        expect(exists, isTrue);
      });

      test('returns false for non-existing file', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        final exists =
            await nativeLocalFile.fileExists('${tempDir.path}/nonexistent.txt');

        expect(exists, isFalse);
      });
    });

    group('lastModified', () {
      test('returns modification time for existing file', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        final file = File('${tempDir.path}/test.txt');
        await file.writeAsString('test content');

        final lastModified = await nativeLocalFile.lastModified(file.path);

        expect(lastModified, isNotNull);
        expect(
          lastModified!.difference(DateTime.now()).inSeconds.abs(),
          lessThan(5),
        );
      });

      test('returns null for non-existing file', () async {
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        final lastModified = await nativeLocalFile
            .lastModified('${tempDir.path}/nonexistent.txt');

        expect(lastModified, isNull);
      });

      test('returns null when file deleted during call', () async {
        // This tests the race condition fix
        final tempDir = await Directory.systemTemp.createTemp('test_cache_');
        addTearDown(() => tempDir.delete(recursive: true));

        // File doesn't exist, simulating it being deleted
        final lastModified =
            await nativeLocalFile.lastModified('${tempDir.path}/deleted.txt');

        expect(lastModified, isNull);
      });
    });
  });
}
