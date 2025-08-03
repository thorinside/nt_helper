# Drift Database Migration Reference

## Current Migration Pattern in nt_helper

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
    debugPrint("Database created from scratch (version $schemaVersion).");
  },
  onUpgrade: (Migrator m, int from, int to) async {
    debugPrint("Starting database migration from version $from to $to...");
    
    // Step-by-step migrations
    if (from <= 4) {
      try {
        debugPrint("Adding new column to table...");
        await m.addColumn(tableName, tableName.columnName);
        debugPrint("Migration successful: Added column to table.");
      } catch (e) {
        debugPrint("Migration error: $e");
      }
    }
  },
);
```

## Safe Migration Checklist

1. **Increment Schema Version**
   ```dart
   @override
   int get schemaVersion => 6; // Increment from 5
   ```

2. **Add Migration Logic**
   - Use conditional checks: `if (from <= 5)`
   - Wrap in try-catch for error handling
   - Always use debugPrint for logging

3. **Common Operations**
   - `await m.createTable(newTable)` - Create new table
   - `await m.addColumn(table, table.column)` - Add column
   - `await m.alterTable()` - Complex alterations
   - Custom SQL: `await customStatement('ALTER TABLE...')`

4. **Testing Migrations**
   - Test with fresh install (onCreate)
   - Test upgrading from each previous version
   - Verify data integrity after migration

## Example: Adding Version Tracking

```dart
// In tables.dart - Add column to PluginInstallations
TextColumn get availableVersion => text().nullable()();
TextColumn get updateAvailable => text().withDefault(const Constant('false'))();
DateTimeColumn get lastChecked => dateTime().nullable()();

// In database.dart - Migration
if (from <= 5) {
  try {
    debugPrint("Adding version tracking columns to plugin_installations table...");
    await m.addColumn(pluginInstallations, pluginInstallations.availableVersion);
    await m.addColumn(pluginInstallations, pluginInstallations.updateAvailable);
    await m.addColumn(pluginInstallations, pluginInstallations.lastChecked);
    debugPrint("Migration successful: Added version tracking columns.");
  } catch (e) {
    debugPrint("Migration error adding version tracking: $e");
  }
}
```