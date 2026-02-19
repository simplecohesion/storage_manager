import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage_manager/core/local_file.dart';
import 'package:storage_manager/widgets/storage_manager_builder.dart';

class MockLocalFile extends Mock implements LocalFile {}

void main() {
  late MockLocalFile mockLocalFile;

  Widget buildWidget({
    required String storagePath,
    required Directory cacheDirectory,
    DateTime? updateDate,
  }) {
    return MaterialApp(
      home: StorageFileBuilder(
        storagePath: storagePath,
        cacheDirectory: cacheDirectory,
        updateDate: updateDate,
        builder: (context, snapshot) {
          return Text(
            '${snapshot.status.name}:${snapshot.filePath}',
          );
        },
      ),
    );
  }

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

      await tester.pumpWidget(
        buildWidget(
          storagePath: 'folder/test.png',
          cacheDirectory: Directory('/tmp/cache'),
        ),
      );
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
      await tester.pumpWidget(
        buildWidget(
          storagePath: 'folder/test.png',
          cacheDirectory: Directory('/tmp/cache'),
        ),
      );
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

  testWidgets(
    'refetches and resets to loading when storagePath changes',
    (tester) async {
      final secondPathCompleter = Completer<String>();

      when(
        () => mockLocalFile.getPath(
          storagePath: 'folder/one.png',
          cacheDir: any(named: 'cacheDir'),
        ),
      ).thenAnswer((_) async => '/cache/files/one.png');

      when(
        () => mockLocalFile.getPath(
          storagePath: 'folder/two.png',
          cacheDir: any(named: 'cacheDir'),
        ),
      ).thenAnswer((_) => secondPathCompleter.future);

      when(
        () => mockLocalFile.fileExists('/cache/files/one.png'),
      ).thenAnswer((_) async => true);

      when(
        () => mockLocalFile.fileExists('/cache/files/two.png'),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        buildWidget(
          storagePath: 'folder/one.png',
          cacheDirectory: Directory('/tmp/cache'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('success:/cache/files/one.png'), findsOneWidget);

      await tester.pumpWidget(
        buildWidget(
          storagePath: 'folder/two.png',
          cacheDirectory: Directory('/tmp/cache'),
        ),
      );
      await tester.pump();

      expect(find.text('loading:null'), findsOneWidget);

      secondPathCompleter.complete('/cache/files/two.png');
      await tester.pumpAndSettle();

      expect(find.text('success:/cache/files/two.png'), findsOneWidget);

      verify(
        () => mockLocalFile.getPath(
          storagePath: 'folder/one.png',
          cacheDir: any(named: 'cacheDir'),
        ),
      ).called(1);
      verify(
        () => mockLocalFile.getPath(
          storagePath: 'folder/two.png',
          cacheDir: any(named: 'cacheDir'),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'refetches when cacheDirectory path changes',
    (tester) async {
      when(
        () => mockLocalFile.getPath(
          storagePath: 'folder/test.png',
          cacheDir: any(named: 'cacheDir'),
        ),
      ).thenAnswer((_) async => '/cache/files/test.png');

      when(
        () => mockLocalFile.fileExists('/cache/files/test.png'),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        buildWidget(
          storagePath: 'folder/test.png',
          cacheDirectory: Directory('/tmp/cache_a'),
        ),
      );
      await tester.pumpAndSettle();

      clearInteractions(mockLocalFile);

      await tester.pumpWidget(
        buildWidget(
          storagePath: 'folder/test.png',
          cacheDirectory: Directory('/tmp/cache_b'),
        ),
      );
      await tester.pumpAndSettle();

      final verification = verify(
        () => mockLocalFile.getPath(
          storagePath: 'folder/test.png',
          cacheDir: captureAny(named: 'cacheDir'),
        ),
      )..called(1);

      final cacheDir = verification.captured.single as Directory;
      expect(cacheDir.path, '/tmp/cache_b');
    },
  );

  testWidgets(
    'refetches when updateDate changes',
    (tester) async {
      final firstDate = DateTime(2024);
      final secondDate = DateTime(2025);

      when(
        () => mockLocalFile.getPath(
          storagePath: 'folder/test.png',
          cacheDir: any(named: 'cacheDir'),
        ),
      ).thenAnswer((_) async => '/cache/files/test.png');

      when(
        () => mockLocalFile.fileExists('/cache/files/test.png'),
      ).thenAnswer((_) async => true);

      when(
        () => mockLocalFile.lastModified('/cache/files/test.png'),
      ).thenAnswer((_) async => DateTime(2030));

      await tester.pumpWidget(
        buildWidget(
          storagePath: 'folder/test.png',
          cacheDirectory: Directory('/tmp/cache'),
          updateDate: firstDate,
        ),
      );
      await tester.pumpAndSettle();

      clearInteractions(mockLocalFile);

      await tester.pumpWidget(
        buildWidget(
          storagePath: 'folder/test.png',
          cacheDirectory: Directory('/tmp/cache'),
          updateDate: secondDate,
        ),
      );
      await tester.pumpAndSettle();

      verify(
        () => mockLocalFile.getPath(
          storagePath: 'folder/test.png',
          cacheDir: any(named: 'cacheDir'),
        ),
      ).called(1);
      verify(
        () => mockLocalFile.lastModified('/cache/files/test.png'),
      ).called(1);
    },
  );
}
