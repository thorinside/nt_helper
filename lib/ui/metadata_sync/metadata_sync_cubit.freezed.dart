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
        syncing,
    required TResult Function(String message) success,
    required TResult Function(String error) failure,
    required TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)
        viewingData,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult? Function(String message)? success,
    TResult? Function(String error)? failure,
    TResult? Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult Function(String message)? success,
    TResult Function(String error)? failure,
    TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(Syncing value) syncing,
    required TResult Function(Success value) success,
    required TResult Function(Failure value) failure,
    required TResult Function(ViewingData value) viewingData,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Syncing value)? syncing,
    TResult? Function(Success value)? success,
    TResult? Function(Failure value)? failure,
    TResult? Function(ViewingData value)? viewingData,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Syncing value)? syncing,
    TResult Function(Success value)? success,
    TResult Function(Failure value)? failure,
    TResult Function(ViewingData value)? viewingData,
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
        syncing,
    required TResult Function(String message) success,
    required TResult Function(String error) failure,
    required TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)
        viewingData,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult? Function(String message)? success,
    TResult? Function(String error)? failure,
    TResult? Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult Function(String message)? success,
    TResult Function(String error)? failure,
    TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
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
    required TResult Function(Syncing value) syncing,
    required TResult Function(Success value) success,
    required TResult Function(Failure value) failure,
    required TResult Function(ViewingData value) viewingData,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Syncing value)? syncing,
    TResult? Function(Success value)? success,
    TResult? Function(Failure value)? failure,
    TResult? Function(ViewingData value)? viewingData,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Syncing value)? syncing,
    TResult Function(Success value)? success,
    TResult Function(Failure value)? failure,
    TResult Function(ViewingData value)? viewingData,
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
abstract class _$$SyncingImplCopyWith<$Res> {
  factory _$$SyncingImplCopyWith(
          _$SyncingImpl value, $Res Function(_$SyncingImpl) then) =
      __$$SyncingImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {double progress,
      String mainMessage,
      String subMessage,
      int? algorithmsProcessed,
      int? totalAlgorithms});
}

/// @nodoc
class __$$SyncingImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$SyncingImpl>
    implements _$$SyncingImplCopyWith<$Res> {
  __$$SyncingImplCopyWithImpl(
      _$SyncingImpl _value, $Res Function(_$SyncingImpl) _then)
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
    return _then(_$SyncingImpl(
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

class _$SyncingImpl implements Syncing {
  const _$SyncingImpl(
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
    return 'MetadataSyncState.syncing(progress: $progress, mainMessage: $mainMessage, subMessage: $subMessage, algorithmsProcessed: $algorithmsProcessed, totalAlgorithms: $totalAlgorithms)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncingImpl &&
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
  _$$SyncingImplCopyWith<_$SyncingImpl> get copyWith =>
      __$$SyncingImplCopyWithImpl<_$SyncingImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncing,
    required TResult Function(String message) success,
    required TResult Function(String error) failure,
    required TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)
        viewingData,
  }) {
    return syncing(progress, mainMessage, subMessage, algorithmsProcessed,
        totalAlgorithms);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult? Function(String message)? success,
    TResult? Function(String error)? failure,
    TResult? Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
  }) {
    return syncing?.call(progress, mainMessage, subMessage, algorithmsProcessed,
        totalAlgorithms);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult Function(String message)? success,
    TResult Function(String error)? failure,
    TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
    required TResult orElse(),
  }) {
    if (syncing != null) {
      return syncing(progress, mainMessage, subMessage, algorithmsProcessed,
          totalAlgorithms);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(Syncing value) syncing,
    required TResult Function(Success value) success,
    required TResult Function(Failure value) failure,
    required TResult Function(ViewingData value) viewingData,
  }) {
    return syncing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Syncing value)? syncing,
    TResult? Function(Success value)? success,
    TResult? Function(Failure value)? failure,
    TResult? Function(ViewingData value)? viewingData,
  }) {
    return syncing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Syncing value)? syncing,
    TResult Function(Success value)? success,
    TResult Function(Failure value)? failure,
    TResult Function(ViewingData value)? viewingData,
    required TResult orElse(),
  }) {
    if (syncing != null) {
      return syncing(this);
    }
    return orElse();
  }
}

abstract class Syncing implements MetadataSyncState {
  const factory Syncing(
      {required final double progress,
      required final String mainMessage,
      required final String subMessage,
      final int? algorithmsProcessed,
      final int? totalAlgorithms}) = _$SyncingImpl;

  double get progress; // 0.0 to 1.0
  String get mainMessage; // e.g., "Processing Algorithm X (15/128)"
  String get subMessage; // e.g., "Adding to preset..."
  int? get algorithmsProcessed; // Keep for progress calculation
  int? get totalAlgorithms;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncingImplCopyWith<_$SyncingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SuccessImplCopyWith<$Res> {
  factory _$$SuccessImplCopyWith(
          _$SuccessImpl value, $Res Function(_$SuccessImpl) then) =
      __$$SuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$SuccessImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$SuccessImpl>
    implements _$$SuccessImplCopyWith<$Res> {
  __$$SuccessImplCopyWithImpl(
      _$SuccessImpl _value, $Res Function(_$SuccessImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$SuccessImpl(
      null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SuccessImpl implements Success {
  const _$SuccessImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'MetadataSyncState.success(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SuccessImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SuccessImplCopyWith<_$SuccessImpl> get copyWith =>
      __$$SuccessImplCopyWithImpl<_$SuccessImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncing,
    required TResult Function(String message) success,
    required TResult Function(String error) failure,
    required TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)
        viewingData,
  }) {
    return success(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult? Function(String message)? success,
    TResult? Function(String error)? failure,
    TResult? Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
  }) {
    return success?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult Function(String message)? success,
    TResult Function(String error)? failure,
    TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(Syncing value) syncing,
    required TResult Function(Success value) success,
    required TResult Function(Failure value) failure,
    required TResult Function(ViewingData value) viewingData,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Syncing value)? syncing,
    TResult? Function(Success value)? success,
    TResult? Function(Failure value)? failure,
    TResult? Function(ViewingData value)? viewingData,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Syncing value)? syncing,
    TResult Function(Success value)? success,
    TResult Function(Failure value)? failure,
    TResult Function(ViewingData value)? viewingData,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class Success implements MetadataSyncState {
  const factory Success(final String message) = _$SuccessImpl;

  String get message;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SuccessImplCopyWith<_$SuccessImpl> get copyWith =>
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
        syncing,
    required TResult Function(String message) success,
    required TResult Function(String error) failure,
    required TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)
        viewingData,
  }) {
    return failure(error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult? Function(String message)? success,
    TResult? Function(String error)? failure,
    TResult? Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
  }) {
    return failure?.call(error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult Function(String message)? success,
    TResult Function(String error)? failure,
    TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
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
    required TResult Function(Syncing value) syncing,
    required TResult Function(Success value) success,
    required TResult Function(Failure value) failure,
    required TResult Function(ViewingData value) viewingData,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Syncing value)? syncing,
    TResult? Function(Success value)? success,
    TResult? Function(Failure value)? failure,
    TResult? Function(ViewingData value)? viewingData,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Syncing value)? syncing,
    TResult Function(Success value)? success,
    TResult Function(Failure value)? failure,
    TResult Function(ViewingData value)? viewingData,
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

/// @nodoc
abstract class _$$ViewingDataImplCopyWith<$Res> {
  factory _$$ViewingDataImplCopyWith(
          _$ViewingDataImpl value, $Res Function(_$ViewingDataImpl) then) =
      __$$ViewingDataImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts});
}

/// @nodoc
class __$$ViewingDataImplCopyWithImpl<$Res>
    extends _$MetadataSyncStateCopyWithImpl<$Res, _$ViewingDataImpl>
    implements _$$ViewingDataImplCopyWith<$Res> {
  __$$ViewingDataImplCopyWithImpl(
      _$ViewingDataImpl _value, $Res Function(_$ViewingDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? algorithms = null,
    Object? parameterCounts = null,
  }) {
    return _then(_$ViewingDataImpl(
      algorithms: null == algorithms
          ? _value._algorithms
          : algorithms // ignore: cast_nullable_to_non_nullable
              as List<AlgorithmEntry>,
      parameterCounts: null == parameterCounts
          ? _value._parameterCounts
          : parameterCounts // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ));
  }
}

/// @nodoc

class _$ViewingDataImpl implements ViewingData {
  const _$ViewingDataImpl(
      {required final List<AlgorithmEntry> algorithms,
      required final Map<String, int> parameterCounts})
      : _algorithms = algorithms,
        _parameterCounts = parameterCounts;

  final List<AlgorithmEntry> _algorithms;
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

  @override
  String toString() {
    return 'MetadataSyncState.viewingData(algorithms: $algorithms, parameterCounts: $parameterCounts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ViewingDataImpl &&
            const DeepCollectionEquality()
                .equals(other._algorithms, _algorithms) &&
            const DeepCollectionEquality()
                .equals(other._parameterCounts, _parameterCounts));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_algorithms),
      const DeepCollectionEquality().hash(_parameterCounts));

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ViewingDataImplCopyWith<_$ViewingDataImpl> get copyWith =>
      __$$ViewingDataImplCopyWithImpl<_$ViewingDataImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(double progress, String mainMessage,
            String subMessage, int? algorithmsProcessed, int? totalAlgorithms)
        syncing,
    required TResult Function(String message) success,
    required TResult Function(String error) failure,
    required TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)
        viewingData,
  }) {
    return viewingData(algorithms, parameterCounts);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult? Function(String message)? success,
    TResult? Function(String error)? failure,
    TResult? Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
  }) {
    return viewingData?.call(algorithms, parameterCounts);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(double progress, String mainMessage, String subMessage,
            int? algorithmsProcessed, int? totalAlgorithms)?
        syncing,
    TResult Function(String message)? success,
    TResult Function(String error)? failure,
    TResult Function(
            List<AlgorithmEntry> algorithms, Map<String, int> parameterCounts)?
        viewingData,
    required TResult orElse(),
  }) {
    if (viewingData != null) {
      return viewingData(algorithms, parameterCounts);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(Idle value) idle,
    required TResult Function(Syncing value) syncing,
    required TResult Function(Success value) success,
    required TResult Function(Failure value) failure,
    required TResult Function(ViewingData value) viewingData,
  }) {
    return viewingData(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(Idle value)? idle,
    TResult? Function(Syncing value)? syncing,
    TResult? Function(Success value)? success,
    TResult? Function(Failure value)? failure,
    TResult? Function(ViewingData value)? viewingData,
  }) {
    return viewingData?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(Idle value)? idle,
    TResult Function(Syncing value)? syncing,
    TResult Function(Success value)? success,
    TResult Function(Failure value)? failure,
    TResult Function(ViewingData value)? viewingData,
    required TResult orElse(),
  }) {
    if (viewingData != null) {
      return viewingData(this);
    }
    return orElse();
  }
}

abstract class ViewingData implements MetadataSyncState {
  const factory ViewingData(
      {required final List<AlgorithmEntry> algorithms,
      required final Map<String, int> parameterCounts}) = _$ViewingDataImpl;

  List<AlgorithmEntry> get algorithms;
  Map<String, int> get parameterCounts;

  /// Create a copy of MetadataSyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ViewingDataImplCopyWith<_$ViewingDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
