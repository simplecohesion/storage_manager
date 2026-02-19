import 'package:flutter_test/flutter_test.dart';
import 'package:storage_manager/enums/storage_file_status.dart';
import 'package:storage_manager/models/storage_file_snapshot.dart';

void main() {
  group('StorageFileSnapshot', () {
    test('creates with all required parameters', () {
      const snapshot = StorageFileSnapshot(
        status: StorageFileStatus.loading,
        filePath: null,
        progress: null,
      );

      expect(snapshot.status, StorageFileStatus.loading);
      expect(snapshot.filePath, isNull);
      expect(snapshot.progress, isNull);
    });

    test('creates with non-null optional parameters', () {
      const snapshot = StorageFileSnapshot(
        status: StorageFileStatus.success,
        filePath: '/path/to/file.png',
        progress: 1,
      );

      expect(snapshot.status, StorageFileStatus.success);
      expect(snapshot.filePath, '/path/to/file.png');
      expect(snapshot.progress, 1.0);
    });

    group('copyWith', () {
      test('copies with new status', () {
        const original = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: 0.5,
        );

        final copied = original.copyWith(status: StorageFileStatus.success);

        expect(copied.status, StorageFileStatus.success);
        expect(copied.filePath, isNull);
        expect(copied.progress, 0.5);
      });

      test('copies with new filePath', () {
        const original = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        final copied = original.copyWith(filePath: '/new/path.png');

        expect(copied.status, StorageFileStatus.loading);
        expect(copied.filePath, '/new/path.png');
        expect(copied.progress, isNull);
      });

      test('copies with new progress', () {
        const original = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        final copied = original.copyWith(progress: 0.75);

        expect(copied.status, StorageFileStatus.loading);
        expect(copied.filePath, isNull);
        expect(copied.progress, 0.75);
      });

      test('clears filePath when clearFilePath is true', () {
        const original = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file.png',
          progress: 1,
        );

        final copied = original.copyWith(clearFilePath: true);

        expect(copied.status, StorageFileStatus.success);
        expect(copied.filePath, isNull);
        expect(copied.progress, 1.0);
      });

      test('clears progress when clearProgress is true', () {
        const original = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file.png',
          progress: 1,
        );

        final copied = original.copyWith(clearProgress: true);

        expect(copied.status, StorageFileStatus.success);
        expect(copied.filePath, '/path/to/file.png');
        expect(copied.progress, isNull);
      });

      test('clearFilePath takes precedence over new filePath', () {
        const original = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file.png',
          progress: 1,
        );

        final copied = original.copyWith(
          filePath: '/new/path.png',
          clearFilePath: true,
        );

        expect(copied.filePath, isNull);
      });

      test('returns copy with same values when no parameters provided', () {
        const original = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file.png',
          progress: 1,
        );

        final copied = original.copyWith();

        expect(copied.status, original.status);
        expect(copied.filePath, original.filePath);
        expect(copied.progress, original.progress);
      });
    });

    group('equality', () {
      test('equal snapshots are equal', () {
        const snapshot1 = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file.png',
          progress: 1,
        );

        const snapshot2 = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file.png',
          progress: 1,
        );

        expect(snapshot1, equals(snapshot2));
        expect(snapshot1.hashCode, equals(snapshot2.hashCode));
      });

      test('different status makes snapshots unequal', () {
        const snapshot1 = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file.png',
          progress: 1,
        );

        const snapshot2 = StorageFileSnapshot(
          status: StorageFileStatus.error,
          filePath: '/path/to/file.png',
          progress: 1,
        );

        expect(snapshot1, isNot(equals(snapshot2)));
      });

      test('different filePath makes snapshots unequal', () {
        const snapshot1 = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file1.png',
          progress: 1,
        );

        const snapshot2 = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file2.png',
          progress: 1,
        );

        expect(snapshot1, isNot(equals(snapshot2)));
      });

      test('different progress makes snapshots unequal', () {
        const snapshot1 = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: 0.5,
        );

        const snapshot2 = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: 0.75,
        );

        expect(snapshot1, isNot(equals(snapshot2)));
      });

      test('null vs non-null filePath makes snapshots unequal', () {
        const snapshot1 = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        const snapshot2 = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: '/path/to/file.png',
          progress: null,
        );

        expect(snapshot1, isNot(equals(snapshot2)));
      });

      test('identical snapshots are equal', () {
        const snapshot = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file.png',
          progress: 1,
        );

        expect(snapshot, equals(snapshot));
      });

      test('snapshot is not equal to other types', () {
        const snapshot = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file.png',
          progress: 1,
        );

        expect(snapshot, isNot(equals('not a snapshot')));
        expect(snapshot, isNot(equals(42)));
        expect(snapshot, isNot(equals(null)));
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        const snapshot = StorageFileSnapshot(
          status: StorageFileStatus.success,
          filePath: '/path/to/file.png',
          progress: 1,
        );

        final string = snapshot.toString();

        expect(string, contains('StorageFileSnapshot'));
        expect(string, contains('success'));
        expect(string, contains('/path/to/file.png'));
        expect(string, contains('1.0'));
      });

      test('handles null values', () {
        const snapshot = StorageFileSnapshot(
          status: StorageFileStatus.loading,
          filePath: null,
          progress: null,
        );

        final string = snapshot.toString();

        expect(string, contains('StorageFileSnapshot'));
        expect(string, contains('loading'));
        expect(string, contains('null'));
      });
    });
  });

  group('StorageFileStatus', () {
    test('has all expected values', () {
      expect(StorageFileStatus.values, hasLength(4));
      expect(
        StorageFileStatus.values,
        containsAll([
          StorageFileStatus.success,
          StorageFileStatus.loading,
          StorageFileStatus.error,
          StorageFileStatus.missing,
        ]),
      );
    });
  });
}
