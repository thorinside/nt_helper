import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/ui/algorithm_documentation_screen.dart';
import 'package:nt_helper/ui/parameter_editor_registry.dart';
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
  late List<ExpansibleController> _tileControllers;
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

    // Rebuild tile controllers if page count changed (e.g., Lua script program change)
    if (oldWidget.pages.pages.length != widget.pages.pages.length) {
      // Dispose old controllers
      for (var controller in _tileControllers) {
        controller.dispose();
      }
      // Create new controllers matching new page count and current collapse state
      _tileControllers = List.generate(
        widget.pages.pages.length,
        (_) {
          final controller = ExpansibleController();
          // Match current collapse state
          if (_isCollapsed) {
            controller.collapse();
          } else {
            controller.expand();
          }
          return controller;
        },
      );
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
    // For string-type parameters, don't fetch unit - they use value strings
    // The registry handles firmware version differences automatically
    final shouldShowUnit =
        !ParameterEditorRegistry.isStringTypeUnit(parameterInfo.unit);
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
      // Intentionally empty
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
          // Only show inline dropdown on desktop (width >= 600)
          if (MediaQuery.of(context).size.width >= 600) ...[
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
                        PopupMenuItem(
                          value: 'Remount SD Card',
                          onTap: () {
                            context.read<DistingCubit>().remountSd();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('SD card remount requested'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Remount SD Card'),
                              Icon(Icons.sd_card, size: 20),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'Developer Options',
                          onTap: () {
                            _showDeveloperOptionsDialog(context);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Developer Options...'),
                              Icon(Icons.developer_mode, size: 20),
                            ],
                          ),
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
                      return const SizedBox.shrink();
                    }

                    // Use filler/empty data if not available
                    final safeEnumStrings =
                        enumStrings ?? ParameterEnumStrings.filler();
                    final safeValueString =
                        valueString ?? ParameterValueString.filler();

                    // For string-type parameters, don't show unit
                    final shouldShowUnit = !ParameterEditorRegistry.isStringTypeUnit(
                      parameterInfo.unit,
                    );
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

  void _showDeveloperOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Developer Options'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'These options are for advanced users only.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.dangerous, color: Colors.red),
              title: const Text('Danger Zone'),
              subtitle: const Text('Proceed with caution...'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(dialogContext).pop();
                _showDangerZoneDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDangerZoneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.red),
            SizedBox(width: 8),
            Text('Danger Zone', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Here be dragons. You have been warned.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.red),
              title: const Text('Reboot Device'),
              subtitle: const Text('Restart the Disting NT'),
              onTap: () {
                Navigator.of(dialogContext).pop();
                _showRebootConfirmationDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Retreat to Safety'),
          ),
        ],
      ),
    );
  }

  void _showRebootConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology_alt, color: Colors.orange),
            SizedBox(width: 8),
            Text('Are You Sure?'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to reboot your Disting NT.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('This will:'),
            SizedBox(height: 4),
            Text('  \u2022 Interrupt any audio processing'),
            Text('  \u2022 Cause a brief moment of silence'),
            Text('  \u2022 Make your modular setup very confused'),
            SizedBox(height: 12),
            Text(
              'Unsaved changes will be lost to the void.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('No, I panicked'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<DistingCubit>().reboot();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reboot command sent. Goodbye, cruel world...'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Yes, reboot it'),
          ),
        ],
      ),
    );
  }
}
