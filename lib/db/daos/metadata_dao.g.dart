// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_dao.dart';

// ignore_for_file: type=lint
mixin _$MetadataDaoMixin on DatabaseAccessor<AppDatabase> {
  $AlgorithmsTable get algorithms => attachedDatabase.algorithms;
  $SpecificationsTable get specifications => attachedDatabase.specifications;
  $UnitsTable get units => attachedDatabase.units;
  $ParametersTable get parameters => attachedDatabase.parameters;
  $ParameterEnumsTable get parameterEnums => attachedDatabase.parameterEnums;
  $ParameterPagesTable get parameterPages => attachedDatabase.parameterPages;
  $ParameterPageItemsTable get parameterPageItems =>
      attachedDatabase.parameterPageItems;
  $ParameterOutputModeUsageTable get parameterOutputModeUsage =>
      attachedDatabase.parameterOutputModeUsage;
  $MetadataCacheTable get metadataCache => attachedDatabase.metadataCache;
  MetadataDaoManager get managers => MetadataDaoManager(this);
}

class MetadataDaoManager {
  final _$MetadataDaoMixin _db;
  MetadataDaoManager(this._db);
  $$AlgorithmsTableTableManager get algorithms =>
      $$AlgorithmsTableTableManager(_db.attachedDatabase, _db.algorithms);
  $$SpecificationsTableTableManager get specifications =>
      $$SpecificationsTableTableManager(
        _db.attachedDatabase,
        _db.specifications,
      );
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db.attachedDatabase, _db.units);
  $$ParametersTableTableManager get parameters =>
      $$ParametersTableTableManager(_db.attachedDatabase, _db.parameters);
  $$ParameterEnumsTableTableManager get parameterEnums =>
      $$ParameterEnumsTableTableManager(
        _db.attachedDatabase,
        _db.parameterEnums,
      );
  $$ParameterPagesTableTableManager get parameterPages =>
      $$ParameterPagesTableTableManager(
        _db.attachedDatabase,
        _db.parameterPages,
      );
  $$ParameterPageItemsTableTableManager get parameterPageItems =>
      $$ParameterPageItemsTableTableManager(
        _db.attachedDatabase,
        _db.parameterPageItems,
      );
  $$ParameterOutputModeUsageTableTableManager get parameterOutputModeUsage =>
      $$ParameterOutputModeUsageTableTableManager(
        _db.attachedDatabase,
        _db.parameterOutputModeUsage,
      );
  $$MetadataCacheTableTableManager get metadataCache =>
      $$MetadataCacheTableTableManager(_db.attachedDatabase, _db.metadataCache);
}
