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
  @override
  List<GeneratedColumn> get $columns => [guid, name, numSpecifications];
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
  const AlgorithmEntry(
      {required this.guid,
      required this.name,
      required this.numSpecifications});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['guid'] = Variable<String>(guid);
    map['name'] = Variable<String>(name);
    map['num_specifications'] = Variable<int>(numSpecifications);
    return map;
  }

  AlgorithmsCompanion toCompanion(bool nullToAbsent) {
    return AlgorithmsCompanion(
      guid: Value(guid),
      name: Value(name),
      numSpecifications: Value(numSpecifications),
    );
  }

  factory AlgorithmEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlgorithmEntry(
      guid: serializer.fromJson<String>(json['guid']),
      name: serializer.fromJson<String>(json['name']),
      numSpecifications: serializer.fromJson<int>(json['numSpecifications']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'guid': serializer.toJson<String>(guid),
      'name': serializer.toJson<String>(name),
      'numSpecifications': serializer.toJson<int>(numSpecifications),
    };
  }

  AlgorithmEntry copyWith(
          {String? guid, String? name, int? numSpecifications}) =>
      AlgorithmEntry(
        guid: guid ?? this.guid,
        name: name ?? this.name,
        numSpecifications: numSpecifications ?? this.numSpecifications,
      );
  AlgorithmEntry copyWithCompanion(AlgorithmsCompanion data) {
    return AlgorithmEntry(
      guid: data.guid.present ? data.guid.value : this.guid,
      name: data.name.present ? data.name.value : this.name,
      numSpecifications: data.numSpecifications.present
          ? data.numSpecifications.value
          : this.numSpecifications,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlgorithmEntry(')
          ..write('guid: $guid, ')
          ..write('name: $name, ')
          ..write('numSpecifications: $numSpecifications')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(guid, name, numSpecifications);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlgorithmEntry &&
          other.guid == this.guid &&
          other.name == this.name &&
          other.numSpecifications == this.numSpecifications);
}

class AlgorithmsCompanion extends UpdateCompanion<AlgorithmEntry> {
  final Value<String> guid;
  final Value<String> name;
  final Value<int> numSpecifications;
  final Value<int> rowid;
  const AlgorithmsCompanion({
    this.guid = const Value.absent(),
    this.name = const Value.absent(),
    this.numSpecifications = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlgorithmsCompanion.insert({
    required String guid,
    required String name,
    required int numSpecifications,
    this.rowid = const Value.absent(),
  })  : guid = Value(guid),
        name = Value(name),
        numSpecifications = Value(numSpecifications);
  static Insertable<AlgorithmEntry> custom({
    Expression<String>? guid,
    Expression<String>? name,
    Expression<int>? numSpecifications,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (guid != null) 'guid': guid,
      if (name != null) 'name': name,
      if (numSpecifications != null) 'num_specifications': numSpecifications,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlgorithmsCompanion copyWith(
      {Value<String>? guid,
      Value<String>? name,
      Value<int>? numSpecifications,
      Value<int>? rowid}) {
    return AlgorithmsCompanion(
      guid: guid ?? this.guid,
      name: name ?? this.name,
      numSpecifications: numSpecifications ?? this.numSpecifications,
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
      'power_of_ten', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        algorithmGuid,
        parameterNumber,
        name,
        minValue,
        maxValue,
        defaultValue,
        unitId,
        powerOfTen
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
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    }
    if (data.containsKey('power_of_ten')) {
      context.handle(
          _powerOfTenMeta,
          powerOfTen.isAcceptableOrUnknown(
              data['power_of_ten']!, _powerOfTenMeta));
    } else if (isInserting) {
      context.missing(_powerOfTenMeta);
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
          .read(DriftSqlType.int, data['${effectivePrefix}min_value'])!,
      maxValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_value'])!,
      defaultValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}default_value'])!,
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_id']),
      powerOfTen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}power_of_ten'])!,
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
  final int minValue;
  final int maxValue;
  final int defaultValue;
  final int? unitId;
  final int powerOfTen;
  const ParameterEntry(
      {required this.algorithmGuid,
      required this.parameterNumber,
      required this.name,
      required this.minValue,
      required this.maxValue,
      required this.defaultValue,
      this.unitId,
      required this.powerOfTen});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['algorithm_guid'] = Variable<String>(algorithmGuid);
    map['parameter_number'] = Variable<int>(parameterNumber);
    map['name'] = Variable<String>(name);
    map['min_value'] = Variable<int>(minValue);
    map['max_value'] = Variable<int>(maxValue);
    map['default_value'] = Variable<int>(defaultValue);
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<int>(unitId);
    }
    map['power_of_ten'] = Variable<int>(powerOfTen);
    return map;
  }

  ParametersCompanion toCompanion(bool nullToAbsent) {
    return ParametersCompanion(
      algorithmGuid: Value(algorithmGuid),
      parameterNumber: Value(parameterNumber),
      name: Value(name),
      minValue: Value(minValue),
      maxValue: Value(maxValue),
      defaultValue: Value(defaultValue),
      unitId:
          unitId == null && nullToAbsent ? const Value.absent() : Value(unitId),
      powerOfTen: Value(powerOfTen),
    );
  }

  factory ParameterEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParameterEntry(
      algorithmGuid: serializer.fromJson<String>(json['algorithmGuid']),
      parameterNumber: serializer.fromJson<int>(json['parameterNumber']),
      name: serializer.fromJson<String>(json['name']),
      minValue: serializer.fromJson<int>(json['minValue']),
      maxValue: serializer.fromJson<int>(json['maxValue']),
      defaultValue: serializer.fromJson<int>(json['defaultValue']),
      unitId: serializer.fromJson<int?>(json['unitId']),
      powerOfTen: serializer.fromJson<int>(json['powerOfTen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'algorithmGuid': serializer.toJson<String>(algorithmGuid),
      'parameterNumber': serializer.toJson<int>(parameterNumber),
      'name': serializer.toJson<String>(name),
      'minValue': serializer.toJson<int>(minValue),
      'maxValue': serializer.toJson<int>(maxValue),
      'defaultValue': serializer.toJson<int>(defaultValue),
      'unitId': serializer.toJson<int?>(unitId),
      'powerOfTen': serializer.toJson<int>(powerOfTen),
    };
  }

  ParameterEntry copyWith(
          {String? algorithmGuid,
          int? parameterNumber,
          String? name,
          int? minValue,
          int? maxValue,
          int? defaultValue,
          Value<int?> unitId = const Value.absent(),
          int? powerOfTen}) =>
      ParameterEntry(
        algorithmGuid: algorithmGuid ?? this.algorithmGuid,
        parameterNumber: parameterNumber ?? this.parameterNumber,
        name: name ?? this.name,
        minValue: minValue ?? this.minValue,
        maxValue: maxValue ?? this.maxValue,
        defaultValue: defaultValue ?? this.defaultValue,
        unitId: unitId.present ? unitId.value : this.unitId,
        powerOfTen: powerOfTen ?? this.powerOfTen,
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
          ..write('powerOfTen: $powerOfTen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(algorithmGuid, parameterNumber, name,
      minValue, maxValue, defaultValue, unitId, powerOfTen);
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
          other.powerOfTen == this.powerOfTen);
}

class ParametersCompanion extends UpdateCompanion<ParameterEntry> {
  final Value<String> algorithmGuid;
  final Value<int> parameterNumber;
  final Value<String> name;
  final Value<int> minValue;
  final Value<int> maxValue;
  final Value<int> defaultValue;
  final Value<int?> unitId;
  final Value<int> powerOfTen;
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
    this.rowid = const Value.absent(),
  });
  ParametersCompanion.insert({
    required String algorithmGuid,
    required int parameterNumber,
    required String name,
    required int minValue,
    required int maxValue,
    required int defaultValue,
    this.unitId = const Value.absent(),
    required int powerOfTen,
    this.rowid = const Value.absent(),
  })  : algorithmGuid = Value(algorithmGuid),
        parameterNumber = Value(parameterNumber),
        name = Value(name),
        minValue = Value(minValue),
        maxValue = Value(maxValue),
        defaultValue = Value(defaultValue),
        powerOfTen = Value(powerOfTen);
  static Insertable<ParameterEntry> custom({
    Expression<String>? algorithmGuid,
    Expression<int>? parameterNumber,
    Expression<String>? name,
    Expression<int>? minValue,
    Expression<int>? maxValue,
    Expression<int>? defaultValue,
    Expression<int>? unitId,
    Expression<int>? powerOfTen,
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
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParametersCompanion copyWith(
      {Value<String>? algorithmGuid,
      Value<int>? parameterNumber,
      Value<String>? name,
      Value<int>? minValue,
      Value<int>? maxValue,
      Value<int>? defaultValue,
      Value<int?>? unitId,
      Value<int>? powerOfTen,
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
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
      'value', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [presetSlotId, parameterNumber, value];
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
  Set<GeneratedColumn> get $primaryKey => {presetSlotId, parameterNumber};
  @override
  PresetParameterValueEntry map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PresetParameterValueEntry(
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
  final int presetSlotId;
  final int parameterNumber;
  final int value;
  const PresetParameterValueEntry(
      {required this.presetSlotId,
      required this.parameterNumber,
      required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['preset_slot_id'] = Variable<int>(presetSlotId);
    map['parameter_number'] = Variable<int>(parameterNumber);
    map['value'] = Variable<int>(value);
    return map;
  }

  PresetParameterValuesCompanion toCompanion(bool nullToAbsent) {
    return PresetParameterValuesCompanion(
      presetSlotId: Value(presetSlotId),
      parameterNumber: Value(parameterNumber),
      value: Value(value),
    );
  }

  factory PresetParameterValueEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PresetParameterValueEntry(
      presetSlotId: serializer.fromJson<int>(json['presetSlotId']),
      parameterNumber: serializer.fromJson<int>(json['parameterNumber']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'presetSlotId': serializer.toJson<int>(presetSlotId),
      'parameterNumber': serializer.toJson<int>(parameterNumber),
      'value': serializer.toJson<int>(value),
    };
  }

  PresetParameterValueEntry copyWith(
          {int? presetSlotId, int? parameterNumber, int? value}) =>
      PresetParameterValueEntry(
        presetSlotId: presetSlotId ?? this.presetSlotId,
        parameterNumber: parameterNumber ?? this.parameterNumber,
        value: value ?? this.value,
      );
  PresetParameterValueEntry copyWithCompanion(
      PresetParameterValuesCompanion data) {
    return PresetParameterValueEntry(
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
          ..write('presetSlotId: $presetSlotId, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(presetSlotId, parameterNumber, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresetParameterValueEntry &&
          other.presetSlotId == this.presetSlotId &&
          other.parameterNumber == this.parameterNumber &&
          other.value == this.value);
}

class PresetParameterValuesCompanion
    extends UpdateCompanion<PresetParameterValueEntry> {
  final Value<int> presetSlotId;
  final Value<int> parameterNumber;
  final Value<int> value;
  final Value<int> rowid;
  const PresetParameterValuesCompanion({
    this.presetSlotId = const Value.absent(),
    this.parameterNumber = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PresetParameterValuesCompanion.insert({
    required int presetSlotId,
    required int parameterNumber,
    required int value,
    this.rowid = const Value.absent(),
  })  : presetSlotId = Value(presetSlotId),
        parameterNumber = Value(parameterNumber),
        value = Value(value);
  static Insertable<PresetParameterValueEntry> custom({
    Expression<int>? presetSlotId,
    Expression<int>? parameterNumber,
    Expression<int>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (presetSlotId != null) 'preset_slot_id': presetSlotId,
      if (parameterNumber != null) 'parameter_number': parameterNumber,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PresetParameterValuesCompanion copyWith(
      {Value<int>? presetSlotId,
      Value<int>? parameterNumber,
      Value<int>? value,
      Value<int>? rowid}) {
    return PresetParameterValuesCompanion(
      presetSlotId: presetSlotId ?? this.presetSlotId,
      parameterNumber: parameterNumber ?? this.parameterNumber,
      value: value ?? this.value,
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
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PresetParameterValuesCompanion(')
          ..write('presetSlotId: $presetSlotId, ')
          ..write('parameterNumber: $parameterNumber, ')
          ..write('value: $value, ')
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

class $FileSystemEntriesTable extends FileSystemEntries
    with TableInfo<$FileSystemEntriesTable, FileSystemEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileSystemEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES file_system_entries (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDirectoryMeta =
      const VerificationMeta('isDirectory');
  @override
  late final GeneratedColumn<bool> isDirectory = GeneratedColumn<bool>(
      'is_directory', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_directory" IN (0, 1))'));
  static const VerificationMeta _fullPathMeta =
      const VerificationMeta('fullPath');
  @override
  late final GeneratedColumn<String> fullPath = GeneratedColumn<String>(
      'full_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, parentId, name, isDirectory, fullPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_system_entries';
  @override
  VerificationContext validateIntegrity(Insertable<FileSystemEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_directory')) {
      context.handle(
          _isDirectoryMeta,
          isDirectory.isAcceptableOrUnknown(
              data['is_directory']!, _isDirectoryMeta));
    } else if (isInserting) {
      context.missing(_isDirectoryMeta);
    }
    if (data.containsKey('full_path')) {
      context.handle(_fullPathMeta,
          fullPath.isAcceptableOrUnknown(data['full_path']!, _fullPathMeta));
    } else if (isInserting) {
      context.missing(_fullPathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FileSystemEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileSystemEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isDirectory: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_directory'])!,
      fullPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_path'])!,
    );
  }

  @override
  $FileSystemEntriesTable createAlias(String alias) {
    return $FileSystemEntriesTable(attachedDatabase, alias);
  }
}

class FileSystemEntry extends DataClass implements Insertable<FileSystemEntry> {
  final int id;
  final int? parentId;
  final String name;
  final bool isDirectory;
  final String fullPath;
  const FileSystemEntry(
      {required this.id,
      this.parentId,
      required this.name,
      required this.isDirectory,
      required this.fullPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['name'] = Variable<String>(name);
    map['is_directory'] = Variable<bool>(isDirectory);
    map['full_path'] = Variable<String>(fullPath);
    return map;
  }

  FileSystemEntriesCompanion toCompanion(bool nullToAbsent) {
    return FileSystemEntriesCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      isDirectory: Value(isDirectory),
      fullPath: Value(fullPath),
    );
  }

  factory FileSystemEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileSystemEntry(
      id: serializer.fromJson<int>(json['id']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      isDirectory: serializer.fromJson<bool>(json['isDirectory']),
      fullPath: serializer.fromJson<String>(json['fullPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'parentId': serializer.toJson<int?>(parentId),
      'name': serializer.toJson<String>(name),
      'isDirectory': serializer.toJson<bool>(isDirectory),
      'fullPath': serializer.toJson<String>(fullPath),
    };
  }

  FileSystemEntry copyWith(
          {int? id,
          Value<int?> parentId = const Value.absent(),
          String? name,
          bool? isDirectory,
          String? fullPath}) =>
      FileSystemEntry(
        id: id ?? this.id,
        parentId: parentId.present ? parentId.value : this.parentId,
        name: name ?? this.name,
        isDirectory: isDirectory ?? this.isDirectory,
        fullPath: fullPath ?? this.fullPath,
      );
  FileSystemEntry copyWithCompanion(FileSystemEntriesCompanion data) {
    return FileSystemEntry(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      isDirectory:
          data.isDirectory.present ? data.isDirectory.value : this.isDirectory,
      fullPath: data.fullPath.present ? data.fullPath.value : this.fullPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileSystemEntry(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('isDirectory: $isDirectory, ')
          ..write('fullPath: $fullPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, parentId, name, isDirectory, fullPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileSystemEntry &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.isDirectory == this.isDirectory &&
          other.fullPath == this.fullPath);
}

class FileSystemEntriesCompanion extends UpdateCompanion<FileSystemEntry> {
  final Value<int> id;
  final Value<int?> parentId;
  final Value<String> name;
  final Value<bool> isDirectory;
  final Value<String> fullPath;
  const FileSystemEntriesCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.isDirectory = const Value.absent(),
    this.fullPath = const Value.absent(),
  });
  FileSystemEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    required String name,
    required bool isDirectory,
    required String fullPath,
  })  : name = Value(name),
        isDirectory = Value(isDirectory),
        fullPath = Value(fullPath);
  static Insertable<FileSystemEntry> custom({
    Expression<int>? id,
    Expression<int>? parentId,
    Expression<String>? name,
    Expression<bool>? isDirectory,
    Expression<String>? fullPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (isDirectory != null) 'is_directory': isDirectory,
      if (fullPath != null) 'full_path': fullPath,
    });
  }

  FileSystemEntriesCompanion copyWith(
      {Value<int>? id,
      Value<int?>? parentId,
      Value<String>? name,
      Value<bool>? isDirectory,
      Value<String>? fullPath}) {
    return FileSystemEntriesCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      isDirectory: isDirectory ?? this.isDirectory,
      fullPath: fullPath ?? this.fullPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDirectory.present) {
      map['is_directory'] = Variable<bool>(isDirectory.value);
    }
    if (fullPath.present) {
      map['full_path'] = Variable<String>(fullPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileSystemEntriesCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('isDirectory: $isDirectory, ')
          ..write('fullPath: $fullPath')
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
  late final $PresetMappingsTable presetMappings = $PresetMappingsTable(this);
  late final $PresetRoutingsTable presetRoutings = $PresetRoutingsTable(this);
  late final $FileSystemEntriesTable fileSystemEntries =
      $FileSystemEntriesTable(this);
  late final MetadataDao metadataDao = MetadataDao(this as AppDatabase);
  late final PresetsDao presetsDao = PresetsDao(this as AppDatabase);
  late final FileSystemDao fileSystemDao = FileSystemDao(this as AppDatabase);
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
        presetMappings,
        presetRoutings,
        fileSystemEntries
      ];
}

typedef $$AlgorithmsTableCreateCompanionBuilder = AlgorithmsCompanion Function({
  required String guid,
  required String name,
  required int numSpecifications,
  Value<int> rowid,
});
typedef $$AlgorithmsTableUpdateCompanionBuilder = AlgorithmsCompanion Function({
  Value<String> guid,
  Value<String> name,
  Value<int> numSpecifications,
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
            Value<int> rowid = const Value.absent(),
          }) =>
              AlgorithmsCompanion(
            guid: guid,
            name: name,
            numSpecifications: numSpecifications,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String guid,
            required String name,
            required int numSpecifications,
            Value<int> rowid = const Value.absent(),
          }) =>
              AlgorithmsCompanion.insert(
            guid: guid,
            name: name,
            numSpecifications: numSpecifications,
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
  required int minValue,
  required int maxValue,
  required int defaultValue,
  Value<int?> unitId,
  required int powerOfTen,
  Value<int> rowid,
});
typedef $$ParametersTableUpdateCompanionBuilder = ParametersCompanion Function({
  Value<String> algorithmGuid,
  Value<int> parameterNumber,
  Value<String> name,
  Value<int> minValue,
  Value<int> maxValue,
  Value<int> defaultValue,
  Value<int?> unitId,
  Value<int> powerOfTen,
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
            Value<int> minValue = const Value.absent(),
            Value<int> maxValue = const Value.absent(),
            Value<int> defaultValue = const Value.absent(),
            Value<int?> unitId = const Value.absent(),
            Value<int> powerOfTen = const Value.absent(),
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
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String algorithmGuid,
            required int parameterNumber,
            required String name,
            required int minValue,
            required int maxValue,
            required int defaultValue,
            Value<int?> unitId = const Value.absent(),
            required int powerOfTen,
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
              presetMappingsRefs = false,
              presetRoutingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (presetParameterValuesRefs) db.presetParameterValues,
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
        bool presetMappingsRefs,
        bool presetRoutingsRefs})>;
typedef $$PresetParameterValuesTableCreateCompanionBuilder
    = PresetParameterValuesCompanion Function({
  required int presetSlotId,
  required int parameterNumber,
  required int value,
  Value<int> rowid,
});
typedef $$PresetParameterValuesTableUpdateCompanionBuilder
    = PresetParameterValuesCompanion Function({
  Value<int> presetSlotId,
  Value<int> parameterNumber,
  Value<int> value,
  Value<int> rowid,
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
            Value<int> presetSlotId = const Value.absent(),
            Value<int> parameterNumber = const Value.absent(),
            Value<int> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PresetParameterValuesCompanion(
            presetSlotId: presetSlotId,
            parameterNumber: parameterNumber,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int presetSlotId,
            required int parameterNumber,
            required int value,
            Value<int> rowid = const Value.absent(),
          }) =>
              PresetParameterValuesCompanion.insert(
            presetSlotId: presetSlotId,
            parameterNumber: parameterNumber,
            value: value,
            rowid: rowid,
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
typedef $$FileSystemEntriesTableCreateCompanionBuilder
    = FileSystemEntriesCompanion Function({
  Value<int> id,
  Value<int?> parentId,
  required String name,
  required bool isDirectory,
  required String fullPath,
});
typedef $$FileSystemEntriesTableUpdateCompanionBuilder
    = FileSystemEntriesCompanion Function({
  Value<int> id,
  Value<int?> parentId,
  Value<String> name,
  Value<bool> isDirectory,
  Value<String> fullPath,
});

final class $$FileSystemEntriesTableReferences extends BaseReferences<
    _$AppDatabase, $FileSystemEntriesTable, FileSystemEntry> {
  $$FileSystemEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $FileSystemEntriesTable _parentIdTable(_$AppDatabase db) =>
      db.fileSystemEntries.createAlias($_aliasNameGenerator(
          db.fileSystemEntries.parentId, db.fileSystemEntries.id));

  $$FileSystemEntriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager =
        $$FileSystemEntriesTableTableManager($_db, $_db.fileSystemEntries)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FileSystemEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FileSystemEntriesTable> {
  $$FileSystemEntriesTableFilterComposer({
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

  ColumnFilters<bool> get isDirectory => $composableBuilder(
      column: $table.isDirectory, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fullPath => $composableBuilder(
      column: $table.fullPath, builder: (column) => ColumnFilters(column));

  $$FileSystemEntriesTableFilterComposer get parentId {
    final $$FileSystemEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.fileSystemEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FileSystemEntriesTableFilterComposer(
              $db: $db,
              $table: $db.fileSystemEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FileSystemEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FileSystemEntriesTable> {
  $$FileSystemEntriesTableOrderingComposer({
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

  ColumnOrderings<bool> get isDirectory => $composableBuilder(
      column: $table.isDirectory, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fullPath => $composableBuilder(
      column: $table.fullPath, builder: (column) => ColumnOrderings(column));

  $$FileSystemEntriesTableOrderingComposer get parentId {
    final $$FileSystemEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.fileSystemEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FileSystemEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.fileSystemEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FileSystemEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FileSystemEntriesTable> {
  $$FileSystemEntriesTableAnnotationComposer({
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

  GeneratedColumn<bool> get isDirectory => $composableBuilder(
      column: $table.isDirectory, builder: (column) => column);

  GeneratedColumn<String> get fullPath =>
      $composableBuilder(column: $table.fullPath, builder: (column) => column);

  $$FileSystemEntriesTableAnnotationComposer get parentId {
    final $$FileSystemEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.parentId,
            referencedTable: $db.fileSystemEntries,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$FileSystemEntriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.fileSystemEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$FileSystemEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FileSystemEntriesTable,
    FileSystemEntry,
    $$FileSystemEntriesTableFilterComposer,
    $$FileSystemEntriesTableOrderingComposer,
    $$FileSystemEntriesTableAnnotationComposer,
    $$FileSystemEntriesTableCreateCompanionBuilder,
    $$FileSystemEntriesTableUpdateCompanionBuilder,
    (FileSystemEntry, $$FileSystemEntriesTableReferences),
    FileSystemEntry,
    PrefetchHooks Function({bool parentId})> {
  $$FileSystemEntriesTableTableManager(
      _$AppDatabase db, $FileSystemEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileSystemEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileSystemEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileSystemEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isDirectory = const Value.absent(),
            Value<String> fullPath = const Value.absent(),
          }) =>
              FileSystemEntriesCompanion(
            id: id,
            parentId: parentId,
            name: name,
            isDirectory: isDirectory,
            fullPath: fullPath,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            required String name,
            required bool isDirectory,
            required String fullPath,
          }) =>
              FileSystemEntriesCompanion.insert(
            id: id,
            parentId: parentId,
            name: name,
            isDirectory: isDirectory,
            fullPath: fullPath,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FileSystemEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({parentId = false}) {
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
                if (parentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.parentId,
                    referencedTable:
                        $$FileSystemEntriesTableReferences._parentIdTable(db),
                    referencedColumn: $$FileSystemEntriesTableReferences
                        ._parentIdTable(db)
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

typedef $$FileSystemEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FileSystemEntriesTable,
    FileSystemEntry,
    $$FileSystemEntriesTableFilterComposer,
    $$FileSystemEntriesTableOrderingComposer,
    $$FileSystemEntriesTableAnnotationComposer,
    $$FileSystemEntriesTableCreateCompanionBuilder,
    $$FileSystemEntriesTableUpdateCompanionBuilder,
    (FileSystemEntry, $$FileSystemEntriesTableReferences),
    FileSystemEntry,
    PrefetchHooks Function({bool parentId})>;

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
  $$PresetMappingsTableTableManager get presetMappings =>
      $$PresetMappingsTableTableManager(_db, _db.presetMappings);
  $$PresetRoutingsTableTableManager get presetRoutings =>
      $$PresetRoutingsTableTableManager(_db, _db.presetRoutings);
  $$FileSystemEntriesTableTableManager get fileSystemEntries =>
      $$FileSystemEntriesTableTableManager(_db, _db.fileSystemEntries);
}
