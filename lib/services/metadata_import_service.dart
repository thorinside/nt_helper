import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nt_helper/db/database.dart';

class MetadataImportService {
  final AppDatabase database;

  MetadataImportService(this.database);

  /// Imports metadata from a bundled JSON asset file
  /// This is used to pre-populate the database on first launch
  Future<bool> importFromAsset(String assetPath) async {
    try {

      // Load the JSON file from assets
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data = json.decode(jsonString);

      // Validate the export format
      if (data['exportType'] != 'full_metadata') {
        return false;
      }

      final tables = data['tables'] as Map<String, dynamic>;
      if (tables.isEmpty) {
        return false;
      }

      // Import in the correct order to respect foreign key constraints
      await _importUnits(tables['units'] as List<dynamic>?);
      await _importAlgorithms(tables['algorithms'] as List<dynamic>?);
      await _importSpecifications(tables['specifications'] as List<dynamic>?);
      await _importParameters(tables['parameters'] as List<dynamic>?);
      await _importParameterEnums(tables['parameterEnums'] as List<dynamic>?);
      await _importParameterPages(tables['parameterPages'] as List<dynamic>?);
      await _importParameterPageItems(
        tables['parameterPageItems'] as List<dynamic>?,
      );
      await _importMetadataCache(tables['metadataCache'] as List<dynamic>?);

      // Log import summary
      final summary = data['summary'] as Map<String, dynamic>?;
      if (summary != null) {
        summary.forEach((key, value) {
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if the database already has metadata
  Future<bool> hasExistingMetadata() async {
    return await database.metadataDao.hasCachedAlgorithms();
  }

  // --- Private import methods for each table ---

  Future<void> _importUnits(List<dynamic>? unitsList) async {
    if (unitsList == null || unitsList.isEmpty) {
      return;
    }

    final entries = <UnitsCompanion>[];

    for (final unitData in unitsList) {
      entries.add(
        UnitsCompanion.insert(
          id: Value(unitData['id'] as int),
          unitString: unitData['unitString'] as String,
        ),
      );
    }

    await database.batch((batch) {
      batch.insertAll(
        database.units,
        entries,
        mode: InsertMode.insertOrReplace,
      );
    });

  }

  Future<void> _importAlgorithms(List<dynamic>? algorithmsList) async {
    if (algorithmsList == null || algorithmsList.isEmpty) {
      return;
    }

    final entries = <AlgorithmsCompanion>[];

    for (final algoData in algorithmsList) {
      entries.add(
        AlgorithmsCompanion(
          guid: Value(algoData['guid'] as String),
          name: Value(algoData['name'] as String),
          numSpecifications: Value(algoData['numSpecifications'] as int),
          pluginFilePath: Value(algoData['pluginFilePath'] as String?),
        ),
      );
    }

    await database.batch((batch) {
      batch.insertAll(
        database.algorithms,
        entries,
        mode: InsertMode.insertOrReplace,
      );
    });

  }

  Future<void> _importSpecifications(List<dynamic>? specsList) async {
    if (specsList == null || specsList.isEmpty) {
      return;
    }

    final entries = <SpecificationsCompanion>[];

    for (final specData in specsList) {
      entries.add(
        SpecificationsCompanion(
          algorithmGuid: Value(specData['algorithmGuid'] as String),
          specIndex: Value(specData['specIndex'] as int),
          name: Value(specData['name'] as String),
          minValue: Value(specData['minValue'] as int),
          maxValue: Value(specData['maxValue'] as int),
          defaultValue: Value(specData['defaultValue'] as int),
          type: Value(specData['type'] as int),
        ),
      );
    }

    await database.batch((batch) {
      batch.insertAll(
        database.specifications,
        entries,
        mode: InsertMode.insertOrReplace,
      );
    });

  }

  Future<void> _importParameters(List<dynamic>? paramsList) async {
    if (paramsList == null || paramsList.isEmpty) {
      return;
    }

    final entries = <ParametersCompanion>[];

    for (final paramData in paramsList) {
      entries.add(
        ParametersCompanion(
          algorithmGuid: Value(paramData['algorithmGuid'] as String),
          parameterNumber: Value(paramData['parameterNumber'] as int),
          name: Value(paramData['name'] as String),
          minValue: Value(paramData['minValue'] as int?),
          maxValue: Value(paramData['maxValue'] as int?),
          defaultValue: Value(paramData['defaultValue'] as int?),
          unitId: Value(paramData['unitId'] as int?),
          powerOfTen: Value(paramData['powerOfTen'] as int?),
          rawUnitIndex: Value(paramData['rawUnitIndex'] as int?),
        ),
      );
    }

    await database.batch((batch) {
      batch.insertAll(
        database.parameters,
        entries,
        mode: InsertMode.insertOrReplace,
      );
    });

  }

  Future<void> _importParameterEnums(List<dynamic>? enumsList) async {
    if (enumsList == null || enumsList.isEmpty) {
      return;
    }

    final entries = <ParameterEnumsCompanion>[];

    for (final enumData in enumsList) {
      entries.add(
        ParameterEnumsCompanion(
          algorithmGuid: Value(enumData['algorithmGuid'] as String),
          parameterNumber: Value(enumData['parameterNumber'] as int),
          enumIndex: Value(enumData['enumIndex'] as int),
          enumString: Value(enumData['enumString'] as String),
        ),
      );
    }

    await database.batch((batch) {
      batch.insertAll(
        database.parameterEnums,
        entries,
        mode: InsertMode.insertOrReplace,
      );
    });

  }

  Future<void> _importParameterPages(List<dynamic>? pagesList) async {
    if (pagesList == null || pagesList.isEmpty) {
      return;
    }

    final entries = <ParameterPagesCompanion>[];

    for (final pageData in pagesList) {
      entries.add(
        ParameterPagesCompanion(
          algorithmGuid: Value(pageData['algorithmGuid'] as String),
          pageIndex: Value(pageData['pageIndex'] as int),
          name: Value(pageData['name'] as String),
        ),
      );
    }

    await database.batch((batch) {
      batch.insertAll(
        database.parameterPages,
        entries,
        mode: InsertMode.insertOrReplace,
      );
    });

  }

  Future<void> _importParameterPageItems(List<dynamic>? itemsList) async {
    if (itemsList == null || itemsList.isEmpty) {
      return;
    }

    final entries = <ParameterPageItemsCompanion>[];

    for (final itemData in itemsList) {
      entries.add(
        ParameterPageItemsCompanion(
          algorithmGuid: Value(itemData['algorithmGuid'] as String),
          pageIndex: Value(itemData['pageIndex'] as int),
          parameterNumber: Value(itemData['parameterNumber'] as int),
        ),
      );
    }

    await database.batch((batch) {
      batch.insertAll(
        database.parameterPageItems,
        entries,
        mode: InsertMode.insertOrReplace,
      );
    });

  }

  Future<void> _importMetadataCache(List<dynamic>? cacheList) async {
    if (cacheList == null || cacheList.isEmpty) {
      return;
    }

    final entries = <MetadataCacheCompanion>[];

    for (final cacheData in cacheList) {
      entries.add(
        MetadataCacheCompanion(
          cacheKey: Value(cacheData['cacheKey'] as String),
          cacheValue: Value(cacheData['cacheValue'] as String),
        ),
      );
    }

    await database.batch((batch) {
      batch.insertAll(
        database.metadataCache,
        entries,
        mode: InsertMode.insertOrReplace,
      );
    });

  }
}
