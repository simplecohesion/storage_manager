import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage_manager/core/local_file.dart';
import 'package:storage_manager/widgets/storage_manager_builder.dart';

class MockLocalFile extends Mock implements LocalFile {}

void main() {
  late MockLocalFile mockLocalFile;

  setUp(() {
    mockLocalFile = MockLocalFile();
    LocalFile.instance = mockLocalFile;
  });

  tearDown(() {
    LocalFile.instance = null;
  });

  testWidgets(
    'does not refetch when cacheDirectory path is unchanged',
    (tester) async {
      when(
        () => mockLocalFile.getPath(
          storagePath: any(named: 'storagePath'),
          cacheDir: any(named: 'cacheDir'),
        ),
      ).thenAnswer((_) async => '/cache/files/test.png');

      when(
        () => mockLocalFile.fileExists('/cache/files/test.png'),
      ).thenAnswer((_) async => true);

      Widget build(Directory cacheDirectory) {
        return MaterialApp(
          home: StorageFileBuilder(
            storagePath: 'folder/test.png',
            cacheDirectory: cacheDirectory,
            builder: (context, snapshot) {
              return Text(
                '${snapshot.status.name}:${snapshot.filePath}',
              );
            },
          ),
        );
      }

      await tester.pumpWidget(build(Directory('/tmp/cache')));
      await tester.pumpAndSettle();

      expect(
        find.text('success:/cache/files/test.png'),
        findsOneWidget,
      );

      verify(
        () => mockLocalFile.getPath(
          storagePath: 'folder/test.png',
          cacheDir: any(named: 'cacheDir'),
        ),
      ).called(1);

      clearInteractions(mockLocalFile);

      // New Directory instance, but with the same path.
      await tester.pumpWidget(build(Directory('/tmp/cache')));
      await tester.pumpAndSettle();

      expect(
        find.text('success:/cache/files/test.png'),
        findsOneWidget,
      );

      verifyNever(
        () => mockLocalFile.getPath(
          storagePath: any(named: 'storagePath'),
          cacheDir: any(named: 'cacheDir'),
        ),
      );
    },
  );
}
