import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/add_algorithm_screen.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/rename_preset_dialog.dart';

class SynchronizedScreen extends StatelessWidget {
  final List<Slot> slots;
  final List<AlgorithmInfo> algorithms;
  final List<String> units;
  final String presetName;
  final String distingVersion;

  const SynchronizedScreen({
    super.key,
    required this.slots,
    required this.algorithms,
    required this.units,
    required this.presetName,
    required this.distingVersion,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: slots.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Disting NT Preset Editor'),
          actions: [
            IconButton(
              icon: const Icon(Icons.alarm_on_rounded),
              tooltip: 'Wake',
              onPressed: () {
                context.read<DistingCubit>().wakeDevice();
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () {
                context.read<DistingCubit>().refresh();
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded),
              tooltip: 'Add Algorithm',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AddAlgorithmScreen(algorithms: algorithms)),
                );

                if (result != null) {
                  context.read<DistingCubit>().onAlgorithmSelected(
                        result['algorithm'],
                        result['specValues'],
                      );
                }
              },
            ),
            Builder(
              builder: (context) => IconButton(
                  icon: const Icon(Icons.delete_forever_rounded),
                  tooltip: 'Remove Algorithm',
                  onPressed: () async {
                    context.read<DistingCubit>().onRemoveAlgorithm(
                        DefaultTabController.of(context).index);
                  }),
            ),
          ],
          elevation: 0,
          scrolledUnderElevation: 6,
          notificationPredicate: (ScrollNotification notification) =>
              notification.depth == 1,
          bottom: PreferredSize(
            // Set the total height you need for your text + tab bar.
            preferredSize: const Size.fromHeight(100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Your text
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          // 1) Show an AlertDialog with a text field to rename the preset.
                          final newName = await showDialog<String>(
                            context: context,
                            builder: (context) => RenamePresetDialog(
                              initialName: presetName,
                            ),
                          );

                          // 2) If the user pressed OK (instead of Cancel), newName will be non-null.
                          if (newName != null && newName.isNotEmpty && newName != presetName) {
                            context.read<DistingCubit>().renamePreset(newName);
                          }

                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          // Shrinks to fit content
                          children: [
                            Text(
                              'Preset: ${presetName.trim()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.edit,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                      Text(distingVersion,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  )),
                    ],
                  ),
                ),
                // The TabBar
                TabBar(
                  isScrollable: true,
                  tabs: slots.map((slot) {
                    final algorithmName = algorithms
                        .where((element) =>
                            element.guid == slot.algorithmGuid.guid)
                        .firstOrNull
                        ?.name;
                    return Tab(text: algorithmName ?? "");
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: slots.map((slot) {
            return SlotDetailView(slot: slot, units: units);
          }).toList(),
        ),
      ),
    );
  }
}

class SlotDetailView extends StatelessWidget {
  final Slot slot;
  final List<String> units;

  const SlotDetailView({super.key, required this.slot, required this.units});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      itemCount: slot.parameters.length,
      itemBuilder: (context, index) {
        final parameter = slot.parameters.elementAt(index);
        final value = slot.values.elementAt(index);
        final enumStrings = slot.enums.elementAt(index);
        final mapping = slot.mappings.elementAtOrNull(index);
        final valueString = slot.valueStrings.elementAt(index);
        final unit = parameter.unit > 0
            ? units.elementAtOrNull(parameter.unit - 1)
            : null;

        return ParameterEditorView(
          parameterInfo: parameter,
          value: value,
          enumStrings: enumStrings,
          mapping: mapping,
          valueString: valueString,
          unit: unit,
        );
      },
    );
  }
}

class ParameterEditorView extends StatelessWidget {
  final ParameterInfo parameterInfo;
  final ParameterValue value;
  final ParameterEnumStrings enumStrings;
  final Mapping? mapping;
  final ParameterValueString valueString;
  final String? unit;

  const ParameterEditorView({
    super.key,
    required this.parameterInfo,
    required this.value,
    required this.enumStrings,
    required this.mapping,
    required this.valueString,
    this.unit,
  });

  @override
  Widget build(BuildContext context) => ParameterViewRow(
        name: parameterInfo.name,
        min: parameterInfo.min,
        max: parameterInfo.max,
        algorithmIndex: parameterInfo.algorithmIndex,
        parameterNumber: parameterInfo.parameterNumber,
        defaultValue: parameterInfo.defaultValue,
        displayString: valueString.value.isNotEmpty ? valueString.value : null,
        dropdownItems:
            enumStrings.values.isNotEmpty ? enumStrings.values : null,
        isOnOff: (enumStrings.values.isNotEmpty &&
            enumStrings.values[0] == "Off" &&
            enumStrings.values[1] == "On"),
        initialValue: (value.value >= parameterInfo.min &&
                value.value <= parameterInfo.max)
            ? value.value
            : parameterInfo.defaultValue,
        unit: unit,
      );
}

class ParameterViewRow extends StatefulWidget {
  final String name;
  final int min;
  final int max;
  final int defaultValue;
  final String?
      displayString; // For additional display string instead of dropdown
  final String? unit;
  final List<String>? dropdownItems; // For enums as a dropdown
  final bool isOnOff; // Whether the parameter is an "on/off" type
  final int initialValue;
  final int algorithmIndex;
  final int parameterNumber;

  const ParameterViewRow({
    super.key,
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.parameterNumber,
    required this.algorithmIndex,
    this.unit,
    this.displayString,
    this.dropdownItems,
    this.isOnOff = false,
    required this.initialValue,
  });

  @override
  State<ParameterViewRow> createState() => _ParameterViewRowState();
}

class _ParameterViewRowState extends State<ParameterViewRow> {
  late int currentValue;
  late bool isChecked;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
    isChecked = widget.isOnOff && currentValue == 1;
  }

  @override
  void didUpdateWidget(covariant ParameterViewRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update internal state when the widget is updated
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        currentValue = widget.initialValue;
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
        );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Name column with reduced width
          Expanded(
            flex: 2, // Reduced flex for the name column
            child: GestureDetector(
              onLongPress: () {
                context.read<DistingCubit>().onFocusParameter(
                    // Call the Cubit method for long press
                    algorithmIndex: widget.algorithmIndex,
                    parameterNumber: widget.parameterNumber);
              },
              child: Text(
                widget.name,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium, // Larger title for the name
              ),
            ),
          ),

          // Slider column
          Expanded(
            flex: 4, // Proportionally larger space for the slider
            child: Slider(
              value: currentValue.toDouble(),
              min: widget.min.toDouble(),
              max: widget.max.toDouble(),
              divisions: (widget.max - widget.min > 0)
                  ? widget.max - widget.min
                  : null,
              onChanged: (value) {
                setState(() {
                  currentValue = value.toInt();
                  if (widget.isOnOff) isChecked = currentValue == 1;
                });
                _updateCubitValue(currentValue);
              },
            ),
          ),

          // Control column
          Expanded(
            flex: 3, // Slightly larger control column
            child: Align(
              alignment: Alignment.centerLeft,
              child: widget.isOnOff
                  ? Checkbox(
                      value: isChecked,
                      onChanged: (value) {
                        setState(() {
                          isChecked = value!;
                          currentValue = isChecked ? 1 : 0;
                        });
                        _updateCubitValue(currentValue);
                      },
                    )
                  : widget.dropdownItems != null
                      ? DropdownMenu(
                          initialSelection: widget.dropdownItems![currentValue],
                          dropdownMenuEntries: widget.dropdownItems!
                              .map((item) =>
                                  DropdownMenuEntry(value: item, label: item))
                              .toList(),
                          onSelected: (value) {
                            setState(() {
                              currentValue = min(
                                  max(widget.dropdownItems!.indexOf(value!),
                                      widget.min),
                                  widget.max);
                            });
                            _updateCubitValue(
                                min(max(currentValue, widget.min), widget.max));
                          },
                        )
                      : widget.displayString != null
                          ? Text(
                              widget.displayString!,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLarge,
                            )
                          : widget.unit != null
                              ? Text(formatWithUnit(currentValue,
                                  min: widget.min,
                                  max: widget.max,
                                  unit: widget.unit))
                              : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

String formatWithUnit(int currentValue,
    {required int min, required int max, String? unit}) {
  if (unit == null) return currentValue.toString();
  if (unit == '%') {
    if (max == 1000) {
      return '${((currentValue / (max - min)) * 100).toStringAsFixed(2)} $unit';
    }
  }
  if (unit == ' BPM') {
    return '${((currentValue / 10)).toStringAsFixed(1)} ${unit.trim()}';
  }
  return '$currentValue ${unit.trim()}';
}
