import 'dart:io';

import 'package:flutter/material.dart';
import '../storage_manager.dart';

/// Using this widget it will download the file if not downloaded yet,
/// if downloaded it will get it back in snapshot.
class DownloadMediaBuilder extends StatefulWidget {
  const DownloadMediaBuilder(
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
  final Widget? Function(BuildContext context, DownloadMediaSnapshot snapshot)
      builder;

  @override
  State<DownloadMediaBuilder> createState() => _DownloadMediaBuilderState();
}

class _DownloadMediaBuilderState extends State<DownloadMediaBuilder> {
  late DownloadMediaBuilderController __downloadMediaBuilderController;
  late DownloadMediaSnapshot snapshot;

  @override
  void initState() {
    snapshot = DownloadMediaSnapshot(
      status: DownloadMediaStatus.loading,
      filePath: null,
      progress: null,
    );

    /// Initializing Widget Logic Controller
    __downloadMediaBuilderController = DownloadMediaBuilderController(
      snapshot: snapshot,
      onSnapshotChanged: (snapshot) {
        if (mounted) {
          setState(() => this.snapshot = snapshot);
        } else {
          this.snapshot = snapshot;
        }
      },
    );

    __downloadMediaBuilderController.getFile(widget.storagePath,
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
