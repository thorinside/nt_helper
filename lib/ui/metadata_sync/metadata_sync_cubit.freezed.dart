// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'metadata_sync_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MetadataSyncState implements DiagnosticableTreeMixin {
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties..add(DiagnosticsProperty('type', 'MetadataSyncState'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is MetadataSyncState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState()';
  }
}

/// @nodoc
class $MetadataSyncStateCopyWith<$Res> {
  $MetadataSyncStateCopyWith(
      MetadataSyncState _, $Res Function(MetadataSyncState) __);
}

/// @nodoc

class Idle with DiagnosticableTreeMixin implements MetadataSyncState {
  const Idle();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties..add(DiagnosticsProperty('type', 'MetadataSyncState.idle'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is Idle);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.idle()';
  }
}

/// @nodoc

class SyncingMetadata
    with DiagnosticableTreeMixin
    implements MetadataSyncState {
  const SyncingMetadata(
      {required this.progress,
      required this.mainMessage,
      required this.subMessage,
      this.algorithmsProcessed,
      this.totalAlgorithms});

  final double progress;
// 0.0 to 1.0
  final String mainMessage;
// e.g., "Processing Algorithm X (15/128)"
  final String subMessage;
// e.g., "Adding to preset..."
  final int? algorithmsProcessed;
// Keep for progress calculation
  final int? totalAlgorithms;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SyncingMetadataCopyWith<SyncingMetadata> get copyWith =>
      _$SyncingMetadataCopyWithImpl<SyncingMetadata>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'MetadataSyncState.syncingMetadata'))
      ..add(DiagnosticsProperty('progress', progress))
      ..add(DiagnosticsProperty('mainMessage', mainMessage))
      ..add(DiagnosticsProperty('subMessage', subMessage))
      ..add(DiagnosticsProperty('algorithmsProcessed', algorithmsProcessed))
      ..add(DiagnosticsProperty('totalAlgorithms', totalAlgorithms));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SyncingMetadata &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.mainMessage, mainMessage) ||
                other.mainMessage == mainMessage) &&
            (identical(other.subMessage, subMessage) ||
                other.subMessage == subMessage) &&
            (identical(other.algorithmsProcessed, algorithmsProcessed) ||
                other.algorithmsProcessed == algorithmsProcessed) &&
            (identical(other.totalAlgorithms, totalAlgorithms) ||
                other.totalAlgorithms == totalAlgorithms));
  }

  @override
  int get hashCode => Object.hash(runtimeType, progress, mainMessage,
      subMessage, algorithmsProcessed, totalAlgorithms);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.syncingMetadata(progress: $progress, mainMessage: $mainMessage, subMessage: $subMessage, algorithmsProcessed: $algorithmsProcessed, totalAlgorithms: $totalAlgorithms)';
  }
}

/// @nodoc
abstract mixin class $SyncingMetadataCopyWith<$Res>
    implements $MetadataSyncStateCopyWith<$Res> {
  factory $SyncingMetadataCopyWith(
          SyncingMetadata value, $Res Function(SyncingMetadata) _then) =
      _$SyncingMetadataCopyWithImpl;
  @useResult
  $Res call(
      {double progress,
      String mainMessage,
      String subMessage,
      int? algorithmsProcessed,
      int? totalAlgorithms});
}

/// @nodoc
class _$SyncingMetadataCopyWithImpl<$Res>
    implements $SyncingMetadataCopyWith<$Res> {
  _$SyncingMetadataCopyWithImpl(this._self, this._then);

  final SyncingMetadata _self;
  final $Res Function(SyncingMetadata) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? progress = null,
    Object? mainMessage = null,
    Object? subMessage = null,
    Object? algorithmsProcessed = freezed,
    Object? totalAlgorithms = freezed,
  }) {
    return _then(SyncingMetadata(
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      mainMessage: null == mainMessage
          ? _self.mainMessage
          : mainMessage // ignore: cast_nullable_to_non_nullable
              as String,
      subMessage: null == subMessage
          ? _self.subMessage
          : subMessage // ignore: cast_nullable_to_non_nullable
              as String,
      algorithmsProcessed: freezed == algorithmsProcessed
          ? _self.algorithmsProcessed
          : algorithmsProcessed // ignore: cast_nullable_to_non_nullable
              as int?,
      totalAlgorithms: freezed == totalAlgorithms
          ? _self.totalAlgorithms
          : totalAlgorithms // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class MetadataSyncSuccess
    with DiagnosticableTreeMixin
    implements MetadataSyncState {
  const MetadataSyncSuccess(this.message);

  final String message;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MetadataSyncSuccessCopyWith<MetadataSyncSuccess> get copyWith =>
      _$MetadataSyncSuccessCopyWithImpl<MetadataSyncSuccess>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(
          DiagnosticsProperty('type', 'MetadataSyncState.metadataSyncSuccess'))
      ..add(DiagnosticsProperty('message', message));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MetadataSyncSuccess &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.metadataSyncSuccess(message: $message)';
  }
}

/// @nodoc
abstract mixin class $MetadataSyncSuccessCopyWith<$Res>
    implements $MetadataSyncStateCopyWith<$Res> {
  factory $MetadataSyncSuccessCopyWith(
          MetadataSyncSuccess value, $Res Function(MetadataSyncSuccess) _then) =
      _$MetadataSyncSuccessCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$MetadataSyncSuccessCopyWithImpl<$Res>
    implements $MetadataSyncSuccessCopyWith<$Res> {
  _$MetadataSyncSuccessCopyWithImpl(this._self, this._then);

  final MetadataSyncSuccess _self;
  final $Res Function(MetadataSyncSuccess) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(MetadataSyncSuccess(
      null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class MetadataSyncFailure
    with DiagnosticableTreeMixin
    implements MetadataSyncState {
  const MetadataSyncFailure(this.error);

  final String error;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MetadataSyncFailureCopyWith<MetadataSyncFailure> get copyWith =>
      _$MetadataSyncFailureCopyWithImpl<MetadataSyncFailure>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(
          DiagnosticsProperty('type', 'MetadataSyncState.metadataSyncFailure'))
      ..add(DiagnosticsProperty('error', error));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MetadataSyncFailure &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.metadataSyncFailure(error: $error)';
  }
}

/// @nodoc
abstract mixin class $MetadataSyncFailureCopyWith<$Res>
    implements $MetadataSyncStateCopyWith<$Res> {
  factory $MetadataSyncFailureCopyWith(
          MetadataSyncFailure value, $Res Function(MetadataSyncFailure) _then) =
      _$MetadataSyncFailureCopyWithImpl;
  @useResult
  $Res call({String error});
}

/// @nodoc
class _$MetadataSyncFailureCopyWithImpl<$Res>
    implements $MetadataSyncFailureCopyWith<$Res> {
  _$MetadataSyncFailureCopyWithImpl(this._self, this._then);

  final MetadataSyncFailure _self;
  final $Res Function(MetadataSyncFailure) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? error = null,
  }) {
    return _then(MetadataSyncFailure(
      null == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class SavingPreset with DiagnosticableTreeMixin implements MetadataSyncState {
  const SavingPreset();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'MetadataSyncState.savingPreset'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SavingPreset);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.savingPreset()';
  }
}

/// @nodoc

class LoadingPreset with DiagnosticableTreeMixin implements MetadataSyncState {
  const LoadingPreset();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'MetadataSyncState.loadingPreset'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LoadingPreset);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.loadingPreset()';
  }
}

/// @nodoc

class PresetSaveSuccess
    with DiagnosticableTreeMixin
    implements MetadataSyncState {
  const PresetSaveSuccess(this.message);

  final String message;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PresetSaveSuccessCopyWith<PresetSaveSuccess> get copyWith =>
      _$PresetSaveSuccessCopyWithImpl<PresetSaveSuccess>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'MetadataSyncState.presetSaveSuccess'))
      ..add(DiagnosticsProperty('message', message));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PresetSaveSuccess &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.presetSaveSuccess(message: $message)';
  }
}

/// @nodoc
abstract mixin class $PresetSaveSuccessCopyWith<$Res>
    implements $MetadataSyncStateCopyWith<$Res> {
  factory $PresetSaveSuccessCopyWith(
          PresetSaveSuccess value, $Res Function(PresetSaveSuccess) _then) =
      _$PresetSaveSuccessCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$PresetSaveSuccessCopyWithImpl<$Res>
    implements $PresetSaveSuccessCopyWith<$Res> {
  _$PresetSaveSuccessCopyWithImpl(this._self, this._then);

  final PresetSaveSuccess _self;
  final $Res Function(PresetSaveSuccess) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(PresetSaveSuccess(
      null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class PresetSaveFailure
    with DiagnosticableTreeMixin
    implements MetadataSyncState {
  const PresetSaveFailure(this.error);

  final String error;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PresetSaveFailureCopyWith<PresetSaveFailure> get copyWith =>
      _$PresetSaveFailureCopyWithImpl<PresetSaveFailure>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'MetadataSyncState.presetSaveFailure'))
      ..add(DiagnosticsProperty('error', error));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PresetSaveFailure &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.presetSaveFailure(error: $error)';
  }
}

/// @nodoc
abstract mixin class $PresetSaveFailureCopyWith<$Res>
    implements $MetadataSyncStateCopyWith<$Res> {
  factory $PresetSaveFailureCopyWith(
          PresetSaveFailure value, $Res Function(PresetSaveFailure) _then) =
      _$PresetSaveFailureCopyWithImpl;
  @useResult
  $Res call({String error});
}

/// @nodoc
class _$PresetSaveFailureCopyWithImpl<$Res>
    implements $PresetSaveFailureCopyWith<$Res> {
  _$PresetSaveFailureCopyWithImpl(this._self, this._then);

  final PresetSaveFailure _self;
  final $Res Function(PresetSaveFailure) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? error = null,
  }) {
    return _then(PresetSaveFailure(
      null == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class PresetLoadSuccess
    with DiagnosticableTreeMixin
    implements MetadataSyncState {
  const PresetLoadSuccess(this.message);

  final String message;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PresetLoadSuccessCopyWith<PresetLoadSuccess> get copyWith =>
      _$PresetLoadSuccessCopyWithImpl<PresetLoadSuccess>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'MetadataSyncState.presetLoadSuccess'))
      ..add(DiagnosticsProperty('message', message));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PresetLoadSuccess &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.presetLoadSuccess(message: $message)';
  }
}

/// @nodoc
abstract mixin class $PresetLoadSuccessCopyWith<$Res>
    implements $MetadataSyncStateCopyWith<$Res> {
  factory $PresetLoadSuccessCopyWith(
          PresetLoadSuccess value, $Res Function(PresetLoadSuccess) _then) =
      _$PresetLoadSuccessCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$PresetLoadSuccessCopyWithImpl<$Res>
    implements $PresetLoadSuccessCopyWith<$Res> {
  _$PresetLoadSuccessCopyWithImpl(this._self, this._then);

  final PresetLoadSuccess _self;
  final $Res Function(PresetLoadSuccess) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(PresetLoadSuccess(
      null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class PresetLoadFailure
    with DiagnosticableTreeMixin
    implements MetadataSyncState {
  const PresetLoadFailure(this.error);

  final String error;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PresetLoadFailureCopyWith<PresetLoadFailure> get copyWith =>
      _$PresetLoadFailureCopyWithImpl<PresetLoadFailure>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'MetadataSyncState.presetLoadFailure'))
      ..add(DiagnosticsProperty('error', error));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PresetLoadFailure &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.presetLoadFailure(error: $error)';
  }
}

/// @nodoc
abstract mixin class $PresetLoadFailureCopyWith<$Res>
    implements $MetadataSyncStateCopyWith<$Res> {
  factory $PresetLoadFailureCopyWith(
          PresetLoadFailure value, $Res Function(PresetLoadFailure) _then) =
      _$PresetLoadFailureCopyWithImpl;
  @useResult
  $Res call({String error});
}

/// @nodoc
class _$PresetLoadFailureCopyWithImpl<$Res>
    implements $PresetLoadFailureCopyWith<$Res> {
  _$PresetLoadFailureCopyWithImpl(this._self, this._then);

  final PresetLoadFailure _self;
  final $Res Function(PresetLoadFailure) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? error = null,
  }) {
    return _then(PresetLoadFailure(
      null == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class DeletingPreset with DiagnosticableTreeMixin implements MetadataSyncState {
  const DeletingPreset();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'MetadataSyncState.deletingPreset'));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is DeletingPreset);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.deletingPreset()';
  }
}

/// @nodoc

class PresetDeleteSuccess
    with DiagnosticableTreeMixin
    implements MetadataSyncState {
  const PresetDeleteSuccess(this.message);

  final String message;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PresetDeleteSuccessCopyWith<PresetDeleteSuccess> get copyWith =>
      _$PresetDeleteSuccessCopyWithImpl<PresetDeleteSuccess>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(
          DiagnosticsProperty('type', 'MetadataSyncState.presetDeleteSuccess'))
      ..add(DiagnosticsProperty('message', message));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PresetDeleteSuccess &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.presetDeleteSuccess(message: $message)';
  }
}

/// @nodoc
abstract mixin class $PresetDeleteSuccessCopyWith<$Res>
    implements $MetadataSyncStateCopyWith<$Res> {
  factory $PresetDeleteSuccessCopyWith(
          PresetDeleteSuccess value, $Res Function(PresetDeleteSuccess) _then) =
      _$PresetDeleteSuccessCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$PresetDeleteSuccessCopyWithImpl<$Res>
    implements $PresetDeleteSuccessCopyWith<$Res> {
  _$PresetDeleteSuccessCopyWithImpl(this._self, this._then);

  final PresetDeleteSuccess _self;
  final $Res Function(PresetDeleteSuccess) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(PresetDeleteSuccess(
      null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class PresetDeleteFailure
    with DiagnosticableTreeMixin
    implements MetadataSyncState {
  const PresetDeleteFailure(this.error);

  final String error;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PresetDeleteFailureCopyWith<PresetDeleteFailure> get copyWith =>
      _$PresetDeleteFailureCopyWithImpl<PresetDeleteFailure>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(
          DiagnosticsProperty('type', 'MetadataSyncState.presetDeleteFailure'))
      ..add(DiagnosticsProperty('error', error));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PresetDeleteFailure &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.presetDeleteFailure(error: $error)';
  }
}

/// @nodoc
abstract mixin class $PresetDeleteFailureCopyWith<$Res>
    implements $MetadataSyncStateCopyWith<$Res> {
  factory $PresetDeleteFailureCopyWith(
          PresetDeleteFailure value, $Res Function(PresetDeleteFailure) _then) =
      _$PresetDeleteFailureCopyWithImpl;
  @useResult
  $Res call({String error});
}

/// @nodoc
class _$PresetDeleteFailureCopyWithImpl<$Res>
    implements $PresetDeleteFailureCopyWith<$Res> {
  _$PresetDeleteFailureCopyWithImpl(this._self, this._then);

  final PresetDeleteFailure _self;
  final $Res Function(PresetDeleteFailure) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? error = null,
  }) {
    return _then(PresetDeleteFailure(
      null == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class ViewingLocalData
    with DiagnosticableTreeMixin
    implements MetadataSyncState {
  const ViewingLocalData(
      {required final List<AlgorithmEntry> algorithms,
      required final Map<String, int> parameterCounts,
      required final List<PresetEntry> presets})
      : _algorithms = algorithms,
        _parameterCounts = parameterCounts,
        _presets = presets;

  final List<AlgorithmEntry> _algorithms;
  List<AlgorithmEntry> get algorithms {
    if (_algorithms is EqualUnmodifiableListView) return _algorithms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_algorithms);
  }

  final Map<String, int> _parameterCounts;
  Map<String, int> get parameterCounts {
    if (_parameterCounts is EqualUnmodifiableMapView) return _parameterCounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_parameterCounts);
  }

  final List<PresetEntry> _presets;
  List<PresetEntry> get presets {
    if (_presets is EqualUnmodifiableListView) return _presets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_presets);
  }

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ViewingLocalDataCopyWith<ViewingLocalData> get copyWith =>
      _$ViewingLocalDataCopyWithImpl<ViewingLocalData>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'MetadataSyncState.viewingLocalData'))
      ..add(DiagnosticsProperty('algorithms', algorithms))
      ..add(DiagnosticsProperty('parameterCounts', parameterCounts))
      ..add(DiagnosticsProperty('presets', presets));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ViewingLocalData &&
            const DeepCollectionEquality()
                .equals(other._algorithms, _algorithms) &&
            const DeepCollectionEquality()
                .equals(other._parameterCounts, _parameterCounts) &&
            const DeepCollectionEquality().equals(other._presets, _presets));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_algorithms),
      const DeepCollectionEquality().hash(_parameterCounts),
      const DeepCollectionEquality().hash(_presets));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.viewingLocalData(algorithms: $algorithms, parameterCounts: $parameterCounts, presets: $presets)';
  }
}

/// @nodoc
abstract mixin class $ViewingLocalDataCopyWith<$Res>
    implements $MetadataSyncStateCopyWith<$Res> {
  factory $ViewingLocalDataCopyWith(
          ViewingLocalData value, $Res Function(ViewingLocalData) _then) =
      _$ViewingLocalDataCopyWithImpl;
  @useResult
  $Res call(
      {List<AlgorithmEntry> algorithms,
      Map<String, int> parameterCounts,
      List<PresetEntry> presets});
}

/// @nodoc
class _$ViewingLocalDataCopyWithImpl<$Res>
    implements $ViewingLocalDataCopyWith<$Res> {
  _$ViewingLocalDataCopyWithImpl(this._self, this._then);

  final ViewingLocalData _self;
  final $Res Function(ViewingLocalData) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? algorithms = null,
    Object? parameterCounts = null,
    Object? presets = null,
  }) {
    return _then(ViewingLocalData(
      algorithms: null == algorithms
          ? _self._algorithms
          : algorithms // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmEntry>,
      parameterCounts: null == parameterCounts
          ? _self._parameterCounts
          : parameterCounts // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      presets: null == presets
          ? _self._presets
          : presets // ignore: cast_nullable_to_non_nullable
              as List<PresetEntry>,
    ));
  }
}

/// @nodoc

class Failure with DiagnosticableTreeMixin implements MetadataSyncState {
  const Failure(this.error);

  final String error;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FailureCopyWith<Failure> get copyWith =>
      _$FailureCopyWithImpl<Failure>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'MetadataSyncState.failure'))
      ..add(DiagnosticsProperty('error', error));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Failure &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MetadataSyncState.failure(error: $error)';
  }
}

/// @nodoc
abstract mixin class $FailureCopyWith<$Res>
    implements $MetadataSyncStateCopyWith<$Res> {
  factory $FailureCopyWith(Failure value, $Res Function(Failure) _then) =
      _$FailureCopyWithImpl;
  @useResult
  $Res call({String error});
}

/// @nodoc
class _$FailureCopyWithImpl<$Res> implements $FailureCopyWith<$Res> {
  _$FailureCopyWithImpl(this._self, this._then);

  final Failure _self;
  final $Res Function(Failure) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? error = null,
  }) {
    return _then(Failure(
      null == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
