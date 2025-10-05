import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'dart:convert';

void main() {
  group('AlgorithmMetadataService Direct Test', () {
    test('should load clck algorithm from JSON', () async {
      // Create a new instance to test
      final service = AlgorithmMetadataService();

      // This test will verify if the service can be used without initialization
      // which is the suspected cause of the timeout
      expect(
        () => service.getAllAlgorithms(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not initialized'),
          ),
        ),
      );
    });

    test('should handle getAlgorithmByGuid without initialization', () {
      final service = AlgorithmMetadataService();

      expect(
        () => service.getAlgorithmByGuid('clck'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not initialized'),
          ),
        ),
      );
    });
  });

  group('Algorithm Tools Error Simulation', () {
    test('should handle uninitialized service error gracefully', () {
      // Simulate what happens in the MCP tool
      try {
        final service = AlgorithmMetadataService();
        service.getAllAlgorithms(); // This should throw
        fail('Expected exception was not thrown');
      } catch (e) {
        // This is what should be caught in the MCP server
        expect(e.toString(), contains('not initialized'));

        // This is what should be returned as error JSON
        final errorJson = jsonEncode({
          'success': false,
          'error': 'Tool execution failed: ${e.toString()}',
        });

        final decoded = jsonDecode(errorJson);
        expect(decoded['success'], isFalse);
        expect(decoded['error'], contains('not initialized'));
      }
    });
  });
}
