import 'package:flutter/material.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/accessibility_colors.dart';

/// CustomPainter implementation for rendering a 1/8" Eurorack jack socket.
///
/// This painter creates a realistic jack socket visualization with:
/// - Outer ring representing the threaded socket body
/// - Inner circle with gradient for depth perception
/// - Center hole simulating the actual jack opening
/// - Color bar indicating the signal type
/// 
/// The design follows Material 3 principles and adapts to theme changes.
class JackPainter extends CustomPainter {
  /// The port data model containing type information for color coding
  final Port port;
  
  /// Whether the jack is currently being hovered over
  final bool isHovered;
  
  /// Whether the jack is currently selected
  final bool isSelected;
  
  /// Whether the jack is currently connected to another jack
  final bool isConnected;
  
  /// The color scheme for Material 3 theming
  final ColorScheme colorScheme;
  
  /// Accessible colors for proper contrast ratios
  final AccessibleRoutingColors? accessibleColors;
  
  /// Optional animation value for hover effects (0.0 to 1.0)
  final double? hoverAnimation;

  JackPainter({
    required this.port,
    required this.isHovered,
    required this.isSelected,
    required this.isConnected,
    required this.colorScheme,
    this.accessibleColors,
    this.hoverAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate dimensions
    final jackDiameter = 24.0;
    final jackRadius = jackDiameter / 2;
    
    // Position jack based on port direction
    // Input ports: jack on left, label on right
    // Output ports: jack on right, label on left  
    final isInput = port.direction == PortDirection.input || port.direction == PortDirection.bidirectional;
    final jackCenter = isInput 
        ? Offset(jackRadius + 4, size.height / 2)  // Jack on left for inputs
        : Offset(size.width - jackRadius - 4, size.height / 2); // Jack on right for outputs
    
    // Color bar dimensions and position
    final colorBarHeight = 14.0;
    final colorBarWidth = size.width - jackDiameter - 16;
    final colorBarRect = isInput
        ? RRect.fromRectAndRadius(  // Bar extends right from jack for inputs
            Rect.fromLTWH(
              jackDiameter / 2, 
              (size.height - colorBarHeight) / 2,
              colorBarWidth,
              colorBarHeight,
            ),
            const Radius.circular(7),
          )
        : RRect.fromRectAndRadius(  // Bar extends left from jack for outputs
            Rect.fromLTWH(
              0, 
              (size.height - colorBarHeight) / 2,
              colorBarWidth,
              colorBarHeight,
            ),
            const Radius.circular(7),
          );
    
    // Draw color bar behind the jack
    _drawColorBar(canvas, colorBarRect);
    
    // Draw the jack socket
    _drawJackSocket(canvas, jackCenter, jackRadius);
    
    // Draw selection indicator if selected
    if (isSelected) {
      _drawSelectionIndicator(canvas, jackCenter, jackRadius);
    }
    
    // Draw text label
    _drawLabel(canvas, size, jackCenter, jackRadius, colorBarWidth - 8);
  }
  
  /// Draws the colored bar indicating the port type
  void _drawColorBar(Canvas canvas, RRect rect) {
    final paint = Paint()
      ..color = _getPortColor()
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(rect, paint);
    
    // Add subtle gradient overlay for depth
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.black.withValues(alpha: 0.1),
        ],
      ).createShader(rect.outerRect)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(rect, gradientPaint);
  }
  
  /// Draws the main jack socket with realistic appearance
  void _drawJackSocket(Canvas canvas, Offset center, double radius) {
    final hoverScale = hoverAnimation ?? (isHovered ? 1.0 : 0.0);
    final scaledRadius = radius * (1.0 + hoverScale * 0.1);
    
    // Outer socket ring (metallic appearance)
    final outerSocketPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, scaledRadius, outerSocketPaint);
    
    // Inner socket with metallic gradient
    final socketGradient = RadialGradient(
      center: const Alignment(-0.2, -0.2),
      radius: 1.2,
      colors: [
        Colors.grey.shade300,
        Colors.grey.shade700,
        Colors.grey.shade800,
      ],
      stops: const [0.0, 0.7, 1.0],
    );
    
    final socketPaint = Paint()
      ..shader = socketGradient.createShader(
        Rect.fromCircle(center: center, radius: scaledRadius * 0.9),
      )
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, scaledRadius * 0.9, socketPaint);
    
    // Threaded appearance (multiple rings)
    for (int i = 0; i < 3; i++) {
      final ringRadius = scaledRadius * (0.8 - i * 0.1);
      final ringPaint = Paint()
        ..color = Colors.grey.shade500.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      
      canvas.drawCircle(center, ringRadius, ringPaint);
    }
    
    // Center hole (jack opening) - larger and more pronounced
    final holePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, scaledRadius * 0.4, holePaint);
    
    // Inner hole shadow for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(center, scaledRadius * 0.35, shadowPaint);
    
    // Connection indicator in center hole
    if (isConnected) {
      final connectedPaint = Paint()
        ..color = _getPortColor()
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(center, scaledRadius * 0.25, connectedPaint);
    }
  }
  
  /// Draws a glowing selection indicator around the jack
  void _drawSelectionIndicator(Canvas canvas, Offset center, double radius) {
    final selectionPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
    
    canvas.drawCircle(center, radius + 4, selectionPaint);
  }
  
  /// Draws the port name label positioned based on port direction
  void _drawLabel(Canvas canvas, Size size, Offset jackCenter, double jackRadius, double maxWidth) {
    final isInput = port.direction == PortDirection.input || port.direction == PortDirection.bidirectional;
    
    final textSpan = TextSpan(
      text: port.name,
      style: TextStyle(
        color: isHovered 
            ? colorScheme.onSurface 
            : colorScheme.onSurfaceVariant,
        fontSize: 16, // Increased from 14 for better readability
        fontWeight: FontWeight.w600, // Bolder text
        fontFamily: 'Roboto', // Explicit font for consistency
      ),
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: isInput ? TextAlign.left : TextAlign.right,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
      textScaler: TextScaler.noScaling, // Prevent system text scaling from affecting readability
    );
    
    textPainter.layout(maxWidth: maxWidth);
    
    final textOffset = isInput
        ? Offset(  // Input: label to the right of jack
            jackCenter.dx + jackRadius + 8,
            (size.height - textPainter.height) / 2,
          )
        : Offset(  // Output: label to the left of jack
            jackCenter.dx - jackRadius - textPainter.width - 8,
            (size.height - textPainter.height) / 2,
          );
    
    textPainter.paint(canvas, textOffset);
  }
  
  /// Gets the appropriate color for the port based on its type
  Color _getPortColor() {
    // Use accessible colors if provided, otherwise fallback to color scheme
    final colors = accessibleColors;
    
    if (colors != null) {
      switch (port.type) {
        case PortType.audio:
          return colors.audioPortColor;
        case PortType.cv:
          return colors.cvPortColor;
        case PortType.gate:
          return colors.gatePortColor;
        case PortType.clock:
          return colors.clockPortColor;
      }
    } else {
      // Fallback with enhanced contrast
      switch (port.type) {
        case PortType.audio:
          return AccessibilityColors.ensureContrast(colorScheme.primary, colorScheme.surface);
        case PortType.cv:
          return AccessibilityColors.ensureContrast(colorScheme.tertiary, colorScheme.surface);
        case PortType.gate:
          return AccessibilityColors.ensureContrast(colorScheme.error, colorScheme.surface);
        case PortType.clock:
          return AccessibilityColors.ensureContrast(colorScheme.secondary, colorScheme.surface);
      }
    }
  }

  @override
  bool shouldRepaint(JackPainter oldDelegate) {
    return oldDelegate.port != port ||
           oldDelegate.isHovered != isHovered ||
           oldDelegate.isSelected != isSelected ||
           oldDelegate.isConnected != isConnected ||
           oldDelegate.colorScheme != colorScheme ||
           oldDelegate.hoverAnimation != hoverAnimation;
  }
  
  @override
  bool shouldRebuildSemantics(JackPainter oldDelegate) => false;
}