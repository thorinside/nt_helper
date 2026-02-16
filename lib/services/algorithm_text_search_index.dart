import 'dart:math' as math;
import 'package:nt_helper/models/algorithm_metadata.dart';

class AlgorithmTextSearchIndex {
  static const double _k1 = 1.5;
  static const double _b = 0.75;
  static const double _synonymWeight = 0.5;

  static const Map<String, double> _fieldWeights = {
    'name': 10.0,
    'shortDescription': 7.0,
    'useCases': 6.0,
    'categories': 5.0,
    'description': 3.0,
    'parameterNames': 2.0,
    'portNames': 1.5,
  };

  static const Map<String, List<String>> _synonyms = {
    'echo': ['delay', 'repeat', 'feedback'],
    'delay': ['echo', 'repeat', 'feedback'],
    'reverb': ['room', 'hall', 'space', 'ambience', 'reflection'],
    'room': ['reverb', 'hall', 'space'],
    'hall': ['reverb', 'room', 'space'],
    'wobble': ['modulation', 'lfo', 'vibrato', 'tremolo'],
    'modulation': ['lfo', 'wobble', 'vibrato', 'tremolo', 'chorus'],
    'lfo': ['modulation', 'wobble', 'oscillator'],
    'vibrato': ['modulation', 'pitch', 'lfo', 'wobble'],
    'tremolo': ['modulation', 'amplitude', 'lfo', 'wobble'],
    'filter': ['vcf', 'lowpass', 'highpass', 'bandpass', 'cutoff'],
    'vcf': ['filter', 'lowpass', 'highpass', 'bandpass'],
    'lowpass': ['filter', 'vcf', 'low', 'bass'],
    'highpass': ['filter', 'vcf', 'high', 'treble', 'bright'],
    'bandpass': ['filter', 'vcf', 'band'],
    'cutoff': ['filter', 'frequency', 'vcf'],
    'resonance': ['filter', 'q', 'emphasis', 'peak'],
    'oscillator': ['vco', 'tone', 'synth', 'waveform', 'generator'],
    'vco': ['oscillator', 'tone', 'synth', 'waveform'],
    'waveform': ['oscillator', 'shape', 'wave'],
    'envelope': ['adsr', 'attack', 'decay', 'sustain', 'release', 'contour'],
    'adsr': ['envelope', 'attack', 'decay', 'sustain', 'release'],
    'distortion': ['overdrive', 'saturation', 'fuzz', 'clip', 'drive'],
    'overdrive': ['distortion', 'saturation', 'drive'],
    'saturation': ['distortion', 'overdrive', 'warmth', 'drive'],
    'fuzz': ['distortion', 'clip'],
    'chorus': ['ensemble', 'modulation', 'detune', 'thicken'],
    'phaser': ['phase', 'modulation', 'sweep'],
    'flanger': ['flange', 'modulation', 'comb'],
    'pitch': ['tune', 'frequency', 'transpose', 'shift', 'semitone'],
    'shift': ['pitch', 'transpose', 'frequency'],
    'transpose': ['pitch', 'shift', 'semitone'],
    'clock': ['tempo', 'bpm', 'sync', 'timing', 'trigger'],
    'tempo': ['clock', 'bpm', 'speed', 'rate'],
    'divider': ['divide', 'subdivision', 'clock'],
    'multiplier': ['multiply', 'clock'],
    'sequencer': ['sequence', 'step', 'pattern', 'note'],
    'mixer': ['mix', 'blend', 'crossfade', 'sum', 'combine'],
    'compressor': ['compression', 'dynamics', 'limiter', 'squeeze'],
    'limiter': ['compressor', 'dynamics', 'ceiling'],
    'noise': ['random', 'white', 'pink', 'static'],
    'random': ['noise', 'chance', 'probability', 'stochastic'],
    'quantize': ['quantizer', 'scale', 'chromatic', 'note', 'tune'],
    'quantizer': ['quantize', 'scale', 'chromatic'],
    'sample': ['sampler', 'playback', 'audio', 'recording', 'wav'],
    'sampler': ['sample', 'playback', 'recording'],
    'looper': ['loop', 'record', 'playback', 'overdub'],
    'loop': ['looper', 'record', 'playback'],
    'gate': ['trigger', 'pulse', 'cv', 'on', 'off'],
    'trigger': ['gate', 'pulse', 'clock', 'bang'],
    'slew': ['glide', 'portamento', 'lag', 'smooth'],
    'glide': ['slew', 'portamento', 'lag'],
    'attenuator': ['attenuate', 'scale', 'level', 'gain', 'volume'],
    'amplifier': ['amp', 'gain', 'vca', 'boost', 'volume'],
    'vca': ['amplifier', 'gain', 'volume', 'level'],
    'eq': ['equalizer', 'tone', 'frequency', 'boost', 'cut'],
    'equalizer': ['eq', 'tone', 'frequency'],
    'pan': ['panner', 'stereo', 'spatial', 'balance'],
    'stereo': ['pan', 'dual', 'wide', 'spatial'],
    'wavetable': ['wave', 'oscillator', 'morph', 'scan'],
    'granular': ['grain', 'texture', 'cloud', 'particle'],
  };

  static const Set<String> _stopWords = {
    'a', 'an', 'the', 'is', 'it', 'in', 'on', 'of', 'to', 'for',
    'and', 'or', 'but', 'not', 'with', 'from', 'by', 'at', 'as',
    'this', 'that', 'be', 'are', 'was', 'were', 'been', 'has', 'have',
    'had', 'do', 'does', 'did', 'will', 'can', 'may', 'which', 'its',
  };

  // term -> (guid -> _TermInfo)
  final Map<String, Map<String, _TermInfo>> _invertedIndex = {};
  final Map<String, int> _docLengths = {};
  double _avgDocLength = 0.0;
  int _totalDocs = 0;

  void buildIndex(List<AlgorithmMetadata> algorithms) {
    _invertedIndex.clear();
    _docLengths.clear();

    _totalDocs = algorithms.length;
    int totalLength = 0;

    for (final algo in algorithms) {
      final guid = algo.guid;
      final fieldTexts = _extractFieldTexts(algo);

      int docLength = 0;
      for (final entry in fieldTexts.entries) {
        final fieldName = entry.key;
        final text = entry.value;
        final weight = _fieldWeights[fieldName] ?? 1.0;
        final tokens = tokenize(text);
        docLength += tokens.length;

        final termFreqs = <String, int>{};
        for (final token in tokens) {
          termFreqs[token] = (termFreqs[token] ?? 0) + 1;
        }

        for (final termEntry in termFreqs.entries) {
          final term = termEntry.key;
          final freq = termEntry.value;

          _invertedIndex.putIfAbsent(term, () => {});
          final existing = _invertedIndex[term]![guid];
          if (existing != null) {
            _invertedIndex[term]![guid] = _TermInfo(
              frequency: existing.frequency + freq,
              maxFieldWeight: math.max(existing.maxFieldWeight, weight),
            );
          } else {
            _invertedIndex[term]![guid] = _TermInfo(
              frequency: freq,
              maxFieldWeight: weight,
            );
          }
        }
      }

      _docLengths[guid] = docLength;
      totalLength += docLength;
    }

    _avgDocLength = _totalDocs > 0 ? totalLength / _totalDocs : 0.0;
  }

  Map<String, double> search(String query) {
    if (query.isEmpty) return {};

    final queryTokens = tokenize(query);
    if (queryTokens.isEmpty) return {};

    // Expand with synonyms
    final expandedTerms = <String, double>{};
    for (final token in queryTokens) {
      expandedTerms[token] = 1.0;
      final synonyms = _synonyms[token];
      if (synonyms != null) {
        for (final syn in synonyms) {
          if (!expandedTerms.containsKey(syn)) {
            expandedTerms[syn] = _synonymWeight;
          }
        }
      }
    }

    // Score each document
    final scores = <String, double>{};
    for (final termEntry in expandedTerms.entries) {
      final term = termEntry.key;
      final termWeight = termEntry.value;
      final postings = _invertedIndex[term];
      if (postings == null) continue;

      final df = postings.length;
      final idf = math.log((_totalDocs - df + 0.5) / (df + 0.5) + 1.0);

      for (final docEntry in postings.entries) {
        final guid = docEntry.key;
        final info = docEntry.value;
        final tf = info.frequency;
        final dl = _docLengths[guid] ?? 0;
        final fieldWeight = info.maxFieldWeight;

        final numerator = tf * (_k1 + 1);
        final denominator = tf + _k1 * (1 - _b + _b * dl / (_avgDocLength == 0 ? 1 : _avgDocLength));
        final bm25 = idf * (numerator / denominator) * fieldWeight * termWeight;

        scores[guid] = (scores[guid] ?? 0.0) + bm25;
      }
    }

    if (scores.isEmpty) return {};

    // Normalize to 0.0-1.0
    final maxScore = scores.values.reduce(math.max);
    if (maxScore <= 0) return {};

    return scores.map((guid, score) => MapEntry(guid, score / maxScore));
  }

  static List<String> tokenize(String text) {
    final tokens = <String>[];
    final words = text.toLowerCase().split(RegExp(r'[^a-z0-9]+'));
    for (final word in words) {
      if (word.length < 2) continue;
      if (_stopWords.contains(word)) continue;
      tokens.add(_stem(word));
    }
    return tokens;
  }

  static String _stem(String word) {
    if (word.length > 4 && word.endsWith('ing')) {
      return word.substring(0, word.length - 3);
    }
    if (word.length > 3 && word.endsWith('ed')) {
      return word.substring(0, word.length - 2);
    }
    if (word.length > 3 && word.endsWith('s') && !word.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  Map<String, String> _extractFieldTexts(AlgorithmMetadata algo) {
    final texts = <String, String>{};

    texts['name'] = algo.name;
    texts['shortDescription'] = algo.shortDescription ?? '';
    texts['useCases'] = algo.useCases.join(' ');
    texts['categories'] = algo.categories.join(' ');
    texts['description'] = algo.description;

    final paramNames = algo.parameters.map((p) => p.name).join(' ');
    texts['parameterNames'] = paramNames;

    final portNames = [
      ...algo.inputPorts.map((p) => '${p.name} ${p.description ?? ""}'),
      ...algo.outputPorts.map((p) => '${p.name} ${p.description ?? ""}'),
    ].join(' ');
    texts['portNames'] = portNames;

    return texts;
  }
}

class _TermInfo {
  final int frequency;
  final double maxFieldWeight;

  _TermInfo({required this.frequency, required this.maxFieldWeight});
}
