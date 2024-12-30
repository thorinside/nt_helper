import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class SynchronizedScreen extends StatelessWidget {
  final List<Slot> slots;
  final List<AlgorithmInfo> algorithms;

  const SynchronizedScreen({
    super.key,
    required this.slots,
    required this.algorithms,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: slots.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Disting NT Preset Editor'),
          bottom: TabBar(
            isScrollable: true,
            tabs: slots.map((slot) {
              final algorithmName = algorithms
                  .where((element) => element.guid == slot.algorithmGuid.guid)
                  .firstOrNull
                  ?.name;
              return Tab(text: algorithmName ?? "");
            }).toList(),
          ),
        ),
        body: TabBarView(
          children: slots.map((slot) {
            return SlotDetailView(slot: slot);
          }).toList(),
        ),
      ),
    );
  }
}

class SlotDetailView extends StatelessWidget {
  final Slot slot;

  const SlotDetailView({super.key, required this.slot});

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

        return ParameterEditorView(
          parameterInfo: parameter,
          value: value,
          enumStrings: enumStrings,
          mapping: mapping,
          valueString: valueString,
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

  const ParameterEditorView({
    super.key,
    required this.parameterInfo,
    required this.value,
    required this.enumStrings,
    required this.mapping,
    required this.valueString,
  });

  @override
  Widget build(BuildContext context) => ParameterViewRow(
        name: parameterInfo.name,
        min: parameterInfo.min,
        max: parameterInfo.max,
        defaultValue: parameterInfo.defaultValue,
        displayString: valueString.value.isNotEmpty ? valueString.value : null,
        dropdownItems:
            enumStrings.values.isNotEmpty ? enumStrings.values : null,
        isOnOff: enumStrings.values.isNotEmpty &&
            enumStrings.values[0] == "Off" &&
            enumStrings.values[1] == "On",
        initialValue: value.value,
      );
}

class ParameterViewRow extends StatefulWidget {
  final String name;
  final int min;
  final int max;
  final int defaultValue;
  final String?
      displayString; // For additional display string instead of dropdown
  final List<String>? dropdownItems; // For enums as a dropdown
  final bool isOnOff; // Whether the parameter is an "on/off" type
  final int initialValue;

  const ParameterViewRow({
    Key? key,
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
    this.displayString,
    this.dropdownItems,
    this.isOnOff = false,
    required this.initialValue,
  }) : super(key: key);

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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      // Less horizontal padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Name column with reduced width
          Expanded(
            flex: 1, // Reduced flex for the name column
            child: Text(
              widget.name,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium, // Larger title for the name
            ),
          ),

          // Slider column
          Expanded(
            flex: 4, // Proportionally larger space for the slider
            child: Slider(
              value: currentValue.toDouble(),
              min: widget.min.toDouble(),
              max: widget.max.toDouble(),
              divisions: widget.max - widget.min,
              onChanged: (value) {
                setState(() {
                  currentValue = value.toInt();
                  if (widget.isOnOff) isChecked = currentValue == 1;
                });
              },
            ),
          ),

          // Control column
          Expanded(
            flex: 1, // Slightly larger control column
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
                      },
                    )
                  : widget.dropdownItems != null
                      ? DropdownMenu(
                          initialSelection:
                              widget.dropdownItems![currentValue - widget.min],
                          dropdownMenuEntries: widget.dropdownItems!
                              .map((item) =>
                                  DropdownMenuEntry(value: item, label: item))
                              .toList(),
                          onSelected: (value) {
                            setState(() {
                              currentValue =
                                  widget.dropdownItems!.indexOf(value!) +
                                      widget.min;
                            });
                          },
                        )
                      : widget.displayString != null
                          ? Text(
                              widget.displayString!,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme
                                  .bodyLarge, // Larger body style for strings
                            )
                          : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
