import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show DistingNTRespMessageType;

class Response {
  final int sysExId;
  final int? algorithmIndex;
  final int? propertyIndex;
  final DistingNTRespMessageType messageType;
  final dynamic payload;

  Response({
    required this.sysExId,
    this.algorithmIndex,
    this.propertyIndex,
    required this.messageType,
    required this.payload,
  });

  @override
  String toString() =>
      "Response(sysExId: $sysExId, algorithmIndex: $algorithmIndex, propertyIndex: $propertyIndex, messageType: $messageType, payload: $payload)";
}
