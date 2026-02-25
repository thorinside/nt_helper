import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/firmware_update_cubit.dart';
import 'package:nt_helper/cubit/firmware_update_state.dart';
import 'package:nt_helper/models/firmware_release.dart';
import 'package:nt_helper/services/firmware_version_service.dart';
import 'package:nt_helper/services/flash_tool_bridge.dart';
import 'package:nt_helper/services/flash_tool_manager.dart';
import 'package:nt_helper/ui/firmware/firmware_error_widget.dart';
import 'package:nt_helper/ui/firmware/firmware_flow_diagram.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

const String _kLastFirmwareDirectoryKey = 'last_firmware_directory';

/// Screen for managing firmware updates on desktop platforms
class FirmwareUpdateScreen extends StatelessWidget {
  final DistingCubit distingCubit;

  const FirmwareUpdateScreen({super.key, required this.distingCubit});

  @override
  Widget build(BuildContext context) {
    // Check platform - only available on desktop
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
      return Scaffold(
        appBar: AppBar(title: const Text('Firmware Update')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Firmware updates are only available on desktop platforms (macOS, Windows, Linux).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Get current state info
    final distingState = distingCubit.state;
    final syncState = distingState is DistingStateSynchronized
        ? distingState
        : null;
    final currentVersion = syncState?.firmwareVersion.versionString ?? 'Unknown';
    final isDemo = syncState?.demo ?? false;
    final isOffline = syncState?.offline ?? false;

    // Create services
    final firmwareVersionService = FirmwareVersionService();
    final flashToolManager = FlashToolManager();
    final flashToolBridge = FlashToolBridge(toolManager: flashToolManager);

    return BlocProvider.value(
      value: distingCubit,
      child: BlocProvider(
        create: (context) => FirmwareUpdateCubit(
          firmwareVersionService: firmwareVersionService,
          flashToolManager: flashToolManager,
          flashToolBridge: flashToolBridge,
          currentVersion: currentVersion,
          isDemo: isDemo,
          isOffline: isOffline,
          firmwareVersion: syncState?.firmwareVersion,
          midiManager: syncState != null ? distingCubit.disting() : null,
        )..loadAvailableVersions(),
        child: const _FirmwareUpdateView(),
      ),
    );
  }
}

class _FirmwareUpdateView extends StatelessWidget {
  const _FirmwareUpdateView();

  @override
  Widget build(BuildContext context) {
    return const FirmwareUpdateAnnouncementListener(
      child: _FirmwareUpdateScaffold(),
    );
  }
}

class FirmwareUpdateAnnouncementListener extends StatelessWidget {
  final Widget child;
  final FirmwareUpdateCubit? bloc;

  const FirmwareUpdateAnnouncementListener({
    super.key,
    required this.child,
    this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<FirmwareUpdateCubit, FirmwareUpdateState>(
      bloc: bloc,
      listener: (context, state) {
        if (state is FirmwareUpdateStateDownloading) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            'Downloading firmware: ${(state.progress * 100).toInt()}%',
            TextDirection.ltr,
          );
        } else if (state is FirmwareUpdateStateFlashing) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            'Flashing firmware: ${state.progress.percent}%',
            TextDirection.ltr,
          );
        } else if (state is FirmwareUpdateStateSuccess) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            'Firmware update complete',
            TextDirection.ltr,
          );
        } else if (state is FirmwareUpdateStateError) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            'Firmware update error: ${state.message}',
            TextDirection.ltr,
          );
        } else if (state is FirmwareUpdateStateEnteringBootloader) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            'Entering bootloader mode',
            TextDirection.ltr,
          );
        } else if (state is FirmwareUpdateStateWaitingForBootloader) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            'Waiting for bootloader mode',
            TextDirection.ltr,
          );
        }
      },
      child: child,
    );
  }
}

class _FirmwareUpdateScaffold extends StatelessWidget {
  const _FirmwareUpdateScaffold();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FirmwareUpdateCubit, FirmwareUpdateState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Firmware Update'),
            leading: _buildBackButton(context, state),
            actions: _buildAppBarActions(context, state),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildStateContent(context, state),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget>? _buildAppBarActions(
    BuildContext context,
    FirmwareUpdateState state,
  ) {
    // Only show local file action on initial state
    if (state is FirmwareUpdateStateInitial) {
      return [
        TextButton.icon(
          onPressed: () => _selectLocalFile(context),
          icon: const Icon(Icons.folder_open),
          label: const Text('Local Zip File'),
        ),
        const SizedBox(width: 8),
      ];
    }
    return null;
  }

  Widget? _buildBackButton(BuildContext context, FirmwareUpdateState state) {
    // During bootloader entry or flashing, show a disabled back button
    if (state is FirmwareUpdateStateEnteringBootloader ||
        state is FirmwareUpdateStateFlashing) {
      return IconButton(
        icon: const Icon(
          Icons.arrow_back,
          semanticLabel: 'Cannot exit during firmware update',
        ),
        onPressed: null,
        tooltip: 'Cannot exit during firmware update',
      );
    }
    return null; // Use default back button
  }

  Widget _buildStateContent(BuildContext context, FirmwareUpdateState state) {
    return state.map(
      initial: (s) => _InitialStateView(state: s),
      downloading: (s) => _DownloadingStateView(state: s),
      waitingForBootloader: (s) => _BootloaderInstructionsView(state: s),
      enteringBootloader: (s) => _EnteringBootloaderView(state: s),
      flashing: (s) => _FlashingStateView(state: s),
      success: (s) => _SuccessStateView(state: s),
      error: (s) => _ErrorView(state: s),
    );
  }

  Future<void> _selectLocalFile(BuildContext context) async {
    final cubit = context.read<FirmwareUpdateCubit>();

    // Get last used directory
    final prefs = await SharedPreferences.getInstance();
    final lastDirectory = prefs.getString(_kLastFirmwareDirectoryKey);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'Select Firmware Package',
      initialDirectory: lastDirectory,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath != null) {
        // Save the directory for next time
        final directory = path.dirname(filePath);
        await prefs.setString(_kLastFirmwareDirectoryKey, directory);

        cubit.useLocalFile(filePath);
      }
    }
  }
}

/// Initial state - shows current and available versions
class _InitialStateView extends StatelessWidget {
  final FirmwareUpdateStateInitial state;

  const _InitialStateView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FirmwareUpdateCubit>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Current version - pinned at top
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.memory, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Firmware',
                        style: theme.textTheme.labelMedium,
                      ),
                      Text(
                        state.currentVersion.startsWith('v')
                            ? state.currentVersion
                            : 'v${state.currentVersion}',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Available versions section header
        Text('Available Firmware', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),

        // Scrollable content
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Content based on state
                  _buildVersionsContent(context, theme, cubit, state),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersionsContent(
    BuildContext context,
    ThemeData theme,
    FirmwareUpdateCubit cubit,
    FirmwareUpdateStateInitial state,
  ) {
    // Loading state
    if (state.isLoadingVersions) {
      return Column(
        children: [
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          Text(
            'Checking for updates...',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Error state
    if (state.fetchError != null) {
      return Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to check for updates',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.fetchError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => cubit.loadAvailableVersions(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Available versions
    if (state.availableVersions != null) {
      if (state.availableVersions!.isEmpty) {
        return Text(
          'No firmware versions found.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildVersionCards(context, state.availableVersions!),
      );
    }

    // No data yet
    return const SizedBox.shrink();
  }

  List<Widget> _buildVersionCards(
    BuildContext context,
    List<FirmwareRelease> versions,
  ) {
    final cubit = context.read<FirmwareUpdateCubit>();
    final theme = Theme.of(context);

    return [
      Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
          2: IntrinsicColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          for (int i = 0; i < versions.length && i < 5; i++)
            _buildVersionRow(context, theme, cubit, versions[i], i == 0),
        ],
      ),
    ];
  }

  TableRow _buildVersionRow(
    BuildContext context,
    ThemeData theme,
    FirmwareUpdateCubit cubit,
    FirmwareRelease version,
    bool isLatest,
  ) {
    return TableRow(
      children: [
        // Column 1: Version number
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'v${version.version}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 14,
                child: isLatest
                    ? Text(
                        'Latest',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
        // Column 2: Changelog
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 12),
          child: version.changelog.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: version.changelog
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                )
              : const SizedBox.shrink(),
        ),
        // Column 3: Install button
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FilledButton(
            onPressed: () => cubit.startUpdate(version),
            child: const Text('Install'),
          ),
        ),
      ],
    );
  }
}

/// Downloading state - shows download progress
class _DownloadingStateView extends StatelessWidget {
  final FirmwareUpdateStateDownloading state;

  const _DownloadingStateView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FirmwareUpdateCubit>();
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.download, size: 64),
        const SizedBox(height: 24),
        Text('Downloading Firmware', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('v${state.version.version}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 32),
        LinearProgressIndicator(value: state.progress),
        const SizedBox(height: 8),
        Text('${(state.progress * 100).toInt()}%'),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () => cubit.cancel(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Bootloader instructions - guides user to enter bootloader mode
class _BootloaderInstructionsView extends StatelessWidget {
  final FirmwareUpdateStateWaitingForBootloader state;

  const _BootloaderInstructionsView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FirmwareUpdateCubit>();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.info_outline, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            state.canAutoEnter ? 'Ready to Update' : 'Enter Bootloader Mode',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            state.canAutoEnter
                ? 'Your Disting NT will be rebooted into bootloader mode '
                    'automatically and the firmware will be flashed.'
                : 'Follow these steps on your Disting NT:',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          if (!state.canAutoEnter) ...[
            // Manual bootloader steps
            _buildStep(
              context,
              number: 1,
              title: 'Enter Bootloader Mode',
              description:
                  'Menu > Misc > Enter bootloader mode, then confirm',
            ),
            const SizedBox(height: 16),
            _buildStep(
              context,
              number: 2,
              title: 'Screen Shows Message',
              description: 'The display shows "Entering serial downloader"',
            ),
            const SizedBox(height: 16),
            _buildStep(
              context,
              number: 3,
              title: 'Ready to Flash',
              description: 'Click the button below when ready',
            ),
            const SizedBox(height: 32),
          ],

          if (state.canAutoEnter) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'The module will be unavailable during the update. '
                        'Do not disconnect USB or power until the update is '
                        'complete.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          FilledButton.icon(
            onPressed: () => cubit.confirmAndFlash(),
            icon: const Icon(Icons.flash_on),
            label: Text(
              state.canAutoEnter
                  ? 'Update Firmware'
                  : "I'm in bootloader mode - Flash Now",
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: () => cubit.cancel(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required int number,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: Text('$number'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(description, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entering bootloader state - auto-entering via SysEx
class _EnteringBootloaderView extends StatelessWidget {
  final FirmwareUpdateStateEnteringBootloader state;

  const _EnteringBootloaderView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondsLeft =
        ((1.0 - state.progress) * 5).ceil().clamp(0, 5);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.restart_alt, size: 64),
        const SizedBox(height: 24),
        Text('Entering Bootloader Mode', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          state.progress == 0
              ? 'Sending command to device...'
              : 'Waiting for device to switch ($secondsLeft s)',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        LinearProgressIndicator(value: state.progress),
      ],
    );
  }
}

/// Flashing state - shows progress with animated diagram
class _FlashingStateView extends StatelessWidget {
  final FirmwareUpdateStateFlashing state;

  const _FlashingStateView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FirmwareUpdateCubit>();
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated flow diagram
        SizedBox(
          height: 150,
          child: FirmwareFlowDiagram(progress: state.progress),
        ),
        const SizedBox(height: 32),

        // Stage label
        Text(
          _getStageLabel(state.progress.stage.name),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 16,
          child: state.progress.message.isNotEmpty
              ? Text(
                  state.progress.message,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                )
              : null,
        ),
        const SizedBox(height: 24),

        // Progress bar
        LinearProgressIndicator(value: state.progress.percent / 100),
        const SizedBox(height: 8),
        Text('${state.progress.percent}%'),

        const SizedBox(height: 32),

        // Cancel button with confirmation
        OutlinedButton(
          onPressed: () => _confirmCancel(context, cubit),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _getStageLabel(String stage) {
    switch (stage) {
      case 'sdpConnect':
        return 'Connecting to bootloader...';
      case 'blCheck':
        return 'Checking bootloader...';
      case 'sdpUpload':
        return 'Uploading firmware...';
      case 'write':
        return 'Writing firmware...';
      case 'configure':
        return 'Configuring device...';
      case 'reset':
        return 'Resetting device...';
      case 'complete':
        return 'Completing...';
      default:
        return stage;
    }
  }

  Future<void> _confirmCancel(
    BuildContext context,
    FirmwareUpdateCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Firmware Update?'),
        content: const Text(
          'Canceling during a firmware update may leave your device in an '
          'unusable state. Are you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Update'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Update'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cubit.cancel();
    }
  }
}

/// Success state - firmware update completed
class _SuccessStateView extends StatelessWidget {
  final FirmwareUpdateStateSuccess state;

  const _SuccessStateView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FirmwareUpdateCubit>();
    final distingCubit = context.read<DistingCubit>();
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, size: 96, color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text('Update Complete!', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          state.newVersion == 'local'
              ? 'Firmware updated from local file'
              : 'Updated to v${state.newVersion}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () {
            cubit.cleanupAndReset();
            // Notify DistingCubit to refresh firmware version from device
            distingCubit.onFirmwareUpdateComplete();
            Navigator.of(context).pop();
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// Error state - shows error message with contextual actions
class _ErrorView extends StatelessWidget {
  final FirmwareUpdateStateError state;

  const _ErrorView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FirmwareUpdateCubit>();

    return FirmwareErrorWidget(
      state: state,
      onReturnToBootloader: () => cubit.returnToBootloaderInstructions(),
      onRetryFlash: () => cubit.retryFlash(),
      onTryAgain: () => cubit.cleanupAndReset(),
      onInstallUdevRules: () => cubit.installUdevRules(),
      onGetDiagnostics: () => cubit.getDiagnostics(),
    );
  }
}
