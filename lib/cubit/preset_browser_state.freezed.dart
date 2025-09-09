// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preset_browser_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PresetBrowserState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresetBrowserState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PresetBrowserState()';
}


}

/// @nodoc
class $PresetBrowserStateCopyWith<$Res>  {
$PresetBrowserStateCopyWith(PresetBrowserState _, $Res Function(PresetBrowserState) __);
}


/// Adds pattern-matching-related methods to [PresetBrowserState].
extension PresetBrowserStatePatterns on PresetBrowserState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _Error():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String currentPath,  List<DirectoryEntry> leftPanelItems,  List<DirectoryEntry> centerPanelItems,  List<DirectoryEntry> rightPanelItems,  DirectoryEntry? selectedLeftItem,  DirectoryEntry? selectedCenterItem,  DirectoryEntry? selectedRightItem,  List<String> navigationHistory,  bool sortByDate,  Map<String, List<DirectoryEntry>>? directoryCache)?  loaded,TResult Function( String message,  String? lastPath)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.currentPath,_that.leftPanelItems,_that.centerPanelItems,_that.rightPanelItems,_that.selectedLeftItem,_that.selectedCenterItem,_that.selectedRightItem,_that.navigationHistory,_that.sortByDate,_that.directoryCache);case _Error() when error != null:
return error(_that.message,_that.lastPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String currentPath,  List<DirectoryEntry> leftPanelItems,  List<DirectoryEntry> centerPanelItems,  List<DirectoryEntry> rightPanelItems,  DirectoryEntry? selectedLeftItem,  DirectoryEntry? selectedCenterItem,  DirectoryEntry? selectedRightItem,  List<String> navigationHistory,  bool sortByDate,  Map<String, List<DirectoryEntry>>? directoryCache)  loaded,required TResult Function( String message,  String? lastPath)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.currentPath,_that.leftPanelItems,_that.centerPanelItems,_that.rightPanelItems,_that.selectedLeftItem,_that.selectedCenterItem,_that.selectedRightItem,_that.navigationHistory,_that.sortByDate,_that.directoryCache);case _Error():
return error(_that.message,_that.lastPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String currentPath,  List<DirectoryEntry> leftPanelItems,  List<DirectoryEntry> centerPanelItems,  List<DirectoryEntry> rightPanelItems,  DirectoryEntry? selectedLeftItem,  DirectoryEntry? selectedCenterItem,  DirectoryEntry? selectedRightItem,  List<String> navigationHistory,  bool sortByDate,  Map<String, List<DirectoryEntry>>? directoryCache)?  loaded,TResult? Function( String message,  String? lastPath)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.currentPath,_that.leftPanelItems,_that.centerPanelItems,_that.rightPanelItems,_that.selectedLeftItem,_that.selectedCenterItem,_that.selectedRightItem,_that.navigationHistory,_that.sortByDate,_that.directoryCache);case _Error() when error != null:
return error(_that.message,_that.lastPath);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements PresetBrowserState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PresetBrowserState.initial()';
}


}




/// @nodoc


class _Loading implements PresetBrowserState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PresetBrowserState.loading()';
}


}




/// @nodoc


class _Loaded implements PresetBrowserState {
  const _Loaded({required this.currentPath, required final  List<DirectoryEntry> leftPanelItems, required final  List<DirectoryEntry> centerPanelItems, required final  List<DirectoryEntry> rightPanelItems, this.selectedLeftItem, this.selectedCenterItem, this.selectedRightItem, required final  List<String> navigationHistory, required this.sortByDate, final  Map<String, List<DirectoryEntry>>? directoryCache}): _leftPanelItems = leftPanelItems,_centerPanelItems = centerPanelItems,_rightPanelItems = rightPanelItems,_navigationHistory = navigationHistory,_directoryCache = directoryCache;
  

 final  String currentPath;
 final  List<DirectoryEntry> _leftPanelItems;
 List<DirectoryEntry> get leftPanelItems {
  if (_leftPanelItems is EqualUnmodifiableListView) return _leftPanelItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_leftPanelItems);
}

 final  List<DirectoryEntry> _centerPanelItems;
 List<DirectoryEntry> get centerPanelItems {
  if (_centerPanelItems is EqualUnmodifiableListView) return _centerPanelItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_centerPanelItems);
}

 final  List<DirectoryEntry> _rightPanelItems;
 List<DirectoryEntry> get rightPanelItems {
  if (_rightPanelItems is EqualUnmodifiableListView) return _rightPanelItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rightPanelItems);
}

 final  DirectoryEntry? selectedLeftItem;
 final  DirectoryEntry? selectedCenterItem;
 final  DirectoryEntry? selectedRightItem;
 final  List<String> _navigationHistory;
 List<String> get navigationHistory {
  if (_navigationHistory is EqualUnmodifiableListView) return _navigationHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_navigationHistory);
}

 final  bool sortByDate;
 final  Map<String, List<DirectoryEntry>>? _directoryCache;
 Map<String, List<DirectoryEntry>>? get directoryCache {
  final value = _directoryCache;
  if (value == null) return null;
  if (_directoryCache is EqualUnmodifiableMapView) return _directoryCache;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of PresetBrowserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&(identical(other.currentPath, currentPath) || other.currentPath == currentPath)&&const DeepCollectionEquality().equals(other._leftPanelItems, _leftPanelItems)&&const DeepCollectionEquality().equals(other._centerPanelItems, _centerPanelItems)&&const DeepCollectionEquality().equals(other._rightPanelItems, _rightPanelItems)&&(identical(other.selectedLeftItem, selectedLeftItem) || other.selectedLeftItem == selectedLeftItem)&&(identical(other.selectedCenterItem, selectedCenterItem) || other.selectedCenterItem == selectedCenterItem)&&(identical(other.selectedRightItem, selectedRightItem) || other.selectedRightItem == selectedRightItem)&&const DeepCollectionEquality().equals(other._navigationHistory, _navigationHistory)&&(identical(other.sortByDate, sortByDate) || other.sortByDate == sortByDate)&&const DeepCollectionEquality().equals(other._directoryCache, _directoryCache));
}


@override
int get hashCode => Object.hash(runtimeType,currentPath,const DeepCollectionEquality().hash(_leftPanelItems),const DeepCollectionEquality().hash(_centerPanelItems),const DeepCollectionEquality().hash(_rightPanelItems),selectedLeftItem,selectedCenterItem,selectedRightItem,const DeepCollectionEquality().hash(_navigationHistory),sortByDate,const DeepCollectionEquality().hash(_directoryCache));

@override
String toString() {
  return 'PresetBrowserState.loaded(currentPath: $currentPath, leftPanelItems: $leftPanelItems, centerPanelItems: $centerPanelItems, rightPanelItems: $rightPanelItems, selectedLeftItem: $selectedLeftItem, selectedCenterItem: $selectedCenterItem, selectedRightItem: $selectedRightItem, navigationHistory: $navigationHistory, sortByDate: $sortByDate, directoryCache: $directoryCache)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $PresetBrowserStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 String currentPath, List<DirectoryEntry> leftPanelItems, List<DirectoryEntry> centerPanelItems, List<DirectoryEntry> rightPanelItems, DirectoryEntry? selectedLeftItem, DirectoryEntry? selectedCenterItem, DirectoryEntry? selectedRightItem, List<String> navigationHistory, bool sortByDate, Map<String, List<DirectoryEntry>>? directoryCache
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of PresetBrowserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? currentPath = null,Object? leftPanelItems = null,Object? centerPanelItems = null,Object? rightPanelItems = null,Object? selectedLeftItem = freezed,Object? selectedCenterItem = freezed,Object? selectedRightItem = freezed,Object? navigationHistory = null,Object? sortByDate = null,Object? directoryCache = freezed,}) {
  return _then(_Loaded(
currentPath: null == currentPath ? _self.currentPath : currentPath // ignore: cast_nullable_to_non_nullable
as String,leftPanelItems: null == leftPanelItems ? _self._leftPanelItems : leftPanelItems // ignore: cast_nullable_to_non_nullable
as List<DirectoryEntry>,centerPanelItems: null == centerPanelItems ? _self._centerPanelItems : centerPanelItems // ignore: cast_nullable_to_non_nullable
as List<DirectoryEntry>,rightPanelItems: null == rightPanelItems ? _self._rightPanelItems : rightPanelItems // ignore: cast_nullable_to_non_nullable
as List<DirectoryEntry>,selectedLeftItem: freezed == selectedLeftItem ? _self.selectedLeftItem : selectedLeftItem // ignore: cast_nullable_to_non_nullable
as DirectoryEntry?,selectedCenterItem: freezed == selectedCenterItem ? _self.selectedCenterItem : selectedCenterItem // ignore: cast_nullable_to_non_nullable
as DirectoryEntry?,selectedRightItem: freezed == selectedRightItem ? _self.selectedRightItem : selectedRightItem // ignore: cast_nullable_to_non_nullable
as DirectoryEntry?,navigationHistory: null == navigationHistory ? _self._navigationHistory : navigationHistory // ignore: cast_nullable_to_non_nullable
as List<String>,sortByDate: null == sortByDate ? _self.sortByDate : sortByDate // ignore: cast_nullable_to_non_nullable
as bool,directoryCache: freezed == directoryCache ? _self._directoryCache : directoryCache // ignore: cast_nullable_to_non_nullable
as Map<String, List<DirectoryEntry>>?,
  ));
}


}

/// @nodoc


class _Error implements PresetBrowserState {
  const _Error({required this.message, this.lastPath});
  

 final  String message;
 final  String? lastPath;

/// Create a copy of PresetBrowserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message)&&(identical(other.lastPath, lastPath) || other.lastPath == lastPath));
}


@override
int get hashCode => Object.hash(runtimeType,message,lastPath);

@override
String toString() {
  return 'PresetBrowserState.error(message: $message, lastPath: $lastPath)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $PresetBrowserStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message, String? lastPath
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of PresetBrowserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? lastPath = freezed,}) {
  return _then(_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,lastPath: freezed == lastPath ? _self.lastPath : lastPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
