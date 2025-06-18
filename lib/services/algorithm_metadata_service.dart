import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nt_helper/models/algorithm_metadata.dart';
import 'package:nt_helper/models/algorithm_feature.dart';
import 'package:nt_helper/models/algorithm_parameter.dart';
import 'package:nt_helper/db/database.dart';

class AlgorithmMetadataService {
  // Singleton pattern
  static final AlgorithmMetadataService _instance =
      AlgorithmMetadataService._internal();
  factory AlgorithmMetadataService() => _instance;
  AlgorithmMetadataService._internal();

  final Map<String, AlgorithmMetadata> _algorithms = {};
  final Map<String, AlgorithmFeature> _features = {};
  bool _isInitialized = false;

  // --- Initialization ---

  Future<void> initialize(AppDatabase database) async {
    if (_isInitialized) return;

    await _loadFeatures();
    await _loadAlgorithms();

    await _mergeSyncedAlgorithms(database);

    _isInitialized = true;
    print(
        'AlgorithmMetadataService initialized with a total of ${_algorithms.length} algorithms (from JSON and DB) and ${_features.length} features.');
  }

  Future<void> _loadAlgorithms() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final algorithmFiles = manifestMap.keys
        .where((path) =>
            path.startsWith('docs/algorithms/') && path.endsWith('.json'))
        .toList();

    print('Found ${algorithmFiles.length} algorithm files in manifest.');

    for (final path in algorithmFiles) {
      try {
        final jsonString = await rootBundle.loadString(path);
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        final algorithm = AlgorithmMetadata.fromJson(jsonMap);
        _algorithms[algorithm.guid] = algorithm;
        // print('Loaded algorithm: ${algorithm.name} (${algorithm.guid})');
      } catch (e, stacktrace) {
        print('Error processing algorithm file $path: $e\n$stacktrace');
      }
    }
  }

  Future<void> _loadFeatures() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final featureFiles = manifestMap.keys
        .where((path) =>
            path.startsWith('docs/features/') && path.endsWith('.json'))
        .toList();

    print('Found ${featureFiles.length} feature files in manifest.');

    for (final path in featureFiles) {
      try {
        final jsonString = await rootBundle.loadString(path);
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        final feature = AlgorithmFeature.fromJson(jsonMap);
        _features[feature.guid] = feature;
        // print('Loaded feature: ${feature.name} (${feature.guid})');
      } catch (e, stacktrace) {
        print('Error processing feature file $path: $e\n$stacktrace');
      }
    }
  }

  Future<void> _mergeSyncedAlgorithms(AppDatabase database) async {
    final metadataDao = database.metadataDao;
    final List<AlgorithmEntry> syncedEntries =
        await metadataDao.getAllAlgorithms();
    int mergedCount = 0;

    print(
        '[AlgorithmMetadataService] Found ${syncedEntries.length} algorithm entries in local DB for potential merging.');

    for (final entry in syncedEntries) {
      if (!_algorithms.containsKey(entry.guid)) {
        final newAlgo = AlgorithmMetadata(
          guid: entry.guid,
          name: entry.name,
          description:
              "Synced from device. Full documentation may be unavailable locally.",
          categories: ["Synced From Device"],
          features: [],
          parameters: [],
        );
        _algorithms[entry.guid] = newAlgo;
        mergedCount++;
      }
    }
    if (mergedCount > 0) {
      print(
          '[AlgorithmMetadataService] Successfully merged $mergedCount new algorithms from the local database.');
    } else {
      print(
          '[AlgorithmMetadataService] No new algorithms from local DB to merge (all already present in JSON or DB empty).');
    }
  }

  // --- Public Access Methods ---

  List<AlgorithmMetadata> getAllAlgorithms() {
    _ensureInitialized();
    return _algorithms.values.toList();
  }

  AlgorithmMetadata? getAlgorithmByGuid(String guid) {
    _ensureInitialized();
    return _algorithms[guid];
  }

  AlgorithmFeature? getFeatureByGuid(String guid) {
    _ensureInitialized();
    return _features[guid];
  }

  List<AlgorithmMetadata> findAlgorithmsByCategory(String category) {
    _ensureInitialized();
    final lowerCategory = category.toLowerCase();
    return _algorithms.values
        .where((alg) =>
            alg.categories.any((cat) => cat.toLowerCase() == lowerCategory))
        .toList();
  }

  // Placeholder for more complex search - simple implementation for now
  List<AlgorithmMetadata> findAlgorithmsByQuery(String query) {
    _ensureInitialized();
    final lowerQuery = query.toLowerCase();
    return _algorithms.values
        .where((alg) =>
            alg.name.toLowerCase().contains(lowerQuery) ||
            alg.description.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Returns a combined list of parameters for an algorithm, including
  /// its own parameters and those inherited from its features.
  List<AlgorithmParameter> getExpandedParameters(String algorithmGuid) {
    _ensureInitialized();
    final algorithm = getAlgorithmByGuid(algorithmGuid);
    if (algorithm == null) return [];

    // Use a Set to avoid duplicate parameters if a feature redefines one
    // (though ideally features shouldn't overlap heavily with base params)
    // We use the parameter name as the key for uniqueness.
    final Map<String, AlgorithmParameter> combinedParams = {};

    // Add base parameters first
    for (final param in algorithm.parameters) {
      combinedParams[param.name] = param;
    }

    // Add parameters from features, potentially overwriting if name collision occurs
    // (though this indicates a potential issue in feature/algorithm definition)
    for (final featureGuid in algorithm.features) {
      final feature = getFeatureByGuid(featureGuid);
      if (feature != null) {
        for (final param in feature.parameters) {
          combinedParams[param.name] = param; // Overwrite if name exists
        }
      } else {
        print(
            'Warning: Feature with guid $featureGuid not found for algorithm ${algorithm.guid}');
      }
    }
    return combinedParams.values.toList();
  }

  // --- Private Helpers ---

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception(
          'AlgorithmMetadataService not initialized. Call initialize(database) first.');
    }
  }
}
