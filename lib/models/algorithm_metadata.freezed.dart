// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'algorithm_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AlgorithmMetadata {
  String get guid;
  String get name;
  List<String> get categories;
  String get description;
  List<AlgorithmSpecification> get specifications;
  @JsonKey(fromJson: _parametersFromJson)
  List<AlgorithmParameter> get parameters;
  List<String> get features; // List of feature GUIDs
  @JsonKey(name: 'input_ports', fromJson: _portsFromJson)
  List<AlgorithmPort> get inputPorts;
  @JsonKey(name: 'output_ports', fromJson: _portsFromJson)
  List<AlgorithmPort> get outputPorts;

  /// Create a copy of AlgorithmMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AlgorithmMetadataCopyWith<AlgorithmMetadata> get copyWith =>
      _$AlgorithmMetadataCopyWithImpl<AlgorithmMetadata>(
          this as AlgorithmMetadata, _$identity);

  /// Serializes this AlgorithmMetadata to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AlgorithmMetadata &&
            (identical(other.guid, guid) || other.guid == guid) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality()
                .equals(other.categories, categories) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other.specifications, specifications) &&
            const DeepCollectionEquality()
                .equals(other.parameters, parameters) &&
            const DeepCollectionEquality().equals(other.features, features) &&
            const DeepCollectionEquality()
                .equals(other.inputPorts, inputPorts) &&
            const DeepCollectionEquality()
                .equals(other.outputPorts, outputPorts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      guid,
      name,
      const DeepCollectionEquality().hash(categories),
      description,
      const DeepCollectionEquality().hash(specifications),
      const DeepCollectionEquality().hash(parameters),
      const DeepCollectionEquality().hash(features),
      const DeepCollectionEquality().hash(inputPorts),
      const DeepCollectionEquality().hash(outputPorts));

  @override
  String toString() {
    return 'AlgorithmMetadata(guid: $guid, name: $name, categories: $categories, description: $description, specifications: $specifications, parameters: $parameters, features: $features, inputPorts: $inputPorts, outputPorts: $outputPorts)';
  }
}

/// @nodoc
abstract mixin class $AlgorithmMetadataCopyWith<$Res> {
  factory $AlgorithmMetadataCopyWith(
          AlgorithmMetadata value, $Res Function(AlgorithmMetadata) _then) =
      _$AlgorithmMetadataCopyWithImpl;
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
      @JsonKey(name: 'input_ports', fromJson: _portsFromJson)
      List<AlgorithmPort> inputPorts,
      @JsonKey(name: 'output_ports', fromJson: _portsFromJson)
      List<AlgorithmPort> outputPorts});
}

/// @nodoc
class _$AlgorithmMetadataCopyWithImpl<$Res>
    implements $AlgorithmMetadataCopyWith<$Res> {
  _$AlgorithmMetadataCopyWithImpl(this._self, this._then);

  final AlgorithmMetadata _self;
  final $Res Function(AlgorithmMetadata) _then;

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
    return _then(_self.copyWith(
      guid: null == guid
          ? _self.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      categories: null == categories
          ? _self.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      specifications: null == specifications
          ? _self.specifications
          : specifications // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmSpecification>,
      parameters: null == parameters
          ? _self.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmParameter>,
      features: null == features
          ? _self.features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
      inputPorts: null == inputPorts
          ? _self.inputPorts
          : inputPorts // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmPort>,
      outputPorts: null == outputPorts
          ? _self.outputPorts
          : outputPorts // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmPort>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _AlgorithmMetadata implements AlgorithmMetadata {
  const _AlgorithmMetadata(
      {required this.guid,
      required this.name,
      required final List<String> categories,
      required this.description,
      final List<AlgorithmSpecification> specifications = const [],
      @JsonKey(fromJson: _parametersFromJson)
      final List<AlgorithmParameter> parameters = const [],
      final List<String> features = const [],
      @JsonKey(name: 'input_ports', fromJson: _portsFromJson)
      final List<AlgorithmPort> inputPorts = const [],
      @JsonKey(name: 'output_ports', fromJson: _portsFromJson)
      final List<AlgorithmPort> outputPorts = const []})
      : _categories = categories,
        _specifications = specifications,
        _parameters = parameters,
        _features = features,
        _inputPorts = inputPorts,
        _outputPorts = outputPorts;
  factory _AlgorithmMetadata.fromJson(Map<String, dynamic> json) =>
      _$AlgorithmMetadataFromJson(json);

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

  final List<String> _features;
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
  @JsonKey(name: 'input_ports', fromJson: _portsFromJson)
  List<AlgorithmPort> get inputPorts {
    if (_inputPorts is EqualUnmodifiableListView) return _inputPorts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_inputPorts);
  }

  final List<AlgorithmPort> _outputPorts;
  @override
  @JsonKey(name: 'output_ports', fromJson: _portsFromJson)
  List<AlgorithmPort> get outputPorts {
    if (_outputPorts is EqualUnmodifiableListView) return _outputPorts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_outputPorts);
  }

  /// Create a copy of AlgorithmMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AlgorithmMetadataCopyWith<_AlgorithmMetadata> get copyWith =>
      __$AlgorithmMetadataCopyWithImpl<_AlgorithmMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AlgorithmMetadataToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AlgorithmMetadata &&
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

  @override
  String toString() {
    return 'AlgorithmMetadata(guid: $guid, name: $name, categories: $categories, description: $description, specifications: $specifications, parameters: $parameters, features: $features, inputPorts: $inputPorts, outputPorts: $outputPorts)';
  }
}

/// @nodoc
abstract mixin class _$AlgorithmMetadataCopyWith<$Res>
    implements $AlgorithmMetadataCopyWith<$Res> {
  factory _$AlgorithmMetadataCopyWith(
          _AlgorithmMetadata value, $Res Function(_AlgorithmMetadata) _then) =
      __$AlgorithmMetadataCopyWithImpl;
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
      @JsonKey(name: 'input_ports', fromJson: _portsFromJson)
      List<AlgorithmPort> inputPorts,
      @JsonKey(name: 'output_ports', fromJson: _portsFromJson)
      List<AlgorithmPort> outputPorts});
}

/// @nodoc
class __$AlgorithmMetadataCopyWithImpl<$Res>
    implements _$AlgorithmMetadataCopyWith<$Res> {
  __$AlgorithmMetadataCopyWithImpl(this._self, this._then);

  final _AlgorithmMetadata _self;
  final $Res Function(_AlgorithmMetadata) _then;

  /// Create a copy of AlgorithmMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_AlgorithmMetadata(
      guid: null == guid
          ? _self.guid
          : guid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      categories: null == categories
          ? _self._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      specifications: null == specifications
          ? _self._specifications
          : specifications // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmSpecification>,
      parameters: null == parameters
          ? _self._parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmParameter>,
      features: null == features
          ? _self._features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
      inputPorts: null == inputPorts
          ? _self._inputPorts
          : inputPorts // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmPort>,
      outputPorts: null == outputPorts
          ? _self._outputPorts
          : outputPorts // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmPort>,
    ));
  }
}

// dart format on
