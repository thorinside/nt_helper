import 'package:flutter/material.dart';
import 'package:nt_helper/utils/responsive.dart';

/// The entry page for configuring a separately connected NTX-8CV.
///
/// Connection behavior and settings reads are added independently of the
/// disting NT connection. This page deliberately owns no [DistingCubit].
class Ntx8cvScreen extends StatelessWidget {
  const Ntx8cvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = Responsive.isMobile(context);
    final theme = Theme.of(context);

    return Scaffold(
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
                    _ConnectionSection(isNarrow: isNarrow),
                    const SizedBox(height: 16),
                    const _SettingsSection(),
                  ],
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
  const _ConnectionSection({required this.isNarrow});

  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
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
                Semantics(
                  liveRegion: true,
                  label: 'NTX-8CV connection status: Disconnected',
                  child: Chip(
                    avatar: Icon(Icons.link_off),
                    label: Text('Disconnected'),
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
              const _NarrowConnectionControls()
            else
              const _WideConnectionControls(),
          ],
        ),
      ),
    );
  }
}

class _WideConnectionControls extends StatelessWidget {
  const _WideConnectionControls();

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('ntx8cv-connection-controls-wide'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _MidiEndpointField(label: 'MIDI input')),
        SizedBox(width: 12),
        Expanded(child: _MidiEndpointField(label: 'MIDI output')),
        SizedBox(width: 12),
        Expanded(child: _DeviceIdField()),
        SizedBox(width: 12),
        Padding(
          padding: EdgeInsets.only(top: 4),
          child: Tooltip(
            message: 'Choose an NTX-8CV MIDI input and output to connect.',
            child: FilledButton.icon(
              onPressed: null,
              icon: Icon(Icons.link),
              label: Text('Connect'),
            ),
          ),
        ),
      ],
    );
  }
}

class _NarrowConnectionControls extends StatelessWidget {
  const _NarrowConnectionControls();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('ntx8cv-connection-controls-narrow'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MidiEndpointField(label: 'MIDI input'),
        SizedBox(height: 12),
        _MidiEndpointField(label: 'MIDI output'),
        SizedBox(height: 12),
        _DeviceIdField(),
        SizedBox(height: 16),
        Tooltip(
          message: 'Choose an NTX-8CV MIDI input and output to connect.',
          child: FilledButton.icon(
            onPressed: null,
            icon: Icon(Icons.link),
            label: Text('Connect'),
          ),
        ),
      ],
    );
  }
}

class _MidiEndpointField extends StatelessWidget {
  const _MidiEndpointField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: false,
      initialValue: 'No MIDI endpoint selected',
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _DeviceIdField extends StatelessWidget {
  const _DeviceIdField();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: false,
      initialValue: '0',
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'SysEx device ID',
        helperText: '0–126',
        border: OutlineInputBorder(),
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
