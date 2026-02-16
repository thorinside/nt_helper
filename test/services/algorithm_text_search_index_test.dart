import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/algorithm_metadata.dart';
import 'package:nt_helper/services/algorithm_text_search_index.dart';

void main() {
  group('AlgorithmTextSearchIndex', () {
    group('tokenize', () {
      test('should lowercase all tokens', () {
        final tokens = AlgorithmTextSearchIndex.tokenize('Hello WORLD Test');
        expect(tokens, equals(['hello', 'world', 'test']));
      });

      test('should split on non-alphanumeric characters', () {
        final tokens = AlgorithmTextSearchIndex.tokenize('low-pass filter/bank');
        expect(tokens, contains('low'));
        expect(tokens, contains('pass'));
        expect(tokens, contains('filter'));
        expect(tokens, contains('bank'));
      });

      test('should remove stop words', () {
        final tokens = AlgorithmTextSearchIndex.tokenize(
          'this is a filter for the signal',
        );
        expect(tokens, isNot(contains('this')));
        expect(tokens, isNot(contains('is')));
        expect(tokens, isNot(contains('a')));
        expect(tokens, isNot(contains('for')));
        expect(tokens, isNot(contains('the')));
        expect(tokens, contains('filter'));
        expect(tokens, contains('signal'));
      });

      test('should strip trailing "ing" for stemming', () {
        final tokens = AlgorithmTextSearchIndex.tokenize('filtering processing');
        expect(tokens, contains('filter'));
        expect(tokens, contains('process'));
      });

      test('should strip trailing "ed" for stemming', () {
        final tokens = AlgorithmTextSearchIndex.tokenize('filtered processed');
        expect(tokens, contains('filter'));
        expect(tokens, contains('process'));
      });

      test('should strip trailing "s" for stemming', () {
        final tokens = AlgorithmTextSearchIndex.tokenize('filters oscillators');
        expect(tokens, contains('filter'));
        expect(tokens, contains('oscillator'));
      });

      test('should not strip "ss" endings', () {
        final tokens = AlgorithmTextSearchIndex.tokenize('bass pass');
        expect(tokens, contains('bass'));
        expect(tokens, contains('pass'));
      });

      test('should skip tokens shorter than 2 characters', () {
        final tokens = AlgorithmTextSearchIndex.tokenize('a b cd ef');
        expect(tokens, isNot(contains('b')));
        expect(tokens, contains('cd'));
        expect(tokens, contains('ef'));
      });

      test('should handle empty string', () {
        final tokens = AlgorithmTextSearchIndex.tokenize('');
        expect(tokens, isEmpty);
      });

      test('should handle special characters only', () {
        final tokens = AlgorithmTextSearchIndex.tokenize('!@#\$%^&*()');
        expect(tokens, isEmpty);
      });
    });

    group('buildIndex and search', () {
      late AlgorithmTextSearchIndex index;

      final testAlgorithms = [
        const AlgorithmMetadata(
          guid: 'revb',
          name: 'Reverb',
          categories: ['effects', 'reverb', 'audio processing'],
          description:
              'A classic algorithmic reverb effect with room simulation.',
          shortDescription: 'A general purpose reverb effect',
        ),
        const AlgorithmMetadata(
          guid: 'fsvf',
          name: 'VCF (State Variable)',
          categories: ['Filter', 'State Variable Filter'],
          description:
              'Voltage controlled filter with low, band, and highpass responses.',
          shortDescription: 'Second order LP/BP/HP filter',
        ),
        const AlgorithmMetadata(
          guid: 'dels',
          name: 'Stereo Delay',
          categories: ['effects', 'delay'],
          description:
              'A stereo delay effect with feedback and tempo sync capabilities.',
          shortDescription: 'Stereo delay with sync',
        ),
        const AlgorithmMetadata(
          guid: 'clck',
          name: 'Clock',
          categories: ['utility', 'clock'],
          description:
              'A master clock generator for tempo synchronization.',
          shortDescription: 'Master clock source',
        ),
        const AlgorithmMetadata(
          guid: 'oscs',
          name: 'Oscillator',
          categories: ['sound source', 'oscillator'],
          description:
              'A multi-waveform oscillator with sine, saw, square and triangle.',
          shortDescription: 'Multi-waveform VCO',
        ),
      ];

      setUp(() {
        index = AlgorithmTextSearchIndex();
        index.buildIndex(testAlgorithms);
      });

      test('should return empty map for empty query', () {
        final results = index.search('');
        expect(results, isEmpty);
      });

      test('should find algorithm by name keyword', () {
        final results = index.search('reverb');
        expect(results, contains('revb'));
        expect(results['revb']!, greaterThan(0));
      });

      test('should find algorithm by description keyword', () {
        final results = index.search('feedback');
        expect(results, contains('dels'));
      });

      test('should find algorithm by category keyword', () {
        final results = index.search('utility');
        expect(results, contains('clck'));
      });

      test('should rank name matches higher than description matches', () {
        final results = index.search('reverb');
        // 'revb' has "Reverb" in name (weight 10) and category (weight 5)
        // Should score highest
        expect(results['revb']!, equals(1.0)); // Normalized max
      });

      test('should find via synonym expansion', () {
        // "echo" should find delay algorithms via synonym
        final results = index.search('echo');
        expect(results, contains('dels'));
      });

      test('should score direct matches higher than synonym matches', () {
        final results = index.search('delay');
        // Direct match on 'dels' should score higher than
        // any synonym-only matches
        expect(results, contains('dels'));
        expect(results['dels']!, equals(1.0));
      });

      test('should handle multi-word queries', () {
        final results = index.search('clock generator');
        expect(results, contains('clck'));
      });

      test('should normalize scores to 0-1 range', () {
        final results = index.search('filter');
        for (final score in results.values) {
          expect(score, greaterThanOrEqualTo(0.0));
          expect(score, lessThanOrEqualTo(1.0));
        }
      });

      test('should return empty for completely unrelated query', () {
        final results = index.search('zzzzznotaword');
        expect(results, isEmpty);
      });

      test('should handle special characters in query', () {
        final results = index.search('low-pass filter!');
        expect(results, contains('fsvf'));
      });
    });

    group('field weighting', () {
      late AlgorithmTextSearchIndex index;

      setUp(() {
        index = AlgorithmTextSearchIndex();
        index.buildIndex([
          const AlgorithmMetadata(
            guid: 'name_match',
            name: 'Resonance',
            categories: ['other'],
            description: 'Something unrelated.',
          ),
          const AlgorithmMetadata(
            guid: 'desc_match',
            name: 'Other Algorithm',
            categories: ['other'],
            description: 'Has resonance in the description.',
          ),
        ]);
      });

      test('should weight name matches higher than description matches', () {
        final results = index.search('resonance');
        expect(results, contains('name_match'));
        expect(results, contains('desc_match'));
        expect(results['name_match']!, greaterThan(results['desc_match']!));
      });
    });

    group('edge cases', () {
      test('should handle building index with empty list', () {
        final index = AlgorithmTextSearchIndex();
        index.buildIndex([]);
        final results = index.search('reverb');
        expect(results, isEmpty);
      });

      test('should handle algorithm with minimal fields', () {
        final index = AlgorithmTextSearchIndex();
        index.buildIndex([
          const AlgorithmMetadata(
            guid: 'min',
            name: 'Minimal',
            categories: [],
            description: '',
          ),
        ]);
        final results = index.search('minimal');
        expect(results, contains('min'));
      });

      test('should handle rebuilding index', () {
        final index = AlgorithmTextSearchIndex();
        index.buildIndex([
          const AlgorithmMetadata(
            guid: 'first',
            name: 'First',
            categories: [],
            description: 'First algorithm',
          ),
        ]);
        // Rebuild with different data
        index.buildIndex([
          const AlgorithmMetadata(
            guid: 'second',
            name: 'Second',
            categories: [],
            description: 'Second algorithm',
          ),
        ]);
        final results = index.search('first');
        expect(results, isNot(contains('first')));
        expect(index.search('second'), contains('second'));
      });
    });
  });
}
