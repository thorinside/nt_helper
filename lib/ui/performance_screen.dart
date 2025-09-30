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

  // Selected page index (null if no pages exist)
  int? _selectedPageIndex;

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

  // Discover which performance pages have parameters assigned
  List<int> _getPopulatedPages(List<MappedParameter> mappedParameters) {
    final populatedPages = <int>{};
    for (final param in mappedParameters) {
      final perfPageIndex = param.mapping.packedMappingData.perfPageIndex;
      if (perfPageIndex > 0) {
        populatedPages.add(perfPageIndex);
      }
    }
    final sorted = populatedPages.toList()..sort();
    return sorted;
  }

  // Filter parameters for the selected page
  List<MappedParameter> _getParametersForPage(
    List<MappedParameter> mappedParameters,
    int pageIndex,
  ) {
    return mappedParameters
        .where((param) =>
            param.mapping.packedMappingData.perfPageIndex == pageIndex)
        .toList();
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
            'Assign parameters to performance pages in the property editor',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
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
                      (item.algorithm.name != parameters[index - 1].algorithm.name)
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: (index == 0 ? 0.0 : 16.0),
                        bottom: 8,
                      ),
                      child: Text(
                        item.algorithm.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.color
                                  ?.withAlpha(200),
                            ),
                      ),
                    )
                  : const SizedBox.shrink(),
              ParameterEditorView(
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
            final mappedParameters = context
                .read<DistingCubit>()
                .buildMappedParameterList();

            // Discover populated pages
            final populatedPages = _getPopulatedPages(mappedParameters);

            // If no pages have parameters, show empty state
            if (populatedPages.isEmpty) {
              return _buildEmptyState();
            }

            // Set initial selection to first page if not set or invalid
            if (_selectedPageIndex == null ||
                !populatedPages.contains(_selectedPageIndex)) {
              _selectedPageIndex = populatedPages.first;
            }

            // Filter parameters for selected page
            final pageParameters =
                _getParametersForPage(mappedParameters, _selectedPageIndex!);

            return Row(
              children: [
                // Dynamic side navigation
                NavigationRail(
                  selectedIndex: populatedPages.indexOf(_selectedPageIndex!),
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedPageIndex = populatedPages[index];
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: populatedPages.map((pageIndex) {
                    return NavigationRailDestination(
                      icon: const Icon(Icons.music_note),
                      label: Text('Page $pageIndex'),
                    );
                  }).toList(),
                ),

                // Parameter list (filtered by selected page)
                Expanded(
                  child: _buildParameterList(pageParameters),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
