import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_deletion_state.freezed.dart';

/// Enum representing different deletion interaction modes
enum DeletionMode {
  /// No deletion interaction active
  idle,
  /// Desktop hover mode - connection is being hovered
  hovering,
  /// Mobile tap mode - connection(s) are selected for deletion
  tapSelected,
}

/// Immutable state representing the current connection deletion interaction state
@freezed
class ConnectionDeletionState with _$ConnectionDeletionState {
  /// Creates an idle state with no active deletion interactions
  const factory ConnectionDeletionState.initial() = _Initial;

  /// Creates a hovering state for desktop platforms
  /// 
  /// [connectionId] must not be empty
  const factory ConnectionDeletionState.hovering(String connectionId) = _Hovering;


  /// Creates a tap-selected state for mobile platforms
  /// 
  /// [selectedConnectionIds] can be empty to represent no selection
  const factory ConnectionDeletionState.tapSelected(
    Set<String> selectedConnectionIds,
  ) = _TapSelected;

  const ConnectionDeletionState._();

  /// Returns the current deletion mode
  DeletionMode get mode {
    return map(
      initial: (_) => DeletionMode.idle,
      hovering: (_) => DeletionMode.hovering,
      tapSelected: (_) => DeletionMode.tapSelected,
    );
  }

  /// Returns the hovered connection ID if in hovering mode, null otherwise
  String? get hoveredConnectionId {
    return mapOrNull(
      hovering: (state) => state.connectionId,
    );
  }

  /// Returns the set of selected connection IDs if in tap-selected mode, empty set otherwise
  Set<String> get selectedConnectionIds {
    return mapOrNull(
      tapSelected: (state) => state.selectedConnectionIds,
    ) ?? {};
  }

  /// Returns true if currently in hovering mode
  bool get isHovering => mode == DeletionMode.hovering;

  /// Returns true if currently in tap selection mode
  bool get isTapSelecting => mode == DeletionMode.tapSelected;

  /// Returns true if currently in idle mode
  bool get isIdle => mode == DeletionMode.idle;

  /// Returns true if any connection is selected (hovered or tap-selected)
  bool get hasSelectedConnection {
    return map(
      initial: (_) => false,
      hovering: (_) => true,
      tapSelected: (state) => state.selectedConnectionIds.isNotEmpty,
    );
  }

  /// Returns true if the specified connection is currently selected
  bool isConnectionSelected(String connectionId) {
    return map(
      initial: (_) => false,
      hovering: (state) => state.connectionId == connectionId,
      tapSelected: (state) => state.selectedConnectionIds.contains(connectionId),
    );
  }
}