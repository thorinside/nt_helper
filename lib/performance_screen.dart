import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/synchronized_screen.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen(
      {super.key, required this.mappedParameters, required this.units});

  final List<MappedParameter> mappedParameters;
  final List<String> units;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perform')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  unit: item.parameter.getUnitString(units),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
