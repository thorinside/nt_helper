import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show DistingNTRespMessageType;
import 'package:nt_helper/domain/sysex/sysex_parser.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class RequestKey {
  final int sysExId;
  final DistingNTRespMessageType?
  messageType; // Optional in the case of messages that don't return a value
  final int? algorithmIndex; // Optional
  final int? parameterNumber; // Optional

  RequestKey({
    required this.sysExId,
    this.messageType,
    this.algorithmIndex,
    this.parameterNumber,
  });

  factory RequestKey.fromDistingNTParsedMessage(DistingNTParsedMessage msg) {
    int? algorithmIndex;
    int? parameterNumber;

    switch (msg.messageType) {
      // These messages have an algorithm index as the first payload byte.
      case DistingNTRespMessageType.respNumParameters:
      case DistingNTRespMessageType.respAllParameterValues:
      case DistingNTRespMessageType.respAlgorithm:
      case DistingNTRespMessageType.respParameterPages:
      case DistingNTRespMessageType.respRouting:
        if (msg.payload.isNotEmpty) {
          algorithmIndex = msg.payload[0];
        }
        break;

      // These messages have both algorithm and parameter indices.
      case DistingNTRespMessageType.respParameterInfo:
      case DistingNTRespMessageType.respParameterValue:
      case DistingNTRespMessageType.respEnumStrings:
      case DistingNTRespMessageType.respMapping:
      case DistingNTRespMessageType.respParameterValueString:
        if (msg.payload.isNotEmpty) {
          algorithmIndex = msg.payload[0];
        }
        if (msg.payload.length >= 4) {
          // decode16 reads 3 bytes at offset 1, so we need indices 1,2,3
          parameterNumber = decode16(msg.payload, 1);
        }
        break;
      case DistingNTRespMessageType.respOutputModeUsage:
        if (msg.payload.isNotEmpty) {
          algorithmIndex = msg.payload[0];
        }
        if (msg.payload.length >= 4) {
          // Output mode usage uses unsigned parameter numbers
          parameterNumber = decode16Unsigned(msg.payload, 1);
        }
        break;

      // Other messages don't have these indices.
      case DistingNTRespMessageType.respAlgorithmInfo:
      default:
        break;
    }

    return RequestKey(
      sysExId: msg.sysExId,
      messageType: msg.messageType,
      algorithmIndex: algorithmIndex,
      parameterNumber: parameterNumber,
    );
  }

  bool matches(DistingNTParsedMessage msg) {
    if (sysExId != msg.sysExId) return false;
    if (messageType != msg.messageType) return false;

    // Create a key from the message to easily access its embedded indices
    final responseKey = RequestKey.fromDistingNTParsedMessage(msg);

    if (algorithmIndex != null &&
        algorithmIndex != responseKey.algorithmIndex) {
      return false;
    }

    // For enum strings, be lenient with parameterNumber matching since firmware
    // may return corrupted values for some algorithms (e.g., Macro Oscillator).
    // We still require algorithmIndex to match to avoid out-of-order issues.
    if (messageType == DistingNTRespMessageType.respEnumStrings) {
      return true;
    }

    if (parameterNumber != null &&
        parameterNumber != responseKey.parameterNumber) {
      return false;
    }

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestKey &&
          runtimeType == other.runtimeType &&
          sysExId == other.sysExId &&
          messageType == other.messageType &&
          algorithmIndex == other.algorithmIndex &&
          parameterNumber == other.parameterNumber;

  @override
  int get hashCode =>
      Object.hash(sysExId, messageType, algorithmIndex, parameterNumber);

  @override
  String toString() =>
      "RequestKey(sysExId: $sysExId, algorithmIndex: $algorithmIndex, propertyIndex: $parameterNumber, messageType: $messageType)";
}
