//
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:file_system_access_api/file_system_access_api.dart';
import 'package:flutter/foundation.dart';

/// Helper class for interacting with the File System Access API.
/// This class provides utility methods to work with files and directories
/// in the browser's Origin Private File System (OPFS).
abstract class OpfsHelper {
  /// Retrieves a directory handle.
  ///
  /// If [directoryName] is provided, it navigates to the specified subdirectory
  /// inside the root directory. If not provided, it returns the root directory handle.
  ///
  /// Returns the [FileSystemDirectoryHandle] for the requested directory or null if
  /// an error occurs.
  static Future<FileSystemDirectoryHandle?> getDirectoryHandle({
    String? directoryName,
  }) async {
    try {
      final directoryHandle =
          await html.window.navigator.storage?.getDirectory();
      if (directoryHandle == null) {
        throw UnsupportedError(
          'File System Access API is not supported on this browser.',
        );
      }
      if (directoryName != null) {
        return directoryHandle.getDirectoryHandle(directoryName);
      }
      return directoryHandle;
    } catch (e) {
      debugPrint('Error in getDirectoryHandle: $e');
      return null;
    }
  }

  /// Retrieves a file handle for a specified file path.
  ///
  /// The [localPath] should include the file name and, optionally, the directory name.
  ///
  /// Returns the [FileSystemFileHandle] for the requested file or null if an error occurs.
  static Future<FileSystemFileHandle?> getFileHandle(String localPath) async {
    try {
      final parts = localPath.split('/');
      final fileName = parts.last;
      final directoryName = parts.length > 1 ? parts.first : null;

      final directoryHandle =
          await getDirectoryHandle(directoryName: directoryName);
      if (directoryHandle == null) {
        return null;
      }
      return directoryHandle.getFileHandle(fileName);
    } catch (e) {
      debugPrint('Error in getFileHandle: $e');
      return null;
    }
  }

  /// Reads a file from the OPFS and returns its URL for temporary access.
  ///
  /// The [filename] is the name of the file to be read.
  ///
  /// Returns a string URL pointing to the file blob or null if an error occurs.
  static Future<String?> readFileFromOPFS(String filename) async {
    try {
      final fileSystem = await html.window.navigator.storage?.getDirectory();
      if (fileSystem == null) {
        debugPrint('File System Access API is not supported or unavailable.');
        return null;
      }

      final fileHandle = await fileSystem.getFileHandle(filename);
      final file = await fileHandle.getFile();
      final fileUrl = html.Url.createObjectUrlFromBlob(file);

      debugPrint('File URL: $fileUrl');
      return fileUrl;
    } catch (e) {
      debugPrint('Error in readFileFromOPFS: $e');
      return null;
    }
  }
}
