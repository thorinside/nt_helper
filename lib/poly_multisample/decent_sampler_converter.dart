import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;

import 'poly_multisample_parser.dart';
import 'wav_metadata.dart';

class DecentSamplerConversionResult {
  const DecentSamplerConversionResult({
    required this.outputFolders,
    required this.copiedFiles,
    required this.copiedDocumentationFiles,
    required this.decisions,
    required this.warnings,
  });

  final List<String> outputFolders;
  final int copiedFiles;
  final int copiedDocumentationFiles;
  final List<String> decisions;
  final List<String> warnings;

  String get summary {
    final folderCount = outputFolders.length;
    final docText = copiedDocumentationFiles > 0
        ? ' Copied $copiedDocumentationFiles source doc/license file(s).'
        : '';
    final warningText = warnings.isEmpty
        ? 'No warnings.'
        : '${warnings.length} warning(s).';
    return 'Converted $copiedFiles WAV file(s) into $folderCount folder(s).$docText $warningText';
  }
}

enum DecentSamplerGroupHandling {
  auto,
  tagMapping,
  velocityLayers,
  keyRanges,
  splitFolders,
  selectedGroup,
  selectedTags,
}

class DecentSamplerConvertOptions {
  const DecentSamplerConvertOptions({
    this.groupHandling = DecentSamplerGroupHandling.auto,
    this.selectedPresetNames = const [],
    this.selectedGroupKey,
    this.selectedGroupKeys = const [],
    this.selectedTagKeys = const [],
    this.groupVelocityLayers = const {},
    this.groupKeyRanges = const {},
    this.groupRoundRobins = const {},
    this.tagVelocityLayers = const {},
    this.tagKeyRanges = const {},
    this.tagRoundRobins = const {},
    this.preserveXmlMapping = false,
    this.addUnmapped = false,
    this.includeSourceDocs = true,
    this.writeConversionReports = true,
  });

  final DecentSamplerGroupHandling groupHandling;
  final List<String> selectedPresetNames;
  final String? selectedGroupKey;
  final List<String> selectedGroupKeys;
  final List<String> selectedTagKeys;
  final Map<String, int> groupVelocityLayers;
  final Map<String, DecentSamplerTagKeyRange> groupKeyRanges;
  final Map<String, int> groupRoundRobins;
  final Map<String, int> tagVelocityLayers;
  final Map<String, DecentSamplerTagKeyRange> tagKeyRanges;
  final Map<String, int> tagRoundRobins;
  final bool preserveXmlMapping;
  final bool addUnmapped;
  final bool includeSourceDocs;
  final bool writeConversionReports;
}

class DecentSamplerTagKeyRange {
  const DecentSamplerTagKeyRange({
    required this.lowMidi,
    required this.rootMidi,
    required this.highMidi,
    this.enabled = true,
  });

  final int lowMidi;
  final int rootMidi;
  final int highMidi;
  final bool enabled;
}

class DecentSamplerGroupInfo {
  const DecentSamplerGroupInfo({
    required this.key,
    required this.name,
    required this.xmlSummary,
    required this.sampleCount,
    required this.rootCount,
    required this.structureSummary,
    required this.noteRange,
    required this.velocitySummary,
    required this.roundRobinSummary,
    required this.examples,
    required this.defaultLowMidi,
    required this.defaultRootMidi,
    required this.defaultHighMidi,
    required this.defaultVelocityLayer,
    this.presetName,
    this.previewSourcePath,
  });

  final String key;
  final String name;
  final String xmlSummary;
  final int sampleCount;
  final int rootCount;
  final String structureSummary;
  final String noteRange;
  final String velocitySummary;
  final String roundRobinSummary;
  final List<String> examples;
  final int defaultLowMidi;
  final int defaultRootMidi;
  final int defaultHighMidi;
  final int defaultVelocityLayer;
  final String? presetName;
  final String? previewSourcePath;

  DecentSamplerGroupInfo withDisplayName(String displayName) {
    return DecentSamplerGroupInfo(
      key: key,
      name: displayName,
      xmlSummary: xmlSummary,
      sampleCount: sampleCount,
      rootCount: rootCount,
      structureSummary: structureSummary,
      noteRange: noteRange,
      velocitySummary: velocitySummary,
      roundRobinSummary: roundRobinSummary,
      examples: examples,
      defaultLowMidi: defaultLowMidi,
      defaultRootMidi: defaultRootMidi,
      defaultHighMidi: defaultHighMidi,
      defaultVelocityLayer: defaultVelocityLayer,
      presetName: presetName,
      previewSourcePath: previewSourcePath,
    );
  }

  DecentSamplerGroupInfo withPresetName(String value) {
    return DecentSamplerGroupInfo(
      key: key,
      name: name,
      xmlSummary: xmlSummary,
      sampleCount: sampleCount,
      rootCount: rootCount,
      structureSummary: structureSummary,
      noteRange: noteRange,
      velocitySummary: velocitySummary,
      roundRobinSummary: roundRobinSummary,
      examples: examples,
      defaultLowMidi: defaultLowMidi,
      defaultRootMidi: defaultRootMidi,
      defaultHighMidi: defaultHighMidi,
      defaultVelocityLayer: defaultVelocityLayer,
      presetName: value,
      previewSourcePath: previewSourcePath,
    );
  }
}

class DecentSamplerTag {
  const DecentSamplerTag({
    required this.key,
    required this.label,
    required this.groupKeys,
    required this.sampleCount,
    required this.confidence,
    required this.evidence,
    required this.structureSummary,
    required this.noteRange,
    required this.velocitySummary,
    required this.roundRobinSummary,
    required this.defaultLowMidi,
    required this.defaultRootMidi,
    required this.defaultHighMidi,
    required this.defaultVelocityLayer,
    this.presetName,
    this.previewSourcePath,
  });

  final String key;
  final String label;
  final List<String> groupKeys;
  final int sampleCount;
  final double confidence;
  final String evidence;
  final String structureSummary;
  final String noteRange;
  final String velocitySummary;
  final String roundRobinSummary;
  final int defaultLowMidi;
  final int defaultRootMidi;
  final int defaultHighMidi;
  final int defaultVelocityLayer;
  final String? presetName;
  final String? previewSourcePath;

  DecentSamplerTag withPresetName(String value) {
    return DecentSamplerTag(
      key: key,
      label: label,
      groupKeys: groupKeys,
      sampleCount: sampleCount,
      confidence: confidence,
      evidence: evidence,
      structureSummary: structureSummary,
      noteRange: noteRange,
      velocitySummary: velocitySummary,
      roundRobinSummary: roundRobinSummary,
      defaultLowMidi: defaultLowMidi,
      defaultRootMidi: defaultRootMidi,
      defaultHighMidi: defaultHighMidi,
      defaultVelocityLayer: defaultVelocityLayer,
      presetName: value,
      previewSourcePath: previewSourcePath,
    );
  }
}

class DecentSamplerPresetInfo {
  const DecentSamplerPresetInfo({
    required this.name,
    required this.groupCount,
    required this.sampleCount,
    required this.tagCount,
  });

  final String name;
  final int groupCount;
  final int sampleCount;
  final int tagCount;
}

class DecentSamplerImportAnalysis {
  const DecentSamplerImportAnalysis({
    required this.presetName,
    required this.presets,
    required this.groups,
    required this.tags,
    required this.hasAmbiguousOverlaps,
    required this.structureSummary,
    required this.recommendedGroupHandling,
  });

  final String presetName;
  final List<DecentSamplerPresetInfo> presets;
  final List<DecentSamplerGroupInfo> groups;
  final List<DecentSamplerTag> tags;
  final bool hasAmbiguousOverlaps;
  final String structureSummary;
  final DecentSamplerGroupHandling recommendedGroupHandling;
}

class DecentSamplerConverter {
  static const _supportedInputExtensions = {'.dspreset', '.dslibrary', '.zip'};

  Future<DecentSamplerConversionResult> convert({
    required String sourcePath,
    required String outputParentPath,
    DecentSamplerConvertOptions options = const DecentSamplerConvertOptions(),
  }) async {
    final extension = p.extension(sourcePath).toLowerCase();
    final sourceDirectory = Directory(sourcePath);
    final isDirectory = await sourceDirectory.exists();
    if (!isDirectory && !_supportedInputExtensions.contains(extension)) {
      throw FormatException('Unsupported Decent source: $extension');
    }

    final sourceFile = File(sourcePath);
    final sourceName = isDirectory
        ? p.basename(sourcePath)
        : p.basenameWithoutExtension(sourcePath);
    final decisions = <String>[];
    final warnings = <String>[];
    final plans = isDirectory
        ? await _readDirectory(
            sourceDirectory,
            sourceName,
            decisions,
            warnings,
            options,
          )
        : extension == '.dspreset'
        ? await _readDspreset(
            sourceFile,
            sourceName,
            decisions,
            warnings,
            options,
          )
        : await _readArchive(
            sourceFile,
            sourceName,
            decisions,
            warnings,
            options,
          );

    if (plans.isEmpty) {
      throw const FormatException('No Decent Sampler preset found.');
    }

    final outputFolders = <String>[];
    var copiedFiles = 0;
    var copiedDocumentationFiles = 0;
    for (final plan in plans) {
      final outputFolder = await _createOutputFolder(
        outputParentPath,
        plan.presetName,
      );
      outputFolders.add(outputFolder.path);
      copiedFiles += await _writePlan(plan, outputFolder, warnings);
      copiedDocumentationFiles += await _copySourceDocs(
        plan,
        outputFolder,
        warnings,
      );
      if (options.writeConversionReports) {
        await _writeReport(plan, outputFolder, decisions, warnings);
      }
    }

    return DecentSamplerConversionResult(
      outputFolders: outputFolders,
      copiedFiles: copiedFiles,
      copiedDocumentationFiles: copiedDocumentationFiles,
      decisions: decisions,
      warnings: warnings,
    );
  }

  Future<DecentSamplerImportAnalysis> analyze({
    required String sourcePath,
  }) async {
    final extension = p.extension(sourcePath).toLowerCase();
    final sourceDirectory = Directory(sourcePath);
    final isDirectory = await sourceDirectory.exists();
    if (!isDirectory && !_supportedInputExtensions.contains(extension)) {
      throw FormatException('Unsupported Decent source: $extension');
    }

    final sourceFile = File(sourcePath);
    final sourceName = isDirectory
        ? p.basename(sourcePath)
        : p.basenameWithoutExtension(sourcePath);
    final presetAnalyses = isDirectory
        ? await _analyzeDirectoryPresets(sourceDirectory, sourceName)
        : extension == '.dspreset'
        ? [
            _analyzePresetContent(
              _safeFileStem(sourceName),
              _fixInvalidXml(_decodeXmlText(await sourceFile.readAsBytes())),
            ),
          ]
        : await _analyzeArchivePresets(sourceFile, sourceName);
    final presets = <DecentSamplerPresetInfo>[];
    final groups = <DecentSamplerGroupInfo>[];
    final presetTags = <DecentSamplerTag>[];
    final tagBuilders = <String, _MutableDecentTag>{};
    var hasAmbiguousOverlaps = false;
    final showPresetNames = presetAnalyses.length > 1;
    final summaries = <String>[];
    final recommendations = <DecentSamplerGroupHandling>{};
    for (final analysis in presetAnalyses) {
      presets.addAll(analysis.presets);
      hasAmbiguousOverlaps =
          hasAmbiguousOverlaps || analysis.hasAmbiguousOverlaps;
      recommendations.add(analysis.recommendedGroupHandling);
      if (analysis.structureSummary.isNotEmpty) {
        summaries.add(
          showPresetNames
              ? '${analysis.presetName}: ${analysis.structureSummary}'
              : analysis.structureSummary,
        );
      }
      groups.addAll(
        analysis.groups.map(
          (group) => showPresetNames
              ? group.withDisplayName('${analysis.presetName} / ${group.name}')
              : group,
        ),
      );
      presetTags.addAll(analysis.tags);
      for (final tag in analysis.tags) {
        final builder = tagBuilders.putIfAbsent(
          tag.key,
          () => _MutableDecentTag(
            label: tag.label,
            confidence: tag.confidence,
            evidence: tag.evidence,
          ),
        );
        builder.sampleCount += tag.sampleCount;
        builder.confidence = math.max(builder.confidence, tag.confidence);
        if (builder.evidence.length < tag.evidence.length) {
          builder.evidence = tag.evidence;
        }
        builder.groupKeys.addAll(tag.groupKeys);
        builder.defaultLowMidi ??= tag.defaultLowMidi;
        builder.defaultRootMidi ??= tag.defaultRootMidi;
        builder.defaultHighMidi = math.max(
          builder.defaultHighMidi ?? tag.defaultHighMidi,
          tag.defaultHighMidi,
        );
        builder.defaultVelocityLayer ??= tag.defaultVelocityLayer;
        builder.structureSummary ??= tag.structureSummary;
        builder.noteRange ??= tag.noteRange;
        builder.velocitySummary ??= tag.velocitySummary;
        builder.roundRobinSummary ??= tag.roundRobinSummary;
        builder.previewSourcePath ??= tag.previewSourcePath;
      }
    }
    final tags =
        (showPresetNames
              ? presetTags
              : tagBuilders.entries
                    .map(
                      (entry) =>
                          entry.value.toTag(entry.key, entry.value.defaults),
                    )
                    .toList())
          ..sort(_compareDecentTags);
    return DecentSamplerImportAnalysis(
      presetName: _safeFileStem(sourceName),
      presets: presets,
      groups: groups,
      tags: tags,
      hasAmbiguousOverlaps: hasAmbiguousOverlaps,
      structureSummary: summaries.join('\n'),
      recommendedGroupHandling: _mergeRecommendations(recommendations),
    );
  }

  Future<List<DecentSamplerImportAnalysis>> _analyzeDirectoryPresets(
    Directory directory,
    String fallbackName,
  ) async {
    final presetFiles = await _presetFilesInDirectory(directory);
    if (presetFiles.isEmpty) {
      throw const FormatException('No Decent Sampler preset found.');
    }
    return [
      for (final file in presetFiles)
        _analyzePresetContent(
          p.basenameWithoutExtension(file.path).isEmpty
              ? _safeFileStem(fallbackName)
              : _safeFileStem(p.basenameWithoutExtension(file.path)),
          _fixInvalidXml(_decodeXmlText(await file.readAsBytes())),
        ),
    ];
  }

  Future<List<DecentSamplerImportAnalysis>> _analyzeArchivePresets(
    File file,
    String fallbackName,
  ) async {
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final presetFiles =
        archive
            .where(
              (entry) =>
                  entry.isFile &&
                  !_isMacOsJunkPath(entry.name) &&
                  entry.name.toLowerCase().endsWith('.dspreset'),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    if (presetFiles.isEmpty) {
      throw const FormatException('No Decent Sampler preset found.');
    }
    return [
      for (final entry in presetFiles)
        _analyzePresetContent(
          p.posix.basenameWithoutExtension(entry.name).isEmpty
              ? _safeFileStem(fallbackName)
              : _safeFileStem(p.posix.basenameWithoutExtension(entry.name)),
          _fixInvalidXml(_decodeXmlText(entry.content as List<int>)),
        ),
    ];
  }

  DecentSamplerImportAnalysis _analyzePresetContent(
    String presetName,
    String content,
  ) {
    final groups = _sampleGroups(content);
    final warnings = <String>[];
    final rawRegions = _rawRegionsFromGroups(groups, presetName, warnings);
    final groupInfos = [
      for (final group in groups)
        _groupInfoFor(group, rawRegions).withPresetName(presetName),
    ];
    final tags = [
      for (final tag in _tagsForGroups(groups, rawRegions))
        tag.withPresetName(presetName),
    ];
    final structureParts = [
      _structureSummary(groups, rawRegions, content),
      _uiGroupBindingSummary(content),
    ].where((part) => part.isNotEmpty).toList();
    return DecentSamplerImportAnalysis(
      presetName: presetName,
      presets: [
        DecentSamplerPresetInfo(
          name: presetName,
          groupCount: groups.length,
          sampleCount: rawRegions.length,
          tagCount: tags.length,
        ),
      ],
      groups: groupInfos,
      tags: tags,
      hasAmbiguousOverlaps: _hasAmbiguousGroupOverlaps(rawRegions),
      structureSummary: structureParts.join('; '),
      recommendedGroupHandling: _recommendedGroupHandling(rawRegions),
    );
  }

  Future<List<_DecentPresetPlan>> _readDirectory(
    Directory directory,
    String fallbackName,
    List<String> decisions,
    List<String> warnings,
    DecentSamplerConvertOptions options,
  ) async {
    final presetFiles = await _presetFilesInDirectory(directory);
    if (presetFiles.isEmpty) {
      warnings.add('${directory.path} contains no .dspreset file.');
      return const [];
    }

    final plans = <_DecentPresetPlan>[];
    final selectedPresetNames = _selectedPresetNames(options);
    for (final file in presetFiles) {
      final resolver = _LocalDecentSourceResolver(
        baseDirectory: file.parent.path,
        allowedRoot: _localPresetAllowedRoot(file),
      );
      final sourceDocs = options.includeSourceDocs
          ? await _sourceDocsForLocalDirectory(file.parent)
          : const <_DecentSourceDoc>[];
      final presetName = p.basenameWithoutExtension(file.path);
      final actualPresetName = presetName.isEmpty
          ? _safeFileStem(fallbackName)
          : _safeFileStem(presetName);
      if (!_presetIsSelected(actualPresetName, selectedPresetNames)) continue;
      final presets = _parsePresetXml(
        _fixInvalidXml(_decodeXmlText(await file.readAsBytes())),
        presetName: actualPresetName,
        decisions: decisions,
        warnings: warnings,
        options: options,
      );
      plans.addAll(
        presets.map(
          (preset) =>
              preset.copyWith(sourceResolver: resolver, sourceDocs: sourceDocs),
        ),
      );
    }
    return plans;
  }

  Future<List<_DecentPresetPlan>> _readDspreset(
    File file,
    String fallbackName,
    List<String> decisions,
    List<String> warnings,
    DecentSamplerConvertOptions options,
  ) async {
    final selectedPresetNames = _selectedPresetNames(options);
    if (!_presetIsSelected(_safeFileStem(fallbackName), selectedPresetNames)) {
      return const [];
    }
    final content = _fixInvalidXml(_decodeXmlText(await file.readAsBytes()));
    final presets = _parsePresetXml(
      content,
      presetName: fallbackName,
      decisions: decisions,
      warnings: warnings,
      options: options,
    );
    final baseDir = file.parent.path;
    final commonParent = _localPresetAllowedRoot(file);
    final sourceDocs = options.includeSourceDocs
        ? await _sourceDocsForLocalDirectory(file.parent)
        : const <_DecentSourceDoc>[];
    return [
      for (final preset in presets)
        preset.copyWith(
          sourceResolver: _LocalDecentSourceResolver(
            baseDirectory: baseDir,
            allowedRoot: commonParent,
          ),
          sourceDocs: sourceDocs,
        ),
    ];
  }

  String _localPresetAllowedRoot(File file) => file.parent.parent.path;

  Future<List<_DecentPresetPlan>> _readArchive(
    File file,
    String fallbackName,
    List<String> decisions,
    List<String> warnings,
    DecentSamplerConvertOptions options,
  ) async {
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final files = archive.where((entry) {
      if (!entry.isFile || _isMacOsJunkPath(entry.name)) return false;
      if (_isUnsafeArchiveEntryPath(entry.name)) {
        warnings.add('Skipped unsafe archive path ${entry.name}.');
        return false;
      }
      return true;
    }).toList();
    final presetFiles =
        files
            .where((entry) => entry.name.toLowerCase().endsWith('.dspreset'))
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    if (presetFiles.isEmpty) {
      warnings.add('${p.basename(file.path)} contains no .dspreset file.');
      return const [];
    }

    final archiveFiles = {
      for (final entry in files) _normalizeZipPath(entry.name): entry,
    };
    final archiveDocs = options.includeSourceDocs
        ? _sourceDocsForArchive(files)
        : const <_DecentSourceDoc>[];
    final plans = <_DecentPresetPlan>[];
    final selectedPresetNames = _selectedPresetNames(options);
    for (final entry in presetFiles) {
      final content = _fixInvalidXml(
        _decodeXmlText(entry.content as List<int>),
      );
      final presetName = p.posix.basenameWithoutExtension(entry.name);
      final actualPresetName = presetName.isEmpty
          ? _safeFileStem(fallbackName)
          : _safeFileStem(presetName);
      if (!_presetIsSelected(actualPresetName, selectedPresetNames)) continue;
      final presetDirectory = p.posix.dirname(_normalizeZipPath(entry.name));
      final presets = _parsePresetXml(
        content,
        presetName: actualPresetName,
        decisions: decisions,
        warnings: warnings,
        options: options,
      );
      plans.addAll(
        presets.map(
          (preset) => preset.copyWith(
            sourceResolver: _ArchiveDecentSourceResolver(
              files: archiveFiles,
              presetDirectory: presetDirectory,
            ),
            sourceDocs: _sourceDocsForArchivePreset(
              archiveDocs,
              presetDirectory,
            ),
          ),
        ),
      );
    }
    return plans;
  }

  Future<List<File>> _presetFilesInDirectory(Directory directory) async {
    final files = <File>[];
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final normalized = entity.path.replaceAll('\\', '/');
      if (_isMacOsJunkPath(normalized)) continue;
      if (!entity.path.toLowerCase().endsWith('.dspreset')) continue;
      files.add(entity);
    }
    files.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    return files;
  }

  static Set<String> _selectedPresetNames(DecentSamplerConvertOptions options) {
    return {for (final name in options.selectedPresetNames) _safeFileStem(name)}
      ..removeWhere((name) => name.trim().isEmpty);
  }

  static bool _presetIsSelected(String presetName, Set<String> selectedNames) {
    return selectedNames.isEmpty ||
        selectedNames.contains(_safeFileStem(presetName));
  }

  List<_DecentPresetPlan> _parsePresetXml(
    String content, {
    required String presetName,
    required List<String> decisions,
    required List<String> warnings,
    required DecentSamplerConvertOptions options,
  }) {
    final sampleGroups = _sampleGroups(content);
    if (sampleGroups.isEmpty) {
      warnings.add('$presetName has no <sample> entries.');
    }

    final rawRegions = _rawRegionsFromGroups(
      sampleGroups,
      presetName,
      warnings,
    );
    final selectedGroupKeys = options.selectedGroupKeys.toSet();
    final selectedTagKeys = options.selectedTagKeys.toSet();
    final availableTags = _tagsForGroups(sampleGroups, rawRegions);
    final availableTagKeys = {for (final tag in availableTags) tag.key};
    final selectedTagLabels = [
      for (final tag in availableTags)
        if (selectedTagKeys.contains(tag.key)) tag.label,
    ];
    final explicitVelocityTagKeys = options.tagVelocityLayers.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .where(selectedTagKeys.contains)
        .toSet();
    final explicitRangeTagKeys = options.tagKeyRanges.keys
        .where(
          (key) =>
              selectedTagKeys.contains(key) &&
              (options.tagKeyRanges[key]?.enabled ?? false),
        )
        .toSet();
    final explicitMappedTagKeys = {
      ...explicitVelocityTagKeys,
      ...explicitRangeTagKeys,
    };
    final materialTagKeys = explicitMappedTagKeys.isEmpty
        ? explicitMappedTagKeys
        : selectedTagKeys;
    final hasExplicitVelocityTags =
        (options.groupHandling == DecentSamplerGroupHandling.tagMapping ||
            options.groupHandling ==
                DecentSamplerGroupHandling.velocityLayers) &&
        explicitVelocityTagKeys.isNotEmpty;
    final hasExplicitRangeTags =
        (options.groupHandling == DecentSamplerGroupHandling.tagMapping ||
            options.groupHandling == DecentSamplerGroupHandling.keyRanges) &&
        explicitRangeTagKeys.isNotEmpty;
    final shouldFilterByTags =
        selectedTagKeys.isNotEmpty &&
        availableTagKeys.isNotEmpty &&
        (hasExplicitVelocityTags ||
            hasExplicitRangeTags ||
            !selectedTagKeys.containsAll(availableTagKeys));
    var regionsForSelectedScope = shouldFilterByTags
        ? _filterRegionsForSelectedTags(
            rawRegions,
            selectedTagKeys,
            materialTagKeys,
            options.groupHandling,
          )
        : rawRegions;
    if (shouldFilterByTags) {
      decisions.add(
        '$presetName: limited import to selected tags (${selectedTagLabels.join(', ')}).',
      );
    }
    if (selectedGroupKeys.isNotEmpty) {
      final selectedGroupNames = [
        for (final group in sampleGroups)
          if (selectedGroupKeys.contains(
            _groupKeyFromParts(group.index, group.name),
          ))
            group.name,
      ];
      regionsForSelectedScope = rawRegions
          .where((region) => selectedGroupKeys.contains(_groupKey(region)))
          .toList();
      decisions.add(
        '$presetName: limited import to selected XML groups (${selectedGroupNames.join(', ')}).',
      );
    }
    if (options.groupHandling == DecentSamplerGroupHandling.splitFolders) {
      final tagPlans = _selectedTagPlans(
        sampleGroups,
        rawRegions,
        options.selectedTagKeys,
      );
      if (tagPlans.isNotEmpty) {
        final plans = <_DecentPresetPlan>[];
        for (final tagPlan in tagPlans) {
          final tagRegions = rawRegions
              .where((region) => region.tagKeys.any(tagPlan.tagKeys.contains))
              .toList();
          if (tagRegions.isEmpty) continue;
          final outputName = '${presetName}_${tagPlan.label}';
          decisions.add(
            '$presetName: split selected tag `${tagPlan.label}` into its own output folder.',
          );
          plans.add(
            _DecentPresetPlan(
              presetName: _safeFileStem(outputName),
              regions: _mapRawRegions(
                tagRegions,
                outputName,
                decisions,
                warnings,
                const DecentSamplerConvertOptions(),
              ),
              sourceResolver: const _MissingDecentSourceResolver(),
              sourceDocs: const [],
            ),
          );
        }
        if (plans.isNotEmpty) return plans;
      }
      final plans = <_DecentPresetPlan>[];
      final splitGroups = _splitFolderGroups(regionsForSelectedScope);
      for (final splitGroup in splitGroups) {
        decisions.add(
          '$presetName: split `${splitGroup.label}` into its own output folder.',
        );
        plans.add(
          _DecentPresetPlan(
            presetName: _safeFileStem('${presetName}_${splitGroup.label}'),
            regions: _mapRawRegions(
              splitGroup.regions,
              '${presetName}_${splitGroup.label}',
              decisions,
              warnings,
              const DecentSamplerConvertOptions(),
            ),
            sourceResolver: const _MissingDecentSourceResolver(),
            sourceDocs: const [],
          ),
        );
      }
      return plans;
    }

    var regionsToMap = regionsForSelectedScope;
    if (options.groupHandling == DecentSamplerGroupHandling.selectedGroup) {
      final selectedKey = options.selectedGroupKey;
      regionsToMap = rawRegions
          .where((region) => _groupKey(region) == selectedKey)
          .toList();
      final selectedName = _groupNameForKey(sampleGroups, selectedKey);
      decisions.add(
        '$presetName: converted selected group `${selectedName ?? selectedKey ?? 'unknown'}` only.',
      );
    }

    return [
      _DecentPresetPlan(
        presetName: _safeFileStem(presetName),
        regions: _mapRawRegions(
          regionsToMap,
          presetName,
          decisions,
          warnings,
          options,
        ),
        sourceResolver: const _MissingDecentSourceResolver(),
        sourceDocs: const [],
      ),
    ];
  }

  static List<_DecentRawRegion> _filterRegionsForSelectedTags(
    List<_DecentRawRegion> rawRegions,
    Set<String> selectedTagKeys,
    Set<String> explicitlyMappedTagKeys,
    DecentSamplerGroupHandling handling,
  ) {
    if ((handling == DecentSamplerGroupHandling.tagMapping ||
            handling == DecentSamplerGroupHandling.velocityLayers ||
            handling == DecentSamplerGroupHandling.keyRanges) &&
        explicitlyMappedTagKeys.isNotEmpty) {
      final filterOnlyTagKeys = selectedTagKeys.difference(
        explicitlyMappedTagKeys,
      );
      final mappedRegions = rawRegions.where((region) {
        if (!region.tagKeys.any(explicitlyMappedTagKeys.contains)) {
          return false;
        }
        return true;
      }).toList();
      if (filterOnlyTagKeys.isEmpty) return mappedRegions;
      final allFilterMatches = mappedRegions
          .where((region) => filterOnlyTagKeys.every(region.tagKeys.contains))
          .toList();
      if (allFilterMatches.isNotEmpty) return allFilterMatches;
      final anyFilterMatches = mappedRegions
          .where((region) => region.tagKeys.any(filterOnlyTagKeys.contains))
          .toList();
      return anyFilterMatches.isNotEmpty ? anyFilterMatches : mappedRegions;
    }
    final allMatches = rawRegions
        .where((region) => selectedTagKeys.every(region.tagKeys.contains))
        .toList();
    if (allMatches.isNotEmpty) return allMatches;
    return rawRegions
        .where((region) => region.tagKeys.any(selectedTagKeys.contains))
        .toList();
  }

  List<_DecentMappedRegion> _mapRawRegions(
    List<_DecentRawRegion> rawRegions,
    String presetName,
    List<String> decisions,
    List<String> warnings,
    DecentSamplerConvertOptions options,
  ) {
    if (options.addUnmapped) {
      decisions.add('$presetName: added selected Decent samples unmapped.');
      final outputNames = <String>{};
      return [
        for (final region in rawRegions)
          _DecentMappedRegion(
            sourcePath: region.sourcePath,
            outputFileName: _uniqueOriginalSampleName(
              region.sourcePath,
              outputNames,
            ),
            groupName: region.groupName,
            rootMidi: region.rootMidi ?? 60,
            switchPoint: region.lowMidi ?? region.rootMidi ?? 60,
            velocityLayer: 1,
            roundRobin: 1,
            loopStart: region.loopStart,
            loopEnd: region.loopEnd,
          ),
      ];
    }
    final usesTagOptionMaps =
        options.groupHandling == DecentSamplerGroupHandling.tagMapping ||
        options.groupHandling == DecentSamplerGroupHandling.velocityLayers ||
        options.groupHandling == DecentSamplerGroupHandling.keyRanges ||
        options.groupHandling == DecentSamplerGroupHandling.selectedTags;
    final tagVelocityLayers = usesTagOptionMaps
        ? _forcedTagVelocityLayers(rawRegions, options)
        : null;
    final tagKeyRanges = usesTagOptionMaps
        ? _forcedTagKeyRanges(rawRegions, options)
        : null;
    final selectedGroupVelocityLayers =
        options.groupHandling == DecentSamplerGroupHandling.tagMapping ||
            options.groupHandling == DecentSamplerGroupHandling.velocityLayers
        ? _forcedSelectedGroupVelocityLayers(rawRegions, options)
        : null;
    final selectedGroupKeyRanges =
        options.groupHandling == DecentSamplerGroupHandling.tagMapping ||
            options.groupHandling == DecentSamplerGroupHandling.keyRanges
        ? _forcedSelectedGroupKeyRanges(rawRegions, options)
        : null;
    final forcedRoundRobins = usesTagOptionMaps
        ? _forcedRoundRobins(rawRegions, options)
        : const <_DecentRawRegion, int>{};
    final forcedVelocityLayerCount =
        tagVelocityLayers?.tagLayers.values.toSet().length ??
        selectedGroupVelocityLayers?.tagLayers.values.toSet().length;
    final groupVelocityLayers =
        !options.preserveXmlMapping &&
            tagVelocityLayers == null &&
            tagKeyRanges == null &&
            selectedGroupVelocityLayers == null &&
            selectedGroupKeyRanges == null
        ? options.groupHandling == DecentSamplerGroupHandling.velocityLayers
              ? _forcedGroupVelocityLayers(rawRegions)
              : _dynamicGroupVelocityLayers(rawRegions)
        : null;
    final keyRanges = tagKeyRanges ?? selectedGroupKeyRanges;
    if (tagVelocityLayers != null) {
      decisions.add(
        '$presetName: user-selected velocity layers for Decent tags '
        '(${_tagLayerSummary(tagVelocityLayers)}).',
      );
    }
    if (selectedGroupVelocityLayers != null) {
      decisions.add(
        '$presetName: user-selected velocity layers for Decent XML groups '
        '(${_tagLayerSummary(selectedGroupVelocityLayers)}).',
      );
    }
    if (forcedRoundRobins.isNotEmpty) {
      decisions.add(
        '$presetName: user-selected round robins for selected Decent tags/groups.',
      );
    }
    if (keyRanges != null) {
      decisions.add(
        tagKeyRanges != null
            ? '$presetName: user-selected key ranges for Decent tags '
                  '(${_tagRangeSummary(tagKeyRanges)}).'
            : '$presetName: user-selected key ranges for Decent XML groups '
                  '(${_tagRangeSummary(selectedGroupKeyRanges!)}).',
      );
    } else if (groupVelocityLayers != null) {
      if (options.groupHandling == DecentSamplerGroupHandling.velocityLayers) {
        decisions.add(
          '$presetName: user-selected velocity layers for Decent groups '
          '(${_groupLayerSummary(groupVelocityLayers)}).',
        );
      } else {
        decisions.add(
          '$presetName: auto-selected velocity layers for overlapping dynamic '
          'groups (${_groupLayerSummary(groupVelocityLayers)}).',
        );
      }
    } else if (tagVelocityLayers == null &&
        selectedGroupVelocityLayers == null &&
        forcedRoundRobins.isEmpty) {
      _warnAboutAmbiguousGroupOverlaps(
        rawRegions,
        presetName,
        decisions,
        warnings,
      );
    }

    final velocityKeys = <String, List<_DecentRawRegion>>{};
    for (final region in rawRegions) {
      final root = region.rootMidi;
      if (root == null) {
        warnings.add('${p.basename(region.sourcePath)} has no rootNote.');
        continue;
      }
      final low = (region.lowMidi ?? root).clamp(0, 127).toInt();
      final key = '$root|$low|${region.highMidi ?? -1}';
      velocityKeys.putIfAbsent(key, () => []).add(region);
    }

    final velocityLayerByRegion = <_DecentRawRegion, int>{};
    if (tagVelocityLayers != null) {
      velocityLayerByRegion.addAll(tagVelocityLayers.regionLayers);
    } else if (selectedGroupVelocityLayers != null) {
      velocityLayerByRegion.addAll(selectedGroupVelocityLayers.regionLayers);
    } else if (groupVelocityLayers != null) {
      for (final region in rawRegions) {
        velocityLayerByRegion[region] =
            groupVelocityLayers[_groupKey(region)] ?? 1;
      }
    } else {
      for (final group in velocityKeys.values) {
        final hasExplicitVelocity = group.any(
          (region) => region.hasExplicitVelocity,
        );
        final ranges = hasExplicitVelocity
            ? (group
                  .map(
                    (region) => '${region.velocityLow}-${region.velocityHigh}',
                  )
                  .toSet()
                  .toList()
                ..sort((a, b) {
                  final aLow = int.tryParse(a.split('-').first) ?? 1;
                  final bLow = int.tryParse(b.split('-').first) ?? 1;
                  return aLow.compareTo(bLow);
                }))
            : <String>['1-127'];
        for (final region in group) {
          final key = '${region.velocityLow}-${region.velocityHigh}';
          velocityLayerByRegion[region] = hasExplicitVelocity
              ? ranges.indexOf(key) + 1
              : 1;
        }
      }
    }

    final usedRoundRobins = <String, Set<int>>{};
    final outputNames = <String>{};
    final mapped = <_DecentMappedRegion>[];
    final mappedRootByRegion = <_DecentRawRegion, int>{};
    final mappedLowByRegion = <_DecentRawRegion, int>{};
    for (final region in rawRegions) {
      final originalRoot = region.rootMidi;
      if (originalRoot == null) continue;
      final originalLow = (region.lowMidi ?? originalRoot)
          .clamp(0, 127)
          .toInt();
      final rangeMapping = keyRanges?.regionMappings[region];
      mappedRootByRegion[region] = rangeMapping == null
          ? originalRoot
          : (rangeMapping.range.rootMidi +
                    originalRoot -
                    rangeMapping.sourceRootMidi)
                .clamp(rangeMapping.range.lowMidi, rangeMapping.range.highMidi)
                .toInt();
      mappedLowByRegion[region] = rangeMapping == null
          ? originalLow
          : (rangeMapping.range.lowMidi +
                    originalLow -
                    rangeMapping.sourceRootMidi)
                .clamp(rangeMapping.range.lowMidi, rangeMapping.range.highMidi)
                .toInt();
    }
    var repairedRoundRobinCount = 0;
    final repairedRoundRobinExamples = <String>[];
    for (final region in rawRegions) {
      final root = mappedRootByRegion[region];
      final low = mappedLowByRegion[region];
      if (root == null || low == null) continue;
      final velocityLayer = velocityLayerByRegion[region] ?? 1;
      final velocityLayerCount = rawRegions
          .where((candidate) {
            return mappedRootByRegion[candidate] == root &&
                mappedLowByRegion[candidate] == low;
          })
          .map((candidate) => velocityLayerByRegion[candidate] ?? 1)
          .toSet()
          .length;
      final rrKey = '$root|$low|$velocityLayer';
      final roundRobin = _roundRobinForRegion(
        key: rrKey,
        requested: forcedRoundRobins[region] ?? region.seqPosition,
        sourcePath: region.sourcePath,
        usedRoundRobins: usedRoundRobins,
        onDuplicateRequest: (sourcePath, requested, assigned) {
          repairedRoundRobinCount++;
          if (repairedRoundRobinExamples.length < 4) {
            repairedRoundRobinExamples.add(
              '${p.basename(sourcePath)} RR$requested->RR$assigned',
            );
          }
        },
      );
      final roundRobinCount = rawRegions.where((candidate) {
        return mappedRootByRegion[candidate] == root &&
            mappedLowByRegion[candidate] == low &&
            (velocityLayerByRegion[candidate] ?? 1) == velocityLayer;
      }).length;
      final hasExplicitVelocityLayer = _hasExplicitVelocityLayerSelection(
        region,
        options,
      );
      final fileName = _targetFileName(
        presetName: presetName,
        rootMidi: root,
        switchPoint: low,
        velocityLayer: velocityLayer,
        writeVelocityLayer:
            hasExplicitVelocityLayer ||
            (forcedVelocityLayerCount ?? velocityLayerCount) > 1 ||
            velocityLayer > 1,
        roundRobin: roundRobin,
        writeRoundRobin:
            forcedRoundRobins.containsKey(region) ||
            roundRobinCount > 1 ||
            roundRobin > 1,
      );
      if (!outputNames.add(fileName.toLowerCase())) {
        warnings.add(
          '$presetName: skipped duplicate target mapping `$fileName` from '
          '${p.basename(region.sourcePath)}.',
        );
        continue;
      }
      mapped.add(
        _DecentMappedRegion(
          sourcePath: region.sourcePath,
          outputFileName: fileName,
          groupName: region.groupName,
          rootMidi: root,
          switchPoint: low,
          velocityLayer: velocityLayer,
          roundRobin: roundRobin,
          loopStart: region.loopStart,
          loopEnd: region.loopEnd,
        ),
      );
    }
    if (repairedRoundRobinCount > 0) {
      final suffix = repairedRoundRobinCount > repairedRoundRobinExamples.length
          ? ', ...'
          : '';
      decisions.add(
        '$presetName: repaired $repairedRoundRobinCount duplicate Decent '
        'round-robin request(s) by assigning the next free RR slot '
        '(${repairedRoundRobinExamples.join(', ')}$suffix).',
      );
    }
    return mapped;
  }

  static List<_DecentRawRegion> _rawRegionsFromGroups(
    List<_DecentSampleGroup> sampleGroups,
    String presetName,
    List<String> warnings,
  ) {
    final rawRegions = <_DecentRawRegion>[];
    for (final group in sampleGroups) {
      final groupSeqPosition = _parseIntAttribute(
        group.attributes['seqposition'],
      );
      final groupTagLabels = _groupTagLabelsForImport(group).toList();
      final fallbackTagLabel = groupTagLabels.isEmpty
          ? _fallbackTagLabel(group.name)
          : null;
      final groupHasExplicitVelocity =
          group.attributes.containsKey('lovel') ||
          group.attributes.containsKey('hivel');
      final groupVelocityLow = _parseIntAttribute(group.attributes['lovel']);
      final groupVelocityHigh = _parseIntAttribute(group.attributes['hivel']);
      for (final sample in group.samples) {
        final samplePath = sample['path'];
        if (samplePath == null || samplePath.trim().isEmpty) {
          warnings.add('$presetName has a sample with no path.');
          continue;
        }
        final rootMidi = _parseNoteAttribute(sample['rootnote']);
        final lowMidi = _parseNoteAttribute(sample['lonote']);
        final highMidi = _parseNoteAttribute(sample['hinote']);
        final hasExplicitVelocity =
            sample.containsKey('lovel') ||
            sample.containsKey('hivel') ||
            groupHasExplicitVelocity;
        final velocityLow =
            _parseIntAttribute(sample['lovel']) ?? groupVelocityLow ?? 1;
        final velocityHigh =
            _parseIntAttribute(sample['hivel']) ?? groupVelocityHigh ?? 127;
        final seqPosition =
            _parseIntAttribute(sample['seqposition']) ?? groupSeqPosition;
        final loopStart = _parseIntAttribute(sample['loopstart']);
        final loopEnd = _parseIntAttribute(sample['loopend']);
        final sampleTagLabels = _formalTagLabels(sample).toList();
        final tagKeys = <String>{
          for (final label in groupTagLabels) _tagKeyForLabel(label),
          for (final label in sampleTagLabels) _tagKeyForLabel(label),
          if (groupTagLabels.isEmpty &&
              sampleTagLabels.isEmpty &&
              fallbackTagLabel != null)
            _tagKeyForLabel(fallbackTagLabel),
        }..removeWhere((key) => key.trim().isEmpty);

        rawRegions.add(
          _DecentRawRegion(
            sourcePath: samplePath.trim(),
            rootMidi: rootMidi,
            lowMidi: lowMidi,
            highMidi: highMidi,
            velocityLow: velocityLow.clamp(1, 127).toInt(),
            velocityHigh: velocityHigh.clamp(1, 127).toInt(),
            hasExplicitVelocity: hasExplicitVelocity,
            seqPosition: seqPosition,
            loopStart: loopStart,
            loopEnd: loopEnd,
            groupName: group.name,
            groupIndex: group.index,
            pitchKeyTrackDisabled: _isPitchKeyTrackDisabled(sample),
            tagKeys: tagKeys,
          ),
        );
      }
    }
    return rawRegions;
  }

  static DecentSamplerGroupInfo _groupInfoFor(
    _DecentSampleGroup group,
    List<_DecentRawRegion> rawRegions,
  ) {
    final key = _groupKeyFromParts(group.index, group.name);
    final groupRegions = rawRegions
        .where((region) => _groupKey(region) == key)
        .toList();
    final roots =
        groupRegions
            .map((region) => region.rootMidi)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();
    final defaults = _defaultMappingForRegions(groupRegions);
    final examples =
        groupRegions
            .map((region) => p.basename(region.sourcePath))
            .toSet()
            .toList()
          ..sort();
    return DecentSamplerGroupInfo(
      key: key,
      name: group.name,
      xmlSummary: _groupXmlSummary(group),
      sampleCount: group.samples.length,
      rootCount: roots.length,
      structureSummary: _structureSummaryForRegions(groupRegions),
      noteRange: _noteRangeForRegions(groupRegions),
      velocitySummary: _velocitySummaryForRegions(groupRegions),
      roundRobinSummary: _roundRobinSummaryForRegions(groupRegions),
      examples: examples.take(4).toList(),
      defaultLowMidi: defaults.lowMidi,
      defaultRootMidi: defaults.rootMidi,
      defaultHighMidi: defaults.highMidi,
      defaultVelocityLayer: defaults.velocityLayer,
      previewSourcePath: groupRegions.isEmpty
          ? null
          : groupRegions.first.sourcePath,
    );
  }

  static List<DecentSamplerTag> _tagsForGroups(
    List<_DecentSampleGroup> sampleGroups,
    List<_DecentRawRegion> rawRegions,
  ) {
    final byKey = <String, _MutableDecentTag>{};
    for (final group in sampleGroups) {
      final groupKey = _groupKeyFromParts(group.index, group.name);
      final groupRegions = rawRegions
          .where((region) => _groupKey(region) == groupKey)
          .toList();
      final sampleCount = groupRegions.length;
      final groupLabels = _groupTagLabelsForImport(group).toList();
      if (groupLabels.isEmpty) {
        final fallback = _fallbackTagLabel(group.name);
        if (fallback != null) {
          _addTag(
            byKey,
            label: fallback,
            groupKey: groupKey,
            sampleCount: sampleCount,
            confidence: 0.45,
            evidence: 'group name `${group.name}`',
            previewSourcePath: groupRegions.isEmpty
                ? null
                : groupRegions.first.sourcePath,
          );
        }
      } else {
        for (final label in groupLabels) {
          _addTag(
            byKey,
            label: _displayLabelForGroupTag(label, group.name),
            keyLabel: label,
            groupKey: groupKey,
            sampleCount: sampleCount,
            confidence: 0.9,
            evidence: 'group tags="${group.attributes['tags'] ?? label}"',
            previewSourcePath: groupRegions.isEmpty
                ? null
                : groupRegions.first.sourcePath,
          );
        }
      }
      final sampleTagCounts = <String, int>{};
      final sampleTagLabels = <String, String>{};
      final sampleTagEvidence = <String, String>{};
      for (final sample in group.samples) {
        for (final label in _formalTagLabels(sample)) {
          final key = _tagKeyForLabel(label);
          if (key.isEmpty) continue;
          sampleTagCounts[key] = (sampleTagCounts[key] ?? 0) + 1;
          sampleTagLabels.putIfAbsent(key, () => label.trim());
          sampleTagEvidence.putIfAbsent(
            key,
            () => 'sample tags="${sample['tags'] ?? label}"',
          );
        }
      }
      for (final entry in sampleTagCounts.entries) {
        final label = sampleTagLabels[entry.key] ?? _tagLabelFromKey(entry.key);
        _addTag(
          byKey,
          label: label,
          groupKey: groupKey,
          sampleCount: entry.value,
          confidence: 0.85,
          evidence: sampleTagEvidence[entry.key] ?? 'sample tag',
          previewSourcePath: groupRegions.isEmpty
              ? null
              : groupRegions.first.sourcePath,
        );
      }
    }
    return byKey.entries.map((entry) {
      final tagRegions = rawRegions
          .where((region) => region.tagKeys.contains(entry.key))
          .toList();
      final defaults = _defaultMappingForRegions(tagRegions);
      return entry.value.toTag(
        entry.key,
        defaults,
        noteRange: _noteRangeForRegions(tagRegions),
        structureSummary: _structureSummaryForRegions(tagRegions),
        velocitySummary: _velocitySummaryForRegions(tagRegions),
        roundRobinSummary: _roundRobinSummaryForRegions(tagRegions),
        previewSourcePath: tagRegions.isEmpty
            ? entry.value.previewSourcePath
            : tagRegions.first.sourcePath,
      );
    }).toList()..sort(_compareDecentTags);
  }

  static _DefaultDecentMapping _defaultMappingForRegions(
    List<_DecentRawRegion> regions,
  ) {
    final lows =
        regions
            .map((region) => region.lowMidi ?? region.rootMidi)
            .whereType<int>()
            .toList()
          ..sort();
    final roots =
        regions.map((region) => region.rootMidi).whereType<int>().toList()
          ..sort();
    final highs =
        regions
            .map((region) => region.highMidi ?? region.rootMidi)
            .whereType<int>()
            .toList()
          ..sort();
    final velocityRanges =
        regions
            .where((region) => region.hasExplicitVelocity)
            .map((region) => '${region.velocityLow}-${region.velocityHigh}')
            .toSet()
            .toList()
          ..sort((a, b) {
            final aLow = int.tryParse(a.split('-').first) ?? 1;
            final bLow = int.tryParse(b.split('-').first) ?? 1;
            return aLow.compareTo(bLow);
          });
    final rootMidi = roots.isNotEmpty
        ? roots.first.clamp(0, 127).toInt()
        : (lows.isNotEmpty ? lows.first.clamp(0, 127).toInt() : 36);
    final lowMidi = lows.isNotEmpty
        ? lows.first.clamp(0, rootMidi).toInt()
        : rootMidi;
    final highMidi = highs.isNotEmpty
        ? highs.last.clamp(rootMidi, 127).toInt()
        : rootMidi;
    return _DefaultDecentMapping(
      lowMidi: lowMidi,
      rootMidi: rootMidi,
      highMidi: highMidi,
      velocityLayer: velocityRanges.isNotEmpty ? 1 : 1,
    );
  }

  static String _noteRangeForRegions(List<_DecentRawRegion> regions) {
    final lows = regions
        .map((region) => region.lowMidi ?? region.rootMidi)
        .whereType<int>();
    final highs = regions
        .map((region) => region.highMidi ?? region.rootMidi)
        .whereType<int>();
    final notes = [...lows, ...highs].toList()..sort();
    if (notes.isEmpty) return 'No notes';
    return '${PolyMultisampleParser.midiToNoteName(notes.first)} - ${PolyMultisampleParser.midiToNoteName(notes.last)}';
  }

  static String _velocitySummaryForRegions(List<_DecentRawRegion> regions) {
    final velocityRanges =
        regions
            .where((region) => region.hasExplicitVelocity)
            .map((region) => '${region.velocityLow}-${region.velocityHigh}')
            .toSet()
            .toList()
          ..sort((a, b) {
            final aLow = int.tryParse(a.split('-').first) ?? 1;
            final bLow = int.tryParse(b.split('-').first) ?? 1;
            return aLow.compareTo(bLow);
          });
    return velocityRanges.isEmpty
        ? 'No explicit velocity ranges'
        : velocityRanges.join(', ');
  }

  static String _roundRobinSummaryForRegions(List<_DecentRawRegion> regions) {
    final rrValues =
        regions
            .map((region) => region.seqPosition)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();
    return rrValues.isEmpty
        ? 'No seqPosition'
        : 'RR ${rrValues.first}-${rrValues.last}';
  }

  static String _structureSummaryForRegions(List<_DecentRawRegion> regions) {
    if (regions.isEmpty) return 'No mapped samples';
    final roots =
        regions.map((region) => region.rootMidi).whereType<int>().toSet()
          ..removeWhere((value) => value < 0 || value > 127);
    final lows = regions
        .map((region) => region.lowMidi ?? region.rootMidi)
        .whereType<int>()
        .where((value) => value >= 0 && value <= 127)
        .toList();
    final highs = regions
        .map((region) => region.highMidi ?? region.rootMidi)
        .whereType<int>()
        .where((value) => value >= 0 && value <= 127)
        .toList();
    final notes = [...lows, ...highs]..sort();
    final rangeText = notes.isEmpty
        ? 'no note range'
        : '${PolyMultisampleParser.midiToNoteName(notes.first)}-'
              '${PolyMultisampleParser.midiToNoteName(notes.last)}';
    final fixedPitch = regions.every((region) => region.pitchKeyTrackDisabled);
    final pointMapped = regions.every((region) {
      final root = region.rootMidi;
      if (root == null) return false;
      return (region.lowMidi ?? root) == root &&
          (region.highMidi ?? root) == root;
    });
    final rootText = roots.length == 1
        ? PolyMultisampleParser.midiToNoteName(roots.single)
        : '${roots.length} roots';
    final parts = <String>[];
    if (regions.length == 1 && fixedPitch && notes.length >= 2) {
      parts.add('1 fixed-pitch sample across $rangeText');
    } else if (regions.length == 1 && roots.length == 1) {
      parts.add('1 sample on $rootText');
      if (!pointMapped && notes.length >= 2) parts.add('range $rangeText');
    } else if (pointMapped && roots.length == regions.length) {
      parts.add('${regions.length} pitched samples, one per key, $rangeText');
    } else if (roots.length > 1) {
      parts.add('${regions.length} samples over $rootText, $rangeText');
    } else if (roots.length == 1) {
      parts.add(
        '${regions.length} sample${regions.length == 1 ? '' : 's'} on $rootText',
      );
      if (!pointMapped && notes.length >= 2) parts.add('range $rangeText');
    } else {
      parts.add(
        '${regions.length} sample${regions.length == 1 ? '' : 's'}, $rangeText',
      );
    }

    final velocityRanges = regions
        .where((region) => region.hasExplicitVelocity)
        .map((region) => '${region.velocityLow}-${region.velocityHigh}')
        .toSet();
    if (velocityRanges.isNotEmpty) {
      parts.add(
        '${velocityRanges.length} velocity range${velocityRanges.length == 1 ? '' : 's'}',
      );
    }
    final rrValues = regions
        .map((region) => region.seqPosition)
        .whereType<int>()
        .toSet();
    if (rrValues.isNotEmpty) {
      parts.add('${rrValues.length} RR slot${rrValues.length == 1 ? '' : 's'}');
    }
    if (fixedPitch && regions.length > 1) {
      parts.add('fixed pitch');
    }
    return parts.join(' · ');
  }

  static List<_SelectedTagPlan> _selectedTagPlans(
    List<_DecentSampleGroup> sampleGroups,
    List<_DecentRawRegion> rawRegions,
    List<String> selectedTagKeys,
  ) {
    final tags = _tagsForGroups(sampleGroups, rawRegions);
    if (tags.isEmpty || selectedTagKeys.isEmpty) return const [];
    final selected = selectedTagKeys.toSet();
    final selectedTags = tags
        .where((tag) => selected.contains(tag.key))
        .toList();
    if (selectedTags.isEmpty) return const [];
    return [
      for (final tag in selectedTags)
        _SelectedTagPlan(label: tag.label, tagKeys: {tag.key}),
    ];
  }

  static void _addTag(
    Map<String, _MutableDecentTag> byKey, {
    required String label,
    String? keyLabel,
    required String groupKey,
    required int sampleCount,
    required double confidence,
    required String evidence,
    String? previewSourcePath,
  }) {
    final normalized = label.trim();
    final normalizedKeyLabel = (keyLabel ?? label).trim();
    if (normalized.isEmpty || _isHiddenTagLabel(normalizedKeyLabel)) return;
    final key = _tagKeyForLabel(normalizedKeyLabel);
    if (key.isEmpty) return;
    final tag = byKey.putIfAbsent(
      key,
      () => _MutableDecentTag(
        label: normalized,
        confidence: confidence,
        evidence: evidence,
      ),
    );
    tag.groupKeys.add(groupKey);
    tag.sampleCount += sampleCount;
    tag.maxGroupSampleCount = math.max(tag.maxGroupSampleCount, sampleCount);
    tag.confidence = math.max(tag.confidence, confidence);
    tag.previewSourcePath ??= previewSourcePath;
  }

  static Iterable<String> _groupTagLabelsForImport(
    _DecentSampleGroup group,
  ) sync* {
    for (final label in _formalTagLabels(group.attributes)) {
      if (!_isHiddenTagLabel(label)) yield label;
    }
  }

  static Iterable<String> _formalTagLabels(Map<String, String> attrs) sync* {
    const keys = [
      'tags',
      'tag',
      'layer',
      'layers',
      'mic',
      'mics',
      'articulation',
      'articulations',
      'category',
      'label',
    ];
    for (final key in keys) {
      final value = attrs[key];
      if (value == null || value.trim().isEmpty) continue;
      for (final part in value.split(RegExp(r'[,;/|]+'))) {
        final label = part.trim();
        if (label.isNotEmpty && !_isHiddenTagLabel(label)) yield label;
      }
    }
  }

  static bool _isPitchKeyTrackDisabled(Map<String, String> attrs) {
    final value = attrs['pitchkeytrack']?.trim().toLowerCase();
    return value == '0' || value == 'false' || value == 'off';
  }

  static String _displayLabelForGroupTag(String label, String groupName) {
    final normalized = label.trim();
    final parts = groupName
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    final index = parts.indexWhere(
      (part) => part.toLowerCase() == normalized.toLowerCase(),
    );
    if (index < 0 || index + 1 >= parts.length) return normalized;
    final next = parts[index + 1];
    final nextKey = next.toLowerCase();
    if (RegExp(r'^[amdluv]\d+$').hasMatch(nextKey)) return normalized;
    if (const {
      'placeholder',
      'retired',
      'locked',
      'legacy',
    }.contains(nextKey)) {
      return normalized;
    }
    return '$normalized ${_titleTagWord(next)}';
  }

  static String _titleTagWord(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return '${lower.substring(0, 1).toUpperCase()}${lower.substring(1)}';
  }

  static String? _fallbackTagLabel(String groupName) {
    final roundRobinPattern = RegExp(
      r'(^|[\s_-])rr\s*\d+(?=$|[\s_-])',
      caseSensitive: false,
    );
    final sequencePattern = RegExp(
      r'(^|[\s_-])seq\s*\d+(?=$|[\s_-])',
      caseSensitive: false,
    );
    final clean = _roundRobinBankLabelFromName(groupName, null)
        .replaceAll(roundRobinPattern, ' ')
        .replaceAll(sequencePattern, ' ')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();
    if (_isGenericGroupLabel(clean)) return null;
    return clean;
  }

  static bool _isUtilityTag(String label) {
    final key = _labelKey(label);
    return key.isEmpty;
  }

  static bool _isHiddenTagLabel(String label) {
    return _isUtilityTag(label);
  }

  static String _tagKeyForLabel(String label) {
    final normalized = label.trim();
    if (normalized.isEmpty || _isHiddenTagLabel(normalized)) return '';
    return 'tag:${_labelKey(normalized)}';
  }

  static String _tagLabelFromKey(String key) {
    final separator = key.indexOf(':');
    return separator < 0 ? key : key.substring(separator + 1);
  }

  static int _compareDecentTags(DecentSamplerTag a, DecentSamplerTag b) {
    final countCompare = b.sampleCount.compareTo(a.sampleCount);
    if (countCompare != 0) return countCompare;
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  }

  Map<String, int>? _dynamicGroupVelocityLayers(
    List<_DecentRawRegion> rawRegions,
  ) {
    if (rawRegions.any((region) => region.hasExplicitVelocity)) return null;
    final structuralRoundRobinLayers = _structuralRoundRobinBankVelocityLayers(
      rawRegions,
      requireDynamicNames: true,
    );
    if (structuralRoundRobinLayers != null) {
      return structuralRoundRobinLayers;
    }

    final groupKeys = <String>{
      for (final region in rawRegions) _groupKey(region),
    };
    if (groupKeys.length < 2) return null;
    if (!groupKeys.every(_isDynamicGroupName)) return null;

    final signatures = <String, Set<String>>{};
    for (final region in rawRegions) {
      signatures
          .putIfAbsent(_groupKey(region), () => <String>{})
          .add(_mappingSignature(region));
    }
    if (signatures.length < 2) return null;
    final first = signatures.values.first;
    if (!signatures.values.every((signature) => _sameSet(signature, first))) {
      return null;
    }

    final sorted = groupKeys.toList()
      ..sort((a, b) {
        final rank = _dynamicGroupRank(a).compareTo(_dynamicGroupRank(b));
        return rank != 0 ? rank : a.compareTo(b);
      });
    return {
      for (var index = 0; index < sorted.length; index++)
        sorted[index]: index + 1,
    };
  }

  Map<String, int>? _forcedGroupVelocityLayers(
    List<_DecentRawRegion> rawRegions,
  ) {
    final structuralRoundRobinLayers = _structuralRoundRobinBankVelocityLayers(
      rawRegions,
      requireDynamicNames: false,
    );
    if (structuralRoundRobinLayers != null) {
      return structuralRoundRobinLayers;
    }
    if (rawRegions.any((region) => region.seqPosition != null) &&
        _roundRobinBankLabels(rawRegions).isEmpty) {
      return null;
    }

    final groupKeys =
        <String>{for (final region in rawRegions) _groupKey(region)}.toList()
          ..sort((a, b) {
            final aIndex = int.tryParse(a.split(':').first) ?? 0;
            final bIndex = int.tryParse(b.split(':').first) ?? 0;
            return aIndex.compareTo(bIndex);
          });
    if (groupKeys.length < 2) return null;
    return {
      for (var index = 0; index < groupKeys.length; index++)
        groupKeys[index]: index + 1,
    };
  }

  _TagVelocityLayerPlan? _forcedTagVelocityLayers(
    List<_DecentRawRegion> rawRegions,
    DecentSamplerConvertOptions options,
  ) {
    final selectedTagKeys = options.selectedTagKeys;
    final selected = selectedTagKeys.toSet();
    final explicitLayers = {
      for (final entry in options.tagVelocityLayers.entries)
        if (selected.contains(entry.key) && entry.value > 0)
          entry.key: entry.value,
    };
    if (explicitLayers.isEmpty) return null;
    final orderedTags = [
      for (final key in selectedTagKeys)
        if (rawRegions.any((region) => region.tagKeys.contains(key))) key,
    ];
    final uniqueOrderedTags = <String>[];
    for (final key in orderedTags) {
      if (!uniqueOrderedTags.contains(key) &&
          rawRegions.any((region) => region.tagKeys.contains(key))) {
        uniqueOrderedTags.add(key);
      }
    }
    if (uniqueOrderedTags.isEmpty) return null;
    final explicitLayerValues = explicitLayers.values.toSet();
    var nextFallbackLayer = 1;
    int fallbackLayerFor(String key) {
      final explicit = explicitLayers[key];
      if (explicit != null) return explicit;
      while (explicitLayerValues.contains(nextFallbackLayer)) {
        nextFallbackLayer++;
      }
      return nextFallbackLayer++;
    }

    final fallbackLayers = {
      for (final key in uniqueOrderedTags) key: fallbackLayerFor(key),
    };
    final orderedForSummary = List<String>.from(uniqueOrderedTags)
      ..sort((a, b) {
        final aExplicit = explicitLayers[a];
        final bExplicit = explicitLayers[b];
        if (aExplicit != null && bExplicit != null) {
          final layerCompare = aExplicit.compareTo(bExplicit);
          if (layerCompare != 0) return layerCompare;
        } else if (aExplicit != null) {
          final layerCompare = aExplicit.compareTo(
            selectedTagKeys.indexOf(b) + 1,
          );
          if (layerCompare != 0) return layerCompare;
        } else if (bExplicit != null) {
          final layerCompare = selectedTagKeys.indexOf(a) + 1 - bExplicit;
          if (layerCompare != 0) return layerCompare;
        }
        return selectedTagKeys.indexOf(a).compareTo(selectedTagKeys.indexOf(b));
      });
    final regionLayers = <_DecentRawRegion, int>{};
    for (final region in rawRegions) {
      for (var index = 0; index < uniqueOrderedTags.length; index++) {
        final tagKey = uniqueOrderedTags[index];
        if (!region.tagKeys.contains(tagKey)) continue;
        regionLayers[region] = fallbackLayers[tagKey] ?? index + 1;
        break;
      }
    }
    if (regionLayers.isEmpty) return null;
    return _TagVelocityLayerPlan(
      tagLayers: {
        for (final key in orderedForSummary)
          key: fallbackLayers[key] ?? explicitLayers[key] ?? 1,
      },
      regionLayers: regionLayers,
    );
  }

  Map<_DecentRawRegion, int> _forcedRoundRobins(
    List<_DecentRawRegion> rawRegions,
    DecentSamplerConvertOptions options,
  ) {
    final result = <_DecentRawRegion, int>{};
    final selectedTags = options.selectedTagKeys.toSet();
    final tagRoundRobins = {
      for (final entry in options.tagRoundRobins.entries)
        if (selectedTags.contains(entry.key) && entry.value > 0)
          entry.key: entry.value.clamp(1, 32).toInt(),
    };
    final selectedGroups = options.selectedGroupKeys.toSet();
    final groupRoundRobins = {
      for (final entry in options.groupRoundRobins.entries)
        if (selectedGroups.contains(entry.key) && entry.value > 0)
          entry.key: entry.value.clamp(1, 32).toInt(),
    };
    if (tagRoundRobins.isEmpty && groupRoundRobins.isEmpty) return result;

    for (final region in rawRegions) {
      for (final tagKey in options.selectedTagKeys) {
        final roundRobin = tagRoundRobins[tagKey];
        if (roundRobin != null && region.tagKeys.contains(tagKey)) {
          result[region] = roundRobin;
          break;
        }
      }
      if (result.containsKey(region)) continue;
      for (final groupKey in options.selectedGroupKeys) {
        final roundRobin = groupRoundRobins[groupKey];
        if (roundRobin != null && _groupKey(region) == groupKey) {
          result[region] = roundRobin;
          break;
        }
      }
    }
    return result;
  }

  static String _uniqueOriginalSampleName(String sourcePath, Set<String> used) {
    final extension = p.extension(sourcePath).isEmpty
        ? '.wav'
        : p.extension(sourcePath);
    final stem = _safeFileStem(p.basenameWithoutExtension(sourcePath));
    var candidate = '$stem$extension';
    var index = 2;
    while (!used.add(candidate.toLowerCase())) {
      candidate = '${stem}_$index$extension';
      index++;
    }
    return candidate;
  }

  bool _hasExplicitVelocityLayerSelection(
    _DecentRawRegion region,
    DecentSamplerConvertOptions options,
  ) {
    final selectedTags = options.selectedTagKeys.toSet();
    for (final entry in options.tagVelocityLayers.entries) {
      if (entry.value > 0 &&
          selectedTags.contains(entry.key) &&
          region.tagKeys.contains(entry.key)) {
        return true;
      }
    }
    final selectedGroups = options.selectedGroupKeys.toSet();
    final groupKey = _groupKey(region);
    if (selectedGroups.isNotEmpty &&
        selectedGroups.contains(groupKey) &&
        (options.groupVelocityLayers[groupKey] ?? 0) > 0) {
      return true;
    }
    return selectedGroups.isEmpty &&
        (options.groupVelocityLayers[groupKey] ?? 0) > 0;
  }

  _TagKeyRangePlan? _forcedTagKeyRanges(
    List<_DecentRawRegion> rawRegions,
    DecentSamplerConvertOptions options,
  ) {
    final selected = options.selectedTagKeys.toSet();
    final explicitRanges = {
      for (final entry in options.tagKeyRanges.entries)
        if (selected.contains(entry.key) && entry.value.enabled)
          entry.key: entry.value,
    };
    if (explicitRanges.isEmpty) return null;
    final orderedTags = explicitRanges.keys.toList()
      ..sort((a, b) {
        final lowCompare = explicitRanges[a]!.lowMidi.compareTo(
          explicitRanges[b]!.lowMidi,
        );
        return lowCompare != 0
            ? lowCompare
            : options.selectedTagKeys
                  .indexOf(a)
                  .compareTo(options.selectedTagKeys.indexOf(b));
      });
    final regionMappings = <_DecentRawRegion, _RegionKeyRangeMapping>{};
    for (final tagKey in orderedTags) {
      final range = explicitRanges[tagKey]!;
      final tagRegions = rawRegions
          .where(
            (region) =>
                region.rootMidi != null && region.tagKeys.contains(tagKey),
          )
          .toList();
      if (tagRegions.isEmpty) continue;
      final sourceRoot = tagRegions
          .map((region) => region.rootMidi!)
          .reduce(math.min);
      for (final region in tagRegions) {
        regionMappings.putIfAbsent(
          region,
          () => _RegionKeyRangeMapping(
            tagKey: tagKey,
            range: range,
            sourceRootMidi: sourceRoot,
          ),
        );
      }
    }
    if (regionMappings.isEmpty) return null;
    return _TagKeyRangePlan(
      tagRanges: explicitRanges,
      regionMappings: regionMappings,
    );
  }

  _TagVelocityLayerPlan? _forcedSelectedGroupVelocityLayers(
    List<_DecentRawRegion> rawRegions,
    DecentSamplerConvertOptions options,
  ) {
    final selected = options.selectedGroupKeys.toSet();
    final explicitLayers = {
      for (final entry in options.groupVelocityLayers.entries)
        if (selected.contains(entry.key) && entry.value > 0)
          entry.key: entry.value,
    };
    if (explicitLayers.isEmpty) return null;
    final orderedGroups = [
      for (final key in options.selectedGroupKeys)
        if (rawRegions.any((region) => _groupKey(region) == key)) key,
    ];
    final explicitLayerValues = explicitLayers.values.toSet();
    var nextFallbackLayer = 1;
    int fallbackLayerFor(String key) {
      final explicit = explicitLayers[key];
      if (explicit != null) return explicit;
      while (explicitLayerValues.contains(nextFallbackLayer)) {
        nextFallbackLayer++;
      }
      return nextFallbackLayer++;
    }

    final orderedForSummary = List<String>.from(orderedGroups)
      ..sort((a, b) {
        final aExplicit = explicitLayers[a];
        final bExplicit = explicitLayers[b];
        if (aExplicit != null && bExplicit != null) {
          final layerCompare = aExplicit.compareTo(bExplicit);
          if (layerCompare != 0) return layerCompare;
        } else if (aExplicit != null) {
          final layerCompare = aExplicit.compareTo(
            options.selectedGroupKeys.indexOf(b) + 1,
          );
          if (layerCompare != 0) return layerCompare;
        } else if (bExplicit != null) {
          final layerCompare =
              options.selectedGroupKeys.indexOf(a) + 1 - bExplicit;
          if (layerCompare != 0) return layerCompare;
        }
        return options.selectedGroupKeys
            .indexOf(a)
            .compareTo(options.selectedGroupKeys.indexOf(b));
      });
    final fallbackLayers = {
      for (final key in orderedGroups) key: fallbackLayerFor(key),
    };
    final regionLayers = <_DecentRawRegion, int>{};
    for (final region in rawRegions) {
      final groupKey = _groupKey(region);
      final groupIndex = orderedGroups.indexOf(groupKey);
      if (groupIndex < 0) continue;
      regionLayers[region] = fallbackLayers[groupKey] ?? groupIndex + 1;
    }
    if (regionLayers.isEmpty) return null;
    return _TagVelocityLayerPlan(
      tagLayers: {
        for (final key in orderedForSummary)
          key: fallbackLayers[key] ?? explicitLayers[key] ?? 1,
      },
      regionLayers: regionLayers,
    );
  }

  _TagKeyRangePlan? _forcedSelectedGroupKeyRanges(
    List<_DecentRawRegion> rawRegions,
    DecentSamplerConvertOptions options,
  ) {
    final selected = options.selectedGroupKeys.toSet();
    final explicitRanges = {
      for (final entry in options.groupKeyRanges.entries)
        if (selected.contains(entry.key) && entry.value.enabled)
          entry.key: entry.value,
    };
    if (explicitRanges.isEmpty) return null;
    final orderedGroups = explicitRanges.keys.toList()
      ..sort((a, b) {
        final lowCompare = explicitRanges[a]!.lowMidi.compareTo(
          explicitRanges[b]!.lowMidi,
        );
        return lowCompare != 0
            ? lowCompare
            : options.selectedGroupKeys
                  .indexOf(a)
                  .compareTo(options.selectedGroupKeys.indexOf(b));
      });
    final regionMappings = <_DecentRawRegion, _RegionKeyRangeMapping>{};
    for (final groupKey in orderedGroups) {
      final range = explicitRanges[groupKey]!;
      final groupRegions = rawRegions
          .where(
            (region) =>
                region.rootMidi != null && _groupKey(region) == groupKey,
          )
          .toList();
      if (groupRegions.isEmpty) continue;
      final sourceRoot = groupRegions
          .map((region) => region.rootMidi!)
          .reduce(math.min);
      for (final region in groupRegions) {
        regionMappings.putIfAbsent(
          region,
          () => _RegionKeyRangeMapping(
            tagKey: groupKey,
            range: range,
            sourceRootMidi: sourceRoot,
          ),
        );
      }
    }
    if (regionMappings.isEmpty) return null;
    return _TagKeyRangePlan(
      tagRanges: explicitRanges,
      regionMappings: regionMappings,
    );
  }

  static String _tagLayerSummary(_TagVelocityLayerPlan plan) {
    final entries = plan.tagLayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries
        .map((entry) => '${_tagLabelFromKey(entry.key)}=V${entry.value}')
        .join(', ');
  }

  static String _tagRangeSummary(_TagKeyRangePlan plan) {
    final entries = plan.tagRanges.entries.toList()
      ..sort((a, b) => a.value.lowMidi.compareTo(b.value.lowMidi));
    return entries
        .map((entry) {
          final range = entry.value;
          return '${_tagLabelFromKey(entry.key)}='
              '${PolyMultisampleParser.midiToNoteName(range.lowMidi)}-'
              '${PolyMultisampleParser.midiToNoteName(range.highMidi)}';
        })
        .join(', ');
  }

  static List<_SplitFolderGroup> _splitFolderGroups(
    List<_DecentRawRegion> rawRegions,
  ) {
    final groups = <String, _MutableSplitFolderGroup>{};
    for (final region in rawRegions) {
      final hasRoundRobinAxis = region.seqPosition != null;
      final label = hasRoundRobinAxis
          ? _roundRobinBankLabel(region)
          : region.groupName;
      final key = hasRoundRobinAxis
          ? (label.isEmpty ? 'round-robin-set' : _labelKey(label))
          : _groupKey(region);
      final group = groups.putIfAbsent(
        key,
        () => _MutableSplitFolderGroup(
          label: label.isEmpty ? 'Round robin set' : label,
          firstGroupIndex: region.groupIndex,
        ),
      );
      if (region.groupIndex < group.firstGroupIndex) {
        group.firstGroupIndex = region.groupIndex;
      }
      group.regions.add(region);
    }
    final result =
        groups.values
            .map(
              (group) => _SplitFolderGroup(
                label: group.label,
                firstGroupIndex: group.firstGroupIndex,
                regions: group.regions,
              ),
            )
            .toList()
          ..sort((a, b) => a.firstGroupIndex.compareTo(b.firstGroupIndex));
    return result;
  }

  static Map<String, int>? _structuralRoundRobinBankVelocityLayers(
    List<_DecentRawRegion> rawRegions, {
    required bool requireDynamicNames,
  }) {
    if (!rawRegions.any((region) => region.seqPosition != null)) return null;

    final bankLabels = <String, String>{};
    final bankSignatures = <String, Set<String>>{};
    final bankGroupKeys = <String, Set<String>>{};
    for (final region in rawRegions) {
      final label = _roundRobinBankLabel(region);
      if (label.isEmpty) return null;
      final bankKey = _labelKey(label);
      bankLabels[bankKey] = label;
      bankSignatures
          .putIfAbsent(bankKey, () => <String>{})
          .add(_mappingSignature(region));
      bankGroupKeys
          .putIfAbsent(bankKey, () => <String>{})
          .add(_groupKey(region));
    }
    if (bankLabels.length < 2) return null;
    if (requireDynamicNames &&
        !bankLabels.values.every((label) => _isDynamicLabel(label))) {
      return null;
    }

    final firstSignature = bankSignatures.values.first;
    if (!bankSignatures.values.every(
      (signature) => _sameSet(signature, firstSignature),
    )) {
      return null;
    }

    final sortedBankKeys = bankLabels.keys.toList()
      ..sort((a, b) {
        final rank = _dynamicLabelRank(
          bankLabels[a]!,
        ).compareTo(_dynamicLabelRank(bankLabels[b]!));
        return rank != 0 ? rank : bankLabels[a]!.compareTo(bankLabels[b]!);
      });
    final layers = <String, int>{};
    for (var index = 0; index < sortedBankKeys.length; index++) {
      final bankKey = sortedBankKeys[index];
      for (final groupKey in bankGroupKeys[bankKey]!) {
        layers[groupKey] = index + 1;
      }
    }
    return layers;
  }

  static bool _hasAmbiguousGroupOverlaps(List<_DecentRawRegion> rawRegions) {
    if (!rawRegions.any((region) => region.hasExplicitVelocity) &&
        _dynamicGroupVelocityLayersStatic(rawRegions) != null) {
      return false;
    }
    final signatures = <String, Set<String>>{};
    for (final region in rawRegions) {
      signatures
          .putIfAbsent(_overlapSignature(region), () => <String>{})
          .add(_groupKey(region));
    }
    return signatures.values.any((groups) => groups.length > 1);
  }

  static Map<String, int>? _dynamicGroupVelocityLayersStatic(
    List<_DecentRawRegion> rawRegions,
  ) {
    if (rawRegions.any((region) => region.hasExplicitVelocity)) return null;
    final groupKeys = <String>{
      for (final region in rawRegions) _groupKey(region),
    };
    if (groupKeys.length < 2) return null;
    if (!groupKeys.every(_isDynamicGroupName)) return null;

    final signatures = <String, Set<String>>{};
    for (final region in rawRegions) {
      signatures
          .putIfAbsent(_groupKey(region), () => <String>{})
          .add(_mappingSignature(region));
    }
    if (signatures.length < 2) return null;
    final first = signatures.values.first;
    if (!signatures.values.every((signature) => _sameSet(signature, first))) {
      return null;
    }

    final sorted = groupKeys.toList()
      ..sort((a, b) {
        final rank = _dynamicGroupRank(a).compareTo(_dynamicGroupRank(b));
        return rank != 0 ? rank : a.compareTo(b);
      });
    return {
      for (var index = 0; index < sorted.length; index++)
        sorted[index]: index + 1,
    };
  }

  void _warnAboutAmbiguousGroupOverlaps(
    List<_DecentRawRegion> rawRegions,
    String presetName,
    List<String> decisions,
    List<String> warnings,
  ) {
    final signatures = <String, Set<String>>{};
    for (final region in rawRegions) {
      signatures
          .putIfAbsent(_overlapSignature(region), () => <String>{})
          .add(_groupKey(region));
    }
    final overlappingGroups =
        signatures.values
            .where((groups) => groups.length > 1)
            .expand((groups) => groups)
            .toSet()
            .toList()
          ..sort();
    if (overlappingGroups.isEmpty) return;
    warnings.add(
      '$presetName: overlapping Decent groups were not auto-merged '
      '(${overlappingGroups.take(8).join(', ')}). Choose velocity, folder, '
      'or selected-group handling if this needs a different interpretation.',
    );
    decisions.add(
      '$presetName: overlapping groups need a manual import choice. Use '
      'velocity layers only for real dynamics, round robins only for repeated '
      'takes, or select the intended tag/group material explicitly.',
    );
  }

  int _roundRobinForRegion({
    required String key,
    required int? requested,
    required String sourcePath,
    required Map<String, Set<int>> usedRoundRobins,
    required void Function(String sourcePath, int requested, int assigned)
    onDuplicateRequest,
  }) {
    final used = usedRoundRobins.putIfAbsent(key, () => <int>{});
    if (requested != null && requested > 0 && !used.contains(requested)) {
      used.add(requested);
      return requested;
    }

    var next = 1;
    while (used.contains(next)) {
      next++;
    }
    used.add(next);
    if (requested != null && requested > 0) {
      onDuplicateRequest(sourcePath, requested, next);
    }
    return next;
  }

  Future<Directory> _createOutputFolder(
    String outputParentPath,
    String presetName,
  ) async {
    final parent = Directory(outputParentPath);
    await parent.create(recursive: true);
    var candidate = Directory(p.join(parent.path, presetName));
    if (!await candidate.exists()) {
      await candidate.create(recursive: true);
      return candidate;
    }
    for (var index = 2; index < 1000; index++) {
      candidate = Directory(p.join(parent.path, '${presetName}_$index'));
      if (!await candidate.exists()) {
        await candidate.create(recursive: true);
        return candidate;
      }
    }
    throw FileSystemException('Could not create output folder', parent.path);
  }

  Future<int> _writePlan(
    _DecentPresetPlan plan,
    Directory outputFolder,
    List<String> warnings,
  ) async {
    var copied = 0;
    for (final region in plan.regions) {
      final extension = p.extension(region.sourcePath).toLowerCase();
      if (extension != '.wav') {
        warnings.add(
          '${p.basename(region.sourcePath)} is $extension; WAV output only in this build.',
        );
        continue;
      }

      Uint8List? bytes;
      try {
        bytes = await plan.sourceResolver.read(region.sourcePath);
      } on _BlockedDecentSourceException catch (error) {
        warnings.add(error.message);
        continue;
      }
      if (bytes == null) {
        warnings.add('Missing source sample: ${region.sourcePath}');
        continue;
      }

      var outputBytes = bytes;
      final loopStart = region.loopStart;
      final loopEnd = region.loopEnd;
      if (loopStart != null && loopEnd != null && loopEnd > loopStart) {
        try {
          outputBytes = WavMetadataWriter.writeSmplLoop(
            bytes,
            loopStart: loopStart,
            loopEnd: loopEnd,
          );
        } catch (e) {
          warnings.add(
            'Could not write loop metadata for ${p.basename(region.sourcePath)}: $e',
          );
        }
      }

      final outputFile = File(p.join(outputFolder.path, region.outputFileName));
      await outputFile.writeAsBytes(outputBytes);
      copied++;
    }
    return copied;
  }

  Future<int> _copySourceDocs(
    _DecentPresetPlan plan,
    Directory outputFolder,
    List<String> warnings,
  ) async {
    if (plan.sourceDocs.isEmpty) return 0;

    final docsFolder = Directory(p.join(outputFolder.path, '_source_docs'));
    final usedNames = <String>{};
    var copied = 0;
    for (final doc in plan.sourceDocs) {
      final bytes = await plan.sourceResolver.read(doc.sourcePath);
      if (bytes == null) {
        warnings.add('Missing source documentation: ${doc.sourcePath}');
        continue;
      }
      await docsFolder.create(recursive: true);
      final outputName = _uniqueDocOutputName(doc.displayPath, usedNames);
      await File(p.join(docsFolder.path, outputName)).writeAsBytes(bytes);
      copied++;
    }
    return copied;
  }

  Future<void> _writeReport(
    _DecentPresetPlan plan,
    Directory outputFolder,
    List<String> decisions,
    List<String> warnings,
  ) async {
    final lines = <String>[
      '# Decent Sampler Conversion Report',
      '',
      '- Preset: `${plan.presetName}`',
      '- Output folder: `${outputFolder.path}`',
      '- Regions planned: ${plan.regions.length}',
      '- Source docs copied: ${plan.sourceDocs.length}',
      '',
      '## Conversion decisions',
      '',
      if (decisions.isEmpty)
        '- Auto/default mapping only.'
      else
        for (final decision in decisions) '- $decision',
      '',
      '## Files',
      '',
      '| Group | Source | Output | Root | Switch | Velocity | Round robin | Loop |',
      '| --- | --- | --- | --- | --- | --- | --- | --- |',
      for (final region in plan.regions)
        '| `${region.groupName}` | `${region.sourcePath}` | `${region.outputFileName}` | ${PolyMultisampleParser.midiToNoteName(region.rootMidi)} | ${region.switchPoint} | V${region.velocityLayer} | RR${region.roundRobin} | ${region.loopStart != null && region.loopEnd != null ? '${region.loopStart}-${region.loopEnd}' : '-'} |',
      '',
      if (plan.sourceDocs.isNotEmpty) ...[
        '## Source documentation',
        '',
        for (final doc in plan.sourceDocs) '- `${doc.displayPath}`',
        '',
      ],
      '## Warnings',
      '',
      if (warnings.isEmpty)
        '- None'
      else
        for (final warning in warnings) '- $warning',
      '',
    ];
    await File(
      p.join(outputFolder.path, '_CONVERSION_REPORT.md'),
    ).writeAsString(lines.join('\n'), flush: true);
  }

  String _targetFileName({
    required String presetName,
    required int rootMidi,
    required int switchPoint,
    required int velocityLayer,
    required bool writeVelocityLayer,
    required int roundRobin,
    required bool writeRoundRobin,
  }) {
    final rootName = PolyMultisampleParser.midiToNoteName(rootMidi);
    final parts = <String>[_safeFileStem(presetName), rootName];
    if (switchPoint != rootMidi) {
      parts.add('SW$switchPoint');
    }
    if (writeVelocityLayer) {
      parts.add('V$velocityLayer');
    }
    if (writeRoundRobin) {
      parts.add('RR$roundRobin');
    }
    return '${parts.join('_')}.wav';
  }

  static List<_DecentSampleGroup> _sampleGroups(String content) {
    final document = html_parser.parse(content);
    final root = document.querySelector('decentsampler');
    final groupElements =
        root?.querySelectorAll('groups group') ?? const <html_dom.Element>[];
    if (groupElements.isNotEmpty) {
      return [
        for (var index = 0; index < groupElements.length; index++)
          _DecentSampleGroup(
            index: index,
            attributes: _elementAttributes(groupElements[index]),
            samples: groupElements[index]
                .querySelectorAll('sample')
                .map(_elementAttributes)
                .toList(),
          ),
      ].where((group) => group.samples.isNotEmpty).toList();
    }
    final looseSamples =
        root?.querySelectorAll('sample') ?? const <html_dom.Element>[];
    if (looseSamples.isNotEmpty) {
      return [
        _DecentSampleGroup(
          index: 0,
          attributes: const {'name': 'Ungrouped'},
          samples: looseSamples.map(_elementAttributes).toList(),
        ),
      ];
    }
    return _sampleGroupsFromText(content);
  }

  static Map<String, String> _elementAttributes(html_dom.Element element) {
    final attributes = <String, String>{};
    for (final entry in element.attributes.entries) {
      attributes[entry.key.toString().toLowerCase()] = entry.value;
    }
    return attributes;
  }

  static Iterable<String> _sampleTagsFromText(String content) {
    return RegExp(
      r'<\s*sample\b[^>]*>',
      caseSensitive: false,
      multiLine: true,
    ).allMatches(content).map((match) => match.group(0) ?? '');
  }

  static List<_DecentSampleGroup> _sampleGroupsFromText(String content) {
    final groups = <_DecentSampleGroup>[];
    final groupPattern = RegExp(
      r'<\s*group\b([^>]*)>(.*?)<\s*/\s*group\s*>',
      caseSensitive: false,
      dotAll: true,
      multiLine: true,
    );
    var index = 0;
    for (final match in groupPattern.allMatches(content)) {
      final attrs = _tagAttributes(match.group(1) ?? '');
      final body = match.group(2) ?? '';
      final samples = _sampleTagsFromText(body).map(_tagAttributes).toList();
      if (samples.isEmpty) continue;
      groups.add(
        _DecentSampleGroup(index: index++, attributes: attrs, samples: samples),
      );
    }
    if (groups.isNotEmpty) return groups;
    final samples = _sampleTagsFromText(content).map(_tagAttributes).toList();
    if (samples.isEmpty) return const [];
    return [
      _DecentSampleGroup(
        index: 0,
        attributes: const {'name': 'Ungrouped'},
        samples: samples,
      ),
    ];
  }

  static Map<String, String> _tagAttributes(String tag) {
    final attributes = <String, String>{};
    final pattern = RegExp(
      r'''([A-Za-z_:][A-Za-z0-9_:.-]*)\s*=\s*("([^"]*)"|'([^']*)'|([^\s"'=<>`]+))''',
      multiLine: true,
    );
    for (final match in pattern.allMatches(tag)) {
      final key = match.group(1)?.toLowerCase();
      final value = match.group(3) ?? match.group(4) ?? match.group(5) ?? '';
      if (key != null) attributes[key] = value;
    }
    return attributes;
  }

  static int? _parseIntAttribute(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim())?.round();
  }

  static int? _parseNoteAttribute(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    return int.tryParse(trimmed) ??
        PolyMultisampleParser.noteNameToMidi(trimmed);
  }

  static String _fixInvalidXml(String content) {
    final headerStart = content.indexOf('<?xml');
    return headerStart > 0 ? content.substring(headerStart) : content;
  }

  static String _decodeXmlText(List<int> bytes) {
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String _safeFileStem(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return cleaned.isEmpty ? 'DecentSampler' : cleaned;
  }

  static String _normalizeZipPath(String path) {
    return p.posix
        .normalize(path.replaceAll('\\', '/'))
        .replaceAll(RegExp(r'^/+'), '');
  }

  static bool _isMacOsJunkPath(String path) {
    final normalized = _normalizeZipPath(path);
    if (normalized.isEmpty) return true;
    final parts = normalized.split('/');
    return parts.any(
      (part) =>
          part == '__MACOSX' || part == '.DS_Store' || part.startsWith('._'),
    );
  }

  Future<List<_DecentSourceDoc>> _sourceDocsForLocalDirectory(
    Directory directory,
  ) async {
    final docs = <_DecentSourceDoc>[];
    if (!await directory.exists()) return docs;
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final relativePath = p.relative(entity.path, from: directory.path);
      final normalized = _normalizeZipPath(relativePath);
      if (!_isSourceDocPath(normalized)) continue;
      docs.add(
        _DecentSourceDoc(sourcePath: normalized, displayPath: normalized),
      );
    }
    docs.sort((a, b) => a.displayPath.compareTo(b.displayPath));
    return _dedupeSourceDocs(docs);
  }

  static List<_DecentSourceDoc> _sourceDocsForArchive(List<ArchiveFile> files) {
    final docs = <_DecentSourceDoc>[];
    for (final entry in files) {
      final normalized = _normalizeZipPath(entry.name);
      if (!_isSourceDocPath(normalized)) continue;
      docs.add(
        _DecentSourceDoc(sourcePath: normalized, displayPath: normalized),
      );
    }
    docs.sort((a, b) => a.displayPath.compareTo(b.displayPath));
    return _dedupeSourceDocs(docs);
  }

  static List<_DecentSourceDoc> _sourceDocsForArchivePreset(
    List<_DecentSourceDoc> docs,
    String presetDirectory,
  ) {
    final normalizedPresetDirectory = _normalizeZipPath(presetDirectory);
    final presetPrefix =
        normalizedPresetDirectory.isEmpty || normalizedPresetDirectory == '.'
        ? ''
        : '$normalizedPresetDirectory/';
    final filtered = <_DecentSourceDoc>[];
    for (final doc in docs) {
      final path = _normalizeZipPath(doc.sourcePath);
      final isTopLevel = !path.contains('/');
      final isUnderPreset =
          presetPrefix.isNotEmpty && path.startsWith(presetPrefix);
      final isRootDocsFolder =
          path.contains('/') &&
          _sourceDocFolderHints.contains(path.split('/').first.toLowerCase());
      if (isTopLevel || isUnderPreset || isRootDocsFolder) {
        filtered.add(
          presetPrefix.isNotEmpty && path.startsWith(presetPrefix)
              ? _DecentSourceDoc(
                  sourcePath: p.posix.relative(
                    path,
                    from: normalizedPresetDirectory,
                  ),
                  displayPath: path,
                )
              : _DecentSourceDoc(
                  sourcePath: p.posix.relative(
                    path,
                    from: normalizedPresetDirectory,
                  ),
                  displayPath: path,
                ),
        );
      }
    }
    return _dedupeSourceDocs(filtered);
  }

  static List<_DecentSourceDoc> _dedupeSourceDocs(List<_DecentSourceDoc> docs) {
    final seen = <String>{};
    return [
      for (final doc in docs)
        if (seen.add(doc.displayPath.toLowerCase())) doc,
    ];
  }

  static bool _isSourceDocPath(String path) {
    final normalized = _normalizeZipPath(path);
    if (normalized.isEmpty || _isMacOsJunkPath(normalized)) return false;
    final extension = p.posix.extension(normalized).toLowerCase();
    if (!_sourceDocExtensions.contains(extension)) return false;
    final parts = normalized
        .split('/')
        .map((part) => part.toLowerCase())
        .toList();
    final stem = p.posix.basenameWithoutExtension(normalized).toLowerCase();
    final searchable = [...parts, stem].join(' ');
    final hasDocName = _sourceDocNameHints.any(searchable.contains);
    final hasDocFolder = parts.any(_sourceDocFolderHints.contains);
    final isTopLevel = !normalized.contains('/');
    if (_sourceGraphicExtensions.contains(extension)) {
      return hasDocName || hasDocFolder;
    }
    if (_sourceTextDocExtensions.contains(extension) && isTopLevel) {
      return true;
    }
    return hasDocName || hasDocFolder;
  }

  static String _uniqueDocOutputName(String sourcePath, Set<String> usedNames) {
    final normalized = _normalizeZipPath(sourcePath);
    final basename = p.posix
        .basename(normalized)
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
    final safeName = basename.trim().isEmpty ? 'source_doc' : basename.trim();
    final extension = p.extension(safeName);
    final stem = p.basenameWithoutExtension(safeName);
    var candidate = safeName;
    var index = 2;
    while (!usedNames.add(candidate.toLowerCase())) {
      candidate = extension.isEmpty
          ? '${stem}_$index'
          : '${stem}_$index$extension';
      index++;
    }
    return candidate;
  }

  static const _sourceDocExtensions = {
    '.txt',
    '.md',
    '.markdown',
    '.pdf',
    '.rtf',
    '.html',
    '.htm',
    '.url',
    '.doc',
    '.docx',
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
  };

  static const _sourceGraphicExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
  };

  static const _sourceTextDocExtensions = {
    '.txt',
    '.md',
    '.markdown',
    '.pdf',
    '.rtf',
    '.html',
    '.htm',
    '.url',
    '.doc',
    '.docx',
  };

  static const _sourceDocNameHints = {
    'license',
    'licence',
    'readme',
    'credits',
    'credit',
    'attribution',
    'copyright',
    'manual',
    'guide',
    'docs',
    'documentation',
    'info',
    'about',
    'terms',
    'eula',
    'cover',
    'artwork',
  };

  static const _sourceDocFolderHints = {
    'docs',
    'doc',
    'documentation',
    'manual',
    'manuals',
    'license',
    'licenses',
    'licence',
    'licences',
    'readme',
    'info',
    'credits',
    'artwork',
    'cover',
  };

  static String _groupKey(_DecentRawRegion region) {
    return _groupKeyFromParts(region.groupIndex, region.groupName);
  }

  static String _groupKeyFromParts(int index, String name) {
    return '$index:$name';
  }

  static String _groupXmlSummary(_DecentSampleGroup group) {
    final attrs = Map<String, String>.of(group.attributes)
      ..removeWhere((key, value) => key == 'name' || value.trim().isEmpty);
    if (attrs.isEmpty) return 'No group-level XML attributes';
    final priority = [
      'seqmode',
      'trigger',
      'lovel',
      'hivel',
      'lokey',
      'hikey',
      'volume',
      'pan',
      'tags',
      'silencedbytags',
      'silencingmode',
    ];
    final keys = [
      ...priority.where(attrs.containsKey),
      ...attrs.keys.where((key) => !priority.contains(key)).toList()..sort(),
    ];
    return keys.take(8).map((key) => '$key=${attrs[key]}').join(', ');
  }

  static String? _groupNameForKey(
    List<_DecentSampleGroup> groups,
    String? key,
  ) {
    if (key == null) return null;
    for (final group in groups) {
      if (_groupKeyFromParts(group.index, group.name) == key) {
        return group.name;
      }
    }
    return null;
  }

  static String _mappingSignature(_DecentRawRegion region) {
    final root = region.rootMidi ?? -1;
    final low = region.lowMidi ?? root;
    final high = region.highMidi ?? root;
    return '$root|$low|$high|${region.seqPosition ?? '-'}';
  }

  static String _overlapSignature(_DecentRawRegion region) {
    final root = region.rootMidi ?? -1;
    final low = region.lowMidi ?? root;
    final high = region.highMidi ?? root;
    final velocity = region.hasExplicitVelocity
        ? '${region.velocityLow}-${region.velocityHigh}'
        : '1-127';
    return '$root|$low|$high|$velocity|${region.seqPosition ?? '-'}';
  }

  static String _structureSummary(
    List<_DecentSampleGroup> sampleGroups,
    List<_DecentRawRegion> rawRegions,
    String content,
  ) {
    if (rawRegions.isEmpty) return '';
    final roots = rawRegions
        .map((region) => region.rootMidi)
        .whereType<int>()
        .toSet();
    final roundRobins =
        rawRegions.map((region) => region.seqPosition).whereType<int>().toList()
          ..sort();
    final explicitVelocityRanges =
        rawRegions
            .where((region) => region.hasExplicitVelocity)
            .map((region) => '${region.velocityLow}-${region.velocityHigh}')
            .toSet()
            .toList()
          ..sort();

    final layerToRoundRobins = <String, Set<int>>{};
    for (final region in rawRegions.where(
      (region) => region.seqPosition != null,
    )) {
      final label = _roundRobinBankLabel(region);
      if (label.isEmpty) continue;
      layerToRoundRobins
          .putIfAbsent(label, () => <int>{})
          .add(region.seqPosition!);
    }
    final bindings = _groupBindings(content);
    final bindingParams = bindings
        .map((binding) => binding.parameter)
        .where((value) => value.isNotEmpty)
        .toSet();
    final bindingControls = bindings
        .map((binding) => binding.controlLabel)
        .where((value) => value.isNotEmpty)
        .toSet();
    final groupLabels =
        sampleGroups
            .map((group) => _roundRobinBankLabelFromName(group.name, null))
            .where((label) => label.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final parts = <String>[];
    parts.add(
      '${sampleGroups.length} group(s), ${rawRegions.length} sample(s)',
    );

    if (layerToRoundRobins.length > 1 && roundRobins.isNotEmpty) {
      final layerNames = layerToRoundRobins.keys.toList()..sort();
      final rrValues = roundRobins.toSet().toList()..sort();
      final allLayersUseSameRr = layerToRoundRobins.values.every(
        (values) => _sameSet(
          values.map((value) => value.toString()).toSet(),
          rrValues.map((value) => value.toString()).toSet(),
        ),
      );
      parts.add(
        '${layerNames.length} labelled group layer(s) (${layerNames.take(6).join(', ')}) '
        '${allLayersUseSameRr ? 'each ' : ''}with RR ${rrValues.first}-${rrValues.last}',
      );
    } else if (groupLabels.length > 1) {
      parts.add('group labels ${groupLabels.take(8).join(', ')}');
    } else if (roundRobins.isNotEmpty) {
      final rrValues = roundRobins.toSet().toList()..sort();
      parts.add('round robins RR ${rrValues.first}-${rrValues.last}');
    }

    if (explicitVelocityRanges.isNotEmpty) {
      if (explicitVelocityRanges.length == 1 &&
          explicitVelocityRanges.first == '1-127') {
        parts.add('all samples use full velocity 1-127');
      } else {
        parts.add(
          '${explicitVelocityRanges.length} explicit velocity range(s): ${explicitVelocityRanges.take(8).join(', ')}',
        );
      }
    }
    if (bindingParams.isNotEmpty) {
      final controls = bindingControls.isEmpty
          ? 'Decent UI/control bindings'
          : 'Decent controls ${bindingControls.take(5).join(', ')}';
      final params = bindingParams.take(6).join(', ');
      final bindsVolume = bindingParams.any(
        (param) => param.toUpperCase().contains('VOLUME'),
      );
      final bindsEnabled = bindingParams.any(
        (param) => param.toUpperCase().contains('ENABLED'),
      );
      if (bindsVolume) {
        parts.add(
          '$controls fade/mix group volume ($params), so these may be controller layers rather than velocity layers',
        );
      } else if (bindsEnabled) {
        parts.add(
          '$controls switch groups on/off ($params), so these may be articulations/options',
        );
      } else {
        parts.add('$controls affect groups ($params)');
      }
    }
    parts.add('${roots.length} root note(s)');
    return parts.join('; ');
  }

  static String _uiGroupBindingSummary(String content) {
    final bindings = _groupBindings(content);
    if (bindings.isEmpty) return '';
    final positions = bindings
        .map((binding) => binding.position)
        .whereType<int>()
        .toSet();
    final params = bindings
        .map((binding) => binding.parameter)
        .where((value) => value.isNotEmpty)
        .toSet();
    final controls = bindings
        .map((binding) => binding.controlLabel)
        .where((value) => value.isNotEmpty)
        .toSet();
    if (positions.isEmpty) return '';
    final sortedPositions = positions.toList()..sort();
    final sortedParams = params.toList()..sort();
    final sortedControls = controls.toList()..sort();
    final controlText = sortedControls.isEmpty
        ? 'UI controls'
        : 'UI controls ${sortedControls.take(4).join(', ')}';
    final paramText = sortedParams.isEmpty
        ? ''
        : ' (${sortedParams.take(4).join(', ')})';
    final linksVolume = sortedParams.any(
      (param) => param.toUpperCase().contains('VOLUME'),
    );
    final action = linksVolume
        ? 'control group volume for positions'
        : 'bind group positions';
    return '$controlText $action ${sortedPositions.join(', ')}$paramText';
  }

  static List<_GroupBindingInfo> _groupBindings(String content) {
    final document = html_parser.parse(content);
    final root = document.querySelector('decentsampler');
    if (root == null) return const [];
    final bindings = <_GroupBindingInfo>[];
    for (final binding in root.querySelectorAll('binding')) {
      final attrs = _elementAttributes(binding);
      if (attrs['level']?.toLowerCase() != 'group') continue;
      final parent = binding.parent;
      final parentAttrs = parent == null
          ? const <String, String>{}
          : _elementAttributes(parent);
      bindings.add(
        _GroupBindingInfo(
          position: _parseIntAttribute(attrs['position']),
          parameter: attrs['parameter']?.trim() ?? '',
          controlLabel: (parentAttrs['label'] ?? parentAttrs['name'] ?? '')
              .trim(),
        ),
      );
    }
    return bindings;
  }

  static DecentSamplerGroupHandling _recommendedGroupHandling(
    List<_DecentRawRegion> rawRegions,
  ) {
    final banks = _roundRobinBankLabels(rawRegions);
    if (banks.length > 1) {
      final labels = banks.values.toList();
      return labels.every(_isDynamicLabel)
          ? DecentSamplerGroupHandling.velocityLayers
          : DecentSamplerGroupHandling.splitFolders;
    }
    if (_dynamicGroupVelocityLayersStatic(rawRegions) != null) {
      return DecentSamplerGroupHandling.velocityLayers;
    }
    return DecentSamplerGroupHandling.auto;
  }

  static DecentSamplerGroupHandling _mergeRecommendations(
    Set<DecentSamplerGroupHandling> recommendations,
  ) {
    if (recommendations.contains(DecentSamplerGroupHandling.splitFolders)) {
      return DecentSamplerGroupHandling.splitFolders;
    }
    if (recommendations.contains(DecentSamplerGroupHandling.velocityLayers)) {
      return DecentSamplerGroupHandling.velocityLayers;
    }
    return DecentSamplerGroupHandling.auto;
  }

  static Map<String, String> _roundRobinBankLabels(
    List<_DecentRawRegion> rawRegions,
  ) {
    final labels = <String, String>{};
    for (final region in rawRegions) {
      if (region.seqPosition == null) continue;
      final label = _roundRobinBankLabel(region);
      if (label.isEmpty) continue;
      labels[_labelKey(label)] = label;
    }
    return labels;
  }

  static String _roundRobinBankLabel(_DecentRawRegion region) {
    return _roundRobinBankLabelFromName(region.groupName, region.seqPosition);
  }

  static String _roundRobinBankLabelFromName(String name, int? rr) {
    var label = name.trim();
    if (rr != null) {
      for (final pattern in [
        RegExp(
          '(^|[\\s_\\-])rr\\s*0*$rr(?=\$|[\\s_\\-])',
          caseSensitive: false,
        ),
        RegExp(
          '(^|[\\s_\\-])round\\s*robin\\s*0*$rr(?=\$|[\\s_\\-])',
          caseSensitive: false,
        ),
        RegExp(
          '(^|[\\s_\\-])seq\\s*0*$rr(?=\$|[\\s_\\-])',
          caseSensitive: false,
        ),
      ]) {
        label = label.replaceAll(pattern, ' ');
      }
    }
    label = _compactLabel(label);
    if (label.isEmpty || _isGenericGroupLabel(label)) return '';
    return label;
  }

  static String _compactLabel(String value) {
    return value
        .replaceAll(RegExp(r'[\s_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isGenericGroupLabel(String label) {
    final normalized = _labelKey(label).replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return normalized.isEmpty ||
        normalized == 'group' ||
        RegExp(r'^group\d+$').hasMatch(normalized);
  }

  static String _labelKey(String value) => _compactLabel(value).toLowerCase();

  static bool _isDynamicLabel(String label) {
    return label
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .any(
          (word) =>
              _dynamicNameRanks.containsKey(word) ||
              _numberedDynamicLayerRank(word) != null,
        );
  }

  static int _dynamicLabelRank(String label) {
    final words = label
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty);
    var rank = 1000;
    for (final word in words) {
      final layerRank = _numberedDynamicLayerRank(word);
      if (layerRank != null && layerRank < rank) rank = layerRank;
      final value = _dynamicNameRanks[word];
      if (value != null && value < rank) rank = value;
    }
    return rank;
  }

  static bool _sameSet(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }

  static bool _isDynamicGroupName(String key) {
    final name = key.substring(key.indexOf(':') + 1).toLowerCase();
    final words = name
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty);
    return words.any((word) {
      return _dynamicNameRanks.containsKey(word) ||
          _numberedDynamicLayerRank(word) != null;
    });
  }

  static int _dynamicGroupRank(String key) {
    final name = key.substring(key.indexOf(':') + 1).toLowerCase();
    final words = name
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty);
    var rank = 1000;
    for (final word in words) {
      final layerRank = _numberedDynamicLayerRank(word);
      if (layerRank != null && layerRank < rank) rank = layerRank;
      final value = _dynamicNameRanks[word];
      if (value != null && value < rank) rank = value;
    }
    return rank;
  }

  static int? _numberedDynamicLayerRank(String word) {
    final match = RegExp(
      r'^(?:vel|velocity|v|dyn|dynamic|layer|l)(\d+)$',
    ).firstMatch(word);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static String _groupLayerSummary(Map<String, int> layers) {
    final entries = layers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries
        .map(
          (entry) =>
              '${entry.key.substring(entry.key.indexOf(':') + 1)}=V${entry.value}',
        )
        .join(', ');
  }

  static const _dynamicNameRanks = {
    'pp': 1,
    'p': 2,
    'soft': 2,
    'quiet': 2,
    'low': 2,
    'mp': 3,
    'medium': 3,
    'med': 3,
    'mid': 3,
    'mf': 4,
    'hard': 5,
    'loud': 5,
    'high': 5,
    'f': 6,
    'ff': 7,
    'fff': 8,
  };
}

class _DecentSampleGroup {
  const _DecentSampleGroup({
    required this.index,
    required this.attributes,
    required this.samples,
  });

  final int index;
  final Map<String, String> attributes;
  final List<Map<String, String>> samples;

  String get name {
    final explicitName = attributes['name']?.trim();
    if (explicitName != null && explicitName.isNotEmpty) return explicitName;
    for (final key in const ['tags', 'tag', 'articulation', 'mic', 'label']) {
      final value = attributes[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return 'Group ${index + 1}';
  }
}

class _GroupBindingInfo {
  const _GroupBindingInfo({
    required this.position,
    required this.parameter,
    required this.controlLabel,
  });

  final int? position;
  final String parameter;
  final String controlLabel;
}

class _DecentPresetPlan {
  const _DecentPresetPlan({
    required this.presetName,
    required this.regions,
    required this.sourceResolver,
    required this.sourceDocs,
  });

  final String presetName;
  final List<_DecentMappedRegion> regions;
  final _DecentSourceResolver sourceResolver;
  final List<_DecentSourceDoc> sourceDocs;

  _DecentPresetPlan copyWith({
    _DecentSourceResolver? sourceResolver,
    List<_DecentSourceDoc>? sourceDocs,
  }) {
    return _DecentPresetPlan(
      presetName: presetName,
      regions: regions,
      sourceResolver: sourceResolver ?? this.sourceResolver,
      sourceDocs: sourceDocs ?? this.sourceDocs,
    );
  }
}

class _DecentSourceDoc {
  const _DecentSourceDoc({required this.sourcePath, required this.displayPath});

  final String sourcePath;
  final String displayPath;
}

class _MutableDecentTag {
  _MutableDecentTag({
    required this.label,
    required this.confidence,
    required this.evidence,
  });

  final String label;
  double confidence;
  String evidence;
  int sampleCount = 0;
  int maxGroupSampleCount = 0;
  int? defaultLowMidi;
  int? defaultRootMidi;
  int? defaultHighMidi;
  int? defaultVelocityLayer;
  String? structureSummary;
  String? noteRange;
  String? velocitySummary;
  String? roundRobinSummary;
  String? previewSourcePath;
  final Set<String> groupKeys = {};

  _DefaultDecentMapping get defaults => _DefaultDecentMapping(
    lowMidi: (defaultLowMidi ?? defaultRootMidi ?? 36).clamp(0, 127).toInt(),
    rootMidi: (defaultRootMidi ?? defaultLowMidi ?? 36).clamp(0, 127).toInt(),
    highMidi: (defaultHighMidi ?? defaultRootMidi ?? defaultLowMidi ?? 36)
        .clamp(0, 127)
        .toInt(),
    velocityLayer: (defaultVelocityLayer ?? 1).clamp(1, 32).toInt(),
  );

  DecentSamplerTag toTag(
    String key,
    _DefaultDecentMapping defaults, {
    String? structureSummary,
    String? noteRange,
    String? velocitySummary,
    String? roundRobinSummary,
    String? previewSourcePath,
  }) {
    final groups = groupKeys.toList()..sort();
    return DecentSamplerTag(
      key: key,
      label: label,
      groupKeys: groups,
      sampleCount: sampleCount,
      confidence: confidence,
      evidence: evidence,
      structureSummary:
          structureSummary ??
          this.structureSummary ??
          '$sampleCount sample${sampleCount == 1 ? '' : 's'}',
      noteRange: noteRange ?? this.noteRange ?? 'No notes',
      velocitySummary:
          velocitySummary ??
          this.velocitySummary ??
          'No explicit velocity ranges',
      roundRobinSummary:
          roundRobinSummary ?? this.roundRobinSummary ?? 'No seqPosition',
      defaultLowMidi: defaults.lowMidi,
      defaultRootMidi: defaults.rootMidi,
      defaultHighMidi: defaults.highMidi,
      defaultVelocityLayer: defaults.velocityLayer,
      previewSourcePath: previewSourcePath ?? this.previewSourcePath,
    );
  }
}

class _DefaultDecentMapping {
  const _DefaultDecentMapping({
    required this.lowMidi,
    required this.rootMidi,
    required this.highMidi,
    required this.velocityLayer,
  });

  final int lowMidi;
  final int rootMidi;
  final int highMidi;
  final int velocityLayer;
}

class _SelectedTagPlan {
  const _SelectedTagPlan({required this.label, required this.tagKeys});

  final String label;
  final Set<String> tagKeys;
}

class _TagVelocityLayerPlan {
  const _TagVelocityLayerPlan({
    required this.tagLayers,
    required this.regionLayers,
  });

  final Map<String, int> tagLayers;
  final Map<_DecentRawRegion, int> regionLayers;
}

class _TagKeyRangePlan {
  const _TagKeyRangePlan({
    required this.tagRanges,
    required this.regionMappings,
  });

  final Map<String, DecentSamplerTagKeyRange> tagRanges;
  final Map<_DecentRawRegion, _RegionKeyRangeMapping> regionMappings;
}

class _RegionKeyRangeMapping {
  const _RegionKeyRangeMapping({
    required this.tagKey,
    required this.range,
    required this.sourceRootMidi,
  });

  final String tagKey;
  final DecentSamplerTagKeyRange range;
  final int sourceRootMidi;
}

class _MutableSplitFolderGroup {
  _MutableSplitFolderGroup({
    required this.label,
    required this.firstGroupIndex,
  });

  final String label;
  int firstGroupIndex;
  final List<_DecentRawRegion> regions = [];
}

class _SplitFolderGroup {
  const _SplitFolderGroup({
    required this.label,
    required this.firstGroupIndex,
    required this.regions,
  });

  final String label;
  final int firstGroupIndex;
  final List<_DecentRawRegion> regions;
}

class _DecentRawRegion {
  const _DecentRawRegion({
    required this.sourcePath,
    required this.rootMidi,
    required this.lowMidi,
    required this.highMidi,
    required this.velocityLow,
    required this.velocityHigh,
    required this.hasExplicitVelocity,
    required this.pitchKeyTrackDisabled,
    required this.seqPosition,
    required this.loopStart,
    required this.loopEnd,
    required this.groupName,
    required this.groupIndex,
    required this.tagKeys,
  });

  final String sourcePath;
  final int? rootMidi;
  final int? lowMidi;
  final int? highMidi;
  final int velocityLow;
  final int velocityHigh;
  final bool hasExplicitVelocity;
  final bool pitchKeyTrackDisabled;
  final int? seqPosition;
  final int? loopStart;
  final int? loopEnd;
  final String groupName;
  final int groupIndex;
  final Set<String> tagKeys;
}

class _DecentMappedRegion {
  const _DecentMappedRegion({
    required this.sourcePath,
    required this.outputFileName,
    required this.groupName,
    required this.rootMidi,
    required this.switchPoint,
    required this.velocityLayer,
    required this.roundRobin,
    required this.loopStart,
    required this.loopEnd,
  });

  final String sourcePath;
  final String outputFileName;
  final String groupName;
  final int rootMidi;
  final int switchPoint;
  final int velocityLayer;
  final int roundRobin;
  final int? loopStart;
  final int? loopEnd;
}

abstract class _DecentSourceResolver {
  const _DecentSourceResolver();

  Future<Uint8List?> read(String samplePath);
}

class _MissingDecentSourceResolver extends _DecentSourceResolver {
  const _MissingDecentSourceResolver();

  @override
  Future<Uint8List?> read(String samplePath) async => null;
}

class _BlockedDecentSourceException implements Exception {
  const _BlockedDecentSourceException(this.message);

  final String message;
}

class _LocalDecentSourceResolver extends _DecentSourceResolver {
  const _LocalDecentSourceResolver({
    required this.baseDirectory,
    required this.allowedRoot,
  });

  final String baseDirectory;
  final String allowedRoot;

  @override
  Future<Uint8List?> read(String samplePath) async {
    final resolved = await _resolveSamplePath(samplePath);
    if (resolved == null) return null;
    final file = File(resolved);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  Future<String?> _resolveSamplePath(String samplePath) async {
    final requestedPath = p.normalize(samplePath.trim());
    if (p.isAbsolute(requestedPath) || _isWindowsAbsolutePath(requestedPath)) {
      throw _BlockedDecentSourceException(
        '$samplePath is outside the selected source and was skipped.',
      );
    }
    final joined = p.isAbsolute(requestedPath)
        ? requestedPath
        : p.normalize(p.join(baseDirectory, requestedPath));
    final root = await Directory(allowedRoot).resolveSymbolicLinks();
    String resolved;
    try {
      resolved = await File(joined).resolveSymbolicLinks();
    } on FileSystemException {
      resolved = p.canonicalize(joined);
    }
    if (!_isWithinDirectory(resolved, root)) {
      throw _BlockedDecentSourceException(
        '$samplePath is outside the selected source and was skipped.',
      );
    }
    return resolved;
  }
}

bool _isWithinDirectory(String candidate, String root) {
  if (candidate == root) return true;
  return p.isWithin(root, candidate);
}

class _ArchiveDecentSourceResolver extends _DecentSourceResolver {
  const _ArchiveDecentSourceResolver({
    required this.files,
    required this.presetDirectory,
  });

  final Map<String, ArchiveFile> files;
  final String presetDirectory;

  @override
  Future<Uint8List?> read(String samplePath) async {
    final path = _resolveArchivePath(samplePath);
    final file = files[path] ?? _caseInsensitiveLookup(path);
    if (file == null) return null;
    return Uint8List.fromList(file.content as List<int>);
  }

  String _resolveArchivePath(String samplePath) {
    final normalizedSamplePath = samplePath.trim().replaceAll('\\', '/');
    if (p.posix.isAbsolute(normalizedSamplePath) ||
        _isWindowsAbsolutePath(normalizedSamplePath)) {
      throw _BlockedDecentSourceException(
        '$samplePath is outside the selected source and was skipped.',
      );
    }
    final parts = <String>[
      if (presetDirectory != '.')
        ...DecentSamplerConverter._normalizeZipPath(
          presetDirectory,
        ).split('/').where((part) => part.isNotEmpty),
    ];
    for (final part in normalizedSamplePath.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isEmpty) {
          throw _BlockedDecentSourceException(
            '$samplePath is outside the selected source and was skipped.',
          );
        }
        parts.removeLast();
        continue;
      }
      parts.add(part);
    }
    return parts.join('/');
  }

  ArchiveFile? _caseInsensitiveLookup(String path) {
    final lower = path.toLowerCase();
    for (final entry in files.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
  }
}

bool _isWindowsAbsolutePath(String path) {
  return RegExp(r'^[A-Za-z]:[/\\]').hasMatch(path) ||
      path.startsWith(r'\\') ||
      path.startsWith('\\');
}

bool _isUnsafeArchiveEntryPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  if (p.posix.isAbsolute(normalized) || _isWindowsAbsolutePath(path)) {
    return true;
  }
  return normalized.split('/').any((part) => part == '..');
}
