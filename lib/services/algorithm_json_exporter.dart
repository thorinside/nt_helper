import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nt_helper/db/database.dart';

class AlgorithmJsonExporter {
  final AppDatabase database;

  AlgorithmJsonExporter(this.database);

  /// Exports all algorithm details with parameters to a JSON file
  Future<void> exportAlgorithmDetails(String filePath) async {
    try {
      debugPrint('Starting algorithm export to: $filePath');

      final dao = database.metadataDao;
      final algorithms = await dao.getAllAlgorithms();
      final List<Map<String, dynamic>> exportData = [];

      for (final algorithm in algorithms) {
        debugPrint(
            'Processing algorithm: ${algorithm.name} (${algorithm.guid})');

        // Get full details including parameters
        final details = await dao.getFullAlgorithmDetails(algorithm.guid);

        final Map<String, dynamic> algorithmData = {
          'guid': algorithm.guid,
          'name': algorithm.name,
          'numSpecifications': algorithm.numSpecifications,
          'pluginFilePath': algorithm.pluginFilePath,
          'parameters': <Map<String, dynamic>>[],
        };

        // Add parameters if they exist
        if (details?.parameters != null) {
          for (final paramWithUnit in details!.parameters) {
            final param = paramWithUnit.parameter;
            algorithmData['parameters'].add({
              'name': param.name,
              'parameterNumber': param.parameterNumber,
              'minValue': param.minValue,
              'maxValue': param.maxValue,
              'defaultValue': param.defaultValue,
              'unit': paramWithUnit.unitString,
              'pageName': paramWithUnit.pageName,
            });
          }
        }

        exportData.add(algorithmData);
      }

      // Sort algorithms by name for consistent output
      exportData
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      // Create the final export structure
      final Map<String, dynamic> exportJson = {
        'exportDate': DateTime.now().toIso8601String(),
        'totalAlgorithms': exportData.length,
        'algorithms': exportData,
      };

      // Write to file
      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportJson),
        encoding: utf8,
      );

      debugPrint(
          'Successfully exported ${exportData.length} algorithms to $filePath');
    } catch (e, stackTrace) {
      debugPrint('Error exporting algorithm details: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Gets a preview of the export data for display purposes
  Future<Map<String, dynamic>> getExportPreview() async {
    try {
      final dao = database.metadataDao;
      final algorithms = await dao.getAllAlgorithms();

      int totalParameters = 0;
      final List<String> sampleAlgorithms = [];

      for (int i = 0; i < algorithms.length && i < 5; i++) {
        final details = await dao.getFullAlgorithmDetails(algorithms[i].guid);
        final paramCount = details?.parameters.length ?? 0;
        totalParameters += paramCount;
        sampleAlgorithms.add('${algorithms[i].name} ($paramCount params)');
      }

      return {
        'totalAlgorithms': algorithms.length,
        'estimatedSize': '${(algorithms.length * 2.5).toStringAsFixed(1)} KB',
        'sampleAlgorithms': sampleAlgorithms,
        'hasParameters': totalParameters > 0,
      };
    } catch (e) {
      debugPrint('Error getting export preview: $e');
      return {
        'totalAlgorithms': 0,
        'estimatedSize': '0 KB',
        'sampleAlgorithms': <String>[],
        'hasParameters': false,
      };
    }
  }
}
