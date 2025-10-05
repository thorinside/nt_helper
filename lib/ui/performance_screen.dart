import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show ParameterPages, RoutingInfo;
import 'package:nt_helper/ui/widgets/parameter_editor_view.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key, required this.units});

  final List<String> units;

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  // Local flag to track whether polling is enabled.
  bool _pollingEnabled = false;
  DistingCubit? _cubit;
  int? _selectedPageIndex; // Nullable - null if no pages

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit = context.read<DistingCubit>();
  }

  @override
  void dispose() {
    _cubit?.stopPollingMappedParameters();
    super.dispose();
  }

  // Discover which pages have parameters assigned
  List<int> _getPopulatedPages(List<MappedParameter> mappedParameters) {
    final populatedPages = <int>{};
    for (final param in mappedParameters) {
      final pageIndex = param.mapping.packedMappingData.perfPageIndex;
      if (pageIndex > 0) {
        populatedPages.add(pageIndex);
      }
    }
    return populatedPages.toList()..sort();
  }

  // Build a map of (algorithmIndex, parameterNumber) -> order
  // based on the order parameters appear in the parameter pages
  Map<String, int> _buildParameterOrderMap(List<Slot> slots) {
    final orderMap = <String, int>{};
    var globalOrder = 0;

    for (final slot in slots) {
      // Flatten all parameter numbers across all pages in order
      for (final page in slot.pages.pages) {
        for (final paramNum in page.parameters) {
          final key = '${slot.algorithm.algorithmIndex}_$paramNum';
          orderMap[key] = globalOrder++;
        }
      }
    }

    return orderMap;
  }

  // Sort parameters by page (ascending), then by parameter page order
  List<MappedParameter> _sortParameters(
    List<MappedParameter> mappedParameters,
    Map<String, int> orderMap,
  ) {
    final sorted = List<MappedParameter>.from(mappedParameters);
    sorted.sort((a, b) {
      final pageA = a.mapping.packedMappingData.perfPageIndex;
      final pageB = b.mapping.packedMappingData.perfPageIndex;

      // First, sort by page number (ascending)
      if (pageA != pageB) {
        return pageA.compareTo(pageB);
      }

      // Within the same page, sort by parameter page order
      final keyA =
          '${a.parameter.algorithmIndex}_${a.parameter.parameterNumber}';
      final keyB =
          '${b.parameter.algorithmIndex}_${b.parameter.parameterNumber}';
      final orderA = orderMap[keyA] ?? 999999;
      final orderB = orderMap[keyB] ?? 999999;

      return orderA.compareTo(orderB);
    });
    return sorted;
  }

  // Filter parameters for a specific page
  List<MappedParameter> _filterParametersForPage(
    List<MappedParameter> mappedParameters,
    int pageIndex,
  ) {
    return mappedParameters
        .where((p) => p.mapping.packedMappingData.perfPageIndex == pageIndex)
        .toList();
  }

  // Get color for page badge
  Color _getPageColor(int pageIndex) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[(pageIndex - 1) % colors.length];
  }

  // Build colored page badge for navigation rail
  Widget _buildPageBadge(int pageIndex, {bool isSelected = false}) {
    final color = _getPageColor(pageIndex);
    final scale = isSelected ? 1.3 : 1.0;

    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Text(
          'P$pageIndex',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSelected ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No performance parameters assigned',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Assign parameters in the property editor',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterList(List<MappedParameter> parameters) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ListView.builder(
        itemCount: parameters.length,
        itemBuilder: (context, index) {
          final item = parameters[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              index == 0 ||
                      (item.algorithm.name !=
                          parameters[index - 1].algorithm.name)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: (index == 0 ? 0.0 : 16.0),
                        bottom: 8,
                      ),
                      child: Text(
                        item.algorithm.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).textTheme.titleMedium?.color?.withAlpha(200),
                            ),
                      ),
                    )
                  : const SizedBox.shrink(),
              ParameterEditorView(
                key: ValueKey(
                  '${item.parameter.algorithmIndex}_${item.parameter.parameterNumber}',
                ),
                slot: Slot(
                  algorithm: item.algorithm,
                  routing: RoutingInfo.filler(),
                  pages: ParameterPages(
                    algorithmIndex: item.algorithm.algorithmIndex,
                    pages: [],
                  ),
                  parameters: [item.parameter],
                  values: [item.value],
                  enums: [item.enums],
                  mappings: [item.mapping],
                  valueStrings: [item.valueString],
                ),
                parameterInfo: item.parameter,
                enumStrings: item.enums,
                mapping: item.mapping,
                value: item.value,
                valueString: item.valueString,
                unit: item.parameter.getUnitString(widget.units),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perform'),
        actions: [
          IconButton(
            icon: Icon(
              _pollingEnabled
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
            ),
            tooltip: _pollingEnabled ? 'Stop polling' : 'Start polling',
            onPressed: () {
              setState(() {
                _pollingEnabled = !_pollingEnabled;
              });
              if (_pollingEnabled) {
                context.read<DistingCubit>().startPollingMappedParameters();
              } else {
                context.read<DistingCubit>().stopPollingMappedParameters();
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<DistingCubit, DistingState>(
        builder: (context, state) {
          if (state is DistingStateSynchronized) {
            final mappedParameters = DistingCubit.buildMappedParameterList(
              state,
            );

            // If no parameters, show empty state
            if (mappedParameters.isEmpty) {
              return _buildEmptyState();
            }

            // Discover populated pages
            final populatedPages = _getPopulatedPages(mappedParameters);

            // Set initial selection to first page if not set or if current selection is no longer valid
            if (_selectedPageIndex == null ||
                !populatedPages.contains(_selectedPageIndex)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedPageIndex = populatedPages.isNotEmpty
                        ? populatedPages.first
                        : null;
                  });
                }
              });
            }

            // If no pages exist, show empty state
            if (populatedPages.isEmpty || _selectedPageIndex == null) {
              return _buildEmptyState();
            }

            // Build parameter order map from slots
            final orderMap = _buildParameterOrderMap(state.slots);

            // Filter parameters for selected page
            final pageParameters = _filterParametersForPage(
              mappedParameters,
              _selectedPageIndex!,
            );

            // Sort parameters by parameter page order within the page
            final sortedParameters = _sortParameters(pageParameters, orderMap);

            return Row(
              children: [
                // Navigation rail for page selection
                NavigationRail(
                  selectedIndex: populatedPages.indexOf(_selectedPageIndex!),
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedPageIndex = populatedPages[index];
                    });
                  },
                  labelType: NavigationRailLabelType.none,
                  destinations: populatedPages.map((pageIndex) {
                    final isSelected = pageIndex == _selectedPageIndex;
                    return NavigationRailDestination(
                      icon: _buildPageBadge(pageIndex, isSelected: isSelected),
                      label: const Text(''),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // Parameter list for selected page
                Expanded(child: _buildParameterList(sortedParameters)),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
