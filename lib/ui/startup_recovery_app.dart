import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:nt_helper/services/macos_library_storage.dart';
import 'package:nt_helper/services/gallery_cache_storage.dart';
import 'package:nt_helper/services/startup_controller.dart';

/// Presentation only. Storage, admission and close ownership remain in the controller.
class StartupRecoveryApp extends StatefulWidget {
  const StartupRecoveryApp({
    super.key,
    required this.controller,
    required this.normalBuilder,
  });
  final StartupController controller;
  final WidgetBuilder normalBuilder;

  @override
  State<StartupRecoveryApp> createState() => _StartupRecoveryAppState();
}

class _StartupRecoveryAppState extends State<StartupRecoveryApp> {
  String? _lastAnnouncement;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _lifecycle = AppLifecycleListener(
      onExitRequested: () async {
        await widget.controller.close();
        return AppExitResponse.exit;
      },
    );
  }

  void _changed() {
    if (!mounted) return;
    final controller = widget.controller;
    final message = controller.closed
        ? 'Closing library'
        : controller.ready
        ? '${_recoveryMessage(controller.recovery)}Library ready${controller.location == null ? '' : ' at ${controller.location}'}'
        : controller.busy
        ? 'Opening library. Please wait'
        : controller.failure == null
        ? 'Preparing library'
        : 'Library unavailable. ${_failureMessage(controller.failure!)}';
    if (message != _lastAnnouncement) {
      _lastAnnouncement = message;
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          message,
          TextDirection.ltr,
        ),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller.ready) return widget.normalBuilder(context);
    final failure = controller.failure;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Dialog(
            child: SizedBox(
              width: 560,
              height: 460,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        namesRoute: true,
                        child: Text(
                          'Open your library',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Normal library features wait until the selected database opens. Existing files and recovery data are retained.',
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Semantics(
                            liveRegion: true,
                            child: SelectableText(
                              failure == null
                                  ? 'Preparing storage.'
                                  : '${_failureMessage(failure)}\n\nOperation details: $failure',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'After resolving the reported condition, use Retry here; restarting the app is not required. Folder selection, when offered, does not guarantee that macOS will permit access.',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 24,
                        child: controller.busy
                            ? const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      semanticsLabel: 'Opening library',
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Opening library…'),
                                ],
                              )
                            : Text(
                                controller.closed
                                    ? 'Closing…'
                                    : failure == null
                                    ? 'Ready to open'
                                    : 'Library remains unavailable',
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(1),
                            child: FilledButton(
                              autofocus: true,
                              onPressed: controller.canRetry && !controller.busy
                                  ? () => unawaited(controller.retry())
                                  : null,
                              child: const Text('Retry'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FocusTraversalOrder(
                              order: const NumericFocusOrder(2),
                              child: OutlinedButton(
                                onPressed:
                                    controller.canSelectAccess &&
                                        !controller.busy
                                    ? () => unawaited(
                                        controller.retry(
                                          selectLegacyDirectory: true,
                                        ),
                                      )
                                    : null,
                                child: const Text('Select legacy folder…'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _failureMessage(Object failure) {
  if (failure is! StorageFailure) {
    return 'The library could not be opened. No replacement library was admitted.';
  }
  return switch (failure.kind) {
    StorageFailureKind.access =>
      'A required storage operation was denied. Check the reported source or destination access, then Retry.',
    StorageFailureKind.busy =>
      'Storage is busy. Let the other operation finish, then Retry.',
    StorageFailureKind.io =>
      'A storage read or write failed. Resolve the reported I/O condition, then Retry.',
    StorageFailureKind.native =>
      'SQLite could not complete opening or inspection. The library has not been classified as corrupt. Retry when the reported condition is corrected.',
    StorageFailureKind.unsupportedSchema =>
      'This library schema is not supported by this version. Its files remain preserved.',
    StorageFailureKind.uncertain => failure.message,
    StorageFailureKind.damaged =>
      'Database damage was detected. The previous library has not been recovered; files remain preserved.',
  };
}

String _recoveryMessage(LibraryRecovery? recovery) => switch (recovery) {
  LibraryRecovery.repaired =>
    'The library was safely repaired in a separate copy. Originals and recovery files are retained. ',
  LibraryRecovery.freshAfterDamage =>
    'The previous library was not recovered. Originals and recovery files are retained. A fresh library was opened after confirmed database damage and unsuccessful safe repair. ',
  null => '',
};

/// Nonmodal outcome feedback: never changes normal content geometry.
class StorageLocationNotice extends StatefulWidget {
  const StorageLocationNotice({
    super.key,
    required this.location,
    this.recovery,
    this.galleryStorage,
    required this.child,
  });
  final String? location;
  final LibraryRecovery? recovery;
  final GalleryCacheStorage? galleryStorage;
  final Widget child;
  @override
  State<StorageLocationNotice> createState() => _StorageLocationNoticeState();
}

class _StorageLocationNoticeState extends State<StorageLocationNotice> {
  bool _dismissed = false;
  String? _lastGalleryAnnouncement;

  @override
  void initState() {
    super.initState();
    widget.galleryStorage?.addListener(_galleryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _retryGallery();
    });
  }

  @override
  void didUpdateWidget(StorageLocationNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.galleryStorage != widget.galleryStorage) {
      oldWidget.galleryStorage?.removeListener(_galleryChanged);
      widget.galleryStorage?.addListener(_galleryChanged);
      _retryGallery();
    }
  }

  void _retryGallery() {
    unawaited(widget.galleryStorage?.prepare().catchError((Object _) {}));
  }

  String get _galleryMessage {
    final storage = widget.galleryStorage;
    if (storage == null) return '';
    if (storage.busy) {
      return 'Gallery cache transfer in progress. Gallery temporarily unavailable; the library remains usable.';
    }
    if (storage.failure != null) {
      return '${storage.failure} The library remains usable.';
    }
    return storage.ready
        ? 'Gallery cache available.'
        : 'Gallery cache transfer has not completed.';
  }

  void _galleryChanged() {
    if (!mounted) return;
    if (widget.galleryStorage?.failure != null) _dismissed = false;
    final message = _galleryMessage;
    if (message != _lastGalleryAnnouncement) {
      _lastGalleryAnnouncement = message;
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          message,
          TextDirection.ltr,
        ),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.galleryStorage?.removeListener(_galleryChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (widget.location != null && !_dismissed)
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Semantics(
                            liveRegion: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(switch (widget.recovery) {
                                    LibraryRecovery.repaired =>
                                      'Library repaired',
                                    LibraryRecovery.freshAfterDamage =>
                                      'Fresh library after database damage',
                                    null => 'Library storage ready',
                                  }),
                                ),
                                Text(
                                  '${_recoveryMessage(widget.recovery)}Opened in Application Support: ${widget.location}\nOld Documents files are retained. Migration is one-way: older releases may show the old library and do not receive newer changes.\n$_galleryMessage',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (widget.galleryStorage != null)
                            OutlinedButton(
                              onPressed:
                                  widget.galleryStorage!.busy ||
                                      widget.galleryStorage!.ready
                                  ? null
                                  : _retryGallery,
                              child: const Text('Retry gallery transfer'),
                            ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Dismiss library storage notice',
                            onPressed: () => setState(() => _dismissed = true),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
