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
    List<int> potValues = const [2048, 2048, 2048],
    this.pending = false,
    this.error,
  }) : heldControls = Set<int>.unmodifiable(heldControls),
       potValues = List<int>.unmodifiable(potValues);

  final int? connectionId;
  final String? sessionId;
  final String? unavailableReason;
  final Set<int> heldControls;
  final List<int> potValues;
  final bool pending;
  final String? error;

  bool get available => unavailableReason == null;
}
