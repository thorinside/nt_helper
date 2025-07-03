// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AlgorithmsTable extends Algorithms
    with TableInfo<$AlgorithmsTable, AlgorithmEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlgorithmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
      'guid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numSpecificationsMeta =
      const VerificationMeta('numSpecifications');
  @override
  late final GeneratedColumn<int> numSpecifications = GeneratedColumn<int>(
      'num_specifications', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _pluginFilePathMeta =
      const VerificationMeta('pluginFilePath');
  @override
  late final GeneratedColumn<String> pluginFilePath = GeneratedColumn<String>(
      'plugin_file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [guid, name, numSpecifications, pluginFilePath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'algorithms';
  @override
  VerificationContext validateIntegrity(Insertable<AlgorithmEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('guid')) {
      context.handle(
          _guidMeta, guid.isAcceptableOrUnknown(data['guid']!, _guidMeta));
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('num_specifications')) {
      context.handle(
          _numSpecificationsMeta,
          numSpecifications.isAcceptableOrUnknown(
              data['num_specifications']!, _numSpecificationsMeta));
    } else if (isInserting) {
      context.missing(_numSpecificationsMeta);
    }
    if (data.containsKey('plugin_file_path')) {
      context.handle(
          _pluginFilePathMeta,
          pluginFilePath.isAcceptableOrUnknown(
              data['plugin_file_path']!, _pluginFilePathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {guid};
  @override
  AlgorithmEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlgorithmEntry(
      guid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}guid'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      numSpecifications: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}num_specifications'])!,
      pluginFilePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}plugin_file_path']),
    );
  }

  @override
  $AlgorithmsTable createAlias(String alias) {
    return $AlgorithmsTable(attachedDatabase, alias);
  }
}

class AlgorithmEntry extends DataClass implements Insertable<AlgorithmEntry> {
  final String guid;
  final String name;
  final int numSpecifications;
  final String? pluginFilePath;
  const AlgorithmEntry(
      {required this.guid,
      required this.name,
      required this.numSpecifications,
      this.pluginFilePath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['guid'] = Variable<String>(guid);
    map['name'] = Variable<String>(name);
    map['num_specifications'] = Variable<int>(numSpecifications);
    if (!nullToAbsent || pluginFilePath != null) {
      map['plugin_file_path'] = Variable<String>(pluginFilePath);
    }
    return map;
  }

  AlgorithmsCompanion toCompanion(bool nullToAbsent) {
    return AlgorithmsCompanion(
      guid: Value(guid),
      name: Value(name),
      numSpecifications: Value(numSpecifications),
      pluginFilePath: pluginFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(pluginFilePath),
    );
  }

  factory AlgorithmEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlgorithmEntry(
      guid: serializer.fromJson<String>(json['guid']),
      name: serializer.fromJson<String>(json['name']),
      numSpecifications: serializer.fromJson<int>(json['numSpecifications']),
      pluginFilePath: serializer.fromJson<String?>(json['pluginFilePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'guid': serializer.toJson<String>(guid),
      'name': serializer.toJson<String>(name),
      'numSpecifications': serializer.toJson<int>(numSpecifications),
      'pluginFilePath': serializer.toJson<String?>(pluginFilePath),
    };
  }

  AlgorithmEntry copyWith(
          {String? guid,
          String? name,
          int? numSpecifications,
          Value<String?> pluginFilePath = const Value.absent()}) =>
      AlgorithmEntry(
        guid: guid ?? this.guid,
        name: name ?? this.name,
        numSpecifications: numSpecifications ?? this.numSpecifications,
        pluginFilePath:
            pluginFilePath.present ? pluginFilePath.value : this.pluginFilePath,
      );
  AlgorithmEntry copyWithCompanion(AlgorithmsCompanion data) {
    return AlgorithmEntry(
      guid: data.guid.present ? data.guid.value : this.guid,
      name: data.name.present ? data.name.value : this.name,
      numSpecifications: data.numSpecifications.present
          ? data.numSpecifications.value
          : this.numSpecifications,
      pluginFilePath: data.pluginFilePath.present
          ? data.pluginFilePath.value
          : this.pluginFilePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlgorithmEntry(')
          ..write('guid: $guid, ')
          ..write('name: $name, ')
          ..write('numSpecifications: $numSpecifications, ')
          ..write('pluginFilePath: $pluginFilePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(guid, name, numSpecifications, pluginFilePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlgorithmEntry &&
          other.guid == this.guid &&
          other.name == this.name &&
          other.numSpecifications == this.numSpecifications &&
          other.pluginFilePath == this.pluginFilePath);
}

class AlgorithmsCompanion extends UpdateCompanion<AlgorithmEntry> {
  final Value<String> guid;
  final Value<String> name;
  final Value<int> numSpecifications;
  final Value<String?> pluginFilePath;
  final Value<int> rowid;
  const AlgorithmsCompanion({
    this.guid = const Value.absent(),
    this.name = const Value.absent(),
    this.numSpecifications = const Value.absent(),
    this.pluginFilePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlgorithmsCompanion.insert({
    required String guid,
    required String name,
    required int numSpecifications,
    this.pluginFilePath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : guid = Value(guid),
        name = Value(name),
        numSpecifications = Value(numSpecifications);
  static Insertable<AlgorithmEntry> custom({
    Expression<String>? guid,
    Expression<String>? name,
    Expression<int>? numSpecifications,
    Expression<String>? pluginFilePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (guid != null) 'guid': guid,
      if (name != null) 'name': name,
      if (numSpecifications != null) 'num_specifications': numSpecifications,
      if (pluginFilePath != null) 'plugin_file_path': pluginFilePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlgorithmsCompanion copyWith(
      {Value<String>? guid,
      Value<String>? name,
      Value<int>? numSpecifications,
      Value<String?>? pluginFilePath,
      Value<int>? rowid}) {
    return AlgorithmsCompanion(
      guid: guid ?? this.guid,
      name: name ?? this.name,
      numSpecifications: numSpecifications ?? this.numSpecifications,
      pluginFilePath: pluginFilePath ?? this.pluginFilePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (numSpecifications.present) {
      map['num_specifications'] = Variable<int>(numSpecifications.value);
    }
    if (pluginFilePath.present) {
      map['plugin_file_path'] = Variable<String>(pluginFilePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlgorithmsCompanion(')
          ..write('guid: $guid, ')
          ..write('name: $name, ')
          ..write('numSpecifications: $numSpecifications, ')
          ..write('pluginFilePath: $pluginFilePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpecificationsTable extends Specifications
    with TableInfo<$SpecificationsTable, SpecificationEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpecificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _algorithmGuidMeta =
      const VerificationMeta('algorithmGuid');
  @override
  late final GeneratedColumn<String> algorithmGuid = GeneratedColumn<String>(
      'algorithm_guid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES algorithms (guid)'));
  static const VerificationMeta _specIndexMeta =
      const VerificationMeta('specIndex');
  @override
  late final GeneratedColumn<int> specIndex = GeneratedColumn<int>(
      'spec_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minValueMeta =
      const VerificationMeta('minValue');
  @override
  late final GeneratedColumn<int> minValue = GeneratedColumn<int>(
      'min_value', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _maxValueMeta =
      const VerificationMeta('maxValue');
  @override
  late final GeneratedColumn<int> maxValue = GeneratedColumn<int>(
      'max_value', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _defaultValueMeta =
      const VerificationMeta('defaultValue');
  @override
  late final GeneratedColumn<int> defaultValue = GeneratedColumn<int>(
      'default_value', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
      'type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [algorithmGuid, specIndex, name, minValue, maxValue, defaultValue, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'specifications';
  @override
  VerificationContext validateIntegrity(Insertable<SpecificationEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('algorithm_guid')) {
      context.handle(
          _algorithmGuidMeta,
          algorithmGuid.isAcceptableOrUnknown(
              data['algorithm_guid']!, _algorithmGuidMeta));
    } else if (isInserting) {
      context.missing(_algorithmGuidMeta);
    }
    if (data.containsKey('spec_index')) {
      context.handle(_specIndexMeta,
          specIndex.isAcceptableOrUnknown(data['spec_index']!, _specIndexMeta));
    } else if (isInserting) {
      context.missing(_specIndexMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('min_value')) {
      context.handle(_minValueMeta,
          minValue.isAcceptableOrUnknown(data['min_value']!, _minValueMeta));
    } else if (isInserting) {
      context.missing(_minValueMeta);
    }
    if (data.containsKey('max_value')) {
      context.handle(_maxValueMeta,
          maxValue.isAcceptableOrUnknown(data['max_value']!, _maxValueMeta));
    } else if (isInserting) {
      context.missing(_maxValueMeta);
    }
    if (data.containsKey('default_value')) {
      context.handle(
          _defaultValueMeta,
          defaultValue.isAcceptableOrUnknown(
              data['default_value']!, _defaultValueMeta));
    } else if (isInserting) {
      context.missing(_defaultValueMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {algorithmGuid, specIndex};
  @override
  SpecificationEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpecificationEntry(
      algorithmGuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}algorithm_guid'])!,
      specIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}spec_index'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      minValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_value'])!,
      maxValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_value'])!,
      defaultValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}default_value'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!,
    );
  }

  @override
  $SpecificationsTable createAlias(String alias) {
    return $SpecificationsTable(attachedDatabase, alias);
  }
}

class SpecificationEntry extends DataClass
    implements Insertable<SpecificationEntry> {
  final String algorithmGuid;
  final int specIndex;
  final String name;
  final int minValue;
  final int maxValue;
  final int defaultValue;
  final int type;
  const SpecificationEntry(
      {required this.algorithmGuid,
      required this.specIndex,
      required this.name,
      required this.minValue,
      required this.maxValue,
      required this.defaultValue,
      required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['algorithm_guid'] = Variable<String>(algorithmGuid);
    map['spec_index'] = Variable<int>(specIndex);
    map['name'] = Variable<String>(name);
    map['min_value'] = Variable<int>(minValue);
    map['max_value'] = Variable<int>(maxValue);
    map['default_value'] = Variable<int>(defaultValue);
    map['type'] = Variable<int>(type);
    return map;
  }

  SpecificationsCompanion toCompanion(bool nullToAbsent) {
    return SpecificationsCompanion(
      algorithmGuid: Value(algorithmGuid),
      specIndex: Value(specIndex),
      name: Value(name),
      minValue: Value(minValue),
      maxValue: Value(maxValue),
      defaultValue: Value(defaultValue),
      type: Value(type),
    );
  }

  factory SpecificationEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpecificationEntry(
      algorithmGuid: serializer.fromJson<String>(json['algorithmGuid']),
      specIndex: serializer.fromJson<int>(json['specIndex']),
      name: serializer.fromJson<String>(json['name']),
      minValue: serializer.fromJson<int>(json['minValue']),
      maxValue: serializer.fromJson<int>(json['maxValue']),
      defaultValue: serializer.fromJson<int>(json['defaultValue']),
      type: serializer.fromJson<int>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'algorithmGuid': serializer.toJson<String>(algorithmGuid),
      'specIndex': serializer.toJson<int>(specIndex),
      'name': serializer.toJson<String>(name),
      'minValue': serializer.toJson<int>(minValue),
      'maxValue': serializer.toJson<int>(maxValue),
      'defaultValue': serializer.toJson<int>(defaultValue),
      'type': serializer.toJson<int>(type),
    };
  }

  SpecificationEntry copyWith(
          {String? algorithmGuid,
          int? specIndex,
          String? name,
          int? minValue,
          int? maxValue,
          int? defaultValue,
          int? type}) =>
      SpecificationEntry(
        algorithmGuid: algorithmGuid ?? this.algorithmGuid,
        specIndex: specIndex ?? this.specIndex,
        name: name ?? this.name,
        minValue: minValue ?? this.minValue,
        maxValue: maxValue ?? this.maxValue,
        defaultValue: defaultValue ?? this.defaultValue,
        type: type ?? this.type,
      );
  SpecificationEntry copyWithCompanion(SpecificationsCompanion data) {
    return SpecificationEntry(
      algorithmGuid: data.algorithmGuid.present
          ? data.algorithmGuid.value
          : this.algorithmGuid,
      specIndex: data.specIndex.present ? data.specIndex.value : this.specIndex,
      name: data.name.present ? data.name.value : this.name,
      minValue: data.minValue.present ? data.minValue.value : this.minValue,
      maxValue: data.maxValue.present ? data.maxValue.value : this.maxValue,
      defaultValue: data.defaultValue.present
          ? data.defaultValue.value
          : this.defaultValue,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpecificationEntry(')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('specIndex: $specIndex, ')
          ..write('name: $name, ')
          ..write('minValue: $minValue, ')
          ..write('maxValue: $maxValue, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      algorithmGuid, specIndex, name, minValue, maxValue, defaultValue, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpecificationEntry &&
          other.algorithmGuid == this.algorithmGuid &&
          other.specIndex == this.specIndex &&
          other.name == this.name &&
          other.minValue == this.minValue &&
          other.maxValue == this.maxValue &&
          other.defaultValue == this.defaultValue &&
          other.type == this.type);
}

class SpecificationsCompanion extends UpdateCompanion<SpecificationEntry> {
  final Value<String> algorithmGuid;
  final Value<int> specIndex;
  final Value<String> name;
  final Value<int> minValue;
  final Value<int> maxValue;
  final Value<int> defaultValue;
  final Value<int> type;
  final Value<int> rowid;
  const SpecificationsCompanion({
    this.algorithmGuid = const Value.absent(),
    this.specIndex = const Value.absent(),
    this.name = const Value.absent(),
    this.minValue = const Value.absent(),
    this.maxValue = const Value.absent(),
    this.defaultValue = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpecificationsCompanion.insert({
    required String algorithmGuid,
    required int specIndex,
    required String name,
    required int minValue,
    required int maxValue,
    required int defaultValue,
    required int type,
    this.rowid = const Value.absent(),
  })  : algorithmGuid = Value(algorithmGuid),
        specIndex = Value(specIndex),
        name = Value(name),
        minValue = Value(minValue),
        maxValue = Value(maxValue),
        defaultValue = Value(defaultValue),
        type = Value(type);
  static Insertable<SpecificationEntry> custom({
    Expression<String>? algorithmGuid,
    Expression<int>? specIndex,
    Expression<String>? name,
    Expression<int>? minValue,
    Expression<int>? maxValue,
    Expression<int>? defaultValue,
    Expression<int>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (algorithmGuid != null) 'algorithm_guid': algorithmGuid,
      if (specIndex != null) 'spec_index': specIndex,
      if (name != null) 'name': name,
      if (minValue != null) 'min_value': minValue,
      if (maxValue != null) 'max_value': maxValue,
      if (defaultValue != null) 'default_value': defaultValue,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpecificationsCompanion copyWith(
      {Value<String>? algorithmGuid,
      Value<int>? specIndex,
      Value<String>? name,
      Value<int>? minValue,
      Value<int>? maxValue,
      Value<int>? defaultValue,
      Value<int>? type,
      Value<int>? rowid}) {
    return SpecificationsCompanion(
      algorithmGuid: algorithmGuid ?? this.algorithmGuid,
      specIndex: specIndex ?? this.specIndex,
      name: name ?? this.name,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      defaultValue: defaultValue ?? this.defaultValue,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (algorithmGuid.present) {
      map['algorithm_guid'] = Variable<String>(algorithmGuid.value);
    }
    if (specIndex.present) {
      map['spec_index'] = Variable<int>(specIndex.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (minValue.present) {
      map['min_value'] = Variable<int>(minValue.value);
    }
    if (maxValue.present) {
      map['max_value'] = Variable<int>(maxValue.value);
    }
    if (defaultValue.present) {
      map['default_value'] = Variable<int>(defaultValue.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpecificationsCompanion(')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('specIndex: $specIndex, ')
          ..write('name: $name, ')
          ..write('minValue: $minValue, ')
          ..write('maxValue: $maxValue, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, UnitEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _unitStringMeta =
      const VerificationMeta('unitString');
  @override
  late final GeneratedColumn<String> unitString = GeneratedColumn<String>(
      'unit_string', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, unitString];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units';
  @override
  VerificationContext validateIntegrity(Insertable<UnitEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('unit_string')) {
      context.handle(
          _unitStringMeta,
          unitString.isAcceptableOrUnknown(
              data['unit_string']!, _unitStringMeta));
    } else if (isInserting) {
      context.missing(_unitStringMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnitEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnitEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      unitString: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit_string'])!,
    );
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(attachedDatabase, alias);
  }
}

class UnitEntry extends DataClass implements Insertable<UnitEntry> {
  final int id;
  final String unitString;
  const UnitEntry({required this.id, required this.unitString});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['unit_string'] = Variable<String>(unitString);
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      unitString: Value(unitString),
    );
  }

  factory UnitEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnitEntry(
      id: serializer.fromJson<int>(json['id']),
      unitString: serializer.fromJson<String>(json['unitString']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'unitString': serializer.toJson<String>(unitString),
    };
  }

  UnitEntry copyWith({int? id, String? unitString}) => UnitEntry(
        id: id ?? this.id,
        unitString: unitString ?? this.unitString,
      );
  UnitEntry copyWithCompanion(UnitsCompanion data) {
    return UnitEntry(
      id: data.id.present ? data.id.value : this.id,
      unitString:
          data.unitString.present ? data.unitString.value : this.unitString,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnitEntry(')
          ..write('id: $id, ')
          ..write('unitString: $unitString')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, unitString);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnitEntry &&
          other.id == this.id &&
          other.unitString == this.unitString);
}

class UnitsCompanion extends UpdateCompanion<UnitEntry> {
  final Value<int> id;
  final Value<String> unitString;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.unitString = const Value.absent(),
  });
  UnitsCompanion.insert({
    this.id = const Value.absent(),
    required String unitString,
  }) : unitString = Value(unitString);
  static Insertable<UnitEntry> custom({
    Expression<int>? id,
    Expression<String>? unitString,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (unitString != null) 'unit_string': unitString,
    });
  }

  UnitsCompanion copyWith({Value<int>? id, Value<String>? unitString}) {
    return UnitsCompanion(
      id: id ?? this.id,
      unitString: unitString ?? this.unitString,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (unitString.present) {
      map['unit_string'] = Variable<String>(unitString.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('unitString: $unitString')
          ..write(')'))
        .toString();
  }
}

class $ParametersTable extends Parameters
    with TableInfo<$ParametersTable, ParameterEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParametersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _algorithmGuidMeta =
      const VerificationMeta('algorithmGuid');
  @override
  late final GeneratedColumn<String> algorithmGuid = GeneratedColumn<String>(
      'algorithm_guid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES algorithms (guid)'));
  static const VerificationMeta _parameterNumberMeta =
      const VerificationMeta('parameterNumber');
  @override
  late final GeneratedColumn<int> parameterNumber = GeneratedColumn<int>(
      'parameter_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minValueMeta =
      const VerificationMeta('minValue');
  @override
  late final GeneratedColumn<int> minValue = GeneratedColumn<int>(
      'min_value', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _maxValueMeta =
      const VerificationMeta('maxValue');
  @override
  late final GeneratedColumn<int> maxValue = GeneratedColumn<int>(
      'max_value', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _defaultValueMeta =
      const VerificationMeta('defaultValue');
  @override
  late final GeneratedColumn<int> defaultValue = GeneratedColumn<int>(
      'default_value', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<int> unitId = GeneratedColumn<int>(
      'unit_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES units (id)'));
  static const VerificationMeta _powerOfTenMeta =
      const VerificationMeta('powerOfTen');
  @override
  late final GeneratedColumn<int> powerOfTen = GeneratedColumn<int>(
      'power_of_ten', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _rawUnitIndexMeta =
      const VerificationMeta('rawUnitIndex');
  @override
  late final GeneratedColumn<int> rawUnitIndex = GeneratedColumn<int>(
      'raw_unit_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        algorithmGuid,
        parameterNumber,
        name,
        minValue,
        maxValue,
        defaultValue,
        unitId,
        powerOfTen,
        rawUnitIndex
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parameters';
  @override
  VerificationContext validateIntegrity(Insertable<ParameterEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('algorithm_guid')) {
      context.handle(
          _algorithmGuidMeta,
          algorithmGuid.isAcceptableOrUnknown(
              data['algorithm_guid']!, _algorithmGuidMeta));
    } else if (isInserting) {
      context.missing(_algorithmGuidMeta);
    }
    if (data.containsKey('parameter_number')) {
      context.handle(
          _parameterNumberMeta,
          parameterNumber.isAcceptableOrUnknown(
              data['parameter_number']!, _parameterNumberMeta));
    } else if (isInserting) {
      context.missing(_parameterNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('min_value')) {
      context.handle(_minValueMeta,
          minValue.isAcceptableOrUnknown(data['min_value']!, _minValueMeta));
    }
    if (data.containsKey('max_value')) {
      context.handle(_maxValueMeta,
          maxValue.isAcceptableOrUnknown(data['max_value']!, _maxValueMeta));
    }
    if (data.containsKey('default_value')) {
      context.handle(
          _defaultValueMeta,
          defaultValue.isAcceptableOrUnknown(
              data['default_value']!, _defaultValueMeta));
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    }
    if (data.containsKey('power_of_ten')) {
      context.handle(
          _powerOfTenMeta,
          powerOfTen.isAcceptableOrUnknown(
              data['power_of_ten']!, _powerOfTenMeta));
    }
    if (data.containsKey('raw_unit_index')) {
      context.handle(
          _rawUnitIndexMeta,
          rawUnitIndex.isAcceptableOrUnknown(
              data['raw_unit_index']!, _rawUnitIndexMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {algorithmGuid, parameterNumber};
  @override
  ParameterEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParameterEntry(
      algorithmGuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}algorithm_guid'])!,
      parameterNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parameter_number'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      minValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}min_value']),
      maxValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_value']),
      defaultValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}default_value']),
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_id']),
      powerOfTen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}power_of_ten']),
      rawUnitIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}raw_unit_index']),
    );
  }

  @override
  $ParametersTable createAlias(String alias) {
    return $ParametersTable(attachedDatabase, alias);
  }
}

class ParameterEntry extends DataClass implements Insertable<ParameterEntry> {
  final String algorithmGuid;
  final int parameterNumber;
  final String name;
  final int? minValue;
  final int? maxValue;
  final int? defaultValue;
  final int? unitId;
  final int? powerOfTen;
  final int? rawUnitIndex;
  const ParameterEntry(
      {required this.algorithmGuid,
      required this.parameterNumber,
      required this.name,
      this.minValue,
      this.maxValue,
      this.defaultValue,
      this.unitId,
      this.powerOfTen,
      this.rawUnitIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['algorithm_guid'] = Variable<String>(algorithmGuid);
    map['parameter_number'] = Variable<int>(parameterNumber);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || minValue != null) {
      map['min_value'] = Variable<int>(minValue);
    }
    if (!nullToAbsent || maxValue != null) {
      map['max_value'] = Variable<int>(maxValue);
    }
    if (!nullToAbsent || defaultValue != null) {
      map['default_value'] = Variable<int>(defaultValue);
    }
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<int>(unitId);
    }
    if (!nullToAbsent || powerOfTen != null) {
      map['power_of_ten'] = Variable<int>(powerOfTen);
    }
    if (!nullToAbsent || rawUnitIndex != null) {
      map['raw_unit_index'] = Variable<int>(rawUnitIndex);
    }
    return map;
  }

  ParametersCompanion toCompanion(bool nullToAbsent) {
    return ParametersCompanion(
      algorithmGuid: Value(algorithmGuid),
      parameterNumber: Value(parameterNumber),
      name: Value(name),
      minValue: minValue == null && nullToAbsent
          ? const Value.absent()
          : Value(minValue),
      maxValue: maxValue == null && nullToAbsent
          ? const Value.absent()
          : Value(maxValue),
      defaultValue: defaultValue == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultValue),
      unitId:
          unitId == null && nullToAbsent ? const Value.absent() : Value(unitId),
      powerOfTen: powerOfTen == null && nullToAbsent
          ? const Value.absent()
          : Value(powerOfTen),
      rawUnitIndex: rawUnitIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(rawUnitIndex),
    );
  }

  factory ParameterEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParameterEntry(
      algorithmGuid: serializer.fromJson<String>(json['algorithmGuid']),
      parameterNumber: serializer.fromJson<int>(json['parameterNumber']),
      name: serializer.fromJson<String>(json['name']),
      minValue: serializer.fromJson<int?>(json['minValue']),
      maxValue: serializer.fromJson<int?>(json['maxValue']),
      defaultValue: serializer.fromJson<int?>(json['defaultValue']),
      unitId: serializer.fromJson<int?>(json['unitId']),
      powerOfTen: serializer.fromJson<int?>(json['powerOfTen']),
      rawUnitIndex: serializer.fromJson<int?>(json['rawUnitIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'algorithmGuid': serializer.toJson<String>(algorithmGuid),
      'parameterNumber': serializer.toJson<int>(parameterNumber),
      'name': serializer.toJson<String>(name),
      'minValue': serializer.toJson<int?>(minValue),
      'maxValue': serializer.toJson<int?>(maxValue),
      'defaultValue': serializer.toJson<int?>(defaultValue),
      'unitId': serializer.toJson<int?>(unitId),
      'powerOfTen': serializer.toJson<int?>(powerOfTen),
      'rawUnitIndex': serializer.toJson<int?>(rawUnitIndex),
    };
  }

  ParameterEntry copyWith(
          {String? algorithmGuid,
          int? parameterNumber,
          String? name,
          Value<int?> minValue = const Value.absent(),
          Value<int?> maxValue = const Value.absent(),
          Value<int?> defaultValue = const Value.absent(),
          Value<int?> unitId = const Value.absent(),
          Value<int?> powerOfTen = const Value.absent(),
          Value<int?> rawUnitIndex = const Value.absent()}) =>
      ParameterEntry(
        algorithmGuid: algorithmGuid ?? this.algorithmGuid,
        parameterNumber: parameterNumber ?? this.parameterNumber,
        name: name ?? this.name,
        minValue: minValue.present ? minValue.value : this.minValue,
        maxValue: maxValue.present ? maxValue.value : this.maxValue,
        defaultValue:
            defaultValue.present ? defaultValue.value : this.defaultValue,
        unitId: unitId.present ? unitId.value : this.unitId,
        powerOfTen: powerOfTen.present ? powerOfTen.value : this.powerOfTen,
        rawUnitIndex:
            rawUnitIndex.present ? rawUnitIndex.value : this.rawUnitIndex,
      );
  ParameterEntry copyWithCompanion(ParametersCompanion data) {
    return ParameterEntry(
      algorithmGuid: data.algorithmGuid.present
          ? data.algorithmGuid.value
          : this.algorithmGuid,
      parameterNumber: data.parameterNumber.present
          ? data.parameterNumber.value
          : this.parameterNumber,
      name: data.name.present ? data.name.value : this.name,
      minValue: data.minValue.present ? data.minValue.value : this.minValue,
      maxValue: data.maxValue.present ? data.maxValue.value : this.maxValue,
      defaultValue: data.defaultValue.present
          ? data.defaultValue.value
          : this.defaultValue,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
      powerOfTen:
          data.powerOfTen.present ? data.powerOfTen.value : this.powerOfTen,
      rawUnitIndex: data.rawUnitIndex.present
          ? data.rawUnitIndex.value
          : this.rawUnitIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParameterEntry(')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('name: $name, ')
          ..write('minValue: $minValue, ')
          ..write('maxValue: $maxValue, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('unitId: $unitId, ')
          ..write('powerOfTen: $powerOfTen, ')
          ..write('rawUnitIndex: $rawUnitIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(algorithmGuid, parameterNumber, name,
      minValue, maxValue, defaultValue, unitId, powerOfTen, rawUnitIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParameterEntry &&
          other.algorithmGuid == this.algorithmGuid &&
          other.parameterNumber == this.parameterNumber &&
          other.name == this.name &&
          other.minValue == this.minValue &&
          other.maxValue == this.maxValue &&
          other.defaultValue == this.defaultValue &&
          other.unitId == this.unitId &&
          other.powerOfTen == this.powerOfTen &&
          other.rawUnitIndex == this.rawUnitIndex);
}

class ParametersCompanion extends UpdateCompanion<ParameterEntry> {
  final Value<String> algorithmGuid;
  final Value<int> parameterNumber;
  final Value<String> name;
  final Value<int?> minValue;
  final Value<int?> maxValue;
  final Value<int?> defaultValue;
  final Value<int?> unitId;
  final Value<int?> powerOfTen;
  final Value<int?> rawUnitIndex;
  final Value<int> rowid;
  const ParametersCompanion({
    this.algorithmGuid = const Value.absent(),
    this.parameterNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.minValue = const Value.absent(),
    this.maxValue = const Value.absent(),
    this.defaultValue = const Value.absent(),
    this.unitId = const Value.absent(),
    this.powerOfTen = const Value.absent(),
    this.rawUnitIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParametersCompanion.insert({
    required String algorithmGuid,
    required int parameterNumber,
    required String name,
    this.minValue = const Value.absent(),
    this.maxValue = const Value.absent(),
    this.defaultValue = const Value.absent(),
    this.unitId = const Value.absent(),
    this.powerOfTen = const Value.absent(),
    this.rawUnitIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : algorithmGuid = Value(algorithmGuid),
        parameterNumber = Value(parameterNumber),
        name = Value(name);
  static Insertable<ParameterEntry> custom({
    Expression<String>? algorithmGuid,
    Expression<int>? parameterNumber,
    Expression<String>? name,
    Expression<int>? minValue,
    Expression<int>? maxValue,
    Expression<int>? defaultValue,
    Expression<int>? unitId,
    Expression<int>? powerOfTen,
    Expression<int>? rawUnitIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (algorithmGuid != null) 'algorithm_guid': algorithmGuid,
      if (parameterNumber != null) 'parameter_number': parameterNumber,
      if (name != null) 'name': name,
      if (minValue != null) 'min_value': minValue,
      if (maxValue != null) 'max_value': maxValue,
      if (defaultValue != null) 'default_value': defaultValue,
      if (unitId != null) 'unit_id': unitId,
      if (powerOfTen != null) 'power_of_ten': powerOfTen,
      if (rawUnitIndex != null) 'raw_unit_index': rawUnitIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParametersCompanion copyWith(
      {Value<String>? algorithmGuid,
      Value<int>? parameterNumber,
      Value<String>? name,
      Value<int?>? minValue,
      Value<int?>? maxValue,
      Value<int?>? defaultValue,
      Value<int?>? unitId,
      Value<int?>? powerOfTen,
      Value<int?>? rawUnitIndex,
      Value<int>? rowid}) {
    return ParametersCompanion(
      algorithmGuid: algorithmGuid ?? this.algorithmGuid,
      parameterNumber: parameterNumber ?? this.parameterNumber,
      name: name ?? this.name,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      defaultValue: defaultValue ?? this.defaultValue,
      unitId: unitId ?? this.unitId,
      powerOfTen: powerOfTen ?? this.powerOfTen,
      rawUnitIndex: rawUnitIndex ?? this.rawUnitIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (algorithmGuid.present) {
      map['algorithm_guid'] = Variable<String>(algorithmGuid.value);
    }
    if (parameterNumber.present) {
      map['parameter_number'] = Variable<int>(parameterNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (minValue.present) {
      map['min_value'] = Variable<int>(minValue.value);
    }
    if (maxValue.present) {
      map['max_value'] = Variable<int>(maxValue.value);
    }
    if (defaultValue.present) {
      map['default_value'] = Variable<int>(defaultValue.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<int>(unitId.value);
    }
    if (powerOfTen.present) {
      map['power_of_ten'] = Variable<int>(powerOfTen.value);
    }
    if (rawUnitIndex.present) {
      map['raw_unit_index'] = Variable<int>(rawUnitIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParametersCompanion(')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('name: $name, ')
          ..write('minValue: $minValue, ')
          ..write('maxValue: $maxValue, ')
          ..write('defaultValue: $defaultValue, ')
          ..write('unitId: $unitId, ')
          ..write('powerOfTen: $powerOfTen, ')
          ..write('rawUnitIndex: $rawUnitIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParameterEnumsTable extends ParameterEnums
    with TableInfo<$ParameterEnumsTable, ParameterEnumEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParameterEnumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _algorithmGuidMeta =
      const VerificationMeta('algorithmGuid');
  @override
  late final GeneratedColumn<String> algorithmGuid = GeneratedColumn<String>(
      'algorithm_guid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parameterNumberMeta =
      const VerificationMeta('parameterNumber');
  @override
  late final GeneratedColumn<int> parameterNumber = GeneratedColumn<int>(
      'parameter_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _enumIndexMeta =
      const VerificationMeta('enumIndex');
  @override
  late final GeneratedColumn<int> enumIndex = GeneratedColumn<int>(
      'enum_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _enumStringMeta =
      const VerificationMeta('enumString');
  @override
  late final GeneratedColumn<String> enumString = GeneratedColumn<String>(
      'enum_string', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [algorithmGuid, parameterNumber, enumIndex, enumString];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parameter_enums';
  @override
  VerificationContext validateIntegrity(Insertable<ParameterEnumEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('algorithm_guid')) {
      context.handle(
          _algorithmGuidMeta,
          algorithmGuid.isAcceptableOrUnknown(
              data['algorithm_guid']!, _algorithmGuidMeta));
    } else if (isInserting) {
      context.missing(_algorithmGuidMeta);
    }
    if (data.containsKey('parameter_number')) {
      context.handle(
          _parameterNumberMeta,
          parameterNumber.isAcceptableOrUnknown(
              data['parameter_number']!, _parameterNumberMeta));
    } else if (isInserting) {
      context.missing(_parameterNumberMeta);
    }
    if (data.containsKey('enum_index')) {
      context.handle(_enumIndexMeta,
          enumIndex.isAcceptableOrUnknown(data['enum_index']!, _enumIndexMeta));
    } else if (isInserting) {
      context.missing(_enumIndexMeta);
    }
    if (data.containsKey('enum_string')) {
      context.handle(
          _enumStringMeta,
          enumString.isAcceptableOrUnknown(
              data['enum_string']!, _enumStringMeta));
    } else if (isInserting) {
      context.missing(_enumStringMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey =>
      {algorithmGuid, parameterNumber, enumIndex};
  @override
  ParameterEnumEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParameterEnumEntry(
      algorithmGuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}algorithm_guid'])!,
      parameterNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parameter_number'])!,
      enumIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}enum_index'])!,
      enumString: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}enum_string'])!,
    );
  }

  @override
  $ParameterEnumsTable createAlias(String alias) {
    return $ParameterEnumsTable(attachedDatabase, alias);
  }
}

class ParameterEnumEntry extends DataClass
    implements Insertable<ParameterEnumEntry> {
  final String algorithmGuid;
  final int parameterNumber;
  final int enumIndex;
  final String enumString;
  const ParameterEnumEntry(
      {required this.algorithmGuid,
      required this.parameterNumber,
      required this.enumIndex,
      required this.enumString});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['algorithm_guid'] = Variable<String>(algorithmGuid);
    map['parameter_number'] = Variable<int>(parameterNumber);
    map['enum_index'] = Variable<int>(enumIndex);
    map['enum_string'] = Variable<String>(enumString);
    return map;
  }

  ParameterEnumsCompanion toCompanion(bool nullToAbsent) {
    return ParameterEnumsCompanion(
      algorithmGuid: Value(algorithmGuid),
      parameterNumber: Value(parameterNumber),
      enumIndex: Value(enumIndex),
      enumString: Value(enumString),
    );
  }

  factory ParameterEnumEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParameterEnumEntry(
      algorithmGuid: serializer.fromJson<String>(json['algorithmGuid']),
      parameterNumber: serializer.fromJson<int>(json['parameterNumber']),
      enumIndex: serializer.fromJson<int>(json['enumIndex']),
      enumString: serializer.fromJson<String>(json['enumString']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'algorithmGuid': serializer.toJson<String>(algorithmGuid),
      'parameterNumber': serializer.toJson<int>(parameterNumber),
      'enumIndex': serializer.toJson<int>(enumIndex),
      'enumString': serializer.toJson<String>(enumString),
    };
  }

  ParameterEnumEntry copyWith(
          {String? algorithmGuid,
          int? parameterNumber,
          int? enumIndex,
          String? enumString}) =>
      ParameterEnumEntry(
        algorithmGuid: algorithmGuid ?? this.algorithmGuid,
        parameterNumber: parameterNumber ?? this.parameterNumber,
        enumIndex: enumIndex ?? this.enumIndex,
        enumString: enumString ?? this.enumString,
      );
  ParameterEnumEntry copyWithCompanion(ParameterEnumsCompanion data) {
    return ParameterEnumEntry(
      algorithmGuid: data.algorithmGuid.present
          ? data.algorithmGuid.value
          : this.algorithmGuid,
      parameterNumber: data.parameterNumber.present
          ? data.parameterNumber.value
          : this.parameterNumber,
      enumIndex: data.enumIndex.present ? data.enumIndex.value : this.enumIndex,
      enumString:
          data.enumString.present ? data.enumString.value : this.enumString,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParameterEnumEntry(')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('enumIndex: $enumIndex, ')
          ..write('enumString: $enumString')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(algorithmGuid, parameterNumber, enumIndex, enumString);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParameterEnumEntry &&
          other.algorithmGuid == this.algorithmGuid &&
          other.parameterNumber == this.parameterNumber &&
          other.enumIndex == this.enumIndex &&
          other.enumString == this.enumString);
}

class ParameterEnumsCompanion extends UpdateCompanion<ParameterEnumEntry> {
  final Value<String> algorithmGuid;
  final Value<int> parameterNumber;
  final Value<int> enumIndex;
  final Value<String> enumString;
  final Value<int> rowid;
  const ParameterEnumsCompanion({
    this.algorithmGuid = const Value.absent(),
    this.parameterNumber = const Value.absent(),
    this.enumIndex = const Value.absent(),
    this.enumString = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParameterEnumsCompanion.insert({
    required String algorithmGuid,
    required int parameterNumber,
    required int enumIndex,
    required String enumString,
    this.rowid = const Value.absent(),
  })  : algorithmGuid = Value(algorithmGuid),
        parameterNumber = Value(parameterNumber),
        enumIndex = Value(enumIndex),
        enumString = Value(enumString);
  static Insertable<ParameterEnumEntry> custom({
    Expression<String>? algorithmGuid,
    Expression<int>? parameterNumber,
    Expression<int>? enumIndex,
    Expression<String>? enumString,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (algorithmGuid != null) 'algorithm_guid': algorithmGuid,
      if (parameterNumber != null) 'parameter_number': parameterNumber,
      if (enumIndex != null) 'enum_index': enumIndex,
      if (enumString != null) 'enum_string': enumString,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParameterEnumsCompanion copyWith(
      {Value<String>? algorithmGuid,
      Value<int>? parameterNumber,
      Value<int>? enumIndex,
      Value<String>? enumString,
      Value<int>? rowid}) {
    return ParameterEnumsCompanion(
      algorithmGuid: algorithmGuid ?? this.algorithmGuid,
      parameterNumber: parameterNumber ?? this.parameterNumber,
      enumIndex: enumIndex ?? this.enumIndex,
      enumString: enumString ?? this.enumString,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (algorithmGuid.present) {
      map['algorithm_guid'] = Variable<String>(algorithmGuid.value);
    }
    if (parameterNumber.present) {
      map['parameter_number'] = Variable<int>(parameterNumber.value);
    }
    if (enumIndex.present) {
      map['enum_index'] = Variable<int>(enumIndex.value);
    }
    if (enumString.present) {
      map['enum_string'] = Variable<String>(enumString.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParameterEnumsCompanion(')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('enumIndex: $enumIndex, ')
          ..write('enumString: $enumString, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParameterPagesTable extends ParameterPages
    with TableInfo<$ParameterPagesTable, ParameterPageEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParameterPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _algorithmGuidMeta =
      const VerificationMeta('algorithmGuid');
  @override
  late final GeneratedColumn<String> algorithmGuid = GeneratedColumn<String>(
      'algorithm_guid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES algorithms (guid)'));
  static const VerificationMeta _pageIndexMeta =
      const VerificationMeta('pageIndex');
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
      'page_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [algorithmGuid, pageIndex, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parameter_pages';
  @override
  VerificationContext validateIntegrity(Insertable<ParameterPageEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('algorithm_guid')) {
      context.handle(
          _algorithmGuidMeta,
          algorithmGuid.isAcceptableOrUnknown(
              data['algorithm_guid']!, _algorithmGuidMeta));
    } else if (isInserting) {
      context.missing(_algorithmGuidMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(_pageIndexMeta,
          pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta));
    } else if (isInserting) {
      context.missing(_pageIndexMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {algorithmGuid, pageIndex};
  @override
  ParameterPageEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParameterPageEntry(
      algorithmGuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}algorithm_guid'])!,
      pageIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_index'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $ParameterPagesTable createAlias(String alias) {
    return $ParameterPagesTable(attachedDatabase, alias);
  }
}

class ParameterPageEntry extends DataClass
    implements Insertable<ParameterPageEntry> {
  final String algorithmGuid;
  final int pageIndex;
  final String name;
  const ParameterPageEntry(
      {required this.algorithmGuid,
      required this.pageIndex,
      required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['algorithm_guid'] = Variable<String>(algorithmGuid);
    map['page_index'] = Variable<int>(pageIndex);
    map['name'] = Variable<String>(name);
    return map;
  }

  ParameterPagesCompanion toCompanion(bool nullToAbsent) {
    return ParameterPagesCompanion(
      algorithmGuid: Value(algorithmGuid),
      pageIndex: Value(pageIndex),
      name: Value(name),
    );
  }

  factory ParameterPageEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParameterPageEntry(
      algorithmGuid: serializer.fromJson<String>(json['algorithmGuid']),
      pageIndex: serializer.fromJson<int>(json['pageIndex']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'algorithmGuid': serializer.toJson<String>(algorithmGuid),
      'pageIndex': serializer.toJson<int>(pageIndex),
      'name': serializer.toJson<String>(name),
    };
  }

  ParameterPageEntry copyWith(
          {String? algorithmGuid, int? pageIndex, String? name}) =>
      ParameterPageEntry(
        algorithmGuid: algorithmGuid ?? this.algorithmGuid,
        pageIndex: pageIndex ?? this.pageIndex,
        name: name ?? this.name,
      );
  ParameterPageEntry copyWithCompanion(ParameterPagesCompanion data) {
    return ParameterPageEntry(
      algorithmGuid: data.algorithmGuid.present
          ? data.algorithmGuid.value
          : this.algorithmGuid,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParameterPageEntry(')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(algorithmGuid, pageIndex, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParameterPageEntry &&
          other.algorithmGuid == this.algorithmGuid &&
          other.pageIndex == this.pageIndex &&
          other.name == this.name);
}

class ParameterPagesCompanion extends UpdateCompanion<ParameterPageEntry> {
  final Value<String> algorithmGuid;
  final Value<int> pageIndex;
  final Value<String> name;
  final Value<int> rowid;
  const ParameterPagesCompanion({
    this.algorithmGuid = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParameterPagesCompanion.insert({
    required String algorithmGuid,
    required int pageIndex,
    required String name,
    this.rowid = const Value.absent(),
  })  : algorithmGuid = Value(algorithmGuid),
        pageIndex = Value(pageIndex),
        name = Value(name);
  static Insertable<ParameterPageEntry> custom({
    Expression<String>? algorithmGuid,
    Expression<int>? pageIndex,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (algorithmGuid != null) 'algorithm_guid': algorithmGuid,
      if (pageIndex != null) 'page_index': pageIndex,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParameterPagesCompanion copyWith(
      {Value<String>? algorithmGuid,
      Value<int>? pageIndex,
      Value<String>? name,
      Value<int>? rowid}) {
    return ParameterPagesCompanion(
      algorithmGuid: algorithmGuid ?? this.algorithmGuid,
      pageIndex: pageIndex ?? this.pageIndex,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (algorithmGuid.present) {
      map['algorithm_guid'] = Variable<String>(algorithmGuid.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParameterPagesCompanion(')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParameterPageItemsTable extends ParameterPageItems
    with TableInfo<$ParameterPageItemsTable, ParameterPageItemEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParameterPageItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _algorithmGuidMeta =
      const VerificationMeta('algorithmGuid');
  @override
  late final GeneratedColumn<String> algorithmGuid = GeneratedColumn<String>(
      'algorithm_guid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageIndexMeta =
      const VerificationMeta('pageIndex');
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
      'page_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _parameterNumberMeta =
      const VerificationMeta('parameterNumber');
  @override
  late final GeneratedColumn<int> parameterNumber = GeneratedColumn<int>(
      'parameter_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [algorithmGuid, pageIndex, parameterNumber];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parameter_page_items';
  @override
  VerificationContext validateIntegrity(
      Insertable<ParameterPageItemEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('algorithm_guid')) {
      context.handle(
          _algorithmGuidMeta,
          algorithmGuid.isAcceptableOrUnknown(
              data['algorithm_guid']!, _algorithmGuidMeta));
    } else if (isInserting) {
      context.missing(_algorithmGuidMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(_pageIndexMeta,
          pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta));
    } else if (isInserting) {
      context.missing(_pageIndexMeta);
    }
    if (data.containsKey('parameter_number')) {
      context.handle(
          _parameterNumberMeta,
          parameterNumber.isAcceptableOrUnknown(
              data['parameter_number']!, _parameterNumberMeta));
    } else if (isInserting) {
      context.missing(_parameterNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey =>
      {algorithmGuid, pageIndex, parameterNumber};
  @override
  ParameterPageItemEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParameterPageItemEntry(
      algorithmGuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}algorithm_guid'])!,
      pageIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_index'])!,
      parameterNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parameter_number'])!,
    );
  }

  @override
  $ParameterPageItemsTable createAlias(String alias) {
    return $ParameterPageItemsTable(attachedDatabase, alias);
  }
}

class ParameterPageItemEntry extends DataClass
    implements Insertable<ParameterPageItemEntry> {
  final String algorithmGuid;
  final int pageIndex;
  final int parameterNumber;
  const ParameterPageItemEntry(
      {required this.algorithmGuid,
      required this.pageIndex,
      required this.parameterNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['algorithm_guid'] = Variable<String>(algorithmGuid);
    map['page_index'] = Variable<int>(pageIndex);
    map['parameter_number'] = Variable<int>(parameterNumber);
    return map;
  }

  ParameterPageItemsCompanion toCompanion(bool nullToAbsent) {
    return ParameterPageItemsCompanion(
      algorithmGuid: Value(algorithmGuid),
      pageIndex: Value(pageIndex),
      parameterNumber: Value(parameterNumber),
    );
  }

  factory ParameterPageItemEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParameterPageItemEntry(
      algorithmGuid: serializer.fromJson<String>(json['algorithmGuid']),
      pageIndex: serializer.fromJson<int>(json['pageIndex']),
      parameterNumber: serializer.fromJson<int>(json['parameterNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'algorithmGuid': serializer.toJson<String>(algorithmGuid),
      'pageIndex': serializer.toJson<int>(pageIndex),
      'parameterNumber': serializer.toJson<int>(parameterNumber),
    };
  }

  ParameterPageItemEntry copyWith(
          {String? algorithmGuid, int? pageIndex, int? parameterNumber}) =>
      ParameterPageItemEntry(
        algorithmGuid: algorithmGuid ?? this.algorithmGuid,
        pageIndex: pageIndex ?? this.pageIndex,
        parameterNumber: parameterNumber ?? this.parameterNumber,
      );
  ParameterPageItemEntry copyWithCompanion(ParameterPageItemsCompanion data) {
    return ParameterPageItemEntry(
      algorithmGuid: data.algorithmGuid.present
          ? data.algorithmGuid.value
          : this.algorithmGuid,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      parameterNumber: data.parameterNumber.present
          ? data.parameterNumber.value
          : this.parameterNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParameterPageItemEntry(')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('parameterNumber: $parameterNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(algorithmGuid, pageIndex, parameterNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParameterPageItemEntry &&
          other.algorithmGuid == this.algorithmGuid &&
          other.pageIndex == this.pageIndex &&
          other.parameterNumber == this.parameterNumber);
}

class ParameterPageItemsCompanion
    extends UpdateCompanion<ParameterPageItemEntry> {
  final Value<String> algorithmGuid;
  final Value<int> pageIndex;
  final Value<int> parameterNumber;
  final Value<int> rowid;
  const ParameterPageItemsCompanion({
    this.algorithmGuid = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.parameterNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParameterPageItemsCompanion.insert({
    required String algorithmGuid,
    required int pageIndex,
    required int parameterNumber,
    this.rowid = const Value.absent(),
  })  : algorithmGuid = Value(algorithmGuid),
        pageIndex = Value(pageIndex),
        parameterNumber = Value(parameterNumber);
  static Insertable<ParameterPageItemEntry> custom({
    Expression<String>? algorithmGuid,
    Expression<int>? pageIndex,
    Expression<int>? parameterNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (algorithmGuid != null) 'algorithm_guid': algorithmGuid,
      if (pageIndex != null) 'page_index': pageIndex,
      if (parameterNumber != null) 'parameter_number': parameterNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParameterPageItemsCompanion copyWith(
      {Value<String>? algorithmGuid,
      Value<int>? pageIndex,
      Value<int>? parameterNumber,
      Value<int>? rowid}) {
    return ParameterPageItemsCompanion(
      algorithmGuid: algorithmGuid ?? this.algorithmGuid,
      pageIndex: pageIndex ?? this.pageIndex,
      parameterNumber: parameterNumber ?? this.parameterNumber,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (algorithmGuid.present) {
      map['algorithm_guid'] = Variable<String>(algorithmGuid.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (parameterNumber.present) {
      map['parameter_number'] = Variable<int>(parameterNumber.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParameterPageItemsCompanion(')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PresetsTable extends Presets with TableInfo<$PresetsTable, PresetEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, lastModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'presets';
  @override
  VerificationContext validateIntegrity(Insertable<PresetEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PresetEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresetEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
    );
  }

  @override
  $PresetsTable createAlias(String alias) {
    return $PresetsTable(attachedDatabase, alias);
  }
}

class PresetEntry extends DataClass implements Insertable<PresetEntry> {
  final int id;
  final String name;
  final DateTime lastModified;
  const PresetEntry(
      {required this.id, required this.name, required this.lastModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['last_modified'] = Variable<DateTime>(lastModified);
    return map;
  }

  PresetsCompanion toCompanion(bool nullToAbsent) {
    return PresetsCompanion(
      id: Value(id),
      name: Value(name),
      lastModified: Value(lastModified),
    );
  }

  factory PresetEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresetEntry(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'lastModified': serializer.toJson<DateTime>(lastModified),
    };
  }

  PresetEntry copyWith({int? id, String? name, DateTime? lastModified}) =>
      PresetEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        lastModified: lastModified ?? this.lastModified,
      );
  PresetEntry copyWithCompanion(PresetsCompanion data) {
    return PresetEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresetEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, lastModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresetEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.lastModified == this.lastModified);
}

class PresetsCompanion extends UpdateCompanion<PresetEntry> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> lastModified;
  const PresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.lastModified = const Value.absent(),
  });
  PresetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.lastModified = const Value.absent(),
  }) : name = Value(name);
  static Insertable<PresetEntry> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? lastModified,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (lastModified != null) 'last_modified': lastModified,
    });
  }

  PresetsCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<DateTime>? lastModified}) {
    return PresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('lastModified: $lastModified')
          ..write(')'))
        .toString();
  }
}

class $PresetSlotsTable extends PresetSlots
    with TableInfo<$PresetSlotsTable, PresetSlotEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresetSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _presetIdMeta =
      const VerificationMeta('presetId');
  @override
  late final GeneratedColumn<int> presetId = GeneratedColumn<int>(
      'preset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES presets (id)'));
  static const VerificationMeta _slotIndexMeta =
      const VerificationMeta('slotIndex');
  @override
  late final GeneratedColumn<int> slotIndex = GeneratedColumn<int>(
      'slot_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _algorithmGuidMeta =
      const VerificationMeta('algorithmGuid');
  @override
  late final GeneratedColumn<String> algorithmGuid = GeneratedColumn<String>(
      'algorithm_guid', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES algorithms (guid)'));
  static const VerificationMeta _customNameMeta =
      const VerificationMeta('customName');
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
      'custom_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, presetId, slotIndex, algorithmGuid, customName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preset_slots';
  @override
  VerificationContext validateIntegrity(Insertable<PresetSlotEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('preset_id')) {
      context.handle(_presetIdMeta,
          presetId.isAcceptableOrUnknown(data['preset_id']!, _presetIdMeta));
    } else if (isInserting) {
      context.missing(_presetIdMeta);
    }
    if (data.containsKey('slot_index')) {
      context.handle(_slotIndexMeta,
          slotIndex.isAcceptableOrUnknown(data['slot_index']!, _slotIndexMeta));
    } else if (isInserting) {
      context.missing(_slotIndexMeta);
    }
    if (data.containsKey('algorithm_guid')) {
      context.handle(
          _algorithmGuidMeta,
          algorithmGuid.isAcceptableOrUnknown(
              data['algorithm_guid']!, _algorithmGuidMeta));
    } else if (isInserting) {
      context.missing(_algorithmGuidMeta);
    }
    if (data.containsKey('custom_name')) {
      context.handle(
          _customNameMeta,
          customName.isAcceptableOrUnknown(
              data['custom_name']!, _customNameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PresetSlotEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresetSlotEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      presetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}preset_id'])!,
      slotIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}slot_index'])!,
      algorithmGuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}algorithm_guid'])!,
      customName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_name']),
    );
  }

  @override
  $PresetSlotsTable createAlias(String alias) {
    return $PresetSlotsTable(attachedDatabase, alias);
  }
}

class PresetSlotEntry extends DataClass implements Insertable<PresetSlotEntry> {
  final int id;
  final int presetId;
  final int slotIndex;
  final String algorithmGuid;
  final String? customName;
  const PresetSlotEntry(
      {required this.id,
      required this.presetId,
      required this.slotIndex,
      required this.algorithmGuid,
      this.customName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['preset_id'] = Variable<int>(presetId);
    map['slot_index'] = Variable<int>(slotIndex);
    map['algorithm_guid'] = Variable<String>(algorithmGuid);
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    return map;
  }

  PresetSlotsCompanion toCompanion(bool nullToAbsent) {
    return PresetSlotsCompanion(
      id: Value(id),
      presetId: Value(presetId),
      slotIndex: Value(slotIndex),
      algorithmGuid: Value(algorithmGuid),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
    );
  }

  factory PresetSlotEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresetSlotEntry(
      id: serializer.fromJson<int>(json['id']),
      presetId: serializer.fromJson<int>(json['presetId']),
      slotIndex: serializer.fromJson<int>(json['slotIndex']),
      algorithmGuid: serializer.fromJson<String>(json['algorithmGuid']),
      customName: serializer.fromJson<String?>(json['customName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'presetId': serializer.toJson<int>(presetId),
      'slotIndex': serializer.toJson<int>(slotIndex),
      'algorithmGuid': serializer.toJson<String>(algorithmGuid),
      'customName': serializer.toJson<String?>(customName),
    };
  }

  PresetSlotEntry copyWith(
          {int? id,
          int? presetId,
          int? slotIndex,
          String? algorithmGuid,
          Value<String?> customName = const Value.absent()}) =>
      PresetSlotEntry(
        id: id ?? this.id,
        presetId: presetId ?? this.presetId,
        slotIndex: slotIndex ?? this.slotIndex,
        algorithmGuid: algorithmGuid ?? this.algorithmGuid,
        customName: customName.present ? customName.value : this.customName,
      );
  PresetSlotEntry copyWithCompanion(PresetSlotsCompanion data) {
    return PresetSlotEntry(
      id: data.id.present ? data.id.value : this.id,
      presetId: data.presetId.present ? data.presetId.value : this.presetId,
      slotIndex: data.slotIndex.present ? data.slotIndex.value : this.slotIndex,
      algorithmGuid: data.algorithmGuid.present
          ? data.algorithmGuid.value
          : this.algorithmGuid,
      customName:
          data.customName.present ? data.customName.value : this.customName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresetSlotEntry(')
          ..write('id: $id, ')
          ..write('presetId: $presetId, ')
          ..write('slotIndex: $slotIndex, ')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('customName: $customName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, presetId, slotIndex, algorithmGuid, customName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresetSlotEntry &&
          other.id == this.id &&
          other.presetId == this.presetId &&
          other.slotIndex == this.slotIndex &&
          other.algorithmGuid == this.algorithmGuid &&
          other.customName == this.customName);
}

class PresetSlotsCompanion extends UpdateCompanion<PresetSlotEntry> {
  final Value<int> id;
  final Value<int> presetId;
  final Value<int> slotIndex;
  final Value<String> algorithmGuid;
  final Value<String?> customName;
  const PresetSlotsCompanion({
    this.id = const Value.absent(),
    this.presetId = const Value.absent(),
    this.slotIndex = const Value.absent(),
    this.algorithmGuid = const Value.absent(),
    this.customName = const Value.absent(),
  });
  PresetSlotsCompanion.insert({
    this.id = const Value.absent(),
    required int presetId,
    required int slotIndex,
    required String algorithmGuid,
    this.customName = const Value.absent(),
  })  : presetId = Value(presetId),
        slotIndex = Value(slotIndex),
        algorithmGuid = Value(algorithmGuid);
  static Insertable<PresetSlotEntry> custom({
    Expression<int>? id,
    Expression<int>? presetId,
    Expression<int>? slotIndex,
    Expression<String>? algorithmGuid,
    Expression<String>? customName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (presetId != null) 'preset_id': presetId,
      if (slotIndex != null) 'slot_index': slotIndex,
      if (algorithmGuid != null) 'algorithm_guid': algorithmGuid,
      if (customName != null) 'custom_name': customName,
    });
  }

  PresetSlotsCompanion copyWith(
      {Value<int>? id,
      Value<int>? presetId,
      Value<int>? slotIndex,
      Value<String>? algorithmGuid,
      Value<String?>? customName}) {
    return PresetSlotsCompanion(
      id: id ?? this.id,
      presetId: presetId ?? this.presetId,
      slotIndex: slotIndex ?? this.slotIndex,
      algorithmGuid: algorithmGuid ?? this.algorithmGuid,
      customName: customName ?? this.customName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (presetId.present) {
      map['preset_id'] = Variable<int>(presetId.value);
    }
    if (slotIndex.present) {
      map['slot_index'] = Variable<int>(slotIndex.value);
    }
    if (algorithmGuid.present) {
      map['algorithm_guid'] = Variable<String>(algorithmGuid.value);
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresetSlotsCompanion(')
          ..write('id: $id, ')
          ..write('presetId: $presetId, ')
          ..write('slotIndex: $slotIndex, ')
          ..write('algorithmGuid: $algorithmGuid, ')
          ..write('customName: $customName')
          ..write(')'))
        .toString();
  }
}

class $PresetParameterValuesTable extends PresetParameterValues
    with TableInfo<$PresetParameterValuesTable, PresetParameterValueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresetParameterValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _presetSlotIdMeta =
      const VerificationMeta('presetSlotId');
  @override
  late final GeneratedColumn<int> presetSlotId = GeneratedColumn<int>(
      'preset_slot_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES preset_slots (id) ON DELETE CASCADE'));
  static const VerificationMeta _parameterNumberMeta =
      const VerificationMeta('parameterNumber');
  @override
  late final GeneratedColumn<int> parameterNumber = GeneratedColumn<int>(
      'parameter_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
      'value', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, presetSlotId, parameterNumber, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preset_parameter_values';
  @override
  VerificationContext validateIntegrity(
      Insertable<PresetParameterValueEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('preset_slot_id')) {
      context.handle(
          _presetSlotIdMeta,
          presetSlotId.isAcceptableOrUnknown(
              data['preset_slot_id']!, _presetSlotIdMeta));
    } else if (isInserting) {
      context.missing(_presetSlotIdMeta);
    }
    if (data.containsKey('parameter_number')) {
      context.handle(
          _parameterNumberMeta,
          parameterNumber.isAcceptableOrUnknown(
              data['parameter_number']!, _parameterNumberMeta));
    } else if (isInserting) {
      context.missing(_parameterNumberMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PresetParameterValueEntry map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresetParameterValueEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      presetSlotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}preset_slot_id'])!,
      parameterNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parameter_number'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $PresetParameterValuesTable createAlias(String alias) {
    return $PresetParameterValuesTable(attachedDatabase, alias);
  }
}

class PresetParameterValueEntry extends DataClass
    implements Insertable<PresetParameterValueEntry> {
  final int id;
  final int presetSlotId;
  final int parameterNumber;
  final int value;
  const PresetParameterValueEntry(
      {required this.id,
      required this.presetSlotId,
      required this.parameterNumber,
      required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['preset_slot_id'] = Variable<int>(presetSlotId);
    map['parameter_number'] = Variable<int>(parameterNumber);
    map['value'] = Variable<int>(value);
    return map;
  }

  PresetParameterValuesCompanion toCompanion(bool nullToAbsent) {
    return PresetParameterValuesCompanion(
      id: Value(id),
      presetSlotId: Value(presetSlotId),
      parameterNumber: Value(parameterNumber),
      value: Value(value),
    );
  }

  factory PresetParameterValueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresetParameterValueEntry(
      id: serializer.fromJson<int>(json['id']),
      presetSlotId: serializer.fromJson<int>(json['presetSlotId']),
      parameterNumber: serializer.fromJson<int>(json['parameterNumber']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'presetSlotId': serializer.toJson<int>(presetSlotId),
      'parameterNumber': serializer.toJson<int>(parameterNumber),
      'value': serializer.toJson<int>(value),
    };
  }

  PresetParameterValueEntry copyWith(
          {int? id, int? presetSlotId, int? parameterNumber, int? value}) =>
      PresetParameterValueEntry(
        id: id ?? this.id,
        presetSlotId: presetSlotId ?? this.presetSlotId,
        parameterNumber: parameterNumber ?? this.parameterNumber,
        value: value ?? this.value,
      );
  PresetParameterValueEntry copyWithCompanion(
      PresetParameterValuesCompanion data) {
    return PresetParameterValueEntry(
      id: data.id.present ? data.id.value : this.id,
      presetSlotId: data.presetSlotId.present
          ? data.presetSlotId.value
          : this.presetSlotId,
      parameterNumber: data.parameterNumber.present
          ? data.parameterNumber.value
          : this.parameterNumber,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresetParameterValueEntry(')
          ..write('id: $id, ')
          ..write('presetSlotId: $presetSlotId, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, presetSlotId, parameterNumber, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresetParameterValueEntry &&
          other.id == this.id &&
          other.presetSlotId == this.presetSlotId &&
          other.parameterNumber == this.parameterNumber &&
          other.value == this.value);
}

class PresetParameterValuesCompanion
    extends UpdateCompanion<PresetParameterValueEntry> {
  final Value<int> id;
  final Value<int> presetSlotId;
  final Value<int> parameterNumber;
  final Value<int> value;
  const PresetParameterValuesCompanion({
    this.id = const Value.absent(),
    this.presetSlotId = const Value.absent(),
    this.parameterNumber = const Value.absent(),
    this.value = const Value.absent(),
  });
  PresetParameterValuesCompanion.insert({
    this.id = const Value.absent(),
    required int presetSlotId,
    required int parameterNumber,
    required int value,
  })  : presetSlotId = Value(presetSlotId),
        parameterNumber = Value(parameterNumber),
        value = Value(value);
  static Insertable<PresetParameterValueEntry> custom({
    Expression<int>? id,
    Expression<int>? presetSlotId,
    Expression<int>? parameterNumber,
    Expression<int>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (presetSlotId != null) 'preset_slot_id': presetSlotId,
      if (parameterNumber != null) 'parameter_number': parameterNumber,
      if (value != null) 'value': value,
    });
  }

  PresetParameterValuesCompanion copyWith(
      {Value<int>? id,
      Value<int>? presetSlotId,
      Value<int>? parameterNumber,
      Value<int>? value}) {
    return PresetParameterValuesCompanion(
      id: id ?? this.id,
      presetSlotId: presetSlotId ?? this.presetSlotId,
      parameterNumber: parameterNumber ?? this.parameterNumber,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (presetSlotId.present) {
      map['preset_slot_id'] = Variable<int>(presetSlotId.value);
    }
    if (parameterNumber.present) {
      map['parameter_number'] = Variable<int>(parameterNumber.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresetParameterValuesCompanion(')
          ..write('id: $id, ')
          ..write('presetSlotId: $presetSlotId, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $PresetParameterStringValuesTable extends PresetParameterStringValues
    with
        TableInfo<$PresetParameterStringValuesTable,
            PresetParameterStringValueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresetParameterStringValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _presetSlotIdMeta =
      const VerificationMeta('presetSlotId');
  @override
  late final GeneratedColumn<int> presetSlotId = GeneratedColumn<int>(
      'preset_slot_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES preset_slots (id) ON DELETE CASCADE'));
  static const VerificationMeta _parameterNumberMeta =
      const VerificationMeta('parameterNumber');
  @override
  late final GeneratedColumn<int> parameterNumber = GeneratedColumn<int>(
      'parameter_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _stringValueMeta =
      const VerificationMeta('stringValue');
  @override
  late final GeneratedColumn<String> stringValue = GeneratedColumn<String>(
      'string_value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [presetSlotId, parameterNumber, stringValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preset_parameter_string_values';
  @override
  VerificationContext validateIntegrity(
      Insertable<PresetParameterStringValueEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('preset_slot_id')) {
      context.handle(
          _presetSlotIdMeta,
          presetSlotId.isAcceptableOrUnknown(
              data['preset_slot_id']!, _presetSlotIdMeta));
    } else if (isInserting) {
      context.missing(_presetSlotIdMeta);
    }
    if (data.containsKey('parameter_number')) {
      context.handle(
          _parameterNumberMeta,
          parameterNumber.isAcceptableOrUnknown(
              data['parameter_number']!, _parameterNumberMeta));
    } else if (isInserting) {
      context.missing(_parameterNumberMeta);
    }
    if (data.containsKey('string_value')) {
      context.handle(
          _stringValueMeta,
          stringValue.isAcceptableOrUnknown(
              data['string_value']!, _stringValueMeta));
    } else if (isInserting) {
      context.missing(_stringValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {presetSlotId, parameterNumber};
  @override
  PresetParameterStringValueEntry map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresetParameterStringValueEntry(
      presetSlotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}preset_slot_id'])!,
      parameterNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parameter_number'])!,
      stringValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}string_value'])!,
    );
  }

  @override
  $PresetParameterStringValuesTable createAlias(String alias) {
    return $PresetParameterStringValuesTable(attachedDatabase, alias);
  }
}

class PresetParameterStringValueEntry extends DataClass
    implements Insertable<PresetParameterStringValueEntry> {
  final int presetSlotId;
  final int parameterNumber;
  final String stringValue;
  const PresetParameterStringValueEntry(
      {required this.presetSlotId,
      required this.parameterNumber,
      required this.stringValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['preset_slot_id'] = Variable<int>(presetSlotId);
    map['parameter_number'] = Variable<int>(parameterNumber);
    map['string_value'] = Variable<String>(stringValue);
    return map;
  }

  PresetParameterStringValuesCompanion toCompanion(bool nullToAbsent) {
    return PresetParameterStringValuesCompanion(
      presetSlotId: Value(presetSlotId),
      parameterNumber: Value(parameterNumber),
      stringValue: Value(stringValue),
    );
  }

  factory PresetParameterStringValueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresetParameterStringValueEntry(
      presetSlotId: serializer.fromJson<int>(json['presetSlotId']),
      parameterNumber: serializer.fromJson<int>(json['parameterNumber']),
      stringValue: serializer.fromJson<String>(json['stringValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'presetSlotId': serializer.toJson<int>(presetSlotId),
      'parameterNumber': serializer.toJson<int>(parameterNumber),
      'stringValue': serializer.toJson<String>(stringValue),
    };
  }

  PresetParameterStringValueEntry copyWith(
          {int? presetSlotId, int? parameterNumber, String? stringValue}) =>
      PresetParameterStringValueEntry(
        presetSlotId: presetSlotId ?? this.presetSlotId,
        parameterNumber: parameterNumber ?? this.parameterNumber,
        stringValue: stringValue ?? this.stringValue,
      );
  PresetParameterStringValueEntry copyWithCompanion(
      PresetParameterStringValuesCompanion data) {
    return PresetParameterStringValueEntry(
      presetSlotId: data.presetSlotId.present
          ? data.presetSlotId.value
          : this.presetSlotId,
      parameterNumber: data.parameterNumber.present
          ? data.parameterNumber.value
          : this.parameterNumber,
      stringValue:
          data.stringValue.present ? data.stringValue.value : this.stringValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresetParameterStringValueEntry(')
          ..write('presetSlotId: $presetSlotId, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('stringValue: $stringValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(presetSlotId, parameterNumber, stringValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresetParameterStringValueEntry &&
          other.presetSlotId == this.presetSlotId &&
          other.parameterNumber == this.parameterNumber &&
          other.stringValue == this.stringValue);
}

class PresetParameterStringValuesCompanion
    extends UpdateCompanion<PresetParameterStringValueEntry> {
  final Value<int> presetSlotId;
  final Value<int> parameterNumber;
  final Value<String> stringValue;
  final Value<int> rowid;
  const PresetParameterStringValuesCompanion({
    this.presetSlotId = const Value.absent(),
    this.parameterNumber = const Value.absent(),
    this.stringValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PresetParameterStringValuesCompanion.insert({
    required int presetSlotId,
    required int parameterNumber,
    required String stringValue,
    this.rowid = const Value.absent(),
  })  : presetSlotId = Value(presetSlotId),
        parameterNumber = Value(parameterNumber),
        stringValue = Value(stringValue);
  static Insertable<PresetParameterStringValueEntry> custom({
    Expression<int>? presetSlotId,
    Expression<int>? parameterNumber,
    Expression<String>? stringValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (presetSlotId != null) 'preset_slot_id': presetSlotId,
      if (parameterNumber != null) 'parameter_number': parameterNumber,
      if (stringValue != null) 'string_value': stringValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PresetParameterStringValuesCompanion copyWith(
      {Value<int>? presetSlotId,
      Value<int>? parameterNumber,
      Value<String>? stringValue,
      Value<int>? rowid}) {
    return PresetParameterStringValuesCompanion(
      presetSlotId: presetSlotId ?? this.presetSlotId,
      parameterNumber: parameterNumber ?? this.parameterNumber,
      stringValue: stringValue ?? this.stringValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (presetSlotId.present) {
      map['preset_slot_id'] = Variable<int>(presetSlotId.value);
    }
    if (parameterNumber.present) {
      map['parameter_number'] = Variable<int>(parameterNumber.value);
    }
    if (stringValue.present) {
      map['string_value'] = Variable<String>(stringValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresetParameterStringValuesCompanion(')
          ..write('presetSlotId: $presetSlotId, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('stringValue: $stringValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PresetMappingsTable extends PresetMappings
    with TableInfo<$PresetMappingsTable, PresetMappingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresetMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _presetSlotIdMeta =
      const VerificationMeta('presetSlotId');
  @override
  late final GeneratedColumn<int> presetSlotId = GeneratedColumn<int>(
      'preset_slot_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES preset_slots (id)'));
  static const VerificationMeta _parameterNumberMeta =
      const VerificationMeta('parameterNumber');
  @override
  late final GeneratedColumn<int> parameterNumber = GeneratedColumn<int>(
      'parameter_number', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<PackedMappingData, Uint8List>
      packedData = GeneratedColumn<Uint8List>('packed_data', aliasedName, false,
              type: DriftSqlType.blob, requiredDuringInsert: true)
          .withConverter<PackedMappingData>(
              $PresetMappingsTable.$converterpackedData);
  @override
  List<GeneratedColumn> get $columns =>
      [presetSlotId, parameterNumber, packedData];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preset_mappings';
  @override
  VerificationContext validateIntegrity(Insertable<PresetMappingEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('preset_slot_id')) {
      context.handle(
          _presetSlotIdMeta,
          presetSlotId.isAcceptableOrUnknown(
              data['preset_slot_id']!, _presetSlotIdMeta));
    } else if (isInserting) {
      context.missing(_presetSlotIdMeta);
    }
    if (data.containsKey('parameter_number')) {
      context.handle(
          _parameterNumberMeta,
          parameterNumber.isAcceptableOrUnknown(
              data['parameter_number']!, _parameterNumberMeta));
    } else if (isInserting) {
      context.missing(_parameterNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {presetSlotId, parameterNumber};
  @override
  PresetMappingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresetMappingEntry(
      presetSlotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}preset_slot_id'])!,
      parameterNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parameter_number'])!,
      packedData: $PresetMappingsTable.$converterpackedData.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.blob, data['${effectivePrefix}packed_data'])!),
    );
  }

  @override
  $PresetMappingsTable createAlias(String alias) {
    return $PresetMappingsTable(attachedDatabase, alias);
  }

  static TypeConverter<PackedMappingData, Uint8List> $converterpackedData =
      const PackedMappingDataConverter();
}

class PresetMappingEntry extends DataClass
    implements Insertable<PresetMappingEntry> {
  final int presetSlotId;
  final int parameterNumber;
  final PackedMappingData packedData;
  const PresetMappingEntry(
      {required this.presetSlotId,
      required this.parameterNumber,
      required this.packedData});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['preset_slot_id'] = Variable<int>(presetSlotId);
    map['parameter_number'] = Variable<int>(parameterNumber);
    {
      map['packed_data'] = Variable<Uint8List>(
          $PresetMappingsTable.$converterpackedData.toSql(packedData));
    }
    return map;
  }

  PresetMappingsCompanion toCompanion(bool nullToAbsent) {
    return PresetMappingsCompanion(
      presetSlotId: Value(presetSlotId),
      parameterNumber: Value(parameterNumber),
      packedData: Value(packedData),
    );
  }

  factory PresetMappingEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresetMappingEntry(
      presetSlotId: serializer.fromJson<int>(json['presetSlotId']),
      parameterNumber: serializer.fromJson<int>(json['parameterNumber']),
      packedData: serializer.fromJson<PackedMappingData>(json['packedData']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'presetSlotId': serializer.toJson<int>(presetSlotId),
      'parameterNumber': serializer.toJson<int>(parameterNumber),
      'packedData': serializer.toJson<PackedMappingData>(packedData),
    };
  }

  PresetMappingEntry copyWith(
          {int? presetSlotId,
          int? parameterNumber,
          PackedMappingData? packedData}) =>
      PresetMappingEntry(
        presetSlotId: presetSlotId ?? this.presetSlotId,
        parameterNumber: parameterNumber ?? this.parameterNumber,
        packedData: packedData ?? this.packedData,
      );
  PresetMappingEntry copyWithCompanion(PresetMappingsCompanion data) {
    return PresetMappingEntry(
      presetSlotId: data.presetSlotId.present
          ? data.presetSlotId.value
          : this.presetSlotId,
      parameterNumber: data.parameterNumber.present
          ? data.parameterNumber.value
          : this.parameterNumber,
      packedData:
          data.packedData.present ? data.packedData.value : this.packedData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresetMappingEntry(')
          ..write('presetSlotId: $presetSlotId, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('packedData: $packedData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(presetSlotId, parameterNumber, packedData);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresetMappingEntry &&
          other.presetSlotId == this.presetSlotId &&
          other.parameterNumber == this.parameterNumber &&
          other.packedData == this.packedData);
}

class PresetMappingsCompanion extends UpdateCompanion<PresetMappingEntry> {
  final Value<int> presetSlotId;
  final Value<int> parameterNumber;
  final Value<PackedMappingData> packedData;
  final Value<int> rowid;
  const PresetMappingsCompanion({
    this.presetSlotId = const Value.absent(),
    this.parameterNumber = const Value.absent(),
    this.packedData = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PresetMappingsCompanion.insert({
    required int presetSlotId,
    required int parameterNumber,
    required PackedMappingData packedData,
    this.rowid = const Value.absent(),
  })  : presetSlotId = Value(presetSlotId),
        parameterNumber = Value(parameterNumber),
        packedData = Value(packedData);
  static Insertable<PresetMappingEntry> custom({
    Expression<int>? presetSlotId,
    Expression<int>? parameterNumber,
    Expression<Uint8List>? packedData,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (presetSlotId != null) 'preset_slot_id': presetSlotId,
      if (parameterNumber != null) 'parameter_number': parameterNumber,
      if (packedData != null) 'packed_data': packedData,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PresetMappingsCompanion copyWith(
      {Value<int>? presetSlotId,
      Value<int>? parameterNumber,
      Value<PackedMappingData>? packedData,
      Value<int>? rowid}) {
    return PresetMappingsCompanion(
      presetSlotId: presetSlotId ?? this.presetSlotId,
      parameterNumber: parameterNumber ?? this.parameterNumber,
      packedData: packedData ?? this.packedData,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (presetSlotId.present) {
      map['preset_slot_id'] = Variable<int>(presetSlotId.value);
    }
    if (parameterNumber.present) {
      map['parameter_number'] = Variable<int>(parameterNumber.value);
    }
    if (packedData.present) {
      map['packed_data'] = Variable<Uint8List>(
          $PresetMappingsTable.$converterpackedData.toSql(packedData.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresetMappingsCompanion(')
          ..write('presetSlotId: $presetSlotId, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('packedData: $packedData, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PresetRoutingsTable extends PresetRoutings
    with TableInfo<$PresetRoutingsTable, PresetRoutingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PresetRoutingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _presetSlotIdMeta =
      const VerificationMeta('presetSlotId');
  @override
  late final GeneratedColumn<int> presetSlotId = GeneratedColumn<int>(
      'preset_slot_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES preset_slots (id)'));
  @override
  late final GeneratedColumnWithTypeConverter<List<int>, String>
      routingInfoJson = GeneratedColumn<String>(
              'routing_info_json', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<int>>(
              $PresetRoutingsTable.$converterroutingInfoJson);
  @override
  List<GeneratedColumn> get $columns => [presetSlotId, routingInfoJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preset_routings';
  @override
  VerificationContext validateIntegrity(Insertable<PresetRoutingEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('preset_slot_id')) {
      context.handle(
          _presetSlotIdMeta,
          presetSlotId.isAcceptableOrUnknown(
              data['preset_slot_id']!, _presetSlotIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {presetSlotId};
  @override
  PresetRoutingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresetRoutingEntry(
      presetSlotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}preset_slot_id'])!,
      routingInfoJson: $PresetRoutingsTable.$converterroutingInfoJson.fromSql(
          attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}routing_info_json'])!),
    );
  }

  @override
  $PresetRoutingsTable createAlias(String alias) {
    return $PresetRoutingsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<int>, String> $converterroutingInfoJson =
      const IntListConverter();
}

class PresetRoutingEntry extends DataClass
    implements Insertable<PresetRoutingEntry> {
  final int presetSlotId;
  final List<int> routingInfoJson;
  const PresetRoutingEntry(
      {required this.presetSlotId, required this.routingInfoJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['preset_slot_id'] = Variable<int>(presetSlotId);
    {
      map['routing_info_json'] = Variable<String>($PresetRoutingsTable
          .$converterroutingInfoJson
          .toSql(routingInfoJson));
    }
    return map;
  }

  PresetRoutingsCompanion toCompanion(bool nullToAbsent) {
    return PresetRoutingsCompanion(
      presetSlotId: Value(presetSlotId),
      routingInfoJson: Value(routingInfoJson),
    );
  }

  factory PresetRoutingEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresetRoutingEntry(
      presetSlotId: serializer.fromJson<int>(json['presetSlotId']),
      routingInfoJson: serializer.fromJson<List<int>>(json['routingInfoJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'presetSlotId': serializer.toJson<int>(presetSlotId),
      'routingInfoJson': serializer.toJson<List<int>>(routingInfoJson),
    };
  }

  PresetRoutingEntry copyWith(
          {int? presetSlotId, List<int>? routingInfoJson}) =>
      PresetRoutingEntry(
        presetSlotId: presetSlotId ?? this.presetSlotId,
        routingInfoJson: routingInfoJson ?? this.routingInfoJson,
      );
  PresetRoutingEntry copyWithCompanion(PresetRoutingsCompanion data) {
    return PresetRoutingEntry(
      presetSlotId: data.presetSlotId.present
          ? data.presetSlotId.value
          : this.presetSlotId,
      routingInfoJson: data.routingInfoJson.present
          ? data.routingInfoJson.value
          : this.routingInfoJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PresetRoutingEntry(')
          ..write('presetSlotId: $presetSlotId, ')
          ..write('routingInfoJson: $routingInfoJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(presetSlotId, routingInfoJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresetRoutingEntry &&
          other.presetSlotId == this.presetSlotId &&
          other.routingInfoJson == this.routingInfoJson);
}

class PresetRoutingsCompanion extends UpdateCompanion<PresetRoutingEntry> {
  final Value<int> presetSlotId;
  final Value<List<int>> routingInfoJson;
  const PresetRoutingsCompanion({
    this.presetSlotId = const Value.absent(),
    this.routingInfoJson = const Value.absent(),
  });
  PresetRoutingsCompanion.insert({
    this.presetSlotId = const Value.absent(),
    required List<int> routingInfoJson,
  }) : routingInfoJson = Value(routingInfoJson);
  static Insertable<PresetRoutingEntry> custom({
    Expression<int>? presetSlotId,
    Expression<String>? routingInfoJson,
  }) {
    return RawValuesInsertable({
      if (presetSlotId != null) 'preset_slot_id': presetSlotId,
      if (routingInfoJson != null) 'routing_info_json': routingInfoJson,
    });
  }

  PresetRoutingsCompanion copyWith(
      {Value<int>? presetSlotId, Value<List<int>>? routingInfoJson}) {
    return PresetRoutingsCompanion(
      presetSlotId: presetSlotId ?? this.presetSlotId,
      routingInfoJson: routingInfoJson ?? this.routingInfoJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (presetSlotId.present) {
      map['preset_slot_id'] = Variable<int>(presetSlotId.value);
    }
    if (routingInfoJson.present) {
      map['routing_info_json'] = Variable<String>($PresetRoutingsTable
          .$converterroutingInfoJson
          .toSql(routingInfoJson.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresetRoutingsCompanion(')
          ..write('presetSlotId: $presetSlotId, ')
          ..write('routingInfoJson: $routingInfoJson')
          ..write(')'))
        .toString();
  }
}

class $SdCardsTable extends SdCards with TableInfo<$SdCardsTable, SdCardEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SdCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userLabelMeta =
      const VerificationMeta('userLabel');
  @override
  late final GeneratedColumn<String> userLabel = GeneratedColumn<String>(
      'user_label', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _systemIdentifierMeta =
      const VerificationMeta('systemIdentifier');
  @override
  late final GeneratedColumn<String> systemIdentifier = GeneratedColumn<String>(
      'system_identifier', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns => [id, userLabel, systemIdentifier];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sd_cards';
  @override
  VerificationContext validateIntegrity(Insertable<SdCardEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_label')) {
      context.handle(_userLabelMeta,
          userLabel.isAcceptableOrUnknown(data['user_label']!, _userLabelMeta));
    } else if (isInserting) {
      context.missing(_userLabelMeta);
    }
    if (data.containsKey('system_identifier')) {
      context.handle(
          _systemIdentifierMeta,
          systemIdentifier.isAcceptableOrUnknown(
              data['system_identifier']!, _systemIdentifierMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SdCardEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SdCardEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_label'])!,
      systemIdentifier: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}system_identifier']),
    );
  }

  @override
  $SdCardsTable createAlias(String alias) {
    return $SdCardsTable(attachedDatabase, alias);
  }
}

class SdCardEntry extends DataClass implements Insertable<SdCardEntry> {
  final int id;
  final String userLabel;
  final String? systemIdentifier;
  const SdCardEntry(
      {required this.id, required this.userLabel, this.systemIdentifier});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_label'] = Variable<String>(userLabel);
    if (!nullToAbsent || systemIdentifier != null) {
      map['system_identifier'] = Variable<String>(systemIdentifier);
    }
    return map;
  }

  SdCardsCompanion toCompanion(bool nullToAbsent) {
    return SdCardsCompanion(
      id: Value(id),
      userLabel: Value(userLabel),
      systemIdentifier: systemIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(systemIdentifier),
    );
  }

  factory SdCardEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SdCardEntry(
      id: serializer.fromJson<int>(json['id']),
      userLabel: serializer.fromJson<String>(json['userLabel']),
      systemIdentifier: serializer.fromJson<String?>(json['systemIdentifier']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userLabel': serializer.toJson<String>(userLabel),
      'systemIdentifier': serializer.toJson<String?>(systemIdentifier),
    };
  }

  SdCardEntry copyWith(
          {int? id,
          String? userLabel,
          Value<String?> systemIdentifier = const Value.absent()}) =>
      SdCardEntry(
        id: id ?? this.id,
        userLabel: userLabel ?? this.userLabel,
        systemIdentifier: systemIdentifier.present
            ? systemIdentifier.value
            : this.systemIdentifier,
      );
  SdCardEntry copyWithCompanion(SdCardsCompanion data) {
    return SdCardEntry(
      id: data.id.present ? data.id.value : this.id,
      userLabel: data.userLabel.present ? data.userLabel.value : this.userLabel,
      systemIdentifier: data.systemIdentifier.present
          ? data.systemIdentifier.value
          : this.systemIdentifier,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SdCardEntry(')
          ..write('id: $id, ')
          ..write('userLabel: $userLabel, ')
          ..write('systemIdentifier: $systemIdentifier')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userLabel, systemIdentifier);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SdCardEntry &&
          other.id == this.id &&
          other.userLabel == this.userLabel &&
          other.systemIdentifier == this.systemIdentifier);
}

class SdCardsCompanion extends UpdateCompanion<SdCardEntry> {
  final Value<int> id;
  final Value<String> userLabel;
  final Value<String?> systemIdentifier;
  const SdCardsCompanion({
    this.id = const Value.absent(),
    this.userLabel = const Value.absent(),
    this.systemIdentifier = const Value.absent(),
  });
  SdCardsCompanion.insert({
    this.id = const Value.absent(),
    required String userLabel,
    this.systemIdentifier = const Value.absent(),
  }) : userLabel = Value(userLabel);
  static Insertable<SdCardEntry> custom({
    Expression<int>? id,
    Expression<String>? userLabel,
    Expression<String>? systemIdentifier,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userLabel != null) 'user_label': userLabel,
      if (systemIdentifier != null) 'system_identifier': systemIdentifier,
    });
  }

  SdCardsCompanion copyWith(
      {Value<int>? id,
      Value<String>? userLabel,
      Value<String?>? systemIdentifier}) {
    return SdCardsCompanion(
      id: id ?? this.id,
      userLabel: userLabel ?? this.userLabel,
      systemIdentifier: systemIdentifier ?? this.systemIdentifier,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userLabel.present) {
      map['user_label'] = Variable<String>(userLabel.value);
    }
    if (systemIdentifier.present) {
      map['system_identifier'] = Variable<String>(systemIdentifier.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SdCardsCompanion(')
          ..write('id: $id, ')
          ..write('userLabel: $userLabel, ')
          ..write('systemIdentifier: $systemIdentifier')
          ..write(')'))
        .toString();
  }
}

class $IndexedPresetFilesTable extends IndexedPresetFiles
    with TableInfo<$IndexedPresetFilesTable, IndexedPresetFileEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IndexedPresetFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sdCardIdMeta =
      const VerificationMeta('sdCardId');
  @override
  late final GeneratedColumn<int> sdCardId = GeneratedColumn<int>(
      'sd_card_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES sd_cards (id)'));
  static const VerificationMeta _relativePathMeta =
      const VerificationMeta('relativePath');
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
      'relative_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _absolutePathAtScanTimeMeta =
      const VerificationMeta('absolutePathAtScanTime');
  @override
  late final GeneratedColumn<String> absolutePathAtScanTime =
      GeneratedColumn<String>('absolute_path_at_scan_time', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _algorithmNameFromPresetMeta =
      const VerificationMeta('algorithmNameFromPreset');
  @override
  late final GeneratedColumn<String> algorithmNameFromPreset =
      GeneratedColumn<String>('algorithm_name_from_preset', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesFromPresetMeta =
      const VerificationMeta('notesFromPreset');
  @override
  late final GeneratedColumn<String> notesFromPreset = GeneratedColumn<String>(
      'notes_from_preset', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _otherExtractedMetadataJsonMeta =
      const VerificationMeta('otherExtractedMetadataJson');
  @override
  late final GeneratedColumn<String> otherExtractedMetadataJson =
      GeneratedColumn<String>(
          'other_extracted_metadata_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastSeenUtcMeta =
      const VerificationMeta('lastSeenUtc');
  @override
  late final GeneratedColumn<DateTime> lastSeenUtc = GeneratedColumn<DateTime>(
      'last_seen_utc', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sdCardId,
        relativePath,
        fileName,
        absolutePathAtScanTime,
        algorithmNameFromPreset,
        notesFromPreset,
        otherExtractedMetadataJson,
        lastSeenUtc
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'indexed_preset_files';
  @override
  VerificationContext validateIntegrity(
      Insertable<IndexedPresetFileEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sd_card_id')) {
      context.handle(_sdCardIdMeta,
          sdCardId.isAcceptableOrUnknown(data['sd_card_id']!, _sdCardIdMeta));
    } else if (isInserting) {
      context.missing(_sdCardIdMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
          _relativePathMeta,
          relativePath.isAcceptableOrUnknown(
              data['relative_path']!, _relativePathMeta));
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('absolute_path_at_scan_time')) {
      context.handle(
          _absolutePathAtScanTimeMeta,
          absolutePathAtScanTime.isAcceptableOrUnknown(
              data['absolute_path_at_scan_time']!,
              _absolutePathAtScanTimeMeta));
    } else if (isInserting) {
      context.missing(_absolutePathAtScanTimeMeta);
    }
    if (data.containsKey('algorithm_name_from_preset')) {
      context.handle(
          _algorithmNameFromPresetMeta,
          algorithmNameFromPreset.isAcceptableOrUnknown(
              data['algorithm_name_from_preset']!,
              _algorithmNameFromPresetMeta));
    }
    if (data.containsKey('notes_from_preset')) {
      context.handle(
          _notesFromPresetMeta,
          notesFromPreset.isAcceptableOrUnknown(
              data['notes_from_preset']!, _notesFromPresetMeta));
    }
    if (data.containsKey('other_extracted_metadata_json')) {
      context.handle(
          _otherExtractedMetadataJsonMeta,
          otherExtractedMetadataJson.isAcceptableOrUnknown(
              data['other_extracted_metadata_json']!,
              _otherExtractedMetadataJsonMeta));
    }
    if (data.containsKey('last_seen_utc')) {
      context.handle(
          _lastSeenUtcMeta,
          lastSeenUtc.isAcceptableOrUnknown(
              data['last_seen_utc']!, _lastSeenUtcMeta));
    } else if (isInserting) {
      context.missing(_lastSeenUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IndexedPresetFileEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IndexedPresetFileEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sdCardId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sd_card_id'])!,
      relativePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relative_path'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      absolutePathAtScanTime: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}absolute_path_at_scan_time'])!,
      algorithmNameFromPreset: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}algorithm_name_from_preset']),
      notesFromPreset: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}notes_from_preset']),
      otherExtractedMetadataJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}other_extracted_metadata_json']),
      lastSeenUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_seen_utc'])!,
    );
  }

  @override
  $IndexedPresetFilesTable createAlias(String alias) {
    return $IndexedPresetFilesTable(attachedDatabase, alias);
  }
}

class IndexedPresetFileEntry extends DataClass
    implements Insertable<IndexedPresetFileEntry> {
  final int id;
  final int sdCardId;
  final String relativePath;
  final String fileName;
  final String absolutePathAtScanTime;
  final String? algorithmNameFromPreset;
  final String? notesFromPreset;
  final String? otherExtractedMetadataJson;
  final DateTime lastSeenUtc;
  const IndexedPresetFileEntry(
      {required this.id,
      required this.sdCardId,
      required this.relativePath,
      required this.fileName,
      required this.absolutePathAtScanTime,
      this.algorithmNameFromPreset,
      this.notesFromPreset,
      this.otherExtractedMetadataJson,
      required this.lastSeenUtc});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sd_card_id'] = Variable<int>(sdCardId);
    map['relative_path'] = Variable<String>(relativePath);
    map['file_name'] = Variable<String>(fileName);
    map['absolute_path_at_scan_time'] =
        Variable<String>(absolutePathAtScanTime);
    if (!nullToAbsent || algorithmNameFromPreset != null) {
      map['algorithm_name_from_preset'] =
          Variable<String>(algorithmNameFromPreset);
    }
    if (!nullToAbsent || notesFromPreset != null) {
      map['notes_from_preset'] = Variable<String>(notesFromPreset);
    }
    if (!nullToAbsent || otherExtractedMetadataJson != null) {
      map['other_extracted_metadata_json'] =
          Variable<String>(otherExtractedMetadataJson);
    }
    map['last_seen_utc'] = Variable<DateTime>(lastSeenUtc);
    return map;
  }

  IndexedPresetFilesCompanion toCompanion(bool nullToAbsent) {
    return IndexedPresetFilesCompanion(
      id: Value(id),
      sdCardId: Value(sdCardId),
      relativePath: Value(relativePath),
      fileName: Value(fileName),
      absolutePathAtScanTime: Value(absolutePathAtScanTime),
      algorithmNameFromPreset: algorithmNameFromPreset == null && nullToAbsent
          ? const Value.absent()
          : Value(algorithmNameFromPreset),
      notesFromPreset: notesFromPreset == null && nullToAbsent
          ? const Value.absent()
          : Value(notesFromPreset),
      otherExtractedMetadataJson:
          otherExtractedMetadataJson == null && nullToAbsent
              ? const Value.absent()
              : Value(otherExtractedMetadataJson),
      lastSeenUtc: Value(lastSeenUtc),
    );
  }

  factory IndexedPresetFileEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IndexedPresetFileEntry(
      id: serializer.fromJson<int>(json['id']),
      sdCardId: serializer.fromJson<int>(json['sdCardId']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      absolutePathAtScanTime:
          serializer.fromJson<String>(json['absolutePathAtScanTime']),
      algorithmNameFromPreset:
          serializer.fromJson<String?>(json['algorithmNameFromPreset']),
      notesFromPreset: serializer.fromJson<String?>(json['notesFromPreset']),
      otherExtractedMetadataJson:
          serializer.fromJson<String?>(json['otherExtractedMetadataJson']),
      lastSeenUtc: serializer.fromJson<DateTime>(json['lastSeenUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sdCardId': serializer.toJson<int>(sdCardId),
      'relativePath': serializer.toJson<String>(relativePath),
      'fileName': serializer.toJson<String>(fileName),
      'absolutePathAtScanTime':
          serializer.toJson<String>(absolutePathAtScanTime),
      'algorithmNameFromPreset':
          serializer.toJson<String?>(algorithmNameFromPreset),
      'notesFromPreset': serializer.toJson<String?>(notesFromPreset),
      'otherExtractedMetadataJson':
          serializer.toJson<String?>(otherExtractedMetadataJson),
      'lastSeenUtc': serializer.toJson<DateTime>(lastSeenUtc),
    };
  }

  IndexedPresetFileEntry copyWith(
          {int? id,
          int? sdCardId,
          String? relativePath,
          String? fileName,
          String? absolutePathAtScanTime,
          Value<String?> algorithmNameFromPreset = const Value.absent(),
          Value<String?> notesFromPreset = const Value.absent(),
          Value<String?> otherExtractedMetadataJson = const Value.absent(),
          DateTime? lastSeenUtc}) =>
      IndexedPresetFileEntry(
        id: id ?? this.id,
        sdCardId: sdCardId ?? this.sdCardId,
        relativePath: relativePath ?? this.relativePath,
        fileName: fileName ?? this.fileName,
        absolutePathAtScanTime:
            absolutePathAtScanTime ?? this.absolutePathAtScanTime,
        algorithmNameFromPreset: algorithmNameFromPreset.present
            ? algorithmNameFromPreset.value
            : this.algorithmNameFromPreset,
        notesFromPreset: notesFromPreset.present
            ? notesFromPreset.value
            : this.notesFromPreset,
        otherExtractedMetadataJson: otherExtractedMetadataJson.present
            ? otherExtractedMetadataJson.value
            : this.otherExtractedMetadataJson,
        lastSeenUtc: lastSeenUtc ?? this.lastSeenUtc,
      );
  IndexedPresetFileEntry copyWithCompanion(IndexedPresetFilesCompanion data) {
    return IndexedPresetFileEntry(
      id: data.id.present ? data.id.value : this.id,
      sdCardId: data.sdCardId.present ? data.sdCardId.value : this.sdCardId,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      absolutePathAtScanTime: data.absolutePathAtScanTime.present
          ? data.absolutePathAtScanTime.value
          : this.absolutePathAtScanTime,
      algorithmNameFromPreset: data.algorithmNameFromPreset.present
          ? data.algorithmNameFromPreset.value
          : this.algorithmNameFromPreset,
      notesFromPreset: data.notesFromPreset.present
          ? data.notesFromPreset.value
          : this.notesFromPreset,
      otherExtractedMetadataJson: data.otherExtractedMetadataJson.present
          ? data.otherExtractedMetadataJson.value
          : this.otherExtractedMetadataJson,
      lastSeenUtc:
          data.lastSeenUtc.present ? data.lastSeenUtc.value : this.lastSeenUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IndexedPresetFileEntry(')
          ..write('id: $id, ')
          ..write('sdCardId: $sdCardId, ')
          ..write('relativePath: $relativePath, ')
          ..write('fileName: $fileName, ')
          ..write('absolutePathAtScanTime: $absolutePathAtScanTime, ')
          ..write('algorithmNameFromPreset: $algorithmNameFromPreset, ')
          ..write('notesFromPreset: $notesFromPreset, ')
          ..write('otherExtractedMetadataJson: $otherExtractedMetadataJson, ')
          ..write('lastSeenUtc: $lastSeenUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sdCardId,
      relativePath,
      fileName,
      absolutePathAtScanTime,
      algorithmNameFromPreset,
      notesFromPreset,
      otherExtractedMetadataJson,
      lastSeenUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IndexedPresetFileEntry &&
          other.id == this.id &&
          other.sdCardId == this.sdCardId &&
          other.relativePath == this.relativePath &&
          other.fileName == this.fileName &&
          other.absolutePathAtScanTime == this.absolutePathAtScanTime &&
          other.algorithmNameFromPreset == this.algorithmNameFromPreset &&
          other.notesFromPreset == this.notesFromPreset &&
          other.otherExtractedMetadataJson == this.otherExtractedMetadataJson &&
          other.lastSeenUtc == this.lastSeenUtc);
}

class IndexedPresetFilesCompanion
    extends UpdateCompanion<IndexedPresetFileEntry> {
  final Value<int> id;
  final Value<int> sdCardId;
  final Value<String> relativePath;
  final Value<String> fileName;
  final Value<String> absolutePathAtScanTime;
  final Value<String?> algorithmNameFromPreset;
  final Value<String?> notesFromPreset;
  final Value<String?> otherExtractedMetadataJson;
  final Value<DateTime> lastSeenUtc;
  const IndexedPresetFilesCompanion({
    this.id = const Value.absent(),
    this.sdCardId = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.absolutePathAtScanTime = const Value.absent(),
    this.algorithmNameFromPreset = const Value.absent(),
    this.notesFromPreset = const Value.absent(),
    this.otherExtractedMetadataJson = const Value.absent(),
    this.lastSeenUtc = const Value.absent(),
  });
  IndexedPresetFilesCompanion.insert({
    this.id = const Value.absent(),
    required int sdCardId,
    required String relativePath,
    required String fileName,
    required String absolutePathAtScanTime,
    this.algorithmNameFromPreset = const Value.absent(),
    this.notesFromPreset = const Value.absent(),
    this.otherExtractedMetadataJson = const Value.absent(),
    required DateTime lastSeenUtc,
  })  : sdCardId = Value(sdCardId),
        relativePath = Value(relativePath),
        fileName = Value(fileName),
        absolutePathAtScanTime = Value(absolutePathAtScanTime),
        lastSeenUtc = Value(lastSeenUtc);
  static Insertable<IndexedPresetFileEntry> custom({
    Expression<int>? id,
    Expression<int>? sdCardId,
    Expression<String>? relativePath,
    Expression<String>? fileName,
    Expression<String>? absolutePathAtScanTime,
    Expression<String>? algorithmNameFromPreset,
    Expression<String>? notesFromPreset,
    Expression<String>? otherExtractedMetadataJson,
    Expression<DateTime>? lastSeenUtc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sdCardId != null) 'sd_card_id': sdCardId,
      if (relativePath != null) 'relative_path': relativePath,
      if (fileName != null) 'file_name': fileName,
      if (absolutePathAtScanTime != null)
        'absolute_path_at_scan_time': absolutePathAtScanTime,
      if (algorithmNameFromPreset != null)
        'algorithm_name_from_preset': algorithmNameFromPreset,
      if (notesFromPreset != null) 'notes_from_preset': notesFromPreset,
      if (otherExtractedMetadataJson != null)
        'other_extracted_metadata_json': otherExtractedMetadataJson,
      if (lastSeenUtc != null) 'last_seen_utc': lastSeenUtc,
    });
  }

  IndexedPresetFilesCompanion copyWith(
      {Value<int>? id,
      Value<int>? sdCardId,
      Value<String>? relativePath,
      Value<String>? fileName,
      Value<String>? absolutePathAtScanTime,
      Value<String?>? algorithmNameFromPreset,
      Value<String?>? notesFromPreset,
      Value<String?>? otherExtractedMetadataJson,
      Value<DateTime>? lastSeenUtc}) {
    return IndexedPresetFilesCompanion(
      id: id ?? this.id,
      sdCardId: sdCardId ?? this.sdCardId,
      relativePath: relativePath ?? this.relativePath,
      fileName: fileName ?? this.fileName,
      absolutePathAtScanTime:
          absolutePathAtScanTime ?? this.absolutePathAtScanTime,
      algorithmNameFromPreset:
          algorithmNameFromPreset ?? this.algorithmNameFromPreset,
      notesFromPreset: notesFromPreset ?? this.notesFromPreset,
      otherExtractedMetadataJson:
          otherExtractedMetadataJson ?? this.otherExtractedMetadataJson,
      lastSeenUtc: lastSeenUtc ?? this.lastSeenUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sdCardId.present) {
      map['sd_card_id'] = Variable<int>(sdCardId.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (absolutePathAtScanTime.present) {
      map['absolute_path_at_scan_time'] =
          Variable<String>(absolutePathAtScanTime.value);
    }
    if (algorithmNameFromPreset.present) {
      map['algorithm_name_from_preset'] =
          Variable<String>(algorithmNameFromPreset.value);
    }
    if (notesFromPreset.present) {
      map['notes_from_preset'] = Variable<String>(notesFromPreset.value);
    }
    if (otherExtractedMetadataJson.present) {
      map['other_extracted_metadata_json'] =
          Variable<String>(otherExtractedMetadataJson.value);
    }
    if (lastSeenUtc.present) {
      map['last_seen_utc'] = Variable<DateTime>(lastSeenUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IndexedPresetFilesCompanion(')
          ..write('id: $id, ')
          ..write('sdCardId: $sdCardId, ')
          ..write('relativePath: $relativePath, ')
          ..write('fileName: $fileName, ')
          ..write('absolutePathAtScanTime: $absolutePathAtScanTime, ')
          ..write('algorithmNameFromPreset: $algorithmNameFromPreset, ')
          ..write('notesFromPreset: $notesFromPreset, ')
          ..write('otherExtractedMetadataJson: $otherExtractedMetadataJson, ')
          ..write('lastSeenUtc: $lastSeenUtc')
          ..write(')'))
        .toString();
  }
}

class $MetadataCacheTable extends MetadataCache
    with TableInfo<$MetadataCacheTable, MetadataCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetadataCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta =
      const VerificationMeta('cacheKey');
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
      'cache_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cacheValueMeta =
      const VerificationMeta('cacheValue');
  @override
  late final GeneratedColumn<String> cacheValue = GeneratedColumn<String>(
      'cache_value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [cacheKey, cacheValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metadata_cache';
  @override
  VerificationContext validateIntegrity(Insertable<MetadataCacheEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta));
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('cache_value')) {
      context.handle(
          _cacheValueMeta,
          cacheValue.isAcceptableOrUnknown(
              data['cache_value']!, _cacheValueMeta));
    } else if (isInserting) {
      context.missing(_cacheValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  MetadataCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetadataCacheEntry(
      cacheKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_key'])!,
      cacheValue: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_value'])!,
    );
  }

  @override
  $MetadataCacheTable createAlias(String alias) {
    return $MetadataCacheTable(attachedDatabase, alias);
  }
}

class MetadataCacheEntry extends DataClass
    implements Insertable<MetadataCacheEntry> {
  final String cacheKey;
  final String cacheValue;
  const MetadataCacheEntry({required this.cacheKey, required this.cacheValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['cache_value'] = Variable<String>(cacheValue);
    return map;
  }

  MetadataCacheCompanion toCompanion(bool nullToAbsent) {
    return MetadataCacheCompanion(
      cacheKey: Value(cacheKey),
      cacheValue: Value(cacheValue),
    );
  }

  factory MetadataCacheEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetadataCacheEntry(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      cacheValue: serializer.fromJson<String>(json['cacheValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'cacheValue': serializer.toJson<String>(cacheValue),
    };
  }

  MetadataCacheEntry copyWith({String? cacheKey, String? cacheValue}) =>
      MetadataCacheEntry(
        cacheKey: cacheKey ?? this.cacheKey,
        cacheValue: cacheValue ?? this.cacheValue,
      );
  MetadataCacheEntry copyWithCompanion(MetadataCacheCompanion data) {
    return MetadataCacheEntry(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      cacheValue:
          data.cacheValue.present ? data.cacheValue.value : this.cacheValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetadataCacheEntry(')
          ..write('cacheKey: $cacheKey, ')
          ..write('cacheValue: $cacheValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, cacheValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetadataCacheEntry &&
          other.cacheKey == this.cacheKey &&
          other.cacheValue == this.cacheValue);
}

class MetadataCacheCompanion extends UpdateCompanion<MetadataCacheEntry> {
  final Value<String> cacheKey;
  final Value<String> cacheValue;
  final Value<int> rowid;
  const MetadataCacheCompanion({
    this.cacheKey = const Value.absent(),
    this.cacheValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetadataCacheCompanion.insert({
    required String cacheKey,
    required String cacheValue,
    this.rowid = const Value.absent(),
  })  : cacheKey = Value(cacheKey),
        cacheValue = Value(cacheValue);
  static Insertable<MetadataCacheEntry> custom({
    Expression<String>? cacheKey,
    Expression<String>? cacheValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (cacheValue != null) 'cache_value': cacheValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetadataCacheCompanion copyWith(
      {Value<String>? cacheKey, Value<String>? cacheValue, Value<int>? rowid}) {
    return MetadataCacheCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      cacheValue: cacheValue ?? this.cacheValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (cacheValue.present) {
      map['cache_value'] = Variable<String>(cacheValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetadataCacheCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('cacheValue: $cacheValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PluginInstallationsTable extends PluginInstallations
    with TableInfo<$PluginInstallationsTable, PluginInstallationEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PluginInstallationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _pluginIdMeta =
      const VerificationMeta('pluginId');
  @override
  late final GeneratedColumn<String> pluginId = GeneratedColumn<String>(
      'plugin_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pluginNameMeta =
      const VerificationMeta('pluginName');
  @override
  late final GeneratedColumn<String> pluginName = GeneratedColumn<String>(
      'plugin_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pluginVersionMeta =
      const VerificationMeta('pluginVersion');
  @override
  late final GeneratedColumn<String> pluginVersion = GeneratedColumn<String>(
      'plugin_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pluginTypeMeta =
      const VerificationMeta('pluginType');
  @override
  late final GeneratedColumn<String> pluginType = GeneratedColumn<String>(
      'plugin_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pluginAuthorMeta =
      const VerificationMeta('pluginAuthor');
  @override
  late final GeneratedColumn<String> pluginAuthor = GeneratedColumn<String>(
      'plugin_author', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _installedAtMeta =
      const VerificationMeta('installedAt');
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
      'installed_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _installationPathMeta =
      const VerificationMeta('installationPath');
  @override
  late final GeneratedColumn<String> installationPath = GeneratedColumn<String>(
      'installation_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _installationStatusMeta =
      const VerificationMeta('installationStatus');
  @override
  late final GeneratedColumn<String> installationStatus =
      GeneratedColumn<String>('installation_status', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('completed'));
  static const VerificationMeta _marketplaceMetadataMeta =
      const VerificationMeta('marketplaceMetadata');
  @override
  late final GeneratedColumn<String> marketplaceMetadata =
      GeneratedColumn<String>('marketplace_metadata', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _repositoryUrlMeta =
      const VerificationMeta('repositoryUrl');
  @override
  late final GeneratedColumn<String> repositoryUrl = GeneratedColumn<String>(
      'repository_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _repositoryOwnerMeta =
      const VerificationMeta('repositoryOwner');
  @override
  late final GeneratedColumn<String> repositoryOwner = GeneratedColumn<String>(
      'repository_owner', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _repositoryNameMeta =
      const VerificationMeta('repositoryName');
  @override
  late final GeneratedColumn<String> repositoryName = GeneratedColumn<String>(
      'repository_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileCountMeta =
      const VerificationMeta('fileCount');
  @override
  late final GeneratedColumn<int> fileCount = GeneratedColumn<int>(
      'file_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalBytesMeta =
      const VerificationMeta('totalBytes');
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
      'total_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _installationNotesMeta =
      const VerificationMeta('installationNotes');
  @override
  late final GeneratedColumn<String> installationNotes =
      GeneratedColumn<String>('installation_notes', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        pluginId,
        pluginName,
        pluginVersion,
        pluginType,
        pluginAuthor,
        installedAt,
        installationPath,
        installationStatus,
        marketplaceMetadata,
        repositoryUrl,
        repositoryOwner,
        repositoryName,
        fileCount,
        totalBytes,
        installationNotes,
        errorMessage
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plugin_installations';
  @override
  VerificationContext validateIntegrity(
      Insertable<PluginInstallationEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plugin_id')) {
      context.handle(_pluginIdMeta,
          pluginId.isAcceptableOrUnknown(data['plugin_id']!, _pluginIdMeta));
    } else if (isInserting) {
      context.missing(_pluginIdMeta);
    }
    if (data.containsKey('plugin_name')) {
      context.handle(
          _pluginNameMeta,
          pluginName.isAcceptableOrUnknown(
              data['plugin_name']!, _pluginNameMeta));
    } else if (isInserting) {
      context.missing(_pluginNameMeta);
    }
    if (data.containsKey('plugin_version')) {
      context.handle(
          _pluginVersionMeta,
          pluginVersion.isAcceptableOrUnknown(
              data['plugin_version']!, _pluginVersionMeta));
    } else if (isInserting) {
      context.missing(_pluginVersionMeta);
    }
    if (data.containsKey('plugin_type')) {
      context.handle(
          _pluginTypeMeta,
          pluginType.isAcceptableOrUnknown(
              data['plugin_type']!, _pluginTypeMeta));
    } else if (isInserting) {
      context.missing(_pluginTypeMeta);
    }
    if (data.containsKey('plugin_author')) {
      context.handle(
          _pluginAuthorMeta,
          pluginAuthor.isAcceptableOrUnknown(
              data['plugin_author']!, _pluginAuthorMeta));
    } else if (isInserting) {
      context.missing(_pluginAuthorMeta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
          _installedAtMeta,
          installedAt.isAcceptableOrUnknown(
              data['installed_at']!, _installedAtMeta));
    }
    if (data.containsKey('installation_path')) {
      context.handle(
          _installationPathMeta,
          installationPath.isAcceptableOrUnknown(
              data['installation_path']!, _installationPathMeta));
    } else if (isInserting) {
      context.missing(_installationPathMeta);
    }
    if (data.containsKey('installation_status')) {
      context.handle(
          _installationStatusMeta,
          installationStatus.isAcceptableOrUnknown(
              data['installation_status']!, _installationStatusMeta));
    }
    if (data.containsKey('marketplace_metadata')) {
      context.handle(
          _marketplaceMetadataMeta,
          marketplaceMetadata.isAcceptableOrUnknown(
              data['marketplace_metadata']!, _marketplaceMetadataMeta));
    }
    if (data.containsKey('repository_url')) {
      context.handle(
          _repositoryUrlMeta,
          repositoryUrl.isAcceptableOrUnknown(
              data['repository_url']!, _repositoryUrlMeta));
    }
    if (data.containsKey('repository_owner')) {
      context.handle(
          _repositoryOwnerMeta,
          repositoryOwner.isAcceptableOrUnknown(
              data['repository_owner']!, _repositoryOwnerMeta));
    }
    if (data.containsKey('repository_name')) {
      context.handle(
          _repositoryNameMeta,
          repositoryName.isAcceptableOrUnknown(
              data['repository_name']!, _repositoryNameMeta));
    }
    if (data.containsKey('file_count')) {
      context.handle(_fileCountMeta,
          fileCount.isAcceptableOrUnknown(data['file_count']!, _fileCountMeta));
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
          _totalBytesMeta,
          totalBytes.isAcceptableOrUnknown(
              data['total_bytes']!, _totalBytesMeta));
    }
    if (data.containsKey('installation_notes')) {
      context.handle(
          _installationNotesMeta,
          installationNotes.isAcceptableOrUnknown(
              data['installation_notes']!, _installationNotesMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PluginInstallationEntry map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PluginInstallationEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      pluginId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plugin_id'])!,
      pluginName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plugin_name'])!,
      pluginVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plugin_version'])!,
      pluginType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plugin_type'])!,
      pluginAuthor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plugin_author'])!,
      installedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}installed_at'])!,
      installationPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}installation_path'])!,
      installationStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}installation_status'])!,
      marketplaceMetadata: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}marketplace_metadata']),
      repositoryUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repository_url']),
      repositoryOwner: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}repository_owner']),
      repositoryName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repository_name']),
      fileCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_count']),
      totalBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_bytes']),
      installationNotes: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}installation_notes']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
    );
  }

  @override
  $PluginInstallationsTable createAlias(String alias) {
    return $PluginInstallationsTable(attachedDatabase, alias);
  }
}

class PluginInstallationEntry extends DataClass
    implements Insertable<PluginInstallationEntry> {
  final int id;
  final String pluginId;
  final String pluginName;
  final String pluginVersion;
  final String pluginType;
  final String pluginAuthor;
  final DateTime installedAt;
  final String installationPath;
  final String installationStatus;
  final String? marketplaceMetadata;
  final String? repositoryUrl;
  final String? repositoryOwner;
  final String? repositoryName;
  final int? fileCount;
  final int? totalBytes;
  final String? installationNotes;
  final String? errorMessage;
  const PluginInstallationEntry(
      {required this.id,
      required this.pluginId,
      required this.pluginName,
      required this.pluginVersion,
      required this.pluginType,
      required this.pluginAuthor,
      required this.installedAt,
      required this.installationPath,
      required this.installationStatus,
      this.marketplaceMetadata,
      this.repositoryUrl,
      this.repositoryOwner,
      this.repositoryName,
      this.fileCount,
      this.totalBytes,
      this.installationNotes,
      this.errorMessage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plugin_id'] = Variable<String>(pluginId);
    map['plugin_name'] = Variable<String>(pluginName);
    map['plugin_version'] = Variable<String>(pluginVersion);
    map['plugin_type'] = Variable<String>(pluginType);
    map['plugin_author'] = Variable<String>(pluginAuthor);
    map['installed_at'] = Variable<DateTime>(installedAt);
    map['installation_path'] = Variable<String>(installationPath);
    map['installation_status'] = Variable<String>(installationStatus);
    if (!nullToAbsent || marketplaceMetadata != null) {
      map['marketplace_metadata'] = Variable<String>(marketplaceMetadata);
    }
    if (!nullToAbsent || repositoryUrl != null) {
      map['repository_url'] = Variable<String>(repositoryUrl);
    }
    if (!nullToAbsent || repositoryOwner != null) {
      map['repository_owner'] = Variable<String>(repositoryOwner);
    }
    if (!nullToAbsent || repositoryName != null) {
      map['repository_name'] = Variable<String>(repositoryName);
    }
    if (!nullToAbsent || fileCount != null) {
      map['file_count'] = Variable<int>(fileCount);
    }
    if (!nullToAbsent || totalBytes != null) {
      map['total_bytes'] = Variable<int>(totalBytes);
    }
    if (!nullToAbsent || installationNotes != null) {
      map['installation_notes'] = Variable<String>(installationNotes);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  PluginInstallationsCompanion toCompanion(bool nullToAbsent) {
    return PluginInstallationsCompanion(
      id: Value(id),
      pluginId: Value(pluginId),
      pluginName: Value(pluginName),
      pluginVersion: Value(pluginVersion),
      pluginType: Value(pluginType),
      pluginAuthor: Value(pluginAuthor),
      installedAt: Value(installedAt),
      installationPath: Value(installationPath),
      installationStatus: Value(installationStatus),
      marketplaceMetadata: marketplaceMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(marketplaceMetadata),
      repositoryUrl: repositoryUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(repositoryUrl),
      repositoryOwner: repositoryOwner == null && nullToAbsent
          ? const Value.absent()
          : Value(repositoryOwner),
      repositoryName: repositoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(repositoryName),
      fileCount: fileCount == null && nullToAbsent
          ? const Value.absent()
          : Value(fileCount),
      totalBytes: totalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBytes),
      installationNotes: installationNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(installationNotes),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory PluginInstallationEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PluginInstallationEntry(
      id: serializer.fromJson<int>(json['id']),
      pluginId: serializer.fromJson<String>(json['pluginId']),
      pluginName: serializer.fromJson<String>(json['pluginName']),
      pluginVersion: serializer.fromJson<String>(json['pluginVersion']),
      pluginType: serializer.fromJson<String>(json['pluginType']),
      pluginAuthor: serializer.fromJson<String>(json['pluginAuthor']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
      installationPath: serializer.fromJson<String>(json['installationPath']),
      installationStatus:
          serializer.fromJson<String>(json['installationStatus']),
      marketplaceMetadata:
          serializer.fromJson<String?>(json['marketplaceMetadata']),
      repositoryUrl: serializer.fromJson<String?>(json['repositoryUrl']),
      repositoryOwner: serializer.fromJson<String?>(json['repositoryOwner']),
      repositoryName: serializer.fromJson<String?>(json['repositoryName']),
      fileCount: serializer.fromJson<int?>(json['fileCount']),
      totalBytes: serializer.fromJson<int?>(json['totalBytes']),
      installationNotes:
          serializer.fromJson<String?>(json['installationNotes']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pluginId': serializer.toJson<String>(pluginId),
      'pluginName': serializer.toJson<String>(pluginName),
      'pluginVersion': serializer.toJson<String>(pluginVersion),
      'pluginType': serializer.toJson<String>(pluginType),
      'pluginAuthor': serializer.toJson<String>(pluginAuthor),
      'installedAt': serializer.toJson<DateTime>(installedAt),
      'installationPath': serializer.toJson<String>(installationPath),
      'installationStatus': serializer.toJson<String>(installationStatus),
      'marketplaceMetadata': serializer.toJson<String?>(marketplaceMetadata),
      'repositoryUrl': serializer.toJson<String?>(repositoryUrl),
      'repositoryOwner': serializer.toJson<String?>(repositoryOwner),
      'repositoryName': serializer.toJson<String?>(repositoryName),
      'fileCount': serializer.toJson<int?>(fileCount),
      'totalBytes': serializer.toJson<int?>(totalBytes),
      'installationNotes': serializer.toJson<String?>(installationNotes),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  PluginInstallationEntry copyWith(
          {int? id,
          String? pluginId,
          String? pluginName,
          String? pluginVersion,
          String? pluginType,
          String? pluginAuthor,
          DateTime? installedAt,
          String? installationPath,
          String? installationStatus,
          Value<String?> marketplaceMetadata = const Value.absent(),
          Value<String?> repositoryUrl = const Value.absent(),
          Value<String?> repositoryOwner = const Value.absent(),
          Value<String?> repositoryName = const Value.absent(),
          Value<int?> fileCount = const Value.absent(),
          Value<int?> totalBytes = const Value.absent(),
          Value<String?> installationNotes = const Value.absent(),
          Value<String?> errorMessage = const Value.absent()}) =>
      PluginInstallationEntry(
        id: id ?? this.id,
        pluginId: pluginId ?? this.pluginId,
        pluginName: pluginName ?? this.pluginName,
        pluginVersion: pluginVersion ?? this.pluginVersion,
        pluginType: pluginType ?? this.pluginType,
        pluginAuthor: pluginAuthor ?? this.pluginAuthor,
        installedAt: installedAt ?? this.installedAt,
        installationPath: installationPath ?? this.installationPath,
        installationStatus: installationStatus ?? this.installationStatus,
        marketplaceMetadata: marketplaceMetadata.present
            ? marketplaceMetadata.value
            : this.marketplaceMetadata,
        repositoryUrl:
            repositoryUrl.present ? repositoryUrl.value : this.repositoryUrl,
        repositoryOwner: repositoryOwner.present
            ? repositoryOwner.value
            : this.repositoryOwner,
        repositoryName:
            repositoryName.present ? repositoryName.value : this.repositoryName,
        fileCount: fileCount.present ? fileCount.value : this.fileCount,
        totalBytes: totalBytes.present ? totalBytes.value : this.totalBytes,
        installationNotes: installationNotes.present
            ? installationNotes.value
            : this.installationNotes,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
      );
  PluginInstallationEntry copyWithCompanion(PluginInstallationsCompanion data) {
    return PluginInstallationEntry(
      id: data.id.present ? data.id.value : this.id,
      pluginId: data.pluginId.present ? data.pluginId.value : this.pluginId,
      pluginName:
          data.pluginName.present ? data.pluginName.value : this.pluginName,
      pluginVersion: data.pluginVersion.present
          ? data.pluginVersion.value
          : this.pluginVersion,
      pluginType:
          data.pluginType.present ? data.pluginType.value : this.pluginType,
      pluginAuthor: data.pluginAuthor.present
          ? data.pluginAuthor.value
          : this.pluginAuthor,
      installedAt:
          data.installedAt.present ? data.installedAt.value : this.installedAt,
      installationPath: data.installationPath.present
          ? data.installationPath.value
          : this.installationPath,
      installationStatus: data.installationStatus.present
          ? data.installationStatus.value
          : this.installationStatus,
      marketplaceMetadata: data.marketplaceMetadata.present
          ? data.marketplaceMetadata.value
          : this.marketplaceMetadata,
      repositoryUrl: data.repositoryUrl.present
          ? data.repositoryUrl.value
          : this.repositoryUrl,
      repositoryOwner: data.repositoryOwner.present
          ? data.repositoryOwner.value
          : this.repositoryOwner,
      repositoryName: data.repositoryName.present
          ? data.repositoryName.value
          : this.repositoryName,
      fileCount: data.fileCount.present ? data.fileCount.value : this.fileCount,
      totalBytes:
          data.totalBytes.present ? data.totalBytes.value : this.totalBytes,
      installationNotes: data.installationNotes.present
          ? data.installationNotes.value
          : this.installationNotes,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PluginInstallationEntry(')
          ..write('id: $id, ')
          ..write('pluginId: $pluginId, ')
          ..write('pluginName: $pluginName, ')
          ..write('pluginVersion: $pluginVersion, ')
          ..write('pluginType: $pluginType, ')
          ..write('pluginAuthor: $pluginAuthor, ')
          ..write('installedAt: $installedAt, ')
          ..write('installationPath: $installationPath, ')
          ..write('installationStatus: $installationStatus, ')
          ..write('marketplaceMetadata: $marketplaceMetadata, ')
          ..write('repositoryUrl: $repositoryUrl, ')
          ..write('repositoryOwner: $repositoryOwner, ')
          ..write('repositoryName: $repositoryName, ')
          ..write('fileCount: $fileCount, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('installationNotes: $installationNotes, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      pluginId,
      pluginName,
      pluginVersion,
      pluginType,
      pluginAuthor,
      installedAt,
      installationPath,
      installationStatus,
      marketplaceMetadata,
      repositoryUrl,
      repositoryOwner,
      repositoryName,
      fileCount,
      totalBytes,
      installationNotes,
      errorMessage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PluginInstallationEntry &&
          other.id == this.id &&
          other.pluginId == this.pluginId &&
          other.pluginName == this.pluginName &&
          other.pluginVersion == this.pluginVersion &&
          other.pluginType == this.pluginType &&
          other.pluginAuthor == this.pluginAuthor &&
          other.installedAt == this.installedAt &&
          other.installationPath == this.installationPath &&
          other.installationStatus == this.installationStatus &&
          other.marketplaceMetadata == this.marketplaceMetadata &&
          other.repositoryUrl == this.repositoryUrl &&
          other.repositoryOwner == this.repositoryOwner &&
          other.repositoryName == this.repositoryName &&
          other.fileCount == this.fileCount &&
          other.totalBytes == this.totalBytes &&
          other.installationNotes == this.installationNotes &&
          other.errorMessage == this.errorMessage);
}

class PluginInstallationsCompanion
    extends UpdateCompanion<PluginInstallationEntry> {
  final Value<int> id;
  final Value<String> pluginId;
  final Value<String> pluginName;
  final Value<String> pluginVersion;
  final Value<String> pluginType;
  final Value<String> pluginAuthor;
  final Value<DateTime> installedAt;
  final Value<String> installationPath;
  final Value<String> installationStatus;
  final Value<String?> marketplaceMetadata;
  final Value<String?> repositoryUrl;
  final Value<String?> repositoryOwner;
  final Value<String?> repositoryName;
  final Value<int?> fileCount;
  final Value<int?> totalBytes;
  final Value<String?> installationNotes;
  final Value<String?> errorMessage;
  const PluginInstallationsCompanion({
    this.id = const Value.absent(),
    this.pluginId = const Value.absent(),
    this.pluginName = const Value.absent(),
    this.pluginVersion = const Value.absent(),
    this.pluginType = const Value.absent(),
    this.pluginAuthor = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.installationPath = const Value.absent(),
    this.installationStatus = const Value.absent(),
    this.marketplaceMetadata = const Value.absent(),
    this.repositoryUrl = const Value.absent(),
    this.repositoryOwner = const Value.absent(),
    this.repositoryName = const Value.absent(),
    this.fileCount = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.installationNotes = const Value.absent(),
    this.errorMessage = const Value.absent(),
  });
  PluginInstallationsCompanion.insert({
    this.id = const Value.absent(),
    required String pluginId,
    required String pluginName,
    required String pluginVersion,
    required String pluginType,
    required String pluginAuthor,
    this.installedAt = const Value.absent(),
    required String installationPath,
    this.installationStatus = const Value.absent(),
    this.marketplaceMetadata = const Value.absent(),
    this.repositoryUrl = const Value.absent(),
    this.repositoryOwner = const Value.absent(),
    this.repositoryName = const Value.absent(),
    this.fileCount = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.installationNotes = const Value.absent(),
    this.errorMessage = const Value.absent(),
  })  : pluginId = Value(pluginId),
        pluginName = Value(pluginName),
        pluginVersion = Value(pluginVersion),
        pluginType = Value(pluginType),
        pluginAuthor = Value(pluginAuthor),
        installationPath = Value(installationPath);
  static Insertable<PluginInstallationEntry> custom({
    Expression<int>? id,
    Expression<String>? pluginId,
    Expression<String>? pluginName,
    Expression<String>? pluginVersion,
    Expression<String>? pluginType,
    Expression<String>? pluginAuthor,
    Expression<DateTime>? installedAt,
    Expression<String>? installationPath,
    Expression<String>? installationStatus,
    Expression<String>? marketplaceMetadata,
    Expression<String>? repositoryUrl,
    Expression<String>? repositoryOwner,
    Expression<String>? repositoryName,
    Expression<int>? fileCount,
    Expression<int>? totalBytes,
    Expression<String>? installationNotes,
    Expression<String>? errorMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pluginId != null) 'plugin_id': pluginId,
      if (pluginName != null) 'plugin_name': pluginName,
      if (pluginVersion != null) 'plugin_version': pluginVersion,
      if (pluginType != null) 'plugin_type': pluginType,
      if (pluginAuthor != null) 'plugin_author': pluginAuthor,
      if (installedAt != null) 'installed_at': installedAt,
      if (installationPath != null) 'installation_path': installationPath,
      if (installationStatus != null) 'installation_status': installationStatus,
      if (marketplaceMetadata != null)
        'marketplace_metadata': marketplaceMetadata,
      if (repositoryUrl != null) 'repository_url': repositoryUrl,
      if (repositoryOwner != null) 'repository_owner': repositoryOwner,
      if (repositoryName != null) 'repository_name': repositoryName,
      if (fileCount != null) 'file_count': fileCount,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (installationNotes != null) 'installation_notes': installationNotes,
      if (errorMessage != null) 'error_message': errorMessage,
    });
  }

  PluginInstallationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? pluginId,
      Value<String>? pluginName,
      Value<String>? pluginVersion,
      Value<String>? pluginType,
      Value<String>? pluginAuthor,
      Value<DateTime>? installedAt,
      Value<String>? installationPath,
      Value<String>? installationStatus,
      Value<String?>? marketplaceMetadata,
      Value<String?>? repositoryUrl,
      Value<String?>? repositoryOwner,
      Value<String?>? repositoryName,
      Value<int?>? fileCount,
      Value<int?>? totalBytes,
      Value<String?>? installationNotes,
      Value<String?>? errorMessage}) {
    return PluginInstallationsCompanion(
      id: id ?? this.id,
      pluginId: pluginId ?? this.pluginId,
      pluginName: pluginName ?? this.pluginName,
      pluginVersion: pluginVersion ?? this.pluginVersion,
      pluginType: pluginType ?? this.pluginType,
      pluginAuthor: pluginAuthor ?? this.pluginAuthor,
      installedAt: installedAt ?? this.installedAt,
      installationPath: installationPath ?? this.installationPath,
      installationStatus: installationStatus ?? this.installationStatus,
      marketplaceMetadata: marketplaceMetadata ?? this.marketplaceMetadata,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
      repositoryOwner: repositoryOwner ?? this.repositoryOwner,
      repositoryName: repositoryName ?? this.repositoryName,
      fileCount: fileCount ?? this.fileCount,
      totalBytes: totalBytes ?? this.totalBytes,
      installationNotes: installationNotes ?? this.installationNotes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pluginId.present) {
      map['plugin_id'] = Variable<String>(pluginId.value);
    }
    if (pluginName.present) {
      map['plugin_name'] = Variable<String>(pluginName.value);
    }
    if (pluginVersion.present) {
      map['plugin_version'] = Variable<String>(pluginVersion.value);
    }
    if (pluginType.present) {
      map['plugin_type'] = Variable<String>(pluginType.value);
    }
    if (pluginAuthor.present) {
      map['plugin_author'] = Variable<String>(pluginAuthor.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (installationPath.present) {
      map['installation_path'] = Variable<String>(installationPath.value);
    }
    if (installationStatus.present) {
      map['installation_status'] = Variable<String>(installationStatus.value);
    }
    if (marketplaceMetadata.present) {
      map['marketplace_metadata'] = Variable<String>(marketplaceMetadata.value);
    }
    if (repositoryUrl.present) {
      map['repository_url'] = Variable<String>(repositoryUrl.value);
    }
    if (repositoryOwner.present) {
      map['repository_owner'] = Variable<String>(repositoryOwner.value);
    }
    if (repositoryName.present) {
      map['repository_name'] = Variable<String>(repositoryName.value);
    }
    if (fileCount.present) {
      map['file_count'] = Variable<int>(fileCount.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (installationNotes.present) {
      map['installation_notes'] = Variable<String>(installationNotes.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PluginInstallationsCompanion(')
          ..write('id: $id, ')
          ..write('pluginId: $pluginId, ')
          ..write('pluginName: $pluginName, ')
          ..write('pluginVersion: $pluginVersion, ')
          ..write('pluginType: $pluginType, ')
          ..write('pluginAuthor: $pluginAuthor, ')
          ..write('installedAt: $installedAt, ')
          ..write('installationPath: $installationPath, ')
          ..write('installationStatus: $installationStatus, ')
          ..write('marketplaceMetadata: $marketplaceMetadata, ')
          ..write('repositoryUrl: $repositoryUrl, ')
          ..write('repositoryOwner: $repositoryOwner, ')
          ..write('repositoryName: $repositoryName, ')
          ..write('fileCount: $fileCount, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('installationNotes: $installationNotes, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AlgorithmsTable algorithms = $AlgorithmsTable(this);
  late final $SpecificationsTable specifications = $SpecificationsTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $ParametersTable parameters = $ParametersTable(this);
  late final $ParameterEnumsTable parameterEnums = $ParameterEnumsTable(this);
  late final $ParameterPagesTable parameterPages = $ParameterPagesTable(this);
  late final $ParameterPageItemsTable parameterPageItems =
      $ParameterPageItemsTable(this);
  late final $PresetsTable presets = $PresetsTable(this);
  late final $PresetSlotsTable presetSlots = $PresetSlotsTable(this);
  late final $PresetParameterValuesTable presetParameterValues =
      $PresetParameterValuesTable(this);
  late final $PresetParameterStringValuesTable presetParameterStringValues =
      $PresetParameterStringValuesTable(this);
  late final $PresetMappingsTable presetMappings = $PresetMappingsTable(this);
  late final $PresetRoutingsTable presetRoutings = $PresetRoutingsTable(this);
  late final $SdCardsTable sdCards = $SdCardsTable(this);
  late final $IndexedPresetFilesTable indexedPresetFiles =
      $IndexedPresetFilesTable(this);
  late final $MetadataCacheTable metadataCache = $MetadataCacheTable(this);
  late final $PluginInstallationsTable pluginInstallations =
      $PluginInstallationsTable(this);
  late final MetadataDao metadataDao = MetadataDao(this as AppDatabase);
  late final PresetsDao presetsDao = PresetsDao(this as AppDatabase);
  late final SdCardsDao sdCardsDao = SdCardsDao(this as AppDatabase);
  late final IndexedPresetFilesDao indexedPresetFilesDao =
      IndexedPresetFilesDao(this as AppDatabase);
  late final PluginInstallationsDao pluginInstallationsDao =
      PluginInstallationsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        algorithms,
        specifications,
        units,
        parameters,
        parameterEnums,
        parameterPages,
        parameterPageItems,
        presets,
        presetSlots,
        presetParameterValues,
        presetParameterStringValues,
        presetMappings,
        presetRoutings,
        sdCards,
        indexedPresetFiles,
        metadataCache,
        pluginInstallations
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('preset_slots',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('preset_parameter_values', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('preset_slots',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('preset_parameter_string_values',
                  kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$AlgorithmsTableCreateCompanionBuilder = AlgorithmsCompanion Function({
  required String guid,
  required String name,
  required int numSpecifications,
  Value<String?> pluginFilePath,
  Value<int> rowid,
});
typedef $$AlgorithmsTableUpdateCompanionBuilder = AlgorithmsCompanion Function({
  Value<String> guid,
  Value<String> name,
  Value<int> numSpecifications,
  Value<String?> pluginFilePath,
  Value<int> rowid,
});

final class $$AlgorithmsTableReferences
    extends BaseReferences<_$AppDatabase, $AlgorithmsTable, AlgorithmEntry> {
  $$AlgorithmsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SpecificationsTable, List<SpecificationEntry>>
      _specificationsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.specifications,
              aliasName: $_aliasNameGenerator(
                  db.algorithms.guid, db.specifications.algorithmGuid));

  $$SpecificationsTableProcessedTableManager get specificationsRefs {
    final manager = $$SpecificationsTableTableManager($_db, $_db.specifications)
        .filter((f) =>
            f.algorithmGuid.guid.sqlEquals($_itemColumn<String>('guid')!));

    final cache = $_typedResult.readTableOrNull(_specificationsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ParametersTable, List<ParameterEntry>>
      _parametersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.parameters,
              aliasName: $_aliasNameGenerator(
                  db.algorithms.guid, db.parameters.algorithmGuid));

  $$ParametersTableProcessedTableManager get parametersRefs {
    final manager = $$ParametersTableTableManager($_db, $_db.parameters).filter(
        (f) => f.algorithmGuid.guid.sqlEquals($_itemColumn<String>('guid')!));

    final cache = $_typedResult.readTableOrNull(_parametersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ParameterPagesTable, List<ParameterPageEntry>>
      _parameterPagesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.parameterPages,
              aliasName: $_aliasNameGenerator(
                  db.algorithms.guid, db.parameterPages.algorithmGuid));

  $$ParameterPagesTableProcessedTableManager get parameterPagesRefs {
    final manager = $$ParameterPagesTableTableManager($_db, $_db.parameterPages)
        .filter((f) =>
            f.algorithmGuid.guid.sqlEquals($_itemColumn<String>('guid')!));

    final cache = $_typedResult.readTableOrNull(_parameterPagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PresetSlotsTable, List<PresetSlotEntry>>
      _presetSlotsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.presetSlots,
              aliasName: $_aliasNameGenerator(
                  db.algorithms.guid, db.presetSlots.algorithmGuid));

  $$PresetSlotsTableProcessedTableManager get presetSlotsRefs {
    final manager = $$PresetSlotsTableTableManager($_db, $_db.presetSlots)
        .filter((f) =>
            f.algorithmGuid.guid.sqlEquals($_itemColumn<String>('guid')!));

    final cache = $_typedResult.readTableOrNull(_presetSlotsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AlgorithmsTableFilterComposer
    extends Composer<_$AppDatabase, $AlgorithmsTable> {
  $$AlgorithmsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get guid => $composableBuilder(
      column: $table.guid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numSpecifications => $composableBuilder(
      column: $table.numSpecifications,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pluginFilePath => $composableBuilder(
      column: $table.pluginFilePath,
      builder: (column) => ColumnFilters(column));

  Expression<bool> specificationsRefs(
      Expression<bool> Function($$SpecificationsTableFilterComposer f) f) {
    final $$SpecificationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.guid,
        referencedTable: $db.specifications,
        getReferencedColumn: (t) => t.algorithmGuid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SpecificationsTableFilterComposer(
              $db: $db,
              $table: $db.specifications,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> parametersRefs(
      Expression<bool> Function($$ParametersTableFilterComposer f) f) {
    final $$ParametersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.guid,
        referencedTable: $db.parameters,
        getReferencedColumn: (t) => t.algorithmGuid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ParametersTableFilterComposer(
              $db: $db,
              $table: $db.parameters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> parameterPagesRefs(
      Expression<bool> Function($$ParameterPagesTableFilterComposer f) f) {
    final $$ParameterPagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.guid,
        referencedTable: $db.parameterPages,
        getReferencedColumn: (t) => t.algorithmGuid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ParameterPagesTableFilterComposer(
              $db: $db,
              $table: $db.parameterPages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> presetSlotsRefs(
      Expression<bool> Function($$PresetSlotsTableFilterComposer f) f) {
    final $$PresetSlotsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.guid,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.algorithmGuid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableFilterComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AlgorithmsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlgorithmsTable> {
  $$AlgorithmsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get guid => $composableBuilder(
      column: $table.guid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numSpecifications => $composableBuilder(
      column: $table.numSpecifications,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pluginFilePath => $composableBuilder(
      column: $table.pluginFilePath,
      builder: (column) => ColumnOrderings(column));
}

class $$AlgorithmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlgorithmsTable> {
  $$AlgorithmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get numSpecifications => $composableBuilder(
      column: $table.numSpecifications, builder: (column) => column);

  GeneratedColumn<String> get pluginFilePath => $composableBuilder(
      column: $table.pluginFilePath, builder: (column) => column);

  Expression<T> specificationsRefs<T extends Object>(
      Expression<T> Function($$SpecificationsTableAnnotationComposer a) f) {
    final $$SpecificationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.guid,
        referencedTable: $db.specifications,
        getReferencedColumn: (t) => t.algorithmGuid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SpecificationsTableAnnotationComposer(
              $db: $db,
              $table: $db.specifications,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> parametersRefs<T extends Object>(
      Expression<T> Function($$ParametersTableAnnotationComposer a) f) {
    final $$ParametersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.guid,
        referencedTable: $db.parameters,
        getReferencedColumn: (t) => t.algorithmGuid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ParametersTableAnnotationComposer(
              $db: $db,
              $table: $db.parameters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> parameterPagesRefs<T extends Object>(
      Expression<T> Function($$ParameterPagesTableAnnotationComposer a) f) {
    final $$ParameterPagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.guid,
        referencedTable: $db.parameterPages,
        getReferencedColumn: (t) => t.algorithmGuid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ParameterPagesTableAnnotationComposer(
              $db: $db,
              $table: $db.parameterPages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> presetSlotsRefs<T extends Object>(
      Expression<T> Function($$PresetSlotsTableAnnotationComposer a) f) {
    final $$PresetSlotsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.guid,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.algorithmGuid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableAnnotationComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AlgorithmsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AlgorithmsTable,
    AlgorithmEntry,
    $$AlgorithmsTableFilterComposer,
    $$AlgorithmsTableOrderingComposer,
    $$AlgorithmsTableAnnotationComposer,
    $$AlgorithmsTableCreateCompanionBuilder,
    $$AlgorithmsTableUpdateCompanionBuilder,
    (AlgorithmEntry, $$AlgorithmsTableReferences),
    AlgorithmEntry,
    PrefetchHooks Function(
        {bool specificationsRefs,
        bool parametersRefs,
        bool parameterPagesRefs,
        bool presetSlotsRefs})> {
  $$AlgorithmsTableTableManager(_$AppDatabase db, $AlgorithmsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlgorithmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlgorithmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlgorithmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> guid = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> numSpecifications = const Value.absent(),
            Value<String?> pluginFilePath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AlgorithmsCompanion(
            guid: guid,
            name: name,
            numSpecifications: numSpecifications,
            pluginFilePath: pluginFilePath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String guid,
            required String name,
            required int numSpecifications,
            Value<String?> pluginFilePath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AlgorithmsCompanion.insert(
            guid: guid,
            name: name,
            numSpecifications: numSpecifications,
            pluginFilePath: pluginFilePath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AlgorithmsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {specificationsRefs = false,
              parametersRefs = false,
              parameterPagesRefs = false,
              presetSlotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (specificationsRefs) db.specifications,
                if (parametersRefs) db.parameters,
                if (parameterPagesRefs) db.parameterPages,
                if (presetSlotsRefs) db.presetSlots
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (specificationsRefs)
                    await $_getPrefetchedData<AlgorithmEntry, $AlgorithmsTable,
                            SpecificationEntry>(
                        currentTable: table,
                        referencedTable: $$AlgorithmsTableReferences
                            ._specificationsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AlgorithmsTableReferences(db, table, p0)
                                .specificationsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.algorithmGuid == item.guid),
                        typedResults: items),
                  if (parametersRefs)
                    await $_getPrefetchedData<AlgorithmEntry, $AlgorithmsTable,
                            ParameterEntry>(
                        currentTable: table,
                        referencedTable: $$AlgorithmsTableReferences
                            ._parametersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AlgorithmsTableReferences(db, table, p0)
                                .parametersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.algorithmGuid == item.guid),
                        typedResults: items),
                  if (parameterPagesRefs)
                    await $_getPrefetchedData<AlgorithmEntry, $AlgorithmsTable,
                            ParameterPageEntry>(
                        currentTable: table,
                        referencedTable: $$AlgorithmsTableReferences
                            ._parameterPagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AlgorithmsTableReferences(db, table, p0)
                                .parameterPagesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.algorithmGuid == item.guid),
                        typedResults: items),
                  if (presetSlotsRefs)
                    await $_getPrefetchedData<AlgorithmEntry, $AlgorithmsTable,
                            PresetSlotEntry>(
                        currentTable: table,
                        referencedTable: $$AlgorithmsTableReferences
                            ._presetSlotsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AlgorithmsTableReferences(db, table, p0)
                                .presetSlotsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.algorithmGuid == item.guid),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AlgorithmsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AlgorithmsTable,
    AlgorithmEntry,
    $$AlgorithmsTableFilterComposer,
    $$AlgorithmsTableOrderingComposer,
    $$AlgorithmsTableAnnotationComposer,
    $$AlgorithmsTableCreateCompanionBuilder,
    $$AlgorithmsTableUpdateCompanionBuilder,
    (AlgorithmEntry, $$AlgorithmsTableReferences),
    AlgorithmEntry,
    PrefetchHooks Function(
        {bool specificationsRefs,
        bool parametersRefs,
        bool parameterPagesRefs,
        bool presetSlotsRefs})>;
typedef $$SpecificationsTableCreateCompanionBuilder = SpecificationsCompanion
    Function({
  required String algorithmGuid,
  required int specIndex,
  required String name,
  required int minValue,
  required int maxValue,
  required int defaultValue,
  required int type,
  Value<int> rowid,
});
typedef $$SpecificationsTableUpdateCompanionBuilder = SpecificationsCompanion
    Function({
  Value<String> algorithmGuid,
  Value<int> specIndex,
  Value<String> name,
  Value<int> minValue,
  Value<int> maxValue,
  Value<int> defaultValue,
  Value<int> type,
  Value<int> rowid,
});

final class $$SpecificationsTableReferences extends BaseReferences<
    _$AppDatabase, $SpecificationsTable, SpecificationEntry> {
  $$SpecificationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AlgorithmsTable _algorithmGuidTable(_$AppDatabase db) =>
      db.algorithms.createAlias($_aliasNameGenerator(
          db.specifications.algorithmGuid, db.algorithms.guid));

  $$AlgorithmsTableProcessedTableManager get algorithmGuid {
    final $_column = $_itemColumn<String>('algorithm_guid')!;

    final manager = $$AlgorithmsTableTableManager($_db, $_db.algorithms)
        .filter((f) => f.guid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_algorithmGuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SpecificationsTableFilterComposer
    extends Composer<_$AppDatabase, $SpecificationsTable> {
  $$SpecificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get specIndex => $composableBuilder(
      column: $table.specIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minValue => $composableBuilder(
      column: $table.minValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxValue => $composableBuilder(
      column: $table.maxValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get defaultValue => $composableBuilder(
      column: $table.defaultValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  $$AlgorithmsTableFilterComposer get algorithmGuid {
    final $$AlgorithmsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableFilterComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SpecificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SpecificationsTable> {
  $$SpecificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get specIndex => $composableBuilder(
      column: $table.specIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minValue => $composableBuilder(
      column: $table.minValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxValue => $composableBuilder(
      column: $table.maxValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get defaultValue => $composableBuilder(
      column: $table.defaultValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  $$AlgorithmsTableOrderingComposer get algorithmGuid {
    final $$AlgorithmsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableOrderingComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SpecificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpecificationsTable> {
  $$SpecificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get specIndex =>
      $composableBuilder(column: $table.specIndex, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get minValue =>
      $composableBuilder(column: $table.minValue, builder: (column) => column);

  GeneratedColumn<int> get maxValue =>
      $composableBuilder(column: $table.maxValue, builder: (column) => column);

  GeneratedColumn<int> get defaultValue => $composableBuilder(
      column: $table.defaultValue, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  $$AlgorithmsTableAnnotationComposer get algorithmGuid {
    final $$AlgorithmsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableAnnotationComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SpecificationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SpecificationsTable,
    SpecificationEntry,
    $$SpecificationsTableFilterComposer,
    $$SpecificationsTableOrderingComposer,
    $$SpecificationsTableAnnotationComposer,
    $$SpecificationsTableCreateCompanionBuilder,
    $$SpecificationsTableUpdateCompanionBuilder,
    (SpecificationEntry, $$SpecificationsTableReferences),
    SpecificationEntry,
    PrefetchHooks Function({bool algorithmGuid})> {
  $$SpecificationsTableTableManager(
      _$AppDatabase db, $SpecificationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpecificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpecificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpecificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> algorithmGuid = const Value.absent(),
            Value<int> specIndex = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> minValue = const Value.absent(),
            Value<int> maxValue = const Value.absent(),
            Value<int> defaultValue = const Value.absent(),
            Value<int> type = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SpecificationsCompanion(
            algorithmGuid: algorithmGuid,
            specIndex: specIndex,
            name: name,
            minValue: minValue,
            maxValue: maxValue,
            defaultValue: defaultValue,
            type: type,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String algorithmGuid,
            required int specIndex,
            required String name,
            required int minValue,
            required int maxValue,
            required int defaultValue,
            required int type,
            Value<int> rowid = const Value.absent(),
          }) =>
              SpecificationsCompanion.insert(
            algorithmGuid: algorithmGuid,
            specIndex: specIndex,
            name: name,
            minValue: minValue,
            maxValue: maxValue,
            defaultValue: defaultValue,
            type: type,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SpecificationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({algorithmGuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (algorithmGuid) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.algorithmGuid,
                    referencedTable:
                        $$SpecificationsTableReferences._algorithmGuidTable(db),
                    referencedColumn: $$SpecificationsTableReferences
                        ._algorithmGuidTable(db)
                        .guid,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SpecificationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SpecificationsTable,
    SpecificationEntry,
    $$SpecificationsTableFilterComposer,
    $$SpecificationsTableOrderingComposer,
    $$SpecificationsTableAnnotationComposer,
    $$SpecificationsTableCreateCompanionBuilder,
    $$SpecificationsTableUpdateCompanionBuilder,
    (SpecificationEntry, $$SpecificationsTableReferences),
    SpecificationEntry,
    PrefetchHooks Function({bool algorithmGuid})>;
typedef $$UnitsTableCreateCompanionBuilder = UnitsCompanion Function({
  Value<int> id,
  required String unitString,
});
typedef $$UnitsTableUpdateCompanionBuilder = UnitsCompanion Function({
  Value<int> id,
  Value<String> unitString,
});

final class $$UnitsTableReferences
    extends BaseReferences<_$AppDatabase, $UnitsTable, UnitEntry> {
  $$UnitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ParametersTable, List<ParameterEntry>>
      _parametersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.parameters,
          aliasName: $_aliasNameGenerator(db.units.id, db.parameters.unitId));

  $$ParametersTableProcessedTableManager get parametersRefs {
    final manager = $$ParametersTableTableManager($_db, $_db.parameters)
        .filter((f) => f.unitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_parametersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UnitsTableFilterComposer extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitString => $composableBuilder(
      column: $table.unitString, builder: (column) => ColumnFilters(column));

  Expression<bool> parametersRefs(
      Expression<bool> Function($$ParametersTableFilterComposer f) f) {
    final $$ParametersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.parameters,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ParametersTableFilterComposer(
              $db: $db,
              $table: $db.parameters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitString => $composableBuilder(
      column: $table.unitString, builder: (column) => ColumnOrderings(column));
}

class $$UnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get unitString => $composableBuilder(
      column: $table.unitString, builder: (column) => column);

  Expression<T> parametersRefs<T extends Object>(
      Expression<T> Function($$ParametersTableAnnotationComposer a) f) {
    final $$ParametersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.parameters,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ParametersTableAnnotationComposer(
              $db: $db,
              $table: $db.parameters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UnitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UnitsTable,
    UnitEntry,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (UnitEntry, $$UnitsTableReferences),
    UnitEntry,
    PrefetchHooks Function({bool parametersRefs})> {
  $$UnitsTableTableManager(_$AppDatabase db, $UnitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> unitString = const Value.absent(),
          }) =>
              UnitsCompanion(
            id: id,
            unitString: unitString,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String unitString,
          }) =>
              UnitsCompanion.insert(
            id: id,
            unitString: unitString,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$UnitsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({parametersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (parametersRefs) db.parameters],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (parametersRefs)
                    await $_getPrefetchedData<UnitEntry, $UnitsTable,
                            ParameterEntry>(
                        currentTable: table,
                        referencedTable:
                            $$UnitsTableReferences._parametersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsTableReferences(db, table, p0)
                                .parametersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.unitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UnitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UnitsTable,
    UnitEntry,
    $$UnitsTableFilterComposer,
    $$UnitsTableOrderingComposer,
    $$UnitsTableAnnotationComposer,
    $$UnitsTableCreateCompanionBuilder,
    $$UnitsTableUpdateCompanionBuilder,
    (UnitEntry, $$UnitsTableReferences),
    UnitEntry,
    PrefetchHooks Function({bool parametersRefs})>;
typedef $$ParametersTableCreateCompanionBuilder = ParametersCompanion Function({
  required String algorithmGuid,
  required int parameterNumber,
  required String name,
  Value<int?> minValue,
  Value<int?> maxValue,
  Value<int?> defaultValue,
  Value<int?> unitId,
  Value<int?> powerOfTen,
  Value<int?> rawUnitIndex,
  Value<int> rowid,
});
typedef $$ParametersTableUpdateCompanionBuilder = ParametersCompanion Function({
  Value<String> algorithmGuid,
  Value<int> parameterNumber,
  Value<String> name,
  Value<int?> minValue,
  Value<int?> maxValue,
  Value<int?> defaultValue,
  Value<int?> unitId,
  Value<int?> powerOfTen,
  Value<int?> rawUnitIndex,
  Value<int> rowid,
});

final class $$ParametersTableReferences
    extends BaseReferences<_$AppDatabase, $ParametersTable, ParameterEntry> {
  $$ParametersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AlgorithmsTable _algorithmGuidTable(_$AppDatabase db) =>
      db.algorithms.createAlias($_aliasNameGenerator(
          db.parameters.algorithmGuid, db.algorithms.guid));

  $$AlgorithmsTableProcessedTableManager get algorithmGuid {
    final $_column = $_itemColumn<String>('algorithm_guid')!;

    final manager = $$AlgorithmsTableTableManager($_db, $_db.algorithms)
        .filter((f) => f.guid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_algorithmGuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UnitsTable _unitIdTable(_$AppDatabase db) => db.units
      .createAlias($_aliasNameGenerator(db.parameters.unitId, db.units.id));

  $$UnitsTableProcessedTableManager? get unitId {
    final $_column = $_itemColumn<int>('unit_id');
    if ($_column == null) return null;
    final manager = $$UnitsTableTableManager($_db, $_db.units)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ParametersTableFilterComposer
    extends Composer<_$AppDatabase, $ParametersTable> {
  $$ParametersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minValue => $composableBuilder(
      column: $table.minValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxValue => $composableBuilder(
      column: $table.maxValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get defaultValue => $composableBuilder(
      column: $table.defaultValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get powerOfTen => $composableBuilder(
      column: $table.powerOfTen, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rawUnitIndex => $composableBuilder(
      column: $table.rawUnitIndex, builder: (column) => ColumnFilters(column));

  $$AlgorithmsTableFilterComposer get algorithmGuid {
    final $$AlgorithmsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableFilterComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableFilterComposer get unitId {
    final $$UnitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableFilterComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ParametersTableOrderingComposer
    extends Composer<_$AppDatabase, $ParametersTable> {
  $$ParametersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minValue => $composableBuilder(
      column: $table.minValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxValue => $composableBuilder(
      column: $table.maxValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get defaultValue => $composableBuilder(
      column: $table.defaultValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get powerOfTen => $composableBuilder(
      column: $table.powerOfTen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rawUnitIndex => $composableBuilder(
      column: $table.rawUnitIndex,
      builder: (column) => ColumnOrderings(column));

  $$AlgorithmsTableOrderingComposer get algorithmGuid {
    final $$AlgorithmsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableOrderingComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableOrderingComposer get unitId {
    final $$UnitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableOrderingComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ParametersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParametersTable> {
  $$ParametersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get minValue =>
      $composableBuilder(column: $table.minValue, builder: (column) => column);

  GeneratedColumn<int> get maxValue =>
      $composableBuilder(column: $table.maxValue, builder: (column) => column);

  GeneratedColumn<int> get defaultValue => $composableBuilder(
      column: $table.defaultValue, builder: (column) => column);

  GeneratedColumn<int> get powerOfTen => $composableBuilder(
      column: $table.powerOfTen, builder: (column) => column);

  GeneratedColumn<int> get rawUnitIndex => $composableBuilder(
      column: $table.rawUnitIndex, builder: (column) => column);

  $$AlgorithmsTableAnnotationComposer get algorithmGuid {
    final $$AlgorithmsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableAnnotationComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$UnitsTableAnnotationComposer get unitId {
    final $$UnitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.units,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsTableAnnotationComposer(
              $db: $db,
              $table: $db.units,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ParametersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ParametersTable,
    ParameterEntry,
    $$ParametersTableFilterComposer,
    $$ParametersTableOrderingComposer,
    $$ParametersTableAnnotationComposer,
    $$ParametersTableCreateCompanionBuilder,
    $$ParametersTableUpdateCompanionBuilder,
    (ParameterEntry, $$ParametersTableReferences),
    ParameterEntry,
    PrefetchHooks Function({bool algorithmGuid, bool unitId})> {
  $$ParametersTableTableManager(_$AppDatabase db, $ParametersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParametersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParametersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParametersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> algorithmGuid = const Value.absent(),
            Value<int> parameterNumber = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> minValue = const Value.absent(),
            Value<int?> maxValue = const Value.absent(),
            Value<int?> defaultValue = const Value.absent(),
            Value<int?> unitId = const Value.absent(),
            Value<int?> powerOfTen = const Value.absent(),
            Value<int?> rawUnitIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ParametersCompanion(
            algorithmGuid: algorithmGuid,
            parameterNumber: parameterNumber,
            name: name,
            minValue: minValue,
            maxValue: maxValue,
            defaultValue: defaultValue,
            unitId: unitId,
            powerOfTen: powerOfTen,
            rawUnitIndex: rawUnitIndex,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String algorithmGuid,
            required int parameterNumber,
            required String name,
            Value<int?> minValue = const Value.absent(),
            Value<int?> maxValue = const Value.absent(),
            Value<int?> defaultValue = const Value.absent(),
            Value<int?> unitId = const Value.absent(),
            Value<int?> powerOfTen = const Value.absent(),
            Value<int?> rawUnitIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ParametersCompanion.insert(
            algorithmGuid: algorithmGuid,
            parameterNumber: parameterNumber,
            name: name,
            minValue: minValue,
            maxValue: maxValue,
            defaultValue: defaultValue,
            unitId: unitId,
            powerOfTen: powerOfTen,
            rawUnitIndex: rawUnitIndex,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ParametersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({algorithmGuid = false, unitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (algorithmGuid) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.algorithmGuid,
                    referencedTable:
                        $$ParametersTableReferences._algorithmGuidTable(db),
                    referencedColumn: $$ParametersTableReferences
                        ._algorithmGuidTable(db)
                        .guid,
                  ) as T;
                }
                if (unitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitId,
                    referencedTable:
                        $$ParametersTableReferences._unitIdTable(db),
                    referencedColumn:
                        $$ParametersTableReferences._unitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ParametersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ParametersTable,
    ParameterEntry,
    $$ParametersTableFilterComposer,
    $$ParametersTableOrderingComposer,
    $$ParametersTableAnnotationComposer,
    $$ParametersTableCreateCompanionBuilder,
    $$ParametersTableUpdateCompanionBuilder,
    (ParameterEntry, $$ParametersTableReferences),
    ParameterEntry,
    PrefetchHooks Function({bool algorithmGuid, bool unitId})>;
typedef $$ParameterEnumsTableCreateCompanionBuilder = ParameterEnumsCompanion
    Function({
  required String algorithmGuid,
  required int parameterNumber,
  required int enumIndex,
  required String enumString,
  Value<int> rowid,
});
typedef $$ParameterEnumsTableUpdateCompanionBuilder = ParameterEnumsCompanion
    Function({
  Value<String> algorithmGuid,
  Value<int> parameterNumber,
  Value<int> enumIndex,
  Value<String> enumString,
  Value<int> rowid,
});

class $$ParameterEnumsTableFilterComposer
    extends Composer<_$AppDatabase, $ParameterEnumsTable> {
  $$ParameterEnumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get algorithmGuid => $composableBuilder(
      column: $table.algorithmGuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get enumIndex => $composableBuilder(
      column: $table.enumIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get enumString => $composableBuilder(
      column: $table.enumString, builder: (column) => ColumnFilters(column));
}

class $$ParameterEnumsTableOrderingComposer
    extends Composer<_$AppDatabase, $ParameterEnumsTable> {
  $$ParameterEnumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get algorithmGuid => $composableBuilder(
      column: $table.algorithmGuid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get enumIndex => $composableBuilder(
      column: $table.enumIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get enumString => $composableBuilder(
      column: $table.enumString, builder: (column) => ColumnOrderings(column));
}

class $$ParameterEnumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParameterEnumsTable> {
  $$ParameterEnumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get algorithmGuid => $composableBuilder(
      column: $table.algorithmGuid, builder: (column) => column);

  GeneratedColumn<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber, builder: (column) => column);

  GeneratedColumn<int> get enumIndex =>
      $composableBuilder(column: $table.enumIndex, builder: (column) => column);

  GeneratedColumn<String> get enumString => $composableBuilder(
      column: $table.enumString, builder: (column) => column);
}

class $$ParameterEnumsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ParameterEnumsTable,
    ParameterEnumEntry,
    $$ParameterEnumsTableFilterComposer,
    $$ParameterEnumsTableOrderingComposer,
    $$ParameterEnumsTableAnnotationComposer,
    $$ParameterEnumsTableCreateCompanionBuilder,
    $$ParameterEnumsTableUpdateCompanionBuilder,
    (
      ParameterEnumEntry,
      BaseReferences<_$AppDatabase, $ParameterEnumsTable, ParameterEnumEntry>
    ),
    ParameterEnumEntry,
    PrefetchHooks Function()> {
  $$ParameterEnumsTableTableManager(
      _$AppDatabase db, $ParameterEnumsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParameterEnumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParameterEnumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParameterEnumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> algorithmGuid = const Value.absent(),
            Value<int> parameterNumber = const Value.absent(),
            Value<int> enumIndex = const Value.absent(),
            Value<String> enumString = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ParameterEnumsCompanion(
            algorithmGuid: algorithmGuid,
            parameterNumber: parameterNumber,
            enumIndex: enumIndex,
            enumString: enumString,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String algorithmGuid,
            required int parameterNumber,
            required int enumIndex,
            required String enumString,
            Value<int> rowid = const Value.absent(),
          }) =>
              ParameterEnumsCompanion.insert(
            algorithmGuid: algorithmGuid,
            parameterNumber: parameterNumber,
            enumIndex: enumIndex,
            enumString: enumString,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ParameterEnumsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ParameterEnumsTable,
    ParameterEnumEntry,
    $$ParameterEnumsTableFilterComposer,
    $$ParameterEnumsTableOrderingComposer,
    $$ParameterEnumsTableAnnotationComposer,
    $$ParameterEnumsTableCreateCompanionBuilder,
    $$ParameterEnumsTableUpdateCompanionBuilder,
    (
      ParameterEnumEntry,
      BaseReferences<_$AppDatabase, $ParameterEnumsTable, ParameterEnumEntry>
    ),
    ParameterEnumEntry,
    PrefetchHooks Function()>;
typedef $$ParameterPagesTableCreateCompanionBuilder = ParameterPagesCompanion
    Function({
  required String algorithmGuid,
  required int pageIndex,
  required String name,
  Value<int> rowid,
});
typedef $$ParameterPagesTableUpdateCompanionBuilder = ParameterPagesCompanion
    Function({
  Value<String> algorithmGuid,
  Value<int> pageIndex,
  Value<String> name,
  Value<int> rowid,
});

final class $$ParameterPagesTableReferences extends BaseReferences<
    _$AppDatabase, $ParameterPagesTable, ParameterPageEntry> {
  $$ParameterPagesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AlgorithmsTable _algorithmGuidTable(_$AppDatabase db) =>
      db.algorithms.createAlias($_aliasNameGenerator(
          db.parameterPages.algorithmGuid, db.algorithms.guid));

  $$AlgorithmsTableProcessedTableManager get algorithmGuid {
    final $_column = $_itemColumn<String>('algorithm_guid')!;

    final manager = $$AlgorithmsTableTableManager($_db, $_db.algorithms)
        .filter((f) => f.guid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_algorithmGuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ParameterPagesTableFilterComposer
    extends Composer<_$AppDatabase, $ParameterPagesTable> {
  $$ParameterPagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get pageIndex => $composableBuilder(
      column: $table.pageIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  $$AlgorithmsTableFilterComposer get algorithmGuid {
    final $$AlgorithmsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableFilterComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ParameterPagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ParameterPagesTable> {
  $$ParameterPagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get pageIndex => $composableBuilder(
      column: $table.pageIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  $$AlgorithmsTableOrderingComposer get algorithmGuid {
    final $$AlgorithmsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableOrderingComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ParameterPagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParameterPagesTable> {
  $$ParameterPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$AlgorithmsTableAnnotationComposer get algorithmGuid {
    final $$AlgorithmsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableAnnotationComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ParameterPagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ParameterPagesTable,
    ParameterPageEntry,
    $$ParameterPagesTableFilterComposer,
    $$ParameterPagesTableOrderingComposer,
    $$ParameterPagesTableAnnotationComposer,
    $$ParameterPagesTableCreateCompanionBuilder,
    $$ParameterPagesTableUpdateCompanionBuilder,
    (ParameterPageEntry, $$ParameterPagesTableReferences),
    ParameterPageEntry,
    PrefetchHooks Function({bool algorithmGuid})> {
  $$ParameterPagesTableTableManager(
      _$AppDatabase db, $ParameterPagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParameterPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParameterPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParameterPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> algorithmGuid = const Value.absent(),
            Value<int> pageIndex = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ParameterPagesCompanion(
            algorithmGuid: algorithmGuid,
            pageIndex: pageIndex,
            name: name,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String algorithmGuid,
            required int pageIndex,
            required String name,
            Value<int> rowid = const Value.absent(),
          }) =>
              ParameterPagesCompanion.insert(
            algorithmGuid: algorithmGuid,
            pageIndex: pageIndex,
            name: name,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ParameterPagesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({algorithmGuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (algorithmGuid) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.algorithmGuid,
                    referencedTable:
                        $$ParameterPagesTableReferences._algorithmGuidTable(db),
                    referencedColumn: $$ParameterPagesTableReferences
                        ._algorithmGuidTable(db)
                        .guid,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ParameterPagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ParameterPagesTable,
    ParameterPageEntry,
    $$ParameterPagesTableFilterComposer,
    $$ParameterPagesTableOrderingComposer,
    $$ParameterPagesTableAnnotationComposer,
    $$ParameterPagesTableCreateCompanionBuilder,
    $$ParameterPagesTableUpdateCompanionBuilder,
    (ParameterPageEntry, $$ParameterPagesTableReferences),
    ParameterPageEntry,
    PrefetchHooks Function({bool algorithmGuid})>;
typedef $$ParameterPageItemsTableCreateCompanionBuilder
    = ParameterPageItemsCompanion Function({
  required String algorithmGuid,
  required int pageIndex,
  required int parameterNumber,
  Value<int> rowid,
});
typedef $$ParameterPageItemsTableUpdateCompanionBuilder
    = ParameterPageItemsCompanion Function({
  Value<String> algorithmGuid,
  Value<int> pageIndex,
  Value<int> parameterNumber,
  Value<int> rowid,
});

class $$ParameterPageItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ParameterPageItemsTable> {
  $$ParameterPageItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get algorithmGuid => $composableBuilder(
      column: $table.algorithmGuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageIndex => $composableBuilder(
      column: $table.pageIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnFilters(column));
}

class $$ParameterPageItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ParameterPageItemsTable> {
  $$ParameterPageItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get algorithmGuid => $composableBuilder(
      column: $table.algorithmGuid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageIndex => $composableBuilder(
      column: $table.pageIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnOrderings(column));
}

class $$ParameterPageItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParameterPageItemsTable> {
  $$ParameterPageItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get algorithmGuid => $composableBuilder(
      column: $table.algorithmGuid, builder: (column) => column);

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber, builder: (column) => column);
}

class $$ParameterPageItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ParameterPageItemsTable,
    ParameterPageItemEntry,
    $$ParameterPageItemsTableFilterComposer,
    $$ParameterPageItemsTableOrderingComposer,
    $$ParameterPageItemsTableAnnotationComposer,
    $$ParameterPageItemsTableCreateCompanionBuilder,
    $$ParameterPageItemsTableUpdateCompanionBuilder,
    (
      ParameterPageItemEntry,
      BaseReferences<_$AppDatabase, $ParameterPageItemsTable,
          ParameterPageItemEntry>
    ),
    ParameterPageItemEntry,
    PrefetchHooks Function()> {
  $$ParameterPageItemsTableTableManager(
      _$AppDatabase db, $ParameterPageItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParameterPageItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParameterPageItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParameterPageItemsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> algorithmGuid = const Value.absent(),
            Value<int> pageIndex = const Value.absent(),
            Value<int> parameterNumber = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ParameterPageItemsCompanion(
            algorithmGuid: algorithmGuid,
            pageIndex: pageIndex,
            parameterNumber: parameterNumber,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String algorithmGuid,
            required int pageIndex,
            required int parameterNumber,
            Value<int> rowid = const Value.absent(),
          }) =>
              ParameterPageItemsCompanion.insert(
            algorithmGuid: algorithmGuid,
            pageIndex: pageIndex,
            parameterNumber: parameterNumber,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ParameterPageItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ParameterPageItemsTable,
    ParameterPageItemEntry,
    $$ParameterPageItemsTableFilterComposer,
    $$ParameterPageItemsTableOrderingComposer,
    $$ParameterPageItemsTableAnnotationComposer,
    $$ParameterPageItemsTableCreateCompanionBuilder,
    $$ParameterPageItemsTableUpdateCompanionBuilder,
    (
      ParameterPageItemEntry,
      BaseReferences<_$AppDatabase, $ParameterPageItemsTable,
          ParameterPageItemEntry>
    ),
    ParameterPageItemEntry,
    PrefetchHooks Function()>;
typedef $$PresetsTableCreateCompanionBuilder = PresetsCompanion Function({
  Value<int> id,
  required String name,
  Value<DateTime> lastModified,
});
typedef $$PresetsTableUpdateCompanionBuilder = PresetsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<DateTime> lastModified,
});

final class $$PresetsTableReferences
    extends BaseReferences<_$AppDatabase, $PresetsTable, PresetEntry> {
  $$PresetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PresetSlotsTable, List<PresetSlotEntry>>
      _presetSlotsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.presetSlots,
              aliasName:
                  $_aliasNameGenerator(db.presets.id, db.presetSlots.presetId));

  $$PresetSlotsTableProcessedTableManager get presetSlotsRefs {
    final manager = $$PresetSlotsTableTableManager($_db, $_db.presetSlots)
        .filter((f) => f.presetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_presetSlotsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PresetsTableFilterComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => ColumnFilters(column));

  Expression<bool> presetSlotsRefs(
      Expression<bool> Function($$PresetSlotsTableFilterComposer f) f) {
    final $$PresetSlotsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.presetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableFilterComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified,
      builder: (column) => ColumnOrderings(column));
}

class $$PresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresetsTable> {
  $$PresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
      column: $table.lastModified, builder: (column) => column);

  Expression<T> presetSlotsRefs<T extends Object>(
      Expression<T> Function($$PresetSlotsTableAnnotationComposer a) f) {
    final $$PresetSlotsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.presetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableAnnotationComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PresetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PresetsTable,
    PresetEntry,
    $$PresetsTableFilterComposer,
    $$PresetsTableOrderingComposer,
    $$PresetsTableAnnotationComposer,
    $$PresetsTableCreateCompanionBuilder,
    $$PresetsTableUpdateCompanionBuilder,
    (PresetEntry, $$PresetsTableReferences),
    PresetEntry,
    PrefetchHooks Function({bool presetSlotsRefs})> {
  $$PresetsTableTableManager(_$AppDatabase db, $PresetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
          }) =>
              PresetsCompanion(
            id: id,
            name: name,
            lastModified: lastModified,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<DateTime> lastModified = const Value.absent(),
          }) =>
              PresetsCompanion.insert(
            id: id,
            name: name,
            lastModified: lastModified,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PresetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({presetSlotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (presetSlotsRefs) db.presetSlots],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (presetSlotsRefs)
                    await $_getPrefetchedData<PresetEntry, $PresetsTable,
                            PresetSlotEntry>(
                        currentTable: table,
                        referencedTable:
                            $$PresetsTableReferences._presetSlotsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PresetsTableReferences(db, table, p0)
                                .presetSlotsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.presetId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PresetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PresetsTable,
    PresetEntry,
    $$PresetsTableFilterComposer,
    $$PresetsTableOrderingComposer,
    $$PresetsTableAnnotationComposer,
    $$PresetsTableCreateCompanionBuilder,
    $$PresetsTableUpdateCompanionBuilder,
    (PresetEntry, $$PresetsTableReferences),
    PresetEntry,
    PrefetchHooks Function({bool presetSlotsRefs})>;
typedef $$PresetSlotsTableCreateCompanionBuilder = PresetSlotsCompanion
    Function({
  Value<int> id,
  required int presetId,
  required int slotIndex,
  required String algorithmGuid,
  Value<String?> customName,
});
typedef $$PresetSlotsTableUpdateCompanionBuilder = PresetSlotsCompanion
    Function({
  Value<int> id,
  Value<int> presetId,
  Value<int> slotIndex,
  Value<String> algorithmGuid,
  Value<String?> customName,
});

final class $$PresetSlotsTableReferences
    extends BaseReferences<_$AppDatabase, $PresetSlotsTable, PresetSlotEntry> {
  $$PresetSlotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PresetsTable _presetIdTable(_$AppDatabase db) =>
      db.presets.createAlias(
          $_aliasNameGenerator(db.presetSlots.presetId, db.presets.id));

  $$PresetsTableProcessedTableManager get presetId {
    final $_column = $_itemColumn<int>('preset_id')!;

    final manager = $$PresetsTableTableManager($_db, $_db.presets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_presetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AlgorithmsTable _algorithmGuidTable(_$AppDatabase db) =>
      db.algorithms.createAlias($_aliasNameGenerator(
          db.presetSlots.algorithmGuid, db.algorithms.guid));

  $$AlgorithmsTableProcessedTableManager get algorithmGuid {
    final $_column = $_itemColumn<String>('algorithm_guid')!;

    final manager = $$AlgorithmsTableTableManager($_db, $_db.algorithms)
        .filter((f) => f.guid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_algorithmGuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PresetParameterValuesTable,
      List<PresetParameterValueEntry>> _presetParameterValuesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.presetParameterValues,
          aliasName: $_aliasNameGenerator(
              db.presetSlots.id, db.presetParameterValues.presetSlotId));

  $$PresetParameterValuesTableProcessedTableManager
      get presetParameterValuesRefs {
    final manager = $$PresetParameterValuesTableTableManager(
            $_db, $_db.presetParameterValues)
        .filter((f) => f.presetSlotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_presetParameterValuesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PresetParameterStringValuesTable,
          List<PresetParameterStringValueEntry>>
      _presetParameterStringValuesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.presetParameterStringValues,
              aliasName: $_aliasNameGenerator(db.presetSlots.id,
                  db.presetParameterStringValues.presetSlotId));

  $$PresetParameterStringValuesTableProcessedTableManager
      get presetParameterStringValuesRefs {
    final manager = $$PresetParameterStringValuesTableTableManager(
            $_db, $_db.presetParameterStringValues)
        .filter((f) => f.presetSlotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult
        .readTableOrNull(_presetParameterStringValuesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PresetMappingsTable, List<PresetMappingEntry>>
      _presetMappingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.presetMappings,
              aliasName: $_aliasNameGenerator(
                  db.presetSlots.id, db.presetMappings.presetSlotId));

  $$PresetMappingsTableProcessedTableManager get presetMappingsRefs {
    final manager = $$PresetMappingsTableTableManager($_db, $_db.presetMappings)
        .filter((f) => f.presetSlotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_presetMappingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PresetRoutingsTable, List<PresetRoutingEntry>>
      _presetRoutingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.presetRoutings,
              aliasName: $_aliasNameGenerator(
                  db.presetSlots.id, db.presetRoutings.presetSlotId));

  $$PresetRoutingsTableProcessedTableManager get presetRoutingsRefs {
    final manager = $$PresetRoutingsTableTableManager($_db, $_db.presetRoutings)
        .filter((f) => f.presetSlotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_presetRoutingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PresetSlotsTableFilterComposer
    extends Composer<_$AppDatabase, $PresetSlotsTable> {
  $$PresetSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get slotIndex => $composableBuilder(
      column: $table.slotIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customName => $composableBuilder(
      column: $table.customName, builder: (column) => ColumnFilters(column));

  $$PresetsTableFilterComposer get presetId {
    final $$PresetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetId,
        referencedTable: $db.presets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetsTableFilterComposer(
              $db: $db,
              $table: $db.presets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AlgorithmsTableFilterComposer get algorithmGuid {
    final $$AlgorithmsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableFilterComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> presetParameterValuesRefs(
      Expression<bool> Function($$PresetParameterValuesTableFilterComposer f)
          f) {
    final $$PresetParameterValuesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.presetParameterValues,
            getReferencedColumn: (t) => t.presetSlotId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PresetParameterValuesTableFilterComposer(
                  $db: $db,
                  $table: $db.presetParameterValues,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> presetParameterStringValuesRefs(
      Expression<bool> Function(
              $$PresetParameterStringValuesTableFilterComposer f)
          f) {
    final $$PresetParameterStringValuesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.presetParameterStringValues,
            getReferencedColumn: (t) => t.presetSlotId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PresetParameterStringValuesTableFilterComposer(
                  $db: $db,
                  $table: $db.presetParameterStringValues,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> presetMappingsRefs(
      Expression<bool> Function($$PresetMappingsTableFilterComposer f) f) {
    final $$PresetMappingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.presetMappings,
        getReferencedColumn: (t) => t.presetSlotId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetMappingsTableFilterComposer(
              $db: $db,
              $table: $db.presetMappings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> presetRoutingsRefs(
      Expression<bool> Function($$PresetRoutingsTableFilterComposer f) f) {
    final $$PresetRoutingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.presetRoutings,
        getReferencedColumn: (t) => t.presetSlotId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetRoutingsTableFilterComposer(
              $db: $db,
              $table: $db.presetRoutings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PresetSlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $PresetSlotsTable> {
  $$PresetSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get slotIndex => $composableBuilder(
      column: $table.slotIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customName => $composableBuilder(
      column: $table.customName, builder: (column) => ColumnOrderings(column));

  $$PresetsTableOrderingComposer get presetId {
    final $$PresetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetId,
        referencedTable: $db.presets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetsTableOrderingComposer(
              $db: $db,
              $table: $db.presets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AlgorithmsTableOrderingComposer get algorithmGuid {
    final $$AlgorithmsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableOrderingComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetSlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresetSlotsTable> {
  $$PresetSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get slotIndex =>
      $composableBuilder(column: $table.slotIndex, builder: (column) => column);

  GeneratedColumn<String> get customName => $composableBuilder(
      column: $table.customName, builder: (column) => column);

  $$PresetsTableAnnotationComposer get presetId {
    final $$PresetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetId,
        referencedTable: $db.presets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetsTableAnnotationComposer(
              $db: $db,
              $table: $db.presets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AlgorithmsTableAnnotationComposer get algorithmGuid {
    final $$AlgorithmsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.algorithmGuid,
        referencedTable: $db.algorithms,
        getReferencedColumn: (t) => t.guid,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AlgorithmsTableAnnotationComposer(
              $db: $db,
              $table: $db.algorithms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> presetParameterValuesRefs<T extends Object>(
      Expression<T> Function($$PresetParameterValuesTableAnnotationComposer a)
          f) {
    final $$PresetParameterValuesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.presetParameterValues,
            getReferencedColumn: (t) => t.presetSlotId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PresetParameterValuesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.presetParameterValues,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> presetParameterStringValuesRefs<T extends Object>(
      Expression<T> Function(
              $$PresetParameterStringValuesTableAnnotationComposer a)
          f) {
    final $$PresetParameterStringValuesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.presetParameterStringValues,
            getReferencedColumn: (t) => t.presetSlotId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PresetParameterStringValuesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.presetParameterStringValues,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> presetMappingsRefs<T extends Object>(
      Expression<T> Function($$PresetMappingsTableAnnotationComposer a) f) {
    final $$PresetMappingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.presetMappings,
        getReferencedColumn: (t) => t.presetSlotId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetMappingsTableAnnotationComposer(
              $db: $db,
              $table: $db.presetMappings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> presetRoutingsRefs<T extends Object>(
      Expression<T> Function($$PresetRoutingsTableAnnotationComposer a) f) {
    final $$PresetRoutingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.presetRoutings,
        getReferencedColumn: (t) => t.presetSlotId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetRoutingsTableAnnotationComposer(
              $db: $db,
              $table: $db.presetRoutings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PresetSlotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PresetSlotsTable,
    PresetSlotEntry,
    $$PresetSlotsTableFilterComposer,
    $$PresetSlotsTableOrderingComposer,
    $$PresetSlotsTableAnnotationComposer,
    $$PresetSlotsTableCreateCompanionBuilder,
    $$PresetSlotsTableUpdateCompanionBuilder,
    (PresetSlotEntry, $$PresetSlotsTableReferences),
    PresetSlotEntry,
    PrefetchHooks Function(
        {bool presetId,
        bool algorithmGuid,
        bool presetParameterValuesRefs,
        bool presetParameterStringValuesRefs,
        bool presetMappingsRefs,
        bool presetRoutingsRefs})> {
  $$PresetSlotsTableTableManager(_$AppDatabase db, $PresetSlotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresetSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresetSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresetSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> presetId = const Value.absent(),
            Value<int> slotIndex = const Value.absent(),
            Value<String> algorithmGuid = const Value.absent(),
            Value<String?> customName = const Value.absent(),
          }) =>
              PresetSlotsCompanion(
            id: id,
            presetId: presetId,
            slotIndex: slotIndex,
            algorithmGuid: algorithmGuid,
            customName: customName,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int presetId,
            required int slotIndex,
            required String algorithmGuid,
            Value<String?> customName = const Value.absent(),
          }) =>
              PresetSlotsCompanion.insert(
            id: id,
            presetId: presetId,
            slotIndex: slotIndex,
            algorithmGuid: algorithmGuid,
            customName: customName,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PresetSlotsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {presetId = false,
              algorithmGuid = false,
              presetParameterValuesRefs = false,
              presetParameterStringValuesRefs = false,
              presetMappingsRefs = false,
              presetRoutingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (presetParameterValuesRefs) db.presetParameterValues,
                if (presetParameterStringValuesRefs)
                  db.presetParameterStringValues,
                if (presetMappingsRefs) db.presetMappings,
                if (presetRoutingsRefs) db.presetRoutings
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (presetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.presetId,
                    referencedTable:
                        $$PresetSlotsTableReferences._presetIdTable(db),
                    referencedColumn:
                        $$PresetSlotsTableReferences._presetIdTable(db).id,
                  ) as T;
                }
                if (algorithmGuid) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.algorithmGuid,
                    referencedTable:
                        $$PresetSlotsTableReferences._algorithmGuidTable(db),
                    referencedColumn: $$PresetSlotsTableReferences
                        ._algorithmGuidTable(db)
                        .guid,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (presetParameterValuesRefs)
                    await $_getPrefetchedData<PresetSlotEntry,
                            $PresetSlotsTable, PresetParameterValueEntry>(
                        currentTable: table,
                        referencedTable: $$PresetSlotsTableReferences
                            ._presetParameterValuesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PresetSlotsTableReferences(db, table, p0)
                                .presetParameterValuesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.presetSlotId == item.id),
                        typedResults: items),
                  if (presetParameterStringValuesRefs)
                    await $_getPrefetchedData<PresetSlotEntry,
                            $PresetSlotsTable, PresetParameterStringValueEntry>(
                        currentTable: table,
                        referencedTable: $$PresetSlotsTableReferences
                            ._presetParameterStringValuesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PresetSlotsTableReferences(db, table, p0)
                                .presetParameterStringValuesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.presetSlotId == item.id),
                        typedResults: items),
                  if (presetMappingsRefs)
                    await $_getPrefetchedData<PresetSlotEntry,
                            $PresetSlotsTable, PresetMappingEntry>(
                        currentTable: table,
                        referencedTable: $$PresetSlotsTableReferences
                            ._presetMappingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PresetSlotsTableReferences(db, table, p0)
                                .presetMappingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.presetSlotId == item.id),
                        typedResults: items),
                  if (presetRoutingsRefs)
                    await $_getPrefetchedData<PresetSlotEntry,
                            $PresetSlotsTable, PresetRoutingEntry>(
                        currentTable: table,
                        referencedTable: $$PresetSlotsTableReferences
                            ._presetRoutingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PresetSlotsTableReferences(db, table, p0)
                                .presetRoutingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.presetSlotId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PresetSlotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PresetSlotsTable,
    PresetSlotEntry,
    $$PresetSlotsTableFilterComposer,
    $$PresetSlotsTableOrderingComposer,
    $$PresetSlotsTableAnnotationComposer,
    $$PresetSlotsTableCreateCompanionBuilder,
    $$PresetSlotsTableUpdateCompanionBuilder,
    (PresetSlotEntry, $$PresetSlotsTableReferences),
    PresetSlotEntry,
    PrefetchHooks Function(
        {bool presetId,
        bool algorithmGuid,
        bool presetParameterValuesRefs,
        bool presetParameterStringValuesRefs,
        bool presetMappingsRefs,
        bool presetRoutingsRefs})>;
typedef $$PresetParameterValuesTableCreateCompanionBuilder
    = PresetParameterValuesCompanion Function({
  Value<int> id,
  required int presetSlotId,
  required int parameterNumber,
  required int value,
});
typedef $$PresetParameterValuesTableUpdateCompanionBuilder
    = PresetParameterValuesCompanion Function({
  Value<int> id,
  Value<int> presetSlotId,
  Value<int> parameterNumber,
  Value<int> value,
});

final class $$PresetParameterValuesTableReferences extends BaseReferences<
    _$AppDatabase, $PresetParameterValuesTable, PresetParameterValueEntry> {
  $$PresetParameterValuesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PresetSlotsTable _presetSlotIdTable(_$AppDatabase db) =>
      db.presetSlots.createAlias($_aliasNameGenerator(
          db.presetParameterValues.presetSlotId, db.presetSlots.id));

  $$PresetSlotsTableProcessedTableManager get presetSlotId {
    final $_column = $_itemColumn<int>('preset_slot_id')!;

    final manager = $$PresetSlotsTableTableManager($_db, $_db.presetSlots)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_presetSlotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PresetParameterValuesTableFilterComposer
    extends Composer<_$AppDatabase, $PresetParameterValuesTable> {
  $$PresetParameterValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  $$PresetSlotsTableFilterComposer get presetSlotId {
    final $$PresetSlotsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableFilterComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetParameterValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $PresetParameterValuesTable> {
  $$PresetParameterValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  $$PresetSlotsTableOrderingComposer get presetSlotId {
    final $$PresetSlotsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableOrderingComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetParameterValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresetParameterValuesTable> {
  $$PresetParameterValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$PresetSlotsTableAnnotationComposer get presetSlotId {
    final $$PresetSlotsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableAnnotationComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetParameterValuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PresetParameterValuesTable,
    PresetParameterValueEntry,
    $$PresetParameterValuesTableFilterComposer,
    $$PresetParameterValuesTableOrderingComposer,
    $$PresetParameterValuesTableAnnotationComposer,
    $$PresetParameterValuesTableCreateCompanionBuilder,
    $$PresetParameterValuesTableUpdateCompanionBuilder,
    (PresetParameterValueEntry, $$PresetParameterValuesTableReferences),
    PresetParameterValueEntry,
    PrefetchHooks Function({bool presetSlotId})> {
  $$PresetParameterValuesTableTableManager(
      _$AppDatabase db, $PresetParameterValuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresetParameterValuesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PresetParameterValuesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresetParameterValuesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> presetSlotId = const Value.absent(),
            Value<int> parameterNumber = const Value.absent(),
            Value<int> value = const Value.absent(),
          }) =>
              PresetParameterValuesCompanion(
            id: id,
            presetSlotId: presetSlotId,
            parameterNumber: parameterNumber,
            value: value,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int presetSlotId,
            required int parameterNumber,
            required int value,
          }) =>
              PresetParameterValuesCompanion.insert(
            id: id,
            presetSlotId: presetSlotId,
            parameterNumber: parameterNumber,
            value: value,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PresetParameterValuesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({presetSlotId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (presetSlotId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.presetSlotId,
                    referencedTable: $$PresetParameterValuesTableReferences
                        ._presetSlotIdTable(db),
                    referencedColumn: $$PresetParameterValuesTableReferences
                        ._presetSlotIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PresetParameterValuesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PresetParameterValuesTable,
        PresetParameterValueEntry,
        $$PresetParameterValuesTableFilterComposer,
        $$PresetParameterValuesTableOrderingComposer,
        $$PresetParameterValuesTableAnnotationComposer,
        $$PresetParameterValuesTableCreateCompanionBuilder,
        $$PresetParameterValuesTableUpdateCompanionBuilder,
        (PresetParameterValueEntry, $$PresetParameterValuesTableReferences),
        PresetParameterValueEntry,
        PrefetchHooks Function({bool presetSlotId})>;
typedef $$PresetParameterStringValuesTableCreateCompanionBuilder
    = PresetParameterStringValuesCompanion Function({
  required int presetSlotId,
  required int parameterNumber,
  required String stringValue,
  Value<int> rowid,
});
typedef $$PresetParameterStringValuesTableUpdateCompanionBuilder
    = PresetParameterStringValuesCompanion Function({
  Value<int> presetSlotId,
  Value<int> parameterNumber,
  Value<String> stringValue,
  Value<int> rowid,
});

final class $$PresetParameterStringValuesTableReferences extends BaseReferences<
    _$AppDatabase,
    $PresetParameterStringValuesTable,
    PresetParameterStringValueEntry> {
  $$PresetParameterStringValuesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PresetSlotsTable _presetSlotIdTable(_$AppDatabase db) =>
      db.presetSlots.createAlias($_aliasNameGenerator(
          db.presetParameterStringValues.presetSlotId, db.presetSlots.id));

  $$PresetSlotsTableProcessedTableManager get presetSlotId {
    final $_column = $_itemColumn<int>('preset_slot_id')!;

    final manager = $$PresetSlotsTableTableManager($_db, $_db.presetSlots)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_presetSlotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PresetParameterStringValuesTableFilterComposer
    extends Composer<_$AppDatabase, $PresetParameterStringValuesTable> {
  $$PresetParameterStringValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stringValue => $composableBuilder(
      column: $table.stringValue, builder: (column) => ColumnFilters(column));

  $$PresetSlotsTableFilterComposer get presetSlotId {
    final $$PresetSlotsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableFilterComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetParameterStringValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $PresetParameterStringValuesTable> {
  $$PresetParameterStringValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stringValue => $composableBuilder(
      column: $table.stringValue, builder: (column) => ColumnOrderings(column));

  $$PresetSlotsTableOrderingComposer get presetSlotId {
    final $$PresetSlotsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableOrderingComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetParameterStringValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresetParameterStringValuesTable> {
  $$PresetParameterStringValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber, builder: (column) => column);

  GeneratedColumn<String> get stringValue => $composableBuilder(
      column: $table.stringValue, builder: (column) => column);

  $$PresetSlotsTableAnnotationComposer get presetSlotId {
    final $$PresetSlotsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableAnnotationComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetParameterStringValuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PresetParameterStringValuesTable,
    PresetParameterStringValueEntry,
    $$PresetParameterStringValuesTableFilterComposer,
    $$PresetParameterStringValuesTableOrderingComposer,
    $$PresetParameterStringValuesTableAnnotationComposer,
    $$PresetParameterStringValuesTableCreateCompanionBuilder,
    $$PresetParameterStringValuesTableUpdateCompanionBuilder,
    (
      PresetParameterStringValueEntry,
      $$PresetParameterStringValuesTableReferences
    ),
    PresetParameterStringValueEntry,
    PrefetchHooks Function({bool presetSlotId})> {
  $$PresetParameterStringValuesTableTableManager(
      _$AppDatabase db, $PresetParameterStringValuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresetParameterStringValuesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PresetParameterStringValuesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresetParameterStringValuesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> presetSlotId = const Value.absent(),
            Value<int> parameterNumber = const Value.absent(),
            Value<String> stringValue = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PresetParameterStringValuesCompanion(
            presetSlotId: presetSlotId,
            parameterNumber: parameterNumber,
            stringValue: stringValue,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int presetSlotId,
            required int parameterNumber,
            required String stringValue,
            Value<int> rowid = const Value.absent(),
          }) =>
              PresetParameterStringValuesCompanion.insert(
            presetSlotId: presetSlotId,
            parameterNumber: parameterNumber,
            stringValue: stringValue,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PresetParameterStringValuesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({presetSlotId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (presetSlotId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.presetSlotId,
                    referencedTable:
                        $$PresetParameterStringValuesTableReferences
                            ._presetSlotIdTable(db),
                    referencedColumn:
                        $$PresetParameterStringValuesTableReferences
                            ._presetSlotIdTable(db)
                            .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PresetParameterStringValuesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PresetParameterStringValuesTable,
    PresetParameterStringValueEntry,
    $$PresetParameterStringValuesTableFilterComposer,
    $$PresetParameterStringValuesTableOrderingComposer,
    $$PresetParameterStringValuesTableAnnotationComposer,
    $$PresetParameterStringValuesTableCreateCompanionBuilder,
    $$PresetParameterStringValuesTableUpdateCompanionBuilder,
    (
      PresetParameterStringValueEntry,
      $$PresetParameterStringValuesTableReferences
    ),
    PresetParameterStringValueEntry,
    PrefetchHooks Function({bool presetSlotId})>;
typedef $$PresetMappingsTableCreateCompanionBuilder = PresetMappingsCompanion
    Function({
  required int presetSlotId,
  required int parameterNumber,
  required PackedMappingData packedData,
  Value<int> rowid,
});
typedef $$PresetMappingsTableUpdateCompanionBuilder = PresetMappingsCompanion
    Function({
  Value<int> presetSlotId,
  Value<int> parameterNumber,
  Value<PackedMappingData> packedData,
  Value<int> rowid,
});

final class $$PresetMappingsTableReferences extends BaseReferences<
    _$AppDatabase, $PresetMappingsTable, PresetMappingEntry> {
  $$PresetMappingsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PresetSlotsTable _presetSlotIdTable(_$AppDatabase db) =>
      db.presetSlots.createAlias($_aliasNameGenerator(
          db.presetMappings.presetSlotId, db.presetSlots.id));

  $$PresetSlotsTableProcessedTableManager get presetSlotId {
    final $_column = $_itemColumn<int>('preset_slot_id')!;

    final manager = $$PresetSlotsTableTableManager($_db, $_db.presetSlots)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_presetSlotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PresetMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $PresetMappingsTable> {
  $$PresetMappingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<PackedMappingData, PackedMappingData,
          Uint8List>
      get packedData => $composableBuilder(
          column: $table.packedData,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$PresetSlotsTableFilterComposer get presetSlotId {
    final $$PresetSlotsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableFilterComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $PresetMappingsTable> {
  $$PresetMappingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get packedData => $composableBuilder(
      column: $table.packedData, builder: (column) => ColumnOrderings(column));

  $$PresetSlotsTableOrderingComposer get presetSlotId {
    final $$PresetSlotsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableOrderingComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresetMappingsTable> {
  $$PresetMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get parameterNumber => $composableBuilder(
      column: $table.parameterNumber, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PackedMappingData, Uint8List>
      get packedData => $composableBuilder(
          column: $table.packedData, builder: (column) => column);

  $$PresetSlotsTableAnnotationComposer get presetSlotId {
    final $$PresetSlotsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableAnnotationComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetMappingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PresetMappingsTable,
    PresetMappingEntry,
    $$PresetMappingsTableFilterComposer,
    $$PresetMappingsTableOrderingComposer,
    $$PresetMappingsTableAnnotationComposer,
    $$PresetMappingsTableCreateCompanionBuilder,
    $$PresetMappingsTableUpdateCompanionBuilder,
    (PresetMappingEntry, $$PresetMappingsTableReferences),
    PresetMappingEntry,
    PrefetchHooks Function({bool presetSlotId})> {
  $$PresetMappingsTableTableManager(
      _$AppDatabase db, $PresetMappingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresetMappingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresetMappingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresetMappingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> presetSlotId = const Value.absent(),
            Value<int> parameterNumber = const Value.absent(),
            Value<PackedMappingData> packedData = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PresetMappingsCompanion(
            presetSlotId: presetSlotId,
            parameterNumber: parameterNumber,
            packedData: packedData,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int presetSlotId,
            required int parameterNumber,
            required PackedMappingData packedData,
            Value<int> rowid = const Value.absent(),
          }) =>
              PresetMappingsCompanion.insert(
            presetSlotId: presetSlotId,
            parameterNumber: parameterNumber,
            packedData: packedData,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PresetMappingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({presetSlotId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (presetSlotId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.presetSlotId,
                    referencedTable:
                        $$PresetMappingsTableReferences._presetSlotIdTable(db),
                    referencedColumn: $$PresetMappingsTableReferences
                        ._presetSlotIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PresetMappingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PresetMappingsTable,
    PresetMappingEntry,
    $$PresetMappingsTableFilterComposer,
    $$PresetMappingsTableOrderingComposer,
    $$PresetMappingsTableAnnotationComposer,
    $$PresetMappingsTableCreateCompanionBuilder,
    $$PresetMappingsTableUpdateCompanionBuilder,
    (PresetMappingEntry, $$PresetMappingsTableReferences),
    PresetMappingEntry,
    PrefetchHooks Function({bool presetSlotId})>;
typedef $$PresetRoutingsTableCreateCompanionBuilder = PresetRoutingsCompanion
    Function({
  Value<int> presetSlotId,
  required List<int> routingInfoJson,
});
typedef $$PresetRoutingsTableUpdateCompanionBuilder = PresetRoutingsCompanion
    Function({
  Value<int> presetSlotId,
  Value<List<int>> routingInfoJson,
});

final class $$PresetRoutingsTableReferences extends BaseReferences<
    _$AppDatabase, $PresetRoutingsTable, PresetRoutingEntry> {
  $$PresetRoutingsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PresetSlotsTable _presetSlotIdTable(_$AppDatabase db) =>
      db.presetSlots.createAlias($_aliasNameGenerator(
          db.presetRoutings.presetSlotId, db.presetSlots.id));

  $$PresetSlotsTableProcessedTableManager get presetSlotId {
    final $_column = $_itemColumn<int>('preset_slot_id')!;

    final manager = $$PresetSlotsTableTableManager($_db, $_db.presetSlots)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_presetSlotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PresetRoutingsTableFilterComposer
    extends Composer<_$AppDatabase, $PresetRoutingsTable> {
  $$PresetRoutingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<List<int>, List<int>, String>
      get routingInfoJson => $composableBuilder(
          column: $table.routingInfoJson,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$PresetSlotsTableFilterComposer get presetSlotId {
    final $$PresetSlotsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableFilterComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetRoutingsTableOrderingComposer
    extends Composer<_$AppDatabase, $PresetRoutingsTable> {
  $$PresetRoutingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get routingInfoJson => $composableBuilder(
      column: $table.routingInfoJson,
      builder: (column) => ColumnOrderings(column));

  $$PresetSlotsTableOrderingComposer get presetSlotId {
    final $$PresetSlotsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableOrderingComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetRoutingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PresetRoutingsTable> {
  $$PresetRoutingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<List<int>, String> get routingInfoJson =>
      $composableBuilder(
          column: $table.routingInfoJson, builder: (column) => column);

  $$PresetSlotsTableAnnotationComposer get presetSlotId {
    final $$PresetSlotsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.presetSlotId,
        referencedTable: $db.presetSlots,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PresetSlotsTableAnnotationComposer(
              $db: $db,
              $table: $db.presetSlots,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PresetRoutingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PresetRoutingsTable,
    PresetRoutingEntry,
    $$PresetRoutingsTableFilterComposer,
    $$PresetRoutingsTableOrderingComposer,
    $$PresetRoutingsTableAnnotationComposer,
    $$PresetRoutingsTableCreateCompanionBuilder,
    $$PresetRoutingsTableUpdateCompanionBuilder,
    (PresetRoutingEntry, $$PresetRoutingsTableReferences),
    PresetRoutingEntry,
    PrefetchHooks Function({bool presetSlotId})> {
  $$PresetRoutingsTableTableManager(
      _$AppDatabase db, $PresetRoutingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PresetRoutingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PresetRoutingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PresetRoutingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> presetSlotId = const Value.absent(),
            Value<List<int>> routingInfoJson = const Value.absent(),
          }) =>
              PresetRoutingsCompanion(
            presetSlotId: presetSlotId,
            routingInfoJson: routingInfoJson,
          ),
          createCompanionCallback: ({
            Value<int> presetSlotId = const Value.absent(),
            required List<int> routingInfoJson,
          }) =>
              PresetRoutingsCompanion.insert(
            presetSlotId: presetSlotId,
            routingInfoJson: routingInfoJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PresetRoutingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({presetSlotId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (presetSlotId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.presetSlotId,
                    referencedTable:
                        $$PresetRoutingsTableReferences._presetSlotIdTable(db),
                    referencedColumn: $$PresetRoutingsTableReferences
                        ._presetSlotIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PresetRoutingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PresetRoutingsTable,
    PresetRoutingEntry,
    $$PresetRoutingsTableFilterComposer,
    $$PresetRoutingsTableOrderingComposer,
    $$PresetRoutingsTableAnnotationComposer,
    $$PresetRoutingsTableCreateCompanionBuilder,
    $$PresetRoutingsTableUpdateCompanionBuilder,
    (PresetRoutingEntry, $$PresetRoutingsTableReferences),
    PresetRoutingEntry,
    PrefetchHooks Function({bool presetSlotId})>;
typedef $$SdCardsTableCreateCompanionBuilder = SdCardsCompanion Function({
  Value<int> id,
  required String userLabel,
  Value<String?> systemIdentifier,
});
typedef $$SdCardsTableUpdateCompanionBuilder = SdCardsCompanion Function({
  Value<int> id,
  Value<String> userLabel,
  Value<String?> systemIdentifier,
});

final class $$SdCardsTableReferences
    extends BaseReferences<_$AppDatabase, $SdCardsTable, SdCardEntry> {
  $$SdCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IndexedPresetFilesTable,
      List<IndexedPresetFileEntry>> _indexedPresetFilesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.indexedPresetFiles,
          aliasName: $_aliasNameGenerator(
              db.sdCards.id, db.indexedPresetFiles.sdCardId));

  $$IndexedPresetFilesTableProcessedTableManager get indexedPresetFilesRefs {
    final manager =
        $$IndexedPresetFilesTableTableManager($_db, $_db.indexedPresetFiles)
            .filter((f) => f.sdCardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_indexedPresetFilesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SdCardsTableFilterComposer
    extends Composer<_$AppDatabase, $SdCardsTable> {
  $$SdCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userLabel => $composableBuilder(
      column: $table.userLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemIdentifier => $composableBuilder(
      column: $table.systemIdentifier,
      builder: (column) => ColumnFilters(column));

  Expression<bool> indexedPresetFilesRefs(
      Expression<bool> Function($$IndexedPresetFilesTableFilterComposer f) f) {
    final $$IndexedPresetFilesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.indexedPresetFiles,
        getReferencedColumn: (t) => t.sdCardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$IndexedPresetFilesTableFilterComposer(
              $db: $db,
              $table: $db.indexedPresetFiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SdCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $SdCardsTable> {
  $$SdCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userLabel => $composableBuilder(
      column: $table.userLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemIdentifier => $composableBuilder(
      column: $table.systemIdentifier,
      builder: (column) => ColumnOrderings(column));
}

class $$SdCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SdCardsTable> {
  $$SdCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userLabel =>
      $composableBuilder(column: $table.userLabel, builder: (column) => column);

  GeneratedColumn<String> get systemIdentifier => $composableBuilder(
      column: $table.systemIdentifier, builder: (column) => column);

  Expression<T> indexedPresetFilesRefs<T extends Object>(
      Expression<T> Function($$IndexedPresetFilesTableAnnotationComposer a) f) {
    final $$IndexedPresetFilesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.indexedPresetFiles,
            getReferencedColumn: (t) => t.sdCardId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$IndexedPresetFilesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.indexedPresetFiles,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SdCardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SdCardsTable,
    SdCardEntry,
    $$SdCardsTableFilterComposer,
    $$SdCardsTableOrderingComposer,
    $$SdCardsTableAnnotationComposer,
    $$SdCardsTableCreateCompanionBuilder,
    $$SdCardsTableUpdateCompanionBuilder,
    (SdCardEntry, $$SdCardsTableReferences),
    SdCardEntry,
    PrefetchHooks Function({bool indexedPresetFilesRefs})> {
  $$SdCardsTableTableManager(_$AppDatabase db, $SdCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SdCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SdCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SdCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> userLabel = const Value.absent(),
            Value<String?> systemIdentifier = const Value.absent(),
          }) =>
              SdCardsCompanion(
            id: id,
            userLabel: userLabel,
            systemIdentifier: systemIdentifier,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String userLabel,
            Value<String?> systemIdentifier = const Value.absent(),
          }) =>
              SdCardsCompanion.insert(
            id: id,
            userLabel: userLabel,
            systemIdentifier: systemIdentifier,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SdCardsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({indexedPresetFilesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (indexedPresetFilesRefs) db.indexedPresetFiles
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (indexedPresetFilesRefs)
                    await $_getPrefetchedData<SdCardEntry, $SdCardsTable,
                            IndexedPresetFileEntry>(
                        currentTable: table,
                        referencedTable: $$SdCardsTableReferences
                            ._indexedPresetFilesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SdCardsTableReferences(db, table, p0)
                                .indexedPresetFilesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.sdCardId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SdCardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SdCardsTable,
    SdCardEntry,
    $$SdCardsTableFilterComposer,
    $$SdCardsTableOrderingComposer,
    $$SdCardsTableAnnotationComposer,
    $$SdCardsTableCreateCompanionBuilder,
    $$SdCardsTableUpdateCompanionBuilder,
    (SdCardEntry, $$SdCardsTableReferences),
    SdCardEntry,
    PrefetchHooks Function({bool indexedPresetFilesRefs})>;
typedef $$IndexedPresetFilesTableCreateCompanionBuilder
    = IndexedPresetFilesCompanion Function({
  Value<int> id,
  required int sdCardId,
  required String relativePath,
  required String fileName,
  required String absolutePathAtScanTime,
  Value<String?> algorithmNameFromPreset,
  Value<String?> notesFromPreset,
  Value<String?> otherExtractedMetadataJson,
  required DateTime lastSeenUtc,
});
typedef $$IndexedPresetFilesTableUpdateCompanionBuilder
    = IndexedPresetFilesCompanion Function({
  Value<int> id,
  Value<int> sdCardId,
  Value<String> relativePath,
  Value<String> fileName,
  Value<String> absolutePathAtScanTime,
  Value<String?> algorithmNameFromPreset,
  Value<String?> notesFromPreset,
  Value<String?> otherExtractedMetadataJson,
  Value<DateTime> lastSeenUtc,
});

final class $$IndexedPresetFilesTableReferences extends BaseReferences<
    _$AppDatabase, $IndexedPresetFilesTable, IndexedPresetFileEntry> {
  $$IndexedPresetFilesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SdCardsTable _sdCardIdTable(_$AppDatabase db) =>
      db.sdCards.createAlias(
          $_aliasNameGenerator(db.indexedPresetFiles.sdCardId, db.sdCards.id));

  $$SdCardsTableProcessedTableManager get sdCardId {
    final $_column = $_itemColumn<int>('sd_card_id')!;

    final manager = $$SdCardsTableTableManager($_db, $_db.sdCards)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sdCardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$IndexedPresetFilesTableFilterComposer
    extends Composer<_$AppDatabase, $IndexedPresetFilesTable> {
  $$IndexedPresetFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get absolutePathAtScanTime => $composableBuilder(
      column: $table.absolutePathAtScanTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get algorithmNameFromPreset => $composableBuilder(
      column: $table.algorithmNameFromPreset,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notesFromPreset => $composableBuilder(
      column: $table.notesFromPreset,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get otherExtractedMetadataJson => $composableBuilder(
      column: $table.otherExtractedMetadataJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSeenUtc => $composableBuilder(
      column: $table.lastSeenUtc, builder: (column) => ColumnFilters(column));

  $$SdCardsTableFilterComposer get sdCardId {
    final $$SdCardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sdCardId,
        referencedTable: $db.sdCards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SdCardsTableFilterComposer(
              $db: $db,
              $table: $db.sdCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IndexedPresetFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $IndexedPresetFilesTable> {
  $$IndexedPresetFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relativePath => $composableBuilder(
      column: $table.relativePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get absolutePathAtScanTime => $composableBuilder(
      column: $table.absolutePathAtScanTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get algorithmNameFromPreset => $composableBuilder(
      column: $table.algorithmNameFromPreset,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notesFromPreset => $composableBuilder(
      column: $table.notesFromPreset,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get otherExtractedMetadataJson => $composableBuilder(
      column: $table.otherExtractedMetadataJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSeenUtc => $composableBuilder(
      column: $table.lastSeenUtc, builder: (column) => ColumnOrderings(column));

  $$SdCardsTableOrderingComposer get sdCardId {
    final $$SdCardsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sdCardId,
        referencedTable: $db.sdCards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SdCardsTableOrderingComposer(
              $db: $db,
              $table: $db.sdCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IndexedPresetFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IndexedPresetFilesTable> {
  $$IndexedPresetFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get absolutePathAtScanTime => $composableBuilder(
      column: $table.absolutePathAtScanTime, builder: (column) => column);

  GeneratedColumn<String> get algorithmNameFromPreset => $composableBuilder(
      column: $table.algorithmNameFromPreset, builder: (column) => column);

  GeneratedColumn<String> get notesFromPreset => $composableBuilder(
      column: $table.notesFromPreset, builder: (column) => column);

  GeneratedColumn<String> get otherExtractedMetadataJson => $composableBuilder(
      column: $table.otherExtractedMetadataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenUtc => $composableBuilder(
      column: $table.lastSeenUtc, builder: (column) => column);

  $$SdCardsTableAnnotationComposer get sdCardId {
    final $$SdCardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sdCardId,
        referencedTable: $db.sdCards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SdCardsTableAnnotationComposer(
              $db: $db,
              $table: $db.sdCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$IndexedPresetFilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IndexedPresetFilesTable,
    IndexedPresetFileEntry,
    $$IndexedPresetFilesTableFilterComposer,
    $$IndexedPresetFilesTableOrderingComposer,
    $$IndexedPresetFilesTableAnnotationComposer,
    $$IndexedPresetFilesTableCreateCompanionBuilder,
    $$IndexedPresetFilesTableUpdateCompanionBuilder,
    (IndexedPresetFileEntry, $$IndexedPresetFilesTableReferences),
    IndexedPresetFileEntry,
    PrefetchHooks Function({bool sdCardId})> {
  $$IndexedPresetFilesTableTableManager(
      _$AppDatabase db, $IndexedPresetFilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IndexedPresetFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IndexedPresetFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IndexedPresetFilesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> sdCardId = const Value.absent(),
            Value<String> relativePath = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<String> absolutePathAtScanTime = const Value.absent(),
            Value<String?> algorithmNameFromPreset = const Value.absent(),
            Value<String?> notesFromPreset = const Value.absent(),
            Value<String?> otherExtractedMetadataJson = const Value.absent(),
            Value<DateTime> lastSeenUtc = const Value.absent(),
          }) =>
              IndexedPresetFilesCompanion(
            id: id,
            sdCardId: sdCardId,
            relativePath: relativePath,
            fileName: fileName,
            absolutePathAtScanTime: absolutePathAtScanTime,
            algorithmNameFromPreset: algorithmNameFromPreset,
            notesFromPreset: notesFromPreset,
            otherExtractedMetadataJson: otherExtractedMetadataJson,
            lastSeenUtc: lastSeenUtc,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int sdCardId,
            required String relativePath,
            required String fileName,
            required String absolutePathAtScanTime,
            Value<String?> algorithmNameFromPreset = const Value.absent(),
            Value<String?> notesFromPreset = const Value.absent(),
            Value<String?> otherExtractedMetadataJson = const Value.absent(),
            required DateTime lastSeenUtc,
          }) =>
              IndexedPresetFilesCompanion.insert(
            id: id,
            sdCardId: sdCardId,
            relativePath: relativePath,
            fileName: fileName,
            absolutePathAtScanTime: absolutePathAtScanTime,
            algorithmNameFromPreset: algorithmNameFromPreset,
            notesFromPreset: notesFromPreset,
            otherExtractedMetadataJson: otherExtractedMetadataJson,
            lastSeenUtc: lastSeenUtc,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$IndexedPresetFilesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({sdCardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sdCardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sdCardId,
                    referencedTable:
                        $$IndexedPresetFilesTableReferences._sdCardIdTable(db),
                    referencedColumn: $$IndexedPresetFilesTableReferences
                        ._sdCardIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$IndexedPresetFilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IndexedPresetFilesTable,
    IndexedPresetFileEntry,
    $$IndexedPresetFilesTableFilterComposer,
    $$IndexedPresetFilesTableOrderingComposer,
    $$IndexedPresetFilesTableAnnotationComposer,
    $$IndexedPresetFilesTableCreateCompanionBuilder,
    $$IndexedPresetFilesTableUpdateCompanionBuilder,
    (IndexedPresetFileEntry, $$IndexedPresetFilesTableReferences),
    IndexedPresetFileEntry,
    PrefetchHooks Function({bool sdCardId})>;
typedef $$MetadataCacheTableCreateCompanionBuilder = MetadataCacheCompanion
    Function({
  required String cacheKey,
  required String cacheValue,
  Value<int> rowid,
});
typedef $$MetadataCacheTableUpdateCompanionBuilder = MetadataCacheCompanion
    Function({
  Value<String> cacheKey,
  Value<String> cacheValue,
  Value<int> rowid,
});

class $$MetadataCacheTableFilterComposer
    extends Composer<_$AppDatabase, $MetadataCacheTable> {
  $$MetadataCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cacheValue => $composableBuilder(
      column: $table.cacheValue, builder: (column) => ColumnFilters(column));
}

class $$MetadataCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $MetadataCacheTable> {
  $$MetadataCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cacheValue => $composableBuilder(
      column: $table.cacheValue, builder: (column) => ColumnOrderings(column));
}

class $$MetadataCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetadataCacheTable> {
  $$MetadataCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get cacheValue => $composableBuilder(
      column: $table.cacheValue, builder: (column) => column);
}

class $$MetadataCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MetadataCacheTable,
    MetadataCacheEntry,
    $$MetadataCacheTableFilterComposer,
    $$MetadataCacheTableOrderingComposer,
    $$MetadataCacheTableAnnotationComposer,
    $$MetadataCacheTableCreateCompanionBuilder,
    $$MetadataCacheTableUpdateCompanionBuilder,
    (
      MetadataCacheEntry,
      BaseReferences<_$AppDatabase, $MetadataCacheTable, MetadataCacheEntry>
    ),
    MetadataCacheEntry,
    PrefetchHooks Function()> {
  $$MetadataCacheTableTableManager(_$AppDatabase db, $MetadataCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetadataCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetadataCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetadataCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> cacheKey = const Value.absent(),
            Value<String> cacheValue = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MetadataCacheCompanion(
            cacheKey: cacheKey,
            cacheValue: cacheValue,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cacheKey,
            required String cacheValue,
            Value<int> rowid = const Value.absent(),
          }) =>
              MetadataCacheCompanion.insert(
            cacheKey: cacheKey,
            cacheValue: cacheValue,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MetadataCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MetadataCacheTable,
    MetadataCacheEntry,
    $$MetadataCacheTableFilterComposer,
    $$MetadataCacheTableOrderingComposer,
    $$MetadataCacheTableAnnotationComposer,
    $$MetadataCacheTableCreateCompanionBuilder,
    $$MetadataCacheTableUpdateCompanionBuilder,
    (
      MetadataCacheEntry,
      BaseReferences<_$AppDatabase, $MetadataCacheTable, MetadataCacheEntry>
    ),
    MetadataCacheEntry,
    PrefetchHooks Function()>;
typedef $$PluginInstallationsTableCreateCompanionBuilder
    = PluginInstallationsCompanion Function({
  Value<int> id,
  required String pluginId,
  required String pluginName,
  required String pluginVersion,
  required String pluginType,
  required String pluginAuthor,
  Value<DateTime> installedAt,
  required String installationPath,
  Value<String> installationStatus,
  Value<String?> marketplaceMetadata,
  Value<String?> repositoryUrl,
  Value<String?> repositoryOwner,
  Value<String?> repositoryName,
  Value<int?> fileCount,
  Value<int?> totalBytes,
  Value<String?> installationNotes,
  Value<String?> errorMessage,
});
typedef $$PluginInstallationsTableUpdateCompanionBuilder
    = PluginInstallationsCompanion Function({
  Value<int> id,
  Value<String> pluginId,
  Value<String> pluginName,
  Value<String> pluginVersion,
  Value<String> pluginType,
  Value<String> pluginAuthor,
  Value<DateTime> installedAt,
  Value<String> installationPath,
  Value<String> installationStatus,
  Value<String?> marketplaceMetadata,
  Value<String?> repositoryUrl,
  Value<String?> repositoryOwner,
  Value<String?> repositoryName,
  Value<int?> fileCount,
  Value<int?> totalBytes,
  Value<String?> installationNotes,
  Value<String?> errorMessage,
});

class $$PluginInstallationsTableFilterComposer
    extends Composer<_$AppDatabase, $PluginInstallationsTable> {
  $$PluginInstallationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pluginId => $composableBuilder(
      column: $table.pluginId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pluginName => $composableBuilder(
      column: $table.pluginName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pluginVersion => $composableBuilder(
      column: $table.pluginVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pluginType => $composableBuilder(
      column: $table.pluginType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pluginAuthor => $composableBuilder(
      column: $table.pluginAuthor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
      column: $table.installedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get installationPath => $composableBuilder(
      column: $table.installationPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get installationStatus => $composableBuilder(
      column: $table.installationStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get marketplaceMetadata => $composableBuilder(
      column: $table.marketplaceMetadata,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repositoryUrl => $composableBuilder(
      column: $table.repositoryUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repositoryOwner => $composableBuilder(
      column: $table.repositoryOwner,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repositoryName => $composableBuilder(
      column: $table.repositoryName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileCount => $composableBuilder(
      column: $table.fileCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get installationNotes => $composableBuilder(
      column: $table.installationNotes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));
}

class $$PluginInstallationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PluginInstallationsTable> {
  $$PluginInstallationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pluginId => $composableBuilder(
      column: $table.pluginId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pluginName => $composableBuilder(
      column: $table.pluginName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pluginVersion => $composableBuilder(
      column: $table.pluginVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pluginType => $composableBuilder(
      column: $table.pluginType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pluginAuthor => $composableBuilder(
      column: $table.pluginAuthor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
      column: $table.installedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get installationPath => $composableBuilder(
      column: $table.installationPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get installationStatus => $composableBuilder(
      column: $table.installationStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get marketplaceMetadata => $composableBuilder(
      column: $table.marketplaceMetadata,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repositoryUrl => $composableBuilder(
      column: $table.repositoryUrl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repositoryOwner => $composableBuilder(
      column: $table.repositoryOwner,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repositoryName => $composableBuilder(
      column: $table.repositoryName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileCount => $composableBuilder(
      column: $table.fileCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get installationNotes => $composableBuilder(
      column: $table.installationNotes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));
}

class $$PluginInstallationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PluginInstallationsTable> {
  $$PluginInstallationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pluginId =>
      $composableBuilder(column: $table.pluginId, builder: (column) => column);

  GeneratedColumn<String> get pluginName => $composableBuilder(
      column: $table.pluginName, builder: (column) => column);

  GeneratedColumn<String> get pluginVersion => $composableBuilder(
      column: $table.pluginVersion, builder: (column) => column);

  GeneratedColumn<String> get pluginType => $composableBuilder(
      column: $table.pluginType, builder: (column) => column);

  GeneratedColumn<String> get pluginAuthor => $composableBuilder(
      column: $table.pluginAuthor, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
      column: $table.installedAt, builder: (column) => column);

  GeneratedColumn<String> get installationPath => $composableBuilder(
      column: $table.installationPath, builder: (column) => column);

  GeneratedColumn<String> get installationStatus => $composableBuilder(
      column: $table.installationStatus, builder: (column) => column);

  GeneratedColumn<String> get marketplaceMetadata => $composableBuilder(
      column: $table.marketplaceMetadata, builder: (column) => column);

  GeneratedColumn<String> get repositoryUrl => $composableBuilder(
      column: $table.repositoryUrl, builder: (column) => column);

  GeneratedColumn<String> get repositoryOwner => $composableBuilder(
      column: $table.repositoryOwner, builder: (column) => column);

  GeneratedColumn<String> get repositoryName => $composableBuilder(
      column: $table.repositoryName, builder: (column) => column);

  GeneratedColumn<int> get fileCount =>
      $composableBuilder(column: $table.fileCount, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => column);

  GeneratedColumn<String> get installationNotes => $composableBuilder(
      column: $table.installationNotes, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);
}

class $$PluginInstallationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PluginInstallationsTable,
    PluginInstallationEntry,
    $$PluginInstallationsTableFilterComposer,
    $$PluginInstallationsTableOrderingComposer,
    $$PluginInstallationsTableAnnotationComposer,
    $$PluginInstallationsTableCreateCompanionBuilder,
    $$PluginInstallationsTableUpdateCompanionBuilder,
    (
      PluginInstallationEntry,
      BaseReferences<_$AppDatabase, $PluginInstallationsTable,
          PluginInstallationEntry>
    ),
    PluginInstallationEntry,
    PrefetchHooks Function()> {
  $$PluginInstallationsTableTableManager(
      _$AppDatabase db, $PluginInstallationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PluginInstallationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PluginInstallationsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PluginInstallationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> pluginId = const Value.absent(),
            Value<String> pluginName = const Value.absent(),
            Value<String> pluginVersion = const Value.absent(),
            Value<String> pluginType = const Value.absent(),
            Value<String> pluginAuthor = const Value.absent(),
            Value<DateTime> installedAt = const Value.absent(),
            Value<String> installationPath = const Value.absent(),
            Value<String> installationStatus = const Value.absent(),
            Value<String?> marketplaceMetadata = const Value.absent(),
            Value<String?> repositoryUrl = const Value.absent(),
            Value<String?> repositoryOwner = const Value.absent(),
            Value<String?> repositoryName = const Value.absent(),
            Value<int?> fileCount = const Value.absent(),
            Value<int?> totalBytes = const Value.absent(),
            Value<String?> installationNotes = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
          }) =>
              PluginInstallationsCompanion(
            id: id,
            pluginId: pluginId,
            pluginName: pluginName,
            pluginVersion: pluginVersion,
            pluginType: pluginType,
            pluginAuthor: pluginAuthor,
            installedAt: installedAt,
            installationPath: installationPath,
            installationStatus: installationStatus,
            marketplaceMetadata: marketplaceMetadata,
            repositoryUrl: repositoryUrl,
            repositoryOwner: repositoryOwner,
            repositoryName: repositoryName,
            fileCount: fileCount,
            totalBytes: totalBytes,
            installationNotes: installationNotes,
            errorMessage: errorMessage,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String pluginId,
            required String pluginName,
            required String pluginVersion,
            required String pluginType,
            required String pluginAuthor,
            Value<DateTime> installedAt = const Value.absent(),
            required String installationPath,
            Value<String> installationStatus = const Value.absent(),
            Value<String?> marketplaceMetadata = const Value.absent(),
            Value<String?> repositoryUrl = const Value.absent(),
            Value<String?> repositoryOwner = const Value.absent(),
            Value<String?> repositoryName = const Value.absent(),
            Value<int?> fileCount = const Value.absent(),
            Value<int?> totalBytes = const Value.absent(),
            Value<String?> installationNotes = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
          }) =>
              PluginInstallationsCompanion.insert(
            id: id,
            pluginId: pluginId,
            pluginName: pluginName,
            pluginVersion: pluginVersion,
            pluginType: pluginType,
            pluginAuthor: pluginAuthor,
            installedAt: installedAt,
            installationPath: installationPath,
            installationStatus: installationStatus,
            marketplaceMetadata: marketplaceMetadata,
            repositoryUrl: repositoryUrl,
            repositoryOwner: repositoryOwner,
            repositoryName: repositoryName,
            fileCount: fileCount,
            totalBytes: totalBytes,
            installationNotes: installationNotes,
            errorMessage: errorMessage,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PluginInstallationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PluginInstallationsTable,
    PluginInstallationEntry,
    $$PluginInstallationsTableFilterComposer,
    $$PluginInstallationsTableOrderingComposer,
    $$PluginInstallationsTableAnnotationComposer,
    $$PluginInstallationsTableCreateCompanionBuilder,
    $$PluginInstallationsTableUpdateCompanionBuilder,
    (
      PluginInstallationEntry,
      BaseReferences<_$AppDatabase, $PluginInstallationsTable,
          PluginInstallationEntry>
    ),
    PluginInstallationEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AlgorithmsTableTableManager get algorithms =>
      $$AlgorithmsTableTableManager(_db, _db.algorithms);
  $$SpecificationsTableTableManager get specifications =>
      $$SpecificationsTableTableManager(_db, _db.specifications);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db, _db.units);
  $$ParametersTableTableManager get parameters =>
      $$ParametersTableTableManager(_db, _db.parameters);
  $$ParameterEnumsTableTableManager get parameterEnums =>
      $$ParameterEnumsTableTableManager(_db, _db.parameterEnums);
  $$ParameterPagesTableTableManager get parameterPages =>
      $$ParameterPagesTableTableManager(_db, _db.parameterPages);
  $$ParameterPageItemsTableTableManager get parameterPageItems =>
      $$ParameterPageItemsTableTableManager(_db, _db.parameterPageItems);
  $$PresetsTableTableManager get presets =>
      $$PresetsTableTableManager(_db, _db.presets);
  $$PresetSlotsTableTableManager get presetSlots =>
      $$PresetSlotsTableTableManager(_db, _db.presetSlots);
  $$PresetParameterValuesTableTableManager get presetParameterValues =>
      $$PresetParameterValuesTableTableManager(_db, _db.presetParameterValues);
  $$PresetParameterStringValuesTableTableManager
      get presetParameterStringValues =>
          $$PresetParameterStringValuesTableTableManager(
              _db, _db.presetParameterStringValues);
  $$PresetMappingsTableTableManager get presetMappings =>
      $$PresetMappingsTableTableManager(_db, _db.presetMappings);
  $$PresetRoutingsTableTableManager get presetRoutings =>
      $$PresetRoutingsTableTableManager(_db, _db.presetRoutings);
  $$SdCardsTableTableManager get sdCards =>
      $$SdCardsTableTableManager(_db, _db.sdCards);
  $$IndexedPresetFilesTableTableManager get indexedPresetFiles =>
      $$IndexedPresetFilesTableTableManager(_db, _db.indexedPresetFiles);
  $$MetadataCacheTableTableManager get metadataCache =>
      $$MetadataCacheTableTableManager(_db, _db.metadataCache);
  $$PluginInstallationsTableTableManager get pluginInstallations =>
      $$PluginInstallationsTableTableManager(_db, _db.pluginInstallations);
}
