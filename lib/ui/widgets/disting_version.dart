import 'package:flutter/material.dart';
import 'package:nt_helper/models/firmware_version.dart';

class DistingVersion extends StatelessWidget {
  const DistingVersion({
    super.key,
    required this.distingVersion,
    required this.requiredVersion,
  });

  final String distingVersion;
  final String requiredVersion;

  @override
  Widget build(BuildContext context) {
    final isNotSupported = !FirmwareVersion(
      distingVersion,
    ).isSupported(requiredVersion);
    return Tooltip(
      message: isNotSupported
          ? "nt_helper requires at least $requiredVersion"
          : "",
      child: Text(
        distingVersion,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isNotSupported
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
