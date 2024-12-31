import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/request_key.dart';

class DistingMidiManager {
  final MidiCommand midiCommand;
  final MidiDevice device;
  final int sysExId;

  StreamSubscription<MidiPacket>? _subscription;

  final StreamController<MapEntry<RequestKey, dynamic>> _decodedStreamController =
  StreamController.broadcast();
  Stream<MapEntry<RequestKey, dynamic>> get decodedMessages =>
      _decodedStreamController.stream;

  DistingMidiManager({
    required this.midiCommand,
    required this.device,
    required this.sysExId,
  });

  void startListening() {
    _subscription = midiCommand.onMidiDataReceived?.listen((data) {
      final parsedMessage = DistingNT.decodeDistingNTSysEx(data.data);
      if (parsedMessage != null && parsedMessage.sysExId == sysExId) {
        final decodedResponse = _decodeResponse(parsedMessage);
        _handleDecodedMessage(parsedMessage, decodedResponse);
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _decodedStreamController.close();
  }

  /// Decodes a response and sends it to the stream.
  void _handleDecodedMessage(
      DistingNTParsedMessage parsedMessage, dynamic decodedResponse) {
    final responseKey = RequestKey(
      sysExId: sysExId,
      messageType: parsedMessage.messageType,
      algorithmIndex: (decodedResponse is HasAlgorithmIndex)
          ? decodedResponse.algorithmIndex
          : null,
      parameterNumber: (decodedResponse is HasParameterNumber)
          ? decodedResponse.parameterNumber
          : null,
    );

    _decodedStreamController.add(MapEntry(responseKey, decodedResponse));
  }

  dynamic _decodeResponse(DistingNTParsedMessage parsedMessage) {
    try {
      // Extract relevant details from the parsed message
      final messageType = parsedMessage.messageType;
      final payload = parsedMessage.payload;

      // Handle response types and decode accordingly
      switch (messageType) {
        case DistingNTRespMessageType.respNumAlgorithms:
          return DistingNT.decodeNumberOfAlgorithms(payload);

        case DistingNTRespMessageType.respNumAlgorithmsInPreset:
          return DistingNT.decodeNumberOfAlgorithmsInPreset(payload);

        case DistingNTRespMessageType.respAlgorithmInfo:
          return DistingNT.decodeAlgorithmInfo(payload);

        case DistingNTRespMessageType.respPresetName:
          return DistingNT.decodeMessage(payload);

        case DistingNTRespMessageType.respNumParameters:
          return DistingNT.decodeNumParameters(payload);

        case DistingNTRespMessageType.respParameterInfo:
          return DistingNT.decodeParameterInfo(payload);

        case DistingNTRespMessageType.respAllParameterValues:
          return DistingNT.decodeAllParameterValues(payload);

        case DistingNTRespMessageType.respParameterValue:
          return DistingNT.decodeParameterValue(payload);

        case DistingNTRespMessageType.respParameterValueString:
          return DistingNT.decodeParameterValueString(payload);

        case DistingNTRespMessageType.respEnumStrings:
          return DistingNT.decodeEnumStrings(payload);

        case DistingNTRespMessageType.respMapping:
          return DistingNT.decodeMapping(payload);

        case DistingNTRespMessageType.respRouting:
          return DistingNT.decodeRoutingInformation(payload);

        case DistingNTRespMessageType.respMessage:
          return DistingNT.decodeMessage(payload);

        case DistingNTRespMessageType.respAlgorithmGuid:
          return DistingNT.decodeAlgorithmGuid(payload);

        case DistingNTRespMessageType.respUnitStrings:
          return DistingNT.decodeStrings(payload);

        default:
          print("Unknown or unsupported message type: $messageType");
          return null; // Unhandled message type
      }
    } catch (e) {
      print("Error decoding response: $e");
      return null;
    }
  }

  void _sendSysExMessage(Uint8List message) {
    midiCommand.sendData(message, deviceId: device.id);
    print("Sent SysEx message: $message");
  }

  /// Sends a screenshot request and waits for the screenshot response
  void requestScreenshot() async {
    _sendSysExMessage(DistingNT.encodeTakeScreenshot(sysExId));
  }

  /// Sets the real-time clock
  void setRealTimeClock(int unixTimeSeconds) async {
    final packet = DistingNT.encodeSetRealTimeClock(sysExId, unixTimeSeconds);
    _sendSysExMessage(packet);
  }

  /// Requests the version string
  void requestVersionString() async {
    final packet = DistingNT.encodeRequestVersionString(sysExId);
    _sendSysExMessage(packet);
  }

  /// Requests the number of algorithms
  void requestNumberOfAlgorithms() async {
    final packet = DistingNT.encodeRequestNumAlgorithms(sysExId);
    _sendSysExMessage(packet);
  }

  /// Requests the number of algorithms in the preset
  void requestNumAlgorithmsInPreset() async {
    final packet = DistingNT.encodeNumAlgorithmsInPreset(sysExId);
    _sendSysExMessage(packet);
  }

  /// Requests algorithm information by index
  void requestAlgorithmInfo(int algorithmIndex) async {
    final packet =
        DistingNT.encodeRequestAlgorithmInfo(sysExId, algorithmIndex);
    _sendSysExMessage(packet);
  }

  /// Loads a preset by name
  // Future<void> loadPreset(String presetName) async {
  //   final packet = DistingNT.encodeLoadPreset(sysExId, presetName);
  //   final key = RequestKey(
  //     sysExId: sysExId,
  //     messageType: DistingNTRespMessageType.unknown, // No response expected
  //   );
  //   await _sendRequest<void>(packet, key);
  // }

  /// Requests the preset name
  void requestPresetName() async {
    final packet = DistingNT.encodeRequestPresetName(sysExId);
    _sendSysExMessage(packet);
  }

  /// Requests the number of parameters for an algorithm
  void requestNumberOfParameters(int algorithmIndex) async {
    final packet =
        DistingNT.encodeRequestNumParameters(sysExId, algorithmIndex);
    _sendSysExMessage(packet);
  }

  /// Requests parameter info for a given parameter
  void requestParameterInfo(
      int algorithmIndex, int parameterNumber) async {
    final packet = DistingNT.encodeRequestParameterInfo(
        sysExId, algorithmIndex, parameterNumber);
    _sendSysExMessage(packet);
  }

  /// Requests the parameter value for a given parameter
  void requestParameterValue(
      int algorithmIndex, int parameterNumber) async {
    final packet = DistingNT.encodeRequestParameterValue(
        sysExId, algorithmIndex, parameterNumber);
    _sendSysExMessage(packet);
  }

  void requestUnitStrings() async {
    final packet = DistingNT.encodeRequestUnitStrings(sysExId);
    _sendSysExMessage(packet);
  }

  void requestParameterEnumStrings(
      int algorithmIndex, int parameterNumber) async {
    final packet = DistingNT.encodeRequestEnumStrings(
        sysExId, algorithmIndex, parameterNumber);
    _sendSysExMessage(packet);
  }

  void requestMappings(
      int algorithmIndex, int parameterNumber) async {
    final packet = DistingNT.encodeRequestMappings(
        sysExId, algorithmIndex, parameterNumber);
    _sendSysExMessage(packet);
  }

  void requestParameterValueString(
      int algorithmIndex, int parameterNumber) async {
    final packet = DistingNT.encodeRequestParameterValueString(
        sysExId, algorithmIndex, parameterNumber);
    _sendSysExMessage(packet);
  }

  void requestAlgorithmGuid(int algorithmIndex) async {
    final packet =
        DistingNT.encodeRequestAlgorithmGuid(sysExId, algorithmIndex);
    _sendSysExMessage(packet);
  }

  void setParameterValue(int algorithmIndex, int parameterNumber, int value) {
    final packet = DistingNT.encodeSetParameterValue(
        sysExId, algorithmIndex, parameterNumber, value);
    _sendSysExMessage(packet);
  }

  /// Requests routing information for a given algorithm
// Future<RoutingInfo> requestRoutingInformation(int algorithmIndex) async {
//   final packet = DistingNT.encodeRequestRouting(sysExId, algorithmIndex);
//   final key = RequestKey(
//     sysExId: sysExId,
//     algorithmIndex: algorithmIndex,
//     messageType: DistingNTRespMessageType.respRouting,
//   );
//   return await _sendRequest<RoutingInfo>(packet, key);
// }
}
