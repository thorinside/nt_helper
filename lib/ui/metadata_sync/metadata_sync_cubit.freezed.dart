// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'metadata_sync_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MetadataSyncState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MetadataSyncStateCopyWith<$Res> {
  factory $MetadataSyncStateCopyWith(
          MetadataSyncState value, $Res Function(MetadataSyncState) then) =
      _$MetadataSyncStateCopyWithImpl<$Res, MetadataSyncState>;
}

/// @nodoc
class _$MetadataSyncStateCopyWithImpl<$Res, $Val extends MetadataSyncState>
    implements $MetadataSyncStateCopyWith<$Res> {
  _$MetadataSyncStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$IdleImplCopyWith<$Res> {
  factory _$$IdleImplCopyWith(
          _$IdleImpl value, $Res Function(_$IdleImpl) then) =
      __$$IdleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$IdleImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$IdleImpl>
    implements _$$IdleImplCopyWith<$Res> {
  __$$IdleImplCopyWithImpl(_$IdleImpl _value, $Res Function(_$IdleImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$IdleImpl implements Idle {
  const _$IdleImpl();

  @override
  String toString() {
    return 'MetadataSyncState.idle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$IdleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class Idle implements MetadataSyncState {
  const factory Idle() = _$IdleImpl;
}

/// @nodoc
abstract class _$$SyncingMetadataImplCopyWith<$Res> {
  factory _$$SyncingMetadataImplCopyWith(_$SyncingMetadataImpl value,
          $Res Function(_$SyncingMetadataImpl) then) =
      __$$SyncingMetadataImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {double progress,
      String mainMessage,
      String subMessage,
      int? algorithmsProcessed,
      int? totalAlgorithms});
}

/// @nodoc
class __$$SyncingMetadataImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$SyncingMetadataImpl>
    implements _$$SyncingMetadataImplCopyWith<$Res> {
  __$$SyncingMetadataImplCopyWithImpl(
      _$SyncingMetadataImpl _value, $Res Function(_$SyncingMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? progress = null,
    Object? mainMessage = null,
    Object? subMessage = null,
    Object? algorithmsProcessed = freezed,
    Object? totalAlgorithms = freezed,
  }) {
    return _then(_$SyncingMetadataImpl(
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      mainMessage: null == mainMessage
          ? _value.mainMessage
          : mainMessage // ignore: cast_nullable_to_non_nullable
              as String,
      subMessage: null == subMessage
          ? _value.subMessage
          : subMessage // ignore: cast_nullable_to_non_nullable
              as String,
      algorithmsProcessed: freezed == algorithmsProcessed
          ? _value.algorithmsProcessed
          : algorithmsProcessed // ignore: cast_nullable_to_non_nullable
              as int?,
      totalAlgorithms: freezed == totalAlgorithms
          ? _value.totalAlgorithms
          : totalAlgorithms // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$SyncingMetadataImpl implements SyncingMetadata {
  const _$SyncingMetadataImpl(
      {required this.progress,
      required this.mainMessage,
      required this.subMessage,
      this.algorithmsProcessed,
      this.totalAlgorithms});

  @override
  final double progress;
// 0.0 to 1.0
  @override
  final String mainMessage;
// e.g., "Processing Algorithm X (15/128)"
  @override
  final String subMessage;
// e.g., "Adding to preset..."
  @override
  final int? algorithmsProcessed;
// Keep for progress calculation
  @override
  final int? totalAlgorithms;

  @override
  String toString() {
    return 'MetadataSyncState.syncingMetadata(progress: $progress, mainMessage: $mainMessage, subMessage: $subMessage, algorithmsProcessed: $algorithmsProcessed, totalAlgorithms: $totalAlgorithms)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncingMetadataImpl &&
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

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncingMetadataImplCopyWith<_$SyncingMetadataImpl> get copyWith =>
      __$$SyncingMetadataImplCopyWithImpl<_$SyncingMetadataImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return syncingMetadata(progress, mainMessage, subMessage,
        algorithmsProcessed, totalAlgorithms);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return syncingMetadata?.call(progress, mainMessage, subMessage,
        algorithmsProcessed, totalAlgorithms);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (syncingMetadata != null) {
      return syncingMetadata(progress, mainMessage, subMessage,
          algorithmsProcessed, totalAlgorithms);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return syncingMetadata(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return syncingMetadata?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (syncingMetadata != null) {
      return syncingMetadata(this);
    }
    return orElse();
  }
}

abstract class SyncingMetadata implements MetadataSyncState {
  const factory SyncingMetadata(
      {required final double progress,
      required final String mainMessage,
      required final String subMessage,
      final int? algorithmsProcessed,
      final int? totalAlgorithms}) = _$SyncingMetadataImpl;

  double get progress; // 0.0 to 1.0
  String get mainMessage; // e.g., "Processing Algorithm X (15/128)"
  String get subMessage; // e.g., "Adding to preset..."
  int? get algorithmsProcessed; // Keep for progress calculation
  int? get totalAlgorithms;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncingMetadataImplCopyWith<_$SyncingMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MetadataSyncSuccessImplCopyWith<$Res> {
  factory _$$MetadataSyncSuccessImplCopyWith(_$MetadataSyncSuccessImpl value,
          $Res Function(_$MetadataSyncSuccessImpl) then) =
      __$$MetadataSyncSuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$MetadataSyncSuccessImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$MetadataSyncSuccessImpl>
    implements _$$MetadataSyncSuccessImplCopyWith<$Res> {
  __$$MetadataSyncSuccessImplCopyWithImpl(_$MetadataSyncSuccessImpl _value,
      $Res Function(_$MetadataSyncSuccessImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$MetadataSyncSuccessImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MetadataSyncSuccessImpl implements MetadataSyncSuccess {
  const _$MetadataSyncSuccessImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'MetadataSyncState.metadataSyncSuccess(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MetadataSyncSuccessImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MetadataSyncSuccessImplCopyWith<_$MetadataSyncSuccessImpl> get copyWith =>
      __$$MetadataSyncSuccessImplCopyWithImpl<_$MetadataSyncSuccessImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return metadataSyncSuccess(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return metadataSyncSuccess?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (metadataSyncSuccess != null) {
      return metadataSyncSuccess(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return metadataSyncSuccess(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return metadataSyncSuccess?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (metadataSyncSuccess != null) {
      return metadataSyncSuccess(this);
    }
    return orElse();
  }
}

abstract class MetadataSyncSuccess implements MetadataSyncState {
  const factory MetadataSyncSuccess(final String message) =
      _$MetadataSyncSuccessImpl;

  String get message;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MetadataSyncSuccessImplCopyWith<_$MetadataSyncSuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MetadataSyncFailureImplCopyWith<$Res> {
  factory _$$MetadataSyncFailureImplCopyWith(_$MetadataSyncFailureImpl value,
          $Res Function(_$MetadataSyncFailureImpl) then) =
      __$$MetadataSyncFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String error});
}

/// @nodoc
class __$$MetadataSyncFailureImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$MetadataSyncFailureImpl>
    implements _$$MetadataSyncFailureImplCopyWith<$Res> {
  __$$MetadataSyncFailureImplCopyWithImpl(_$MetadataSyncFailureImpl _value,
      $Res Function(_$MetadataSyncFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = null,
  }) {
    return _then(_$MetadataSyncFailureImpl(
      null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MetadataSyncFailureImpl implements MetadataSyncFailure {
  const _$MetadataSyncFailureImpl(this.error);

  @override
  final String error;

  @override
  String toString() {
    return 'MetadataSyncState.metadataSyncFailure(error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MetadataSyncFailureImpl &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MetadataSyncFailureImplCopyWith<_$MetadataSyncFailureImpl> get copyWith =>
      __$$MetadataSyncFailureImplCopyWithImpl<_$MetadataSyncFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return metadataSyncFailure(error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return metadataSyncFailure?.call(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (metadataSyncFailure != null) {
      return metadataSyncFailure(error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return metadataSyncFailure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return metadataSyncFailure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (metadataSyncFailure != null) {
      return metadataSyncFailure(this);
    }
    return orElse();
  }
}

abstract class MetadataSyncFailure implements MetadataSyncState {
  const factory MetadataSyncFailure(final String error) =
      _$MetadataSyncFailureImpl;

  String get error;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MetadataSyncFailureImplCopyWith<_$MetadataSyncFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SavingPresetImplCopyWith<$Res> {
  factory _$$SavingPresetImplCopyWith(
          _$SavingPresetImpl value, $Res Function(_$SavingPresetImpl) then) =
      __$$SavingPresetImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SavingPresetImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$SavingPresetImpl>
    implements _$$SavingPresetImplCopyWith<$Res> {
  __$$SavingPresetImplCopyWithImpl(
      _$SavingPresetImpl _value, $Res Function(_$SavingPresetImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SavingPresetImpl implements SavingPreset {
  const _$SavingPresetImpl();

  @override
  String toString() {
    return 'MetadataSyncState.savingPreset()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SavingPresetImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return savingPreset();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return savingPreset?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (savingPreset != null) {
      return savingPreset();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return savingPreset(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return savingPreset?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (savingPreset != null) {
      return savingPreset(this);
    }
    return orElse();
  }
}

abstract class SavingPreset implements MetadataSyncState {
  const factory SavingPreset() = _$SavingPresetImpl;
}

/// @nodoc
abstract class _$$LoadingPresetImplCopyWith<$Res> {
  factory _$$LoadingPresetImplCopyWith(
          _$LoadingPresetImpl value, $Res Function(_$LoadingPresetImpl) then) =
      __$$LoadingPresetImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingPresetImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$LoadingPresetImpl>
    implements _$$LoadingPresetImplCopyWith<$Res> {
  __$$LoadingPresetImplCopyWithImpl(
      _$LoadingPresetImpl _value, $Res Function(_$LoadingPresetImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingPresetImpl implements LoadingPreset {
  const _$LoadingPresetImpl();

  @override
  String toString() {
    return 'MetadataSyncState.loadingPreset()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingPresetImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return loadingPreset();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return loadingPreset?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (loadingPreset != null) {
      return loadingPreset();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return loadingPreset(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return loadingPreset?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (loadingPreset != null) {
      return loadingPreset(this);
    }
    return orElse();
  }
}

abstract class LoadingPreset implements MetadataSyncState {
  const factory LoadingPreset() = _$LoadingPresetImpl;
}

/// @nodoc
abstract class _$$PresetSaveSuccessImplCopyWith<$Res> {
  factory _$$PresetSaveSuccessImplCopyWith(_$PresetSaveSuccessImpl value,
          $Res Function(_$PresetSaveSuccessImpl) then) =
      __$$PresetSaveSuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$PresetSaveSuccessImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$PresetSaveSuccessImpl>
    implements _$$PresetSaveSuccessImplCopyWith<$Res> {
  __$$PresetSaveSuccessImplCopyWithImpl(_$PresetSaveSuccessImpl _value,
      $Res Function(_$PresetSaveSuccessImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$PresetSaveSuccessImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PresetSaveSuccessImpl implements PresetSaveSuccess {
  const _$PresetSaveSuccessImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'MetadataSyncState.presetSaveSuccess(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PresetSaveSuccessImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PresetSaveSuccessImplCopyWith<_$PresetSaveSuccessImpl> get copyWith =>
      __$$PresetSaveSuccessImplCopyWithImpl<_$PresetSaveSuccessImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return presetSaveSuccess(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return presetSaveSuccess?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (presetSaveSuccess != null) {
      return presetSaveSuccess(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return presetSaveSuccess(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return presetSaveSuccess?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (presetSaveSuccess != null) {
      return presetSaveSuccess(this);
    }
    return orElse();
  }
}

abstract class PresetSaveSuccess implements MetadataSyncState {
  const factory PresetSaveSuccess(final String message) =
      _$PresetSaveSuccessImpl;

  String get message;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PresetSaveSuccessImplCopyWith<_$PresetSaveSuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PresetSaveFailureImplCopyWith<$Res> {
  factory _$$PresetSaveFailureImplCopyWith(_$PresetSaveFailureImpl value,
          $Res Function(_$PresetSaveFailureImpl) then) =
      __$$PresetSaveFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String error});
}

/// @nodoc
class __$$PresetSaveFailureImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$PresetSaveFailureImpl>
    implements _$$PresetSaveFailureImplCopyWith<$Res> {
  __$$PresetSaveFailureImplCopyWithImpl(_$PresetSaveFailureImpl _value,
      $Res Function(_$PresetSaveFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = null,
  }) {
    return _then(_$PresetSaveFailureImpl(
      null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PresetSaveFailureImpl implements PresetSaveFailure {
  const _$PresetSaveFailureImpl(this.error);

  @override
  final String error;

  @override
  String toString() {
    return 'MetadataSyncState.presetSaveFailure(error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PresetSaveFailureImpl &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PresetSaveFailureImplCopyWith<_$PresetSaveFailureImpl> get copyWith =>
      __$$PresetSaveFailureImplCopyWithImpl<_$PresetSaveFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return presetSaveFailure(error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return presetSaveFailure?.call(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (presetSaveFailure != null) {
      return presetSaveFailure(error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return presetSaveFailure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return presetSaveFailure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (presetSaveFailure != null) {
      return presetSaveFailure(this);
    }
    return orElse();
  }
}

abstract class PresetSaveFailure implements MetadataSyncState {
  const factory PresetSaveFailure(final String error) = _$PresetSaveFailureImpl;

  String get error;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PresetSaveFailureImplCopyWith<_$PresetSaveFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PresetLoadSuccessImplCopyWith<$Res> {
  factory _$$PresetLoadSuccessImplCopyWith(_$PresetLoadSuccessImpl value,
          $Res Function(_$PresetLoadSuccessImpl) then) =
      __$$PresetLoadSuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$PresetLoadSuccessImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$PresetLoadSuccessImpl>
    implements _$$PresetLoadSuccessImplCopyWith<$Res> {
  __$$PresetLoadSuccessImplCopyWithImpl(_$PresetLoadSuccessImpl _value,
      $Res Function(_$PresetLoadSuccessImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$PresetLoadSuccessImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PresetLoadSuccessImpl implements PresetLoadSuccess {
  const _$PresetLoadSuccessImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'MetadataSyncState.presetLoadSuccess(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PresetLoadSuccessImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PresetLoadSuccessImplCopyWith<_$PresetLoadSuccessImpl> get copyWith =>
      __$$PresetLoadSuccessImplCopyWithImpl<_$PresetLoadSuccessImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return presetLoadSuccess(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return presetLoadSuccess?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (presetLoadSuccess != null) {
      return presetLoadSuccess(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return presetLoadSuccess(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return presetLoadSuccess?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (presetLoadSuccess != null) {
      return presetLoadSuccess(this);
    }
    return orElse();
  }
}

abstract class PresetLoadSuccess implements MetadataSyncState {
  const factory PresetLoadSuccess(final String message) =
      _$PresetLoadSuccessImpl;

  String get message;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PresetLoadSuccessImplCopyWith<_$PresetLoadSuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PresetLoadFailureImplCopyWith<$Res> {
  factory _$$PresetLoadFailureImplCopyWith(_$PresetLoadFailureImpl value,
          $Res Function(_$PresetLoadFailureImpl) then) =
      __$$PresetLoadFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String error});
}

/// @nodoc
class __$$PresetLoadFailureImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$PresetLoadFailureImpl>
    implements _$$PresetLoadFailureImplCopyWith<$Res> {
  __$$PresetLoadFailureImplCopyWithImpl(_$PresetLoadFailureImpl _value,
      $Res Function(_$PresetLoadFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = null,
  }) {
    return _then(_$PresetLoadFailureImpl(
      null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PresetLoadFailureImpl implements PresetLoadFailure {
  const _$PresetLoadFailureImpl(this.error);

  @override
  final String error;

  @override
  String toString() {
    return 'MetadataSyncState.presetLoadFailure(error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PresetLoadFailureImpl &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PresetLoadFailureImplCopyWith<_$PresetLoadFailureImpl> get copyWith =>
      __$$PresetLoadFailureImplCopyWithImpl<_$PresetLoadFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return presetLoadFailure(error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return presetLoadFailure?.call(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (presetLoadFailure != null) {
      return presetLoadFailure(error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return presetLoadFailure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return presetLoadFailure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (presetLoadFailure != null) {
      return presetLoadFailure(this);
    }
    return orElse();
  }
}

abstract class PresetLoadFailure implements MetadataSyncState {
  const factory PresetLoadFailure(final String error) = _$PresetLoadFailureImpl;

  String get error;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PresetLoadFailureImplCopyWith<_$PresetLoadFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ViewingLocalDataImplCopyWith<$Res> {
  factory _$$ViewingLocalDataImplCopyWith(_$ViewingLocalDataImpl value,
          $Res Function(_$ViewingLocalDataImpl) then) =
      __$$ViewingLocalDataImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {List<AlgorithmEntry> algorithms,
      Map<String, int> parameterCounts,
      List<PresetEntry> presets});
}

/// @nodoc
class __$$ViewingLocalDataImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$ViewingLocalDataImpl>
    implements _$$ViewingLocalDataImplCopyWith<$Res> {
  __$$ViewingLocalDataImplCopyWithImpl(_$ViewingLocalDataImpl _value,
      $Res Function(_$ViewingLocalDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? algorithms = null,
    Object? parameterCounts = null,
    Object? presets = null,
  }) {
    return _then(_$ViewingLocalDataImpl(
      algorithms: null == algorithms
          ? _value._algorithms
          : algorithms // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmEntry>,
      parameterCounts: null == parameterCounts
          ? _value._parameterCounts
          : parameterCounts // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      presets: null == presets
          ? _value._presets
          : presets // ignore: cast_nullable_to_non_nullable
              as List<PresetEntry>,
    ));
  }
}

/// @nodoc

class _$ViewingLocalDataImpl implements ViewingLocalData {
  const _$ViewingLocalDataImpl(
      {required final List<AlgorithmEntry> algorithms,
      required final Map<String, int> parameterCounts,
      required final List<PresetEntry> presets})
      : _algorithms = algorithms,
        _parameterCounts = parameterCounts,
        _presets = presets;

// Include both for potential future use or segmented view
  final List<AlgorithmEntry> _algorithms;
// Include both for potential future use or segmented view
  @override
  List<AlgorithmEntry> get algorithms {
    if (_algorithms is EqualUnmodifiableListView) return _algorithms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_algorithms);
  }

  final Map<String, int> _parameterCounts;
  @override
  Map<String, int> get parameterCounts {
    if (_parameterCounts is EqualUnmodifiableMapView) return _parameterCounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_parameterCounts);
  }

  final List<PresetEntry> _presets;
  @override
  List<PresetEntry> get presets {
    if (_presets is EqualUnmodifiableListView) return _presets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_presets);
  }

  @override
  String toString() {
    return 'MetadataSyncState.viewingLocalData(algorithms: $algorithms, parameterCounts: $parameterCounts, presets: $presets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ViewingLocalDataImpl &&
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

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ViewingLocalDataImplCopyWith<_$ViewingLocalDataImpl> get copyWith =>
      __$$ViewingLocalDataImplCopyWithImpl<_$ViewingLocalDataImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return viewingLocalData(algorithms, parameterCounts, presets);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return viewingLocalData?.call(algorithms, parameterCounts, presets);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (viewingLocalData != null) {
      return viewingLocalData(algorithms, parameterCounts, presets);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return viewingLocalData(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return viewingLocalData?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (viewingLocalData != null) {
      return viewingLocalData(this);
    }
    return orElse();
  }
}

abstract class ViewingLocalData implements MetadataSyncState {
  const factory ViewingLocalData(
      {required final List<AlgorithmEntry> algorithms,
      required final Map<String, int> parameterCounts,
      required final List<PresetEntry> presets}) = _$ViewingLocalDataImpl;

// Include both for potential future use or segmented view
  List<AlgorithmEntry> get algorithms;
  Map<String, int> get parameterCounts;
  List<PresetEntry> get presets;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ViewingLocalDataImplCopyWith<_$ViewingLocalDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FailureImplCopyWith<$Res> {
  factory _$$FailureImplCopyWith(
          _$FailureImpl value, $Res Function(_$FailureImpl) then) =
      __$$FailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String error});
}

/// @nodoc
class __$$FailureImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$FailureImpl>
    implements _$$FailureImplCopyWith<$Res> {
  __$$FailureImplCopyWithImpl(
      _$FailureImpl _value, $Res Function(_$FailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? error = null,
  }) {
    return _then(_$FailureImpl(
      null == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$FailureImpl implements Failure {
  const _$FailureImpl(this.error);

  @override
  final String error;

  @override
  String toString() {
    return 'MetadataSyncState.failure(error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FailureImpl &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FailureImplCopyWith<_$FailureImpl> get copyWith =>
      __$$FailureImplCopyWithImpl<_$FailureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncingMetadata,
    required TResult Function(String message) metadataSyncSuccess,
    required TResult Function(String error) metadataSyncFailure,
    required TResult Function() savingPreset,
    required TResult Function() loadingPreset,
    required TResult Function(String message) presetSaveSuccess,
    required TResult Function(String error) presetSaveFailure,
    required TResult Function(String message) presetLoadSuccess,
    required TResult Function(String error) presetLoadFailure,
    required TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)
        viewingLocalData,
    required TResult Function(String error) failure,
  }) {
    return failure(error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult? Function(String message)? metadataSyncSuccess,
    TResult? Function(String error)? metadataSyncFailure,
    TResult? Function()? savingPreset,
    TResult? Function()? loadingPreset,
    TResult? Function(String message)? presetSaveSuccess,
    TResult? Function(String error)? presetSaveFailure,
    TResult? Function(String message)? presetLoadSuccess,
    TResult? Function(String error)? presetLoadFailure,
    TResult? Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult? Function(String error)? failure,
  }) {
    return failure?.call(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncingMetadata,
    TResult Function(String message)? metadataSyncSuccess,
    TResult Function(String error)? metadataSyncFailure,
    TResult Function()? savingPreset,
    TResult Function()? loadingPreset,
    TResult Function(String message)? presetSaveSuccess,
    TResult Function(String error)? presetSaveFailure,
    TResult Function(String message)? presetLoadSuccess,
    TResult Function(String error)? presetLoadFailure,
    TResult Function(List<AlgorithmEntry> algorithms,
            Map<String, int> parameterCounts, List<PresetEntry> presets)?
        viewingLocalData,
    TResult Function(String error)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(SyncingMetadata value) syncingMetadata,
    required TResult Function(MetadataSyncSuccess value) metadataSyncSuccess,
    required TResult Function(MetadataSyncFailure value) metadataSyncFailure,
    required TResult Function(SavingPreset value) savingPreset,
    required TResult Function(LoadingPreset value) loadingPreset,
    required TResult Function(PresetSaveSuccess value) presetSaveSuccess,
    required TResult Function(PresetSaveFailure value) presetSaveFailure,
    required TResult Function(PresetLoadSuccess value) presetLoadSuccess,
    required TResult Function(PresetLoadFailure value) presetLoadFailure,
    required TResult Function(ViewingLocalData value) viewingLocalData,
    required TResult Function(Failure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(SyncingMetadata value)? syncingMetadata,
    TResult? Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult? Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult? Function(SavingPreset value)? savingPreset,
    TResult? Function(LoadingPreset value)? loadingPreset,
    TResult? Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult? Function(PresetSaveFailure value)? presetSaveFailure,
    TResult? Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult? Function(PresetLoadFailure value)? presetLoadFailure,
    TResult? Function(ViewingLocalData value)? viewingLocalData,
    TResult? Function(Failure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(SyncingMetadata value)? syncingMetadata,
    TResult Function(MetadataSyncSuccess value)? metadataSyncSuccess,
    TResult Function(MetadataSyncFailure value)? metadataSyncFailure,
    TResult Function(SavingPreset value)? savingPreset,
    TResult Function(LoadingPreset value)? loadingPreset,
    TResult Function(PresetSaveSuccess value)? presetSaveSuccess,
    TResult Function(PresetSaveFailure value)? presetSaveFailure,
    TResult Function(PresetLoadSuccess value)? presetLoadSuccess,
    TResult Function(PresetLoadFailure value)? presetLoadFailure,
    TResult Function(ViewingLocalData value)? viewingLocalData,
    TResult Function(Failure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class Failure implements MetadataSyncState {
  const factory Failure(final String error) = _$FailureImpl;

  String get error;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FailureImplCopyWith<_$FailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
