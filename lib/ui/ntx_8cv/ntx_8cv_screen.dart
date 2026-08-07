import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/cubit/ntx_8cv_connection_cubit.dart';
import 'package:nt_helper/utils/responsive.dart';

/// The primary page for configuring a separately connected NTX-8CV.
class Ntx8cvScreen extends StatefulWidget {
  const Ntx8cvScreen({super.key, this.connectionCubit});

  /// Supplying a cubit is useful for embedding and automated tests.
  final Ntx8cvConnectionCubit? connectionCubit;

  @override
  State<Ntx8cvScreen> createState() => _Ntx8cvScreenState();
}

class _Ntx8cvScreenState extends State<Ntx8cvScreen> {
  late final Ntx8cvConnectionCubit _connectionCubit;
  late final bool _ownsConnectionCubit;
  final TextEditingController _deviceIdController = TextEditingController(
    text: '0',
  );

  @override
  void initState() {
    super.initState();
    _ownsConnectionCubit = widget.connectionCubit == null;
    _connectionCubit = widget.connectionCubit ?? Ntx8cvConnectionCubit();
    unawaited(_connectionCubit.initialize());
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
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
                          onRefresh: _connectionCubit.refreshEndpoints,
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
                      const _SettingsSection(),
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
                Semantics(
                  liveRegion: true,
                  label: 'NTX-8CV connection status: ${state.statusLabel}',
                  child: Chip(
                    avatar: Icon(_statusIcon(state.status)),
                    label: Text(state.statusLabel),
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
            if (state.statusMessage != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  state.statusMessage!,
                  style: TextStyle(
                    color: state.status == Ntx8cvConnectionStatus.failed
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              ),
            ],
            if (state.isConnected) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: const Text(
                  'Device information verified from the selected MIDI input.',
                ),
              ),
            ],
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
          child: controls.button(),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect an NTX-8CV to read and configure its settings. The '
              'NTX-8CV Channel Group remains separate from the disting NT’s '
              'granular channel-enable controls.',
            ),
          ],
        ),
      ),
    );
  }
}
