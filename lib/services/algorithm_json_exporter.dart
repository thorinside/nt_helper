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
          'Processing algorithm: ${algorithm.name} (${algorithm.guid})',
        );

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
      exportData.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );

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
        'Successfully exported ${exportData.length} algorithms to $filePath',
      );
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

  /// DEBUG ONLY: Exports ALL metadata tables to a JSON file for bundling as an asset
  /// This enables offline mode without device sync on first launch
  Future<void> exportFullMetadata(String filePath) async {
    if (!kDebugMode) {
      throw Exception('exportFullMetadata is only available in debug mode');
    }

    try {
      debugPrint('[DEBUG] Starting FULL metadata export to: $filePath');

      final dao = database.metadataDao;

      // Fetch all data from all metadata tables
      final algorithms = await dao.getAllAlgorithms();
      final specifications = await dao.getAllSpecifications();
      final units = await dao.getAllUnits();
      final parameters = await dao.getAllParameters();
      final parameterEnums = await dao.getAllParameterEnums();
      final parameterPages = await dao.getAllParameterPages();
      final parameterPageItems = await dao.getAllParameterPageItems();
      final metadataCache = await dao.getMetadataCacheEntries();

      debugPrint('[DEBUG] Fetched data from all tables:');
      debugPrint('  - Algorithms: ${algorithms.length}');
      debugPrint('  - Specifications: ${specifications.length}');
      debugPrint('  - Units: ${units.length}');
      debugPrint('  - Parameters: ${parameters.length}');
      debugPrint('  - Parameter Enums: ${parameterEnums.length}');
      debugPrint('  - Parameter Pages: ${parameterPages.length}');
      debugPrint('  - Parameter Page Items: ${parameterPageItems.length}');
      debugPrint('  - Metadata Cache: ${metadataCache.length}');

      // Build the complete export structure
      final Map<String, dynamic> exportJson = {
        'exportDate': DateTime.now().toIso8601String(),
        'exportVersion': 1,
        'exportType': 'full_metadata',
        'debugExport': true,
        'tables': {
          // Units must be imported first (referenced by parameters)
          'units': units
              .map((u) => {'id': u.id, 'unitString': u.unitString})
              .toList(),

          // Algorithms must be imported before anything that references them
          'algorithms': algorithms
              .map(
                (a) => {
                  'guid': a.guid,
                  'name': a.name,
                  'numSpecifications': a.numSpecifications,
                  'pluginFilePath': a.pluginFilePath,
                },
              )
              .toList(),

          // Specifications reference algorithms
          'specifications': specifications
              .map(
                (s) => {
                  'algorithmGuid': s.algorithmGuid,
                  'specIndex': s.specIndex,
                  'name': s.name,
                  'minValue': s.minValue,
                  'maxValue': s.maxValue,
                  'defaultValue': s.defaultValue,
                  'type': s.type,
                },
              )
              .toList(),

          // Parameters reference algorithms and units
          'parameters': parameters
              .map(
                (p) => {
                  'algorithmGuid': p.algorithmGuid,
                  'parameterNumber': p.parameterNumber,
                  'name': p.name,
                  'minValue': p.minValue,
                  'maxValue': p.maxValue,
                  'defaultValue': p.defaultValue,
                  'unitId': p.unitId,
                  'powerOfTen': p.powerOfTen,
                  'rawUnitIndex': p.rawUnitIndex,
                },
              )
              .toList(),

          // Parameter enums reference parameters
          'parameterEnums': parameterEnums
              .map(
                (e) => {
                  'algorithmGuid': e.algorithmGuid,
                  'parameterNumber': e.parameterNumber,
                  'enumIndex': e.enumIndex,
                  'enumString': e.enumString,
                },
              )
              .toList(),

          // Parameter pages reference algorithms
          'parameterPages': parameterPages
              .map(
                (p) => {
                  'algorithmGuid': p.algorithmGuid,
                  'pageIndex': p.pageIndex,
                  'name': p.name,
                },
              )
              .toList(),

          // Parameter page items reference pages and parameters
          'parameterPageItems': parameterPageItems
              .map(
                (i) => {
                  'algorithmGuid': i.algorithmGuid,
                  'pageIndex': i.pageIndex,
                  'parameterNumber': i.parameterNumber,
                },
              )
              .toList(),

          // Metadata cache (no references)
          'metadataCache': metadataCache
              .map((c) => {'cacheKey': c.cacheKey, 'cacheValue': c.cacheValue})
              .toList(),
        },
        'summary': {
          'totalAlgorithms': algorithms.length,
          'totalSpecifications': specifications.length,
          'totalUnits': units.length,
          'totalParameters': parameters.length,
          'totalParameterEnums': parameterEnums.length,
          'totalParameterPages': parameterPages.length,
          'totalParameterPageItems': parameterPageItems.length,
          'totalCacheEntries': metadataCache.length,
        },
      };

      // Write to file with pretty printing
      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportJson),
        encoding: utf8,
      );

      final fileSize = await file.length();
      debugPrint(
        '[DEBUG] Successfully exported FULL metadata to $filePath (${(fileSize / 1024).toStringAsFixed(1)} KB)',
      );
    } catch (e, stackTrace) {
      debugPrint('[DEBUG] Error exporting full metadata: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// DEBUG ONLY: Gets a preview of what would be exported for full metadata
  Future<Map<String, dynamic>> getFullExportPreview() async {
    if (!kDebugMode) {
      throw Exception('getFullExportPreview is only available in debug mode');
    }

    try {
      final dao = database.metadataDao;

      // Get counts from all tables
      final algorithms = await dao.getAllAlgorithms();
      final specifications = await dao.getAllSpecifications();
      final units = await dao.getAllUnits();
      final parameters = await dao.getAllParameters();
      final parameterEnums = await dao.getAllParameterEnums();
      final parameterPages = await dao.getAllParameterPages();
      final parameterPageItems = await dao.getAllParameterPageItems();
      final metadataCache = await dao.getMetadataCacheEntries();

      // Estimate size (rough approximation)
      final estimatedSizeKB =
          (algorithms.length * 0.5 +
          specifications.length * 0.3 +
          units.length * 0.1 +
          parameters.length * 0.4 +
          parameterEnums.length * 0.2 +
          parameterPages.length * 0.2 +
          parameterPageItems.length * 0.1 +
          metadataCache.length * 0.5);

      return {
        'exportType': 'full_metadata',
        'debugOnly': true,
        'tableCounts': {
          'algorithms': algorithms.length,
          'specifications': specifications.length,
          'units': units.length,
          'parameters': parameters.length,
          'parameterEnums': parameterEnums.length,
          'parameterPages': parameterPages.length,
          'parameterPageItems': parameterPageItems.length,
          'metadataCache': metadataCache.length,
        },
        'estimatedSizeKB': estimatedSizeKB.toStringAsFixed(1),
        'sampleAlgorithms': algorithms.take(5).map((a) => a.name).toList(),
      };
    } catch (e) {
      debugPrint('[DEBUG] Error getting full export preview: $e');
      return {
        'error': 'Failed to get preview: $e',
        'exportType': 'full_metadata',
        'debugOnly': true,
      };
    }
  }
}
