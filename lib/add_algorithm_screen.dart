import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Algorithm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<AlgorithmInfo>>(
          future: context.read<DistingCubit>().getAvailableAlgorithms(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error loading algorithms: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No algorithms available.'));
            }

            final algorithms = snapshot.data!;

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
                      try {
                        _currentAlgoInfo =
                            algorithms.firstWhere((a) => a.guid == newGuid);
                      } catch (e) {
                        _currentAlgoInfo = null;
                      }
                      specValues = _currentAlgoInfo != null
                          ? List.filled(_currentAlgoInfo!.numSpecifications, 0)
                          : null;
                    });
                  },
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: _currentAlgoInfo != null &&
                            _currentAlgoInfo!.numSpecifications > 0
                        ? _buildSpecificationInputs(_currentAlgoInfo!)
                        : Container(),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _currentAlgoInfo != null
                      ? () {
                          Navigator.pop(context, {
                            'algorithm': _currentAlgoInfo,
                            'specValues': specValues ?? [],
                          });
                        }
                      : null,
                  child: const Text('Add to Preset'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpecificationInputs(AlgorithmInfo algorithm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Specifications:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...List.generate(algorithm.numSpecifications, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: TextFormField(
              initialValue: specValues![index].toString(),
              decoration: InputDecoration(
                labelText: 'Specification ${index + 1}',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  specValues![index] = int.tryParse(value) ?? 0;
                });
              },
            ),
          );
        }),
      ],
    );
  }
}
