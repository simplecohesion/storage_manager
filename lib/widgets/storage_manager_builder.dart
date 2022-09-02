import 'dart:io';

import 'package:flutter/material.dart';
import '../storage_manager.dart';

/// Using this widget it will download the file if not downloaded yet,
/// if downloaded it will get it back in snapshot.
class StorageManagerBuilder extends StatefulWidget {
  const StorageManagerBuilder(
      {Key? key,
      required this.storagePath,
      required this.builder,
      this.cacheDirectory})
      : super(key: key);

  /// URL of any type of media (Audio, Video, Image, etc...)
  final String storagePath;

  final Directory? cacheDirectory;

  /// Snapshot Will provide you the status of process
  /// (Success, Error, Loading)
  /// and file if downloaded and download progress
  final Widget? Function(BuildContext context, StorageManagerSnapshot snapshot)
      builder;

  @override
  State<StorageManagerBuilder> createState() => _StorageManagerBuilderState();
}

class _StorageManagerBuilderState extends State<StorageManagerBuilder> {
  late StorageManagerController _downloadMediaBuilderController;
  late StorageManagerSnapshot snapshot;

  @override
  void initState() {
    snapshot = StorageManagerSnapshot(
      status: StorageManagerStatus.loading,
      filePath: null,
      progress: null,
    );

    /// Initializing Widget Logic Controller
    _downloadMediaBuilderController = StorageManagerController(
      snapshot: snapshot,
      onSnapshotChanged: (snapshot) {
        if (mounted) {
          setState(() => this.snapshot = snapshot);
        } else {
          this.snapshot = snapshot;
        }
      },
    );

    _downloadMediaBuilderController.getFile(widget.storagePath,
        cacheDir: widget.cacheDirectory);

    super.initState();
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
