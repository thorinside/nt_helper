import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
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
  // Track optimistic performance page assignments for immediate UI updates
  final Map<int, int> _optimisticPerfPageAssignments = {};

  @override
  void initState() {
    super.initState();
    _tileControllers = List.generate(
      widget.pages.pages.length,
      (_) => ExpansibleController(),
    );
    _isCollapsed = SettingsService().startPagesCollapsed;
  }

  @override
  void didUpdateWidget(SectionParameterListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear optimistic assignments when slot changes (state has been updated)
    if (oldWidget.slot != widget.slot) {
      _optimisticPerfPageAssignments.clear();
    }
  }

  void _collapseAllTiles() {
    for (var element in _tileControllers) {
      _isCollapsed ? element.expand() : element.collapse();
    }
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  // Get list of parameter indices that have perfPageIndex > 0
  List<int> _getPerformanceParameterIndices() {
    final perfParams = <int>[];
    for (int i = 0; i < widget.slot.mappings.length; i++) {
      final mapping = widget.slot.mappings[i];
      if (mapping.packedMappingData.perfPageIndex > 0) {
        perfParams.add(i);
      }
    }
    // Sort by perfPageIndex, then by parameter number
    perfParams.sort((a, b) {
      final mappingA = widget.slot.mappings[a];
      final mappingB = widget.slot.mappings[b];
      final pageCompare = mappingA.packedMappingData.perfPageIndex.compareTo(
        mappingB.packedMappingData.perfPageIndex,
      );
      if (pageCompare != 0) return pageCompare;
      return a.compareTo(b);
    });
    return perfParams;
  }

  // Build page badge widget
  Widget _buildPageBadge(int pageIndex) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    final color = colors[(pageIndex - 1) % colors.length];

    return Chip(
      label: Text('P$pageIndex'),
      backgroundColor: color,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  // Build performance parameter row
  Widget _buildPerformanceParameterRow(int parameterNumber) {
    final value = widget.slot.values.elementAtOrNull(parameterNumber);
    final enumStrings = widget.slot.enums.elementAtOrNull(parameterNumber);
    final mapping = widget.slot.mappings.elementAtOrNull(parameterNumber);
    final valueString = widget.slot.valueStrings.elementAtOrNull(
      parameterNumber,
    );
    final parameterInfo = widget.slot.parameters.elementAtOrNull(
      parameterNumber,
    );

    // Skip if missing essential data
    if (value == null || parameterInfo == null || mapping == null) {
      return const SizedBox.shrink();
    }

    final safeEnumStrings = enumStrings ?? ParameterEnumStrings.filler();
    final safeValueString = valueString ?? ParameterValueString.filler();
    // For string-type parameters (units 13, 14, 17), don't fetch unit
    final shouldShowUnit =
        parameterInfo.unit != 13 &&
        parameterInfo.unit != 14 &&
        parameterInfo.unit != 17;
    final unit = shouldShowUnit
        ? parameterInfo.getUnitString(widget.units)
        : null;
    final perfPageIndex = mapping.packedMappingData.perfPageIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          // Page badge
          _buildPageBadge(perfPageIndex),
          const SizedBox(width: 12),
          // Parameter editor (expanded)
          Expanded(
            child: ParameterEditorView(
              slot: widget.slot,
              parameterInfo: parameterInfo,
              value: value,
              enumStrings: safeEnumStrings,
              mapping: mapping,
              valueString: safeValueString,
              unit: unit,
            ),
          ),
          // Remove button
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Remove from performance page',
            onPressed: () => _removeFromPerformancePage(parameterNumber),
          ),
        ],
      ),
    );
  }

  // Remove parameter from performance page
  Future<void> _removeFromPerformancePage(int parameterNumber) async {
    final cubit = context.read<DistingCubit>();
    try {
      await cubit.setPerformancePageMapping(
        widget.slot.algorithm.algorithmIndex,
        parameterNumber,
        0, // Remove from performance page
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from performance page'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '[SectionParameterListView] Error removing from performance page: $e',
      );
    }
  }

  // Assign parameter to performance page
  Future<void> _assignToPerformancePage(
    int parameterNumber,
    int pageIndex,
  ) async {
    // Optimistically update the UI immediately
    setState(() {
      _optimisticPerfPageAssignments[parameterNumber] = pageIndex;
    });

    final cubit = context.read<DistingCubit>();
    try {
      await cubit.setPerformancePageMapping(
        widget.slot.algorithm.algorithmIndex,
        parameterNumber,
        pageIndex,
      );
      // Only show SnackBar feedback in connected mode (real hardware)
      // Demo and offline modes are silent operations
      if (mounted) {
        final manager = cubit.disting();
        final isConnectedMode = manager is DistingMidiManager;
        if (isConnectedMode) {
          final message = pageIndex > 0
              ? 'Assigned to Page $pageIndex'
              : 'Removed from performance pages';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[SectionParameterListView] Error assigning to performance page: $e',
      );
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _optimisticPerfPageAssignments.remove(parameterNumber);
        });
      }
    }
  }

  // Build parameter row with performance page selector
  Widget _buildParameterRowWithPageSelector({
    required int parameterNumber,
    required ParameterInfo parameterInfo,
    required ParameterValue value,
    required ParameterEnumStrings enumStrings,
    required Mapping? mapping,
    required ParameterValueString valueString,
    required String? unit,
  }) {
    // Use optimistic value if available, otherwise use actual mapping data
    final actualPerfPageIndex = mapping?.packedMappingData.perfPageIndex ?? 0;
    final perfPageIndex =
        _optimisticPerfPageAssignments[parameterNumber] ?? actualPerfPageIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          // Parameter editor (expanded)
          Expanded(
            child: ParameterEditorView(
              slot: widget.slot,
              parameterInfo: parameterInfo,
              value: value,
              enumStrings: enumStrings,
              mapping: mapping,
              valueString: valueString,
              unit: unit,
            ),
          ),
          const SizedBox(width: 8),
          // Performance page selector
          DropdownButton<int>(
            value: perfPageIndex,
            isDense: true,
            underline: const SizedBox.shrink(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
            hint: const Text('Page'),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onChanged: (newValue) {
              if (newValue != null) {
                _assignToPerformancePage(parameterNumber, newValue);
              }
            },
            items: [
              const DropdownMenuItem(value: 0, child: Text('Not Assigned')),
              ...List.generate(15, (i) {
                return DropdownMenuItem(
                  value: i + 1,
                  child: Text('Page ${i + 1}'),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // Build performance parameters section
  Widget _buildPerformanceParametersSection() {
    final perfParams = _getPerformanceParameterIndices();
    final isEmpty = perfParams.isEmpty;

    return ExpansionTile(
      initiallyExpanded: !isEmpty,
      title: Text(
        'Performance Parameters (${perfParams.length})',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      children: isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No parameters assigned to performance pages',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
            ]
          : perfParams.map((paramIndex) {
              return _buildPerformanceParameterRow(paramIndex);
            }).toList(),
    );
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
        child: ListView(
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
            // Performance Parameters Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildPerformanceParametersSection(),
            ),
            // Regular parameter pages
            ...widget.pages.pages.map((page) {
              final index = widget.pages.pages.indexOf(page);
              return Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: ExpansionTile(
                  initiallyExpanded: !_isCollapsed,
                  controller: _tileControllers.elementAt(index),
                  title: Text(page.name),
                  children: page.parameters.map((parameterNumber) {
                    // Use safe access with bounds checking
                    final value = widget.slot.values.elementAtOrNull(
                      parameterNumber,
                    );
                    final enumStrings = widget.slot.enums.elementAtOrNull(
                      parameterNumber,
                    );
                    final mapping = widget.slot.mappings.elementAtOrNull(
                      parameterNumber,
                    );
                    final valueString = widget.slot.valueStrings
                        .elementAtOrNull(parameterNumber);
                    var parameterInfo = widget.slot.parameters.elementAtOrNull(
                      parameterNumber,
                    );

                    // Skip this parameter if we don't have essential data
                    // Note: valueString and enumStrings can be empty/filler for many parameters
                    if (value == null || parameterInfo == null) {
                      debugPrint(
                        '[SectionParameterListView] Missing essential data for parameter $parameterNumber in slot ${widget.slot.algorithm.algorithmIndex}',
                      );
                      return const SizedBox.shrink();
                    }

                    // Use filler/empty data if not available
                    final safeEnumStrings =
                        enumStrings ?? ParameterEnumStrings.filler();
                    final safeValueString =
                        valueString ?? ParameterValueString.filler();

                    // For string-type parameters (units 13, 14, 17), don't fetch unit
                    final shouldShowUnit =
                        parameterInfo.unit != 13 &&
                        parameterInfo.unit != 14 &&
                        parameterInfo.unit != 17;
                    final unit = shouldShowUnit
                        ? parameterInfo.getUnitString(widget.units)
                        : null;

                    return _buildParameterRowWithPageSelector(
                      parameterNumber: parameterNumber,
                      parameterInfo: parameterInfo,
                      value: value,
                      enumStrings: safeEnumStrings,
                      mapping: mapping,
                      valueString: safeValueString,
                      unit: unit,
                    );
                  }).toList(),
                ),
              );
            }),
            const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
    );
  }
}
