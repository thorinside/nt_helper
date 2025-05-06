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
  })? onMidiEventFound;

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
  })? onMidiEventFound;
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

    _cubit.state.mapOrNull(
      initial: (_) => _cubit.discoverDevices().then(
        (devices) {
          setState(
            () {
              _devices = devices ?? [];
            },
          );
        },
      ),
      data: (value) => setState(
        () {
          _devices = value.devices;
          _selectedDevice = value.selectedDevice;
        },
      ),
    );
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
              listener: (context, state) => state.map(
                initial: (_) => _showStatusMessage('No device connected.'),
                data: (value) {
                  if (value.isConnected) {
                    _showStatusMessage(
                        'Connected to ${value.selectedDevice?.name}.');
                  } else if (!value.isConnected) {
                    _showStatusMessage('No device connected.');
                  }
                  if (value.lastDetectedType != null &&
                      value.lastDetectedChannel != null) {
                    String eventTypeStr = '';
                    int? eventNumber;
                    switch (value.lastDetectedType!) {
                      case MidiEventType.cc:
                        eventTypeStr = 'CC';
                        eventNumber = value.lastDetectedCc;
                        break;
                      case MidiEventType.noteOn:
                        eventTypeStr = 'Note On';
                        eventNumber = value.lastDetectedNote;
                        break;
                      case MidiEventType.noteOff:
                        eventTypeStr = 'Note Off';
                        eventNumber = value.lastDetectedNote;
                        break;
                    }

                    if (eventNumber != null) {
                      _showStatusMessage(
                          'Detected $eventTypeStr $eventNumber on channel ${value.lastDetectedChannel! + 1}');
                      widget.onMidiEventFound?.call(
                          type: value.lastDetectedType!,
                          channel: value.lastDetectedChannel!,
                          number: eventNumber);
                    }
                  }
                  return null;
                },
              ),
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
      return DropdownMenuEntry<MidiDevice>(
        value: device,
        label: device.name,
      );
    }).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownMenu<MidiDevice>(
          width: 250,
          requestFocusOnTap: false,
          label: const Text('MIDI Device'),
          initialSelection: _selectedDevice,
          dropdownMenuEntries: entries,
          onSelected: _onDeviceSelected,
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
