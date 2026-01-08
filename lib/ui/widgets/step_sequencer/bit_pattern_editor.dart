import 'package:flutter/material.dart';

/// Dedicated widget for editing 8-bit pattern parameters (Pattern/Ties)
/// Each bit is a separate clickable cell - much simpler than repurposing pitch bar
class BitPatternEditor extends StatelessWidget {
  final int value; // 0-255 bit pattern
  final Color color;
  final int validBitCount; // 1-8, based on division
  final ValueChanged<int> onChanged;

  const BitPatternEditor({
    super.key,
    required this.value,
    required this.color,
    required this.validBitCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(8, (index) {
        // Invert index: bit 7 at top, bit 0 at bottom
        final bitIndex = 7 - index;
        final isSet = (value >> bitIndex) & 1 == 1;
        final isValid = bitIndex < validBitCount;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 1.0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isValid
                  ? () {
                      // Toggle this bit
                      final newValue = value ^ (1 << bitIndex);
                      onChanged(newValue);
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: !isValid
                      ? Colors.grey.shade400.withValues(alpha: 0.4) // Disabled
                      : isSet
                      ? color // Filled
                      : null, // Empty
                  border: Border.all(
                    color: !isValid
                        ? Colors.grey.shade500
                        : isSet
                        ? color
                        : Colors.grey.shade400,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
