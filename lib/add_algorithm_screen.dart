import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:collection/collection.dart';

class AddAlgorithmScreen extends StatefulWidget {
  const AddAlgorithmScreen({super.key});

  @override
  State<AddAlgorithmScreen> createState() => _AddAlgorithmScreenState();
}

class _AddAlgorithmScreenState extends State<AddAlgorithmScreen> {
  String? selectedAlgorithmGuid;
  AlgorithmInfo? _currentAlgoInfo;
  List<int>? specValues;

  @override
  Widget build(BuildContext context) {
    final distingState = context.watch<DistingCubit>().state;
    final bool isOffline = distingState.maybeMap(
      synchronized: (s) => s.offline,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isOffline ? 'Add Algorithm (Defaults)' : 'Add Algorithm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: distingState.maybeMap(
          synchronized: (syncState) {
            final algorithms = syncState.algorithms;
            if (algorithms.isEmpty) {
              return const Center(
                  child: Text('No algorithms available in current state.'));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Algorithm',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedAlgorithmGuid,
                  isExpanded: true,
                  items: algorithms.map((algo) {
                    return DropdownMenuItem<String>(
                      value: algo.guid,
                      child: Text(
                        algo.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newGuid) {
                    setState(() {
                      selectedAlgorithmGuid = newGuid;
                      _currentAlgoInfo =
                          algorithms.firstWhereOrNull((a) => a.guid == newGuid);
                      specValues = _currentAlgoInfo?.specifications
                          .map((s) => s.defaultValue)
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: _currentAlgoInfo != null &&
                            _currentAlgoInfo!.numSpecifications > 0
                        ? _buildSpecificationInputs(
                            _currentAlgoInfo!, isOffline)
                        : Container(),
                  ),
                ),
                ElevatedButton(
                  onPressed: _currentAlgoInfo != null && specValues != null
                      ? () {
                          Navigator.pop(context, {
                            'algorithm': _currentAlgoInfo,
                            'specValues': specValues,
                          });
                        }
                      : null,
                  child: const Text('Add to Preset'),
                ),
              ],
            );
          },
          orElse: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildSpecificationInputs(AlgorithmInfo algorithm, bool isOffline) {
    if (specValues == null ||
        specValues!.length != algorithm.numSpecifications) {
      specValues = algorithm.specifications.map((s) => s.defaultValue).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
      return const Center(child: Text("Initializing specifications..."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isOffline ? 'Specifications (Using Defaults):' : 'Specifications:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...List.generate(algorithm.numSpecifications, (index) {
          final specInfo = algorithm.specifications[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: TextFormField(
              initialValue: specValues![index].toString(),
              readOnly: isOffline,
              decoration: InputDecoration(
                labelText: specInfo.name.isNotEmpty
                    ? specInfo.name
                    : 'Specification ${index + 1}',
                hintText: '(${specInfo.min} to ${specInfo.max})',
                border: const OutlineInputBorder(),
                filled: isOffline,
                fillColor: isOffline ? Colors.grey[200] : null,
              ),
              keyboardType: TextInputType.number,
              onChanged: isOffline
                  ? null
                  : (value) {
                      int parsedValue =
                          int.tryParse(value) ?? specInfo.defaultValue;
                      parsedValue =
                          parsedValue.clamp(specInfo.min, specInfo.max);
                      if (specValues![index] != parsedValue) {
                        setState(() {
                          specValues![index] = parsedValue;
                        });
                      }
                    },
            ),
          );
        }),
      ],
    );
  }
}
