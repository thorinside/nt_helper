import 'package:nt_helper/models/connection.dart';

class TidyResult {
  final bool success;
  final List<Connection> originalConnections;
  final List<Connection> optimizedConnections;
  final int busesFreed;
  final Map<String, BusChange> changes;
  final String? errorMessage;
  final List<String> warnings;

  const TidyResult.success({
    required this.originalConnections,
    required this.optimizedConnections,
    required this.busesFreed,
    required this.changes,
    this.warnings = const [],
  }) : success = true,
       errorMessage = null;

  const TidyResult.failed(this.errorMessage)
    : success = false,
      originalConnections = const [],
      optimizedConnections = const [],
      busesFreed = 0,
      changes = const {},
      warnings = const [];
}

class BusChange {
  final String connectionId;
  final int oldBus;
  final int newBus;
  final bool oldReplaceMode;
  final bool newReplaceMode;
  final String reason;

  const BusChange({
    required this.connectionId,
    required this.oldBus,
    required this.newBus,
    required this.oldReplaceMode,
    required this.newReplaceMode,
    required this.reason,
  });
}
