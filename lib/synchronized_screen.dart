import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/add_algorithm_screen.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/floating_screenshot_overlay.dart';
import 'package:nt_helper/load_preset_dialog.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/packed_mapping_data_editor.dart';
import 'package:nt_helper/rename_preset_dialog.dart';
import 'package:nt_helper/routing_page.dart';
import 'package:nt_helper/ui/algorithm_registry.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart';
import 'package:nt_helper/ui/section_builder.dart';
import 'package:nt_helper/util/extensions.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SynchronizedScreen extends StatelessWidget {
  final List<Slot> slots;
  final List<AlgorithmInfo> algorithms;
  final List<String> units;
  final String presetName;
  final String distingVersion;
  final Uint8List? screenshot;

  const SynchronizedScreen({
    super.key,
    required this.slots,
    required this.algorithms,
    required this.units,
    required this.presetName,
    required this.distingVersion,
    required this.screenshot,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: slots.length,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('NT Helper'),
          actions: [
            Builder(builder: (context) {
              return IconButton(
                icon: const Icon(Icons.add_circle_rounded),
                tooltip: 'Add Algorithm',
                onPressed: () async {
                  final cubit = context.read<DistingCubit>();
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AddAlgorithmScreen(algorithms: algorithms)),
                  );

                  if (result != null) {
                    await cubit.onAlgorithmSelected(
                      result['algorithm'],
                      result['specValues'],
                    );
                  }
                },
              );
            }),
            Builder(builder: (context) {
              return IconButton(
                icon: const Icon(Icons.arrow_upward_rounded),
                tooltip: 'Move Algorithm Up',
                onPressed: () async {
                  DefaultTabController.of(context).index = await context
                      .read<DistingCubit>()
                      .moveAlgorithmUp(DefaultTabController.of(context).index);
                },
              );
            }),
            Builder(builder: (context) {
              return IconButton(
                icon: const Icon(Icons.arrow_downward_rounded),
                tooltip: 'Move Algorithm Down',
                onPressed: () async {
                  DefaultTabController.of(context).index = await context
                      .read<DistingCubit>()
                      .moveAlgorithmDown(
                          DefaultTabController.of(context).index);
                },
              );
            }),
            Builder(
              builder: (context) => IconButton(
                  icon: const Icon(Icons.delete_forever_rounded),
                  tooltip: 'Remove Algorithm',
                  onPressed: () async {
                    context.read<DistingCubit>().onRemoveAlgorithm(
                        DefaultTabController.of(context).index);
                  }),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: "wake",
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('Wake'), Icon(Icons.alarm_on_rounded)]),
                  onTap: () {
                    context.read<DistingCubit>().wakeDevice();
                  },
                ),
                PopupMenuItem(
                  value: "new",
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('New Preset'),
                        Icon(Icons.fiber_new_rounded)
                      ]),
                  onTap: () {
                    context.read<DistingCubit>().newPreset();
                  },
                ),
                PopupMenuItem(
                  value: "load",
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Load Preset'),
                        Icon(Icons.file_upload_rounded)
                      ]),
                  onTap: () async {
                    var cubit = context.read<DistingCubit>();

                    final preset = await showDialog<dynamic>(
                      context: context,
                      builder: (context) => LoadPresetDialog(
                        initialName: "",
                      ),
                    );
                    if (preset == null) return;

                    cubit.loadPreset(
                        preset["name"] as String, preset["append"] as bool);
                  },
                ),
                PopupMenuItem(
                  value: "save",
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Save Preset'),
                        Icon(Icons.save_alt_rounded)
                      ]),
                  onTap: () {
                    context.read<DistingCubit>().save();
                  },
                ),
                PopupMenuItem(
                  value: 'refresh',
                  onTap: () {
                    context.read<DistingCubit>().refresh();
                  },
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('Refresh'), Icon(Icons.refresh_rounded)]),
                ),
                PopupMenuItem(
                  value: 'routing',
                  onTap: () async {
                    final routingInformation =
                        context.read<DistingCubit>().buildRoutingInformation();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              RoutingPage(routing: routingInformation)),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text('Routing'), Icon(Icons.route_rounded)],
                  ),
                ),
                PopupMenuItem(
                  value: 'screenshot',
                  onTap: () {
                    _showScreenshotOverlay(context);
                  },
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Screenshot'),
                        Icon(Icons.screenshot_monitor_rounded),
                      ]),
                ),
                PopupMenuItem(
                  value: 'Switch Devices',
                  onTap: () {
                    context.read<DistingCubit>().disconnect();
                    context.read<DistingCubit>().loadDevices();
                  },
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('Switch'), Icon(Icons.login_rounded)]),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: Text('About'),
                  onTap: () async {
                    final info = await PackageInfo.fromPlatform();

                    showDialog<String>(
                      context: context,
                      builder: (context) => AboutDialog(
                        applicationName: "NT Helper",
                        applicationVersion:
                            "${info.version} (${info.buildNumber})",
                        applicationLegalese:
                            "Written by Neal Sanche (Thorinside), 2025, No Rights Reserved.",
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
          elevation: 0,
          scrolledUnderElevation: 3,
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
                          if (newName != null &&
                              newName.isNotEmpty &&
                              newName != presetName) {
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
        body: AnimatedSwitcher(
          duration: Duration(seconds: 1),
          child: Builder(
            builder: (context) {
              return slots.isNotEmpty
                  ? TabBarView(
                      children: slots.mapIndexed((index, slot) {
                        return SlotDetailView(
                          key: ValueKey("$index - ${slot.algorithmGuid.guid}"),
                          slot: slot,
                          units: units,
                        );
                      }).toList(),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "No algorithms",
                          style: Theme.of(context).textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
            }
          ),
        ),
      ),
    );
  }

  void _showScreenshotOverlay(BuildContext context) {
    final cubit = context.read<DistingCubit>();

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 16,
        right: 16,
        child: FloatingScreenshotOverlay(
          overlayEntry: overlayEntry,
          cubit: cubit,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }
}

class SlotDetailView extends StatefulWidget {
  final Slot slot;
  final List<String> units;

  const SlotDetailView({super.key, required this.slot, required this.units});

  @override
  State<SlotDetailView> createState() => _SlotDetailViewState();
}

class _SlotDetailViewState extends State<SlotDetailView>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, List<ParameterInfo>>?> sectionsFuture;

  @override
  void initState() {
    sectionsFuture = SectionBuilder(slot: widget.slot).buildSections();
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Provide a full replacement view
    final view = AlgorithmViewRegistry.findViewFor(widget.slot);
    if (view != null) return view;

    // Create a set of list sections for the parameters of the
    // algorithm initially based off Os' organization on the module firmware.

    return FutureBuilder<Map<String, List<ParameterInfo>>?>(
      future: sectionsFuture,
      builder: (context, snapshot) {
        // Handle different states of the Future
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}'); // Show error message
        } else if (snapshot.hasData) {
          return SectionParameterListView(
            slot: widget.slot,
            units: widget.units,
            sections: snapshot.data!,
          );
        } else {
          return ParameterListView(slot: widget.slot, units: widget.units);
        }
      },
    );
  }
}

class SectionParameterListView extends StatelessWidget {
  final Slot slot;
  final List<String> units;
  final Map<String, List<ParameterInfo>> sections;

  const SectionParameterListView({
    super.key,
    required this.slot,
    required this.units,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      data: ListTileThemeData(
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
      ),
      child: ExpansionTileTheme(
        data: ExpansionTileThemeData(
          shape: RoundedRectangleBorder(
            side: BorderSide.none,
          ),
        ),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final element = sections.entries.elementAt(index);

            return ExpansionTile(
              initiallyExpanded: true,
              title: Text(element.key),
              children: element.value.map(
                (parameter) {
                  final value =
                      slot.values.elementAt(parameter.parameterNumber);
                  final enumStrings =
                      slot.enums.elementAt(parameter.parameterNumber);
                  final mapping =
                      slot.mappings.elementAtOrNull(parameter.parameterNumber);
                  final valueString =
                      slot.valueStrings.elementAt(parameter.parameterNumber);
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
              ).toList(),
            );
          },
        ),
      ),
    );
  }
}

class ParameterListView extends StatelessWidget {
  final Slot slot;
  final List<String> units;

  const ParameterListView({
    super.key,
    required this.slot,
    required this.units,
  });

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
        mappingData: mapping?.packedMappingData,
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
  final PackedMappingData? mappingData;

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
    this.mappingData,
    required this.initialValue,
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
          userIsChangingTheValue:
              widget.displayString?.isNotEmpty == true ? false : isChanging,
        );
  }

  DateTime? _lastSent;
  Duration throttleDuration = const Duration(milliseconds: 100);

  void onSliderChanged(int value) {
    final now = DateTime.now();
    if (_lastSent == null || now.difference(_lastSent!) > throttleDuration) {
      // Enough time has passed -> proceed
      _lastSent = now;
      _updateCubitValue(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MappingEditButton(widget: widget),
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
              flex: 8, // Proportionally larger space for the slider
              child: GestureDetector(
                onDoubleTap: () => _showAlternateEditor
                    ? {}
                    : setState(() {
                        currentValue = widget.defaultValue;
                        _updateCubitValue(currentValue);
                      }),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 150),
                  child: SizedBox(
                    height: 45,
                    child: _showAlternateEditor
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 16,
                            children: [
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      currentValue = min(
                                          max(currentValue - 1, widget.min),
                                          widget.max);
                                    });
                                    _updateCubitValue(currentValue);
                                  },
                                  child: Text("-"),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      currentValue = min(
                                          max(currentValue + 1, widget.min),
                                          widget.max);
                                    });
                                    _updateCubitValue(currentValue);
                                  },
                                  child: Text("+"),
                                )
                              ])
                        : Slider(
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
                          ),
                  ),
                ),
              )),
          // Control column
          Expanded(
            flex: 2, // Slightly larger control column
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
                            _updateCubitValue(currentValue);
                          },
                        )
                      : widget.name.toLowerCase().contains("note")
                          ? Text(midiNoteToNoteString(currentValue))
                          : widget.displayString != null
                              ? GestureDetector(
                                  onLongPress: () => setState(() {
                                    // Show alternate editor
                                    _showAlternateEditor =
                                        !_showAlternateEditor;
                                  }),
                                  child: Text(
                                    widget.displayString!,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyLarge,
                                  ),
                                )
                              : widget.unit != null
                                  ? Text(formatWithUnit(currentValue,
                                      name: widget.name,
                                      min: widget.min,
                                      max: widget.max,
                                      unit: widget.unit))
                                  : Text(currentValue.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

class MappingEditButton extends StatelessWidget {
  const MappingEditButton({
    super.key,
    required this.widget,
  });

  final ParameterViewRow widget;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.6,
      child: Builder(
        builder: (context) {
          final bool hasMapping = widget.mappingData != null &&
              widget.mappingData != PackedMappingData.filler() &&
              widget.mappingData?.isMapped() == true;

          // Define your two styles:
          final ButtonStyle defaultStyle = IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          );
          final ButtonStyle mappedStyle = IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            backgroundColor: Theme.of(context)
                .colorScheme
                .primaryContainer, // or any color you prefer
          );

          return IconButton.filledTonal(
            // Decide which style to use based on `hasMapping`
            style: hasMapping ? mappedStyle : defaultStyle,
            icon: const Icon(Icons.map_sharp),
            tooltip: 'Edit mapping',
            onPressed: () async {
              final cubit = context.read<DistingCubit>();
              final data = widget.mappingData ?? PackedMappingData.filler();
              final myMidiCubit = context.read<MidiListenerCubit>();
              final updatedData = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return MappingEditorBottomSheet(
                    myMidiCubit: myMidiCubit,
                    data: data,
                  );
                },
              );

              if (updatedData != null) {
                cubit.saveMapping(
                  widget.algorithmIndex,
                  widget.parameterNumber,
                  updatedData,
                );
              }
            },
          );
        },
      ),
    );
  }
}

class MappingEditorBottomSheet extends StatelessWidget {
  const MappingEditorBottomSheet({
    super.key,
    required this.myMidiCubit,
    required this.data,
  });

  final MidiListenerCubit myMidiCubit;
  final PackedMappingData data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom > 0
              ? MediaQuery.of(context).viewInsets.bottom
              : MediaQuery.of(context).padding.bottom,
        ),
        child: SingleChildScrollView(
          child: BlocProvider.value(
            value: myMidiCubit,
            child: PackedMappingDataEditor(
              initialData: data,
              onSave: (updatedData) {
                // do something with updatedData
                Navigator.of(context).pop(updatedData);
              },
            ),
          ),
        ),
      ),
    );
  }
}

String formatWithUnit(int currentValue,
    {required int min, required int max, required String name, String? unit}) {
  if (kDebugMode) {
    print("formatWithUnit(name='$name' min=$min max=$max unit=$unit)");
  }

  if (unit == null || unit.isEmpty) return currentValue.toString();

  switch (unit) {
    case 'ms':
      if (min == 0 && max == 100) {
        return '${((currentValue / 10).toStringAsFixed(1))} $unit';
      }
      break;
    case '%':
      if (max < 1000) {
        return '${((currentValue).toStringAsFixed(0))} $unit';
      } else if (max < 10000) {
        return '${((currentValue / 10).toStringAsFixed(1))} $unit';
      }
      break;
    case 'dB':
      if (min < -100) {
        return '${((currentValue / 10)).toStringAsFixed(1)} ${unit.trim()}';
      } else {
        return '${((currentValue)).toStringAsFixed(0)} ${unit.trim()}';
      }
    case ' BPM':
      return '${((currentValue / 10)).toStringAsFixed(1)} ${unit.trim()}';
    case 'V':
      if (min == -10 && max == 10) {
        return '${(currentValue.toStringAsFixed(0))} $unit';
      }
      if (min == -100 && max == 100) {
        return '${((currentValue / 10).toStringAsFixed(1))} $unit';
      }
      if (min == -1000 && max == 1000) {
        return '${((currentValue / 100)).toStringAsFixed(2)} ${unit.trim()}';
      }
      return '${(currentValue.toStringAsFixed(0))} $unit';
    case 'Hz':
      if (name == 'Frequency') {
        return '${currentValue.toStringAsFixed(0)} ${unit.trim()}';
      }
      return '${((currentValue / 1000)).toStringAsFixed(3)} ${unit.trim()}';
  }
  return '$currentValue ${unit.trim()}';
}

String midiNoteToNoteString(int midiNoteNumber) {
  if (midiNoteNumber == -1) return "";

  if (midiNoteNumber < 0 || midiNoteNumber > 127) {
    throw ArgumentError('MIDI note number must be between 0 and 127.');
  }

  // Note names
  List<String> noteNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];

  // Calculate the octave and note index
  int octave = (midiNoteNumber ~/ 12) - 1;
  String note = noteNames[midiNoteNumber % 12];

  return '$note$octave';
}
