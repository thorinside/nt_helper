// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SdCardScannerEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SdCardScannerEvent()';
}


}

/// @nodoc
class $SdCardScannerEventCopyWith<$Res>  {
$SdCardScannerEventCopyWith(SdCardScannerEvent _, $Res Function(SdCardScannerEvent) __);
}


/// Adds pattern-matching-related methods to [SdCardScannerEvent].
extension SdCardScannerEventPatterns on SdCardScannerEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoadScannedCards value)?  loadScannedCards,TResult Function( ScanRequested value)?  scanRequested,TResult Function( RescanCardRequested value)?  rescanCardRequested,TResult Function( ScanCancelled value)?  scanCancelled,TResult Function( RemoveCardRequested value)?  removeCardRequested,TResult Function( ClearMessages value)?  clearMessages,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoadScannedCards() when loadScannedCards != null:
return loadScannedCards(_that);case ScanRequested() when scanRequested != null:
return scanRequested(_that);case RescanCardRequested() when rescanCardRequested != null:
return rescanCardRequested(_that);case ScanCancelled() when scanCancelled != null:
return scanCancelled(_that);case RemoveCardRequested() when removeCardRequested != null:
return removeCardRequested(_that);case ClearMessages() when clearMessages != null:
return clearMessages(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoadScannedCards value)  loadScannedCards,required TResult Function( ScanRequested value)  scanRequested,required TResult Function( RescanCardRequested value)  rescanCardRequested,required TResult Function( ScanCancelled value)  scanCancelled,required TResult Function( RemoveCardRequested value)  removeCardRequested,required TResult Function( ClearMessages value)  clearMessages,}){
final _that = this;
switch (_that) {
case LoadScannedCards():
return loadScannedCards(_that);case ScanRequested():
return scanRequested(_that);case RescanCardRequested():
return rescanCardRequested(_that);case ScanCancelled():
return scanCancelled(_that);case RemoveCardRequested():
return removeCardRequested(_that);case ClearMessages():
return clearMessages(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoadScannedCards value)?  loadScannedCards,TResult? Function( ScanRequested value)?  scanRequested,TResult? Function( RescanCardRequested value)?  rescanCardRequested,TResult? Function( ScanCancelled value)?  scanCancelled,TResult? Function( RemoveCardRequested value)?  removeCardRequested,TResult? Function( ClearMessages value)?  clearMessages,}){
final _that = this;
switch (_that) {
case LoadScannedCards() when loadScannedCards != null:
return loadScannedCards(_that);case ScanRequested() when scanRequested != null:
return scanRequested(_that);case RescanCardRequested() when rescanCardRequested != null:
return rescanCardRequested(_that);case ScanCancelled() when scanCancelled != null:
return scanCancelled(_that);case RemoveCardRequested() when removeCardRequested != null:
return removeCardRequested(_that);case ClearMessages() when clearMessages != null:
return clearMessages(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadScannedCards,TResult Function( String sdCardRootPathOrUri,  String relativePresetsPath,  String cardName)?  scanRequested,TResult Function( String cardIdPath,  String relativePresetsPath,  String cardName)?  rescanCardRequested,TResult Function()?  scanCancelled,TResult Function( String cardIdPath)?  removeCardRequested,TResult Function()?  clearMessages,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoadScannedCards() when loadScannedCards != null:
return loadScannedCards();case ScanRequested() when scanRequested != null:
return scanRequested(_that.sdCardRootPathOrUri,_that.relativePresetsPath,_that.cardName);case RescanCardRequested() when rescanCardRequested != null:
return rescanCardRequested(_that.cardIdPath,_that.relativePresetsPath,_that.cardName);case ScanCancelled() when scanCancelled != null:
return scanCancelled();case RemoveCardRequested() when removeCardRequested != null:
return removeCardRequested(_that.cardIdPath);case ClearMessages() when clearMessages != null:
return clearMessages();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadScannedCards,required TResult Function( String sdCardRootPathOrUri,  String relativePresetsPath,  String cardName)  scanRequested,required TResult Function( String cardIdPath,  String relativePresetsPath,  String cardName)  rescanCardRequested,required TResult Function()  scanCancelled,required TResult Function( String cardIdPath)  removeCardRequested,required TResult Function()  clearMessages,}) {final _that = this;
switch (_that) {
case LoadScannedCards():
return loadScannedCards();case ScanRequested():
return scanRequested(_that.sdCardRootPathOrUri,_that.relativePresetsPath,_that.cardName);case RescanCardRequested():
return rescanCardRequested(_that.cardIdPath,_that.relativePresetsPath,_that.cardName);case ScanCancelled():
return scanCancelled();case RemoveCardRequested():
return removeCardRequested(_that.cardIdPath);case ClearMessages():
return clearMessages();case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadScannedCards,TResult? Function( String sdCardRootPathOrUri,  String relativePresetsPath,  String cardName)?  scanRequested,TResult? Function( String cardIdPath,  String relativePresetsPath,  String cardName)?  rescanCardRequested,TResult? Function()?  scanCancelled,TResult? Function( String cardIdPath)?  removeCardRequested,TResult? Function()?  clearMessages,}) {final _that = this;
switch (_that) {
case LoadScannedCards() when loadScannedCards != null:
return loadScannedCards();case ScanRequested() when scanRequested != null:
return scanRequested(_that.sdCardRootPathOrUri,_that.relativePresetsPath,_that.cardName);case RescanCardRequested() when rescanCardRequested != null:
return rescanCardRequested(_that.cardIdPath,_that.relativePresetsPath,_that.cardName);case ScanCancelled() when scanCancelled != null:
return scanCancelled();case RemoveCardRequested() when removeCardRequested != null:
return removeCardRequested(_that.cardIdPath);case ClearMessages() when clearMessages != null:
return clearMessages();case _:
  return null;

}
}

}

/// @nodoc


class LoadScannedCards implements SdCardScannerEvent {
  const LoadScannedCards();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadScannedCards);
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
  const ScanRequested({required this.sdCardRootPathOrUri, required this.relativePresetsPath, required this.cardName});
  

 final  String sdCardRootPathOrUri;
 final  String relativePresetsPath;
 final  String cardName;

/// Create a copy of SdCardScannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanRequestedCopyWith<ScanRequested> get copyWith => _$ScanRequestedCopyWithImpl<ScanRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanRequested&&(identical(other.sdCardRootPathOrUri, sdCardRootPathOrUri) || other.sdCardRootPathOrUri == sdCardRootPathOrUri)&&(identical(other.relativePresetsPath, relativePresetsPath) || other.relativePresetsPath == relativePresetsPath)&&(identical(other.cardName, cardName) || other.cardName == cardName));
}


@override
int get hashCode => Object.hash(runtimeType,sdCardRootPathOrUri,relativePresetsPath,cardName);

@override
String toString() {
  return 'SdCardScannerEvent.scanRequested(sdCardRootPathOrUri: $sdCardRootPathOrUri, relativePresetsPath: $relativePresetsPath, cardName: $cardName)';
}


}

/// @nodoc
abstract mixin class $ScanRequestedCopyWith<$Res> implements $SdCardScannerEventCopyWith<$Res> {
  factory $ScanRequestedCopyWith(ScanRequested value, $Res Function(ScanRequested) _then) = _$ScanRequestedCopyWithImpl;
@useResult
$Res call({
 String sdCardRootPathOrUri, String relativePresetsPath, String cardName
});




}
/// @nodoc
class _$ScanRequestedCopyWithImpl<$Res>
    implements $ScanRequestedCopyWith<$Res> {
  _$ScanRequestedCopyWithImpl(this._self, this._then);

  final ScanRequested _self;
  final $Res Function(ScanRequested) _then;

/// Create a copy of SdCardScannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sdCardRootPathOrUri = null,Object? relativePresetsPath = null,Object? cardName = null,}) {
  return _then(ScanRequested(
sdCardRootPathOrUri: null == sdCardRootPathOrUri ? _self.sdCardRootPathOrUri : sdCardRootPathOrUri // ignore: cast_nullable_to_non_nullable
as String,relativePresetsPath: null == relativePresetsPath ? _self.relativePresetsPath : relativePresetsPath // ignore: cast_nullable_to_non_nullable
as String,cardName: null == cardName ? _self.cardName : cardName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RescanCardRequested implements SdCardScannerEvent {
  const RescanCardRequested({required this.cardIdPath, required this.relativePresetsPath, required this.cardName});
  

 final  String cardIdPath;
 final  String relativePresetsPath;
 final  String cardName;

/// Create a copy of SdCardScannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RescanCardRequestedCopyWith<RescanCardRequested> get copyWith => _$RescanCardRequestedCopyWithImpl<RescanCardRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RescanCardRequested&&(identical(other.cardIdPath, cardIdPath) || other.cardIdPath == cardIdPath)&&(identical(other.relativePresetsPath, relativePresetsPath) || other.relativePresetsPath == relativePresetsPath)&&(identical(other.cardName, cardName) || other.cardName == cardName));
}


@override
int get hashCode => Object.hash(runtimeType,cardIdPath,relativePresetsPath,cardName);

@override
String toString() {
  return 'SdCardScannerEvent.rescanCardRequested(cardIdPath: $cardIdPath, relativePresetsPath: $relativePresetsPath, cardName: $cardName)';
}


}

/// @nodoc
abstract mixin class $RescanCardRequestedCopyWith<$Res> implements $SdCardScannerEventCopyWith<$Res> {
  factory $RescanCardRequestedCopyWith(RescanCardRequested value, $Res Function(RescanCardRequested) _then) = _$RescanCardRequestedCopyWithImpl;
@useResult
$Res call({
 String cardIdPath, String relativePresetsPath, String cardName
});




}
/// @nodoc
class _$RescanCardRequestedCopyWithImpl<$Res>
    implements $RescanCardRequestedCopyWith<$Res> {
  _$RescanCardRequestedCopyWithImpl(this._self, this._then);

  final RescanCardRequested _self;
  final $Res Function(RescanCardRequested) _then;

/// Create a copy of SdCardScannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cardIdPath = null,Object? relativePresetsPath = null,Object? cardName = null,}) {
  return _then(RescanCardRequested(
cardIdPath: null == cardIdPath ? _self.cardIdPath : cardIdPath // ignore: cast_nullable_to_non_nullable
as String,relativePresetsPath: null == relativePresetsPath ? _self.relativePresetsPath : relativePresetsPath // ignore: cast_nullable_to_non_nullable
as String,cardName: null == cardName ? _self.cardName : cardName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ScanCancelled implements SdCardScannerEvent {
  const ScanCancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanCancelled);
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
  

 final  String cardIdPath;

/// Create a copy of SdCardScannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoveCardRequestedCopyWith<RemoveCardRequested> get copyWith => _$RemoveCardRequestedCopyWithImpl<RemoveCardRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoveCardRequested&&(identical(other.cardIdPath, cardIdPath) || other.cardIdPath == cardIdPath));
}


@override
int get hashCode => Object.hash(runtimeType,cardIdPath);

@override
String toString() {
  return 'SdCardScannerEvent.removeCardRequested(cardIdPath: $cardIdPath)';
}


}

/// @nodoc
abstract mixin class $RemoveCardRequestedCopyWith<$Res> implements $SdCardScannerEventCopyWith<$Res> {
  factory $RemoveCardRequestedCopyWith(RemoveCardRequested value, $Res Function(RemoveCardRequested) _then) = _$RemoveCardRequestedCopyWithImpl;
@useResult
$Res call({
 String cardIdPath
});




}
/// @nodoc
class _$RemoveCardRequestedCopyWithImpl<$Res>
    implements $RemoveCardRequestedCopyWith<$Res> {
  _$RemoveCardRequestedCopyWithImpl(this._self, this._then);

  final RemoveCardRequested _self;
  final $Res Function(RemoveCardRequested) _then;

/// Create a copy of SdCardScannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cardIdPath = null,}) {
  return _then(RemoveCardRequested(
cardIdPath: null == cardIdPath ? _self.cardIdPath : cardIdPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ClearMessages implements SdCardScannerEvent {
  const ClearMessages();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClearMessages);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SdCardScannerEvent.clearMessages()';
}


}




// dart format on
