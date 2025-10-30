import 'package:nt_helper/core/routing/models/port.dart';

/// Utility class for generating ES-5 Eurorack hardware node port configurations.
///
/// The Expert Sleepers ES-5 is a Eurorack expander module that receives signals
/// from a computer/synthesizer and outputs them to CV/gate jacks in the modular system.
///
/// Hardware Configuration:
/// - 10 input ports (from the algorithm's perspective, these receive signals to output to hardware)
/// - 0 output ports (ES-5 is a sink - it only outputs to hardware, doesn't send back to algorithms)
///
/// Port Configuration:
/// - L and R ports: Audio signals for Silent Way encoding (fixed bus assignments 29, 30)
/// - Numbered ports 1-8: Gate/trigger outputs (dynamic bus assignment based on algorithm)
///
/// This class follows the pattern established in PhysicalPortGenerator for
/// generating hardware node port configurations.
class ES5HardwareNode {
  /// Unique identifier for the ES-5 hardware node.
  static const String id = 'es5_hardware_node';

  /// Human-readable name for the ES-5 hardware node.
  static const String name = 'ES-5';

  /// Type identifier for the ES-5 hardware node.
  static const String type = 'es5_expander';

  /// Number of ES-5 input ports (L, R, and 1-8).
  static const int inputPortCount = 10;

  /// Bus assignment for the L (left) audio port.
  static const int leftAudioBus = 29;

  /// Bus assignment for the R (right) audio port.
  static const int rightAudioBus = 30;

  /// Generates a list of all ES-5 input ports.
  ///
  /// Creates 10 ports:
  /// - L port: Audio input for Silent Way encoding (bus 29)
  /// - R port: Audio input for Silent Way encoding (bus 30)
  /// - Ports 1-8: Gate/trigger outputs (no fixed bus assignment)
  ///
  /// Returns a list of 10 Port objects configured as ES-5 inputs.
  static List<Port> createInputPorts() {

    final ports = <Port>[];

    // Create L port (audio, bus 29)
    ports.add(
      Port(
        id: 'es5_L',
        name: 'L',
        type: PortType.audio,
        direction: PortDirection.input,
        description: 'ES-5 Left (Silent Way)',
        busValue: leftAudioBus,
        isPhysical: true,
        nodeId: id,
      ),
    );

    // Create R port (audio, bus 30)
    ports.add(
      Port(
        id: 'es5_R',
        name: 'R',
        type: PortType.audio,
        direction: PortDirection.input,
        description: 'ES-5 Right (Silent Way)',
        busValue: rightAudioBus,
        isPhysical: true,
        nodeId: id,
      ),
    );

    // Create numbered ports 1-8 (gate, no fixed bus)
    for (int i = 1; i <= 8; i++) {
      ports.add(
        Port(
          id: 'es5_$i',
          name: '$i',
          type: PortType.gate,
          direction: PortDirection.input,
          description: 'ES-5 Output $i',
          isPhysical: true,
          nodeId: id,
        ),
      );
    }


    return ports;
  }

  /// Generates an empty list of output ports.
  ///
  /// The ES-5 is a sink device - it only receives signals from algorithms
  /// and outputs them to hardware. It does not send signals back to algorithms.
  ///
  /// Returns an empty list.
  static List<Port> createOutputPorts() {
    return [];
  }

  /// Validates that a port belongs to the ES-5 hardware node.
  static bool isES5Port(Port port) {
    return port.nodeId == id;
  }

  /// Gets the L (left) audio port.
  static Port getLeftAudioPort() {
    return Port(
      id: 'es5_L',
      name: 'L',
      type: PortType.audio,
      direction: PortDirection.input,
      description: 'ES-5 Left (Silent Way)',
      busValue: leftAudioBus,
      isPhysical: true,
      nodeId: id,
    );
  }

  /// Gets the R (right) audio port.
  static Port getRightAudioPort() {
    return Port(
      id: 'es5_R',
      name: 'R',
      type: PortType.audio,
      direction: PortDirection.input,
      description: 'ES-5 Right (Silent Way)',
      busValue: rightAudioBus,
      isPhysical: true,
      nodeId: id,
    );
  }

  /// Gets a numbered gate port (1-8).
  ///
  /// [portNumber] should be between 1 and 8 inclusive.
  /// Throws [ArgumentError] if portNumber is out of range.
  static Port getNumberedPort(int portNumber) {
    if (portNumber < 1 || portNumber > 8) {
      throw ArgumentError(
        'ES-5 numbered port must be between 1 and 8, got $portNumber',
      );
    }

    return Port(
      id: 'es5_$portNumber',
      name: '$portNumber',
      type: PortType.gate,
      direction: PortDirection.input,
      description: 'ES-5 Output $portNumber',
      isPhysical: true,
      nodeId: id,
    );
  }
}
