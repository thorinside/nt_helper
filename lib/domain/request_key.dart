import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show DistingNTRespMessageType;
import 'package:nt_helper/domain/sysex/sysex_parser.dart';

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

    if (msg.payload.isNotEmpty &&
        (msg.messageType == DistingNTRespMessageType.respAlgorithmInfo ||
            msg.messageType == DistingNTRespMessageType.respNumParameters ||
            msg.messageType == DistingNTRespMessageType.respParameterInfo ||
            msg.messageType == DistingNTRespMessageType.respParameterValue ||
            msg.messageType ==
                DistingNTRespMessageType.respAllParameterValues ||
            msg.messageType == DistingNTRespMessageType.respEnumStrings ||
            msg.messageType == DistingNTRespMessageType.respMapping ||
            msg.messageType ==
                DistingNTRespMessageType.respParameterValueString ||
            msg.messageType == DistingNTRespMessageType.respAlgorithm ||
            msg.messageType == DistingNTRespMessageType.respParameterPages ||
            msg.messageType == DistingNTRespMessageType.respRouting)) {
      algorithmIndex = msg.payload[0];
    }

    if (msg.payload.length >= 2 &&
        (msg.messageType == DistingNTRespMessageType.respParameterInfo ||
            msg.messageType == DistingNTRespMessageType.respParameterValue ||
            msg.messageType == DistingNTRespMessageType.respEnumStrings ||
            msg.messageType == DistingNTRespMessageType.respMapping ||
            msg.messageType ==
                DistingNTRespMessageType.respParameterValueString)) {
      parameterNumber = msg.payload[1];
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

    // If the key cares about algorithmIndex, check if the message has it.
    if (algorithmIndex != null) {
      final requestKeyFromMsg = RequestKey.fromDistingNTParsedMessage(msg);
      if (algorithmIndex != requestKeyFromMsg.algorithmIndex) {
        return false;
      }
    }

    // If the key cares about parameterNumber, check if the message has it.
    if (parameterNumber != null) {
      final requestKeyFromMsg = RequestKey.fromDistingNTParsedMessage(msg);
      if (parameterNumber != requestKeyFromMsg.parameterNumber) {
        return false;
      }
    }

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestKey &&
          runtimeType == other.runtimeType &&
          sysExId == other.sysExId &&
          (algorithmIndex == other.algorithmIndex ||
              algorithmIndex == null ||
              other.algorithmIndex == null) &&
          (parameterNumber == other.parameterNumber ||
              parameterNumber == null ||
              other.parameterNumber == null) &&
          messageType == other.messageType;

  @override
  int get hashCode =>
      sysExId.hashCode ^
      (algorithmIndex?.hashCode ?? 0) ^
      (parameterNumber?.hashCode ?? 0) ^
      messageType.hashCode;

  @override
  String toString() =>
      "RequestKey(sysExId: $sysExId, algorithmIndex: $algorithmIndex, propertyIndex: $parameterNumber, messageType: $messageType)";
}
