import 'package:flutter/material.dart';

enum PolySampleUploadPath { sysex, mountedSd }

class PolySampleUploadChoice {
  const PolySampleUploadChoice({
    required this.path,
    this.verifyAfterUpload = false,
  });

  final PolySampleUploadPath path;
  final bool verifyAfterUpload;
}

Future<PolySampleUploadChoice?> showPolySampleUploadPathDialog(
  BuildContext context, {
  required bool sysexAvailable,
}) {
  return showDialog<PolySampleUploadChoice>(
    context: context,
    builder: (context) {
      return _PolySampleUploadDialog(sysexAvailable: sysexAvailable);
    },
  );
}

class _PolySampleUploadDialog extends StatefulWidget {
  const _PolySampleUploadDialog({required this.sysexAvailable});

  final bool sysexAvailable;

  @override
  State<_PolySampleUploadDialog> createState() =>
      _PolySampleUploadDialogState();
}

class _PolySampleUploadDialogState extends State<_PolySampleUploadDialog> {
  bool _verifyAfterUpload = false;

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
                widget.sysexAvailable
                    ? 'Uses MIDI SysEx. Optional verification reads every uploaded WAV back in chunks.'
                    : 'Connect to Disting NT to use SysEx upload.',
              ),
              enabled: widget.sysexAvailable,
              onTap: widget.sysexAvailable
                  ? () => Navigator.of(context).pop(
                      PolySampleUploadChoice(
                        path: PolySampleUploadPath.sysex,
                        verifyAfterUpload: _verifyAfterUpload,
                      ),
                    )
                  : null,
            ),
            CheckboxListTile(
              value: _verifyAfterUpload,
              onChanged: widget.sysexAvailable
                  ? (value) {
                      setState(() => _verifyAfterUpload = value ?? false);
                    }
                  : null,
              title: const Text('Verify after upload'),
              subtitle: const Text(
                'Slower, but checks the files on the NT after the upload finishes.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
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
              onTap: () => Navigator.of(context).pop(
                const PolySampleUploadChoice(
                  path: PolySampleUploadPath.mountedSd,
                ),
              ),
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
