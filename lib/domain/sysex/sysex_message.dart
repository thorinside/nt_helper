import 'dart:typed_data';

abstract class SysexMessage {
  final int sysExId;
  SysexMessage({required this.sysExId});
  Uint8List encode();
} 