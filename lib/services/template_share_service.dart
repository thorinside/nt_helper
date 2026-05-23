import 'dart:convert';
import 'dart:typed_data';

import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

class TemplateShareService {
  static const exportType = 'nt_helper_template';
  static const exportVersion = 1;

  final AppDatabase database;

  TemplateShareService(this.database);

  String encodeTemplate(FullPresetDetails template) {
    final payload = {
      'exportType': exportType,
      'exportVersion': exportVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'template': {
        'name': template.preset.name,
        'category': template.preset.category,
        'templateMetadata': template.preset.templateMetadata,
        'slots': [
          for (final slot in template.slots)
            {
              'slotIndex': slot.slot.slotIndex,
              'algorithm': {
                'guid': slot.algorithm.guid,
                'name': slot.algorithm.name,
                'numSpecifications': slot.algorithm.numSpecifications,
                'pluginFilePath': slot.algorithm.pluginFilePath,
              },
              'customName': slot.slot.customName,
              'parameterValues': _intKeyMap(slot.parameterValues),
              'parameterStringValues': _intKeyMap(slot.parameterStringValues),
              'mappings': {
                for (final entry in slot.mappings.entries)
                  entry.key.toString(): _encodeMapping(entry.value),
              },
              'routing': slot.routing?.routingInfoJson,
            },
        ],
      },
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<int> importTemplate(String jsonText) async {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Template JSON must be an object.');
    }
    if (decoded['exportType'] != exportType) {
      throw const FormatException('Not an NT Helper template JSON file.');
    }
    final rawTemplate = decoded['template'];
    if (rawTemplate is! Map<String, dynamic>) {
      throw const FormatException('Template JSON is missing template data.');
    }

    final name = _requiredString(rawTemplate, 'name');
    final rawSlots = rawTemplate['slots'];
    if (rawSlots is! List || rawSlots.isEmpty) {
      throw const FormatException(
        'Template JSON must contain at least one slot.',
      );
    }

    final slots = <FullPresetSlot>[];
    final algorithms = <String, AlgorithmEntry>{};
    for (var outputIndex = 0; outputIndex < rawSlots.length; outputIndex++) {
      final rawSlot = rawSlots[outputIndex];
      if (rawSlot is! Map<String, dynamic>) {
        throw FormatException('Slot ${outputIndex + 1} is not an object.');
      }
      final rawAlgorithm = rawSlot['algorithm'];
      if (rawAlgorithm is! Map<String, dynamic>) {
        throw FormatException(
          'Slot ${outputIndex + 1} is missing algorithm data.',
        );
      }

      final algorithm = AlgorithmEntry(
        guid: _requiredString(rawAlgorithm, 'guid'),
        name: _requiredString(rawAlgorithm, 'name'),
        numSpecifications: _optionalInt(rawAlgorithm['numSpecifications']) ?? 0,
        pluginFilePath: rawAlgorithm['pluginFilePath'] as String?,
      );
      algorithms[algorithm.guid] = algorithm;

      slots.add(
        FullPresetSlot(
          slot: PresetSlotEntry(
            id: -1,
            presetId: -1,
            slotIndex: outputIndex,
            algorithmGuid: algorithm.guid,
            customName: rawSlot['customName'] as String?,
          ),
          algorithm: algorithm,
          parameterValues: _readIntMap(rawSlot['parameterValues']),
          parameterStringValues: _readStringMap(
            rawSlot['parameterStringValues'],
          ),
          mappings: _readMappings(rawSlot['mappings']),
          routing: _readRouting(rawSlot['routing']),
        ),
      );
    }

    await database.metadataDao.upsertAlgorithms(
      algorithms.values.toList(growable: false),
    );
    return database.presetsDao.saveFullPreset(
      FullPresetDetails(
        preset: PresetEntry(
          id: -1,
          name: name,
          lastModified: DateTime.now(),
          isTemplate: true,
          category: rawTemplate['category'] as String?,
          templateMetadata: rawTemplate['templateMetadata'] as String?,
        ),
        slots: slots,
      ),
      isTemplate: true,
    );
  }

  Map<String, Object?> _intKeyMap(Map<int, Object?> input) {
    return {
      for (final entry in input.entries) entry.key.toString(): entry.value,
    };
  }

  String _encodeMapping(PackedMappingData mapping) {
    return base64Encode(
      Uint8List.fromList([mapping.version, ...mapping.toBytes()]),
    );
  }

  Map<int, int> _readIntMap(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        int.parse(entry.key.toString()): _requiredInt(entry.value),
    };
  }

  Map<int, String> _readStringMap(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        int.parse(entry.key.toString()): entry.value.toString(),
    };
  }

  Map<int, PackedMappingData> _readMappings(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        int.parse(entry.key.toString()): _decodeMapping(entry.value),
    };
  }

  PackedMappingData _decodeMapping(Object? value) {
    if (value is! String) {
      throw const FormatException('Mapping payload must be base64 text.');
    }
    final bytes = base64Decode(value);
    if (bytes.length < 2) {
      throw const FormatException('Mapping payload is too short.');
    }
    return PackedMappingData.fromBytes(
      bytes.first,
      Uint8List.fromList(bytes.sublist(1)),
    );
  }

  PresetRoutingEntry? _readRouting(Object? value) {
    if (value == null) return null;
    if (value is! List) {
      throw const FormatException('Routing payload must be a list.');
    }
    return PresetRoutingEntry(
      presetSlotId: -1,
      routingInfoJson: [for (final item in value) _requiredInt(item)],
    );
  }

  String _requiredString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Missing required string field "$key".');
  }

  int _requiredInt(Object? value) {
    final parsed = _optionalInt(value);
    if (parsed == null) {
      throw FormatException('Expected integer, got "$value".');
    }
    return parsed;
  }

  int? _optionalInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
