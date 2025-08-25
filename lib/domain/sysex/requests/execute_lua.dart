import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'dart:typed_data';
import 'dart:convert';

import 'package:nt_helper/domain/sysex/sysex_message.dart';
import 'package:nt_helper/domain/sysex/sysex_utils.dart';

class ExecuteLuaMessage extends SysexMessage {
  final String luaScript;

  ExecuteLuaMessage({required super.sysExId, required this.luaScript});

  @override
  Uint8List encode() {
    // Convert Lua script to ASCII bytes
    final scriptBytes = utf8.encode(luaScript);

    final bytes = <int>[
      ...buildHeader(sysExId),
      DistingNTRequestMessageType.executeLua.value,
      ...scriptBytes, // Lua script text (not null-terminated, F7 indicates end)
      ...buildFooter(),
    ];
    return Uint8List.fromList(bytes);
  }
}
