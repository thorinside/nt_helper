/// Main-authority snapshot for either remote host.
///
/// Pots and holds describe local intended input, never hardware readback or
/// acknowledged execution. A host must acquire a new session after invalidation.
final class RemoteControlState {
  RemoteControlState({
    this.connectionId,
    this.sessionId,
    this.unavailableReason,
    Set<int> heldControls = const {},
    Set<int> pendingReleaseControls = const {},
    List<int> potValues = const [2048, 2048, 2048],
    this.pending = false,
    this.error,
  }) : heldControls = Set<int>.unmodifiable(heldControls),
       pendingReleaseControls = Set<int>.unmodifiable(pendingReleaseControls),
       potValues = List<int>.unmodifiable(potValues);

  final int? connectionId;
  final String? sessionId;
  final String? unavailableReason;
  final Set<int> heldControls;

  /// Pushes whose delivery may have occurred and whose release has not been
  /// confirmed locally after the host session ended or became invalid.
  /// A completed transport write still does not prove hardware execution.
  final Set<int> pendingReleaseControls;
  final List<int> potValues;
  final bool pending;
  final String? error;

  bool get available => unavailableReason == null;
}
