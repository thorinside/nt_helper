import 'package:flutter_midi_command/flutter_midi_command.dart';

MidiCommand createNativeMidiCommand() {
  final midiCommand = MidiCommand();
  midiCommand.configureBleTransport(null);
  midiCommand.configureTransportPolicy(
    const MidiTransportPolicy(excludedTransports: {MidiTransport.ble}),
  );
  return midiCommand;
}
