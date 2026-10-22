import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _InstalledUdevRules extends Mock implements File {}

/// Firmware flow tests mock the flasher, so model its USB prerequisite too.
/// Intercept only the rule-file lookup; never install rules on the test host.
final class FirmwareUsbAccessOverrides extends IOOverrides {
  FirmwareUsbAccessOverrides() {
    when(() => _rules.exists()).thenAnswer((_) async => true);
  }

  final _rules = _InstalledUdevRules();

  @override
  File createFile(String path) =>
      path == '/etc/udev/rules.d/99-disting-nt.rules'
      ? _rules
      : super.createFile(path);
}

void setUpFirmwareUsbAccess() {
  setUp(() {
    final previous = IOOverrides.current;
    IOOverrides.global = FirmwareUsbAccessOverrides();
    addTearDown(() => IOOverrides.global = previous);
  });
}
