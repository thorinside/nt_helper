import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

/// The routing shape used by Airwindows kernel wrappers and SDK gainMultichannel:
/// one base audio input/output, with channel count supplied at construction.
Slot groupedAudioSlot({
  String guid = 'ATo6',
  String name = 'ToTape6',
  int slotIndex = 0,
  List<int> specifications = const [2],
  int input = 11,
  int output = 23,
  String inputName = 'Input 1',
  String outputName = 'Output 1',
  bool explicitStereo = false,
  bool controlPorts = false,
  int? width,
}) {
  ParameterInfo parameter(int number, String name, int flags) => ParameterInfo(
    algorithmIndex: slotIndex,
    parameterNumber: number,
    name: name,
    min: 0,
    max: 64,
    defaultValue: 0,
    unit: 1,
    powerOfTen: 0,
    ioFlags: flags,
  );
  final parameters = [
    parameter(1, inputName, 5),
    parameter(2, outputName, 6),
    parameter(3, '$outputName mode', 8),
    if (explicitStereo) ...[
      parameter(4, 'Input R', 5),
      parameter(5, 'Output R', 6),
    ],
    if (controlPorts) ...[
      parameter(6, 'CV input', 1),
      parameter(7, 'CV output', 2),
    ],
    if (width != null) parameter(8, 'Width', 0),
  ];
  final rawValues = {
    1: input,
    2: output,
    3: 1,
    if (explicitStereo) ...{4: input + 1, 5: output + 1},
    if (controlPorts) ...{6: 3, 7: 27},
    8: ?width,
  };
  return Slot(
    algorithm: Algorithm(
      algorithmIndex: slotIndex,
      guid: guid,
      name: name,
      specifications: specifications,
      hasAuthoritativeSpecifications: true,
    ),
    routing: RoutingInfo.filler(),
    pages: ParameterPages(
      algorithmIndex: slotIndex,
      pages: [
        ParameterPage(
          name: 'Routing',
          parameters: parameters.map((p) => p.parameterNumber).toList(),
        ),
      ],
    ),
    parameters: parameters,
    values: [
      for (final entry in rawValues.entries)
        ParameterValue(
          algorithmIndex: slotIndex,
          parameterNumber: entry.key,
          value: entry.value,
        ),
    ],
    enums: [
      ParameterEnumStrings(
        algorithmIndex: slotIndex,
        parameterNumber: 3,
        values: const ['Add', 'Replace'],
      ),
    ],
    mappings: const [],
    valueStrings: const [],
  );
}

AlgorithmInfo groupedAudioInfo({
  String guid = 'ATo6',
  String name = 'ToTape6',
  List<Specification>? definitions,
}) => AlgorithmInfo(
  algorithmIndex: 0,
  guid: guid,
  name: name,
  isPlugin: guid != guid.toLowerCase(),
  isLoaded: true,
  specifications: definitions ?? [channelSpecification()],
);

Specification channelSpecification({String name = 'Channels', int max = 8}) =>
    Specification(name: name, min: 1, max: max, defaultValue: 1, type: 0);
