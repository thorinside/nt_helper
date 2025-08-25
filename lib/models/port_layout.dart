import 'package:nt_helper/models/algorithm_port.dart';

class PortLayout {
  final List<AlgorithmPort> inputPorts;
  final List<AlgorithmPort> outputPorts;

  const PortLayout({required this.inputPorts, required this.outputPorts});

  PortLayout copyWith({
    List<AlgorithmPort>? inputPorts,
    List<AlgorithmPort>? outputPorts,
  }) {
    return PortLayout(
      inputPorts: inputPorts ?? this.inputPorts,
      outputPorts: outputPorts ?? this.outputPorts,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortLayout &&
        other.inputPorts == inputPorts &&
        other.outputPorts == outputPorts;
  }

  @override
  int get hashCode {
    return Object.hash(inputPorts, outputPorts);
  }
}
