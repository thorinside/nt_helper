// parameter_update_queue.dart - Latest-Value-Wins Parameter Updates
// -----------------------------------------------------------------------------
// Consolidates rapid parameter updates to prevent queue buildup:
// • Latest value wins: Replace pending updates for same parameter
// • Combined operations: Parameter set + string query as one unit
// • Rate limited: Proper intervals between device communications
// • Background processing: UI stays responsive with optimistic updates
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';

// -----------------------------------------------------------------------------
// Parameter update request
// -----------------------------------------------------------------------------

class ParameterUpdate {
  const ParameterUpdate({
    required this.algorithmIndex,
    required this.parameterNumber,
    required this.value,
    required this.needsStringUpdate,
  });

  final int algorithmIndex;
  final int parameterNumber;
  final int value;
  final bool needsStringUpdate;

  String get key => '$algorithmIndex:$parameterNumber';

  @override
  String toString() =>
      'ParameterUpdate(algo: $algorithmIndex, param: $parameterNumber, value: $value, needsString: $needsStringUpdate)';
}

// -----------------------------------------------------------------------------
// Parameter Update Queue - Latest Value Wins
// -----------------------------------------------------------------------------

class ParameterUpdateQueue {
  ParameterUpdateQueue({
    required IDistingMidiManager midiManager,
    this.processingInterval = const Duration(milliseconds: 10),
    this.operationInterval = const Duration(milliseconds: 50),
    this.onParameterStringUpdated,
  }) : _midiManager = midiManager;

  final IDistingMidiManager _midiManager;
  final Duration processingInterval;
  final Duration operationInterval;
  final void Function(int algorithmIndex, int parameterNumber, String value)?
      onParameterStringUpdated;

  // Latest value wins - keyed by "algorithmIndex:parameterNumber"
  final Map<String, ParameterUpdate> _pendingUpdates = {};

  // Processing state
  bool _isProcessing = false;
  Timer? _processTimer;
  bool _disposed = false;

  // Statistics for debugging
  int _totalUpdatesReceived = 0;
  int _totalUpdatesSent = 0;
  int _updatesConsolidated = 0;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Queue a parameter update. If an update for this parameter is already
  /// pending, it will be replaced with the new value (latest wins).
  void updateParameter({
    required int algorithmIndex,
    required int parameterNumber,
    required int value,
    required bool needsStringUpdate,
  }) {
    if (_disposed) return;

    final update = ParameterUpdate(
      algorithmIndex: algorithmIndex,
      parameterNumber: parameterNumber,
      value: value,
      needsStringUpdate: needsStringUpdate,
    );

    _totalUpdatesReceived++;

    // Latest value wins - replace any existing update for this parameter
    final wasAlreadyPending = _pendingUpdates.containsKey(update.key);
    _pendingUpdates[update.key] = update;

    if (wasAlreadyPending) {
      _updatesConsolidated++;
      debugPrint(
          '[ParameterQueue] Consolidated update for ${update.key} (total consolidated: $_updatesConsolidated)');
    }

    debugPrint(
        '[ParameterQueue] Queued: $update (pending: ${_pendingUpdates.length})');

    _scheduleProcessing();
  }

  /// Get current queue statistics for debugging
  Map<String, int> getStatistics() => {
        'received': _totalUpdatesReceived,
        'sent': _totalUpdatesSent,
        'consolidated': _updatesConsolidated,
        'pending': _pendingUpdates.length,
      };

  /// Clear all pending updates
  void clear() {
    _pendingUpdates.clear();
    _processTimer?.cancel();
    _processTimer = null;
  }

  void dispose() {
    _disposed = true;
    _processTimer?.cancel();
    _pendingUpdates.clear();
  }

  // ---------------------------------------------------------------------------
  // Internal processing
  // ---------------------------------------------------------------------------

  void _scheduleProcessing() {
    if (_isProcessing || _disposed) return;

    // Cancel any existing timer and schedule processing
    _processTimer?.cancel();
    _processTimer = Timer(processingInterval, _processNext);
  }

  Future<void> _processNext() async {
    if (_pendingUpdates.isEmpty || _isProcessing || _disposed) return;

    _isProcessing = true;

    try {
      // Take the first pending update (FIFO for fairness across parameters)
      final entry = _pendingUpdates.entries.first;
      _pendingUpdates.remove(entry.key);
      final update = entry.value;

      debugPrint('[ParameterQueue] Processing: $update');

      // Send parameter value (fire-and-forget)
      await _midiManager.setParameterValue(
        update.algorithmIndex,
        update.parameterNumber,
        update.value,
      );

      // Query parameter string if needed (expects response)
      if (update.needsStringUpdate) {
        try {
          final parameterString =
              await _midiManager.requestParameterValueString(
            update.algorithmIndex,
            update.parameterNumber,
          );
          if (parameterString != null) {
            debugPrint(
                '[ParameterQueue] Updated parameter string for ${update.key}: "${parameterString.value}"');
            // Notify the cubit about the updated parameter string
            onParameterStringUpdated?.call(
              update.algorithmIndex,
              update.parameterNumber,
              parameterString.value,
            );
          } else {
            debugPrint(
                '[ParameterQueue] No parameter string returned for ${update.key}');
          }
        } catch (e) {
          debugPrint(
              '[ParameterQueue] Failed to update parameter string for ${update.key}: $e');
          // Continue processing even if string update fails
        }
      }

      _totalUpdatesSent++;
      debugPrint(
          '[ParameterQueue] Completed: $update (remaining: ${_pendingUpdates.length})');
    } catch (e, stackTrace) {
      debugPrint('[ParameterQueue] Error processing update: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isProcessing = false;

      // Schedule next update if more pending
      if (_pendingUpdates.isNotEmpty && !_disposed) {
        _processTimer = Timer(operationInterval, _processNext);
      }
    }
  }
}
