// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sd_card_scanner_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SdCardScannerEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadScannedCards,
    required TResult Function(String path, String cardName) scanRequested,
    required TResult Function(String cardIdPath, String cardName)
        rescanCardRequested,
    required TResult Function() scanCancelled,
    required TResult Function(String cardIdPath) removeCardRequested,
    required TResult Function() clearMessages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadScannedCards,
    TResult? Function(String path, String cardName)? scanRequested,
    TResult? Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult? Function()? scanCancelled,
    TResult? Function(String cardIdPath)? removeCardRequested,
    TResult? Function()? clearMessages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadScannedCards,
    TResult Function(String path, String cardName)? scanRequested,
    TResult Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult Function()? scanCancelled,
    TResult Function(String cardIdPath)? removeCardRequested,
    TResult Function()? clearMessages,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadScannedCards value) loadScannedCards,
    required TResult Function(ScanRequested value) scanRequested,
    required TResult Function(RescanCardRequested value) rescanCardRequested,
    required TResult Function(ScanCancelled value) scanCancelled,
    required TResult Function(RemoveCardRequested value) removeCardRequested,
    required TResult Function(ClearMessages value) clearMessages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadScannedCards value)? loadScannedCards,
    TResult? Function(ScanRequested value)? scanRequested,
    TResult? Function(RescanCardRequested value)? rescanCardRequested,
    TResult? Function(ScanCancelled value)? scanCancelled,
    TResult? Function(RemoveCardRequested value)? removeCardRequested,
    TResult? Function(ClearMessages value)? clearMessages,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadScannedCards value)? loadScannedCards,
    TResult Function(ScanRequested value)? scanRequested,
    TResult Function(RescanCardRequested value)? rescanCardRequested,
    TResult Function(ScanCancelled value)? scanCancelled,
    TResult Function(RemoveCardRequested value)? removeCardRequested,
    TResult Function(ClearMessages value)? clearMessages,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SdCardScannerEventCopyWith<$Res> {
  factory $SdCardScannerEventCopyWith(
          SdCardScannerEvent value, $Res Function(SdCardScannerEvent) then) =
      _$SdCardScannerEventCopyWithImpl<$Res, SdCardScannerEvent>;
}

/// @nodoc
class _$SdCardScannerEventCopyWithImpl<$Res, $Val extends SdCardScannerEvent>
    implements $SdCardScannerEventCopyWith<$Res> {
  _$SdCardScannerEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LoadScannedCardsImplCopyWith<$Res> {
  factory _$$LoadScannedCardsImplCopyWith(_$LoadScannedCardsImpl value,
          $Res Function(_$LoadScannedCardsImpl) then) =
      __$$LoadScannedCardsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadScannedCardsImplCopyWithImpl<$Res>
    extends _$SdCardScannerEventCopyWithImpl<$Res, _$LoadScannedCardsImpl>
    implements _$$LoadScannedCardsImplCopyWith<$Res> {
  __$$LoadScannedCardsImplCopyWithImpl(_$LoadScannedCardsImpl _value,
      $Res Function(_$LoadScannedCardsImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadScannedCardsImpl implements LoadScannedCards {
  const _$LoadScannedCardsImpl();

  @override
  String toString() {
    return 'SdCardScannerEvent.loadScannedCards()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadScannedCardsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadScannedCards,
    required TResult Function(String path, String cardName) scanRequested,
    required TResult Function(String cardIdPath, String cardName)
        rescanCardRequested,
    required TResult Function() scanCancelled,
    required TResult Function(String cardIdPath) removeCardRequested,
    required TResult Function() clearMessages,
  }) {
    return loadScannedCards();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadScannedCards,
    TResult? Function(String path, String cardName)? scanRequested,
    TResult? Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult? Function()? scanCancelled,
    TResult? Function(String cardIdPath)? removeCardRequested,
    TResult? Function()? clearMessages,
  }) {
    return loadScannedCards?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadScannedCards,
    TResult Function(String path, String cardName)? scanRequested,
    TResult Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult Function()? scanCancelled,
    TResult Function(String cardIdPath)? removeCardRequested,
    TResult Function()? clearMessages,
    required TResult orElse(),
  }) {
    if (loadScannedCards != null) {
      return loadScannedCards();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadScannedCards value) loadScannedCards,
    required TResult Function(ScanRequested value) scanRequested,
    required TResult Function(RescanCardRequested value) rescanCardRequested,
    required TResult Function(ScanCancelled value) scanCancelled,
    required TResult Function(RemoveCardRequested value) removeCardRequested,
    required TResult Function(ClearMessages value) clearMessages,
  }) {
    return loadScannedCards(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadScannedCards value)? loadScannedCards,
    TResult? Function(ScanRequested value)? scanRequested,
    TResult? Function(RescanCardRequested value)? rescanCardRequested,
    TResult? Function(ScanCancelled value)? scanCancelled,
    TResult? Function(RemoveCardRequested value)? removeCardRequested,
    TResult? Function(ClearMessages value)? clearMessages,
  }) {
    return loadScannedCards?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadScannedCards value)? loadScannedCards,
    TResult Function(ScanRequested value)? scanRequested,
    TResult Function(RescanCardRequested value)? rescanCardRequested,
    TResult Function(ScanCancelled value)? scanCancelled,
    TResult Function(RemoveCardRequested value)? removeCardRequested,
    TResult Function(ClearMessages value)? clearMessages,
    required TResult orElse(),
  }) {
    if (loadScannedCards != null) {
      return loadScannedCards(this);
    }
    return orElse();
  }
}

abstract class LoadScannedCards implements SdCardScannerEvent {
  const factory LoadScannedCards() = _$LoadScannedCardsImpl;
}

/// @nodoc
abstract class _$$ScanRequestedImplCopyWith<$Res> {
  factory _$$ScanRequestedImplCopyWith(
          _$ScanRequestedImpl value, $Res Function(_$ScanRequestedImpl) then) =
      __$$ScanRequestedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String path, String cardName});
}

/// @nodoc
class __$$ScanRequestedImplCopyWithImpl<$Res>
    extends _$SdCardScannerEventCopyWithImpl<$Res, _$ScanRequestedImpl>
    implements _$$ScanRequestedImplCopyWith<$Res> {
  __$$ScanRequestedImplCopyWithImpl(
      _$ScanRequestedImpl _value, $Res Function(_$ScanRequestedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? cardName = null,
  }) {
    return _then(_$ScanRequestedImpl(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      cardName: null == cardName
          ? _value.cardName
          : cardName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ScanRequestedImpl implements ScanRequested {
  const _$ScanRequestedImpl({required this.path, required this.cardName});

  @override
  final String path;
  @override
  final String cardName;

  @override
  String toString() {
    return 'SdCardScannerEvent.scanRequested(path: $path, cardName: $cardName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScanRequestedImpl &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.cardName, cardName) ||
                other.cardName == cardName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, path, cardName);

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScanRequestedImplCopyWith<_$ScanRequestedImpl> get copyWith =>
      __$$ScanRequestedImplCopyWithImpl<_$ScanRequestedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadScannedCards,
    required TResult Function(String path, String cardName) scanRequested,
    required TResult Function(String cardIdPath, String cardName)
        rescanCardRequested,
    required TResult Function() scanCancelled,
    required TResult Function(String cardIdPath) removeCardRequested,
    required TResult Function() clearMessages,
  }) {
    return scanRequested(path, cardName);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadScannedCards,
    TResult? Function(String path, String cardName)? scanRequested,
    TResult? Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult? Function()? scanCancelled,
    TResult? Function(String cardIdPath)? removeCardRequested,
    TResult? Function()? clearMessages,
  }) {
    return scanRequested?.call(path, cardName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadScannedCards,
    TResult Function(String path, String cardName)? scanRequested,
    TResult Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult Function()? scanCancelled,
    TResult Function(String cardIdPath)? removeCardRequested,
    TResult Function()? clearMessages,
    required TResult orElse(),
  }) {
    if (scanRequested != null) {
      return scanRequested(path, cardName);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadScannedCards value) loadScannedCards,
    required TResult Function(ScanRequested value) scanRequested,
    required TResult Function(RescanCardRequested value) rescanCardRequested,
    required TResult Function(ScanCancelled value) scanCancelled,
    required TResult Function(RemoveCardRequested value) removeCardRequested,
    required TResult Function(ClearMessages value) clearMessages,
  }) {
    return scanRequested(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadScannedCards value)? loadScannedCards,
    TResult? Function(ScanRequested value)? scanRequested,
    TResult? Function(RescanCardRequested value)? rescanCardRequested,
    TResult? Function(ScanCancelled value)? scanCancelled,
    TResult? Function(RemoveCardRequested value)? removeCardRequested,
    TResult? Function(ClearMessages value)? clearMessages,
  }) {
    return scanRequested?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadScannedCards value)? loadScannedCards,
    TResult Function(ScanRequested value)? scanRequested,
    TResult Function(RescanCardRequested value)? rescanCardRequested,
    TResult Function(ScanCancelled value)? scanCancelled,
    TResult Function(RemoveCardRequested value)? removeCardRequested,
    TResult Function(ClearMessages value)? clearMessages,
    required TResult orElse(),
  }) {
    if (scanRequested != null) {
      return scanRequested(this);
    }
    return orElse();
  }
}

abstract class ScanRequested implements SdCardScannerEvent {
  const factory ScanRequested(
      {required final String path,
      required final String cardName}) = _$ScanRequestedImpl;

  String get path;
  String get cardName;

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScanRequestedImplCopyWith<_$ScanRequestedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RescanCardRequestedImplCopyWith<$Res> {
  factory _$$RescanCardRequestedImplCopyWith(_$RescanCardRequestedImpl value,
          $Res Function(_$RescanCardRequestedImpl) then) =
      __$$RescanCardRequestedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String cardIdPath, String cardName});
}

/// @nodoc
class __$$RescanCardRequestedImplCopyWithImpl<$Res>
    extends _$SdCardScannerEventCopyWithImpl<$Res, _$RescanCardRequestedImpl>
    implements _$$RescanCardRequestedImplCopyWith<$Res> {
  __$$RescanCardRequestedImplCopyWithImpl(_$RescanCardRequestedImpl _value,
      $Res Function(_$RescanCardRequestedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardIdPath = null,
    Object? cardName = null,
  }) {
    return _then(_$RescanCardRequestedImpl(
      cardIdPath: null == cardIdPath
          ? _value.cardIdPath
          : cardIdPath // ignore: cast_nullable_to_non_nullable
              as String,
      cardName: null == cardName
          ? _value.cardName
          : cardName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$RescanCardRequestedImpl implements RescanCardRequested {
  const _$RescanCardRequestedImpl(
      {required this.cardIdPath, required this.cardName});

  @override
  final String cardIdPath;
  @override
  final String cardName;

  @override
  String toString() {
    return 'SdCardScannerEvent.rescanCardRequested(cardIdPath: $cardIdPath, cardName: $cardName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RescanCardRequestedImpl &&
            (identical(other.cardIdPath, cardIdPath) ||
                other.cardIdPath == cardIdPath) &&
            (identical(other.cardName, cardName) ||
                other.cardName == cardName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, cardIdPath, cardName);

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RescanCardRequestedImplCopyWith<_$RescanCardRequestedImpl> get copyWith =>
      __$$RescanCardRequestedImplCopyWithImpl<_$RescanCardRequestedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadScannedCards,
    required TResult Function(String path, String cardName) scanRequested,
    required TResult Function(String cardIdPath, String cardName)
        rescanCardRequested,
    required TResult Function() scanCancelled,
    required TResult Function(String cardIdPath) removeCardRequested,
    required TResult Function() clearMessages,
  }) {
    return rescanCardRequested(cardIdPath, cardName);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadScannedCards,
    TResult? Function(String path, String cardName)? scanRequested,
    TResult? Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult? Function()? scanCancelled,
    TResult? Function(String cardIdPath)? removeCardRequested,
    TResult? Function()? clearMessages,
  }) {
    return rescanCardRequested?.call(cardIdPath, cardName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadScannedCards,
    TResult Function(String path, String cardName)? scanRequested,
    TResult Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult Function()? scanCancelled,
    TResult Function(String cardIdPath)? removeCardRequested,
    TResult Function()? clearMessages,
    required TResult orElse(),
  }) {
    if (rescanCardRequested != null) {
      return rescanCardRequested(cardIdPath, cardName);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadScannedCards value) loadScannedCards,
    required TResult Function(ScanRequested value) scanRequested,
    required TResult Function(RescanCardRequested value) rescanCardRequested,
    required TResult Function(ScanCancelled value) scanCancelled,
    required TResult Function(RemoveCardRequested value) removeCardRequested,
    required TResult Function(ClearMessages value) clearMessages,
  }) {
    return rescanCardRequested(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadScannedCards value)? loadScannedCards,
    TResult? Function(ScanRequested value)? scanRequested,
    TResult? Function(RescanCardRequested value)? rescanCardRequested,
    TResult? Function(ScanCancelled value)? scanCancelled,
    TResult? Function(RemoveCardRequested value)? removeCardRequested,
    TResult? Function(ClearMessages value)? clearMessages,
  }) {
    return rescanCardRequested?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadScannedCards value)? loadScannedCards,
    TResult Function(ScanRequested value)? scanRequested,
    TResult Function(RescanCardRequested value)? rescanCardRequested,
    TResult Function(ScanCancelled value)? scanCancelled,
    TResult Function(RemoveCardRequested value)? removeCardRequested,
    TResult Function(ClearMessages value)? clearMessages,
    required TResult orElse(),
  }) {
    if (rescanCardRequested != null) {
      return rescanCardRequested(this);
    }
    return orElse();
  }
}

abstract class RescanCardRequested implements SdCardScannerEvent {
  const factory RescanCardRequested(
      {required final String cardIdPath,
      required final String cardName}) = _$RescanCardRequestedImpl;

  String get cardIdPath;
  String get cardName;

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RescanCardRequestedImplCopyWith<_$RescanCardRequestedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ScanCancelledImplCopyWith<$Res> {
  factory _$$ScanCancelledImplCopyWith(
          _$ScanCancelledImpl value, $Res Function(_$ScanCancelledImpl) then) =
      __$$ScanCancelledImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ScanCancelledImplCopyWithImpl<$Res>
    extends _$SdCardScannerEventCopyWithImpl<$Res, _$ScanCancelledImpl>
    implements _$$ScanCancelledImplCopyWith<$Res> {
  __$$ScanCancelledImplCopyWithImpl(
      _$ScanCancelledImpl _value, $Res Function(_$ScanCancelledImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ScanCancelledImpl implements ScanCancelled {
  const _$ScanCancelledImpl();

  @override
  String toString() {
    return 'SdCardScannerEvent.scanCancelled()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ScanCancelledImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadScannedCards,
    required TResult Function(String path, String cardName) scanRequested,
    required TResult Function(String cardIdPath, String cardName)
        rescanCardRequested,
    required TResult Function() scanCancelled,
    required TResult Function(String cardIdPath) removeCardRequested,
    required TResult Function() clearMessages,
  }) {
    return scanCancelled();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadScannedCards,
    TResult? Function(String path, String cardName)? scanRequested,
    TResult? Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult? Function()? scanCancelled,
    TResult? Function(String cardIdPath)? removeCardRequested,
    TResult? Function()? clearMessages,
  }) {
    return scanCancelled?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadScannedCards,
    TResult Function(String path, String cardName)? scanRequested,
    TResult Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult Function()? scanCancelled,
    TResult Function(String cardIdPath)? removeCardRequested,
    TResult Function()? clearMessages,
    required TResult orElse(),
  }) {
    if (scanCancelled != null) {
      return scanCancelled();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadScannedCards value) loadScannedCards,
    required TResult Function(ScanRequested value) scanRequested,
    required TResult Function(RescanCardRequested value) rescanCardRequested,
    required TResult Function(ScanCancelled value) scanCancelled,
    required TResult Function(RemoveCardRequested value) removeCardRequested,
    required TResult Function(ClearMessages value) clearMessages,
  }) {
    return scanCancelled(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadScannedCards value)? loadScannedCards,
    TResult? Function(ScanRequested value)? scanRequested,
    TResult? Function(RescanCardRequested value)? rescanCardRequested,
    TResult? Function(ScanCancelled value)? scanCancelled,
    TResult? Function(RemoveCardRequested value)? removeCardRequested,
    TResult? Function(ClearMessages value)? clearMessages,
  }) {
    return scanCancelled?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadScannedCards value)? loadScannedCards,
    TResult Function(ScanRequested value)? scanRequested,
    TResult Function(RescanCardRequested value)? rescanCardRequested,
    TResult Function(ScanCancelled value)? scanCancelled,
    TResult Function(RemoveCardRequested value)? removeCardRequested,
    TResult Function(ClearMessages value)? clearMessages,
    required TResult orElse(),
  }) {
    if (scanCancelled != null) {
      return scanCancelled(this);
    }
    return orElse();
  }
}

abstract class ScanCancelled implements SdCardScannerEvent {
  const factory ScanCancelled() = _$ScanCancelledImpl;
}

/// @nodoc
abstract class _$$RemoveCardRequestedImplCopyWith<$Res> {
  factory _$$RemoveCardRequestedImplCopyWith(_$RemoveCardRequestedImpl value,
          $Res Function(_$RemoveCardRequestedImpl) then) =
      __$$RemoveCardRequestedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String cardIdPath});
}

/// @nodoc
class __$$RemoveCardRequestedImplCopyWithImpl<$Res>
    extends _$SdCardScannerEventCopyWithImpl<$Res, _$RemoveCardRequestedImpl>
    implements _$$RemoveCardRequestedImplCopyWith<$Res> {
  __$$RemoveCardRequestedImplCopyWithImpl(_$RemoveCardRequestedImpl _value,
      $Res Function(_$RemoveCardRequestedImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardIdPath = null,
  }) {
    return _then(_$RemoveCardRequestedImpl(
      cardIdPath: null == cardIdPath
          ? _value.cardIdPath
          : cardIdPath // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$RemoveCardRequestedImpl implements RemoveCardRequested {
  const _$RemoveCardRequestedImpl({required this.cardIdPath});

  @override
  final String cardIdPath;

  @override
  String toString() {
    return 'SdCardScannerEvent.removeCardRequested(cardIdPath: $cardIdPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RemoveCardRequestedImpl &&
            (identical(other.cardIdPath, cardIdPath) ||
                other.cardIdPath == cardIdPath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, cardIdPath);

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RemoveCardRequestedImplCopyWith<_$RemoveCardRequestedImpl> get copyWith =>
      __$$RemoveCardRequestedImplCopyWithImpl<_$RemoveCardRequestedImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadScannedCards,
    required TResult Function(String path, String cardName) scanRequested,
    required TResult Function(String cardIdPath, String cardName)
        rescanCardRequested,
    required TResult Function() scanCancelled,
    required TResult Function(String cardIdPath) removeCardRequested,
    required TResult Function() clearMessages,
  }) {
    return removeCardRequested(cardIdPath);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadScannedCards,
    TResult? Function(String path, String cardName)? scanRequested,
    TResult? Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult? Function()? scanCancelled,
    TResult? Function(String cardIdPath)? removeCardRequested,
    TResult? Function()? clearMessages,
  }) {
    return removeCardRequested?.call(cardIdPath);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadScannedCards,
    TResult Function(String path, String cardName)? scanRequested,
    TResult Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult Function()? scanCancelled,
    TResult Function(String cardIdPath)? removeCardRequested,
    TResult Function()? clearMessages,
    required TResult orElse(),
  }) {
    if (removeCardRequested != null) {
      return removeCardRequested(cardIdPath);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadScannedCards value) loadScannedCards,
    required TResult Function(ScanRequested value) scanRequested,
    required TResult Function(RescanCardRequested value) rescanCardRequested,
    required TResult Function(ScanCancelled value) scanCancelled,
    required TResult Function(RemoveCardRequested value) removeCardRequested,
    required TResult Function(ClearMessages value) clearMessages,
  }) {
    return removeCardRequested(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadScannedCards value)? loadScannedCards,
    TResult? Function(ScanRequested value)? scanRequested,
    TResult? Function(RescanCardRequested value)? rescanCardRequested,
    TResult? Function(ScanCancelled value)? scanCancelled,
    TResult? Function(RemoveCardRequested value)? removeCardRequested,
    TResult? Function(ClearMessages value)? clearMessages,
  }) {
    return removeCardRequested?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadScannedCards value)? loadScannedCards,
    TResult Function(ScanRequested value)? scanRequested,
    TResult Function(RescanCardRequested value)? rescanCardRequested,
    TResult Function(ScanCancelled value)? scanCancelled,
    TResult Function(RemoveCardRequested value)? removeCardRequested,
    TResult Function(ClearMessages value)? clearMessages,
    required TResult orElse(),
  }) {
    if (removeCardRequested != null) {
      return removeCardRequested(this);
    }
    return orElse();
  }
}

abstract class RemoveCardRequested implements SdCardScannerEvent {
  const factory RemoveCardRequested({required final String cardIdPath}) =
      _$RemoveCardRequestedImpl;

  String get cardIdPath;

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RemoveCardRequestedImplCopyWith<_$RemoveCardRequestedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ClearMessagesImplCopyWith<$Res> {
  factory _$$ClearMessagesImplCopyWith(
          _$ClearMessagesImpl value, $Res Function(_$ClearMessagesImpl) then) =
      __$$ClearMessagesImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ClearMessagesImplCopyWithImpl<$Res>
    extends _$SdCardScannerEventCopyWithImpl<$Res, _$ClearMessagesImpl>
    implements _$$ClearMessagesImplCopyWith<$Res> {
  __$$ClearMessagesImplCopyWithImpl(
      _$ClearMessagesImpl _value, $Res Function(_$ClearMessagesImpl) _then)
      : super(_value, _then);

  /// Create a copy of SdCardScannerEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ClearMessagesImpl implements ClearMessages {
  const _$ClearMessagesImpl();

  @override
  String toString() {
    return 'SdCardScannerEvent.clearMessages()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ClearMessagesImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadScannedCards,
    required TResult Function(String path, String cardName) scanRequested,
    required TResult Function(String cardIdPath, String cardName)
        rescanCardRequested,
    required TResult Function() scanCancelled,
    required TResult Function(String cardIdPath) removeCardRequested,
    required TResult Function() clearMessages,
  }) {
    return clearMessages();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadScannedCards,
    TResult? Function(String path, String cardName)? scanRequested,
    TResult? Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult? Function()? scanCancelled,
    TResult? Function(String cardIdPath)? removeCardRequested,
    TResult? Function()? clearMessages,
  }) {
    return clearMessages?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadScannedCards,
    TResult Function(String path, String cardName)? scanRequested,
    TResult Function(String cardIdPath, String cardName)? rescanCardRequested,
    TResult Function()? scanCancelled,
    TResult Function(String cardIdPath)? removeCardRequested,
    TResult Function()? clearMessages,
    required TResult orElse(),
  }) {
    if (clearMessages != null) {
      return clearMessages();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadScannedCards value) loadScannedCards,
    required TResult Function(ScanRequested value) scanRequested,
    required TResult Function(RescanCardRequested value) rescanCardRequested,
    required TResult Function(ScanCancelled value) scanCancelled,
    required TResult Function(RemoveCardRequested value) removeCardRequested,
    required TResult Function(ClearMessages value) clearMessages,
  }) {
    return clearMessages(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadScannedCards value)? loadScannedCards,
    TResult? Function(ScanRequested value)? scanRequested,
    TResult? Function(RescanCardRequested value)? rescanCardRequested,
    TResult? Function(ScanCancelled value)? scanCancelled,
    TResult? Function(RemoveCardRequested value)? removeCardRequested,
    TResult? Function(ClearMessages value)? clearMessages,
  }) {
    return clearMessages?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadScannedCards value)? loadScannedCards,
    TResult Function(ScanRequested value)? scanRequested,
    TResult Function(RescanCardRequested value)? rescanCardRequested,
    TResult Function(ScanCancelled value)? scanCancelled,
    TResult Function(RemoveCardRequested value)? removeCardRequested,
    TResult Function(ClearMessages value)? clearMessages,
    required TResult orElse(),
  }) {
    if (clearMessages != null) {
      return clearMessages(this);
    }
    return orElse();
  }
}

abstract class ClearMessages implements SdCardScannerEvent {
  const factory ClearMessages() = _$ClearMessagesImpl;
}
