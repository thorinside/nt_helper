import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';
import 'package:nt_helper/ui/widgets/routing/bus_label_formatter.dart';
import 'dart:ui' as ui;

void main() {
  group('ConnectionPainter Label Rendering', () {
    group('calculateBezierMidpoint', () {
      test('should find midpoint of straight horizontal line', () {
        final start = const Offset(0, 100);
        final end = const Offset(200, 100);
        
        final midpoint = ConnectionPainter.calculateBezierMidpoint(start, end);
        
        expect(midpoint.dx, 100);
        expect(midpoint.dy, 100);
      });

      test('should find midpoint of straight vertical line', () {
        final start = const Offset(100, 0);
        final end = const Offset(100, 200);
        
        final midpoint = ConnectionPainter.calculateBezierMidpoint(start, end);
        
        expect(midpoint.dx, 100);
        expect(midpoint.dy, 100);
      });

      test('should find midpoint of diagonal line', () {
        final start = const Offset(0, 0);
        final end = const Offset(200, 200);
        
        final midpoint = ConnectionPainter.calculateBezierMidpoint(start, end);
        
        expect(midpoint.dx, closeTo(100, 0.01));
        expect(midpoint.dy, closeTo(100, 0.01));
      });

      test('should find midpoint of curved Bezier path', () {
        final start = const Offset(0, 100);
        final end = const Offset(200, 100);
        // For a horizontal line, the Bezier curve will have control points
        // that create a curve, but the midpoint should still be calculable
        
        final midpoint = ConnectionPainter.calculateBezierMidpoint(start, end);
        
        // The exact midpoint depends on the control points
        // But it should be somewhere between start and end
        expect(midpoint.dx, greaterThanOrEqualTo(0));
        expect(midpoint.dx, lessThanOrEqualTo(200));
        expect(midpoint.dy, greaterThanOrEqualTo(50)); // Allow for curve
        expect(midpoint.dy, lessThanOrEqualTo(150));
      });
    });

    group('calculateLabelAngle', () {
      test('should calculate 0 degrees for horizontal line left to right', () {
        final start = const Offset(0, 100);
        final end = const Offset(200, 100);
        
        final angle = ConnectionPainter.calculateLabelAngle(start, end);
        
        expect(angle, closeTo(0, 0.01));
      });

      test('should calculate 180 degrees for horizontal line right to left', () {
        final start = const Offset(200, 100);
        final end = const Offset(0, 100);
        
        final angle = ConnectionPainter.calculateLabelAngle(start, end);
        
        expect(angle, closeTo(3.14159, 0.01)); // π radians
      });

      test('should calculate 90 degrees for vertical line top to bottom', () {
        final start = const Offset(100, 0);
        final end = const Offset(100, 200);
        
        final angle = ConnectionPainter.calculateLabelAngle(start, end);
        
        expect(angle, closeTo(1.5708, 0.01)); // π/2 radians
      });

      test('should calculate 45 degrees for diagonal line', () {
        final start = const Offset(0, 0);
        final end = const Offset(100, 100);
        
        final angle = ConnectionPainter.calculateLabelAngle(start, end);
        
        expect(angle, closeTo(0.7854, 0.01)); // π/4 radians
      });
    });

    group('formatBusLabel', () {
      test('should format input bus numbers correctly', () {
        expect(ConnectionPainter.formatBusLabel(1), 'I1');
        expect(ConnectionPainter.formatBusLabel(6), 'I6');
        expect(ConnectionPainter.formatBusLabel(12), 'I12');
      });

      test('should format output bus numbers correctly', () {
        expect(ConnectionPainter.formatBusLabel(13), 'O1');
        expect(ConnectionPainter.formatBusLabel(16), 'O4');
        expect(ConnectionPainter.formatBusLabel(20), 'O8');
      });

      test('should format auxiliary bus numbers correctly', () {
        expect(ConnectionPainter.formatBusLabel(21), 'A1');
        expect(ConnectionPainter.formatBusLabel(24), 'A4');
        expect(ConnectionPainter.formatBusLabel(28), 'A8');
      });

      test('should return empty string for invalid bus numbers', () {
        expect(ConnectionPainter.formatBusLabel(null), '');
        expect(ConnectionPainter.formatBusLabel(0), '');
        expect(ConnectionPainter.formatBusLabel(29), '');
      });
    });

    group('Label Text Painting', () {
      late Canvas canvas;
      late ui.PictureRecorder recorder;
      late Size canvasSize;

      setUp(() {
        recorder = ui.PictureRecorder();
        canvas = Canvas(recorder);
        canvasSize = const Size(800, 600);
      });

      test('should create text painter with correct style', () {
        final textPainter = ConnectionPainter.createLabelTextPainter(
          'I1',
          const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        );

        expect(textPainter.text, isA<TextSpan>());
        final textSpan = textPainter.text as TextSpan;
        expect(textSpan.text, 'I1');
        expect(textSpan.style?.fontSize, 11);
        expect(textSpan.style?.fontWeight, FontWeight.w500);
        expect(textSpan.style?.color, Colors.black87);
      });

      test('should layout text with proper dimensions', () {
        final textPainter = ConnectionPainter.createLabelTextPainter(
          'O12',
          const TextStyle(fontSize: 11),
        );

        textPainter.layout();

        expect(textPainter.width, greaterThan(0));
        expect(textPainter.height, greaterThan(0));
        // O12 should be wider than a single character
        expect(textPainter.width, greaterThan(15));
      });
    });
  });
}