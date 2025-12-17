part of 'disting_cubit.dart';

// A helper class to track each parameter's polling state.
class _PollingTask {
  bool active = true;
  int noChangeCount = 0;

  _PollingTask();
}

// Retry request types for background parameter retry queue
enum _ParameterRetryType { info, enumStrings, mappings, valueStrings }

// Retry request data structure for background parameter retry queue
class _ParameterRetryRequest {
  final int slotIndex;
  final int paramIndex;
  final _ParameterRetryType type;

  _ParameterRetryRequest({
    required this.slotIndex,
    required this.paramIndex,
    required this.type,
  });
}

