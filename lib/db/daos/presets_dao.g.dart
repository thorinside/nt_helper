// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presets_dao.dart';

// ignore_for_file: type=lint
mixin _$PresetsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PresetsTable get presets => attachedDatabase.presets;
  $AlgorithmsTable get algorithms => attachedDatabase.algorithms;
  $PresetSlotsTable get presetSlots => attachedDatabase.presetSlots;
  $PresetParameterValuesTable get presetParameterValues =>
      attachedDatabase.presetParameterValues;
  $PresetMappingsTable get presetMappings => attachedDatabase.presetMappings;
  $PresetParameterStringValuesTable get presetParameterStringValues =>
      attachedDatabase.presetParameterStringValues;
  PresetsDaoManager get managers => PresetsDaoManager(this);
}

class PresetsDaoManager {
  final _$PresetsDaoMixin _db;
  PresetsDaoManager(this._db);
  $$PresetsTableTableManager get presets =>
      $$PresetsTableTableManager(_db.attachedDatabase, _db.presets);
  $$AlgorithmsTableTableManager get algorithms =>
      $$AlgorithmsTableTableManager(_db.attachedDatabase, _db.algorithms);
  $$PresetSlotsTableTableManager get presetSlots =>
      $$PresetSlotsTableTableManager(_db.attachedDatabase, _db.presetSlots);
  $$PresetParameterValuesTableTableManager get presetParameterValues =>
      $$PresetParameterValuesTableTableManager(
        _db.attachedDatabase,
        _db.presetParameterValues,
      );
  $$PresetMappingsTableTableManager get presetMappings =>
      $$PresetMappingsTableTableManager(
        _db.attachedDatabase,
        _db.presetMappings,
      );
  $$PresetParameterStringValuesTableTableManager
  get presetParameterStringValues =>
      $$PresetParameterStringValuesTableTableManager(
        _db.attachedDatabase,
        _db.presetParameterStringValues,
      );
}
