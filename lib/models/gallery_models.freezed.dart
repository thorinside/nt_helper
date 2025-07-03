// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gallery_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GalleryMetadata {
  String get name;
  String get description;
  GalleryMaintainer get maintainer;

  /// Create a copy of GalleryMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GalleryMetadataCopyWith<GalleryMetadata> get copyWith =>
      _$GalleryMetadataCopyWithImpl<GalleryMetadata>(
          this as GalleryMetadata, _$identity);

  /// Serializes this GalleryMetadata to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GalleryMetadata &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.maintainer, maintainer) ||
                other.maintainer == maintainer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, description, maintainer);

  @override
  String toString() {
    return 'GalleryMetadata(name: $name, description: $description, maintainer: $maintainer)';
  }
}

/// @nodoc
abstract mixin class $GalleryMetadataCopyWith<$Res> {
  factory $GalleryMetadataCopyWith(
          GalleryMetadata value, $Res Function(GalleryMetadata) _then) =
      _$GalleryMetadataCopyWithImpl;
  @useResult
  $Res call({String name, String description, GalleryMaintainer maintainer});

  $GalleryMaintainerCopyWith<$Res> get maintainer;
}

/// @nodoc
class _$GalleryMetadataCopyWithImpl<$Res>
    implements $GalleryMetadataCopyWith<$Res> {
  _$GalleryMetadataCopyWithImpl(this._self, this._then);

  final GalleryMetadata _self;
  final $Res Function(GalleryMetadata) _then;

  /// Create a copy of GalleryMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? maintainer = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      maintainer: null == maintainer
          ? _self.maintainer
          : maintainer // ignore: cast_nullable_to_non_nullable
              as GalleryMaintainer,
    ));
  }

  /// Create a copy of GalleryMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GalleryMaintainerCopyWith<$Res> get maintainer {
    return $GalleryMaintainerCopyWith<$Res>(_self.maintainer, (value) {
      return _then(_self.copyWith(maintainer: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _GalleryMetadata implements GalleryMetadata {
  const _GalleryMetadata(
      {required this.name,
      required this.description,
      required this.maintainer});
  factory _GalleryMetadata.fromJson(Map<String, dynamic> json) =>
      _$GalleryMetadataFromJson(json);

  @override
  final String name;
  @override
  final String description;
  @override
  final GalleryMaintainer maintainer;

  /// Create a copy of GalleryMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GalleryMetadataCopyWith<_GalleryMetadata> get copyWith =>
      __$GalleryMetadataCopyWithImpl<_GalleryMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GalleryMetadataToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GalleryMetadata &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.maintainer, maintainer) ||
                other.maintainer == maintainer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, description, maintainer);

  @override
  String toString() {
    return 'GalleryMetadata(name: $name, description: $description, maintainer: $maintainer)';
  }
}

/// @nodoc
abstract mixin class _$GalleryMetadataCopyWith<$Res>
    implements $GalleryMetadataCopyWith<$Res> {
  factory _$GalleryMetadataCopyWith(
          _GalleryMetadata value, $Res Function(_GalleryMetadata) _then) =
      __$GalleryMetadataCopyWithImpl;
  @override
  @useResult
  $Res call({String name, String description, GalleryMaintainer maintainer});

  @override
  $GalleryMaintainerCopyWith<$Res> get maintainer;
}

/// @nodoc
class __$GalleryMetadataCopyWithImpl<$Res>
    implements _$GalleryMetadataCopyWith<$Res> {
  __$GalleryMetadataCopyWithImpl(this._self, this._then);

  final _GalleryMetadata _self;
  final $Res Function(_GalleryMetadata) _then;

  /// Create a copy of GalleryMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? maintainer = null,
  }) {
    return _then(_GalleryMetadata(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      maintainer: null == maintainer
          ? _self.maintainer
          : maintainer // ignore: cast_nullable_to_non_nullable
              as GalleryMaintainer,
    ));
  }

  /// Create a copy of GalleryMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GalleryMaintainerCopyWith<$Res> get maintainer {
    return $GalleryMaintainerCopyWith<$Res>(_self.maintainer, (value) {
      return _then(_self.copyWith(maintainer: value));
    });
  }
}

/// @nodoc
mixin _$GalleryMaintainer {
  String get name;
  String? get email;
  String? get url;

  /// Create a copy of GalleryMaintainer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GalleryMaintainerCopyWith<GalleryMaintainer> get copyWith =>
      _$GalleryMaintainerCopyWithImpl<GalleryMaintainer>(
          this as GalleryMaintainer, _$identity);

  /// Serializes this GalleryMaintainer to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GalleryMaintainer &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, email, url);

  @override
  String toString() {
    return 'GalleryMaintainer(name: $name, email: $email, url: $url)';
  }
}

/// @nodoc
abstract mixin class $GalleryMaintainerCopyWith<$Res> {
  factory $GalleryMaintainerCopyWith(
          GalleryMaintainer value, $Res Function(GalleryMaintainer) _then) =
      _$GalleryMaintainerCopyWithImpl;
  @useResult
  $Res call({String name, String? email, String? url});
}

/// @nodoc
class _$GalleryMaintainerCopyWithImpl<$Res>
    implements $GalleryMaintainerCopyWith<$Res> {
  _$GalleryMaintainerCopyWithImpl(this._self, this._then);

  final GalleryMaintainer _self;
  final $Res Function(GalleryMaintainer) _then;

  /// Create a copy of GalleryMaintainer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? email = freezed,
    Object? url = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _GalleryMaintainer implements GalleryMaintainer {
  const _GalleryMaintainer({required this.name, this.email, this.url});
  factory _GalleryMaintainer.fromJson(Map<String, dynamic> json) =>
      _$GalleryMaintainerFromJson(json);

  @override
  final String name;
  @override
  final String? email;
  @override
  final String? url;

  /// Create a copy of GalleryMaintainer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GalleryMaintainerCopyWith<_GalleryMaintainer> get copyWith =>
      __$GalleryMaintainerCopyWithImpl<_GalleryMaintainer>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GalleryMaintainerToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GalleryMaintainer &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, email, url);

  @override
  String toString() {
    return 'GalleryMaintainer(name: $name, email: $email, url: $url)';
  }
}

/// @nodoc
abstract mixin class _$GalleryMaintainerCopyWith<$Res>
    implements $GalleryMaintainerCopyWith<$Res> {
  factory _$GalleryMaintainerCopyWith(
          _GalleryMaintainer value, $Res Function(_GalleryMaintainer) _then) =
      __$GalleryMaintainerCopyWithImpl;
  @override
  @useResult
  $Res call({String name, String? email, String? url});
}

/// @nodoc
class __$GalleryMaintainerCopyWithImpl<$Res>
    implements _$GalleryMaintainerCopyWith<$Res> {
  __$GalleryMaintainerCopyWithImpl(this._self, this._then);

  final _GalleryMaintainer _self;
  final $Res Function(_GalleryMaintainer) _then;

  /// Create a copy of GalleryMaintainer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? email = freezed,
    Object? url = freezed,
  }) {
    return _then(_GalleryMaintainer(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$PluginCategory {
  String get id;
  String get name;
  String? get description;
  String? get icon;

  /// Create a copy of PluginCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PluginCategoryCopyWith<PluginCategory> get copyWith =>
      _$PluginCategoryCopyWithImpl<PluginCategory>(
          this as PluginCategory, _$identity);

  /// Serializes this PluginCategory to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PluginCategory &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description, icon);

  @override
  String toString() {
    return 'PluginCategory(id: $id, name: $name, description: $description, icon: $icon)';
  }
}

/// @nodoc
abstract mixin class $PluginCategoryCopyWith<$Res> {
  factory $PluginCategoryCopyWith(
          PluginCategory value, $Res Function(PluginCategory) _then) =
      _$PluginCategoryCopyWithImpl;
  @useResult
  $Res call({String id, String name, String? description, String? icon});
}

/// @nodoc
class _$PluginCategoryCopyWithImpl<$Res>
    implements $PluginCategoryCopyWith<$Res> {
  _$PluginCategoryCopyWithImpl(this._self, this._then);

  final PluginCategory _self;
  final $Res Function(PluginCategory) _then;

  /// Create a copy of PluginCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? icon = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      icon: freezed == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PluginCategory implements PluginCategory {
  const _PluginCategory(
      {required this.id, required this.name, this.description, this.icon});
  factory _PluginCategory.fromJson(Map<String, dynamic> json) =>
      _$PluginCategoryFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? icon;

  /// Create a copy of PluginCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PluginCategoryCopyWith<_PluginCategory> get copyWith =>
      __$PluginCategoryCopyWithImpl<_PluginCategory>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PluginCategoryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PluginCategory &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, description, icon);

  @override
  String toString() {
    return 'PluginCategory(id: $id, name: $name, description: $description, icon: $icon)';
  }
}

/// @nodoc
abstract mixin class _$PluginCategoryCopyWith<$Res>
    implements $PluginCategoryCopyWith<$Res> {
  factory _$PluginCategoryCopyWith(
          _PluginCategory value, $Res Function(_PluginCategory) _then) =
      __$PluginCategoryCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String name, String? description, String? icon});
}

/// @nodoc
class __$PluginCategoryCopyWithImpl<$Res>
    implements _$PluginCategoryCopyWith<$Res> {
  __$PluginCategoryCopyWithImpl(this._self, this._then);

  final _PluginCategory _self;
  final $Res Function(_PluginCategory) _then;

  /// Create a copy of PluginCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? icon = freezed,
  }) {
    return _then(_PluginCategory(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      icon: freezed == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$PluginAuthor {
  String get name;
  String? get bio;
  String? get website;
  String? get avatar;
  bool get verified;
  PluginAuthorSocialLinks? get socialLinks;

  /// Create a copy of PluginAuthor
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PluginAuthorCopyWith<PluginAuthor> get copyWith =>
      _$PluginAuthorCopyWithImpl<PluginAuthor>(
          this as PluginAuthor, _$identity);

  /// Serializes this PluginAuthor to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PluginAuthor &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.socialLinks, socialLinks) ||
                other.socialLinks == socialLinks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, bio, website, avatar, verified, socialLinks);

  @override
  String toString() {
    return 'PluginAuthor(name: $name, bio: $bio, website: $website, avatar: $avatar, verified: $verified, socialLinks: $socialLinks)';
  }
}

/// @nodoc
abstract mixin class $PluginAuthorCopyWith<$Res> {
  factory $PluginAuthorCopyWith(
          PluginAuthor value, $Res Function(PluginAuthor) _then) =
      _$PluginAuthorCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      String? bio,
      String? website,
      String? avatar,
      bool verified,
      PluginAuthorSocialLinks? socialLinks});

  $PluginAuthorSocialLinksCopyWith<$Res>? get socialLinks;
}

/// @nodoc
class _$PluginAuthorCopyWithImpl<$Res> implements $PluginAuthorCopyWith<$Res> {
  _$PluginAuthorCopyWithImpl(this._self, this._then);

  final PluginAuthor _self;
  final $Res Function(PluginAuthor) _then;

  /// Create a copy of PluginAuthor
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? bio = freezed,
    Object? website = freezed,
    Object? avatar = freezed,
    Object? verified = null,
    Object? socialLinks = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      bio: freezed == bio
          ? _self.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      website: freezed == website
          ? _self.website
          : website // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _self.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      verified: null == verified
          ? _self.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      socialLinks: freezed == socialLinks
          ? _self.socialLinks
          : socialLinks // ignore: cast_nullable_to_non_nullable
              as PluginAuthorSocialLinks?,
    ));
  }

  /// Create a copy of PluginAuthor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginAuthorSocialLinksCopyWith<$Res>? get socialLinks {
    if (_self.socialLinks == null) {
      return null;
    }

    return $PluginAuthorSocialLinksCopyWith<$Res>(_self.socialLinks!, (value) {
      return _then(_self.copyWith(socialLinks: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _PluginAuthor implements PluginAuthor {
  const _PluginAuthor(
      {required this.name,
      this.bio,
      this.website,
      this.avatar,
      this.verified = false,
      this.socialLinks});
  factory _PluginAuthor.fromJson(Map<String, dynamic> json) =>
      _$PluginAuthorFromJson(json);

  @override
  final String name;
  @override
  final String? bio;
  @override
  final String? website;
  @override
  final String? avatar;
  @override
  @JsonKey()
  final bool verified;
  @override
  final PluginAuthorSocialLinks? socialLinks;

  /// Create a copy of PluginAuthor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PluginAuthorCopyWith<_PluginAuthor> get copyWith =>
      __$PluginAuthorCopyWithImpl<_PluginAuthor>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PluginAuthorToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PluginAuthor &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.socialLinks, socialLinks) ||
                other.socialLinks == socialLinks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, bio, website, avatar, verified, socialLinks);

  @override
  String toString() {
    return 'PluginAuthor(name: $name, bio: $bio, website: $website, avatar: $avatar, verified: $verified, socialLinks: $socialLinks)';
  }
}

/// @nodoc
abstract mixin class _$PluginAuthorCopyWith<$Res>
    implements $PluginAuthorCopyWith<$Res> {
  factory _$PluginAuthorCopyWith(
          _PluginAuthor value, $Res Function(_PluginAuthor) _then) =
      __$PluginAuthorCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      String? bio,
      String? website,
      String? avatar,
      bool verified,
      PluginAuthorSocialLinks? socialLinks});

  @override
  $PluginAuthorSocialLinksCopyWith<$Res>? get socialLinks;
}

/// @nodoc
class __$PluginAuthorCopyWithImpl<$Res>
    implements _$PluginAuthorCopyWith<$Res> {
  __$PluginAuthorCopyWithImpl(this._self, this._then);

  final _PluginAuthor _self;
  final $Res Function(_PluginAuthor) _then;

  /// Create a copy of PluginAuthor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? bio = freezed,
    Object? website = freezed,
    Object? avatar = freezed,
    Object? verified = null,
    Object? socialLinks = freezed,
  }) {
    return _then(_PluginAuthor(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      bio: freezed == bio
          ? _self.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      website: freezed == website
          ? _self.website
          : website // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _self.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      verified: null == verified
          ? _self.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      socialLinks: freezed == socialLinks
          ? _self.socialLinks
          : socialLinks // ignore: cast_nullable_to_non_nullable
              as PluginAuthorSocialLinks?,
    ));
  }

  /// Create a copy of PluginAuthor
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginAuthorSocialLinksCopyWith<$Res>? get socialLinks {
    if (_self.socialLinks == null) {
      return null;
    }

    return $PluginAuthorSocialLinksCopyWith<$Res>(_self.socialLinks!, (value) {
      return _then(_self.copyWith(socialLinks: value));
    });
  }
}

/// @nodoc
mixin _$PluginAuthorSocialLinks {
  String? get github;
  String? get twitter;
  String? get discord;

  /// Create a copy of PluginAuthorSocialLinks
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PluginAuthorSocialLinksCopyWith<PluginAuthorSocialLinks> get copyWith =>
      _$PluginAuthorSocialLinksCopyWithImpl<PluginAuthorSocialLinks>(
          this as PluginAuthorSocialLinks, _$identity);

  /// Serializes this PluginAuthorSocialLinks to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PluginAuthorSocialLinks &&
            (identical(other.github, github) || other.github == github) &&
            (identical(other.twitter, twitter) || other.twitter == twitter) &&
            (identical(other.discord, discord) || other.discord == discord));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, github, twitter, discord);

  @override
  String toString() {
    return 'PluginAuthorSocialLinks(github: $github, twitter: $twitter, discord: $discord)';
  }
}

/// @nodoc
abstract mixin class $PluginAuthorSocialLinksCopyWith<$Res> {
  factory $PluginAuthorSocialLinksCopyWith(PluginAuthorSocialLinks value,
          $Res Function(PluginAuthorSocialLinks) _then) =
      _$PluginAuthorSocialLinksCopyWithImpl;
  @useResult
  $Res call({String? github, String? twitter, String? discord});
}

/// @nodoc
class _$PluginAuthorSocialLinksCopyWithImpl<$Res>
    implements $PluginAuthorSocialLinksCopyWith<$Res> {
  _$PluginAuthorSocialLinksCopyWithImpl(this._self, this._then);

  final PluginAuthorSocialLinks _self;
  final $Res Function(PluginAuthorSocialLinks) _then;

  /// Create a copy of PluginAuthorSocialLinks
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? github = freezed,
    Object? twitter = freezed,
    Object? discord = freezed,
  }) {
    return _then(_self.copyWith(
      github: freezed == github
          ? _self.github
          : github // ignore: cast_nullable_to_non_nullable
              as String?,
      twitter: freezed == twitter
          ? _self.twitter
          : twitter // ignore: cast_nullable_to_non_nullable
              as String?,
      discord: freezed == discord
          ? _self.discord
          : discord // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PluginAuthorSocialLinks implements PluginAuthorSocialLinks {
  const _PluginAuthorSocialLinks({this.github, this.twitter, this.discord});
  factory _PluginAuthorSocialLinks.fromJson(Map<String, dynamic> json) =>
      _$PluginAuthorSocialLinksFromJson(json);

  @override
  final String? github;
  @override
  final String? twitter;
  @override
  final String? discord;

  /// Create a copy of PluginAuthorSocialLinks
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PluginAuthorSocialLinksCopyWith<_PluginAuthorSocialLinks> get copyWith =>
      __$PluginAuthorSocialLinksCopyWithImpl<_PluginAuthorSocialLinks>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PluginAuthorSocialLinksToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PluginAuthorSocialLinks &&
            (identical(other.github, github) || other.github == github) &&
            (identical(other.twitter, twitter) || other.twitter == twitter) &&
            (identical(other.discord, discord) || other.discord == discord));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, github, twitter, discord);

  @override
  String toString() {
    return 'PluginAuthorSocialLinks(github: $github, twitter: $twitter, discord: $discord)';
  }
}

/// @nodoc
abstract mixin class _$PluginAuthorSocialLinksCopyWith<$Res>
    implements $PluginAuthorSocialLinksCopyWith<$Res> {
  factory _$PluginAuthorSocialLinksCopyWith(_PluginAuthorSocialLinks value,
          $Res Function(_PluginAuthorSocialLinks) _then) =
      __$PluginAuthorSocialLinksCopyWithImpl;
  @override
  @useResult
  $Res call({String? github, String? twitter, String? discord});
}

/// @nodoc
class __$PluginAuthorSocialLinksCopyWithImpl<$Res>
    implements _$PluginAuthorSocialLinksCopyWith<$Res> {
  __$PluginAuthorSocialLinksCopyWithImpl(this._self, this._then);

  final _PluginAuthorSocialLinks _self;
  final $Res Function(_PluginAuthorSocialLinks) _then;

  /// Create a copy of PluginAuthorSocialLinks
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? github = freezed,
    Object? twitter = freezed,
    Object? discord = freezed,
  }) {
    return _then(_PluginAuthorSocialLinks(
      github: freezed == github
          ? _self.github
          : github // ignore: cast_nullable_to_non_nullable
              as String?,
      twitter: freezed == twitter
          ? _self.twitter
          : twitter // ignore: cast_nullable_to_non_nullable
              as String?,
      discord: freezed == discord
          ? _self.discord
          : discord // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$PluginRepository {
  String get owner;
  String get name;
  String get url;
  String? get branch;

  /// Create a copy of PluginRepository
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PluginRepositoryCopyWith<PluginRepository> get copyWith =>
      _$PluginRepositoryCopyWithImpl<PluginRepository>(
          this as PluginRepository, _$identity);

  /// Serializes this PluginRepository to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PluginRepository &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.branch, branch) || other.branch == branch));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, owner, name, url, branch);

  @override
  String toString() {
    return 'PluginRepository(owner: $owner, name: $name, url: $url, branch: $branch)';
  }
}

/// @nodoc
abstract mixin class $PluginRepositoryCopyWith<$Res> {
  factory $PluginRepositoryCopyWith(
          PluginRepository value, $Res Function(PluginRepository) _then) =
      _$PluginRepositoryCopyWithImpl;
  @useResult
  $Res call({String owner, String name, String url, String? branch});
}

/// @nodoc
class _$PluginRepositoryCopyWithImpl<$Res>
    implements $PluginRepositoryCopyWith<$Res> {
  _$PluginRepositoryCopyWithImpl(this._self, this._then);

  final PluginRepository _self;
  final $Res Function(PluginRepository) _then;

  /// Create a copy of PluginRepository
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? owner = null,
    Object? name = null,
    Object? url = null,
    Object? branch = freezed,
  }) {
    return _then(_self.copyWith(
      owner: null == owner
          ? _self.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      branch: freezed == branch
          ? _self.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PluginRepository implements PluginRepository {
  const _PluginRepository(
      {required this.owner,
      required this.name,
      required this.url,
      this.branch});
  factory _PluginRepository.fromJson(Map<String, dynamic> json) =>
      _$PluginRepositoryFromJson(json);

  @override
  final String owner;
  @override
  final String name;
  @override
  final String url;
  @override
  final String? branch;

  /// Create a copy of PluginRepository
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PluginRepositoryCopyWith<_PluginRepository> get copyWith =>
      __$PluginRepositoryCopyWithImpl<_PluginRepository>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PluginRepositoryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PluginRepository &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.branch, branch) || other.branch == branch));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, owner, name, url, branch);

  @override
  String toString() {
    return 'PluginRepository(owner: $owner, name: $name, url: $url, branch: $branch)';
  }
}

/// @nodoc
abstract mixin class _$PluginRepositoryCopyWith<$Res>
    implements $PluginRepositoryCopyWith<$Res> {
  factory _$PluginRepositoryCopyWith(
          _PluginRepository value, $Res Function(_PluginRepository) _then) =
      __$PluginRepositoryCopyWithImpl;
  @override
  @useResult
  $Res call({String owner, String name, String url, String? branch});
}

/// @nodoc
class __$PluginRepositoryCopyWithImpl<$Res>
    implements _$PluginRepositoryCopyWith<$Res> {
  __$PluginRepositoryCopyWithImpl(this._self, this._then);

  final _PluginRepository _self;
  final $Res Function(_PluginRepository) _then;

  /// Create a copy of PluginRepository
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? owner = null,
    Object? name = null,
    Object? url = null,
    Object? branch = freezed,
  }) {
    return _then(_PluginRepository(
      owner: null == owner
          ? _self.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      branch: freezed == branch
          ? _self.branch
          : branch // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$PluginReleases {
  String get latest;
  String? get stable;
  String? get beta;

  /// Create a copy of PluginReleases
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PluginReleasesCopyWith<PluginReleases> get copyWith =>
      _$PluginReleasesCopyWithImpl<PluginReleases>(
          this as PluginReleases, _$identity);

  /// Serializes this PluginReleases to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PluginReleases &&
            (identical(other.latest, latest) || other.latest == latest) &&
            (identical(other.stable, stable) || other.stable == stable) &&
            (identical(other.beta, beta) || other.beta == beta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, latest, stable, beta);

  @override
  String toString() {
    return 'PluginReleases(latest: $latest, stable: $stable, beta: $beta)';
  }
}

/// @nodoc
abstract mixin class $PluginReleasesCopyWith<$Res> {
  factory $PluginReleasesCopyWith(
          PluginReleases value, $Res Function(PluginReleases) _then) =
      _$PluginReleasesCopyWithImpl;
  @useResult
  $Res call({String latest, String? stable, String? beta});
}

/// @nodoc
class _$PluginReleasesCopyWithImpl<$Res>
    implements $PluginReleasesCopyWith<$Res> {
  _$PluginReleasesCopyWithImpl(this._self, this._then);

  final PluginReleases _self;
  final $Res Function(PluginReleases) _then;

  /// Create a copy of PluginReleases
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latest = null,
    Object? stable = freezed,
    Object? beta = freezed,
  }) {
    return _then(_self.copyWith(
      latest: null == latest
          ? _self.latest
          : latest // ignore: cast_nullable_to_non_nullable
              as String,
      stable: freezed == stable
          ? _self.stable
          : stable // ignore: cast_nullable_to_non_nullable
              as String?,
      beta: freezed == beta
          ? _self.beta
          : beta // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PluginReleases implements PluginReleases {
  const _PluginReleases({required this.latest, this.stable, this.beta});
  factory _PluginReleases.fromJson(Map<String, dynamic> json) =>
      _$PluginReleasesFromJson(json);

  @override
  final String latest;
  @override
  final String? stable;
  @override
  final String? beta;

  /// Create a copy of PluginReleases
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PluginReleasesCopyWith<_PluginReleases> get copyWith =>
      __$PluginReleasesCopyWithImpl<_PluginReleases>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PluginReleasesToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PluginReleases &&
            (identical(other.latest, latest) || other.latest == latest) &&
            (identical(other.stable, stable) || other.stable == stable) &&
            (identical(other.beta, beta) || other.beta == beta));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, latest, stable, beta);

  @override
  String toString() {
    return 'PluginReleases(latest: $latest, stable: $stable, beta: $beta)';
  }
}

/// @nodoc
abstract mixin class _$PluginReleasesCopyWith<$Res>
    implements $PluginReleasesCopyWith<$Res> {
  factory _$PluginReleasesCopyWith(
          _PluginReleases value, $Res Function(_PluginReleases) _then) =
      __$PluginReleasesCopyWithImpl;
  @override
  @useResult
  $Res call({String latest, String? stable, String? beta});
}

/// @nodoc
class __$PluginReleasesCopyWithImpl<$Res>
    implements _$PluginReleasesCopyWith<$Res> {
  __$PluginReleasesCopyWithImpl(this._self, this._then);

  final _PluginReleases _self;
  final $Res Function(_PluginReleases) _then;

  /// Create a copy of PluginReleases
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? latest = null,
    Object? stable = freezed,
    Object? beta = freezed,
  }) {
    return _then(_PluginReleases(
      latest: null == latest
          ? _self.latest
          : latest // ignore: cast_nullable_to_non_nullable
              as String,
      stable: freezed == stable
          ? _self.stable
          : stable // ignore: cast_nullable_to_non_nullable
              as String?,
      beta: freezed == beta
          ? _self.beta
          : beta // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$PluginInstallation {
  String get targetPath;
  String? get subdirectory;
  String? get assetPattern;
  String? get extractPattern;
  String? get downloadUrl; // For directory-based installations
  bool get preserveDirectoryStructure;
  String? get sourceDirectoryPath;

  /// Create a copy of PluginInstallation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PluginInstallationCopyWith<PluginInstallation> get copyWith =>
      _$PluginInstallationCopyWithImpl<PluginInstallation>(
          this as PluginInstallation, _$identity);

  /// Serializes this PluginInstallation to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PluginInstallation &&
            (identical(other.targetPath, targetPath) ||
                other.targetPath == targetPath) &&
            (identical(other.subdirectory, subdirectory) ||
                other.subdirectory == subdirectory) &&
            (identical(other.assetPattern, assetPattern) ||
                other.assetPattern == assetPattern) &&
            (identical(other.extractPattern, extractPattern) ||
                other.extractPattern == extractPattern) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            (identical(other.preserveDirectoryStructure,
                    preserveDirectoryStructure) ||
                other.preserveDirectoryStructure ==
                    preserveDirectoryStructure) &&
            (identical(other.sourceDirectoryPath, sourceDirectoryPath) ||
                other.sourceDirectoryPath == sourceDirectoryPath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      targetPath,
      subdirectory,
      assetPattern,
      extractPattern,
      downloadUrl,
      preserveDirectoryStructure,
      sourceDirectoryPath);

  @override
  String toString() {
    return 'PluginInstallation(targetPath: $targetPath, subdirectory: $subdirectory, assetPattern: $assetPattern, extractPattern: $extractPattern, downloadUrl: $downloadUrl, preserveDirectoryStructure: $preserveDirectoryStructure, sourceDirectoryPath: $sourceDirectoryPath)';
  }
}

/// @nodoc
abstract mixin class $PluginInstallationCopyWith<$Res> {
  factory $PluginInstallationCopyWith(
          PluginInstallation value, $Res Function(PluginInstallation) _then) =
      _$PluginInstallationCopyWithImpl;
  @useResult
  $Res call(
      {String targetPath,
      String? subdirectory,
      String? assetPattern,
      String? extractPattern,
      String? downloadUrl,
      bool preserveDirectoryStructure,
      String? sourceDirectoryPath});
}

/// @nodoc
class _$PluginInstallationCopyWithImpl<$Res>
    implements $PluginInstallationCopyWith<$Res> {
  _$PluginInstallationCopyWithImpl(this._self, this._then);

  final PluginInstallation _self;
  final $Res Function(PluginInstallation) _then;

  /// Create a copy of PluginInstallation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetPath = null,
    Object? subdirectory = freezed,
    Object? assetPattern = freezed,
    Object? extractPattern = freezed,
    Object? downloadUrl = freezed,
    Object? preserveDirectoryStructure = null,
    Object? sourceDirectoryPath = freezed,
  }) {
    return _then(_self.copyWith(
      targetPath: null == targetPath
          ? _self.targetPath
          : targetPath // ignore: cast_nullable_to_non_nullable
              as String,
      subdirectory: freezed == subdirectory
          ? _self.subdirectory
          : subdirectory // ignore: cast_nullable_to_non_nullable
              as String?,
      assetPattern: freezed == assetPattern
          ? _self.assetPattern
          : assetPattern // ignore: cast_nullable_to_non_nullable
              as String?,
      extractPattern: freezed == extractPattern
          ? _self.extractPattern
          : extractPattern // ignore: cast_nullable_to_non_nullable
              as String?,
      downloadUrl: freezed == downloadUrl
          ? _self.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      preserveDirectoryStructure: null == preserveDirectoryStructure
          ? _self.preserveDirectoryStructure
          : preserveDirectoryStructure // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceDirectoryPath: freezed == sourceDirectoryPath
          ? _self.sourceDirectoryPath
          : sourceDirectoryPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PluginInstallation implements PluginInstallation {
  const _PluginInstallation(
      {required this.targetPath,
      this.subdirectory,
      this.assetPattern,
      this.extractPattern,
      this.downloadUrl,
      this.preserveDirectoryStructure = false,
      this.sourceDirectoryPath});
  factory _PluginInstallation.fromJson(Map<String, dynamic> json) =>
      _$PluginInstallationFromJson(json);

  @override
  final String targetPath;
  @override
  final String? subdirectory;
  @override
  final String? assetPattern;
  @override
  final String? extractPattern;
  @override
  final String? downloadUrl;
// For directory-based installations
  @override
  @JsonKey()
  final bool preserveDirectoryStructure;
  @override
  final String? sourceDirectoryPath;

  /// Create a copy of PluginInstallation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PluginInstallationCopyWith<_PluginInstallation> get copyWith =>
      __$PluginInstallationCopyWithImpl<_PluginInstallation>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PluginInstallationToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PluginInstallation &&
            (identical(other.targetPath, targetPath) ||
                other.targetPath == targetPath) &&
            (identical(other.subdirectory, subdirectory) ||
                other.subdirectory == subdirectory) &&
            (identical(other.assetPattern, assetPattern) ||
                other.assetPattern == assetPattern) &&
            (identical(other.extractPattern, extractPattern) ||
                other.extractPattern == extractPattern) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            (identical(other.preserveDirectoryStructure,
                    preserveDirectoryStructure) ||
                other.preserveDirectoryStructure ==
                    preserveDirectoryStructure) &&
            (identical(other.sourceDirectoryPath, sourceDirectoryPath) ||
                other.sourceDirectoryPath == sourceDirectoryPath));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      targetPath,
      subdirectory,
      assetPattern,
      extractPattern,
      downloadUrl,
      preserveDirectoryStructure,
      sourceDirectoryPath);

  @override
  String toString() {
    return 'PluginInstallation(targetPath: $targetPath, subdirectory: $subdirectory, assetPattern: $assetPattern, extractPattern: $extractPattern, downloadUrl: $downloadUrl, preserveDirectoryStructure: $preserveDirectoryStructure, sourceDirectoryPath: $sourceDirectoryPath)';
  }
}

/// @nodoc
abstract mixin class _$PluginInstallationCopyWith<$Res>
    implements $PluginInstallationCopyWith<$Res> {
  factory _$PluginInstallationCopyWith(
          _PluginInstallation value, $Res Function(_PluginInstallation) _then) =
      __$PluginInstallationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String targetPath,
      String? subdirectory,
      String? assetPattern,
      String? extractPattern,
      String? downloadUrl,
      bool preserveDirectoryStructure,
      String? sourceDirectoryPath});
}

/// @nodoc
class __$PluginInstallationCopyWithImpl<$Res>
    implements _$PluginInstallationCopyWith<$Res> {
  __$PluginInstallationCopyWithImpl(this._self, this._then);

  final _PluginInstallation _self;
  final $Res Function(_PluginInstallation) _then;

  /// Create a copy of PluginInstallation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? targetPath = null,
    Object? subdirectory = freezed,
    Object? assetPattern = freezed,
    Object? extractPattern = freezed,
    Object? downloadUrl = freezed,
    Object? preserveDirectoryStructure = null,
    Object? sourceDirectoryPath = freezed,
  }) {
    return _then(_PluginInstallation(
      targetPath: null == targetPath
          ? _self.targetPath
          : targetPath // ignore: cast_nullable_to_non_nullable
              as String,
      subdirectory: freezed == subdirectory
          ? _self.subdirectory
          : subdirectory // ignore: cast_nullable_to_non_nullable
              as String?,
      assetPattern: freezed == assetPattern
          ? _self.assetPattern
          : assetPattern // ignore: cast_nullable_to_non_nullable
              as String?,
      extractPattern: freezed == extractPattern
          ? _self.extractPattern
          : extractPattern // ignore: cast_nullable_to_non_nullable
              as String?,
      downloadUrl: freezed == downloadUrl
          ? _self.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      preserveDirectoryStructure: null == preserveDirectoryStructure
          ? _self.preserveDirectoryStructure
          : preserveDirectoryStructure // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceDirectoryPath: freezed == sourceDirectoryPath
          ? _self.sourceDirectoryPath
          : sourceDirectoryPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$PluginCompatibility {
  String? get minFirmwareVersion;
  String? get maxFirmwareVersion;
  List<String> get requiredFeatures;

  /// Create a copy of PluginCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PluginCompatibilityCopyWith<PluginCompatibility> get copyWith =>
      _$PluginCompatibilityCopyWithImpl<PluginCompatibility>(
          this as PluginCompatibility, _$identity);

  /// Serializes this PluginCompatibility to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PluginCompatibility &&
            (identical(other.minFirmwareVersion, minFirmwareVersion) ||
                other.minFirmwareVersion == minFirmwareVersion) &&
            (identical(other.maxFirmwareVersion, maxFirmwareVersion) ||
                other.maxFirmwareVersion == maxFirmwareVersion) &&
            const DeepCollectionEquality()
                .equals(other.requiredFeatures, requiredFeatures));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      minFirmwareVersion,
      maxFirmwareVersion,
      const DeepCollectionEquality().hash(requiredFeatures));

  @override
  String toString() {
    return 'PluginCompatibility(minFirmwareVersion: $minFirmwareVersion, maxFirmwareVersion: $maxFirmwareVersion, requiredFeatures: $requiredFeatures)';
  }
}

/// @nodoc
abstract mixin class $PluginCompatibilityCopyWith<$Res> {
  factory $PluginCompatibilityCopyWith(
          PluginCompatibility value, $Res Function(PluginCompatibility) _then) =
      _$PluginCompatibilityCopyWithImpl;
  @useResult
  $Res call(
      {String? minFirmwareVersion,
      String? maxFirmwareVersion,
      List<String> requiredFeatures});
}

/// @nodoc
class _$PluginCompatibilityCopyWithImpl<$Res>
    implements $PluginCompatibilityCopyWith<$Res> {
  _$PluginCompatibilityCopyWithImpl(this._self, this._then);

  final PluginCompatibility _self;
  final $Res Function(PluginCompatibility) _then;

  /// Create a copy of PluginCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minFirmwareVersion = freezed,
    Object? maxFirmwareVersion = freezed,
    Object? requiredFeatures = null,
  }) {
    return _then(_self.copyWith(
      minFirmwareVersion: freezed == minFirmwareVersion
          ? _self.minFirmwareVersion
          : minFirmwareVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      maxFirmwareVersion: freezed == maxFirmwareVersion
          ? _self.maxFirmwareVersion
          : maxFirmwareVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      requiredFeatures: null == requiredFeatures
          ? _self.requiredFeatures
          : requiredFeatures // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PluginCompatibility implements PluginCompatibility {
  const _PluginCompatibility(
      {this.minFirmwareVersion,
      this.maxFirmwareVersion,
      final List<String> requiredFeatures = const []})
      : _requiredFeatures = requiredFeatures;
  factory _PluginCompatibility.fromJson(Map<String, dynamic> json) =>
      _$PluginCompatibilityFromJson(json);

  @override
  final String? minFirmwareVersion;
  @override
  final String? maxFirmwareVersion;
  final List<String> _requiredFeatures;
  @override
  @JsonKey()
  List<String> get requiredFeatures {
    if (_requiredFeatures is EqualUnmodifiableListView)
      return _requiredFeatures;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredFeatures);
  }

  /// Create a copy of PluginCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PluginCompatibilityCopyWith<_PluginCompatibility> get copyWith =>
      __$PluginCompatibilityCopyWithImpl<_PluginCompatibility>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PluginCompatibilityToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PluginCompatibility &&
            (identical(other.minFirmwareVersion, minFirmwareVersion) ||
                other.minFirmwareVersion == minFirmwareVersion) &&
            (identical(other.maxFirmwareVersion, maxFirmwareVersion) ||
                other.maxFirmwareVersion == maxFirmwareVersion) &&
            const DeepCollectionEquality()
                .equals(other._requiredFeatures, _requiredFeatures));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      minFirmwareVersion,
      maxFirmwareVersion,
      const DeepCollectionEquality().hash(_requiredFeatures));

  @override
  String toString() {
    return 'PluginCompatibility(minFirmwareVersion: $minFirmwareVersion, maxFirmwareVersion: $maxFirmwareVersion, requiredFeatures: $requiredFeatures)';
  }
}

/// @nodoc
abstract mixin class _$PluginCompatibilityCopyWith<$Res>
    implements $PluginCompatibilityCopyWith<$Res> {
  factory _$PluginCompatibilityCopyWith(_PluginCompatibility value,
          $Res Function(_PluginCompatibility) _then) =
      __$PluginCompatibilityCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? minFirmwareVersion,
      String? maxFirmwareVersion,
      List<String> requiredFeatures});
}

/// @nodoc
class __$PluginCompatibilityCopyWithImpl<$Res>
    implements _$PluginCompatibilityCopyWith<$Res> {
  __$PluginCompatibilityCopyWithImpl(this._self, this._then);

  final _PluginCompatibility _self;
  final $Res Function(_PluginCompatibility) _then;

  /// Create a copy of PluginCompatibility
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? minFirmwareVersion = freezed,
    Object? maxFirmwareVersion = freezed,
    Object? requiredFeatures = null,
  }) {
    return _then(_PluginCompatibility(
      minFirmwareVersion: freezed == minFirmwareVersion
          ? _self.minFirmwareVersion
          : minFirmwareVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      maxFirmwareVersion: freezed == maxFirmwareVersion
          ? _self.maxFirmwareVersion
          : maxFirmwareVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      requiredFeatures: null == requiredFeatures
          ? _self._requiredFeatures
          : requiredFeatures // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
mixin _$PluginScreenshot {
  String get url;
  String? get caption;
  String? get thumbnail;

  /// Create a copy of PluginScreenshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PluginScreenshotCopyWith<PluginScreenshot> get copyWith =>
      _$PluginScreenshotCopyWithImpl<PluginScreenshot>(
          this as PluginScreenshot, _$identity);

  /// Serializes this PluginScreenshot to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PluginScreenshot &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, url, caption, thumbnail);

  @override
  String toString() {
    return 'PluginScreenshot(url: $url, caption: $caption, thumbnail: $thumbnail)';
  }
}

/// @nodoc
abstract mixin class $PluginScreenshotCopyWith<$Res> {
  factory $PluginScreenshotCopyWith(
          PluginScreenshot value, $Res Function(PluginScreenshot) _then) =
      _$PluginScreenshotCopyWithImpl;
  @useResult
  $Res call({String url, String? caption, String? thumbnail});
}

/// @nodoc
class _$PluginScreenshotCopyWithImpl<$Res>
    implements $PluginScreenshotCopyWith<$Res> {
  _$PluginScreenshotCopyWithImpl(this._self, this._then);

  final PluginScreenshot _self;
  final $Res Function(PluginScreenshot) _then;

  /// Create a copy of PluginScreenshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? caption = freezed,
    Object? thumbnail = freezed,
  }) {
    return _then(_self.copyWith(
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      caption: freezed == caption
          ? _self.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnail: freezed == thumbnail
          ? _self.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PluginScreenshot implements PluginScreenshot {
  const _PluginScreenshot({required this.url, this.caption, this.thumbnail});
  factory _PluginScreenshot.fromJson(Map<String, dynamic> json) =>
      _$PluginScreenshotFromJson(json);

  @override
  final String url;
  @override
  final String? caption;
  @override
  final String? thumbnail;

  /// Create a copy of PluginScreenshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PluginScreenshotCopyWith<_PluginScreenshot> get copyWith =>
      __$PluginScreenshotCopyWithImpl<_PluginScreenshot>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PluginScreenshotToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PluginScreenshot &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, url, caption, thumbnail);

  @override
  String toString() {
    return 'PluginScreenshot(url: $url, caption: $caption, thumbnail: $thumbnail)';
  }
}

/// @nodoc
abstract mixin class _$PluginScreenshotCopyWith<$Res>
    implements $PluginScreenshotCopyWith<$Res> {
  factory _$PluginScreenshotCopyWith(
          _PluginScreenshot value, $Res Function(_PluginScreenshot) _then) =
      __$PluginScreenshotCopyWithImpl;
  @override
  @useResult
  $Res call({String url, String? caption, String? thumbnail});
}

/// @nodoc
class __$PluginScreenshotCopyWithImpl<$Res>
    implements _$PluginScreenshotCopyWith<$Res> {
  __$PluginScreenshotCopyWithImpl(this._self, this._then);

  final _PluginScreenshot _self;
  final $Res Function(_PluginScreenshot) _then;

  /// Create a copy of PluginScreenshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? url = null,
    Object? caption = freezed,
    Object? thumbnail = freezed,
  }) {
    return _then(_PluginScreenshot(
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      caption: freezed == caption
          ? _self.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnail: freezed == thumbnail
          ? _self.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$PluginDocumentation {
  String? get readme;
  String? get manual;
  String? get examples;

  /// Create a copy of PluginDocumentation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PluginDocumentationCopyWith<PluginDocumentation> get copyWith =>
      _$PluginDocumentationCopyWithImpl<PluginDocumentation>(
          this as PluginDocumentation, _$identity);

  /// Serializes this PluginDocumentation to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PluginDocumentation &&
            (identical(other.readme, readme) || other.readme == readme) &&
            (identical(other.manual, manual) || other.manual == manual) &&
            (identical(other.examples, examples) ||
                other.examples == examples));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, readme, manual, examples);

  @override
  String toString() {
    return 'PluginDocumentation(readme: $readme, manual: $manual, examples: $examples)';
  }
}

/// @nodoc
abstract mixin class $PluginDocumentationCopyWith<$Res> {
  factory $PluginDocumentationCopyWith(
          PluginDocumentation value, $Res Function(PluginDocumentation) _then) =
      _$PluginDocumentationCopyWithImpl;
  @useResult
  $Res call({String? readme, String? manual, String? examples});
}

/// @nodoc
class _$PluginDocumentationCopyWithImpl<$Res>
    implements $PluginDocumentationCopyWith<$Res> {
  _$PluginDocumentationCopyWithImpl(this._self, this._then);

  final PluginDocumentation _self;
  final $Res Function(PluginDocumentation) _then;

  /// Create a copy of PluginDocumentation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? readme = freezed,
    Object? manual = freezed,
    Object? examples = freezed,
  }) {
    return _then(_self.copyWith(
      readme: freezed == readme
          ? _self.readme
          : readme // ignore: cast_nullable_to_non_nullable
              as String?,
      manual: freezed == manual
          ? _self.manual
          : manual // ignore: cast_nullable_to_non_nullable
              as String?,
      examples: freezed == examples
          ? _self.examples
          : examples // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PluginDocumentation implements PluginDocumentation {
  const _PluginDocumentation({this.readme, this.manual, this.examples});
  factory _PluginDocumentation.fromJson(Map<String, dynamic> json) =>
      _$PluginDocumentationFromJson(json);

  @override
  final String? readme;
  @override
  final String? manual;
  @override
  final String? examples;

  /// Create a copy of PluginDocumentation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PluginDocumentationCopyWith<_PluginDocumentation> get copyWith =>
      __$PluginDocumentationCopyWithImpl<_PluginDocumentation>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PluginDocumentationToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PluginDocumentation &&
            (identical(other.readme, readme) || other.readme == readme) &&
            (identical(other.manual, manual) || other.manual == manual) &&
            (identical(other.examples, examples) ||
                other.examples == examples));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, readme, manual, examples);

  @override
  String toString() {
    return 'PluginDocumentation(readme: $readme, manual: $manual, examples: $examples)';
  }
}

/// @nodoc
abstract mixin class _$PluginDocumentationCopyWith<$Res>
    implements $PluginDocumentationCopyWith<$Res> {
  factory _$PluginDocumentationCopyWith(_PluginDocumentation value,
          $Res Function(_PluginDocumentation) _then) =
      __$PluginDocumentationCopyWithImpl;
  @override
  @useResult
  $Res call({String? readme, String? manual, String? examples});
}

/// @nodoc
class __$PluginDocumentationCopyWithImpl<$Res>
    implements _$PluginDocumentationCopyWith<$Res> {
  __$PluginDocumentationCopyWithImpl(this._self, this._then);

  final _PluginDocumentation _self;
  final $Res Function(_PluginDocumentation) _then;

  /// Create a copy of PluginDocumentation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? readme = freezed,
    Object? manual = freezed,
    Object? examples = freezed,
  }) {
    return _then(_PluginDocumentation(
      readme: freezed == readme
          ? _self.readme
          : readme // ignore: cast_nullable_to_non_nullable
              as String?,
      manual: freezed == manual
          ? _self.manual
          : manual // ignore: cast_nullable_to_non_nullable
              as String?,
      examples: freezed == examples
          ? _self.examples
          : examples // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$PluginMetrics {
  int get downloads;
  double? get rating;
  int get ratingCount;

  /// Create a copy of PluginMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PluginMetricsCopyWith<PluginMetrics> get copyWith =>
      _$PluginMetricsCopyWithImpl<PluginMetrics>(
          this as PluginMetrics, _$identity);

  /// Serializes this PluginMetrics to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PluginMetrics &&
            (identical(other.downloads, downloads) ||
                other.downloads == downloads) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.ratingCount, ratingCount) ||
                other.ratingCount == ratingCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, downloads, rating, ratingCount);

  @override
  String toString() {
    return 'PluginMetrics(downloads: $downloads, rating: $rating, ratingCount: $ratingCount)';
  }
}

/// @nodoc
abstract mixin class $PluginMetricsCopyWith<$Res> {
  factory $PluginMetricsCopyWith(
          PluginMetrics value, $Res Function(PluginMetrics) _then) =
      _$PluginMetricsCopyWithImpl;
  @useResult
  $Res call({int downloads, double? rating, int ratingCount});
}

/// @nodoc
class _$PluginMetricsCopyWithImpl<$Res>
    implements $PluginMetricsCopyWith<$Res> {
  _$PluginMetricsCopyWithImpl(this._self, this._then);

  final PluginMetrics _self;
  final $Res Function(PluginMetrics) _then;

  /// Create a copy of PluginMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? downloads = null,
    Object? rating = freezed,
    Object? ratingCount = null,
  }) {
    return _then(_self.copyWith(
      downloads: null == downloads
          ? _self.downloads
          : downloads // ignore: cast_nullable_to_non_nullable
              as int,
      rating: freezed == rating
          ? _self.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      ratingCount: null == ratingCount
          ? _self.ratingCount
          : ratingCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PluginMetrics implements PluginMetrics {
  const _PluginMetrics({this.downloads = 0, this.rating, this.ratingCount = 0});
  factory _PluginMetrics.fromJson(Map<String, dynamic> json) =>
      _$PluginMetricsFromJson(json);

  @override
  @JsonKey()
  final int downloads;
  @override
  final double? rating;
  @override
  @JsonKey()
  final int ratingCount;

  /// Create a copy of PluginMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PluginMetricsCopyWith<_PluginMetrics> get copyWith =>
      __$PluginMetricsCopyWithImpl<_PluginMetrics>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PluginMetricsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PluginMetrics &&
            (identical(other.downloads, downloads) ||
                other.downloads == downloads) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.ratingCount, ratingCount) ||
                other.ratingCount == ratingCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, downloads, rating, ratingCount);

  @override
  String toString() {
    return 'PluginMetrics(downloads: $downloads, rating: $rating, ratingCount: $ratingCount)';
  }
}

/// @nodoc
abstract mixin class _$PluginMetricsCopyWith<$Res>
    implements $PluginMetricsCopyWith<$Res> {
  factory _$PluginMetricsCopyWith(
          _PluginMetrics value, $Res Function(_PluginMetrics) _then) =
      __$PluginMetricsCopyWithImpl;
  @override
  @useResult
  $Res call({int downloads, double? rating, int ratingCount});
}

/// @nodoc
class __$PluginMetricsCopyWithImpl<$Res>
    implements _$PluginMetricsCopyWith<$Res> {
  __$PluginMetricsCopyWithImpl(this._self, this._then);

  final _PluginMetrics _self;
  final $Res Function(_PluginMetrics) _then;

  /// Create a copy of PluginMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? downloads = null,
    Object? rating = freezed,
    Object? ratingCount = null,
  }) {
    return _then(_PluginMetrics(
      downloads: null == downloads
          ? _self.downloads
          : downloads // ignore: cast_nullable_to_non_nullable
              as int,
      rating: freezed == rating
          ? _self.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      ratingCount: null == ratingCount
          ? _self.ratingCount
          : ratingCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$GalleryPlugin {
  String get id;
  String get name;
  String get description;
  String? get longDescription;
  GalleryPluginType get type;
  String? get category;
  List<String> get tags;
  String get author;
  PluginRepository get repository;
  PluginReleases get releases;
  PluginInstallation get installation;
  PluginCompatibility? get compatibility;
  List<PluginScreenshot> get screenshots;
  PluginDocumentation? get documentation;
  PluginMetrics? get metrics;
  bool get featured;
  bool get verified;
  DateTime? get createdAt;
  DateTime? get updatedAt;

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GalleryPluginCopyWith<GalleryPlugin> get copyWith =>
      _$GalleryPluginCopyWithImpl<GalleryPlugin>(
          this as GalleryPlugin, _$identity);

  /// Serializes this GalleryPlugin to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GalleryPlugin &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.longDescription, longDescription) ||
                other.longDescription == longDescription) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.repository, repository) ||
                other.repository == repository) &&
            (identical(other.releases, releases) ||
                other.releases == releases) &&
            (identical(other.installation, installation) ||
                other.installation == installation) &&
            (identical(other.compatibility, compatibility) ||
                other.compatibility == compatibility) &&
            const DeepCollectionEquality()
                .equals(other.screenshots, screenshots) &&
            (identical(other.documentation, documentation) ||
                other.documentation == documentation) &&
            (identical(other.metrics, metrics) || other.metrics == metrics) &&
            (identical(other.featured, featured) ||
                other.featured == featured) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        description,
        longDescription,
        type,
        category,
        const DeepCollectionEquality().hash(tags),
        author,
        repository,
        releases,
        installation,
        compatibility,
        const DeepCollectionEquality().hash(screenshots),
        documentation,
        metrics,
        featured,
        verified,
        createdAt,
        updatedAt
      ]);

  @override
  String toString() {
    return 'GalleryPlugin(id: $id, name: $name, description: $description, longDescription: $longDescription, type: $type, category: $category, tags: $tags, author: $author, repository: $repository, releases: $releases, installation: $installation, compatibility: $compatibility, screenshots: $screenshots, documentation: $documentation, metrics: $metrics, featured: $featured, verified: $verified, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $GalleryPluginCopyWith<$Res> {
  factory $GalleryPluginCopyWith(
          GalleryPlugin value, $Res Function(GalleryPlugin) _then) =
      _$GalleryPluginCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      String? longDescription,
      GalleryPluginType type,
      String? category,
      List<String> tags,
      String author,
      PluginRepository repository,
      PluginReleases releases,
      PluginInstallation installation,
      PluginCompatibility? compatibility,
      List<PluginScreenshot> screenshots,
      PluginDocumentation? documentation,
      PluginMetrics? metrics,
      bool featured,
      bool verified,
      DateTime? createdAt,
      DateTime? updatedAt});

  $PluginRepositoryCopyWith<$Res> get repository;
  $PluginReleasesCopyWith<$Res> get releases;
  $PluginInstallationCopyWith<$Res> get installation;
  $PluginCompatibilityCopyWith<$Res>? get compatibility;
  $PluginDocumentationCopyWith<$Res>? get documentation;
  $PluginMetricsCopyWith<$Res>? get metrics;
}

/// @nodoc
class _$GalleryPluginCopyWithImpl<$Res>
    implements $GalleryPluginCopyWith<$Res> {
  _$GalleryPluginCopyWithImpl(this._self, this._then);

  final GalleryPlugin _self;
  final $Res Function(GalleryPlugin) _then;

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? longDescription = freezed,
    Object? type = null,
    Object? category = freezed,
    Object? tags = null,
    Object? author = null,
    Object? repository = null,
    Object? releases = null,
    Object? installation = null,
    Object? compatibility = freezed,
    Object? screenshots = null,
    Object? documentation = freezed,
    Object? metrics = freezed,
    Object? featured = null,
    Object? verified = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      longDescription: freezed == longDescription
          ? _self.longDescription
          : longDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as GalleryPluginType,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      author: null == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      repository: null == repository
          ? _self.repository
          : repository // ignore: cast_nullable_to_non_nullable
              as PluginRepository,
      releases: null == releases
          ? _self.releases
          : releases // ignore: cast_nullable_to_non_nullable
              as PluginReleases,
      installation: null == installation
          ? _self.installation
          : installation // ignore: cast_nullable_to_non_nullable
              as PluginInstallation,
      compatibility: freezed == compatibility
          ? _self.compatibility
          : compatibility // ignore: cast_nullable_to_non_nullable
              as PluginCompatibility?,
      screenshots: null == screenshots
          ? _self.screenshots
          : screenshots // ignore: cast_nullable_to_non_nullable
              as List<PluginScreenshot>,
      documentation: freezed == documentation
          ? _self.documentation
          : documentation // ignore: cast_nullable_to_non_nullable
              as PluginDocumentation?,
      metrics: freezed == metrics
          ? _self.metrics
          : metrics // ignore: cast_nullable_to_non_nullable
              as PluginMetrics?,
      featured: null == featured
          ? _self.featured
          : featured // ignore: cast_nullable_to_non_nullable
              as bool,
      verified: null == verified
          ? _self.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginRepositoryCopyWith<$Res> get repository {
    return $PluginRepositoryCopyWith<$Res>(_self.repository, (value) {
      return _then(_self.copyWith(repository: value));
    });
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginReleasesCopyWith<$Res> get releases {
    return $PluginReleasesCopyWith<$Res>(_self.releases, (value) {
      return _then(_self.copyWith(releases: value));
    });
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginInstallationCopyWith<$Res> get installation {
    return $PluginInstallationCopyWith<$Res>(_self.installation, (value) {
      return _then(_self.copyWith(installation: value));
    });
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginCompatibilityCopyWith<$Res>? get compatibility {
    if (_self.compatibility == null) {
      return null;
    }

    return $PluginCompatibilityCopyWith<$Res>(_self.compatibility!, (value) {
      return _then(_self.copyWith(compatibility: value));
    });
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginDocumentationCopyWith<$Res>? get documentation {
    if (_self.documentation == null) {
      return null;
    }

    return $PluginDocumentationCopyWith<$Res>(_self.documentation!, (value) {
      return _then(_self.copyWith(documentation: value));
    });
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginMetricsCopyWith<$Res>? get metrics {
    if (_self.metrics == null) {
      return null;
    }

    return $PluginMetricsCopyWith<$Res>(_self.metrics!, (value) {
      return _then(_self.copyWith(metrics: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _GalleryPlugin implements GalleryPlugin {
  const _GalleryPlugin(
      {required this.id,
      required this.name,
      required this.description,
      this.longDescription,
      required this.type,
      this.category,
      final List<String> tags = const [],
      required this.author,
      required this.repository,
      required this.releases,
      required this.installation,
      this.compatibility,
      final List<PluginScreenshot> screenshots = const [],
      this.documentation,
      this.metrics,
      this.featured = false,
      this.verified = false,
      this.createdAt,
      this.updatedAt})
      : _tags = tags,
        _screenshots = screenshots;
  factory _GalleryPlugin.fromJson(Map<String, dynamic> json) =>
      _$GalleryPluginFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String? longDescription;
  @override
  final GalleryPluginType type;
  @override
  final String? category;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final String author;
  @override
  final PluginRepository repository;
  @override
  final PluginReleases releases;
  @override
  final PluginInstallation installation;
  @override
  final PluginCompatibility? compatibility;
  final List<PluginScreenshot> _screenshots;
  @override
  @JsonKey()
  List<PluginScreenshot> get screenshots {
    if (_screenshots is EqualUnmodifiableListView) return _screenshots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_screenshots);
  }

  @override
  final PluginDocumentation? documentation;
  @override
  final PluginMetrics? metrics;
  @override
  @JsonKey()
  final bool featured;
  @override
  @JsonKey()
  final bool verified;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GalleryPluginCopyWith<_GalleryPlugin> get copyWith =>
      __$GalleryPluginCopyWithImpl<_GalleryPlugin>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GalleryPluginToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GalleryPlugin &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.longDescription, longDescription) ||
                other.longDescription == longDescription) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.repository, repository) ||
                other.repository == repository) &&
            (identical(other.releases, releases) ||
                other.releases == releases) &&
            (identical(other.installation, installation) ||
                other.installation == installation) &&
            (identical(other.compatibility, compatibility) ||
                other.compatibility == compatibility) &&
            const DeepCollectionEquality()
                .equals(other._screenshots, _screenshots) &&
            (identical(other.documentation, documentation) ||
                other.documentation == documentation) &&
            (identical(other.metrics, metrics) || other.metrics == metrics) &&
            (identical(other.featured, featured) ||
                other.featured == featured) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        description,
        longDescription,
        type,
        category,
        const DeepCollectionEquality().hash(_tags),
        author,
        repository,
        releases,
        installation,
        compatibility,
        const DeepCollectionEquality().hash(_screenshots),
        documentation,
        metrics,
        featured,
        verified,
        createdAt,
        updatedAt
      ]);

  @override
  String toString() {
    return 'GalleryPlugin(id: $id, name: $name, description: $description, longDescription: $longDescription, type: $type, category: $category, tags: $tags, author: $author, repository: $repository, releases: $releases, installation: $installation, compatibility: $compatibility, screenshots: $screenshots, documentation: $documentation, metrics: $metrics, featured: $featured, verified: $verified, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$GalleryPluginCopyWith<$Res>
    implements $GalleryPluginCopyWith<$Res> {
  factory _$GalleryPluginCopyWith(
          _GalleryPlugin value, $Res Function(_GalleryPlugin) _then) =
      __$GalleryPluginCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      String? longDescription,
      GalleryPluginType type,
      String? category,
      List<String> tags,
      String author,
      PluginRepository repository,
      PluginReleases releases,
      PluginInstallation installation,
      PluginCompatibility? compatibility,
      List<PluginScreenshot> screenshots,
      PluginDocumentation? documentation,
      PluginMetrics? metrics,
      bool featured,
      bool verified,
      DateTime? createdAt,
      DateTime? updatedAt});

  @override
  $PluginRepositoryCopyWith<$Res> get repository;
  @override
  $PluginReleasesCopyWith<$Res> get releases;
  @override
  $PluginInstallationCopyWith<$Res> get installation;
  @override
  $PluginCompatibilityCopyWith<$Res>? get compatibility;
  @override
  $PluginDocumentationCopyWith<$Res>? get documentation;
  @override
  $PluginMetricsCopyWith<$Res>? get metrics;
}

/// @nodoc
class __$GalleryPluginCopyWithImpl<$Res>
    implements _$GalleryPluginCopyWith<$Res> {
  __$GalleryPluginCopyWithImpl(this._self, this._then);

  final _GalleryPlugin _self;
  final $Res Function(_GalleryPlugin) _then;

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? longDescription = freezed,
    Object? type = null,
    Object? category = freezed,
    Object? tags = null,
    Object? author = null,
    Object? repository = null,
    Object? releases = null,
    Object? installation = null,
    Object? compatibility = freezed,
    Object? screenshots = null,
    Object? documentation = freezed,
    Object? metrics = freezed,
    Object? featured = null,
    Object? verified = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_GalleryPlugin(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      longDescription: freezed == longDescription
          ? _self.longDescription
          : longDescription // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as GalleryPluginType,
      category: freezed == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      author: null == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      repository: null == repository
          ? _self.repository
          : repository // ignore: cast_nullable_to_non_nullable
              as PluginRepository,
      releases: null == releases
          ? _self.releases
          : releases // ignore: cast_nullable_to_non_nullable
              as PluginReleases,
      installation: null == installation
          ? _self.installation
          : installation // ignore: cast_nullable_to_non_nullable
              as PluginInstallation,
      compatibility: freezed == compatibility
          ? _self.compatibility
          : compatibility // ignore: cast_nullable_to_non_nullable
              as PluginCompatibility?,
      screenshots: null == screenshots
          ? _self._screenshots
          : screenshots // ignore: cast_nullable_to_non_nullable
              as List<PluginScreenshot>,
      documentation: freezed == documentation
          ? _self.documentation
          : documentation // ignore: cast_nullable_to_non_nullable
              as PluginDocumentation?,
      metrics: freezed == metrics
          ? _self.metrics
          : metrics // ignore: cast_nullable_to_non_nullable
              as PluginMetrics?,
      featured: null == featured
          ? _self.featured
          : featured // ignore: cast_nullable_to_non_nullable
              as bool,
      verified: null == verified
          ? _self.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginRepositoryCopyWith<$Res> get repository {
    return $PluginRepositoryCopyWith<$Res>(_self.repository, (value) {
      return _then(_self.copyWith(repository: value));
    });
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginReleasesCopyWith<$Res> get releases {
    return $PluginReleasesCopyWith<$Res>(_self.releases, (value) {
      return _then(_self.copyWith(releases: value));
    });
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginInstallationCopyWith<$Res> get installation {
    return $PluginInstallationCopyWith<$Res>(_self.installation, (value) {
      return _then(_self.copyWith(installation: value));
    });
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginCompatibilityCopyWith<$Res>? get compatibility {
    if (_self.compatibility == null) {
      return null;
    }

    return $PluginCompatibilityCopyWith<$Res>(_self.compatibility!, (value) {
      return _then(_self.copyWith(compatibility: value));
    });
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginDocumentationCopyWith<$Res>? get documentation {
    if (_self.documentation == null) {
      return null;
    }

    return $PluginDocumentationCopyWith<$Res>(_self.documentation!, (value) {
      return _then(_self.copyWith(documentation: value));
    });
  }

  /// Create a copy of GalleryPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PluginMetricsCopyWith<$Res>? get metrics {
    if (_self.metrics == null) {
      return null;
    }

    return $PluginMetricsCopyWith<$Res>(_self.metrics!, (value) {
      return _then(_self.copyWith(metrics: value));
    });
  }
}

/// @nodoc
mixin _$Gallery {
  String get version;
  DateTime get lastUpdated;
  GalleryMetadata get metadata;
  List<PluginCategory> get categories;
  Map<String, PluginAuthor> get authors;
  List<GalleryPlugin> get plugins;

  /// Create a copy of Gallery
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GalleryCopyWith<Gallery> get copyWith =>
      _$GalleryCopyWithImpl<Gallery>(this as Gallery, _$identity);

  /// Serializes this Gallery to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Gallery &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            const DeepCollectionEquality()
                .equals(other.categories, categories) &&
            const DeepCollectionEquality().equals(other.authors, authors) &&
            const DeepCollectionEquality().equals(other.plugins, plugins));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      version,
      lastUpdated,
      metadata,
      const DeepCollectionEquality().hash(categories),
      const DeepCollectionEquality().hash(authors),
      const DeepCollectionEquality().hash(plugins));

  @override
  String toString() {
    return 'Gallery(version: $version, lastUpdated: $lastUpdated, metadata: $metadata, categories: $categories, authors: $authors, plugins: $plugins)';
  }
}

/// @nodoc
abstract mixin class $GalleryCopyWith<$Res> {
  factory $GalleryCopyWith(Gallery value, $Res Function(Gallery) _then) =
      _$GalleryCopyWithImpl;
  @useResult
  $Res call(
      {String version,
      DateTime lastUpdated,
      GalleryMetadata metadata,
      List<PluginCategory> categories,
      Map<String, PluginAuthor> authors,
      List<GalleryPlugin> plugins});

  $GalleryMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class _$GalleryCopyWithImpl<$Res> implements $GalleryCopyWith<$Res> {
  _$GalleryCopyWithImpl(this._self, this._then);

  final Gallery _self;
  final $Res Function(Gallery) _then;

  /// Create a copy of Gallery
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? lastUpdated = null,
    Object? metadata = null,
    Object? categories = null,
    Object? authors = null,
    Object? plugins = null,
  }) {
    return _then(_self.copyWith(
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      lastUpdated: null == lastUpdated
          ? _self.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as GalleryMetadata,
      categories: null == categories
          ? _self.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<PluginCategory>,
      authors: null == authors
          ? _self.authors
          : authors // ignore: cast_nullable_to_non_nullable
              as Map<String, PluginAuthor>,
      plugins: null == plugins
          ? _self.plugins
          : plugins // ignore: cast_nullable_to_non_nullable
              as List<GalleryPlugin>,
    ));
  }

  /// Create a copy of Gallery
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GalleryMetadataCopyWith<$Res> get metadata {
    return $GalleryMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _Gallery implements Gallery {
  const _Gallery(
      {required this.version,
      required this.lastUpdated,
      required this.metadata,
      final List<PluginCategory> categories = const [],
      final Map<String, PluginAuthor> authors = const {},
      final List<GalleryPlugin> plugins = const []})
      : _categories = categories,
        _authors = authors,
        _plugins = plugins;
  factory _Gallery.fromJson(Map<String, dynamic> json) =>
      _$GalleryFromJson(json);

  @override
  final String version;
  @override
  final DateTime lastUpdated;
  @override
  final GalleryMetadata metadata;
  final List<PluginCategory> _categories;
  @override
  @JsonKey()
  List<PluginCategory> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  final Map<String, PluginAuthor> _authors;
  @override
  @JsonKey()
  Map<String, PluginAuthor> get authors {
    if (_authors is EqualUnmodifiableMapView) return _authors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_authors);
  }

  final List<GalleryPlugin> _plugins;
  @override
  @JsonKey()
  List<GalleryPlugin> get plugins {
    if (_plugins is EqualUnmodifiableListView) return _plugins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_plugins);
  }

  /// Create a copy of Gallery
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GalleryCopyWith<_Gallery> get copyWith =>
      __$GalleryCopyWithImpl<_Gallery>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GalleryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Gallery &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            const DeepCollectionEquality().equals(other._authors, _authors) &&
            const DeepCollectionEquality().equals(other._plugins, _plugins));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      version,
      lastUpdated,
      metadata,
      const DeepCollectionEquality().hash(_categories),
      const DeepCollectionEquality().hash(_authors),
      const DeepCollectionEquality().hash(_plugins));

  @override
  String toString() {
    return 'Gallery(version: $version, lastUpdated: $lastUpdated, metadata: $metadata, categories: $categories, authors: $authors, plugins: $plugins)';
  }
}

/// @nodoc
abstract mixin class _$GalleryCopyWith<$Res> implements $GalleryCopyWith<$Res> {
  factory _$GalleryCopyWith(_Gallery value, $Res Function(_Gallery) _then) =
      __$GalleryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String version,
      DateTime lastUpdated,
      GalleryMetadata metadata,
      List<PluginCategory> categories,
      Map<String, PluginAuthor> authors,
      List<GalleryPlugin> plugins});

  @override
  $GalleryMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class __$GalleryCopyWithImpl<$Res> implements _$GalleryCopyWith<$Res> {
  __$GalleryCopyWithImpl(this._self, this._then);

  final _Gallery _self;
  final $Res Function(_Gallery) _then;

  /// Create a copy of Gallery
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? version = null,
    Object? lastUpdated = null,
    Object? metadata = null,
    Object? categories = null,
    Object? authors = null,
    Object? plugins = null,
  }) {
    return _then(_Gallery(
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      lastUpdated: null == lastUpdated
          ? _self.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as GalleryMetadata,
      categories: null == categories
          ? _self._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<PluginCategory>,
      authors: null == authors
          ? _self._authors
          : authors // ignore: cast_nullable_to_non_nullable
              as Map<String, PluginAuthor>,
      plugins: null == plugins
          ? _self._plugins
          : plugins // ignore: cast_nullable_to_non_nullable
              as List<GalleryPlugin>,
    ));
  }

  /// Create a copy of Gallery
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GalleryMetadataCopyWith<$Res> get metadata {
    return $GalleryMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

/// @nodoc
mixin _$CollectionPlugin {
  String get name;
  String get relativePath;
  String get fileType; // 'o', 'lua', '3pot'
  String? get description;
  int? get fileSize;
  bool get selected;

  /// Create a copy of CollectionPlugin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CollectionPluginCopyWith<CollectionPlugin> get copyWith =>
      _$CollectionPluginCopyWithImpl<CollectionPlugin>(
          this as CollectionPlugin, _$identity);

  /// Serializes this CollectionPlugin to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CollectionPlugin &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.selected, selected) ||
                other.selected == selected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, relativePath, fileType,
      description, fileSize, selected);

  @override
  String toString() {
    return 'CollectionPlugin(name: $name, relativePath: $relativePath, fileType: $fileType, description: $description, fileSize: $fileSize, selected: $selected)';
  }
}

/// @nodoc
abstract mixin class $CollectionPluginCopyWith<$Res> {
  factory $CollectionPluginCopyWith(
          CollectionPlugin value, $Res Function(CollectionPlugin) _then) =
      _$CollectionPluginCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      String relativePath,
      String fileType,
      String? description,
      int? fileSize,
      bool selected});
}

/// @nodoc
class _$CollectionPluginCopyWithImpl<$Res>
    implements $CollectionPluginCopyWith<$Res> {
  _$CollectionPluginCopyWithImpl(this._self, this._then);

  final CollectionPlugin _self;
  final $Res Function(CollectionPlugin) _then;

  /// Create a copy of CollectionPlugin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? relativePath = null,
    Object? fileType = null,
    Object? description = freezed,
    Object? fileSize = freezed,
    Object? selected = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _self.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _self.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      fileSize: freezed == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      selected: null == selected
          ? _self.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _CollectionPlugin implements CollectionPlugin {
  const _CollectionPlugin(
      {required this.name,
      required this.relativePath,
      required this.fileType,
      this.description,
      this.fileSize,
      this.selected = false});
  factory _CollectionPlugin.fromJson(Map<String, dynamic> json) =>
      _$CollectionPluginFromJson(json);

  @override
  final String name;
  @override
  final String relativePath;
  @override
  final String fileType;
// 'o', 'lua', '3pot'
  @override
  final String? description;
  @override
  final int? fileSize;
  @override
  @JsonKey()
  final bool selected;

  /// Create a copy of CollectionPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CollectionPluginCopyWith<_CollectionPlugin> get copyWith =>
      __$CollectionPluginCopyWithImpl<_CollectionPlugin>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CollectionPluginToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CollectionPlugin &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.selected, selected) ||
                other.selected == selected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, relativePath, fileType,
      description, fileSize, selected);

  @override
  String toString() {
    return 'CollectionPlugin(name: $name, relativePath: $relativePath, fileType: $fileType, description: $description, fileSize: $fileSize, selected: $selected)';
  }
}

/// @nodoc
abstract mixin class _$CollectionPluginCopyWith<$Res>
    implements $CollectionPluginCopyWith<$Res> {
  factory _$CollectionPluginCopyWith(
          _CollectionPlugin value, $Res Function(_CollectionPlugin) _then) =
      __$CollectionPluginCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      String relativePath,
      String fileType,
      String? description,
      int? fileSize,
      bool selected});
}

/// @nodoc
class __$CollectionPluginCopyWithImpl<$Res>
    implements _$CollectionPluginCopyWith<$Res> {
  __$CollectionPluginCopyWithImpl(this._self, this._then);

  final _CollectionPlugin _self;
  final $Res Function(_CollectionPlugin) _then;

  /// Create a copy of CollectionPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? relativePath = null,
    Object? fileType = null,
    Object? description = freezed,
    Object? fileSize = freezed,
    Object? selected = null,
  }) {
    return _then(_CollectionPlugin(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _self.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _self.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      fileSize: freezed == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int?,
      selected: null == selected
          ? _self.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$QueuedPlugin {
  GalleryPlugin get plugin;
  String get selectedVersion; // 'latest', 'stable', or 'beta'
  bool get isCollection;
  QueuedPluginStatus get status;
  String? get errorMessage;
  double? get progress;
  List<CollectionPlugin> get selectedPlugins;

  /// Create a copy of QueuedPlugin
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $QueuedPluginCopyWith<QueuedPlugin> get copyWith =>
      _$QueuedPluginCopyWithImpl<QueuedPlugin>(
          this as QueuedPlugin, _$identity);

  /// Serializes this QueuedPlugin to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is QueuedPlugin &&
            (identical(other.plugin, plugin) || other.plugin == plugin) &&
            (identical(other.selectedVersion, selectedVersion) ||
                other.selectedVersion == selectedVersion) &&
            (identical(other.isCollection, isCollection) ||
                other.isCollection == isCollection) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            const DeepCollectionEquality()
                .equals(other.selectedPlugins, selectedPlugins));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      plugin,
      selectedVersion,
      isCollection,
      status,
      errorMessage,
      progress,
      const DeepCollectionEquality().hash(selectedPlugins));

  @override
  String toString() {
    return 'QueuedPlugin(plugin: $plugin, selectedVersion: $selectedVersion, isCollection: $isCollection, status: $status, errorMessage: $errorMessage, progress: $progress, selectedPlugins: $selectedPlugins)';
  }
}

/// @nodoc
abstract mixin class $QueuedPluginCopyWith<$Res> {
  factory $QueuedPluginCopyWith(
          QueuedPlugin value, $Res Function(QueuedPlugin) _then) =
      _$QueuedPluginCopyWithImpl;
  @useResult
  $Res call(
      {GalleryPlugin plugin,
      String selectedVersion,
      bool isCollection,
      QueuedPluginStatus status,
      String? errorMessage,
      double? progress,
      List<CollectionPlugin> selectedPlugins});

  $GalleryPluginCopyWith<$Res> get plugin;
}

/// @nodoc
class _$QueuedPluginCopyWithImpl<$Res> implements $QueuedPluginCopyWith<$Res> {
  _$QueuedPluginCopyWithImpl(this._self, this._then);

  final QueuedPlugin _self;
  final $Res Function(QueuedPlugin) _then;

  /// Create a copy of QueuedPlugin
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plugin = null,
    Object? selectedVersion = null,
    Object? isCollection = null,
    Object? status = null,
    Object? errorMessage = freezed,
    Object? progress = freezed,
    Object? selectedPlugins = null,
  }) {
    return _then(_self.copyWith(
      plugin: null == plugin
          ? _self.plugin
          : plugin // ignore: cast_nullable_to_non_nullable
              as GalleryPlugin,
      selectedVersion: null == selectedVersion
          ? _self.selectedVersion
          : selectedVersion // ignore: cast_nullable_to_non_nullable
              as String,
      isCollection: null == isCollection
          ? _self.isCollection
          : isCollection // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as QueuedPluginStatus,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      progress: freezed == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double?,
      selectedPlugins: null == selectedPlugins
          ? _self.selectedPlugins
          : selectedPlugins // ignore: cast_nullable_to_non_nullable
              as List<CollectionPlugin>,
    ));
  }

  /// Create a copy of QueuedPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GalleryPluginCopyWith<$Res> get plugin {
    return $GalleryPluginCopyWith<$Res>(_self.plugin, (value) {
      return _then(_self.copyWith(plugin: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _QueuedPlugin implements QueuedPlugin {
  const _QueuedPlugin(
      {required this.plugin,
      required this.selectedVersion,
      required this.isCollection,
      this.status = QueuedPluginStatus.queued,
      this.errorMessage,
      this.progress,
      final List<CollectionPlugin> selectedPlugins = const []})
      : _selectedPlugins = selectedPlugins;
  factory _QueuedPlugin.fromJson(Map<String, dynamic> json) =>
      _$QueuedPluginFromJson(json);

  @override
  final GalleryPlugin plugin;
  @override
  final String selectedVersion;
// 'latest', 'stable', or 'beta'
  @override
  final bool isCollection;
  @override
  @JsonKey()
  final QueuedPluginStatus status;
  @override
  final String? errorMessage;
  @override
  final double? progress;
  final List<CollectionPlugin> _selectedPlugins;
  @override
  @JsonKey()
  List<CollectionPlugin> get selectedPlugins {
    if (_selectedPlugins is EqualUnmodifiableListView) return _selectedPlugins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedPlugins);
  }

  /// Create a copy of QueuedPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$QueuedPluginCopyWith<_QueuedPlugin> get copyWith =>
      __$QueuedPluginCopyWithImpl<_QueuedPlugin>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$QueuedPluginToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _QueuedPlugin &&
            (identical(other.plugin, plugin) || other.plugin == plugin) &&
            (identical(other.selectedVersion, selectedVersion) ||
                other.selectedVersion == selectedVersion) &&
            (identical(other.isCollection, isCollection) ||
                other.isCollection == isCollection) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            const DeepCollectionEquality()
                .equals(other._selectedPlugins, _selectedPlugins));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      plugin,
      selectedVersion,
      isCollection,
      status,
      errorMessage,
      progress,
      const DeepCollectionEquality().hash(_selectedPlugins));

  @override
  String toString() {
    return 'QueuedPlugin(plugin: $plugin, selectedVersion: $selectedVersion, isCollection: $isCollection, status: $status, errorMessage: $errorMessage, progress: $progress, selectedPlugins: $selectedPlugins)';
  }
}

/// @nodoc
abstract mixin class _$QueuedPluginCopyWith<$Res>
    implements $QueuedPluginCopyWith<$Res> {
  factory _$QueuedPluginCopyWith(
          _QueuedPlugin value, $Res Function(_QueuedPlugin) _then) =
      __$QueuedPluginCopyWithImpl;
  @override
  @useResult
  $Res call(
      {GalleryPlugin plugin,
      String selectedVersion,
      bool isCollection,
      QueuedPluginStatus status,
      String? errorMessage,
      double? progress,
      List<CollectionPlugin> selectedPlugins});

  @override
  $GalleryPluginCopyWith<$Res> get plugin;
}

/// @nodoc
class __$QueuedPluginCopyWithImpl<$Res>
    implements _$QueuedPluginCopyWith<$Res> {
  __$QueuedPluginCopyWithImpl(this._self, this._then);

  final _QueuedPlugin _self;
  final $Res Function(_QueuedPlugin) _then;

  /// Create a copy of QueuedPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? plugin = null,
    Object? selectedVersion = null,
    Object? isCollection = null,
    Object? status = null,
    Object? errorMessage = freezed,
    Object? progress = freezed,
    Object? selectedPlugins = null,
  }) {
    return _then(_QueuedPlugin(
      plugin: null == plugin
          ? _self.plugin
          : plugin // ignore: cast_nullable_to_non_nullable
              as GalleryPlugin,
      selectedVersion: null == selectedVersion
          ? _self.selectedVersion
          : selectedVersion // ignore: cast_nullable_to_non_nullable
              as String,
      isCollection: null == isCollection
          ? _self.isCollection
          : isCollection // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as QueuedPluginStatus,
      errorMessage: freezed == errorMessage
          ? _self.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      progress: freezed == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double?,
      selectedPlugins: null == selectedPlugins
          ? _self._selectedPlugins
          : selectedPlugins // ignore: cast_nullable_to_non_nullable
              as List<CollectionPlugin>,
    ));
  }

  /// Create a copy of QueuedPlugin
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GalleryPluginCopyWith<$Res> get plugin {
    return $GalleryPluginCopyWith<$Res>(_self.plugin, (value) {
      return _then(_self.copyWith(plugin: value));
    });
  }
}

// dart format on
