import 'dart:typed_data';

abstract class SysexMessage {
  final int sysExId;
  SysexMessage(this.sysExId);
  Uint8List encode();
} 