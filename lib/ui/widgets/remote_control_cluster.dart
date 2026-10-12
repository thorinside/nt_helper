import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/models/remote_action.dart';
import 'package:nt_helper/models/remote_control_state.dart';
import 'package:nt_helper/ui/theme/app_theme.dart';

/// Hardware-shaped inputs shared by video hosts. Connection state, local pot
/// values and command ordering remain at the main connection authority.
class RemoteControlCluster extends StatefulWidget {
  const RemoteControlCluster({
    super.key,
    required this.state,
    required this.onAction,
    required this.onPotAdjustment,
  });

  static const double height = 252;
  final RemoteControlState state;
  final ValueChanged<RemoteAction> onAction;
  final void Function(int index, int adjustment) onPotAdjustment;

  @override
  State<RemoteControlCluster> createState() => _RemoteControlClusterState();
}

class _RemoteControlClusterState extends State<RemoteControlCluster> {
  int _inputGeneration = 0;

  void _releaseFocusGroup() {
    if (!mounted) return;
    setState(() => _inputGeneration++);
    for (final index in widget.state.heldControls) {
      widget.onAction(RemoteRelease(index));
    }
  }

  Widget _control(int pushIndex, String name, {int? pot, int? encoder}) {
    return _RemoteControl(
      key: ValueKey('remote-control-$pushIndex'),
      name: name,
      pushIndex: pushIndex,
      potIndex: pot,
      encoderIndex: encoder,
      potValue: pot == null ? null : widget.state.potValues[pot],
      pressed: widget.state.heldControls.contains(pushIndex),
      enabled: widget.state.available && widget.state.sessionId != null,
      inputIdentity: (widget.state.sessionId, _inputGeneration),
      onAction: widget.onAction,
      onPotAdjustment: widget.onPotAdjustment,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedback =
        widget.state.error ??
        widget.state.unavailableReason ??
        (widget.state.pending
            ? 'Sending remote input…'
            : 'Local inputs, not hardware positions');
    return FocusTraversalGroup(
      // Keep traversal independent of scroll offsets at narrow host widths.
      policy: WidgetOrderTraversalPolicy(),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) {
          if (!focused) _releaseFocusGroup();
        },
        child: Material(
          color: AppThemeColors.ntRemoteSurface,
          child: SingleChildScrollView(
            child: SizedBox(
              height: RemoteControlCluster.height,
              child: Column(
                children: [
                  Semantics(
                    header: true,
                    child: const Text(
                      'NT remote controls',
                      style: TextStyle(
                        inherit: false,
                        color: AppThemeColors.ntDisplayForeground,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 356,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 48,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _control(0, 'Button 1'),
                                    Transform.translate(
                                      offset: const Offset(6, 0),
                                      child: _control(1, 'Button 2'),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 228,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _control(4, 'Left pot', pot: 0),
                                        _control(5, 'Centre pot', pot: 1),
                                        _control(6, 'Right pot', pot: 2),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _control(7, 'Left encoder', encoder: 0),
                                        _control(
                                          8,
                                          'Right encoder',
                                          encoder: 1,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _control(3, 'Button 4'),
                                    Transform.translate(
                                      offset: const Offset(-6, 0),
                                      child: _control(2, 'Button 3'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: Semantics(
                      label:
                          widget.state.error ??
                          widget.state.unavailableReason ??
                          'Local inputs, not hardware positions',
                      liveRegion:
                          widget.state.error != null ||
                          widget.state.unavailableReason != null,
                      child: ExcludeSemantics(
                        child: Tooltip(
                          message: feedback,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              feedback,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                inherit: false,
                                color: AppThemeColors.ntRemoteMutedForeground,
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ), // Keep the host resize handle clear.
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoteControl extends StatefulWidget {
  const _RemoteControl({
    super.key,
    required this.name,
    required this.pushIndex,
    this.potIndex,
    this.encoderIndex,
    this.potValue,
    required this.pressed,
    required this.enabled,
    required this.inputIdentity,
    required this.onAction,
    required this.onPotAdjustment,
  });

  final String name;
  final int pushIndex;
  final int? potIndex;
  final int? encoderIndex;
  final int? potValue;
  final bool pressed;
  final bool enabled;
  final Object inputIdentity;
  final ValueChanged<RemoteAction> onAction;
  final void Function(int, int) onPotAdjustment;

  @override
  State<_RemoteControl> createState() => _RemoteControlState();
}

class _RemoteControlState extends State<_RemoteControl> {
  final _focus = FocusNode();
  final Set<LogicalKeyboardKey> _keys = {};
  int? _pointer;
  double _dragRemainder = 0;
  bool get _held => _pointer != null || _keys.isNotEmpty;
  bool get _rotary => widget.potIndex != null || widget.encoderIndex != null;

  @override
  void didUpdateWidget(covariant _RemoteControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled || oldWidget.inputIdentity != widget.inputIdentity) {
      _pointer = null;
      _keys.clear();
      _dragRemainder = 0;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _changeHold(VoidCallback change) {
    final wasHeld = _held;
    change();
    if (wasHeld != _held && widget.enabled) {
      widget.onAction(
        _held ? RemotePush(widget.pushIndex) : RemoteRelease(widget.pushIndex),
      );
    }
  }

  void _endPointer([int? pointer]) {
    if (_pointer == null || (pointer != null && pointer != _pointer)) return;
    _changeHold(() => _pointer = null);
    _dragRemainder = 0;
  }

  void _turn(int amount) {
    if (!widget.enabled || amount == 0) return;
    if (widget.potIndex case final int index) {
      widget.onPotAdjustment(index, amount);
    } else if (widget.encoderIndex case final int index) {
      widget.onAction(RemoteEncoderTurn(index, amount));
    }
  }

  void _step(int direction) =>
      _turn(direction * (widget.potIndex == null ? 1 : 32));

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      if (event is KeyUpEvent) {
        _changeHold(() => _keys.remove(key));
      } else if (event is KeyDownEvent) {
        _changeHold(() => _keys.add(key));
      }
      return KeyEventResult.handled;
    }
    if (_rotary && event is! KeyUpEvent) {
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowRight) {
        _step(1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.arrowLeft) {
        _step(-1);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final value = [
      if (widget.potValue != null) 'Local value ${widget.potValue} of 4095',
      if (widget.encoderIndex != null) 'Relative adjustment',
      widget.pressed ? 'Pressed' : 'Released',
    ].join(', ');
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      onFocusChange: (focused) {
        if (!mounted) return;
        if (!focused) _changeHold(_keys.clear);
        setState(() {});
        if (focused) Scrollable.ensureVisible(context);
      },
      child: Semantics(
        label: widget.name,
        value: value,
        increasedValue: _rotary
            ? (widget.potValue == null
                  ? 'Relative +1 step'
                  : 'Local value ${(widget.potValue! + 32).clamp(0, 4095)} of 4095')
            : null,
        decreasedValue: _rotary
            ? (widget.potValue == null
                  ? 'Relative -1 step'
                  : 'Local value ${(widget.potValue! - 32).clamp(0, 4095)} of 4095')
            : null,
        button: true,
        enabled: widget.enabled,
        focusable: true,
        focused: _focus.hasFocus,
        onTap: widget.enabled
            ? () {
                if (_held) return;
                widget.onAction(RemotePush(widget.pushIndex));
                widget.onAction(RemoteRelease(widget.pushIndex));
              }
            : null,
        onIncrease: widget.enabled && _rotary ? () => _step(1) : null,
        onDecrease: widget.enabled && _rotary ? () => _step(-1) : null,
        child: Listener(
          onPointerDown: (event) {
            if (!widget.enabled ||
                _pointer != null ||
                event.buttons != kPrimaryButton) {
              return;
            }
            // Do not steal keyboard focus from a different held control: chords
            // must not release an unrelated push.
            if (FocusManager.instance.primaryFocus?.context == null ||
                !HardwareKeyboard.instance.logicalKeysPressed.any(
                  (key) =>
                      key == LogicalKeyboardKey.space ||
                      key == LogicalKeyboardKey.enter,
                )) {
              _focus.requestFocus();
            }
            _changeHold(() => _pointer = event.pointer);
            _dragRemainder = 0;
          },
          onPointerMove: (event) {
            if (_pointer != event.pointer) return;
            if ((event.buttons & kPrimaryButton) == 0) {
              _endPointer(event.pointer); // Capture/button loss without an up.
              return;
            }
            if (widget.potIndex != null) {
              _turn((-event.localDelta.dy * 24).round());
            } else if (widget.encoderIndex != null) {
              _dragRemainder -= event.localDelta.dy;
              final steps = (_dragRemainder / 6).truncate();
              _dragRemainder -= steps * 6;
              _turn(steps);
            }
          },
          onPointerUp: (event) => _endPointer(event.pointer),
          onPointerCancel: (event) => _endPointer(event.pointer),
          onPointerSignal: (event) {
            if (widget.enabled &&
                _rotary &&
                event is PointerScrollEvent &&
                event.scrollDelta.dy != 0) {
              GestureBinding.instance.pointerSignalResolver.register(
                event,
                (_) => _step(event.scrollDelta.dy < 0 ? 1 : -1),
              );
            }
          },
          child: GestureDetector(
            // Claim drags ahead of the surrounding scroll viewport. Raw pointer
            // deltas above include motion before Flutter's drag threshold.
            onPanStart: (_) {},
            onPanUpdate: (_) {},
            onPanCancel: _endPointer,
            child: ExcludeSemantics(
              child: SizedBox(
                width: _rotary ? 76 : 48,
                height: _rotary ? 84 : 64,
                child: Column(
                  children: [
                    SizedBox(
                      width: _rotary ? 56 : 36,
                      height: _rotary ? 56 : 36,
                      child: CustomPaint(
                        painter: _RemoteFacePainter(
                          rotary: _rotary,
                          potValue: widget.potValue,
                          pressed: widget.pressed,
                          focused: _focus.hasFocus,
                        ),
                      ),
                    ),
                    Text(
                      widget.name.replaceFirst('Button ', ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        inherit: false,
                        color: AppThemeColors.ntDisplayForeground,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      widget.pressed
                          ? 'Pressed'
                          : (widget.potValue == null
                                ? ''
                                : 'Local ${widget.potValue}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        inherit: false,
                        color: AppThemeColors.ntRemoteMutedForeground,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
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

class _RemoteFacePainter extends CustomPainter {
  const _RemoteFacePainter({
    required this.rotary,
    this.potValue,
    required this.pressed,
    required this.focused,
  });
  final bool rotary;
  final int? potValue;
  final bool pressed;
  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 3;
    final paint = Paint();
    canvas.drawCircle(
      center,
      radius + 2,
      paint
        ..color = pressed
            ? AppThemeColors.ntRemotePressed
            : AppThemeColors.ntRemoteOutline,
    );
    if (rotary) {
      for (var i = 0; i < 36; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          i * math.pi / 18,
          math.pi / 18,
          true,
          paint
            ..color = i.isEven
                ? AppThemeColors.ntRemoteRidgeDark
                : AppThemeColors.ntRemoteRidgeLight,
        );
      }
    }
    paint.shader = RadialGradient(
      center: const Alignment(-0.3, -0.5),
      colors: pressed && !rotary
          ? [
              AppThemeColors.ntRemotePressedLight,
              AppThemeColors.ntRemotePressedDark,
            ]
          : [AppThemeColors.ntRemoteFaceLight, AppThemeColors.ntRemoteFaceDark],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(
      center + (pressed ? const Offset(0, 2) : Offset.zero),
      radius - (rotary ? 6 : 1),
      paint,
    );
    paint.shader = null;
    if (potValue != null) {
      final angle =
          (-135 + potValue! / 4095 * 270) * math.pi / 180 - math.pi / 2;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * 9,
        center + direction * (radius - 3),
        paint
          ..color = AppThemeColors.ntDisplayForeground
          ..strokeWidth = 3,
      );
    }
    if (focused) {
      canvas.drawCircle(
        center,
        radius + 3,
        paint
          ..color = AppThemeColors.ntDisplayForeground
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RemoteFacePainter oldDelegate) =>
      oldDelegate.pressed != pressed ||
      oldDelegate.focused != focused ||
      oldDelegate.potValue != potValue ||
      oldDelegate.rotary != rotary;
}
