import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/ui/widgets/performance/hardware_preview_widget.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key, required this.units});

  final List<String> units;

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  bool _pollingEnabled = false;
  DistingCubit? _cubit;
  PerformanceLayoutMode _layoutMode = PerformanceLayoutMode.condensed;

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

  Map<String, int> _buildParameterOrderMap(List<Slot> slots) {
    final orderMap = <String, int>{};
    var globalOrder = 0;
    for (final slot in slots) {
      for (final page in slot.pages.pages) {
        for (final paramNum in page.parameters) {
          final key = '${slot.algorithm.algorithmIndex}_$paramNum';
          orderMap[key] = globalOrder++;
        }
      }
    }
    return orderMap;
  }

  List<MappedParameter> _sortParameters(
    List<MappedParameter> mappedParameters,
    Map<String, int> orderMap,
  ) {
    final sorted = List<MappedParameter>.from(mappedParameters);
    sorted.sort((a, b) {
      final pageA = a.mapping.packedMappingData.perfPageIndex;
      final pageB = b.mapping.packedMappingData.perfPageIndex;
      if (pageA != pageB) return pageA.compareTo(pageB);

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

  void _onReorder(
    List<MappedParameter> sortedParams,
    int oldIndex,
    int newIndex,
  ) {
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final reordered = List<MappedParameter>.from(sortedParams);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    final assignments =
        <({int slotIndex, int parameterNumber, int perfPageIndex})>[];
    for (var i = 0; i < reordered.length; i++) {
      final p = reordered[i];
      final newPerfIndex = i + 1;
      if (p.mapping.packedMappingData.perfPageIndex != newPerfIndex) {
        assignments.add((
          slotIndex: p.parameter.algorithmIndex,
          parameterNumber: p.parameter.parameterNumber,
          perfPageIndex: newPerfIndex,
        ));
      }
    }

    if (assignments.isNotEmpty) {
      context.read<DistingCubit>().reorderPerformanceParameters(assignments);
    }
  }

  void _onRemoveParameter(MappedParameter param) {
    context.read<DistingCubit>().setPerformancePageMapping(
          param.parameter.algorithmIndex,
          param.parameter.parameterNumber,
          0,
        );
  }

  void _onIndexChanged(MappedParameter param, int newIndex) {
    context.read<DistingCubit>().setPerformancePageMapping(
          param.parameter.algorithmIndex,
          param.parameter.parameterNumber,
          newIndex,
        );
  }

  Widget _buildCondensedList(List<MappedParameter> sortedParams) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      buildDefaultDragHandles: false,
      itemCount: sortedParams.length,
      onReorder: (oldIndex, newIndex) =>
          _onReorder(sortedParams, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final item = sortedParams[index];
        final perfIndex = item.mapping.packedMappingData.perfPageIndex;
        final pageNum = ((perfIndex - 1) ~/ 3) + 1;

        return ReorderableDragStartListener(
          key: ValueKey(
            'condensed_${item.parameter.algorithmIndex}_${item.parameter.parameterNumber}',
          ),
          index: index,
          child: _ParameterListItem(
            item: item,
            pageColor: _getPageColor(pageNum),
            indexLabel: '$perfIndex',
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              tooltip: 'Remove from performance',
              onPressed: () => _onRemoveParameter(item),
            ),
            leading: const Icon(Icons.drag_handle),
          ),
        );
      },
    );
  }

  Widget _buildAsIndexedList(List<MappedParameter> sortedParams) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedParams.length,
      itemBuilder: (context, index) {
        final item = sortedParams[index];
        final perfIndex = item.mapping.packedMappingData.perfPageIndex;
        final pageNum = ((perfIndex - 1) ~/ 3) + 1;

        return _ParameterListItem(
          key: ValueKey(
            'indexed_${item.parameter.algorithmIndex}_${item.parameter.parameterNumber}',
          ),
          item: item,
          pageColor: _getPageColor(pageNum),
          indexLabel: '$perfIndex',
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            tooltip: 'Remove from performance',
            onPressed: () => _onRemoveParameter(item),
          ),
          leading: SizedBox(
            width: 56,
            child: DropdownButton<int>(
              value: perfIndex,
              isDense: true,
              isExpanded: true,
              items: List.generate(30, (i) {
                return DropdownMenuItem(
                  value: i + 1,
                  child: Text('${i + 1}'),
                );
              }),
              onChanged: (newValue) {
                if (newValue != null && newValue != perfIndex) {
                  _onIndexChanged(item, newValue);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<PerformanceLayoutMode>(
        segments: const [
          ButtonSegment(
            value: PerformanceLayoutMode.condensed,
            label: Text('Condensed'),
            icon: Icon(Icons.reorder),
          ),
          ButtonSegment(
            value: PerformanceLayoutMode.asIndexed,
            label: Text('As Indexed'),
            icon: Icon(Icons.grid_view),
          ),
        ],
        selected: {_layoutMode},
        onSelectionChanged: (selected) {
          setState(() {
            _layoutMode = selected.first;
          });
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
              semanticLabel: _pollingEnabled ? 'Stop polling' : 'Start polling',
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

            if (mappedParameters.isEmpty) {
              return _buildEmptyState();
            }

            final orderMap = _buildParameterOrderMap(state.slots);
            final sortedParams = _sortParameters(mappedParameters, orderMap);

            final isWide = MediaQuery.of(context).size.width >= 720;

            return Column(
              children: [
                _buildModeToggle(),
                Expanded(
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _layoutMode ==
                                      PerformanceLayoutMode.condensed
                                  ? _buildCondensedList(sortedParams)
                                  : _buildAsIndexedList(sortedParams),
                            ),
                            const VerticalDivider(width: 1, thickness: 1),
                            Expanded(
                              flex: 2,
                              child: HardwarePreviewWidget(
                                parameters: sortedParams,
                                layoutMode: _layoutMode,
                              ),
                            ),
                          ],
                        )
                      : _layoutMode == PerformanceLayoutMode.condensed
                          ? _buildCondensedList(sortedParams)
                          : _buildAsIndexedList(sortedParams),
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

class _ParameterListItem extends StatelessWidget {
  const _ParameterListItem({
    super.key,
    required this.item,
    required this.pageColor,
    required this.indexLabel,
    required this.trailing,
    required this.leading,
  });

  final MappedParameter item;
  final Color pageColor;
  final String indexLabel;
  final Widget trailing;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: pageColor,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                indexLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        title: Text(item.parameter.name),
        subtitle: Text(
          item.algorithm.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: trailing,
      ),
    );
  }
}
