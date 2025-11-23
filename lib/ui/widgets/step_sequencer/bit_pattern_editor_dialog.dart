import 'package:flutter/material.dart';

/// Bit pattern editor dialog for Pattern and Ties parameters
///
/// Shows 8 circular toggle buttons for editing 8-bit values (0-255).
/// Each bit represents a substep or control state.
class BitPatternEditorDialog extends StatefulWidget {
  final int initialValue; // 0-255
  final String parameterName; // "Ties" or "Pattern"
  final Color color; // Color for the bit indicators

  const BitPatternEditorDialog({
    super.key,
    required this.initialValue,
    required this.parameterName,
    required this.color,
  });

  @override
  State<BitPatternEditorDialog> createState() => _BitPatternEditorDialogState();
}

class _BitPatternEditorDialogState extends State<BitPatternEditorDialog> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  /// Toggle a specific bit (0-7)
  void _toggleBit(int bit) {
    setState(() {
      _value ^= (1 << bit); // XOR to toggle bit
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text('Edit ${widget.parameterName} Bit Pattern'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 8 toggle buttons in horizontal row (bits 0-7, left to right)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(8, (bit) {
                final isSet = (_value >> bit) & 1 == 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    children: [
                      Text(
                        '$bit',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => _toggleBit(bit),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSet
                                ? widget.color.withValues(alpha: 0.8)
                                : Colors.transparent,
                            border: Border.all(
                              color: widget.color,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isSet
                                ? Icon(
                                    Icons.check,
                                    color: isDark ? Colors.white : Colors.white,
                                    size: 16,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Current value display (decimal and binary)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Value: $_value',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '0b${_value.toRadixString(2).padLeft(8, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Explanation text
          Text(
            'Each bit represents a substep connection or activation state.\nBit 0 (LSB) = Substep 0→1, Bit 7 (MSB) = Substep 7→8',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _value),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
