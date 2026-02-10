import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/bus_spec.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';

class ConsolidateBusesDialog extends StatefulWidget {
  final AuxBusConsolidationPlan plan;
  final RoutingEditorCubit cubit;

  const ConsolidateBusesDialog({
    super.key,
    required this.plan,
    required this.cubit,
  });

  @override
  State<ConsolidateBusesDialog> createState() =>
      _ConsolidateBusesDialogState();
}

class _ConsolidateBusesDialogState extends State<ConsolidateBusesDialog> {
  bool _isExecuting = false;
  bool _isComplete = false;
  bool _replaceModeSet = false;
  final Set<int> _completedSteps = {};

  Future<void> _execute() async {
    setState(() => _isExecuting = true);
    await widget.cubit.executeConsolidationPlan(
      widget.plan,
      onReplaceModeSet: () {
        if (mounted) setState(() => _replaceModeSet = true);
      },
      onStepComplete: (i) {
        if (mounted) setState(() => _completedSteps.add(i));
      },
    );
    if (mounted) {
      setState(() {
        _isExecuting = false;
        _isComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final plan = widget.plan;
    final keepLocal = BusSpec.toLocalNumber(plan.keepBus) ?? plan.keepBus;

    return PopScope(
      canPop: !_isExecuting,
      child: AlertDialog(
        title: Row(
          children: [
            ExcludeSemantics(
              child: Icon(Icons.compress, color: colorScheme.primary),
            ),
            const SizedBox(width: 8),
            const Text('Optimize AUX Buses'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.description, style: textTheme.titleSmall),
              const Divider(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (plan.hasReplaceModeStep)
                      ListTile(
                        dense: true,
                        leading: _replaceModeSet
                            ? const Icon(Icons.check_circle,
                                color: Colors.green, size: 20)
                            : Icon(Icons.circle_outlined,
                                color: colorScheme.onSurfaceVariant, size: 20),
                        title: Text(
                          'Set ${plan.replaceModeAlgorithmName} to Replace on AUX $keepLocal',
                        ),
                      ),
                    for (int i = 0; i < plan.steps.length; i++)
                      _buildStepTile(plan.steps[i], i, colorScheme),
                  ],
                ),
              ),
              if (_isComplete) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Optimization complete',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!_isExecuting && !_isComplete)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          if (!_isExecuting && !_isComplete)
            ElevatedButton(
              onPressed: _execute,
              child: const Text('Confirm'),
            ),
          if (_isComplete)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  Widget _buildStepTile(
      ConsolidationStep step, int index, ColorScheme colorScheme) {
    final done = _completedSteps.contains(index);
    final busLocal = BusSpec.toLocalNumber(step.toBus) ?? step.toBus;
    return ListTile(
      dense: true,
      leading: done
          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
          : Icon(Icons.circle_outlined,
              color: colorScheme.onSurfaceVariant, size: 20),
      title: Text('Move ${step.algorithmName} to AUX $busLocal'),
    );
  }
}
