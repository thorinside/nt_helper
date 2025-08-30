import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/routing_service_locator.dart';
import 'package:nt_helper/services/haptic_feedback_service.dart';
import 'jack_painter.dart';

/// A custom Flutter widget that visually represents a 1/8" Eurorack jack socket
/// with interactive capabilities for the routing visualization system.
///
/// This widget provides tactile feedback, drag-and-drop functionality, and clear 
/// visual distinction between different signal types. It accepts a [Port] instance
/// and renders it as an interactive jack socket following Material 3 design principles.
///
/// ## Features
/// - Visual representation of 1/8" Eurorack jack socket
/// - Color coding based on port type (audio, CV, gate, clock)
/// - Hover and selection state management
/// - Drag gesture support for connection creation
/// - Material 3 theme integration
/// - Accessibility support
///
/// ## Usage
/// ```dart
/// JackConnectionWidget(
///   port: audioInputPort,
///   onTap: () => handlePortTap(),
///   onDragStart: () => beginConnection(),
///   onDragEnd: (offset) => completeConnection(offset),
/// )
/// ```
class JackConnectionWidget extends StatefulWidget {
  /// The port data model containing name, type, direction, and constraints
  final Port port;
  
  /// Callback invoked when the jack is tapped
  final VoidCallback? onTap;
  
  /// Callback invoked when a drag gesture starts from this jack
  final VoidCallback? onDragStart;
  
  /// Callback invoked during drag gesture with current position
  final ValueChanged<Offset>? onDragUpdate;
  
  /// Callback invoked when drag gesture ends with final position
  final ValueChanged<Offset>? onDragEnd;
  
  /// External control of hover state (optional, widget manages internally if null)
  final bool? isHovered;
  
  /// External control of selection state (optional, widget manages internally if null)
  final bool? isSelected;
  
  /// Whether this jack is currently connected to another jack
  final bool isConnected;
  
  /// Whether this jack is part of a ghost connection
  final bool isGhostConnection;
  
  /// Optional custom width for the widget (defaults to 120dp)
  final double? customWidth;
  
  /// Custom focus node for keyboard navigation (optional)
  final FocusNode? focusNode;
  
  /// Whether this jack can receive keyboard focus
  final bool canRequestFocus;
  
  /// Whether to provide haptic feedback on interactions
  final bool enableHapticFeedback;

  const JackConnectionWidget({
    super.key,
    required this.port,
    this.onTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.isHovered,
    this.isSelected,
    this.isConnected = false,
    this.isGhostConnection = false,
    this.customWidth,
    this.focusNode,
    this.canRequestFocus = true,
    this.enableHapticFeedback = true,
  });

  @override
  State<JackConnectionWidget> createState() => _JackConnectionWidgetState();
}

/// State class for [JackConnectionWidget] managing hover and selection states
class _JackConnectionWidgetState extends State<JackConnectionWidget> 
    with SingleTickerProviderStateMixin {
  /// Internal hover state, used when widget.isHovered is null
  bool _internalHovered = false;
  
  /// Internal selection state, used when widget.isSelected is null
  bool _internalSelected = false;
  
  /// Animation controller for hover effects
  late AnimationController _hoverAnimationController;
  
  /// Scale animation for hover effect
  late Animation<double> _scaleAnimation;
  
  /// Focus node for keyboard navigation
  late FocusNode _focusNode;
  
  /// Haptic feedback service
  late IHapticFeedbackService _hapticFeedback;
  
  /// Whether to use internal focus node
  bool get _useInternalFocusNode => widget.focusNode == null;
  
  /// Gets the effective hover state (external or internal)
  bool get isHovered => widget.isHovered ?? _internalHovered;
  
  /// Gets the effective selection state (external or internal)
  bool get isSelected => widget.isSelected ?? _internalSelected;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize haptic feedback service
    _hapticFeedback = RoutingServiceLocator.hapticFeedbackService;
    
    // Initialize focus node
    if (_useInternalFocusNode) {
      _focusNode = FocusNode();
    } else {
      _focusNode = widget.focusNode!;
    }
    
    _hoverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _hoverAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    if (_useInternalFocusNode) {
      _focusNode.dispose();
    }
    _hoverAnimationController.dispose();
    super.dispose();
  }
  
  /// Updates the internal hover state
  void setHovered(bool value) {
    if (widget.isHovered == null && _internalHovered != value) {
      setState(() {
        _internalHovered = value;
      });
      if (value) {
        _hoverAnimationController.forward();
      } else {
        _hoverAnimationController.reverse();
      }
    }
  }
  
  /// Updates the internal selection state
  void setSelected(bool value) {
    if (widget.isSelected == null && _internalSelected != value) {
      setState(() {
        _internalSelected = value;
      });
    }
  }
  
  /// Provides haptic feedback for interactions
  void _triggerHapticFeedback() {
    if (widget.enableHapticFeedback) {
      _hapticFeedback.lightImpact(context);
    }
  }
  
  /// Handles keyboard interactions
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent keyEvent) {
    if (keyEvent is KeyDownEvent) {
      // Handle Enter and Space for activation
      if (keyEvent.logicalKey == LogicalKeyboardKey.enter ||
          keyEvent.logicalKey == LogicalKeyboardKey.space) {
        // Provide haptic feedback
        _triggerHapticFeedback();
        
        // Toggle selection if managed internally
        if (widget.isSelected == null) {
          setSelected(!_internalSelected);
        }
        // Execute tap callback
        widget.onTap?.call();
        return KeyEventResult.handled;
      }
      
      // Handle drag start with D key (for keyboard users)
      if (keyEvent.logicalKey == LogicalKeyboardKey.keyD) {
        // Provide haptic feedback for drag start
        _triggerHapticFeedback();
        
        widget.onDragStart?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Build semantic label
    final portType = widget.port.type.name;
    final portDirection = widget.port.direction == PortDirection.input ? 'input' : 
                         widget.port.direction == PortDirection.output ? 'output' : 'bidirectional';
    final connectionState = widget.isConnected ? 'connected' : 'not connected';
    
    return Semantics(
      label: '${widget.port.name} - $portType $portDirection jack, $connectionState',
      hint: 'Tap to select, use D key to start drag connection, Space or Enter to activate',
      button: true,
      enabled: true,
      selected: isSelected,
      focused: _focusNode.hasFocus,
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: widget.canRequestFocus,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          onEnter: (_) => setHovered(true),
          onExit: (_) => setHovered(false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              // Provide haptic feedback
              _triggerHapticFeedback();
              
              // Request focus on tap
              if (widget.canRequestFocus) {
                _focusNode.requestFocus();
              }
              
              // Toggle selection if managed internally
              if (widget.isSelected == null) {
                setSelected(!_internalSelected);
              }
              // Execute tap callback
              widget.onTap?.call();
            },
        onPanStart: (details) {
          // Only trigger drag from the jack area
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          final widgetWidth = widget.customWidth ?? 120;
          
          // Determine jack position based on port direction
          final isInput = widget.port.direction == PortDirection.input || 
                         widget.port.direction == PortDirection.bidirectional;
          
          bool inJackArea;
          if (isInput) {
            // Input jacks are on the left side (0 to 32px)
            inJackArea = localPosition.dx <= 32;
          } else {
            // Output jacks are on the right side (width-32 to width)
            inJackArea = localPosition.dx >= widgetWidth - 32;
          }
          
          if (inJackArea) {
            // Provide haptic feedback for drag start
            _triggerHapticFeedback();
            
            widget.onDragStart?.call();
          }
        },
        onPanUpdate: (details) {
          widget.onDragUpdate?.call(details.globalPosition);
        },
        onPanEnd: (details) {
          widget.onDragEnd?.call(details.velocity.pixelsPerSecond);
        },
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return SizedBox(
                  width: widget.customWidth ?? 120,
                  height: 32,
                  child: Stack(
                    children: [
                      // Main jack visualization
                      CustomPaint(
                        painter: JackPainter(
                          port: widget.port,
                          isHovered: isHovered || _focusNode.hasFocus, // Show hover effect when focused
                          isSelected: isSelected,
                          isConnected: widget.isConnected,
                          colorScheme: colorScheme,
                          hoverAnimation: _scaleAnimation.value,
                        ),
                        child: Container(), // Empty container for hit testing
                      ),
                      // Ghost connection overlay
                      if (widget.isGhostConnection)
                        _buildGhostOverlay(colorScheme),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Build ghost connection overlay with animated icon
  Widget _buildGhostOverlay(ColorScheme colorScheme) {
    return Positioned(
      right: 4,
      top: 2,
      child: AnimatedBuilder(
        animation: _hoverAnimationController,
        builder: (context, child) {
          // Create a subtle floating animation
          final floatOffset = Tween<double>(begin: 0.0, end: 2.0).animate(
            CurvedAnimation(
              parent: _hoverAnimationController,
              curve: Curves.easeInOut,
            ),
          );
          
          return Transform.translate(
            offset: Offset(0, floatOffset.value * (isHovered ? 1.0 : 0.5)),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 10,
                color: colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          );
        },
      ),
    );
  }
}