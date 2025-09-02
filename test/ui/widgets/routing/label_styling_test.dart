import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';

void main() {
  group('Label Styling and Visibility', () {
    group('Text Style Configuration', () {
      test('should create text painter with proper font size', () {
        final textPainter = ConnectionPainter.createLabelTextPainter(
          'I5',
          const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        );

        textPainter.layout();
        
        // Check text properties
        expect(textPainter.text, isA<TextSpan>());
        final textSpan = textPainter.text as TextSpan;
        expect(textSpan.text, 'I5');
        expect(textSpan.style?.fontSize, 11);
        expect(textSpan.style?.fontWeight, FontWeight.w500);
        expect(textSpan.style?.color, Colors.black87);
      });

      test('should support different font weights', () {
        final weights = [
          FontWeight.w400,
          FontWeight.w500,
          FontWeight.w600,
          FontWeight.bold,
        ];

        for (final weight in weights) {
          final textPainter = ConnectionPainter.createLabelTextPainter(
            'O3',
            TextStyle(
              fontSize: 11,
              fontWeight: weight,
            ),
          );

          textPainter.layout();
          final textSpan = textPainter.text as TextSpan;
          expect(textSpan.style?.fontWeight, weight);
        }
      });

      test('should layout text with appropriate dimensions', () {
        final testCases = [
          ('I1', 11.0, 15.0, 25.0),  // Min width, max width expectations
          ('I12', 11.0, 20.0, 35.0),
          ('O8', 11.0, 18.0, 30.0),
          ('A5', 11.0, 18.0, 30.0),
        ];

        for (final testCase in testCases) {
          final label = testCase.$1;
          final fontSize = testCase.$2;
          final minWidth = testCase.$3;
          final maxWidth = testCase.$4;

          final textPainter = ConnectionPainter.createLabelTextPainter(
            label,
            TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
          );

          textPainter.layout();

          // Check dimensions are reasonable
          expect(textPainter.width, greaterThanOrEqualTo(minWidth));
          expect(textPainter.width, lessThanOrEqualTo(maxWidth));
          expect(textPainter.height, greaterThan(0));
          expect(textPainter.height, lessThan(20)); // Reasonable height for 11pt font
        }
      });
    });

    group('Label Contrast and Visibility', () {
      test('should provide adequate contrast between label and background', () {
        // Test label text color options for different backgrounds
        final lightTheme = ThemeData.light();
        final darkTheme = ThemeData.dark();

        // Light theme - dark text on light background
        final lightTextStyle = lightTheme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        );
        expect(lightTextStyle?.color?.value, isNotNull);
        
        // Dark theme - light text on dark background
        final darkTextStyle = darkTheme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        );
        expect(darkTextStyle?.color?.value, isNotNull);
        
        // Colors should be different for different themes
        expect(lightTextStyle?.color, isNot(equals(darkTextStyle?.color)));
      });

      test('should use semi-transparent background for labels', () {
        final lightTheme = ThemeData.light();
        final backgroundColorLight = lightTheme.cardColor.withValues(alpha: 0.9);
        
        // Check alpha channel for semi-transparency
        expect(backgroundColorLight.a, closeTo(0.9, 0.01));
        
        final darkTheme = ThemeData.dark();
        final backgroundColorDark = darkTheme.cardColor.withValues(alpha: 0.9);
        
        // Check alpha channel for semi-transparency
        expect(backgroundColorDark.a, closeTo(0.9, 0.01));
      });
    });

    group('Performance with Multiple Connections', () {
      test('should handle formatting many bus labels efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Format 1000 bus labels
        for (int i = 0; i < 1000; i++) {
          final busNumber = (i % 28) + 1;
          ConnectionPainter.formatBusLabel(busNumber);
        }
        
        stopwatch.stop();
        
        // Should complete in reasonable time (less than 100ms for 1000 labels)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should create text painters efficiently', () {
        final stopwatch = Stopwatch()..start();
        final style = const TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
        
        // Create and layout 100 text painters
        for (int i = 0; i < 100; i++) {
          final label = 'I${(i % 12) + 1}';
          final textPainter = ConnectionPainter.createLabelTextPainter(label, style);
          textPainter.layout();
        }
        
        stopwatch.stop();
        
        // Should complete in reasonable time (less than 100ms for 100 painters)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Label Formatting Edge Cases', () {
      test('should handle all valid bus ranges correctly', () {
        // Test boundary values
        expect(ConnectionPainter.formatBusLabel(1), 'I1');
        expect(ConnectionPainter.formatBusLabel(12), 'I12');
        expect(ConnectionPainter.formatBusLabel(13), 'O1');
        expect(ConnectionPainter.formatBusLabel(20), 'O8');
        expect(ConnectionPainter.formatBusLabel(21), 'A1');
        expect(ConnectionPainter.formatBusLabel(28), 'A8');
      });

      test('should handle invalid bus numbers gracefully', () {
        expect(ConnectionPainter.formatBusLabel(0), '');
        expect(ConnectionPainter.formatBusLabel(-1), '');
        expect(ConnectionPainter.formatBusLabel(29), '');
        expect(ConnectionPainter.formatBusLabel(100), '');
        expect(ConnectionPainter.formatBusLabel(null), '');
      });
    });
  });
}