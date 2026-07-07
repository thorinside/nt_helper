import 'package:flutter/material.dart';

enum PolySampleUploadPath { sysex, mountedSd }

enum PolySampleMountedSdDestinationMode {
  ntMultisampleFolder,
  selectedFolder,
  createFolder,
}

class PolySampleUploadChoice {
  const PolySampleUploadChoice({required this.path});

  final PolySampleUploadPath path;
}

class PolySampleMountedSdDestinationChoice {
  const PolySampleMountedSdDestinationChoice({required this.mode});

  final PolySampleMountedSdDestinationMode mode;
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

Future<PolySampleMountedSdDestinationChoice?>
showPolySampleMountedSdDestinationDialog(
  BuildContext context, {
  required String selectedFolder,
  required String ntMultisampleFolder,
}) {
  return showDialog<PolySampleMountedSdDestinationChoice>(
    context: context,
    builder: (context) {
      return _PolySampleMountedSdDestinationDialog(
        selectedFolder: selectedFolder,
        ntMultisampleFolder: ntMultisampleFolder,
      );
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
              title: const Row(
                children: [
                  Flexible(child: Text('SysEx to NT hardware')),
                  SizedBox(width: 8),
                  _UploadSpeedBadge(label: 'Slow', isFast: false),
                ],
              ),
              subtitle: Text(
                widget.sysexAvailable
                    ? 'Uses MIDI SysEx and checks uploaded filenames and sizes.'
                    : 'Connect to Disting NT to use SysEx upload.',
              ),
              enabled: widget.sysexAvailable,
              onTap: widget.sysexAvailable
                  ? () => Navigator.of(context).pop(
                      const PolySampleUploadChoice(
                        path: PolySampleUploadPath.sysex,
                      ),
                    )
                  : null,
            ),
            ListTile(
              leading: const Icon(
                Icons.sd_storage,
                semanticLabel: 'Mounted SD-card upload',
              ),
              title: const Row(
                children: [
                  Flexible(child: Text('Mounted SD-card folder')),
                  SizedBox(width: 8),
                  _UploadSpeedBadge(label: 'Fast', isFast: true),
                ],
              ),
              subtitle: const Text(
                'Copies files to an SD card mounted on this computer.',
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

class _PolySampleMountedSdDestinationDialog extends StatelessWidget {
  const _PolySampleMountedSdDestinationDialog({
    required this.selectedFolder,
    required this.ntMultisampleFolder,
  });

  final String selectedFolder;
  final String ntMultisampleFolder;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Semantics(
        header: true,
        child: const Text('Mounted SD destination'),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              isThreeLine: true,
              leading: const Icon(
                Icons.rule_folder,
                semanticLabel: 'NT multisample folder',
              ),
              title: const Text('NT multisample folder'),
              subtitle: Text(
                '$ntMultisampleFolder\nSame folder layout used by SysEx uploads.',
              ),
              onTap: () => Navigator.of(context).pop(
                const PolySampleMountedSdDestinationChoice(
                  mode: PolySampleMountedSdDestinationMode.ntMultisampleFolder,
                ),
              ),
            ),
            ListTile(
              isThreeLine: true,
              leading: const Icon(
                Icons.folder,
                semanticLabel: 'Selected folder',
              ),
              title: const Text('Selected folder'),
              subtitle: Text(
                '$selectedFolder\nCopy directly into this folder.',
              ),
              onTap: () => Navigator.of(context).pop(
                const PolySampleMountedSdDestinationChoice(
                  mode: PolySampleMountedSdDestinationMode.selectedFolder,
                ),
              ),
            ),
            ListTile(
              isThreeLine: true,
              leading: const Icon(
                Icons.create_new_folder,
                semanticLabel: 'Create folder',
              ),
              title: const Text('Create folder'),
              subtitle: Text('$selectedFolder\nCreate a folder here first.'),
              onTap: () => Navigator.of(context).pop(
                const PolySampleMountedSdDestinationChoice(
                  mode: PolySampleMountedSdDestinationMode.createFolder,
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

class _UploadSpeedBadge extends StatelessWidget {
  const _UploadSpeedBadge({required this.label, required this.isFast});

  final String label;
  final bool isFast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isFast
            ? colorScheme.tertiaryContainer
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isFast
              ? colorScheme.onTertiaryContainer
              : colorScheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
