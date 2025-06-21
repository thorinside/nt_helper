// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'marketplace_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MarketplaceState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is MarketplaceState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'MarketplaceState()';
  }
}

/// @nodoc
class $MarketplaceStateCopyWith<$Res> {
  $MarketplaceStateCopyWith(
      MarketplaceState _, $Res Function(MarketplaceState) __);
}

/// @nodoc

class MarketplaceInitial implements MarketplaceState {
  const MarketplaceInitial();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is MarketplaceInitial);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'MarketplaceState.initial()';
  }
}

/// @nodoc

class MarketplaceLoading implements MarketplaceState {
  const MarketplaceLoading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is MarketplaceLoading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'MarketplaceState.loading()';
  }
}

/// @nodoc

class MarketplaceLoaded implements MarketplaceState {
  const MarketplaceLoaded(
      {required this.marketplace,
      required final List<MarketplacePlugin> filteredPlugins,
      required final List<QueuedPlugin> queue,
      required this.searchQuery,
      this.selectedCategory,
      this.selectedType,
      required this.showFeaturedOnly,
      required this.showVerifiedOnly})
      : _filteredPlugins = filteredPlugins,
        _queue = queue;

  final Marketplace marketplace;
  final List<MarketplacePlugin> _filteredPlugins;
  List<MarketplacePlugin> get filteredPlugins {
    if (_filteredPlugins is EqualUnmodifiableListView) return _filteredPlugins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_filteredPlugins);
  }

  final List<QueuedPlugin> _queue;
  List<QueuedPlugin> get queue {
    if (_queue is EqualUnmodifiableListView) return _queue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_queue);
  }

  final String searchQuery;
  final String? selectedCategory;
  final MarketplacePluginType? selectedType;
  final bool showFeaturedOnly;
  final bool showVerifiedOnly;

  /// Create a copy of MarketplaceState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MarketplaceLoadedCopyWith<MarketplaceLoaded> get copyWith =>
      _$MarketplaceLoadedCopyWithImpl<MarketplaceLoaded>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MarketplaceLoaded &&
            (identical(other.marketplace, marketplace) ||
                other.marketplace == marketplace) &&
            const DeepCollectionEquality()
                .equals(other._filteredPlugins, _filteredPlugins) &&
            const DeepCollectionEquality().equals(other._queue, _queue) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.selectedCategory, selectedCategory) ||
                other.selectedCategory == selectedCategory) &&
            (identical(other.selectedType, selectedType) ||
                other.selectedType == selectedType) &&
            (identical(other.showFeaturedOnly, showFeaturedOnly) ||
                other.showFeaturedOnly == showFeaturedOnly) &&
            (identical(other.showVerifiedOnly, showVerifiedOnly) ||
                other.showVerifiedOnly == showVerifiedOnly));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      marketplace,
      const DeepCollectionEquality().hash(_filteredPlugins),
      const DeepCollectionEquality().hash(_queue),
      searchQuery,
      selectedCategory,
      selectedType,
      showFeaturedOnly,
      showVerifiedOnly);

  @override
  String toString() {
    return 'MarketplaceState.loaded(marketplace: $marketplace, filteredPlugins: $filteredPlugins, queue: $queue, searchQuery: $searchQuery, selectedCategory: $selectedCategory, selectedType: $selectedType, showFeaturedOnly: $showFeaturedOnly, showVerifiedOnly: $showVerifiedOnly)';
  }
}

/// @nodoc
abstract mixin class $MarketplaceLoadedCopyWith<$Res>
    implements $MarketplaceStateCopyWith<$Res> {
  factory $MarketplaceLoadedCopyWith(
          MarketplaceLoaded value, $Res Function(MarketplaceLoaded) _then) =
      _$MarketplaceLoadedCopyWithImpl;
  @useResult
  $Res call(
      {Marketplace marketplace,
      List<MarketplacePlugin> filteredPlugins,
      List<QueuedPlugin> queue,
      String searchQuery,
      String? selectedCategory,
      MarketplacePluginType? selectedType,
      bool showFeaturedOnly,
      bool showVerifiedOnly});

  $MarketplaceCopyWith<$Res> get marketplace;
}

/// @nodoc
class _$MarketplaceLoadedCopyWithImpl<$Res>
    implements $MarketplaceLoadedCopyWith<$Res> {
  _$MarketplaceLoadedCopyWithImpl(this._self, this._then);

  final MarketplaceLoaded _self;
  final $Res Function(MarketplaceLoaded) _then;

  /// Create a copy of MarketplaceState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? marketplace = null,
    Object? filteredPlugins = null,
    Object? queue = null,
    Object? searchQuery = null,
    Object? selectedCategory = freezed,
    Object? selectedType = freezed,
    Object? showFeaturedOnly = null,
    Object? showVerifiedOnly = null,
  }) {
    return _then(MarketplaceLoaded(
      marketplace: null == marketplace
          ? _self.marketplace
          : marketplace // ignore: cast_nullable_to_non_nullable
              as Marketplace,
      filteredPlugins: null == filteredPlugins
          ? _self._filteredPlugins
          : filteredPlugins // ignore: cast_nullable_to_non_nullable
              as List<MarketplacePlugin>,
      queue: null == queue
          ? _self._queue
          : queue // ignore: cast_nullable_to_non_nullable
              as List<QueuedPlugin>,
      searchQuery: null == searchQuery
          ? _self.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
      selectedCategory: freezed == selectedCategory
          ? _self.selectedCategory
          : selectedCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedType: freezed == selectedType
          ? _self.selectedType
          : selectedType // ignore: cast_nullable_to_non_nullable
              as MarketplacePluginType?,
      showFeaturedOnly: null == showFeaturedOnly
          ? _self.showFeaturedOnly
          : showFeaturedOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      showVerifiedOnly: null == showVerifiedOnly
          ? _self.showVerifiedOnly
          : showVerifiedOnly // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of MarketplaceState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MarketplaceCopyWith<$Res> get marketplace {
    return $MarketplaceCopyWith<$Res>(_self.marketplace, (value) {
      return _then(_self.copyWith(marketplace: value));
    });
  }
}

/// @nodoc

class MarketplaceError implements MarketplaceState {
  const MarketplaceError(this.message);

  final String message;

  /// Create a copy of MarketplaceState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MarketplaceErrorCopyWith<MarketplaceError> get copyWith =>
      _$MarketplaceErrorCopyWithImpl<MarketplaceError>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MarketplaceError &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'MarketplaceState.error(message: $message)';
  }
}

/// @nodoc
abstract mixin class $MarketplaceErrorCopyWith<$Res>
    implements $MarketplaceStateCopyWith<$Res> {
  factory $MarketplaceErrorCopyWith(
          MarketplaceError value, $Res Function(MarketplaceError) _then) =
      _$MarketplaceErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$MarketplaceErrorCopyWithImpl<$Res>
    implements $MarketplaceErrorCopyWith<$Res> {
  _$MarketplaceErrorCopyWithImpl(this._self, this._then);

  final MarketplaceError _self;
  final $Res Function(MarketplaceError) _then;

  /// Create a copy of MarketplaceState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(MarketplaceError(
      null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
