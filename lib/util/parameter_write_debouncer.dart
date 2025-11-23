import 'dart:async';

/// Debounces parameter writes to prevent excessive MIDI writes during rapid changes
///
/// Used for slider controls where users may drag rapidly, creating many intermediate
/// values. The debouncer ensures only the final value (after user stops dragging)
/// gets written to hardware.
///
/// Example usage:
/// ```dart
/// final _debouncer = ParameterWriteDebouncer();
///
/// void _updateParameter(int paramNumber, int value) {
///   _debouncer.schedule('param_$paramNumber', () {
///     cubit.updateParameterValue(slotIndex, paramNumber, value);
///   }, Duration(milliseconds: 50));
/// }
///
/// @override
/// void dispose() {
///   _debouncer.dispose();
///   super.dispose();
/// }
/// ```
class ParameterWriteDebouncer {
  final Map<String, Timer> _timers = {};

  /// Schedules a callback to run after the specified delay
  ///
  /// If a callback with the same key is already scheduled, it will be cancelled
  /// and replaced with the new one. This ensures only the final value in a rapid
  /// sequence of changes gets processed.
  ///
  /// [key] Unique identifier for this debounced operation (e.g., 'pitch_5')
  /// [callback] Function to execute after delay
  /// [delay] How long to wait before executing (typically 50ms)
  void schedule(String key, void Function() callback, Duration delay) {
    // Cancel any pending timer for this key
    _timers[key]?.cancel();

    // Schedule new timer
    _timers[key] = Timer(delay, () {
      callback();
      _timers.remove(key);
    });
  }

  /// Cancels all pending timers and clears the map
  ///
  /// Must be called in widget dispose() to prevent memory leaks and ensure
  /// pending callbacks don't execute after widget is destroyed.
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Returns the number of currently pending timers (useful for debugging)
  int get pendingCount => _timers.length;
}
