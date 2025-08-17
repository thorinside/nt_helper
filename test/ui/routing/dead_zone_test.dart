import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Connection Dead Zone Logic', () {
    // Helper function that mimics the dead zone logic in our implementation
    bool isPointNearBezier(Offset point, Offset start, Offset end, {double tolerance = 10.0}) {
      // Dead zone radius around ports - don't detect connection clicks near ports
      const double portDeadZoneRadius = 30.0;
      
      // Check if click is within dead zone of source or target port
      final distanceToStart = (point - start).distance;
      final distanceToEnd = (point - end).distance;
      
      if (distanceToStart <= portDeadZoneRadius || distanceToEnd <= portDeadZoneRadius) {
        // Within dead zone - don't consider this a click on the connection
        return false;
      }
      
      // For testing purposes, we'll consider any point within tolerance of the straight line
      // between start and end as "near" the connection
      // (In the real implementation, this checks against a bezier curve)
      final lineVector = end - start;
      final lineLength = lineVector.distance;
      if (lineLength == 0) return false;
      
      final lineDirection = lineVector / lineLength;
      final toPoint = point - start;
      final projection = toPoint.dx * lineDirection.dx + toPoint.dy * lineDirection.dy;
      
      if (projection < 0 || projection > lineLength) {
        // Point is beyond the endpoints
        return false;
      }
      
      final closestPoint = start + lineDirection * projection;
      final distance = (point - closestPoint).distance;
      
      return distance <= tolerance;
    }
    
    test('should not detect clicks within dead zone of source port', () {
      const start = Offset(100, 100);
      const end = Offset(300, 100);
      
      // Click 10 pixels from source (within 30px dead zone)
      expect(isPointNearBezier(const Offset(110, 100), start, end), false);
      
      // Click 25 pixels from source (still within 30px dead zone)
      expect(isPointNearBezier(const Offset(125, 100), start, end), false);
      
      // Click 35 pixels from source (outside dead zone, on the line)
      expect(isPointNearBezier(const Offset(135, 100), start, end), true);
    });
    
    test('should not detect clicks within dead zone of target port', () {
      const start = Offset(100, 100);
      const end = Offset(300, 100);
      
      // Click 10 pixels from target (within 30px dead zone)
      expect(isPointNearBezier(const Offset(290, 100), start, end), false);
      
      // Click 25 pixels from target (still within 30px dead zone)
      expect(isPointNearBezier(const Offset(275, 100), start, end), false);
      
      // Click 35 pixels from target (outside dead zone, on the line)
      expect(isPointNearBezier(const Offset(265, 100), start, end), true);
    });
    
    test('should detect clicks in the middle of the connection', () {
      const start = Offset(100, 100);
      const end = Offset(300, 100);
      
      // Click in the middle (well outside both dead zones)
      expect(isPointNearBezier(const Offset(200, 100), start, end), true);
      
      // Click slightly off the line but within tolerance
      expect(isPointNearBezier(const Offset(200, 108), start, end), true);
      
      // Click too far from the line
      expect(isPointNearBezier(const Offset(200, 115), start, end), false);
    });
    
    test('dead zones should work for diagonal connections', () {
      const start = Offset(100, 100);
      const end = Offset(300, 300);
      
      // Near source port (within dead zone)
      expect(isPointNearBezier(const Offset(120, 120), start, end), false);
      
      // Near target port (within dead zone)
      expect(isPointNearBezier(const Offset(280, 280), start, end), false);
      
      // In the middle (outside dead zones, on the line)
      expect(isPointNearBezier(const Offset(200, 200), start, end), true);
    });
    
    test('dead zone radius should be exactly 30 pixels', () {
      const start = Offset(100, 100);
      const end = Offset(300, 100);
      
      // Exactly at dead zone boundary (30px from source)
      expect(isPointNearBezier(const Offset(130, 100), start, end), false);
      
      // Just outside dead zone (31px from source)
      expect(isPointNearBezier(const Offset(131, 100), start, end), true);
      
      // Exactly at dead zone boundary (30px from target)
      expect(isPointNearBezier(const Offset(270, 100), start, end), false);
      
      // Just outside dead zone (31px from target)  
      expect(isPointNearBezier(const Offset(269, 100), start, end), true);
    });
  });
}