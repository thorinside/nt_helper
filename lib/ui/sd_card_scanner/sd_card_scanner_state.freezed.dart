// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sd_card_scanner_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SdCardScannerState {
  ScanStatus get status => throw _privateConstructorUsedError;
  List<ScannedCardData> get scannedCards => throw _privateConstructorUsedError;
  double get scanProgress => throw _privateConstructorUsedError;
  int get filesProcessed => throw _privateConstructorUsedError;
  int get totalFiles => throw _privateConstructorUsedError;
  String get currentFile => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  String? get successMessage => throw _privateConstructorUsedError;
  ScannedCardData? get newlyScannedCard => throw _privateConstructorUsedError;

  /// Create a copy of SdCardScannerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SdCardScannerStateCopyWith<SdCardScannerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SdCardScannerStateCopyWith<$Res> {
  factory $SdCardScannerStateCopyWith(
          SdCardScannerState value, $Res Function(SdCardScannerState) then) =
      _$SdCardScannerStateCopyWithImpl<$Res, SdCardScannerState>;
  @useResult
  $Res call(
      {ScanStatus status,
      List<ScannedCardData> scannedCards,
      double scanProgress,
      int filesProcessed,
      int totalFiles,
      String currentFile,
      String? errorMessage,
      String? successMessage,
      ScannedCardData? newlyScannedCard});
}

/// @nodoc
class _$SdCardScannerStateCopyWithImpl<$Res, $Val extends SdCardScannerState>
    implements $SdCardScannerStateCopyWith<$Res> {
  _$SdCardScannerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SdCardScannerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? scannedCards = null,
    Object? scanProgress = null,
    Object? filesProcessed = null,
    Object? totalFiles = null,
    Object? currentFile = null,
    Object? errorMessage = freezed,
    Object? successMessage = freezed,
    Object? newlyScannedCard = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ScanStatus,
      scannedCards: null == scannedCards
          ? _value.scannedCards
          : scannedCards // ignore: cast_nullable_to_non_nullable
              as List<ScannedCardData>,
      scanProgress: null == scanProgress
          ? _value.scanProgress
          : scanProgress // ignore: cast_nullable_to_non_nullable
              as double,
      filesProcessed: null == filesProcessed
          ? _value.filesProcessed
          : filesProcessed // ignore: cast_nullable_to_non_nullable
              as int,
      totalFiles: null == totalFiles
          ? _value.totalFiles
          : totalFiles // ignore: cast_nullable_to_non_nullable
              as int,
      currentFile: null == currentFile
          ? _value.currentFile
          : currentFile // ignore: cast_nullable_to_non_nullable
              as String,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      successMessage: freezed == successMessage
          ? _value.successMessage
          : successMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      newlyScannedCard: freezed == newlyScannedCard
          ? _value.newlyScannedCard
          : newlyScannedCard // ignore: cast_nullable_to_non_nullable
              as ScannedCardData?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SdCardScannerStateImplCopyWith<$Res>
    implements $SdCardScannerStateCopyWith<$Res> {
  factory _$$SdCardScannerStateImplCopyWith(_$SdCardScannerStateImpl value,
          $Res Function(_$SdCardScannerStateImpl) then) =
      __$$SdCardScannerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ScanStatus status,
      List<ScannedCardData> scannedCards,
      double scanProgress,
      int filesProcessed,
      int totalFiles,
      String currentFile,
      String? errorMessage,
      String? successMessage,
      ScannedCardData? newlyScannedCard});
}

/// @nodoc
class __$$SdCardScannerStateImplCopyWithImpl<$Res>
    extends _$SdCardScannerStateCopyWithImpl<$Res, _$SdCardScannerStateImpl>
    implements _$$SdCardScannerStateImplCopyWith<$Res> {
  __$$SdCardScannerStateImplCopyWithImpl(_$SdCardScannerStateImpl _value,
      $Res Function(_$SdCardScannerStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdCardScannerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? scannedCards = null,
    Object? scanProgress = null,
    Object? filesProcessed = null,
    Object? totalFiles = null,
    Object? currentFile = null,
    Object? errorMessage = freezed,
    Object? successMessage = freezed,
    Object? newlyScannedCard = freezed,
  }) {
    return _then(_$SdCardScannerStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ScanStatus,
      scannedCards: null == scannedCards
          ? _value._scannedCards
          : scannedCards // ignore: cast_nullable_to_non_nullable
              as List<ScannedCardData>,
      scanProgress: null == scanProgress
          ? _value.scanProgress
          : scanProgress // ignore: cast_nullable_to_non_nullable
              as double,
      filesProcessed: null == filesProcessed
          ? _value.filesProcessed
          : filesProcessed // ignore: cast_nullable_to_non_nullable
              as int,
      totalFiles: null == totalFiles
          ? _value.totalFiles
          : totalFiles // ignore: cast_nullable_to_non_nullable
              as int,
      currentFile: null == currentFile
          ? _value.currentFile
          : currentFile // ignore: cast_nullable_to_non_nullable
              as String,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      successMessage: freezed == successMessage
          ? _value.successMessage
          : successMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      newlyScannedCard: freezed == newlyScannedCard
          ? _value.newlyScannedCard
          : newlyScannedCard // ignore: cast_nullable_to_non_nullable
              as ScannedCardData?,
    ));
  }
}

/// @nodoc

class _$SdCardScannerStateImpl implements _SdCardScannerState {
  const _$SdCardScannerStateImpl(
      {this.status = ScanStatus.initial,
      final List<ScannedCardData> scannedCards = const [],
      this.scanProgress = 0.0,
      this.filesProcessed = 0,
      this.totalFiles = 0,
      this.currentFile = '',
      this.errorMessage,
      this.successMessage,
      this.newlyScannedCard})
      : _scannedCards = scannedCards;

  @override
  @JsonKey()
  final ScanStatus status;
  final List<ScannedCardData> _scannedCards;
  @override
  @JsonKey()
  List<ScannedCardData> get scannedCards {
    if (_scannedCards is EqualUnmodifiableListView) return _scannedCards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_scannedCards);
  }

  @override
  @JsonKey()
  final double scanProgress;
  @override
  @JsonKey()
  final int filesProcessed;
  @override
  @JsonKey()
  final int totalFiles;
  @override
  @JsonKey()
  final String currentFile;
  @override
  final String? errorMessage;
  @override
  final String? successMessage;
  @override
  final ScannedCardData? newlyScannedCard;

  @override
  String toString() {
    return 'SdCardScannerState(status: $status, scannedCards: $scannedCards, scanProgress: $scanProgress, filesProcessed: $filesProcessed, totalFiles: $totalFiles, currentFile: $currentFile, errorMessage: $errorMessage, successMessage: $successMessage, newlyScannedCard: $newlyScannedCard)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SdCardScannerStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other._scannedCards, _scannedCards) &&
            (identical(other.scanProgress, scanProgress) ||
                other.scanProgress == scanProgress) &&
            (identical(other.filesProcessed, filesProcessed) ||
                other.filesProcessed == filesProcessed) &&
            (identical(other.totalFiles, totalFiles) ||
                other.totalFiles == totalFiles) &&
            (identical(other.currentFile, currentFile) ||
                other.currentFile == currentFile) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.successMessage, successMessage) ||
                other.successMessage == successMessage) &&
            (identical(other.newlyScannedCard, newlyScannedCard) ||
                other.newlyScannedCard == newlyScannedCard));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      status,
      const DeepCollectionEquality().hash(_scannedCards),
      scanProgress,
      filesProcessed,
      totalFiles,
      currentFile,
      errorMessage,
      successMessage,
      newlyScannedCard);

  /// Create a copy of SdCardScannerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SdCardScannerStateImplCopyWith<_$SdCardScannerStateImpl> get copyWith =>
      __$$SdCardScannerStateImplCopyWithImpl<_$SdCardScannerStateImpl>(
          this, _$identity);
}

abstract class _SdCardScannerState implements SdCardScannerState {
  const factory _SdCardScannerState(
      {final ScanStatus status,
      final List<ScannedCardData> scannedCards,
      final double scanProgress,
      final int filesProcessed,
      final int totalFiles,
      final String currentFile,
      final String? errorMessage,
      final String? successMessage,
      final ScannedCardData? newlyScannedCard}) = _$SdCardScannerStateImpl;

  @override
  ScanStatus get status;
  @override
  List<ScannedCardData> get scannedCards;
  @override
  double get scanProgress;
  @override
  int get filesProcessed;
  @override
  int get totalFiles;
  @override
  String get currentFile;
  @override
  String? get errorMessage;
  @override
  String? get successMessage;
  @override
  ScannedCardData? get newlyScannedCard;

  /// Create a copy of SdCardScannerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SdCardScannerStateImplCopyWith<_$SdCardScannerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
