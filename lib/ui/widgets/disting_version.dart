import 'package:flutter/material.dart';
import 'package:nt_helper/models/firmware_version.dart';

class DistingVersion extends StatelessWidget {
  const DistingVersion({
    super.key,
    required this.distingVersion,
    required this.requiredVersion,
    this.onTap,
  });

  final String distingVersion;
  final String requiredVersion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isNotSupported = !FirmwareVersion(
      distingVersion,
    ).isSupported(requiredVersion);

    final text = Text(
      distingVersion,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: isNotSupported
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );

    final tooltip = Tooltip(
      message: isNotSupported
          ? "nt_helper requires at least $requiredVersion"
          : onTap != null
              ? "Tap to manage firmware"
              : "",
      child: text,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: tooltip,
        ),
      );
    }

    return tooltip;
  }
}
