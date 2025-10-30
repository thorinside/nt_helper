import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart' show DisplayMode;
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/ui/bpm_editor_widget.dart';
import 'package:nt_helper/ui/parameter_editor_registry.dart';
import 'package:nt_helper/ui/widgets/mapping_edit_button.dart';
import 'package:nt_helper/ui/widgets/parameter_value_display.dart';
import 'package:nt_helper/util/extensions.dart';
import 'package:nt_helper/util/ui_helpers.dart';

class ParameterViewRow extends StatefulWidget {
  final String name;
  final int min;
  final int max;
  final int defaultValue;
  final String?
  displayString; // For additional display string instead of dropdown
  final String? unit;
  final int powerOfTen;
  final List<String>? dropdownItems; // For enums as a dropdown
  final bool isOnOff; // Whether the parameter is an "on/off" type
  final int initialValue;
  final int algorithmIndex;
  final int parameterNumber;
  final PackedMappingData? mappingData;
  final Slot slot;

  const ParameterViewRow({
    super.key,
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.parameterNumber,
    required this.algorithmIndex,
    this.unit,
    this.powerOfTen = 0,
    this.displayString,
    this.dropdownItems,
    this.isOnOff = false,
    this.mappingData,
    required this.initialValue,
    required this.slot,
  });

  @override
  State<ParameterViewRow> createState() => _ParameterViewRowState();
}

class _ParameterViewRowState extends State<ParameterViewRow> {
  late int currentValue;
  late bool isChecked;
  bool isChanging = false;
  bool _showAlternateEditor = false;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue.clamp(widget.min, widget.max);
    isChecked = widget.isOnOff && currentValue == 1;
  }

  @override
  void didUpdateWidget(covariant ParameterViewRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update internal state when the widget is updated
    if (widget.initialValue != oldWidget.initialValue ||
        widget.min != oldWidget.min ||
        widget.max != oldWidget.max) {
      setState(() {
        currentValue = widget.initialValue.clamp(widget.min, widget.max);
        isChecked = widget.isOnOff && currentValue == 1;
      });
    }
  }

  void _updateCubitValue(int value) {
    // Send updated value to the Cubit
    context.read<DistingCubit>().updateParameterValue(
      algorithmIndex: widget.algorithmIndex,
      parameterNumber: widget.parameterNumber,
      value: value,
      userIsChangingTheValue: widget.displayString?.isNotEmpty == true
          ? false
          : isChanging,
    );
  }

  DateTime? _lastSent;
  final Duration throttleDuration = const Duration(milliseconds: 100);

  void onSliderChanged(int value) async {
    final now = DateTime.now();
    if (_lastSent == null || now.difference(_lastSent!) > throttleDuration) {
      // Enough time has passed -> proceed
      _lastSent = now;
      _updateCubitValue(value);
    }

    if (SettingsService().hapticsEnabled) {
      Haptics.vibrate(HapticsType.light);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Check if we are on a wide screen or a smaller screen
    bool widescreen = MediaQuery.of(context).size.width > 600;

    // Determine if the unit is BPM
    final bool isBpmUnit = widget.unit?.toUpperCase().contains('BPM') ?? false;

    // Check if this parameter should use a specialized file editor
    final Widget? fileEditor =
        widget.slot.parameters.length > widget.parameterNumber
        ? ParameterEditorRegistry.findEditorFor(
            slot: widget.slot,
            parameterInfo: widget.slot.parameters[widget.parameterNumber],
            parameterNumber: widget.parameterNumber,
            currentValue: currentValue,
            onValueChanged: (newValue) {
              setState(() {
                currentValue = newValue;
              });
              _updateCubitValue(newValue);
            },
          )
        : null;


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      child: Row(
        key: ValueKey(widescreen),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MappingEditButton(widget: widget),
          // Name column with reduced width
          Expanded(
            flex: widescreen ? 2 : 3,
            child: GestureDetector(
              onDoubleTap: () async {
                var cubit = context.read<DistingCubit>();
                cubit.disting()?.let((manager) {
                  manager.requestSetFocus(
                    widget.algorithmIndex,
                    widget.parameterNumber,
                  );
                  manager.requestSetDisplayMode(DisplayMode.parameters);
                  if (SettingsService().hapticsEnabled) {
                    Haptics.vibrate(HapticsType.medium);
                  }
                });
              },
              onLongPress: () {
                // Get the manager from the cubit
                final manager = context.read<DistingCubit>().requireDisting();
                // Call requestSetFocus on the manager
                manager.requestSetFocus(
                  widget.algorithmIndex,
                  widget.parameterNumber,
                );
                if (SettingsService().hapticsEnabled) {
                  Haptics.vibrate(HapticsType.medium);
                }
              },
              child: Text(
                cleanTitle(widget.name),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                softWrap: false,
                textAlign: TextAlign.start,
                style: widescreen
                    ? textTheme.titleMedium
                    : textTheme.labelMedium,
              ),
            ),
          ),

          // Slider column
          Expanded(
            flex: widescreen ? 8 : 6, // Decreased flex
            // Proportionally larger space for the slider
            child: GestureDetector(
              onDoubleTap: () =>
                  isBpmUnit ||
                      fileEditor != null ||
                      _showAlternateEditor // Do not allow double tap to change editor for BPM, file editor, or if alternate is already shown
                  ? () {}
                  : setState(() {
                      currentValue = widget.defaultValue;
                      _updateCubitValue(currentValue);
                    }),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: SizedBox(
                  height: 45,
                  child: isBpmUnit
                      ? BpmEditorWidget(
                          initialValue: currentValue,
                          min: widget.min,
                          max: widget.max,
                          powerOfTen: widget.powerOfTen,
                          onChanged: (newBpm) {
                            setState(() {
                              currentValue = newBpm;
                            });
                            _updateCubitValue(newBpm);
                          },
                          onEditingStatusChanged: (isEditing) {
                            setState(() {
                              isChanging = isEditing;
                            });
                          },
                        )
                      : fileEditor ??
                            (_showAlternateEditor
                                ? Row(
                                    // Alternate +/- editor
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            currentValue = min(
                                              max(currentValue - 1, widget.min),
                                              widget.max,
                                            );
                                          });
                                          _updateCubitValue(currentValue);
                                        },
                                        child: const Text("-"),
                                      ),
                                      OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            currentValue = min(
                                              max(currentValue + 1, widget.min),
                                              widget.max,
                                            );
                                          });
                                          _updateCubitValue(currentValue);
                                        },
                                        child: const Text("+"),
                                      ),
                                    ],
                                  )
                                : Slider(
                                    // Default Slider editor
                                    value: currentValue.toDouble(),
                                    min: widget.min.toDouble(),
                                    max: widget.max.toDouble(),
                                    divisions: (widget.max - widget.min > 0)
                                        ? widget.max - widget.min
                                        : null,
                                    onChangeStart: (value) {
                                      isChanging = true;
                                    },
                                    onChangeEnd: (value) {
                                      isChanging = false;
                                      setState(() {
                                        currentValue = value.toInt();
                                        if (widget.isOnOff) {
                                          isChecked = currentValue == 1;
                                        }
                                      });
                                      _updateCubitValue(currentValue);
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        currentValue = value.toInt();
                                        if (widget.isOnOff) {
                                          isChecked = currentValue == 1;
                                        }
                                      });
                                      // Throttle a bit
                                      onSliderChanged(currentValue);
                                    },
                                  )),
                ),
              ),
            ),
          ),
          // Control column
          Expanded(
            flex: widescreen ? 4 : 5, // Increased flex
            child: Align(
              alignment: Alignment.centerLeft,
              child: ParameterValueDisplay(
                currentValue: currentValue,
                min: widget.min,
                max: widget.max,
                name: widget.name,
                unit: widget.unit,
                powerOfTen: widget.powerOfTen,
                displayString: widget.displayString,
                dropdownItems: widget.dropdownItems,
                isOnOff: widget.isOnOff,
                widescreen: widescreen,
                isBpmUnit: isBpmUnit,
                hasFileEditor: fileEditor != null,
                showAlternateEditor: _showAlternateEditor,
                onValueChanged: (newValue) {
                  setState(() {
                    currentValue = newValue;
                    if (widget.isOnOff) {
                      isChecked = currentValue == 1;
                    }
                  });
                  _updateCubitValue(newValue);
                },
                onLongPress: () => setState(() {
                  // Show alternate editor only if not BPM or file editor
                  if (!isBpmUnit && fileEditor == null) {
                    _showAlternateEditor = !_showAlternateEditor;
                  }
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
