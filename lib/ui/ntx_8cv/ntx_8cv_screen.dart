import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/cubit/ntx_8cv_connection_cubit.dart';
import 'package:nt_helper/cubit/ntx_8cv_settings_cubit.dart';
import 'package:nt_helper/utils/responsive.dart';

Future<void> _ignoreAudioChannelChange(Ntx8cvAudioChannel _, bool _) async {}
Future<void> _ignoreAudioChannelRetry(Ntx8cvAudioChannel _) async {}

/// The primary page for configuring a separately connected NTX-8CV.
class Ntx8cvScreen extends StatefulWidget {
  const Ntx8cvScreen({super.key, this.connectionCubit});

  /// Supplying a connection cubit is useful for embedding and automated tests.
  final Ntx8cvConnectionCubit? connectionCubit;

  @override
  State<Ntx8cvScreen> createState() => _Ntx8cvScreenState();
}

class _Ntx8cvScreenState extends State<Ntx8cvScreen> {
  late final Ntx8cvConnectionCubit _connectionCubit;
  late final Ntx8cvSettingsCubit _settingsCubit;
  late final bool _ownsConnectionCubit;
  final TextEditingController _deviceIdController = TextEditingController(
    text: '0',
  );

  @override
  void initState() {
    super.initState();
    _ownsConnectionCubit = widget.connectionCubit == null;
    _connectionCubit = widget.connectionCubit ?? Ntx8cvConnectionCubit();
    _settingsCubit = Ntx8cvSettingsCubit(connectionCubit: _connectionCubit);
    unawaited(_connectionCubit.initialize());
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    unawaited(_settingsCubit.close());
    if (_ownsConnectionCubit) {
      unawaited(_connectionCubit.close());
    }
    super.dispose();
  }

  void _syncDeviceIdText(Ntx8cvConnectionState state) {
    if (_deviceIdController.text == state.deviceIdText) return;
    _deviceIdController.value = TextEditingValue(
      text: state.deviceIdText,
      selection: TextSelection.collapsed(offset: state.deviceIdText.length),
    );
  }

  Future<void> _refresh() async {
    await _connectionCubit.refreshEndpoints();
    await _settingsCubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = Responsive.isMobile(context);
    final theme = Theme.of(context);

    return BlocListener<Ntx8cvConnectionCubit, Ntx8cvConnectionState>(
      bloc: _connectionCubit,
      listener: (_, state) => _syncDeviceIdText(state),
      child: Scaffold(
        appBar: AppBar(title: const Text('NTX-8CV')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: SingleChildScrollView(
                padding: Responsive.getScreenPadding(context),
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'NTX-8CV',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connect the NTX-8CV directly. Its USB MIDI connection '
                        'is separate from your disting NT.',
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<Ntx8cvConnectionCubit, Ntx8cvConnectionState>(
                        bloc: _connectionCubit,
                        builder: (context, state) => _ConnectionSection(
                          isNarrow: isNarrow,
                          state: state,
                          deviceIdController: _deviceIdController,
                          onRefresh: _refresh,
                          onInputChanged: (device) {
                            unawaited(
                              _connectionCubit.selectInputDevice(device),
                            );
                          },
                          onOutputChanged: (device) {
                            unawaited(
                              _connectionCubit.selectOutputDevice(device),
                            );
                          },
                          onDeviceIdChanged: (value) {
                            unawaited(_connectionCubit.setDeviceIdText(value));
                          },
                          onConnect: _connectionCubit.connect,
                          onDisconnect: _connectionCubit.disconnect,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BlocBuilder<Ntx8cvConnectionCubit, Ntx8cvConnectionState>(
                        bloc: _connectionCubit,
                        builder: (context, connectionState) =>
                            BlocBuilder<
                              Ntx8cvSettingsCubit,
                              Ntx8cvSettingsState
                            >(
                              bloc: _settingsCubit,
                              builder: (context, settingsState) =>
                                  Ntx8cvSettingsSection(
                                    isConnected: connectionState.isConnected,
                                    isNarrow: isNarrow,
                                    state: settingsState,
                                    onChannelGroupChanged:
                                        _settingsCubit.setChannelGroup,
                                    onRetryChannelGroupChange:
                                        _settingsCubit.retryChannelGroupChange,
                                    onEs5Changed: _settingsCubit.setEs5Enabled,
                                    onRetryEs5Change:
                                        _settingsCubit.retryEs5Change,
                                    onModeChanged:
                                        _settingsCubit.setExpansionMode,
                                    onRetryModeChange:
                                        _settingsCubit.retryModeChange,
                                    onAudioChannelChanged:
                                        _settingsCubit.setAudioChannelEnabled,
                                    onRetryAudioChannelChange:
                                        _settingsCubit.retryAudioChannelChange,
                                    onReboot: _settingsCubit.reboot,
                                  ),
                            ),
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

class _ConnectionSection extends StatelessWidget {
  const _ConnectionSection({
    required this.isNarrow,
    required this.state,
    required this.deviceIdController,
    required this.onRefresh,
    required this.onInputChanged,
    required this.onOutputChanged,
    required this.onDeviceIdChanged,
    required this.onConnect,
    required this.onDisconnect,
  });

  final bool isNarrow;
  final Ntx8cvConnectionState state;
  final TextEditingController deviceIdController;
  final Future<void> Function() onRefresh;
  final ValueChanged<MidiDevice?> onInputChanged;
  final ValueChanged<MidiDevice?> onOutputChanged;
  final ValueChanged<String> onDeviceIdChanged;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;

  @override
  Widget build(BuildContext context) {
    final controls = _ConnectionControls(
      state: state,
      deviceIdController: deviceIdController,
      onInputChanged: onInputChanged,
      onOutputChanged: onOutputChanged,
      onDeviceIdChanged: onDeviceIdChanged,
      onConnect: onConnect,
      onDisconnect: onDisconnect,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Connection',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh NTX-8CV MIDI endpoints',
                  onPressed: state.isConnecting
                      ? null
                      : () {
                          unawaited(onRefresh());
                        },
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 144,
                  child: Semantics(
                    liveRegion: true,
                    label: 'NTX-8CV connection status: ${state.statusLabel}',
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Chip(
                        avatar: Icon(_statusIcon(state.status)),
                        label: Text(state.statusLabel),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the NTX-8CV MIDI input and output, then connect to '
              'verify the device before changing its settings.',
            ),
            const SizedBox(height: 16),
            if (isNarrow)
              _NarrowConnectionControls(controls: controls)
            else
              _WideConnectionControls(controls: controls),
            const SizedBox(height: 12),
            _ConnectionFeedbackRegion(isNarrow: isNarrow, state: state),
          ],
        ),
      ),
    );
  }

  static IconData _statusIcon(Ntx8cvConnectionStatus status) =>
      switch (status) {
        Ntx8cvConnectionStatus.disconnected => Icons.link_off,
        Ntx8cvConnectionStatus.connecting => Icons.sync,
        Ntx8cvConnectionStatus.connected => Icons.link,
        Ntx8cvConnectionStatus.failed => Icons.error_outline,
      };
}

/// A fixed-height connection feedback area keeps endpoint controls from
/// shifting as lifecycle messages appear, disappear, or change length.
class _ConnectionFeedbackRegion extends StatelessWidget {
  const _ConnectionFeedbackRegion({
    required this.isNarrow,
    required this.state,
  });

  final bool isNarrow;
  final Ntx8cvConnectionState state;

  @override
  Widget build(BuildContext context) {
    final message =
        state.statusMessage ??
        (state.isLoadingEndpoints
            ? 'Refreshing NTX-8CV MIDI endpoints.'
            : state.isConnected
            ? 'Device information verified from the selected MIDI input.'
            : 'Select the NTX-8CV MIDI endpoints, then connect to verify it.');
    final isError = state.status == Ntx8cvConnectionStatus.failed;
    return SizedBox(
      height: isNarrow ? 72 : 56,
      child: Align(
        alignment: Alignment.topLeft,
        child: Semantics(
          liveRegion: true,
          label: message,
          child: ExcludeSemantics(
            child: SingleChildScrollView(
              primary: false,
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? Theme.of(context).colorScheme.error : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WideConnectionControls extends StatelessWidget {
  const _WideConnectionControls({required this.controls});

  final _ConnectionControls controls;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('ntx8cv-connection-controls-wide'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: controls.inputField()),
        const SizedBox(width: 12),
        Expanded(child: controls.outputField()),
        const SizedBox(width: 12),
        Expanded(child: controls.deviceIdField()),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(width: 144, child: controls.button()),
        ),
      ],
    );
  }
}

class _NarrowConnectionControls extends StatelessWidget {
  const _NarrowConnectionControls({required this.controls});

  final _ConnectionControls controls;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('ntx8cv-connection-controls-narrow'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        controls.inputField(),
        const SizedBox(height: 12),
        controls.outputField(),
        const SizedBox(height: 12),
        controls.deviceIdField(),
        const SizedBox(height: 16),
        controls.button(),
      ],
    );
  }
}

class _ConnectionControls {
  const _ConnectionControls({
    required this.state,
    required this.deviceIdController,
    required this.onInputChanged,
    required this.onOutputChanged,
    required this.onDeviceIdChanged,
    required this.onConnect,
    required this.onDisconnect,
  });

  final Ntx8cvConnectionState state;
  final TextEditingController deviceIdController;
  final ValueChanged<MidiDevice?> onInputChanged;
  final ValueChanged<MidiDevice?> onOutputChanged;
  final ValueChanged<String> onDeviceIdChanged;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;

  Widget inputField() => _MidiEndpointField(
    key: const Key('ntx8cv-midi-input'),
    label: 'MIDI input',
    devices: state.inputDevices,
    selectedDevice: state.selectedInputDevice,
    enabled: !state.isConnecting,
    onChanged: onInputChanged,
  );

  Widget outputField() => _MidiEndpointField(
    key: const Key('ntx8cv-midi-output'),
    label: 'MIDI output',
    devices: state.outputDevices,
    selectedDevice: state.selectedOutputDevice,
    enabled: !state.isConnecting,
    onChanged: onOutputChanged,
  );

  Widget deviceIdField() => TextFormField(
    key: const Key('ntx8cv-device-id'),
    controller: deviceIdController,
    enabled: !state.isConnecting,
    keyboardType: TextInputType.number,
    onChanged: onDeviceIdChanged,
    decoration: InputDecoration(
      labelText: 'SysEx device ID',
      helperText: '0–126',
      errorText: state.deviceIdError,
      border: const OutlineInputBorder(),
    ),
  );

  Widget button() {
    if (state.isConnected) {
      return FilledButton.icon(
        onPressed: () {
          unawaited(onDisconnect());
        },
        icon: const Icon(Icons.link_off),
        label: const Text('Disconnect'),
      );
    }
    return FilledButton.icon(
      onPressed: state.canConnect
          ? () {
              unawaited(onConnect());
            }
          : null,
      icon: Icon(state.isConnecting ? Icons.sync : Icons.link),
      label: Text(state.isConnecting ? 'Connecting' : 'Connect'),
    );
  }
}

class _MidiEndpointField extends StatelessWidget {
  const _MidiEndpointField({
    super.key,
    required this.label,
    required this.devices,
    required this.selectedDevice,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final List<MidiDevice> devices;
  final MidiDevice? selectedDevice;
  final bool enabled;
  final ValueChanged<MidiDevice?> onChanged;

  @override
  Widget build(BuildContext context) {
    MidiDevice? selectedValue;
    for (final device in devices) {
      if (device.id == selectedDevice?.id) {
        selectedValue = device;
        break;
      }
    }
    return KeyedSubtree(
      key: ValueKey('$label:${selectedValue?.id}'),
      child: DropdownButtonFormField<MidiDevice>(
        key: ValueKey('$label-dropdown'),
        initialValue: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        hint: const Text('No MIDI endpoint selected'),
        items: [
          for (final device in devices)
            DropdownMenuItem(value: device, child: Text(device.name)),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

/// Displays device-confirmed settings and explicit recovery actions.
class Ntx8cvSettingsSection extends StatelessWidget {
  const Ntx8cvSettingsSection({
    super.key,
    required this.isConnected,
    this.isNarrow = false,
    required this.state,
    required this.onChannelGroupChanged,
    required this.onRetryChannelGroupChange,
    required this.onEs5Changed,
    required this.onRetryEs5Change,
    required this.onModeChanged,
    required this.onRetryModeChange,
    this.onAudioChannelChanged = _ignoreAudioChannelChange,
    this.onRetryAudioChannelChange = _ignoreAudioChannelRetry,
    required this.onReboot,
  });

  final bool isConnected;
  final bool isNarrow;
  final Ntx8cvSettingsState state;
  final Future<void> Function(Ntx8cvChannelGroup) onChannelGroupChanged;
  final Future<void> Function() onRetryChannelGroupChange;
  final Future<void> Function(bool) onEs5Changed;
  final Future<void> Function() onRetryEs5Change;
  final Future<void> Function(Ntx8cvExpansionMode) onModeChanged;
  final Future<void> Function() onRetryModeChange;
  final Future<void> Function(Ntx8cvAudioChannel, bool) onAudioChannelChanged;
  final Future<void> Function(Ntx8cvAudioChannel) onRetryAudioChannelChange;
  final Future<void> Function() onReboot;

  @override
  Widget build(BuildContext context) {
    final canChangeChannelGroup =
        isConnected &&
        state.confirmedChannelGroup != null &&
        !state.isBusy &&
        !state.hasPendingChannelGroupChange;
    final canChangeEs5 =
        isConnected &&
        state.confirmedEs5Enabled != null &&
        !state.isBusy &&
        !state.hasPendingEs5Change;
    final canChangeMode =
        isConnected &&
        state.confirmedMode != null &&
        state.modeCapabilityEvidenced &&
        !state.isBusy &&
        !state.hasPendingModeChange;
    final canChangeAudioChannels =
        isConnected && _audioChannelsApply && !state.isBusy;
    final canReboot = isConnected && !state.isBusy;
    final audioChannelTiles = [
      for (final channel in Ntx8cvAudioChannel.values)
        _AudioChannelTile(
          key: Key('ntx8cv-audio-channel-${channel.number}'),
          isNarrow: isNarrow,
          channel: channel,
          confirmedEnabled: state.confirmedAudioChannelEnabled(channel),
          isWriting: state.isWritingAudioChannel(channel),
          hasPendingChange: state.hasPendingAudioChannelChange(channel),
          status: _audioChannelStatus(channel),
          enabled:
              canChangeAudioChannels &&
              state.confirmedAudioChannelEnabled(channel) != null &&
              !state.hasPendingAudioChannelChange(channel),
          onChanged: (enabled) {
            unawaited(onAudioChannelChanged(channel, enabled));
          },
          onRetry: () {
            unawaited(onRetryAudioChannelChange(channel));
          },
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label:
                      'Reboot only the currently selected, identity-verified '
                      'NTX-8CV',
                  child: FilledButton.icon(
                    key: const Key('ntx8cv-reboot'),
                    onPressed: canReboot
                        ? () {
                            unawaited(onReboot());
                          }
                        : null,
                    icon: state.isRebooting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restart_alt),
                    label: const Text('Reboot NTX-8CV'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ReservedSettingsStatusRegion(
              isNarrow: isNarrow,
              message:
                  state.rebootMessage ??
                  (state.isRebooting
                      ? 'Rebooting the selected NTX-8CV and reacquiring its settings.'
                      : ''),
              isError: state.rebootMessage != null,
            ),
            const Text(
              'Connect an NTX-8CV to read and configure its settings. Channel '
              'Group is separate from individual NTX-8CV audio-channel '
              'enablement and does not alter disting NT algorithm routing.',
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable ES-5'),
              subtitle: SizedBox(
                height: 36,
                child: Text(
                  _es5Description(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              value: state.confirmedEs5Enabled ?? false,
              onChanged: canChangeEs5
                  ? (enabled) {
                      unawaited(onEs5Changed(enabled));
                    }
                  : null,
            ),
            _ReservedSettingsStatusRegion(
              isNarrow: isNarrow,
              message: _es5Status(),
            ),
            _RecoveryActionSlot(
              visible: state.hasPendingEs5Change,
              actionKey: const Key('ntx8cv-retry-es5-change'),
              enabled: isConnected && !state.isBusy,
              onPressed: onRetryEs5Change,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Ntx8cvExpansionMode>(
              key: ValueKey('ntx8cv-expansion-mode-${state.confirmedMode}'),
              initialValue: state.confirmedMode,
              decoration: const InputDecoration(
                labelText: 'NT expansion mode',
                border: OutlineInputBorder(),
              ),
              items: Ntx8cvExpansionMode.values
                  .map(
                    (mode) =>
                        DropdownMenuItem(value: mode, child: Text(mode.label)),
                  )
                  .toList(),
              onChanged: canChangeMode
                  ? (mode) {
                      if (mode != null) {
                        unawaited(onModeChanged(mode));
                      }
                    }
                  : null,
            ),
            _ReservedSettingsDescriptionRegion(
              isNarrow: isNarrow,
              message: _modeDescription(),
            ),
            _ReservedSettingsStatusRegion(
              isNarrow: isNarrow,
              message: _modeStatus(),
            ),
            _RecoveryActionSlot(
              visible: state.hasPendingModeChange,
              actionKey: const Key('ntx8cv-retry-mode-change'),
              enabled:
                  isConnected && state.modeCapabilityEvidenced && !state.isBusy,
              onPressed: onRetryModeChange,
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                'Audio channel enablement',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: isNarrow ? 56 : 40,
              child: Text(
                _audioChannelsDescription(),
                maxLines: isNarrow ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isNarrow)
              ...audioChannelTiles
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(children: audioChannelTiles.take(4).toList()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(children: audioChannelTiles.skip(4).toList()),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Ntx8cvChannelGroup>(
              key: ValueKey(
                'ntx8cv-channel-group-${state.confirmedChannelGroup}',
              ),
              initialValue: state.confirmedChannelGroup,
              decoration: const InputDecoration(
                labelText: 'Channel Group',
                border: OutlineInputBorder(),
              ),
              items: Ntx8cvChannelGroup.values
                  .map(
                    (group) => DropdownMenuItem(
                      value: group,
                      child: Text(group.label),
                    ),
                  )
                  .toList(),
              onChanged: canChangeChannelGroup
                  ? (group) {
                      if (group != null) {
                        unawaited(onChannelGroupChanged(group));
                      }
                    }
                  : null,
            ),
            _ReservedSettingsDescriptionRegion(
              isNarrow: isNarrow,
              message: _channelGroupDescription(),
            ),
            _ReservedSettingsStatusRegion(
              isNarrow: isNarrow,
              message: _channelGroupStatus(),
            ),
            _RecoveryActionSlot(
              visible: state.hasPendingChannelGroupChange,
              actionKey: const Key('ntx8cv-retry-channel-group-change'),
              enabled: isConnected && !state.isBusy,
              onPressed: onRetryChannelGroupChange,
            ),
          ],
        ),
      ),
    );
  }

  bool get _audioChannelsApply =>
      !state.modeRebootRequired &&
      switch (state.confirmedMode) {
        Ntx8cvExpansionMode.audio1x8_32bit ||
        Ntx8cvExpansionMode.audio2x8_16bit => true,
        _ => false,
      };

  String _audioChannelsDescription() {
    if (!isConnected) {
      return 'Connect an NTX-8CV to read its audio-channel enable settings.';
    }
    if (!state.modeCapabilityEvidenced) {
      return 'Audio-channel controls remain unavailable until Mode is evidenced.';
    }
    if (state.modeRebootRequired) {
      return 'Audio-channel changes are unavailable until the confirmed Mode change is applied by rebooting the NTX-8CV.';
    }
    if (!_audioChannelsApply) {
      return 'Audio channels are not applicable while the device-confirmed Mode is 8x8 CV.';
    }
    return 'Each channel is read from the selected NTX-8CV and changes require matching readback.';
  }

  String _audioChannelStatus(Ntx8cvAudioChannel channel) {
    final change = state.audioChannelChange(channel);
    if (!isConnected) {
      return 'Connect to read the device-confirmed state.';
    }
    if (state.modeRebootRequired) {
      return 'Unavailable until the confirmed Mode change is applied by rebooting the NTX-8CV.';
    }
    if (!_audioChannelsApply) {
      return 'Unavailable: this channel applies only in an audio expansion mode.';
    }
    if (change.hasPendingChange) {
      final attempted = state.attemptedAudioChannelEnabled(channel);
      final confirmed = state.confirmedAudioChannelEnabled(channel);
      final progress = change.isWriting
          ? 'Sending and waiting for device readback.'
          : change.message ?? 'The actual device state is uncertain.';
      return 'Attempted ${attempted == true ? 'enabled' : 'disabled'}, '
          'pending/failed and not device-confirmed. '
          '${confirmed == null ? 'No device-confirmed value is available.' : 'Last device-confirmed value: ${confirmed ? 'enabled' : 'disabled'}.'} '
          '$progress';
    }
    if (change.isLoading) return 'Reading this channel from the NTX-8CV.';
    final confirmed = state.confirmedAudioChannelEnabled(channel);
    if (confirmed != null) {
      return 'Device-confirmed: ${confirmed ? 'enabled' : 'disabled'}.';
    }
    return change.message ?? 'No device-confirmed value is available.';
  }

  String _channelGroupDescription() {
    if (!isConnected) return 'Connect an NTX-8CV to read this setting.';
    if (state.confirmedChannelGroup == null) {
      return 'Waiting for a device-confirmed value.';
    }
    return 'Selects this NTX-8CV’s eight-channel block. It does not enable '
        'individual audio channels or alter disting NT algorithm routing. '
        'Changes are sent immediately and confirmed by reading the setting back.';
  }

  String _es5Description() {
    if (!isConnected) return 'Connect an NTX-8CV to read this setting.';
    if (state.confirmedEs5Enabled == null) {
      return 'Waiting for a device-confirmed value.';
    }
    return 'Changes are sent immediately and confirmed by reading the setting back.';
  }

  String _modeDescription() {
    if (!isConnected) return 'Connect an NTX-8CV to probe this setting.';
    if (!state.modeCapabilityEvidenced) {
      return state.modeMessage ?? 'Mode capability has not been evidenced.';
    }
    return 'Changes are sent immediately and take effect after reboot.';
  }

  String _channelGroupStatus() {
    if (state.hasPendingChannelGroupChange) {
      final attempted =
          state.attemptedChannelGroup?.label ?? 'an invalid value';
      final confirmed = state.confirmedChannelGroup == null
          ? 'No device-confirmed value is available.'
          : 'Last device-confirmed value: '
                '${state.confirmedChannelGroup!.label}.';
      final progress = state.isWritingChannelGroup
          ? 'Sending and waiting for device readback.'
          : state.channelGroupMessage ??
                'The actual device state is uncertain.';
      return 'Attempted Channel Group: $attempted, pending/failed and not '
          'device-confirmed. $confirmed $progress';
    }
    if (state.isLoadingChannelGroup) {
      return 'Reading Channel Group from the NTX-8CV.';
    }
    if (state.confirmedChannelGroup != null) {
      return 'Device-confirmed Channel Group: '
          '${state.confirmedChannelGroup!.label}.';
    }
    return state.channelGroupMessage ??
        'No device-confirmed Channel Group value is available.';
  }

  String _es5Status() {
    if (state.hasPendingEs5Change) {
      final attempted = state.attemptedEs5Enabled! ? 'enabled' : 'disabled';
      final confirmed = state.confirmedEs5Enabled == null
          ? 'No device-confirmed value is available.'
          : 'Last device-confirmed value: '
                '${state.confirmedEs5Enabled! ? 'enabled' : 'disabled'}.';
      final progress = state.isWritingEs5
          ? 'Sending and waiting for device readback.'
          : state.es5Message ?? 'The actual device state is uncertain.';
      return 'Attempted ES-5 value: $attempted, pending/failed and not '
          'device-confirmed. $confirmed $progress';
    }
    if (state.isLoadingEs5) return 'Reading ES-5 setting from the NTX-8CV.';
    if (state.confirmedEs5Enabled != null) {
      return 'Device-confirmed ES-5 value: '
          '${state.confirmedEs5Enabled! ? 'enabled' : 'disabled'}.';
    }
    return state.es5Message ?? 'No device-confirmed ES-5 value is available.';
  }

  String _modeStatus() {
    if (state.hasPendingModeChange) {
      final attempted = state.attemptedMode?.label ?? 'an invalid value';
      final confirmed = state.confirmedMode == null
          ? 'No device-confirmed value is available.'
          : 'Last device-confirmed value: ${state.confirmedMode!.label}.';
      final progress = state.isWritingMode
          ? 'Sending and waiting for device readback.'
          : state.modeMessage ?? 'The actual device state is uncertain.';
      return 'Attempted NT expansion mode: $attempted, pending/failed and not '
          'device-confirmed. $confirmed $progress';
    }
    if (state.isLoadingMode) {
      return 'Probing NT expansion mode capability from the NTX-8CV.';
    }
    if (!state.modeCapabilityEvidenced) {
      return state.modeMessage ?? 'Mode capability has not been evidenced.';
    }
    final confirmed = state.confirmedMode;
    if (confirmed == null) {
      return 'No device-confirmed mode value is available.';
    }
    final reboot = state.modeRebootRequired
        ? ' Reboot required: this confirmed Mode change is stored but does '
              'not take effect until this NTX-8CV is rebooted.'
        : '';
    return 'Device-confirmed NT expansion mode: ${confirmed.label}.$reboot';
  }
}

/// Keeps explanatory text from changing a dropdown's rendered height.
class _ReservedSettingsDescriptionRegion extends StatelessWidget {
  const _ReservedSettingsDescriptionRegion({
    required this.isNarrow,
    required this.message,
  });

  final bool isNarrow;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isNarrow ? 56 : 40,
      child: Text(
        message,
        maxLines: isNarrow ? 3 : 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Reserves enough vertical room for all lifecycle and recovery text without
/// allowing a transient message to move adjacent settings controls.
class _ReservedSettingsStatusRegion extends StatelessWidget {
  const _ReservedSettingsStatusRegion({
    required this.isNarrow,
    required this.message,
    this.isError = false,
  });

  final bool isNarrow;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isNarrow ? 72 : 56,
      child: message.isEmpty
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.topLeft,
              child: Semantics(
                liveRegion: true,
                label: message,
                child: ExcludeSemantics(
                  child: SingleChildScrollView(
                    primary: false,
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isError
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Keeps recovery actions from changing the settings card's geometry.
class _RecoveryActionSlot extends StatelessWidget {
  const _RecoveryActionSlot({
    required this.visible,
    required this.actionKey,
    required this.enabled,
    required this.onPressed,
  });

  final bool visible;
  final Key actionKey;
  final bool enabled;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: visible
          ? Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: actionKey,
                onPressed: enabled
                    ? () {
                        unawaited(onPressed());
                      }
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry send'),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _AudioChannelTile extends StatelessWidget {
  const _AudioChannelTile({
    super.key,
    required this.isNarrow,
    required this.channel,
    required this.confirmedEnabled,
    required this.isWriting,
    required this.hasPendingChange,
    required this.status,
    required this.enabled,
    required this.onChanged,
    required this.onRetry,
  });

  final bool isNarrow;
  final Ntx8cvAudioChannel channel;
  final bool? confirmedEnabled;
  final bool isWriting;
  final bool hasPendingChange;
  final String status;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isNarrow ? 132 : 116,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: '${channel.label}. $status',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(channel.label),
              subtitle: SizedBox(
                height: 36,
                child: ExcludeSemantics(
                  child: Tooltip(
                    message: status,
                    child: Text(
                      status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              value: confirmedEnabled ?? false,
              onChanged: enabled ? onChanged : null,
              secondary: isWriting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),
          SizedBox(
            height: 32,
            child: hasPendingChange
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: Key('ntx8cv-retry-audio-channel-${channel.number}'),
                      onPressed: enabled ? onRetry : null,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry send'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
