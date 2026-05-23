import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Structured metadata stored alongside a template preset.
///
/// Persisted as JSON text inside `Presets.templateMetadata`. The class is
/// deliberately resilient: malformed input never throws — callers always get
/// back an `empty()` instance. Unknown top-level keys round-trip through
/// [extras] so older clients do not silently drop fields written by newer
/// clients.
@immutable
class TemplateMetadata {
  /// Current schema version stored in the JSON payload.
  static const int currentSchemaVersion = 1;

  static const _kDescription = 'description';
  static const _kTags = 'tags';
  static const _kAuthor = 'author';
  static const _kCreatedAt = 'createdAt';
  static const _kSchemaVersion = 'schemaVersion';

  static const Set<String> _knownKeys = {
    _kDescription,
    _kTags,
    _kAuthor,
    _kCreatedAt,
    _kSchemaVersion,
  };

  final String? description;
  final List<String> tags;
  final String? author;
  final String? createdAt;
  final Map<String, dynamic> extras;

  const TemplateMetadata({
    this.description,
    this.tags = const [],
    this.author,
    this.createdAt,
    this.extras = const {},
  });

  factory TemplateMetadata.empty() => const TemplateMetadata();

  bool get isEmpty =>
      description == null &&
      tags.isEmpty &&
      author == null &&
      createdAt == null &&
      extras.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Decode a JSON string into [TemplateMetadata].
  ///
  /// - `null` or empty input → [TemplateMetadata.empty()].
  /// - Malformed JSON → [TemplateMetadata.empty()] (with a single
  ///   debug print, deduplicated per process via [_loggedFailures]).
  /// - Valid JSON with missing known keys → those keys default to
  ///   null / empty list. Unknown top-level keys are preserved in [extras].
  factory TemplateMetadata.fromJsonString(String? source) {
    if (source == null || source.isEmpty) {
      return TemplateMetadata.empty();
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      _logFailure(source);
      return TemplateMetadata.empty();
    }

    if (decoded is! Map<String, dynamic>) {
      _logFailure(source);
      return TemplateMetadata.empty();
    }

    final description = decoded[_kDescription];
    final author = decoded[_kAuthor];
    final createdAt = decoded[_kCreatedAt];
    final rawTags = decoded[_kTags];

    final tags = <String>[];
    if (rawTags is List) {
      for (final tag in rawTags) {
        if (tag == null) {
          tags.add('');
        } else if (tag is String) {
          tags.add(tag);
        } else {
          tags.add(tag.toString());
        }
      }
    }

    final extras = <String, dynamic>{};
    for (final entry in decoded.entries) {
      if (!_knownKeys.contains(entry.key)) {
        extras[entry.key] = entry.value;
      }
    }

    return TemplateMetadata(
      description: description is String ? description : null,
      tags: List.unmodifiable(tags),
      author: author is String ? author : null,
      createdAt: createdAt is String ? createdAt : null,
      extras: Map.unmodifiable(extras),
    );
  }

  /// Encode this instance to its JSON text representation.
  ///
  /// Known fields always win over [extras] when their keys collide.
  /// `schemaVersion` is always stamped onto the output so the payload is
  /// self-describing.
  String toJsonString() {
    final Map<String, dynamic> out = <String, dynamic>{};

    extras.forEach((key, value) {
      if (_knownKeys.contains(key)) return;
      out[key] = value;
    });

    if (description != null) out[_kDescription] = description;
    if (tags.isNotEmpty) out[_kTags] = tags;
    if (author != null) out[_kAuthor] = author;
    if (createdAt != null) out[_kCreatedAt] = createdAt;
    out[_kSchemaVersion] = currentSchemaVersion;

    return jsonEncode(out);
  }

  TemplateMetadata copyWith({
    String? description,
    List<String>? tags,
    String? author,
    String? createdAt,
    Map<String, dynamic>? extras,
  }) {
    return TemplateMetadata(
      description: description ?? this.description,
      tags: tags ?? this.tags,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      extras: extras ?? this.extras,
    );
  }

  static final Set<String> _loggedFailures = <String>{};

  static void _logFailure(String source) {
    final key = source.length > 32 ? source.substring(0, 32) : source;
    if (_loggedFailures.add(key)) {
      debugPrint(
        'TemplateMetadata: malformed JSON payload ignored (len=${source.length})',
      );
    }
  }
}
