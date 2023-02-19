import 'dart:io';

import 'package:flutter/material.dart';
import '../storage_manager.dart';

/// Using this widget it will download the file if not downloaded yet,
/// if downloaded it will get it back in snapshot.
class StorageManagerBuilder extends StatefulWidget {
  const StorageManagerBuilder({
    Key? key,
    required this.storagePath,
    required this.builder,
    this.updateDate,
    this.cacheDirectory,
  }) : super(key: key);

  /// URL of any type of media (Audio, Video, Image, etc...)
  final String storagePath;

  final Directory? cacheDirectory;

  final DateTime? updateDate;

  /// Snapshot Will provide you the status of process
  /// (Success, Error, Loading)
  /// and file if downloaded and download progress
  final Widget? Function(BuildContext context, StorageManagerSnapshot snapshot)
      builder;

  @override
  State<StorageManagerBuilder> createState() => _StorageManagerBuilderState();
}

class _StorageManagerBuilderState extends State<StorageManagerBuilder> {
  late StorageManagerController _storageManagerController;
  late StorageManagerSnapshot snapshot;

  @override
  void initState() {
    snapshot = StorageManagerSnapshot(
      status: StorageManagerStatus.loading,
      filePath: null,
      progress: null,
    );

    /// Initializing Widget Logic Controller
    _storageManagerController = StorageManagerController(
      snapshot: snapshot,
      onSnapshotChanged: (snapshot) {
        if (mounted) {
          setState(() => this.snapshot = snapshot);
        } else {
          this.snapshot = snapshot;
        }
      },
    );

    _storageManagerController.getFile(widget.storagePath,
        cacheDir: widget.cacheDirectory, updateDate: widget.updateDate);

    super.initState();
  }

  @override
  void dispose() {
    _storageManagerController.dispose();
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
