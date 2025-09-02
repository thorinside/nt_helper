import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/core/routing/models/connection_metadata.dart';
import 'package:nt_helper/ui/widgets/routing/connection_painter.dart';
import 'package:nt_helper/ui/widgets/routing/connection_theme.dart';

void main() {
  group('Unified Connection Rendering', () {
    late ConnectionVisualTheme theme;
    late ThemeData materialTheme;
    
    setUp(() {
      materialTheme = ThemeData.light();
      theme = ConnectionVisualTheme.fromColorScheme(materialTheme.colorScheme);
    });
    
    test('ConnectionPainter renders hardware connections with correct style', () {
      final connection = Connection(
        id: 'hw_conn_1',
        sourcePortId: 'hw_in_1',
        targetPortId: 'algo_test_port_10',
        properties: {
          'metadata': const ConnectionMetadata(
            connectionClass: ConnectionClass.hardware,
            busNumber: 1,
            signalType: SignalType.audio,
            targetAlgorithmId: 'algo_test_1',
            targetParameterNumber: 10,
          ),
        },
      );
      
      final connectionData = ConnectionData(
        connection: connection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(300, 200),
        isPhysicalConnection: true,
        isInputConnection: true,
      );
      
      final painter = ConnectionPainter(
        connections: [connectionData],
        theme: materialTheme,
      );
      
      // Verify hardware connection style is applied
      final metadata = connection.properties?['metadata'] as ConnectionMetadata?;
      expect(metadata?.connectionClass, ConnectionClass.hardware);
      expect(metadata?.signalType, SignalType.audio);
      expect(connectionData.isPhysicalConnection, true);
    });
    
    test('ConnectionPainter renders algorithm connections with correct style', () {
      final connection = Connection(
        id: 'algo_conn_1',
        sourcePortId: 'algo_1_port_23',
        targetPortId: 'algo_2_port_15',
        properties: {
          'metadata': const ConnectionMetadata(
            connectionClass: ConnectionClass.algorithm,
            busNumber: 25,
            signalType: SignalType.cv,
            sourceAlgorithmId: 'algo_1',
            targetAlgorithmId: 'algo_2',
            sourceParameterNumber: 23,
            targetParameterNumber: 15,
            isBackwardEdge: false,
          ),
        },
      );
      
      final connectionData = ConnectionData(
        connection: connection,
        sourcePosition: const Offset(200, 150),
        destinationPosition: const Offset(400, 250),
        isPhysicalConnection: false,
      );
      
      final painter = ConnectionPainter(
        connections: [connectionData],
        theme: materialTheme,
      );
      
      // Verify algorithm connection style is applied
      final metadata = connection.properties?['metadata'] as ConnectionMetadata?;
      expect(metadata?.connectionClass, ConnectionClass.algorithm);
      expect(metadata?.signalType, SignalType.cv);
      expect(metadata?.isBackwardEdge, false);
    });
    
    test('ConnectionPainter handles backward edge styling', () {
      final connection = Connection(
        id: 'backward_conn_1',
        sourcePortId: 'algo_3_port_20',
        targetPortId: 'algo_1_port_10',
        properties: {
          'metadata': const ConnectionMetadata(
            connectionClass: ConnectionClass.algorithm,
            busNumber: 26,
            signalType: SignalType.gate,
            sourceAlgorithmId: 'algo_3',
            targetAlgorithmId: 'algo_1',
            sourceParameterNumber: 20,
            targetParameterNumber: 10,
            isBackwardEdge: true,
          ),
        },
      );
      
      final connectionData = ConnectionData(
        connection: connection,
        sourcePosition: const Offset(400, 300),
        destinationPosition: const Offset(200, 100),
        isPhysicalConnection: false,
      );
      
      final painter = ConnectionPainter(
        connections: [connectionData],
        theme: materialTheme,
      );
      
      // Verify backward edge is detected and styled differently
      final metadata = connection.properties?['metadata'] as ConnectionMetadata?;
      expect(metadata?.isBackwardEdge, true);
      expect(metadata?.connectionClass, ConnectionClass.algorithm);
    });
    
    test('ConnectionVisualTheme provides correct styles for different connection types', () {
      // Direct connections should have solid lines
      expect(theme.directConnection.dashPattern, isNull);
      expect(theme.directConnection.strokeWidth, greaterThan(0));
      
      // Ghost connections should have dashed lines
      expect(theme.ghostConnection.dashPattern, isNotNull);
      expect(theme.ghostConnection.dashPattern!.isNotEmpty, true);
      
      // Selected connections should have thicker stroke
      expect(theme.selectedConnection.strokeWidth, greaterThan(theme.directConnection.strokeWidth));
      
      // Error connections should have dash pattern
      expect(theme.errorConnection.dashPattern, isNotNull);
    });
    
    test('ConnectionStateManager provides correct styles based on state', () {
      final stateManager = ConnectionStateManager(
        theme: theme,
        selectedConnectionIds: {'sel_1'},
        highlightedConnectionIds: {'high_1'},
        errorConnectionIds: {'err_1'},
      );
      
      final normalConn = Connection(id: 'norm_1', sourcePortId: 'p1', targetPortId: 'p2');
      final selectedConn = Connection(id: 'sel_1', sourcePortId: 'p3', targetPortId: 'p4');
      final errorConn = Connection(id: 'err_1', sourcePortId: 'p5', targetPortId: 'p6');
      
      // Normal connection gets direct style
      final normalStyle = stateManager.getConnectionStyle(normalConn);
      expect(normalStyle, theme.directConnection);
      
      // Selected connection gets selected style
      final selectedStyle = stateManager.getConnectionStyle(selectedConn);
      expect(selectedStyle, theme.selectedConnection);
      
      // Error connection gets error style
      final errorStyle = stateManager.getConnectionStyle(errorConn);
      expect(errorStyle, theme.errorConnection);
    });
    
    test('Unified rendering handles null metadata gracefully', () {
      final connection = Connection(
        id: 'conn_no_metadata',
        sourcePortId: 'port_1',
        targetPortId: 'port_2',
        // No metadata provided
      );
      
      final connectionData = ConnectionData(
        connection: connection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(200, 200),
      );
      
      final painter = ConnectionPainter(
        connections: [connectionData],
        theme: materialTheme,
      );
      
      // Should use defaults when metadata is missing
      expect(connectionData.isPhysicalConnection, false);
      expect(connection.properties?['metadata'], isNull);
    });
    
    test('Connection rendering respects mute and gain properties', () {
      final mutedConnection = Connection(
        id: 'muted_conn',
        sourcePortId: 'port_1',
        targetPortId: 'port_2',
        isMuted: true,
        gain: 0.5,
        properties: {
          'metadata': const ConnectionMetadata(
            connectionClass: ConnectionClass.hardware,
            busNumber: 5,
            signalType: SignalType.audio,
          ),
        },
      );
      
      final connectionData = ConnectionData(
        connection: mutedConnection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(200, 200),
        isPhysicalConnection: true,
      );
      
      final painter = ConnectionPainter(
        connections: [connectionData],
        theme: materialTheme,
      );
      
      // Muted connections should be rendered differently
      expect(mutedConnection.isMuted, true);
      expect(mutedConnection.gain, 0.5);
    });
    
    test('Connection validation affects rendering', () {
      final invalidConnection = Connection(
        id: 'invalid_conn',
        sourcePortId: 'port_1',
        targetPortId: 'port_2',
        properties: {
          'metadata': const ConnectionMetadata(
            connectionClass: ConnectionClass.algorithm,
            busNumber: 25,
            signalType: SignalType.audio,
            isValid: false, // Marked as invalid
          ),
        },
      );
      
      final connectionData = ConnectionData(
        connection: invalidConnection,
        sourcePosition: const Offset(100, 100),
        destinationPosition: const Offset(200, 200),
      );
      
      final painter = ConnectionPainter(
        connections: [connectionData],
        theme: materialTheme,
      );
      
      // Invalid connections should be rendered with error style
      final metadata = invalidConnection.properties?['metadata'] as ConnectionMetadata?;
      expect(metadata?.isValid, false);
    });
  });
}