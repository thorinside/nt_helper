import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/template_metadata.dart';

void main() {
  group('TemplateMetadata.fromJsonString', () {
    test('null source returns empty metadata', () {
      final m = TemplateMetadata.fromJsonString(null);

      expect(m.description, isNull);
      expect(m.tags, isEmpty);
      expect(m.author, isNull);
      expect(m.createdAt, isNull);
      expect(m.extras, isEmpty);
      expect(m.isEmpty, isTrue);
    });

    test('empty string returns empty metadata', () {
      final m = TemplateMetadata.fromJsonString('');

      expect(m.description, isNull);
      expect(m.tags, isEmpty);
      expect(m.author, isNull);
      expect(m.createdAt, isNull);
      expect(m.extras, isEmpty);
    });

    test('malformed JSON returns empty metadata without throwing', () {
      final m = TemplateMetadata.fromJsonString('{not valid json');

      expect(m.description, isNull);
      expect(m.tags, isEmpty);
    });

    test('parses known fields', () {
      const src =
          '{'
          '"description":"Reverbs and delays",'
          '"tags":["space","wet","stereo"],'
          '"author":"neal",'
          '"createdAt":"2026-05-22T10:00:00Z",'
          '"schemaVersion":1'
          '}';
      final m = TemplateMetadata.fromJsonString(src);

      expect(m.description, 'Reverbs and delays');
      expect(m.tags, ['space', 'wet', 'stereo']);
      expect(m.author, 'neal');
      expect(m.createdAt, '2026-05-22T10:00:00Z');
      expect(m.extras, isEmpty);
    });

    test('unknown top-level keys flow into extras', () {
      const src =
          '{"description":"x","futureFlag":true,"customNumber":42,"nested":{"a":1}}';
      final m = TemplateMetadata.fromJsonString(src);

      expect(m.description, 'x');
      expect(m.extras['futureFlag'], isTrue);
      expect(m.extras['customNumber'], 42);
      expect(m.extras['nested'], {'a': 1});
    });

    test('missing known keys default to null/empty', () {
      const src = '{"author":"neal"}';
      final m = TemplateMetadata.fromJsonString(src);

      expect(m.description, isNull);
      expect(m.author, 'neal');
      expect(m.tags, isEmpty);
    });

    test('tags coerce non-string entries to strings', () {
      const src = '{"tags":["valid",42,null,true]}';
      final m = TemplateMetadata.fromJsonString(src);

      expect(m.tags, ['valid', '42', '', 'true']);
    });
  });

  group('TemplateMetadata.toJsonString', () {
    test('empty metadata serializes to schemaVersion-only JSON', () {
      const m = TemplateMetadata();
      final encoded = m.toJsonString();
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['schemaVersion'], 1);
      expect(decoded.containsKey('description'), isFalse);
      expect(decoded.containsKey('tags'), isFalse);
    });

    test('serializes known fields and omits nulls', () {
      const m = TemplateMetadata(
        description: 'hi',
        tags: ['a', 'b'],
        author: 'neal',
        createdAt: '2026-05-22T00:00:00Z',
      );
      final encoded = m.toJsonString();
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['description'], 'hi');
      expect(decoded['tags'], ['a', 'b']);
      expect(decoded['author'], 'neal');
      expect(decoded['createdAt'], '2026-05-22T00:00:00Z');
      expect(decoded['schemaVersion'], 1);
    });

    test('extras are merged back into output JSON', () {
      const m = TemplateMetadata(
        description: 'desc',
        extras: {'futureFlag': true, 'customNumber': 42},
      );
      final decoded = jsonDecode(m.toJsonString()) as Map<String, dynamic>;

      expect(decoded['description'], 'desc');
      expect(decoded['futureFlag'], isTrue);
      expect(decoded['customNumber'], 42);
    });

    test('known fields take precedence over extras with same key', () {
      const m = TemplateMetadata(
        description: 'real',
        extras: {'description': 'shadow'},
      );
      final decoded = jsonDecode(m.toJsonString()) as Map<String, dynamic>;

      expect(decoded['description'], 'real');
    });

    test('round-trips via fromJsonString/toJsonString', () {
      const original = TemplateMetadata(
        description: 'rt',
        tags: ['a', 'b'],
        author: 'n',
        createdAt: '2026-05-22T00:00:00Z',
        extras: {'foo': 'bar'},
      );
      final roundTripped = TemplateMetadata.fromJsonString(
        original.toJsonString(),
      );

      expect(roundTripped.description, original.description);
      expect(roundTripped.tags, original.tags);
      expect(roundTripped.author, original.author);
      expect(roundTripped.createdAt, original.createdAt);
      expect(roundTripped.extras, original.extras);
    });
  });

  group('TemplateMetadata.isEmpty', () {
    test('returns true for the default empty value', () {
      expect(const TemplateMetadata().isEmpty, isTrue);
      expect(TemplateMetadata.empty().isEmpty, isTrue);
    });

    test('returns false when any field is set', () {
      expect(const TemplateMetadata(description: 'x').isEmpty, isFalse);
      expect(const TemplateMetadata(tags: ['a']).isEmpty, isFalse);
      expect(const TemplateMetadata(author: 'n').isEmpty, isFalse);
      expect(const TemplateMetadata(createdAt: '2026').isEmpty, isFalse);
      expect(const TemplateMetadata(extras: {'k': 'v'}).isEmpty, isFalse);
    });
  });
}
