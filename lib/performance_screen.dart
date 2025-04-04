import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/synchronized_screen.dart';

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
            final mappedParameters =
                context.read<DistingCubit>().buildMappedParameterList();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ListView.builder(
                itemCount: mappedParameters.length,
                itemBuilder: (context, index) {
                  final item = mappedParameters.elementAt(index);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      index == 0 ||
                              (item.algorithm.name !=
                                  mappedParameters[index - 1].algorithm.name)
                          ? Padding(
                              padding: EdgeInsets.only(
                                  top: (index == 0 ? 0.0 : 16.0), bottom: 8),
                              child: Text(
                                item.algorithm.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.color
                                          ?.withAlpha(200),
                                    ),
                              ),
                            )
                          : SizedBox.shrink(),
                      ParameterEditorView(
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
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
