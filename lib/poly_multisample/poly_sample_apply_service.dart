import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import 'poly_multisample_models.dart';
import 'poly_multisample_parser.dart';

class PolySampleApplyException implements Exception {
  const PolySampleApplyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PolySampleApplyService {
  const PolySampleApplyService();

  PolySampleApplyPlan buildPlan({
    required List<PolySampleRegion> baselineRegions,
    required List<PolySampleRegion> editedRegions,
    required String targetFolder,
    Set<String> existingPaths = const {},
    p.Context? pathContext,
  }) {
    final paths = pathContext ?? p.context;
    final baselineByPath = {
      for (final region in baselineRegions)
        _normalizePath(region.path, paths): region,
    };
    final editedBySourcePath = {
      for (final region in editedRegions)
        _normalizePath(region.path, paths): region,
    };
    final baselinePaths = baselineByPath.keys.toSet();
    final editedSourcePaths = editedBySourcePath.keys.toSet();
    final renames = <PolySampleFileRename>[];
    final removals = <PolySampleFileRemoval>[];
    final additions = <PolySampleFileAddition>[];
    final conflicts = <PolySampleApplyConflict>[];
    final targetOwners = <String, List<String>>{};
    final includeVelocity = editedRegions.any(
      (region) => (region.velocityLayer ?? 1) > 1,
    );
    final includeRoundRobin = editedRegions.any(
      (region) => (region.roundRobin ?? 1) > 1,
    );

    for (final baselineRegion in baselineRegions) {
      if (!editedSourcePaths.contains(
        _normalizePath(baselineRegion.path, paths),
      )) {
        removals.add(
          PolySampleFileRemoval(
            path: baselineRegion.path,
            region: baselineRegion,
          ),
        );
      }
    }

    for (final region in editedRegions) {
      final sourcePath = _normalizePath(region.path, paths);
      final targetFileName = buildTargetFileName(
        region,
        includeVelocity: includeVelocity,
        includeRoundRobin: includeRoundRobin,
        pathContext: paths,
      );
      final targetPath = _normalizePath(
        paths.join(targetFolder, targetFileName),
        paths,
      );
      targetOwners.putIfAbsent(targetPath, () => []).add(region.path);

      if (baselinePaths.contains(sourcePath)) {
        if (sourcePath != targetPath) {
          renames.add(
            PolySampleFileRename(
              fromPath: region.path,
              toPath: targetPath,
              region: region,
            ),
          );
        }
      } else {
        additions.add(
          PolySampleFileAddition(
            sourcePath: region.path,
            toPath: targetPath,
            region: region,
          ),
        );
      }
    }

    for (final entry in targetOwners.entries) {
      if (entry.value.length > 1) {
        conflicts.add(
          PolySampleApplyConflict(
            path: entry.key,
            message: 'Multiple samples target ${paths.basename(entry.key)}.',
          ),
        );
      }
    }

    for (final existingPath in existingPaths.map((path) {
      return _normalizePath(path, paths);
    })) {
      if (!targetOwners.containsKey(existingPath)) continue;
      if (baselinePaths.contains(existingPath)) continue;
      conflicts.add(
        PolySampleApplyConflict(
          path: existingPath,
          message: '${paths.basename(existingPath)} already exists.',
        ),
      );
    }

    return PolySampleApplyPlan(
      additions: additions,
      removals: removals,
      renames: renames,
      conflicts: conflicts,
    );
  }

  String buildTargetFileName(
    PolySampleRegion region, {
    bool includeVelocity = false,
    bool includeRoundRobin = false,
    p.Context? pathContext,
  }) {
    final paths = pathContext ?? p.context;
    final extension = paths.extension(region.fileName);
    final prefix = _preservedPrefix(region.fileName, paths);
    final parts = <String>[
      if (prefix.isNotEmpty) prefix,
      if (region.rootMidi != null)
        region.rootName ??
            PolyMultisampleParser.midiToNoteName(region.rootMidi!),
      if (region.switchPoint != null) 'SW${region.switchPoint}',
      if (includeVelocity || (region.velocityLayer ?? 1) > 1)
        'V${region.velocityLayer ?? 1}',
      if (includeRoundRobin || (region.roundRobin ?? 1) > 1)
        'RR${region.roundRobin ?? 1}',
    ];
    if (parts.isEmpty) {
      return region.fileName;
    }
    return '${parts.join('_')}$extension';
  }

  Future<void> applyLocalPlan(PolySampleApplyPlan plan) async {
    if (plan.hasConflicts) {
      final details = plan.conflicts
          .map((conflict) {
            return conflict.message;
          })
          .join(' ');
      throw PolySampleApplyException(
        'Cannot apply a plan with conflicts. $details',
      );
    }

    await _preflightLocalPlan(plan);

    for (final removal in plan.removals) {
      final file = File(removal.path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    final stagedRenames = <({String tempPath, PolySampleFileRename rename})>[];
    for (final rename in plan.renames) {
      final fromFile = File(rename.fromPath);
      if (!await fromFile.exists()) {
        throw PolySampleApplyException(
          'Cannot rename missing sample ${rename.fromPath}.',
        );
      }
      final tempPath = _uniqueTempPath(rename.fromPath);
      await fromFile.rename(tempPath);
      stagedRenames.add((tempPath: tempPath, rename: rename));
    }

    for (final staged in stagedRenames) {
      await Directory(p.dirname(staged.rename.toPath)).create(recursive: true);
      await File(staged.tempPath).rename(staged.rename.toPath);
    }

    for (final addition in plan.additions) {
      await Directory(p.dirname(addition.toPath)).create(recursive: true);
      await File(addition.sourcePath).copy(addition.toPath);
    }
  }

  Future<void> _preflightLocalPlan(PolySampleApplyPlan plan) async {
    final vacatedPaths = <String>{
      for (final removal in plan.removals) p.normalize(removal.path),
      for (final rename in plan.renames) p.normalize(rename.fromPath),
    };

    for (final removal in plan.removals) {
      final type = await FileSystemEntity.type(removal.path);
      if (type != FileSystemEntityType.file &&
          type != FileSystemEntityType.notFound) {
        throw PolySampleApplyException(
          '${p.basename(removal.path)} is not a removable sample file.',
        );
      }
    }

    for (final rename in plan.renames) {
      if (!await File(rename.fromPath).exists()) {
        throw PolySampleApplyException(
          'Cannot rename missing sample ${rename.fromPath}.',
        );
      }
      final targetPath = p.normalize(rename.toPath);
      final sourcePath = p.normalize(rename.fromPath);
      if (targetPath == sourcePath || vacatedPaths.contains(targetPath)) {
        continue;
      }
      if (await FileSystemEntity.type(rename.toPath) !=
          FileSystemEntityType.notFound) {
        throw PolySampleApplyException(
          '${p.basename(rename.toPath)} already exists.',
        );
      }
    }

    for (final addition in plan.additions) {
      if (!await File(addition.sourcePath).exists()) {
        throw PolySampleApplyException(
          'Cannot copy missing sample ${addition.sourcePath}.',
        );
      }
      final targetPath = p.normalize(addition.toPath);
      final sourcePath = p.normalize(addition.sourcePath);
      if (targetPath == sourcePath || vacatedPaths.contains(targetPath)) {
        continue;
      }
      if (await FileSystemEntity.type(addition.toPath) !=
          FileSystemEntityType.notFound) {
        throw PolySampleApplyException(
          '${p.basename(addition.toPath)} already exists.',
        );
      }
    }
  }
}

String _preservedPrefix(String fileName, p.Context paths) {
  final stem = paths.basenameWithoutExtension(fileName).trim();
  final normalized = stem.replaceAll(RegExp(r'\s+'), '_');
  final tokens = normalized.split('_').where((token) => token.isNotEmpty);
  final kept = tokens.where((token) {
    final upper = token.toUpperCase();
    if (RegExp(r'^[A-G](?:#|B)?-?\d+$', caseSensitive: false).hasMatch(token)) {
      return false;
    }
    if (RegExp(r'^SW\d+$').hasMatch(upper)) return false;
    if (RegExp(r'^V\d+$').hasMatch(upper)) return false;
    if (RegExp(r'^RR\d+$').hasMatch(upper)) return false;
    return true;
  }).toList();
  return kept.join('_');
}

String _normalizePath(String path, p.Context paths) => paths.normalize(path);

String _uniqueTempPath(String sourcePath) {
  final directory = p.dirname(sourcePath);
  final basename = p.basename(sourcePath);
  for (var attempt = 0; attempt < 1000; attempt++) {
    final suffix = DateTime.now().microsecondsSinceEpoch + attempt;
    final candidate = p.join(directory, '.$basename.poly-tmp-$suffix');
    if (!File(candidate).existsSync()) return candidate;
  }
  final fallback = math.Random().nextInt(1 << 32);
  return p.join(directory, '.$basename.poly-tmp-$fallback');
}
