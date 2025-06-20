import 'package:flutter/foundation.dart';

abstract class SysexResponse {
  final Uint8List data;

  SysexResponse(this.data);

  dynamic parse();
}
