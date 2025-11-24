import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/util/parameter_page_assigner.dart';

/// Parameter Pages view for Step Sequencer
///
/// Displays parameters not covered by the custom Step Sequencer UI,
/// organized into logical pages (MIDI, Routing, Modulation, Global).
///
/// Uses tab-based navigation and reusable parameter editor widgets.
class ParameterPagesView extends StatefulWidget {
  final Slot slot;
  final int slotIndex;

  const ParameterPagesView({
    super.key,
    required this.slot,
    required this.slotIndex,
  });

  @override
  State<ParameterPagesView> createState() => _ParameterPagesViewState();
}

class _ParameterPagesViewState extends State<ParameterPagesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<ParamPage, List<ParameterInfo>> _groupedParameters;
  late List<ParamPage> _availablePages;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  /// Initialize pages by grouping parameters and filtering empty pages
  void _initializePages() {
    // Group all parameters by page
    _groupedParameters = ParameterPageAssigner.groupParametersByPage(
      widget.slot.parameters,
    );

    // Filter to only pages with parameters
    _availablePages = _groupedParameters.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList();

    // Initialize tab controller with number of available pages
    _tabController = TabController(
      length: _availablePages.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    // Handle case where no parameters are available for pages
    if (_availablePages.isEmpty) {
      return _buildEmptyState(context, isMobile);
    }

    // Build the parameter pages view
    return _buildParameterPagesView(context, isMobile);
  }

  /// Builds the main parameter pages view with tabs
  Widget _buildParameterPagesView(BuildContext context, bool isMobile) {
    if (isMobile) {
      // Mobile: Full-screen view
      return Scaffold(
        appBar: AppBar(
          title: const Text('Parameter Pages'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _availablePages.map((page) {
              return Tab(text: ParameterPageAssigner.getPageName(page));
            }).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _availablePages.map((page) {
            final parameters = _groupedParameters[page]!;
            return _ParameterPageContent(
              parameters: parameters,
              slot: widget.slot,
              slotIndex: widget.slotIndex,
            );
          }).toList(),
        ),
      );
    } else {
      // Desktop: Large modal dialog
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Parameter Pages'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: false,
                tabs: _availablePages.map((page) {
                  return Tab(text: ParameterPageAssigner.getPageName(page));
                }).toList(),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: _availablePages.map((page) {
                final parameters = _groupedParameters[page]!;
                return _ParameterPageContent(
                  parameters: parameters,
                  slot: widget.slot,
                  slotIndex: widget.slotIndex,
                );
              }).toList(),
            ),
          ),
        ),
      );
    }
  }

  /// Builds the empty state when no parameters are available
  Widget _buildEmptyState(BuildContext context, bool isMobile) {
    final content = Scaffold(
      appBar: AppBar(
        title: const Text('Parameter Pages'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              const Text(
                'All parameters have custom UI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'All Step Sequencer parameters are accessible through the custom interface.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Return to Step Sequencer'),
              ),
            ],
          ),
        ),
      ),
    );

    if (isMobile) {
      return content;
    } else {
      // Desktop: dialog wrapper
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
          child: content,
        ),
      );
    }
  }
}

/// Content widget for a single parameter page
///
/// Displays a scrollable list of parameter editors for the given parameters.
class _ParameterPageContent extends StatelessWidget {
  final List<ParameterInfo> parameters;
  final Slot slot;
  final int slotIndex;

  const _ParameterPageContent({
    required this.parameters,
    required this.slot,
    required this.slotIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DistingCubit, DistingState>(
      builder: (context, state) {
        // Get current slot to refresh parameter values
        final currentSlot = state.maybeWhen(
          synchronized: (
            disting,
            distingVersion,
            firmwareVersion,
            presetName,
            algorithms,
            slots,
            unitStrings,
            inputDevice,
            outputDevice,
            loading,
            offline,
            screenshot,
            demo,
            videoStream,
          ) {
            if (slotIndex < slots.length) {
              return slots[slotIndex];
            }
            return slot;
          },
          orElse: () => slot,
        );

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: parameters.length,
          itemBuilder: (context, index) {
            final param = parameters[index];
            return _buildParameterEditor(context, param, currentSlot);
          },
        );
      },
    );
  }

  /// Builds the appropriate parameter editor widget based on parameter type
  Widget _buildParameterEditor(
    BuildContext context,
    ParameterInfo param,
    Slot currentSlot,
  ) {
    final cubit = context.read<DistingCubit>();
    final paramNumber = param.parameterNumber;

    // Get current value
    final currentValue = paramNumber < currentSlot.values.length
        ? currentSlot.values[paramNumber].value
        : param.defaultValue;

    // Check if parameter has enum strings
    final hasEnumStrings = paramNumber < currentSlot.enums.length &&
        currentSlot.enums[paramNumber].values.isNotEmpty;

    if (hasEnumStrings) {
      // Enum parameter - use dropdown
      return _buildEnumDropdown(
        context,
        param,
        currentValue,
        currentSlot,
        cubit,
      );
    } else if (param.max - param.min == 1) {
      // Boolean parameter - use switch
      return _buildBooleanSwitch(
        context,
        param,
        currentValue,
        cubit,
      );
    } else {
      // Continuous parameter - use slider
      return _buildSlider(
        context,
        param,
        currentValue,
        cubit,
      );
    }
  }

  /// Builds an enum dropdown parameter editor
  Widget _buildEnumDropdown(
    BuildContext context,
    ParameterInfo param,
    int currentValue,
    Slot currentSlot,
    DistingCubit cubit,
  ) {
    final paramNumber = param.parameterNumber;
    final enumStrings = currentSlot.enums[paramNumber].values;

    // Check if parameter is disabled
    final isDisabled = paramNumber < currentSlot.values.length &&
        currentSlot.values[paramNumber].isDisabled;

    // Build dropdown items from enum strings
    final items = enumStrings.asMap().entries.map((entry) {
      final index = entry.key + param.min;
      final label = entry.value;
      return DropdownMenuItem<int>(
        value: index,
        child: Text(label),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            param.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: currentValue.clamp(param.min, param.max),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: items,
            onChanged: isDisabled
                ? null
                : (value) {
                    if (value != null) {
                      cubit.updateParameterValue(
                        algorithmIndex: slotIndex,
                        parameterNumber: paramNumber,
                        value: value,
                        userIsChangingTheValue: true,
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }

  /// Builds a boolean switch parameter editor
  Widget _buildBooleanSwitch(
    BuildContext context,
    ParameterInfo param,
    int currentValue,
    DistingCubit cubit,
  ) {
    // Check if parameter is disabled
    final paramNumber = param.parameterNumber;
    final isDisabled = paramNumber < slot.values.length &&
        slot.values[paramNumber].isDisabled;

    return SwitchListTile(
      title: Text(param.name),
      value: currentValue == param.max,
      onChanged: isDisabled
          ? null
          : (value) {
              cubit.updateParameterValue(
                algorithmIndex: slotIndex,
                parameterNumber: param.parameterNumber,
                value: value ? param.max : param.min,
                userIsChangingTheValue: true,
              );
            },
    );
  }

  /// Builds a slider parameter editor
  Widget _buildSlider(
    BuildContext context,
    ParameterInfo param,
    int currentValue,
    DistingCubit cubit,
  ) {
    // Check if parameter is disabled
    final paramNumber = param.parameterNumber;
    final isDisabled = paramNumber < slot.values.length &&
        slot.values[paramNumber].isDisabled;

    // Get unit string (unit is an int index)
    final unitString = '';  // TODO: Map unit index to string if needed

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                param.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$currentValue$unitString',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          Slider(
            value: currentValue.toDouble().clamp(
                  param.min.toDouble(),
                  param.max.toDouble(),
                ),
            min: param.min.toDouble(),
            max: param.max.toDouble(),
            divisions: (param.max - param.min).clamp(1, 1000),
            label: '$currentValue$unitString',
            onChanged: isDisabled
                ? null
                : (value) {
                    cubit.updateParameterValue(
                      algorithmIndex: slotIndex,
                      parameterNumber: param.parameterNumber,
                      value: value.toInt(),
                      userIsChangingTheValue: true,
                    );
                  },
          ),
        ],
      ),
    );
  }
}
