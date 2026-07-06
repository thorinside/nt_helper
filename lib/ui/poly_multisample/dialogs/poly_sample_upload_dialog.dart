import 'package:flutter/material.dart';

enum PolySampleUploadPath { sysex, mountedSd }

Future<PolySampleUploadPath?> showPolySampleUploadPathDialog(
  BuildContext context, {
  required bool sysexAvailable,
}) {
  return showDialog<PolySampleUploadPath>(
    context: context,
    builder: (context) {
      return _PolySampleUploadDialog(sysexAvailable: sysexAvailable);
    },
  );
}

class _PolySampleUploadDialog extends StatelessWidget {
  const _PolySampleUploadDialog({required this.sysexAvailable});

  final bool sysexAvailable;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Semantics(header: true, child: const Text('Upload sample folder')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select how to send this sample folder to the Disting NT.',
            ),
            ListTile(
              leading: const Icon(Icons.cable, semanticLabel: 'SysEx upload'),
              title: const Text('SysEx to NT hardware'),
              subtitle: Text(
                sysexAvailable
                    ? 'Uses MIDI SysEx and verifies each uploaded file.'
                    : 'Connect to Disting NT to use SysEx upload.',
              ),
              enabled: sysexAvailable,
              onTap: sysexAvailable
                  ? () => Navigator.of(context).pop(PolySampleUploadPath.sysex)
                  : null,
            ),
            ListTile(
              leading: const Icon(
                Icons.sd_storage,
                semanticLabel: 'Mounted SD-card upload',
              ),
              title: const Text('Mounted SD-card folder'),
              subtitle: const Text(
                'Copies files to a mounted SD-card filesystem folder.',
              ),
              onTap: () =>
                  Navigator.of(context).pop(PolySampleUploadPath.mountedSd),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
