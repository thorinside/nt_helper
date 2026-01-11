import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/cpu_usage.dart';
import 'package:nt_helper/services/settings_service.dart';

/// A compact CPU monitor widget that displays CPU usage information.
/// Shows the two main CPU usage numbers with a tooltip containing slot breakdown.
/// Automatically pauses CPU monitoring when not visible and resumes when visible.
class CpuMonitorWidget extends StatefulWidget {
  const CpuMonitorWidget({super.key});

  @override
  State<CpuMonitorWidget> createState() => _CpuMonitorWidgetState();
}

class _CpuMonitorWidgetState extends State<CpuMonitorWidget> {
  late DistingCubit _distingCubit;
  bool _isVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distingCubit = context.read<DistingCubit>();
  }

  void _updateVisibility(bool isVisible) {
    if (_isVisible != isVisible) {
      _isVisible = isVisible;
      if (isVisible) {
        _distingCubit.resumeCpuMonitoring();
      } else {
        _distingCubit.pauseCpuMonitoring();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to CPU monitor setting changes
    return ValueListenableBuilder<bool>(
      valueListenable: SettingsService().cpuMonitorEnabledNotifier,
      builder: (context, cpuMonitorEnabled, _) {
        // Check if CPU monitor is disabled in settings
        if (!cpuMonitorEnabled) {
          _updateVisibility(false);
          return const SizedBox.shrink();
        }

        return BlocBuilder<DistingCubit, DistingState>(
          builder: (context, state) {
            // Only show CPU monitor when connected to a physical device
            final shouldShow = state is DistingStateSynchronized &&
                !state.offline &&
                !state.demo;

            if (!shouldShow) {
              // Pause monitoring when not showing
              _updateVisibility(false);
              return const SizedBox.shrink();
            }

            // Resume monitoring when visible
            _updateVisibility(true);

            return StreamBuilder<CpuUsage>(
              stream: _distingCubit.cpuUsageStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  // Show placeholder while loading
                  return _buildCpuDisplay(
                    context: context,
                    cpu1: null,
                    cpu2: null,
                    slotUsages: [],
                    isLoading: true,
                  );
                }

                final cpuUsage = snapshot.data!;
                return _buildCpuDisplay(
                  context: context,
                  cpu1: cpuUsage.cpu1,
                  cpu2: cpuUsage.cpu2,
                  slotUsages: cpuUsage.slotUsages,
                  isLoading: false,
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // Pause monitoring when widget is disposed
    _updateVisibility(false);
    super.dispose();
  }

  Widget _buildCpuDisplay({
    required BuildContext context,
    required int? cpu1,
    required int? cpu2,
    required List<int> slotUsages,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);

    // Check if either CPU core is above 90%
    final bool isHighUsage =
        (cpu1 != null && cpu1 > 90) || (cpu2 != null && cpu2 > 90);

    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: isHighUsage
          ? theme.colorScheme.error
          : theme.colorScheme.onSurfaceVariant,
    );

    // Build tooltip content with slot breakdown
    final tooltipContent = _buildTooltipContent(
      context: context,
      cpu1: cpu1,
      cpu2: cpu2,
      slotUsages: slotUsages,
      isLoading: isLoading,
    );

    return Tooltip(
      message: tooltipContent,
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.memory,
              size: 14,
              color: isHighUsage
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            if (isLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Text('${cpu1 ?? 0}% | ${cpu2 ?? 0}%', style: textStyle),
          ],
        ),
      ),
    );
  }

  String _buildTooltipContent({
    required BuildContext context,
    required int? cpu1,
    required int? cpu2,
    required List<int> slotUsages,
    required bool isLoading,
  }) {
    if (isLoading) {
      return 'Loading CPU usage...';
    }

    final buffer = StringBuffer();
    buffer.writeln('CPU Usage:');
    buffer.writeln('Core 1: ${cpu1 ?? 0}%');
    buffer.writeln('Core 2: ${cpu2 ?? 0}%');

    if (slotUsages.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Algorithm Slots:');
      for (int i = 0; i < slotUsages.length; i++) {
        buffer.writeln('Slot ${i + 1}: ${slotUsages[i]}%');
      }
    }

    return buffer.toString().trim();
  }
}
