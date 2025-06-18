// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sd_card_scanner_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SdCardScannerState {
  ScanStatus get status;
  List<ScannedCardData> get scannedCards;
  double get scanProgress;
  int get filesProcessed;
  int get totalFiles;
  String get currentFile;
  String? get errorMessage;
  String? get successMessage;
  ScannedCardData? get newlyScannedCard;

  /// Create a copy of SdCardScannerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SdCardScannerStateCopyWith<SdCardScannerState> get copyWith =>
      _$SdCardScannerStateCopyWithImpl<SdCardScannerState>(
          this as SdCardScannerState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SdCardScannerState &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other.scannedCards, scannedCards) &&
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
      const DeepCollectionEquality().hash(scannedCards),
      scanProgress,
      filesProcessed,
      totalFiles,
      currentFile,
      errorMessage,
      successMessage,
      newlyScannedCard);

  @override
  String toString() {
    return 'SdCardScannerState(status: $status, scannedCards: $scannedCards, scanProgress: $scanProgress, filesProcessed: $filesProcessed, totalFiles: $totalFiles, currentFile: $currentFile, errorMessage: $errorMessage, successMessage: $successMessage, newlyScannedCard: $newlyScannedCard)';
  }
}

/// @nodoc
abstract mixin class $SdCardScannerStateCopyWith<$Res> {
  factory $SdCardScannerStateCopyWith(
          SdCardScannerState value, $Res Function(SdCardScannerState) _then) =
      _$SdCardScannerStateCopyWithImpl;
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
class _$SdCardScannerStateCopyWithImpl<$Res>
    implements $SdCardScannerStateCopyWith<$Res> {
  _$SdCardScannerStateCopyWithImpl(this._self, this._then);

  final SdCardScannerState _self;
  final $Res Function(SdCardScannerState) _then;

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
    return _then(_self.copyWith(
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ScanStatus,
      scannedCards: null == scannedCards
          ? _self.scannedCards
          : scannedCards // ignore: cast_nullable_to_non_nullable
              as List<ScannedCardData>,
      scanProgress: null == scanProgress
          ? _self.scanProgress
          : scanProgress // ignore: cast_nullable_to_non_nullable
              as double,
      filesProcessed: null == filesProcessed
          ? _self.filesProcessed
          : filesProcessed // ignore: cast_nullable_to_non_nullable
              as int,
      totalFiles: null == totalFiles
          ? _self.totalFiles
          : totalFiles // ignore: cast_nullable_to_non_nullable
              as int,
      currentFile: null == currentFile
          ? _self.currentFile
          : currentFile // ignore: cast_nullable_to_non_nullable
              as String,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      successMessage: freezed == successMessage
          ? _self.successMessage
          : successMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      newlyScannedCard: freezed == newlyScannedCard
          ? _self.newlyScannedCard
          : newlyScannedCard // ignore: cast_nullable_to_non_nullable
              as ScannedCardData?,
    ));
  }
}

/// @nodoc

class _SdCardScannerState implements SdCardScannerState {
  const _SdCardScannerState(
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

  /// Create a copy of SdCardScannerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SdCardScannerStateCopyWith<_SdCardScannerState> get copyWith =>
      __$SdCardScannerStateCopyWithImpl<_SdCardScannerState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SdCardScannerState &&
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

  @override
  String toString() {
    return 'SdCardScannerState(status: $status, scannedCards: $scannedCards, scanProgress: $scanProgress, filesProcessed: $filesProcessed, totalFiles: $totalFiles, currentFile: $currentFile, errorMessage: $errorMessage, successMessage: $successMessage, newlyScannedCard: $newlyScannedCard)';
  }
}

/// @nodoc
abstract mixin class _$SdCardScannerStateCopyWith<$Res>
    implements $SdCardScannerStateCopyWith<$Res> {
  factory _$SdCardScannerStateCopyWith(
          _SdCardScannerState value, $Res Function(_SdCardScannerState) _then) =
      __$SdCardScannerStateCopyWithImpl;
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
class __$SdCardScannerStateCopyWithImpl<$Res>
    implements _$SdCardScannerStateCopyWith<$Res> {
  __$SdCardScannerStateCopyWithImpl(this._self, this._then);

  final _SdCardScannerState _self;
  final $Res Function(_SdCardScannerState) _then;

  /// Create a copy of SdCardScannerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_SdCardScannerState(
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ScanStatus,
      scannedCards: null == scannedCards
          ? _self._scannedCards
          : scannedCards // ignore: cast_nullable_to_non_nullable
              as List<ScannedCardData>,
      scanProgress: null == scanProgress
          ? _self.scanProgress
          : scanProgress // ignore: cast_nullable_to_non_nullable
              as double,
      filesProcessed: null == filesProcessed
          ? _self.filesProcessed
          : filesProcessed // ignore: cast_nullable_to_non_nullable
              as int,
      totalFiles: null == totalFiles
          ? _self.totalFiles
          : totalFiles // ignore: cast_nullable_to_non_nullable
              as int,
      currentFile: null == currentFile
          ? _self.currentFile
          : currentFile // ignore: cast_nullable_to_non_nullable
              as String,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      successMessage: freezed == successMessage
          ? _self.successMessage
          : successMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      newlyScannedCard: freezed == newlyScannedCard
          ? _self.newlyScannedCard
          : newlyScannedCard // ignore: cast_nullable_to_non_nullable
              as ScannedCardData?,
    ));
  }
}

// dart format on
