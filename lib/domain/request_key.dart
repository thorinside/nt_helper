import 'package:nt_helper/domain/disting_nt_sysex.dart';

class RequestKey {
  final int sysExId;
  final DistingNTRespMessageType messageType; // Required
  final int? algorithmIndex; // Optional
  final int? parameterNumber; // Optional

  RequestKey({
    required this.sysExId,
    required this.messageType,
    this.algorithmIndex,
    this.parameterNumber,
  });

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
