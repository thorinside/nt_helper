import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nt_helper/db/database.dart';

/// Service responsible for upgrading existing databases with metadata from bundled assets.
///
/// This service is used to populate I/O flags and other metadata fields that may be
/// missing in existing installations when the app is upgraded to a newer version.
class MetadataUpgradeService {
  /// Checks if the database needs I/O flags upgrade.
  ///
  /// Returns true if all parameters have null ioFlags (needs upgrade),
  /// false if any parameters have ioFlags set (upgrade not needed or already done).
  Future<bool> needsIoFlagsUpgrade(AppDatabase database) async {
    try {
      // Check if any parameters have ioFlags set
      final result = await database.customSelect(
        'SELECT COUNT(*) as count FROM parameters WHERE io_flags IS NOT NULL',
        readsFrom: {database.parameters},
      ).getSingle();

      final count = result.read<int>('count');
      // Need upgrade if all flags are null (count = 0)
      return count == 0;
    } catch (e) {
      // If query fails, assume no upgrade needed to be safe
      return false;
    }
  }

  /// Upgrades database parameters with I/O flags from bundled metadata.
  ///
  /// This performs a selective update - only the ioFlags field is updated.
  /// All other parameter data (name, min, max, unit, etc.) is preserved.
  ///
  /// Returns the number of parameters updated.
  Future<int> upgradeIoFlags(AppDatabase database) async {
    try {
      // Load bundled metadata
      final jsonString = await rootBundle.loadString(
        'assets/metadata/full_metadata.json',
      );
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Validate export format
      if (data['exportType'] != 'full_metadata') {
        throw Exception('Invalid metadata format: expected full_metadata');
      }

      final tables = data['tables'] as Map<String, dynamic>;
      final paramsList = tables['parameters'] as List<dynamic>?;

      if (paramsList == null || paramsList.isEmpty) {
        return 0;
      }

      // Build list of updates (only parameters with non-null ioFlags)
      final updates = <({String guid, int paramNum, int ioFlags})>[];
      for (final paramData in paramsList) {
        final ioFlags = paramData['ioFlags'] as int?;
        // Only include parameters that have ioFlags data
        if (ioFlags != null) {
          updates.add((
            guid: paramData['algorithmGuid'] as String,
            paramNum: paramData['parameterNumber'] as int,
            ioFlags: ioFlags,
          ));
        }
      }

      if (updates.isEmpty) {
        return 0;
      }

      // Execute batch update in a single transaction using customUpdate
      await database.transaction(() async {
        for (final update in updates) {
          await database.customUpdate(
            'UPDATE parameters SET io_flags = ? WHERE algorithm_guid = ? AND parameter_number = ?',
            updates: {database.parameters},
            updateKind: UpdateKind.update,
            variables: [
              Variable.withInt(update.ioFlags),
              Variable.withString(update.guid),
              Variable.withInt(update.paramNum),
            ],
          );
        }
      });

      return updates.length;
    } catch (e) {
      // Re-throw with context
      throw Exception('Failed to upgrade I/O flags: $e');
    }
  }

  /// Full upgrade flow: check if needed, then perform upgrade.
  ///
  /// This is the main entry point for the upgrade process.
  /// Returns the number of parameters updated, or 0 if upgrade was not needed.
  Future<int> performUpgradeIfNeeded(AppDatabase database) async {
    try {
      final needsUpgrade = await needsIoFlagsUpgrade(database);
      if (!needsUpgrade) {
        return 0;
      }

      final updateCount = await upgradeIoFlags(database);
      return updateCount;
    } catch (e) {
      // Log error but don't fail - app should continue even if upgrade fails
      rethrow;
    }
  }
}
