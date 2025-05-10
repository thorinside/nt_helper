import 'dart:async'; // For Timer
import 'dart:math'; // For pow()
import 'package:flutter/gestures.dart'; // For kDoubleTapTimeout

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:nt_helper/services/settings_service.dart'; // Required for Haptics and SettingsService

// New BPM Editor Widget
class BpmEditorWidget extends StatefulWidget {
  final int initialValue;
  final int min;
  final int max;
  final int powerOfTen;
  final Function(int) onChanged;
  final Function(bool) onEditingStatusChanged; // To inform parent about focus

  const BpmEditorWidget({
    super.key,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.powerOfTen,
    required this.onChanged,
    required this.onEditingStatusChanged,
  });

  @override
  State<BpmEditorWidget> createState() => _BpmEditorWidgetState();
}

class _BpmEditorWidgetState extends State<BpmEditorWidget> {
  late TextEditingController _textController;
  late int _currentBpm;
  final FocusNode _focusNode = FocusNode();

  Timer? _longPressAccelerationTimer;
  int _accelerationMultiplier = 1;
  static const Duration _initialAccelerationDelay = Duration(milliseconds: 400);
  static const Duration _acceleratingInterval = Duration(milliseconds: 80);
  static const int _maxAccelerationMultiplier =
      20; // Max raw step value for acceleration

  Timer? _tapVerificationTimer; // Timer to verify if tap becomes long press
  bool _didPerformInitialStep = false; // Track if onTapDown executed a step
  bool _initialStepWasIncrement =
      false; // Track the direction of the initial step

  @override
  void initState() {
    super.initState();
    _currentBpm = widget.initialValue;
    _textController =
        TextEditingController(text: _formatBpmForDisplay(_currentBpm));
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(BpmEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _currentBpm && !_focusNode.hasFocus) {
      _currentBpm = widget.initialValue;
      _textController.text = _formatBpmForDisplay(_currentBpm);
    }
  }

  void _handleFocusChange() {
    widget.onEditingStatusChanged(_focusNode.hasFocus);
    if (!_focusNode.hasFocus) {
      _validateAndSubmit();
    }
  }

  String _formatBpmForDisplay(int rawBpm) {
    if (widget.powerOfTen == 0) {
      return rawBpm.toString();
    }
    double displayValue = rawBpm / pow(10, widget.powerOfTen);
    return displayValue.toStringAsFixed(widget.powerOfTen);
  }

  void _validateAndSubmit() {
    final textValue = _textController.text;
    double? parsedDisplayValue = double.tryParse(textValue);

    if (parsedDisplayValue != null) {
      int newRawBpm = (parsedDisplayValue * pow(10, widget.powerOfTen)).round();
      newRawBpm = newRawBpm.clamp(widget.min, widget.max);

      if (newRawBpm != _currentBpm) {
        setState(() {
          _currentBpm = newRawBpm;
        });
        widget.onChanged(_currentBpm);
      }
      // Always update text controller to reflect clamped and correctly formatted value
      _textController.text = _formatBpmForDisplay(_currentBpm);
    } else {
      // If parsing fails, revert to the last valid BPM, correctly formatted
      _textController.text = _formatBpmForDisplay(_currentBpm);
    }
  }

  // Renamed from _executeSingleStep for clarity
  void _performSingleStep(bool increment, {bool isUndo = false}) {
    // If it's an undo, we reverse the original direction
    bool actualIncrement = isUndo ? !_initialStepWasIncrement : increment;

    if (actualIncrement) {
      if (_currentBpm < widget.max) {
        setState(() {
          _currentBpm++;
          _textController.text = _formatBpmForDisplay(_currentBpm);
        });
        if (!isUndo) widget.onChanged(_currentBpm);
      }
    } else {
      if (_currentBpm > widget.min) {
        setState(() {
          _currentBpm--;
          _textController.text = _formatBpmForDisplay(_currentBpm);
        });
        if (!isUndo) widget.onChanged(_currentBpm);
      }
    }
    // Haptics only for initial, non-undo actions, triggered by onTapDown directly
  }

  void _handleIconButtonTap(bool increment) {
    if (SettingsService().hapticsEnabled) Haptics.vibrate(HapticsType.light);

    _performSingleStep(increment);
    _didPerformInitialStep = true;
    _initialStepWasIncrement = increment;

    _tapVerificationTimer?.cancel();
    _tapVerificationTimer = Timer(kDoubleTapTimeout, () {
      _didPerformInitialStep = false;
    });
  }

  void _startAcceleratedChange(bool increment) {
    _tapVerificationTimer?.cancel();

    if (_didPerformInitialStep) {
      _performSingleStep(!_initialStepWasIncrement, isUndo: true);
      _didPerformInitialStep = false;
    }

    _stopAcceleratedChange(performSnap: false);
    _accelerationMultiplier = 1;
    _longPressAccelerationTimer =
        Timer.periodic(_initialAccelerationDelay, (timerAfterDelay) {
      timerAfterDelay.cancel();
      _performAcceleratedStep(increment);
      _longPressAccelerationTimer = Timer.periodic(_acceleratingInterval, (_) {
        _performAcceleratedStep(increment);
      });
    });
  }

  void _performAcceleratedStep(bool increment) {
    if (!mounted) {
      _stopAcceleratedChange(performSnap: false);
      return;
    }
    setState(() {
      final step = _accelerationMultiplier;
      if (increment) {
        _currentBpm = (_currentBpm + step).clamp(widget.min, widget.max);
      } else {
        _currentBpm = (_currentBpm - step).clamp(widget.min, widget.max);
      }
      _textController.text = _formatBpmForDisplay(_currentBpm);
      if (_accelerationMultiplier < _maxAccelerationMultiplier) {
        _accelerationMultiplier = (_accelerationMultiplier * 1.25)
            .ceil()
            .clamp(1, _maxAccelerationMultiplier);
      }
    });
    widget.onChanged(_currentBpm);
    if (SettingsService().hapticsEnabled)
      Haptics.vibrate(HapticsType.selection);

    if ((increment && _currentBpm == widget.max) ||
        (!increment && _currentBpm == widget.min)) {
      _stopAcceleratedChange(performSnap: false);
    }
  }

  void _stopAcceleratedChange({required bool performSnap}) {
    _longPressAccelerationTimer?.cancel();
    _longPressAccelerationTimer = null;
    _didPerformInitialStep = false;

    if (performSnap && widget.powerOfTen > 0) {
      double displayedValue = _currentBpm / pow(10, widget.powerOfTen);
      double roundedDisplayValue = displayedValue.roundToDouble();
      int snappedRawBpm =
          (roundedDisplayValue * pow(10, widget.powerOfTen)).round();

      snappedRawBpm = snappedRawBpm.clamp(widget.min, widget.max);

      if (_currentBpm != snappedRawBpm) {
        setState(() {
          _currentBpm = snappedRawBpm;
          _textController.text = _formatBpmForDisplay(_currentBpm);
        });
        widget.onChanged(_currentBpm);
      }
    }
    _accelerationMultiplier = 1;
  }

  @override
  Widget build(BuildContext context) {
    bool widescreen = MediaQuery.of(context).size.width > 600;
    final textStyle = widescreen
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleSmall;
    final iconSize = widescreen ? 28.0 : 24.0;
    final splashRadius = widescreen ? 28.0 : 24.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onLongPressStart: (_) => _startAcceleratedChange(false),
          onLongPressEnd: (_) => _stopAcceleratedChange(performSnap: true),
          onLongPressCancel: () => _stopAcceleratedChange(performSnap: false),
          child: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: iconSize,
            splashRadius: splashRadius,
            onPressed: () => _handleIconButtonTap(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _textController,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType:
                TextInputType.numberWithOptions(decimal: widget.powerOfTen > 0),
            style: textStyle?.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                  vertical: (widescreen ? 14.0 : 10.0) - 2.0, horizontal: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixText: " BPM",
              suffixStyle: textStyle?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.normal),
            ),
            onSubmitted: (_) => _validateAndSubmit(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(widget.powerOfTen > 0 ? r'[0-9.]' : r'[0-9]')),
              if (widget.powerOfTen > 0)
                DecimalTextInputFormatter(decimalRange: widget.powerOfTen),
              LengthLimitingTextInputFormatter(
                  widget.powerOfTen > 0 ? 3 + widget.powerOfTen + 1 : 3),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onLongPressStart: (_) => _startAcceleratedChange(true),
          onLongPressEnd: (_) => _stopAcceleratedChange(performSnap: true),
          onLongPressCancel: () => _stopAcceleratedChange(performSnap: false),
          child: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            iconSize: iconSize,
            splashRadius: splashRadius,
            onPressed: () => _handleIconButtonTap(true),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _longPressAccelerationTimer?.cancel();
    _tapVerificationTimer?.cancel();
    _stopAcceleratedChange(performSnap: false);
    _textController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }
}

// Helper class for input formatting to allow only one decimal point and control decimal places
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalTextInputFormatter({required this.decimalRange});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;
    if (newText.contains('.')) {
      if (newText.substring(newText.indexOf('.') + 1).length > decimalRange) {
        return oldValue;
      }
      if (newText.indexOf('.') != newText.lastIndexOf('.')) {
        // More than one decimal point
        return oldValue;
      }
    }
    return newValue;
  }
}
