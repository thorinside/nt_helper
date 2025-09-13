import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/ui/algorithm_documentation_screen.dart';
import 'package:nt_helper/ui/reset_outputs_dialog.dart';
import 'package:nt_helper/ui/widgets/parameter_editor_view.dart';

class SectionParameterListView extends StatefulWidget {
  final Slot slot;
  final List<String> units;
  final ParameterPages pages;

  const SectionParameterListView({
    super.key,
    required this.slot,
    required this.units,
    required this.pages,
  });

  @override
  State<SectionParameterListView> createState() =>
      _SectionParameterListViewState();
}

class _SectionParameterListViewState extends State<SectionParameterListView> {
  late final List<ExpansibleController> _tileControllers;
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _tileControllers = List.generate(
      widget.pages.pages.length,
      (_) => ExpansibleController(),
    );
    _isCollapsed = SettingsService().startPagesCollapsed;
  }

  void _collapseAllTiles() {
    for (var element in _tileControllers) {
      _isCollapsed ? element.expand() : element.collapse();
    }
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      data: ListTileThemeData(
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
      ),
      child: ExpansionTileTheme(
        data: const ExpansionTileThemeData(
          shape: RoundedRectangleBorder(side: BorderSide.none),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: _isCollapsed ? 'Expand all' : 'Collapse all',
                    child: IconButton.filledTonal(
                      onPressed: () {
                        _collapseAllTiles();
                      },
                      enableFeedback: true,
                      icon: _isCollapsed
                          ? const Icon(Icons.keyboard_double_arrow_down_sharp)
                          : const Icon(Icons.keyboard_double_arrow_up_sharp),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) {
                      final metadata = AlgorithmMetadataService()
                          .getAlgorithmByGuid(widget.slot.algorithm.guid);
                      final bool isHelpAvailable = metadata != null;

                      return <PopupMenuEntry<String>>[
                        if (isHelpAvailable)
                          PopupMenuItem(
                            value: 'Show Help',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AlgorithmDocumentationScreen(
                                        metadata: metadata,
                                      ),
                                ),
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Show Help'),
                                Icon(Icons.help_outline_rounded),
                              ],
                            ),
                          ),
                        if (isHelpAvailable) const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'Reset Outputs',
                          onTap: () {
                            showResetOutputsDialog(
                              context: context,
                              initialCvInput: 0,
                              onReset: (outputIndex) {
                                context.read<DistingCubit>().resetOutputs(
                                  widget.slot,
                                  outputIndex,
                                );
                              },
                            );
                          },
                          child: const Text('Reset Outputs'),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                cacheExtent: double.infinity,
                padding: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
                itemCount: widget.pages.pages.length,
                itemBuilder: (context, index) {
                  final page = widget.pages.pages.elementAt(index);
                  return ExpansionTile(
                    initiallyExpanded: !_isCollapsed,
                    controller: _tileControllers.elementAt(index),
                    title: Text(page.name),
                    children: page.parameters.map((parameterNumber) {
                      final value = widget.slot.values.elementAt(
                        parameterNumber,
                      );
                      final enumStrings = widget.slot.enums.elementAt(
                        parameterNumber,
                      );
                      final mapping = widget.slot.mappings.elementAtOrNull(
                        parameterNumber,
                      );
                      final valueString = widget.slot.valueStrings.elementAt(
                        parameterNumber,
                      );
                      var parameterInfo = widget.slot.parameters.elementAt(
                        parameterNumber,
                      );
                      final unit = parameterInfo.getUnitString(widget.units);

                      return ParameterEditorView(
                        slot: widget.slot,
                        parameterInfo: parameterInfo,
                        value: value,
                        enumStrings: enumStrings,
                        mapping: mapping,
                        valueString: valueString,
                        unit: unit,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
