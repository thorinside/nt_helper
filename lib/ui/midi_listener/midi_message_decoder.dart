/// A decoded MIDI 1.0 channel-voice message.
typedef MidiChannelMessage = ({int statusByte, int data1, int? data2});

/// Decodes all channel-voice messages in a MIDI packet.
///
/// Handles repeated status bytes, running status, and interleaved real-time
/// messages. System messages are ignored and clear running status, except for
/// real-time messages as required by MIDI 1.0.
List<MidiChannelMessage> decodeMidiChannelMessages(List<int> bytes) {
  final messages = <MidiChannelMessage>[];
  final pendingData = <int>[];
  int? runningStatus;

  for (final byte in bytes) {
    if (byte >= 0xF8) {
      continue;
    }

    if (byte >= 0x80) {
      pendingData.clear();
      runningStatus = byte <= 0xEF ? byte : null;
      continue;
    }

    if (runningStatus == null) {
      continue;
    }

    pendingData.add(byte);
    final messageType = runningStatus & 0xF0;
    final dataLength = messageType == 0xC0 || messageType == 0xD0 ? 1 : 2;
    if (pendingData.length == dataLength) {
      messages.add((
        statusByte: runningStatus,
        data1: pendingData[0],
        data2: dataLength == 2 ? pendingData[1] : null,
      ));
      pendingData.clear();
    }
  }

  return messages;
}
