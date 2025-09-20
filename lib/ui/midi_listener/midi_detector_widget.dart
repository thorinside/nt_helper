import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

import 'midi_listener_cubit.dart';

/// Detect MIDI devices, connect, and watch CC messages.
/// If an ancestor MidiListenerCubit is found, use it.
/// Otherwise, create and own a MidiListenerCubit locally.
class MidiDetectorWidget extends StatelessWidget {
  final Function({
    required MidiEventType type,
    required int channel,
    required int number, // CC or Note number
  })?
  onMidiEventFound;

  const MidiDetectorWidget({super.key, this.onMidiEventFound});

  @override
  Widget build(BuildContext context) {
    // Try to find an existing MidiListenerCubit in the current context
    // If none is found, an exception is thrown.
    // We can catch that to decide whether we create a local Cubit or not.
    try {
      context.read<MidiListenerCubit>();
      // If we get here, there's already a MidiListenerCubit in the ancestor tree
      return _MidiDetectorContents(
        onMidiEventFound: onMidiEventFound,
        useLocalCubit: false, // We'll use the existing one
      );
    } catch (_) {
      // No MidiListenerCubit exists above, so we create a local one
      return BlocProvider(
        create: (_) => MidiListenerCubit(),
        child: _MidiDetectorContents(
          onMidiEventFound: onMidiEventFound,
          useLocalCubit: true,
        ),
      );
    }
  }
}

/// The actual UI/stateful logic for the MIDI detector.
/// This widget **expects** a MidiListenerCubit to be in the widget tree.
/// If [useLocalCubit] is true, we created one ourselves in the parent;
/// otherwise, we rely on an ancestor-provided Cubit.
class _MidiDetectorContents extends StatefulWidget {
  final Function({
    required MidiEventType type,
    required int channel,
    required int number,
  })?
  onMidiEventFound;
  final bool useLocalCubit;

  const _MidiDetectorContents({
    required this.onMidiEventFound,
    required this.useLocalCubit,
  });

  @override
  State<_MidiDetectorContents> createState() => _MidiDetectorContentsState();
}

class _MidiDetectorContentsState extends State<_MidiDetectorContents> {
  late MidiListenerCubit _cubit;
  List<MidiDevice> _devices = [];
  MidiDevice? _selectedDevice;

  String? _statusMessage;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    // Access the Cubit from the context
    _cubit = context.read<MidiListenerCubit>();

    final s = _cubit.state;
    if (s is Initial) {
      _cubit.discoverDevices().then((devices) {
        if (mounted) {
          setState(() => _devices = devices ?? []);
        }
      });
    } else if (s is Data) {
      setState(() {
        _devices = s.devices;
        _selectedDevice = s.selectedDevice;
      });
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();

    if (widget.useLocalCubit) {
      _cubit.close();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card.outlined(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('MIDI Detector', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildDeviceDropdown(),
            const SizedBox(height: 16),
            BlocConsumer<MidiListenerCubit, MidiListenerState>(
              listener: (context, state) {
                switch (state) {
                  case Initial():
                    _showStatusMessage('No device connected.');
                  case Data(
                    :final isConnected,
                    :final selectedDevice,
                    :final lastDetectedType,
                    :final lastDetectedChannel,
                    :final lastDetectedCc,
                    :final lastDetectedNote,
                  ):
                    if (isConnected) {
                      _showStatusMessage(
                        'Connected to ${selectedDevice?.name}.',
                      );
                    } else {
                      _showStatusMessage('No device connected.');
                    }
                    if (lastDetectedType != null &&
                        lastDetectedChannel != null) {
                      final (String, int?)
                      eventInfo = switch (lastDetectedType) {
                        MidiEventType.cc => ('CC', lastDetectedCc),
                        MidiEventType.noteOn => ('Note On', lastDetectedNote),
                        MidiEventType.noteOff => ('Note Off', lastDetectedNote),
                      };

                      final eventNumber = eventInfo.$2;
                      if (eventNumber != null) {
                        final eventTypeStr = eventInfo.$1;
                        _showStatusMessage(
                          'Detected $eventTypeStr $eventNumber on channel ${lastDetectedChannel + 1}',
                        );
                        widget.onMidiEventFound?.call(
                          type: lastDetectedType,
                          channel: lastDetectedChannel,
                          number: eventNumber,
                        );
                      }
                    }
                }
              },
              builder: (context, state) {
                return _buildAnimatedStatus(theme);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceDropdown() {
    final entries = _devices.map((device) {
      return DropdownMenuEntry<MidiDevice>(value: device, label: device.name);
    }).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownMenu<MidiDevice>(
          width: 200,
          requestFocusOnTap: false,
          label: const Text('MIDI Device'),
          initialSelection: _selectedDevice,
          dropdownMenuEntries: entries,
          onSelected: _onDeviceSelected,
        ),
        const SizedBox(width: 8),
        BlocBuilder<MidiListenerCubit, MidiListenerState>(
          builder: (context, state) {
            final isConnected = state is Data && state.isConnected;
            return ElevatedButton.icon(
              onPressed: isConnected ? _onDisconnectPressed : null,
              icon: const Icon(Icons.close),
              label: const Text('Disconnect'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedStatus(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: SizedBox(
        height: 24,
        child: _statusMessage != null
            ? Text(
                _statusMessage!,
                key: ValueKey(_statusMessage),
                style: theme.textTheme.bodyMedium,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  void _onDeviceSelected(MidiDevice? device) {
    if (device == null) return;
    setState(() => _selectedDevice = device);
    _cubit.connectToDevice(device);
  }

  void _onDisconnectPressed() {
    setState(() => _selectedDevice = null);
    _cubit.disconnectDevice();
  }

  void _showStatusMessage(String newMessage) {
    setState(() {
      _statusMessage = newMessage;
    });
    _fadeTimer?.cancel();
    _fadeTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _statusMessage = null;
      });
    });
  }
}
