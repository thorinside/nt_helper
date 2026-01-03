import 'package:flutter/material.dart';
import 'package:nt_helper/models/firmware_version.dart';

class DistingVersion extends StatelessWidget {
  const DistingVersion({
    super.key,
    required this.distingVersion,
    required this.requiredVersion,
    this.onTap,
    this.onHelpTextChanged,
  });

  final String distingVersion;
  final String requiredVersion;
  final VoidCallback? onTap;
  final ValueChanged<String?>? onHelpTextChanged;

  static const String firmwareHelpText = 'Tap: Manage firmware updates';

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

    // Only show tooltip if contextual help is not available
    final showTooltip = onHelpTextChanged == null;
    final tooltipMessage = isNotSupported
        ? "nt_helper requires at least $requiredVersion"
        : onTap != null
        ? "Tap to manage firmware"
        : "";

    Widget content = text;
    if (showTooltip && tooltipMessage.isNotEmpty) {
      content = Tooltip(message: tooltipMessage, child: text);
    }

    if (onTap != null) {
      return MouseRegion(
        onEnter: (_) => onHelpTextChanged?.call(firmwareHelpText),
        onExit: (_) => onHelpTextChanged?.call(null),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
