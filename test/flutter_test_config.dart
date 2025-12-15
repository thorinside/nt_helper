import 'dart:async';

import 'package:drift/drift.dart';

/// Global test configuration.
///
/// This file is automatically loaded by the Flutter test runner before
/// running any tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Suppress Drift warning about multiple database instances.
  // In tests, we intentionally create multiple in-memory databases
  // (e.g., for export/import round-trip tests).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  await testMain();
}
