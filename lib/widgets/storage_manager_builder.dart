import 'dart:io';

import 'package:flutter/material.dart';
import 'package:storage_manager/controllers/storage_file_controller.dart';
import 'package:storage_manager/models/storage_file_snapshot.dart';

/// Using this widget it will download the file if not downloaded yet,
/// if downloaded it will get it back in snapshot.
class StorageFileBuilder extends StatefulWidget {
  const StorageFileBuilder({
    required this.storagePath,
    required this.builder,
    this.updateDate,
    this.cacheDirectory,
    super.key,
  });

  /// URL of any type of media (Audio, Video, Image, etc...)
  final String storagePath;

  final Directory? cacheDirectory;

  /// The date when the file was last updated. If provided, the local cached file
  /// will be re-downloaded if it was cached before this date.
  final DateTime? updateDate;

  /// Snapshot Will provide you the status of process
  /// (Success, Error, Loading)
  /// and file if downloaded and download progress
  final Widget? Function(BuildContext context, StorageFileSnapshot snapshot)
      builder;

  @override
  State<StorageFileBuilder> createState() => _StorageFileBuilderState();
}

class _StorageFileBuilderState extends State<StorageFileBuilder> {
  late final StorageFileController _storageFileController;
  late StorageFileSnapshot snapshot;

  @override
  void initState() {
    super.initState();

    snapshot = const StorageFileSnapshot();

    _storageFileController = StorageFileController(
      snapshot: snapshot,
      onSnapshotChanged: (snapshot) {
        if (mounted) {
          setState(() => this.snapshot = snapshot);
        } else {
          this.snapshot = snapshot;
        }
      },
    );

    _storageFileController.getFile(
      widget.storagePath,
      cacheDir: widget.cacheDirectory,
      updateDate: widget.updateDate,
    );
  }

  @override
  void dispose() {
    _storageFileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
          context,
          snapshot,
        ) ??
        const SizedBox();
  }
}
