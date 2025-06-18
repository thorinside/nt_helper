// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sd_card_scanner_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SdCardScannerEvent {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SdCardScannerEvent);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SdCardScannerEvent()';
  }
}

/// @nodoc
class $SdCardScannerEventCopyWith<$Res> {
  $SdCardScannerEventCopyWith(
      SdCardScannerEvent _, $Res Function(SdCardScannerEvent) __);
}

/// @nodoc

class LoadScannedCards implements SdCardScannerEvent {
  const LoadScannedCards();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is LoadScannedCards);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SdCardScannerEvent.loadScannedCards()';
  }
}

/// @nodoc

class ScanRequested implements SdCardScannerEvent {
  const ScanRequested(
      {required this.sdCardRootPathOrUri,
      required this.relativePresetsPath,
      required this.cardName});

  final String sdCardRootPathOrUri;
  final String relativePresetsPath;
  final String cardName;

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScanRequestedCopyWith<ScanRequested> get copyWith =>
      _$ScanRequestedCopyWithImpl<ScanRequested>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScanRequested &&
            (identical(other.sdCardRootPathOrUri, sdCardRootPathOrUri) ||
                other.sdCardRootPathOrUri == sdCardRootPathOrUri) &&
            (identical(other.relativePresetsPath, relativePresetsPath) ||
                other.relativePresetsPath == relativePresetsPath) &&
            (identical(other.cardName, cardName) ||
                other.cardName == cardName));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, sdCardRootPathOrUri, relativePresetsPath, cardName);

  @override
  String toString() {
    return 'SdCardScannerEvent.scanRequested(sdCardRootPathOrUri: $sdCardRootPathOrUri, relativePresetsPath: $relativePresetsPath, cardName: $cardName)';
  }
}

/// @nodoc
abstract mixin class $ScanRequestedCopyWith<$Res>
    implements $SdCardScannerEventCopyWith<$Res> {
  factory $ScanRequestedCopyWith(
          ScanRequested value, $Res Function(ScanRequested) _then) =
      _$ScanRequestedCopyWithImpl;
  @useResult
  $Res call(
      {String sdCardRootPathOrUri,
      String relativePresetsPath,
      String cardName});
}

/// @nodoc
class _$ScanRequestedCopyWithImpl<$Res>
    implements $ScanRequestedCopyWith<$Res> {
  _$ScanRequestedCopyWithImpl(this._self, this._then);

  final ScanRequested _self;
  final $Res Function(ScanRequested) _then;

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? sdCardRootPathOrUri = null,
    Object? relativePresetsPath = null,
    Object? cardName = null,
  }) {
    return _then(ScanRequested(
      sdCardRootPathOrUri: null == sdCardRootPathOrUri
          ? _self.sdCardRootPathOrUri
          : sdCardRootPathOrUri // ignore: cast_nullable_to_non_nullable
              as String,
      relativePresetsPath: null == relativePresetsPath
          ? _self.relativePresetsPath
          : relativePresetsPath // ignore: cast_nullable_to_non_nullable
              as String,
      cardName: null == cardName
          ? _self.cardName
          : cardName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class RescanCardRequested implements SdCardScannerEvent {
  const RescanCardRequested(
      {required this.cardIdPath,
      required this.relativePresetsPath,
      required this.cardName});

  final String cardIdPath;
  final String relativePresetsPath;
  final String cardName;

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RescanCardRequestedCopyWith<RescanCardRequested> get copyWith =>
      _$RescanCardRequestedCopyWithImpl<RescanCardRequested>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RescanCardRequested &&
            (identical(other.cardIdPath, cardIdPath) ||
                other.cardIdPath == cardIdPath) &&
            (identical(other.relativePresetsPath, relativePresetsPath) ||
                other.relativePresetsPath == relativePresetsPath) &&
            (identical(other.cardName, cardName) ||
                other.cardName == cardName));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, cardIdPath, relativePresetsPath, cardName);

  @override
  String toString() {
    return 'SdCardScannerEvent.rescanCardRequested(cardIdPath: $cardIdPath, relativePresetsPath: $relativePresetsPath, cardName: $cardName)';
  }
}

/// @nodoc
abstract mixin class $RescanCardRequestedCopyWith<$Res>
    implements $SdCardScannerEventCopyWith<$Res> {
  factory $RescanCardRequestedCopyWith(
          RescanCardRequested value, $Res Function(RescanCardRequested) _then) =
      _$RescanCardRequestedCopyWithImpl;
  @useResult
  $Res call({String cardIdPath, String relativePresetsPath, String cardName});
}

/// @nodoc
class _$RescanCardRequestedCopyWithImpl<$Res>
    implements $RescanCardRequestedCopyWith<$Res> {
  _$RescanCardRequestedCopyWithImpl(this._self, this._then);

  final RescanCardRequested _self;
  final $Res Function(RescanCardRequested) _then;

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? cardIdPath = null,
    Object? relativePresetsPath = null,
    Object? cardName = null,
  }) {
    return _then(RescanCardRequested(
      cardIdPath: null == cardIdPath
          ? _self.cardIdPath
          : cardIdPath // ignore: cast_nullable_to_non_nullable
              as String,
      relativePresetsPath: null == relativePresetsPath
          ? _self.relativePresetsPath
          : relativePresetsPath // ignore: cast_nullable_to_non_nullable
              as String,
      cardName: null == cardName
          ? _self.cardName
          : cardName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class ScanCancelled implements SdCardScannerEvent {
  const ScanCancelled();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ScanCancelled);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SdCardScannerEvent.scanCancelled()';
  }
}

/// @nodoc

class RemoveCardRequested implements SdCardScannerEvent {
  const RemoveCardRequested({required this.cardIdPath});

  final String cardIdPath;

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RemoveCardRequestedCopyWith<RemoveCardRequested> get copyWith =>
      _$RemoveCardRequestedCopyWithImpl<RemoveCardRequested>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RemoveCardRequested &&
            (identical(other.cardIdPath, cardIdPath) ||
                other.cardIdPath == cardIdPath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, cardIdPath);

  @override
  String toString() {
    return 'SdCardScannerEvent.removeCardRequested(cardIdPath: $cardIdPath)';
  }
}

/// @nodoc
abstract mixin class $RemoveCardRequestedCopyWith<$Res>
    implements $SdCardScannerEventCopyWith<$Res> {
  factory $RemoveCardRequestedCopyWith(
          RemoveCardRequested value, $Res Function(RemoveCardRequested) _then) =
      _$RemoveCardRequestedCopyWithImpl;
  @useResult
  $Res call({String cardIdPath});
}

/// @nodoc
class _$RemoveCardRequestedCopyWithImpl<$Res>
    implements $RemoveCardRequestedCopyWith<$Res> {
  _$RemoveCardRequestedCopyWithImpl(this._self, this._then);

  final RemoveCardRequested _self;
  final $Res Function(RemoveCardRequested) _then;

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? cardIdPath = null,
  }) {
    return _then(RemoveCardRequested(
      cardIdPath: null == cardIdPath
          ? _self.cardIdPath
          : cardIdPath // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class ClearMessages implements SdCardScannerEvent {
  const ClearMessages();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ClearMessages);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SdCardScannerEvent.clearMessages()';
  }
}

// dart format on
