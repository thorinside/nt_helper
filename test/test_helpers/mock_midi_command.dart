import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:mocktail/mocktail.dart';

/// Mock MidiCommand for tests that create DistingCubit directly.
/// Pass this to DistingCubit to avoid MissingPluginException from teardown().
class MockMidiCommand extends Mock implements MidiCommand {}
