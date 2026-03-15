import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/performance_page_item.dart';

enum PerformanceLayoutMode { condensed, asIndexed }

class HardwarePreviewWidget extends StatelessWidget {
  const HardwarePreviewWidget({
    super.key,
    this.parameters = const [],
    this.layoutMode = PerformanceLayoutMode.asIndexed,
    this.perfPageItems,
  });

  final List<MappedParameter> parameters;
  final PerformanceLayoutMode layoutMode;
  final List<PerformancePageItem>? perfPageItems;

  @override
  Widget build(BuildContext context) {
    List<_PageData> pages;
    if (perfPageItems != null && perfPageItems!.isNotEmpty) {
      pages = _buildPerfItemPages();
    } else if (layoutMode == PerformanceLayoutMode.condensed) {
      pages = _buildCondensedPages();
    } else {
      pages = _buildAsIndexedPages();
    }

    if (pages.isEmpty) {
      return const Center(
        child: Text(
          'No parameters assigned',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        return _PageCard(pageNumber: page.pageNumber, knobs: page.knobs);
      },
    );
  }

  List<_PageData> _buildPerfItemPages() {
    final items = perfPageItems!;
    final maxIndex = items
        .map((i) => i.itemIndex)
        .reduce((a, b) => a > b ? a : b);
    final totalPages = (maxIndex ~/ 3) + 1;

    final itemByIndex = <int, PerformancePageItem>{};
    for (final item in items) {
      itemByIndex[item.itemIndex] = item;
    }

    final pages = <_PageData>[];
    for (var page = 0; page < totalPages; page++) {
      final knobs = <_KnobData>[];
      for (var k = 0; k < 3; k++) {
        final index = page * 3 + k;
        final item = itemByIndex[index];
        if (item != null) {
          knobs.add(
            _KnobData(
              label: item.upperLabel.isNotEmpty
                  ? item.upperLabel
                  : 'Item ${item.itemIndex + 1}',
              algorithmName: item.lowerLabel.isNotEmpty
                  ? item.lowerLabel
                  : 'Slot ${item.slotIndex + 1}, P${item.parameterNumber}',
              isEmpty: false,
            ),
          );
        } else {
          knobs.add(
            const _KnobData(label: '', algorithmName: '', isEmpty: true),
          );
        }
      }
      pages.add(_PageData(pageNumber: page + 1, knobs: knobs));
    }
    return pages;
  }

  List<_PageData> _buildCondensedPages() {
    if (parameters.isEmpty) return [];

    final pages = <_PageData>[];
    for (var i = 0; i < parameters.length; i += 3) {
      final pageNumber = (i ~/ 3) + 1;
      final knobs = <_KnobData>[];
      for (var k = 0; k < 3; k++) {
        if (i + k < parameters.length) {
          final p = parameters[i + k];
          knobs.add(
            _KnobData(
              label: p.parameter.name,
              algorithmName: p.algorithm.name,
              isEmpty: false,
            ),
          );
        } else {
          knobs.add(
            const _KnobData(label: '', algorithmName: '', isEmpty: true),
          );
        }
      }
      pages.add(_PageData(pageNumber: pageNumber, knobs: knobs));
    }
    return pages;
  }

  List<_PageData> _buildAsIndexedPages() {
    if (parameters.isEmpty) return [];

    final maxIndex = parameters
        .map((p) => p.mapping.packedMappingData.perfPageIndex)
        .reduce((a, b) => a > b ? a : b);

    final totalPages = ((maxIndex - 1) ~/ 3) + 1;
    final paramByIndex = <int, MappedParameter>{};
    for (final p in parameters) {
      paramByIndex[p.mapping.packedMappingData.perfPageIndex] = p;
    }

    final pages = <_PageData>[];
    for (var page = 0; page < totalPages; page++) {
      final knobs = <_KnobData>[];
      for (var k = 0; k < 3; k++) {
        final index = page * 3 + k + 1;
        final p = paramByIndex[index];
        if (p != null) {
          knobs.add(
            _KnobData(
              label: p.parameter.name,
              algorithmName: p.algorithm.name,
              isEmpty: false,
            ),
          );
        } else {
          knobs.add(
            const _KnobData(label: '', algorithmName: '', isEmpty: true),
          );
        }
      }
      pages.add(_PageData(pageNumber: page + 1, knobs: knobs));
    }
    return pages;
  }
}

class _PageData {
  const _PageData({required this.pageNumber, required this.knobs});
  final int pageNumber;
  final List<_KnobData> knobs;
}

class _KnobData {
  const _KnobData({
    required this.label,
    required this.algorithmName,
    required this.isEmpty,
  });
  final String label;
  final String algorithmName;
  final bool isEmpty;
}

class _PageCard extends StatelessWidget {
  const _PageCard({required this.pageNumber, required this.knobs});

  final int pageNumber;
  final List<_KnobData> knobs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Page $pageNumber',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(3, (i) {
                const potLabels = ['L', 'C', 'R'];
                final knob = i < knobs.length ? knobs[i] : null;
                return Expanded(
                  child: _KnobSlot(potLabel: potLabels[i], knob: knob),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnobSlot extends StatelessWidget {
  const _KnobSlot({required this.potLabel, this.knob});

  final String potLabel;
  final _KnobData? knob;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEmpty = knob == null || knob!.isEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isEmpty
              ? colorScheme.outlineVariant.withAlpha(80)
              : colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isEmpty ? null : colorScheme.surfaceContainerLow,
      ),
      child: Column(
        children: [
          Text(
            'Pot $potLabel',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEmpty ? '---' : knob!.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isEmpty
                  ? colorScheme.onSurfaceVariant.withAlpha(100)
                  : colorScheme.onSurface,
              fontWeight: isEmpty ? null : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (!isEmpty) ...[
            const SizedBox(height: 2),
            Text(
              knob!.algorithmName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
