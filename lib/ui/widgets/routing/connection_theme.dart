import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/ui/widgets/routing/accessibility_colors.dart';

/// Visual styling configuration for different connection types
class ConnectionVisualTheme {
  /// Theme for regular (direct) connections
  final ConnectionStyle directConnection;

  /// Theme for ghost connections
  final ConnectionStyle ghostConnection;

  /// Theme for selected connections
  final ConnectionStyle selectedConnection;

  /// Theme for highlighted connections
  final ConnectionStyle highlightedConnection;

  /// Theme for error/invalid connections
  final ConnectionStyle errorConnection;

  const ConnectionVisualTheme({
    required this.directConnection,
    required this.ghostConnection,
    required this.selectedConnection,
    required this.highlightedConnection,
    required this.errorConnection,
  });

  /// Create a default theme based on Material Design color scheme
  factory ConnectionVisualTheme.fromColorScheme(ColorScheme colorScheme) {
    final accessibleColors = AccessibilityColors.fromColorScheme(colorScheme);

    return ConnectionVisualTheme(
      directConnection: ConnectionStyle(
        strokeWidth: 2.5, // Slightly thicker for better visibility
        color: accessibleColors.primaryConnection,
        dashPattern: null, // Solid line
        animationEnabled: false,
        endpointRadius: 3.0,
        glowEffect: false,
      ),
      ghostConnection: ConnectionStyle(
        strokeWidth: 2.0, // Thicker for better visibility
        color: accessibleColors.secondaryConnection,
        dashPattern: [8.0, 4.0], // Dashed line with good spacing
        animationEnabled: true,
        endpointRadius: 2.5,
        glowEffect: true,
      ),
      selectedConnection: ConnectionStyle(
        strokeWidth: 3.5, // Thicker for high visibility
        color: accessibleColors.selectionIndicator,
        dashPattern: null,
        animationEnabled: false,
        endpointRadius: 4.0,
        glowEffect: true,
      ),
      highlightedConnection: ConnectionStyle(
        strokeWidth: 3.0, // Thicker for better hover indication
        color: accessibleColors.hoverIndicator,
        dashPattern: null,
        animationEnabled: false,
        endpointRadius: 3.5,
        glowEffect: false,
      ),
      errorConnection: ConnectionStyle(
        strokeWidth: 2.5, // Thicker for better error visibility
        color: accessibleColors.errorConnection,
        dashPattern: [6.0, 3.0], // Good contrast pattern for errors
        animationEnabled: false,
        endpointRadius: 3.0,
        glowEffect: false,
      ),
    );
  }

  /// Get the appropriate style for a connection based on its state
  ConnectionStyle getStyleForConnection({
    required Connection connection,
    required bool isSelected,
    required bool isHighlighted,
    required bool hasError,
  }) {
    // Error state takes precedence
    if (hasError) {
      return errorConnection;
    }

    // Selection state
    if (isSelected) {
      return selectedConnection;
    }

    // Highlight state
    if (isHighlighted) {
      return highlightedConnection;
    }

    // Connection type
    if (connection.isGhostConnection) {
      return ghostConnection;
    }

    return directConnection;
  }
}

/// Style configuration for a single connection type
class ConnectionStyle {
  /// Stroke width for the connection line
  final double strokeWidth;

  /// Primary color for the connection
  final Color color;

  /// Dash pattern for dashed lines (null for solid)
  final List<double>? dashPattern;

  /// Whether to show animated flow effects
  final bool animationEnabled;

  /// Radius for connection endpoints
  final double endpointRadius;

  /// Whether to show glow effect around connection
  final bool glowEffect;

  const ConnectionStyle({
    required this.strokeWidth,
    required this.color,
    this.dashPattern,
    required this.animationEnabled,
    required this.endpointRadius,
    required this.glowEffect,
  });

  /// Create a copy with modified properties
  ConnectionStyle copyWith({
    double? strokeWidth,
    Color? color,
    List<double>? dashPattern,
    bool? animationEnabled,
    double? endpointRadius,
    bool? glowEffect,
  }) {
    return ConnectionStyle(
      strokeWidth: strokeWidth ?? this.strokeWidth,
      color: color ?? this.color,
      dashPattern: dashPattern ?? this.dashPattern,
      animationEnabled: animationEnabled ?? this.animationEnabled,
      endpointRadius: endpointRadius ?? this.endpointRadius,
      glowEffect: glowEffect ?? this.glowEffect,
    );
  }

  /// Whether this style uses dashed lines
  bool get isDashed => dashPattern != null && dashPattern!.isNotEmpty;
}

/// Port type color mapping for consistent visual language
class PortTypeColors {
  /// Audio signal color (blue family)
  static const Color audio = Color(0xFF2196F3);

  /// CV signal color (orange family)
  static const Color cv = Color(0xFFFF9800);

  /// Gate signal color (red family)
  static const Color gate = Color(0xFFF44336);

  /// Clock/Trigger signal color (purple family)
  static const Color clockTrigger = Color(0xFF9C27B0);

  /// Default/unknown signal color (grey)
  static const Color unknown = Color(0xFF757575);

  /// Get color for a port type
  static Color getColorForPortType(String portType) {
    final type = portType.toLowerCase();

    if (type.contains('audio')) return audio;
    if (type.contains('cv')) return cv;
    if (type.contains('gate')) return gate;
    if (type.contains('clock') || type.contains('trigger')) return clockTrigger;

    return unknown;
  }

  /// Get color for a port ID (analyzing the ID string)
  static Color getColorForPortId(String portId) {
    final id = portId.toLowerCase();

    if (id.contains('audio')) return audio;
    if (id.contains('cv')) return cv;
    if (id.contains('gate')) return gate;
    if (id.contains('clock') || id.contains('trigger')) return clockTrigger;

    return unknown;
  }
}

/// Connection state management for visual consistency
class ConnectionStateManager {
  final ConnectionVisualTheme theme;

  /// Currently selected connections
  final Set<String> selectedConnectionIds;

  /// Currently highlighted connections
  final Set<String> highlightedConnectionIds;

  /// Connections with errors
  final Set<String> errorConnectionIds;

  ConnectionStateManager({
    required this.theme,
    Set<String>? selectedConnectionIds,
    Set<String>? highlightedConnectionIds,
    Set<String>? errorConnectionIds,
  }) : selectedConnectionIds = selectedConnectionIds ?? {},
       highlightedConnectionIds = highlightedConnectionIds ?? {},
       errorConnectionIds = errorConnectionIds ?? {};

  /// Get the visual style for a specific connection
  ConnectionStyle getConnectionStyle(Connection connection) {
    return theme.getStyleForConnection(
      connection: connection,
      isSelected: selectedConnectionIds.contains(connection.id),
      isHighlighted: highlightedConnectionIds.contains(connection.id),
      hasError: errorConnectionIds.contains(connection.id),
    );
  }

  /// Create a copy with updated state
  ConnectionStateManager copyWith({
    ConnectionVisualTheme? theme,
    Set<String>? selectedConnectionIds,
    Set<String>? highlightedConnectionIds,
    Set<String>? errorConnectionIds,
  }) {
    return ConnectionStateManager(
      theme: theme ?? this.theme,
      selectedConnectionIds:
          selectedConnectionIds ?? this.selectedConnectionIds,
      highlightedConnectionIds:
          highlightedConnectionIds ?? this.highlightedConnectionIds,
      errorConnectionIds: errorConnectionIds ?? this.errorConnectionIds,
    );
  }

  /// Select a connection
  ConnectionStateManager selectConnection(String connectionId) {
    return copyWith(
      selectedConnectionIds: {...selectedConnectionIds, connectionId},
    );
  }

  /// Deselect a connection
  ConnectionStateManager deselectConnection(String connectionId) {
    final updated = Set<String>.from(selectedConnectionIds);
    updated.remove(connectionId);
    return copyWith(selectedConnectionIds: updated);
  }

  /// Clear all selections
  ConnectionStateManager clearSelections() {
    return copyWith(selectedConnectionIds: {});
  }

  /// Highlight a connection
  ConnectionStateManager highlightConnection(String connectionId) {
    return copyWith(
      highlightedConnectionIds: {...highlightedConnectionIds, connectionId},
    );
  }

  /// Remove highlight from connection
  ConnectionStateManager unhighlightConnection(String connectionId) {
    final updated = Set<String>.from(highlightedConnectionIds);
    updated.remove(connectionId);
    return copyWith(highlightedConnectionIds: updated);
  }

  /// Clear all highlights
  ConnectionStateManager clearHighlights() {
    return copyWith(highlightedConnectionIds: {});
  }

  /// Mark connection as having an error
  ConnectionStateManager markConnectionError(String connectionId) {
    return copyWith(errorConnectionIds: {...errorConnectionIds, connectionId});
  }

  /// Clear error state for connection
  ConnectionStateManager clearConnectionError(String connectionId) {
    final updated = Set<String>.from(errorConnectionIds);
    updated.remove(connectionId);
    return copyWith(errorConnectionIds: updated);
  }

  /// Clear all error states
  ConnectionStateManager clearAllErrors() {
    return copyWith(errorConnectionIds: {});
  }
}
