import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

/// Represents different deletion gesture types
enum DeletionGestureType {
  doubleClick,
  hoverClick,
  tapConfirm,
}

/// Data for connection hover state
class ConnectionHoverData {
  final Connection connection;
  final bool isHovered;
  final Offset hoverPosition;

  const ConnectionHoverData({
    required this.connection,
    required this.isHovered,
    required this.hoverPosition,
  });
}

/// Service for handling connection deletion gestures
class ConnectionDeletionHandler {
  // Hover detection
  String? _hoveredConnectionId;
  Timer? _hoverTimer;
  bool _showDeleteIcon = false;
  Offset? _hoverPosition;
  
  // Double click detection
  String? _lastClickedConnectionId;
  DateTime? _lastClickTime;
  static const Duration _doubleClickTimeout = Duration(milliseconds: 500);
  
  // Tap confirmation state
  String? _pendingDeleteConnectionId;
  Timer? _confirmationTimer;
  static const Duration _confirmationTimeout = Duration(seconds: 3);

  // Callbacks
  final void Function(String connectionId)? onDeleteConnection;
  final void Function(String connectionId, bool isHovered, Offset position)? onHoverChanged;
  final void Function(String connectionId)? onShowDeleteConfirmation;
  final void Function()? onHideDeleteConfirmation;

  ConnectionDeletionHandler({
    this.onDeleteConnection,
    this.onHoverChanged,
    this.onShowDeleteConfirmation,
    this.onHideDeleteConfirmation,
  });

  /// Current hovered connection ID
  String? get hoveredConnectionId => _hoveredConnectionId;
  
  /// Whether delete icon should be shown
  bool get showDeleteIcon => _showDeleteIcon;
  
  /// Current hover position
  Offset? get hoverPosition => _hoverPosition;
  
  /// Pending delete connection ID (for confirmation dialog)
  String? get pendingDeleteConnectionId => _pendingDeleteConnectionId;

  /// Handle mouse hover over connection
  void handleConnectionHover(String connectionId, Offset position) {
    if (_hoveredConnectionId == connectionId) return;

    // Clear previous hover state
    _clearHoverState();

    _hoveredConnectionId = connectionId;
    _hoverPosition = position;
    
    // Start hover timer for delete icon display
    _hoverTimer = Timer(const Duration(milliseconds: 200), () {
      _showDeleteIcon = true;
      onHoverChanged?.call(connectionId, true, position);
    });
  }

  /// Handle mouse exit from connection
  void handleConnectionExit(String connectionId) {
    if (_hoveredConnectionId != connectionId) return;
    
    _clearHoverState();
    onHoverChanged?.call(connectionId, false, Offset.zero);
  }

  /// Handle click on connection (for double-click detection)
  void handleConnectionClick(String connectionId) {
    final now = DateTime.now();
    
    // Check for double-click
    if (_lastClickedConnectionId == connectionId &&
        _lastClickTime != null &&
        now.difference(_lastClickTime!) <= _doubleClickTimeout) {
      // Double-click detected - delete immediately
      _executeDelete(connectionId);
      _lastClickedConnectionId = null;
      _lastClickTime = null;
    } else {
      // Single click - store for double-click detection
      _lastClickedConnectionId = connectionId;
      _lastClickTime = now;
    }
  }

  /// Handle click on delete icon (mouse users)
  void handleDeleteIconClick(String connectionId) {
    _executeDelete(connectionId);
  }

  /// Handle tap on connection (for touch-friendly confirmation)
  void handleConnectionTap(String connectionId) {
    // Show confirmation dialog for touch users
    _showDeleteConfirmation(connectionId);
  }

  /// Confirm pending deletion
  void confirmDeletion() {
    if (_pendingDeleteConnectionId != null) {
      _executeDelete(_pendingDeleteConnectionId!);
      _cancelDeleteConfirmation();
    }
  }

  /// Cancel pending deletion
  void cancelDeletion() {
    _cancelDeleteConfirmation();
  }

  /// Execute the actual deletion
  void _executeDelete(String connectionId) {
    _clearHoverState();
    _cancelDeleteConfirmation();
    onDeleteConnection?.call(connectionId);
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(String connectionId) {
    _cancelDeleteConfirmation(); // Cancel any existing confirmation
    
    _pendingDeleteConnectionId = connectionId;
    onShowDeleteConfirmation?.call(connectionId);
    
    // Auto-hide confirmation after timeout
    _confirmationTimer = Timer(_confirmationTimeout, () {
      _cancelDeleteConfirmation();
    });
  }

  /// Cancel delete confirmation
  void _cancelDeleteConfirmation() {
    _confirmationTimer?.cancel();
    _confirmationTimer = null;
    
    if (_pendingDeleteConnectionId != null) {
      _pendingDeleteConnectionId = null;
      onHideDeleteConfirmation?.call();
    }
  }

  /// Clear hover state
  void _clearHoverState() {
    _hoverTimer?.cancel();
    _hoverTimer = null;
    _hoveredConnectionId = null;
    _hoverPosition = null;
    _showDeleteIcon = false;
  }

  /// Check if connection should show hover effects
  bool shouldShowHoverEffects(String connectionId) {
    return _hoveredConnectionId == connectionId && _showDeleteIcon;
  }

  /// Get hover data for a connection
  ConnectionHoverData? getHoverData(String connectionId) {
    if (_hoveredConnectionId == connectionId && _showDeleteIcon && _hoverPosition != null) {
      // This would need the actual Connection object - simplified for now
      return ConnectionHoverData(
        connection: Connection(
          id: connectionId,
          sourcePortId: '',
          destinationPortId: '',
          connectionType: ConnectionType.algorithmToAlgorithm,
        ),
        isHovered: true,
        hoverPosition: _hoverPosition!,
      );
    }
    return null;
  }

  /// Calculate connection thickness with hover effect
  double getConnectionThickness(String connectionId, double baseThickness) {
    if (shouldShowHoverEffects(connectionId)) {
      return baseThickness * 1.1; // 10% increase for hover
    }
    return baseThickness;
  }

  /// Get connection color with hover effect
  Color getConnectionColor(String connectionId, Color baseColor) {
    if (shouldShowHoverEffects(connectionId)) {
      return baseColor.withValues(alpha: 0.8); // Slightly transparent on hover
    }
    return baseColor;
  }

  /// Cleanup resources
  void dispose() {
    _hoverTimer?.cancel();
    _confirmationTimer?.cancel();
  }
}