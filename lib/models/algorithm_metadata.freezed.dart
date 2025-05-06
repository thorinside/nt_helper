// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'algorithm_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AlgorithmMetadata _$AlgorithmMetadataFromJson(Map<String, dynamic> json) {
  return _AlgorithmMetadata.fromJson(json);
}

/// @nodoc
mixin _$AlgorithmMetadata {
  String get guid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<String> get categories => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<AlgorithmSpecification> get specifications =>
      throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parametersFromJson)
  List<AlgorithmParameter> get parameters =>
      throw _privateConstructorUsedError; // Use custom parser
  List<String> get features =>
      throw _privateConstructorUsedError; // List of feature GUIDs
  @JsonKey(name: 'input_ports', fromJson: _portsFromJson, toJson: _portsToJson)
  List<AlgorithmPort> get inputPorts => throw _privateConstructorUsedError;
  @JsonKey(name: 'output_ports', fromJson: _portsFromJson, toJson: _portsToJson)
  List<AlgorithmPort> get outputPorts => throw _privateConstructorUsedError;

  /// Serializes this AlgorithmMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlgorithmMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlgorithmMetadataCopyWith<AlgorithmMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlgorithmMetadataCopyWith<$Res> {
  factory $AlgorithmMetadataCopyWith(
          AlgorithmMetadata value, $Res Function(AlgorithmMetadata) then) =
      _$AlgorithmMetadataCopyWithImpl<$Res, AlgorithmMetadata>;
  @useResult
  $Res call(
      {String guid,
      String name,
      List<String> categories,
      String description,
      List<AlgorithmSpecification> specifications,
      @JsonKey(fromJson: _parametersFromJson)
      List<AlgorithmParameter> parameters,
      List<String> features,
      @JsonKey(
          name: 'input_ports', fromJson: _portsFromJson, toJson: _portsToJson)
      List<AlgorithmPort> inputPorts,
      @JsonKey(
          name: 'output_ports', fromJson: _portsFromJson, toJson: _portsToJson)
      List<AlgorithmPort> outputPorts});
}

/// @nodoc
class _$AlgorithmMetadataCopyWithImpl<$Res, $Val extends AlgorithmMetadata>
    implements $AlgorithmMetadataCopyWith<$Res> {
  _$AlgorithmMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlgorithmMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guid = null,
    Object? name = null,
    Object? categories = null,
    Object? description = null,
    Object? specifications = null,
    Object? parameters = null,
    Object? features = null,
    Object? inputPorts = null,
    Object? outputPorts = null,
  }) {
    return _then(_value.copyWith(
      guid: null == guid
          ? _value.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      specifications: null == specifications
          ? _value.specifications
          : specifications // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmSpecification>,
      parameters: null == parameters
          ? _value.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmParameter>,
      features: null == features
          ? _value.features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
      inputPorts: null == inputPorts
          ? _value.inputPorts
          : inputPorts // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmPort>,
      outputPorts: null == outputPorts
          ? _value.outputPorts
          : outputPorts // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmPort>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlgorithmMetadataImplCopyWith<$Res>
    implements $AlgorithmMetadataCopyWith<$Res> {
  factory _$$AlgorithmMetadataImplCopyWith(_$AlgorithmMetadataImpl value,
          $Res Function(_$AlgorithmMetadataImpl) then) =
      __$$AlgorithmMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String guid,
      String name,
      List<String> categories,
      String description,
      List<AlgorithmSpecification> specifications,
      @JsonKey(fromJson: _parametersFromJson)
      List<AlgorithmParameter> parameters,
      List<String> features,
      @JsonKey(
          name: 'input_ports', fromJson: _portsFromJson, toJson: _portsToJson)
      List<AlgorithmPort> inputPorts,
      @JsonKey(
          name: 'output_ports', fromJson: _portsFromJson, toJson: _portsToJson)
      List<AlgorithmPort> outputPorts});
}

/// @nodoc
class __$$AlgorithmMetadataImplCopyWithImpl<$Res>
    extends _$AlgorithmMetadataCopyWithImpl<$Res, _$AlgorithmMetadataImpl>
    implements _$$AlgorithmMetadataImplCopyWith<$Res> {
  __$$AlgorithmMetadataImplCopyWithImpl(_$AlgorithmMetadataImpl _value,
      $Res Function(_$AlgorithmMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of AlgorithmMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guid = null,
    Object? name = null,
    Object? categories = null,
    Object? description = null,
    Object? specifications = null,
    Object? parameters = null,
    Object? features = null,
    Object? inputPorts = null,
    Object? outputPorts = null,
  }) {
    return _then(_$AlgorithmMetadataImpl(
      guid: null == guid
          ? _value.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      specifications: null == specifications
          ? _value._specifications
          : specifications // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmSpecification>,
      parameters: null == parameters
          ? _value._parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmParameter>,
      features: null == features
          ? _value._features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
      inputPorts: null == inputPorts
          ? _value._inputPorts
          : inputPorts // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmPort>,
      outputPorts: null == outputPorts
          ? _value._outputPorts
          : outputPorts // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmPort>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlgorithmMetadataImpl implements _AlgorithmMetadata {
  const _$AlgorithmMetadataImpl(
      {required this.guid,
      required this.name,
      required final List<String> categories,
      required this.description,
      final List<AlgorithmSpecification> specifications = const [],
      @JsonKey(fromJson: _parametersFromJson)
      final List<AlgorithmParameter> parameters = const [],
      final List<String> features = const [],
      @JsonKey(
          name: 'input_ports', fromJson: _portsFromJson, toJson: _portsToJson)
      final List<AlgorithmPort> inputPorts = const [],
      @JsonKey(
          name: 'output_ports', fromJson: _portsFromJson, toJson: _portsToJson)
      final List<AlgorithmPort> outputPorts = const []})
      : _categories = categories,
        _specifications = specifications,
        _parameters = parameters,
        _features = features,
        _inputPorts = inputPorts,
        _outputPorts = outputPorts;

  factory _$AlgorithmMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlgorithmMetadataImplFromJson(json);

  @override
  final String guid;
  @override
  final String name;
  final List<String> _categories;
  @override
  List<String> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  final String description;
  final List<AlgorithmSpecification> _specifications;
  @override
  @JsonKey()
  List<AlgorithmSpecification> get specifications {
    if (_specifications is EqualUnmodifiableListView) return _specifications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_specifications);
  }

  final List<AlgorithmParameter> _parameters;
  @override
  @JsonKey(fromJson: _parametersFromJson)
  List<AlgorithmParameter> get parameters {
    if (_parameters is EqualUnmodifiableListView) return _parameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_parameters);
  }

// Use custom parser
  final List<String> _features;
// Use custom parser
  @override
  @JsonKey()
  List<String> get features {
    if (_features is EqualUnmodifiableListView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_features);
  }

// List of feature GUIDs
  final List<AlgorithmPort> _inputPorts;
// List of feature GUIDs
  @override
  @JsonKey(name: 'input_ports', fromJson: _portsFromJson, toJson: _portsToJson)
  List<AlgorithmPort> get inputPorts {
    if (_inputPorts is EqualUnmodifiableListView) return _inputPorts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_inputPorts);
  }

  final List<AlgorithmPort> _outputPorts;
  @override
  @JsonKey(name: 'output_ports', fromJson: _portsFromJson, toJson: _portsToJson)
  List<AlgorithmPort> get outputPorts {
    if (_outputPorts is EqualUnmodifiableListView) return _outputPorts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_outputPorts);
  }

  @override
  String toString() {
    return 'AlgorithmMetadata(guid: $guid, name: $name, categories: $categories, description: $description, specifications: $specifications, parameters: $parameters, features: $features, inputPorts: $inputPorts, outputPorts: $outputPorts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlgorithmMetadataImpl &&
            (identical(other.guid, guid) || other.guid == guid) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._specifications, _specifications) &&
            const DeepCollectionEquality()
                .equals(other._parameters, _parameters) &&
            const DeepCollectionEquality().equals(other._features, _features) &&
            const DeepCollectionEquality()
                .equals(other._inputPorts, _inputPorts) &&
            const DeepCollectionEquality()
                .equals(other._outputPorts, _outputPorts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      guid,
      name,
      const DeepCollectionEquality().hash(_categories),
      description,
      const DeepCollectionEquality().hash(_specifications),
      const DeepCollectionEquality().hash(_parameters),
      const DeepCollectionEquality().hash(_features),
      const DeepCollectionEquality().hash(_inputPorts),
      const DeepCollectionEquality().hash(_outputPorts));

  /// Create a copy of AlgorithmMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlgorithmMetadataImplCopyWith<_$AlgorithmMetadataImpl> get copyWith =>
      __$$AlgorithmMetadataImplCopyWithImpl<_$AlgorithmMetadataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlgorithmMetadataImplToJson(
      this,
    );
  }
}

abstract class _AlgorithmMetadata implements AlgorithmMetadata {
  const factory _AlgorithmMetadata(
      {required final String guid,
      required final String name,
      required final List<String> categories,
      required final String description,
      final List<AlgorithmSpecification> specifications,
      @JsonKey(fromJson: _parametersFromJson)
      final List<AlgorithmParameter> parameters,
      final List<String> features,
      @JsonKey(
          name: 'input_ports', fromJson: _portsFromJson, toJson: _portsToJson)
      final List<AlgorithmPort> inputPorts,
      @JsonKey(
          name: 'output_ports', fromJson: _portsFromJson, toJson: _portsToJson)
      final List<AlgorithmPort> outputPorts}) = _$AlgorithmMetadataImpl;

  factory _AlgorithmMetadata.fromJson(Map<String, dynamic> json) =
      _$AlgorithmMetadataImpl.fromJson;

  @override
  String get guid;
  @override
  String get name;
  @override
  List<String> get categories;
  @override
  String get description;
  @override
  List<AlgorithmSpecification> get specifications;
  @override
  @JsonKey(fromJson: _parametersFromJson)
  List<AlgorithmParameter> get parameters; // Use custom parser
  @override
  List<String> get features; // List of feature GUIDs
  @override
  @JsonKey(name: 'input_ports', fromJson: _portsFromJson, toJson: _portsToJson)
  List<AlgorithmPort> get inputPorts;
  @override
  @JsonKey(name: 'output_ports', fromJson: _portsFromJson, toJson: _portsToJson)
  List<AlgorithmPort> get outputPorts;

  /// Create a copy of AlgorithmMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlgorithmMetadataImplCopyWith<_$AlgorithmMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
