import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:path/path.dart' as p;

import '../../poly_multisample/poly_multisample_models.dart';
import '../../poly_multisample/poly_multisample_parser.dart';
import '../../poly_multisample/wav_metadata.dart';

class PolyMultisampleBuilderScreen extends StatefulWidget {
  const PolyMultisampleBuilderScreen({super.key});

  @override
  State<PolyMultisampleBuilderScreen> createState() =>
      _PolyMultisampleBuilderScreenState();
}

class _PolyMultisampleBuilderScreenState
    extends State<PolyMultisampleBuilderScreen> {
  PolySampleInstrument? _instrument;
  PolySampleRegion? _selectedRegion;
  bool _loading = false;
  String? _error;

  Future<void> _chooseFolder() async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose Disting sample folder',
    );
    if (path == null) return;
    await _loadFolder(path);
  }

  Future<void> _loadFolder(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final instrument = await PolyMultisampleFolderReader.readDirectory(path);
      setState(() {
        _instrument = instrument;
        _selectedRegion = instrument.regions.isEmpty
            ? null
            : instrument.regions.first;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _chooseNtSdFolder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final manager = context.read<DistingCubit>().disting();
      if (manager == null) {
        throw Exception('Connect to Disting NT first.');
      }
      final folders = await PolyMultisampleSdReader.listSampleFolders(manager);
      if (!mounted) return;
      setState(() => _loading = false);
      final selectedPath = await showDialog<String>(
        context: context,
        builder: (context) => _SdFolderPickerDialog(folders: folders),
      );
      if (selectedPath == null) return;
      await _loadNtSdFolder(selectedPath);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadNtSdFolder(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final manager = context.read<DistingCubit>().disting();
      if (manager == null) {
        throw Exception('Connect to Disting NT first.');
      }
      final instrument = await PolyMultisampleSdReader.readDirectory(
        manager,
        path,
      );
      setState(() {
        _instrument = instrument;
        _selectedRegion = instrument.regions.isEmpty
            ? null
            : instrument.regions.first;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final instrument = _instrument;

    return Column(
      children: [
        Material(
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.audio_file),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Poly Multisample Builder',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        instrument?.sourcePath ??
                            'Choose a sample folder to inspect',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _loading ? null : _chooseNtSdFolder,
                  icon: const Icon(Icons.memory),
                  label: const Text('NT SD'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _chooseFolder,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Local'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Import'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Export'),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _ErrorView(message: _error!, onRetry: _chooseFolder)
              : instrument == null
              ? _EmptyBuilderView(
                  onChooseFolder: _chooseFolder,
                  onChooseNtSdFolder: _chooseNtSdFolder,
                )
              : _InstrumentEditor(
                  instrument: instrument,
                  selectedRegion: _selectedRegion,
                  onSelectRegion: (region) {
                    setState(() => _selectedRegion = region);
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyBuilderView extends StatelessWidget {
  const _EmptyBuilderView({
    required this.onChooseFolder,
    required this.onChooseNtSdFolder,
  });

  final VoidCallback onChooseFolder;
  final VoidCallback onChooseNtSdFolder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.audio_file, size: 56, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Build a Disting NT multisample folder',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Open an existing /samples instrument folder to inspect roots, ranges, velocity layers, and round robins.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onChooseNtSdFolder,
                  icon: const Icon(Icons.memory),
                  label: const Text('Browse NT SD'),
                ),
                OutlinedButton.icon(
                  onPressed: onChooseFolder,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open Local Folder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SdFolderPickerDialog extends StatelessWidget {
  const _SdFolderPickerDialog({required this.folders});

  final List<String> folders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Disting NT Samples'),
      content: SizedBox(
        width: 520,
        height: 520,
        child: folders.isEmpty
            ? Center(
                child: Text(
                  'No sample folders found in /samples.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            : ListView.separated(
                itemCount: folders.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  final name = folder
                      .split('/')
                      .where((s) => s.isNotEmpty)
                      .last;
                  return ListTile(
                    leading: const Icon(Icons.folder_open),
                    title: Text(name),
                    subtitle: Text(folder),
                    onTap: () => Navigator.of(context).pop(folder),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose Folder'),
          ),
        ],
      ),
    );
  }
}

class _InstrumentEditor extends StatefulWidget {
  const _InstrumentEditor({
    required this.instrument,
    required this.selectedRegion,
    required this.onSelectRegion,
  });

  final PolySampleInstrument instrument;
  final PolySampleRegion? selectedRegion;
  final ValueChanged<PolySampleRegion> onSelectRegion;

  @override
  State<_InstrumentEditor> createState() => _InstrumentEditorState();
}

class _InstrumentEditorState extends State<_InstrumentEditor> {
  late List<PolySampleRegion> _regions;
  late List<PolySampleRegion> _baselineRegions;
  late List<_SampleLane> _mapLanes;
  late int _mapMinMidi;
  late int _mapMaxMidi;
  final AudioPlayer _samplePlayer = AudioPlayer();
  final Map<String, WavOverview?> _waveformCache = {};
  final Map<String, _LoopMarkerDraft> _loopDrafts = {};
  final Map<String, _LoopMarkerDraft> _savedLoopDrafts = {};
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;
  StreamSubscription<Duration>? _playerPositionSubscription;
  String? _selectedPath;
  String? _playingPath;
  bool _playerPlaying = false;
  bool _loopPreviewEnabled = false;
  bool _seekingLoop = false;
  bool _applying = false;
  bool _savingLoop = false;

  @override
  void initState() {
    super.initState();
    _resetDraft();
    _playerStateSubscription = _samplePlayer.onPlayerStateChanged.listen((
      state,
    ) {
      if (!mounted) return;
      setState(() {
        _playerPlaying = state == PlayerState.playing;
        if (state == PlayerState.stopped || state == PlayerState.completed) {
          _playingPath = null;
          _loopPreviewEnabled = false;
        }
      });
    });
    _playerCompleteSubscription = _samplePlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playingPath = null;
        _playerPlaying = false;
        _loopPreviewEnabled = false;
      });
    });
    _playerPositionSubscription = _samplePlayer.onPositionChanged.listen(
      _handlePlayerPosition,
    );
  }

  @override
  void didUpdateWidget(covariant _InstrumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.instrument, widget.instrument)) {
      _resetDraft();
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerPositionSubscription?.cancel();
    _samplePlayer.dispose();
    super.dispose();
  }

  void _resetDraft() {
    _waveformCache.clear();
    _loopDrafts.clear();
    _savedLoopDrafts.clear();
    _regions = _withExplicitSwitchPoints(widget.instrument.regions);
    _baselineRegions = List<PolySampleRegion>.of(_regions);
    _mapLanes = _sortedSampleLanes(_regions);
    _mapMinMidi = _initialMapMinMidi(_regions);
    _mapMaxMidi = _initialMapMaxMidi(_regions, _mapMinMidi);
    _selectedPath =
        widget.selectedRegion?.path ??
        (_regions.isEmpty ? null : _regions.first.path);
  }

  void _ensureMapLanes() {
    final lanes = _sortedSampleLanes(_regions);
    for (final lane in lanes) {
      if (!_mapLanes.contains(lane)) {
        _mapLanes.add(lane);
      }
    }
    _mapLanes.sort();
  }

  PolySampleRegion? get _selectedRegion {
    final selectedPath = _selectedPath;
    if (selectedPath == null) return null;
    for (final region in _regions) {
      if (region.path == selectedPath) return region;
    }
    return _regions.isEmpty ? null : _regions.first;
  }

  void _selectRegion(PolySampleRegion region) {
    setState(() => _selectedPath = region.path);
    widget.onSelectRegion(region);
  }

  void _updateRegion(PolySampleRegion updated) {
    setState(() {
      final index = _regions.indexWhere(
        (region) => region.path == updated.path,
      );
      if (index < 0) return;
      _regions[index] = updated;
      _ensureMapLanes();
      _selectedPath = updated.path;
    });
    final selected = _selectedRegion;
    if (selected != null) {
      widget.onSelectRegion(selected);
    }
  }

  void _updateSelectedRegion(PolySampleRegion updated) {
    _updateRegion(updated);
  }

  void _updateLoopFor(PolySampleRegion region, _LoopMarkerDraft markers) {
    setState(() {
      _loopDrafts[region.path] = markers;
      _selectedPath = region.path;
    });
  }

  Future<WavOverview?> _loadWaveformFor(PolySampleRegion region) async {
    if (_waveformCache.containsKey(region.path)) {
      return _waveformCache[region.path];
    }
    try {
      final bytes = await _readSampleBytes(region);
      if (bytes == null) {
        return null;
      }
      final overview = WavMetadataReader.parse(bytes);
      _waveformCache[region.path] = overview;
      if (overview != null && !_loopDrafts.containsKey(region.path)) {
        final markers = _LoopMarkerDraft.fromWaveform(overview);
        _loopDrafts[region.path] = markers;
        _savedLoopDrafts[region.path] = markers;
      }
      return overview;
    } catch (_) {
      return null;
    }
  }

  bool _isLoopDirty(PolySampleRegion? region) {
    if (region == null || _isNtSdPath(region.path)) return false;
    final draft = _loopDrafts[region.path];
    final saved = _savedLoopDrafts[region.path];
    return draft != null && saved != null && draft != saved;
  }

  Future<void> _saveLoopFor(PolySampleRegion region) async {
    if (_savingLoop || _isNtSdPath(region.path)) return;
    final overview = await _loadWaveformFor(region);
    if (overview == null) return;
    final markers =
        (_loopDrafts[region.path] ?? _LoopMarkerDraft.fromWaveform(overview))
            .clamped(overview.frameCount)
            .snappedToZeroCrossings(overview);

    setState(() => _savingLoop = true);
    try {
      final file = File(region.path);
      final bytes = await file.readAsBytes();
      final updated = WavMetadataWriter.writeSmplLoop(
        bytes,
        loopStart: markers.loopStartFrame,
        loopEnd: markers.loopEndFrame,
      );
      await file.writeAsBytes(updated, flush: true);
      final refreshed = WavMetadataReader.parse(updated);
      setState(() {
        _waveformCache[region.path] = refreshed ?? overview;
        _loopDrafts[region.path] = markers;
        _savedLoopDrafts[region.path] = markers;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved loop points to WAV metadata.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Loop save failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _savingLoop = false);
      }
    }
  }

  Future<Uint8List?> _readSampleBytes(PolySampleRegion region) async {
    if (region.path.startsWith('/')) {
      final manager = context.read<DistingCubit>().disting();
      return manager?.requestFileDownload(region.path);
    }
    return File(region.path).readAsBytes();
  }

  Future<void> _toggleSamplePlayback(PolySampleRegion region) async {
    if (_isNtSdPath(region.path)) return;
    if (_playingPath == region.path && _playerPlaying) {
      await _samplePlayer.stop();
      return;
    }
    final overview = await _loadWaveformFor(region);
    if (overview == null) return;
    final markers =
        _loopDrafts[region.path] ?? _LoopMarkerDraft.fromWaveform(overview);
    final position = _loopPreviewEnabled
        ? _frameDuration(markers.loopStartFrame, overview.sampleRate)
        : Duration.zero;
    await _samplePlayer.stop();
    await _samplePlayer.play(DeviceFileSource(region.path), position: position);
    if (!mounted) return;
    setState(() => _playingPath = region.path);
  }

  Future<void> _setLoopPreview(bool enabled) async {
    final selected = _selectedRegion;
    setState(() => _loopPreviewEnabled = enabled);
    if (!enabled || selected == null || _playingPath != selected.path) return;
    final overview = await _loadWaveformFor(selected);
    if (overview == null) return;
    final markers =
        _loopDrafts[selected.path] ?? _LoopMarkerDraft.fromWaveform(overview);
    await _samplePlayer.seek(
      _frameDuration(markers.loopStartFrame, overview.sampleRate),
    );
  }

  Future<void> _handlePlayerPosition(Duration position) async {
    if (!_loopPreviewEnabled || _seekingLoop) return;
    final path = _playingPath;
    if (path == null) return;
    PolySampleRegion? region;
    for (final candidate in _regions) {
      if (candidate.path == path) {
        region = candidate;
        break;
      }
    }
    if (region == null) return;
    final overview = await _loadWaveformFor(region);
    if (overview == null) return;
    final markers =
        _loopDrafts[path] ?? _LoopMarkerDraft.fromWaveform(overview);
    final loopEnd = _frameDuration(markers.loopEndFrame, overview.sampleRate);
    if (position < loopEnd) return;
    _seekingLoop = true;
    try {
      await _samplePlayer.seek(
        _frameDuration(markers.loopStartFrame, overview.sampleRate),
      );
    } finally {
      _seekingLoop = false;
    }
  }

  void _updateRootFor(PolySampleRegion region, int value) {
    final updated = _updateRoot(region, value);
    setState(() {
      final paths = _roundRobinSiblings(
        region,
        _regions,
      ).map((candidate) => candidate.path).toSet();
      for (var index = 0; index < _regions.length; index++) {
        if (!paths.contains(_regions[index].path)) continue;
        _regions[index] = _regions[index].copyWith(
          rootMidi: updated.rootMidi,
          rootName: updated.rootName,
        );
      }
      _selectedPath = region.path;
    });
    final selected = _selectedRegion;
    if (selected != null) {
      widget.onSelectRegion(selected);
    }
  }

  void _updateVelocityFor(PolySampleRegion region, int value) {
    setState(() {
      final paths = _roundRobinSiblings(
        region,
        _regions,
      ).map((candidate) => candidate.path).toSet();
      for (var index = 0; index < _regions.length; index++) {
        if (!paths.contains(_regions[index].path)) continue;
        _regions[index] = _regions[index].copyWith(velocityLayer: value);
      }
      _ensureMapLanes();
      _selectedPath = region.path;
    });
    final selected = _selectedRegion;
    if (selected != null) {
      widget.onSelectRegion(selected);
    }
  }

  void _updateRangeLowFor(PolySampleRegion region, int value) {
    setState(() {
      final snapshot = List<PolySampleRegion>.of(_regions);
      final current = _regionInSnapshot(region, snapshot);
      if (current == null) return;
      final currentLow = _effectiveLow(current);
      if (currentLow == null) return;
      final min = _lowMinFor(current, snapshot);
      final max = _lowMaxFor(current, snapshot);
      final nextLow = value.clamp(min, max).toInt();
      final paths = _roundRobinSiblings(
        current,
        snapshot,
      ).map((candidate) => candidate.path).toSet();
      for (var index = 0; index < _regions.length; index++) {
        if (!paths.contains(_regions[index].path)) continue;
        _regions[index] = _regions[index].copyWith(switchPoint: nextLow);
      }
      _selectedPath = region.path;
    });
    final selected = _selectedRegion;
    if (selected != null) {
      widget.onSelectRegion(selected);
    }
  }

  void _updateRangeHighFor(PolySampleRegion region, int value) {
    setState(() {
      final snapshot = List<PolySampleRegion>.of(_regions);
      final current = _regionInSnapshot(region, snapshot);
      if (current == null) return;
      final next = _nextRegionInLane(current, snapshot);
      if (next == null) return;
      final afterNext = _nextRegionInLane(next, snapshot);
      final currentLow = _effectiveLow(current);
      if (currentLow == null) return;
      final maxNextLow = afterNext == null
          ? 127
          : math.max(currentLow + 1, _effectiveLow(afterNext)! - 1);
      final nextLow = (value + 1).clamp(currentLow + 1, maxNextLow).toInt();
      final paths = _roundRobinSiblings(
        next,
        snapshot,
      ).map((candidate) => candidate.path).toSet();
      for (var index = 0; index < _regions.length; index++) {
        if (!paths.contains(_regions[index].path)) continue;
        _regions[index] = _regions[index].copyWith(switchPoint: nextLow);
      }
      _selectedPath = region.path;
    });
    final selected = _selectedRegion;
    if (selected != null) {
      widget.onSelectRegion(selected);
    }
  }

  bool get _hasDraftChanges {
    final original = {
      for (final region in _baselineRegions) region.path: region,
    };
    for (final region in _regions) {
      final before = original[region.path];
      if (before == null) return true;
      if (before.rootMidi != region.rootMidi ||
          before.switchPoint != region.switchPoint ||
          (before.velocityLayer ?? 1) != (region.velocityLayer ?? 1) ||
          (before.roundRobin ?? 1) != (region.roundRobin ?? 1)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _applyDraft() async {
    if (_applying || !_hasDraftChanges) return;
    setState(() => _applying = true);
    try {
      final changes = _buildRenamePlan(_baselineRegions, _regions);
      if (changes.isEmpty) {
        setState(() => _baselineRegions = List<PolySampleRegion>.of(_regions));
        return;
      }

      final hasNtPath = changes.values.any(
        (change) => _isNtSdPath(change.source.path),
      );
      if (hasNtPath) {
        final manager = context.read<DistingCubit>().disting();
        if (manager == null) {
          throw Exception('Connect to Disting NT before applying SD changes.');
        }
        await _applyNtRenames(manager, changes.values.toList());
      } else {
        await _applyLocalRenames(changes.values.toList());
      }

      final updatedRegions = _regions
          .map((region) => changes[region.path]?.updated ?? region)
          .toList();
      final selectedPath = _selectedPath;
      for (final change in changes.values) {
        if (_waveformCache.containsKey(change.source.path)) {
          _waveformCache[change.updated.path] = _waveformCache.remove(
            change.source.path,
          );
        }
        if (_loopDrafts.containsKey(change.source.path)) {
          _loopDrafts[change.updated.path] = _loopDrafts.remove(
            change.source.path,
          )!;
        }
        if (_savedLoopDrafts.containsKey(change.source.path)) {
          _savedLoopDrafts[change.updated.path] = _savedLoopDrafts.remove(
            change.source.path,
          )!;
        }
      }
      setState(() {
        _regions = updatedRegions;
        _baselineRegions = List<PolySampleRegion>.of(updatedRegions);
        _mapLanes = _sortedSampleLanes(_regions);
        _selectedPath = selectedPath == null
            ? null
            : changes[selectedPath]?.updated.path ?? selectedPath;
        _playingPath = _playingPath == null
            ? null
            : changes[_playingPath]?.updated.path ?? _playingPath;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied ${changes.length} sample rename(s).'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Apply failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  void _discardDraft() {
    setState(() {
      _resetDraft();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = _selectedRegion;
    final instrument = widget.instrument.copyWith(regions: _regions);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _StatChip(
                label: 'Files',
                value: instrument.regions.length.toString(),
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Mapped',
                value: instrument.mappedCount.toString(),
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Vel Layers',
                value: instrument.velocityLayers.length.toString(),
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Warnings',
                value: instrument.warningCount.toString(),
                warning: instrument.warningCount > 0,
              ),
              const Spacer(),
              _DraftStatusChip(dirty: _hasDraftChanges),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _hasDraftChanges && !_applying
                    ? _discardDraft
                    : null,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Discard'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _hasDraftChanges && !_applying ? _applyDraft : null,
                icon: const Icon(Icons.save, size: 18),
                label: Text(_applying ? 'Applying...' : 'Apply'),
              ),
              const SizedBox(width: 12),
              Text(
                instrument.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      _KeyMapSection(
                        instrument: instrument,
                        selected: selected,
                        lanes: _mapLanes,
                        minMidi: _mapMinMidi,
                        maxMidi: _mapMaxMidi,
                        onSelectRegion: _selectRegion,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _SampleList(
                          regions: instrument.regions,
                          selected: selected,
                          onSelectRegion: _selectRegion,
                          onChangeRegion: _updateRegion,
                          onChangeRoot: _updateRootFor,
                          onChangeVelocity: _updateVelocityFor,
                          onChangeLow: _updateRangeLowFor,
                          onChangeHigh: _updateRangeHighFor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              VerticalDivider(width: 1, color: colorScheme.outlineVariant),
              SizedBox(
                width: 340,
                child: _SampleInspector(
                  region: selected,
                  regions: instrument.regions,
                  waveform: selected == null || _isNtSdPath(selected.path)
                      ? null
                      : _loadWaveformFor(selected),
                  canPreviewAudio:
                      selected != null && !_isNtSdPath(selected.path),
                  isPreviewPlaying:
                      selected != null &&
                      _playingPath == selected.path &&
                      _playerPlaying,
                  loopPreviewEnabled: _loopPreviewEnabled,
                  waveformMessage:
                      selected != null && _isNtSdPath(selected.path)
                      ? 'Waveform, audio preview, and loop-point editing need a local or mounted SD folder. Direct NT SD files cannot be previewed over MIDI.'
                      : null,
                  loopDraft: selected == null
                      ? null
                      : _loopDrafts[selected.path],
                  loopDirty: _isLoopDirty(selected),
                  savingLoop: _savingLoop,
                  onChangeRegion: _updateSelectedRegion,
                  onChangeRoot: _updateRootFor,
                  onChangeVelocity: _updateVelocityFor,
                  onChangeLow: _updateRangeLowFor,
                  onChangeHigh: _updateRangeHighFor,
                  onChangeLoop: _updateLoopFor,
                  onSaveLoop: selected == null
                      ? null
                      : () => _saveLoopFor(selected),
                  onTogglePreview: _toggleSamplePlayback,
                  onToggleLoopPreview: _setLoopPreview,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

bool _isNtSdPath(String path) => path.startsWith('/');

Duration _frameDuration(int frame, int sampleRate) {
  if (sampleRate <= 0) return Duration.zero;
  return Duration(microseconds: ((frame / sampleRate) * 1000000).round());
}

class _RenameChange {
  const _RenameChange({
    required this.source,
    required this.updated,
    required this.temporaryPath,
  });

  final PolySampleRegion source;
  final PolySampleRegion updated;
  final String temporaryPath;
}

Map<String, _RenameChange> _buildRenamePlan(
  List<PolySampleRegion> baseline,
  List<PolySampleRegion> edited,
) {
  final baselineByPath = {for (final region in baseline) region.path: region};
  final reservedNames = <String, int>{};
  final changes = <String, _RenameChange>{};
  final stamp = DateTime.now().microsecondsSinceEpoch;

  for (var index = 0; index < edited.length; index++) {
    final region = edited[index];
    final source = baselineByPath[region.path];
    if (source == null) continue;
    final isNt = _isNtSdPath(source.path);
    final targetName = _targetSampleFileName(region, edited, reservedNames);
    final targetPath = _replaceBasename(source.path, targetName, isNt: isNt);
    if (targetPath == source.path) continue;
    final temporaryPath = _replaceBasename(
      source.path,
      '.nthelper-$stamp-$index-${source.fileName}',
      isNt: isNt,
    );
    changes[source.path] = _RenameChange(
      source: source,
      updated: region.copyWith(
        path: targetPath,
        fileName: targetName,
        displayName: _replaceDisplayBasename(region.displayName, targetName),
      ),
      temporaryPath: temporaryPath,
    );
  }

  return changes;
}

Future<void> _applyLocalRenames(List<_RenameChange> changes) async {
  final sources = changes.map((change) => change.source.path).toSet();
  for (final change in changes) {
    if (!sources.contains(change.updated.path) &&
        await File(change.updated.path).exists()) {
      throw Exception('Target already exists: ${change.updated.path}');
    }
  }
  for (final change in changes) {
    await File(change.source.path).rename(change.temporaryPath);
  }
  for (final change in changes) {
    await File(change.temporaryPath).rename(change.updated.path);
  }
}

Future<void> _applyNtRenames(
  IDistingMidiManager manager,
  List<_RenameChange> changes,
) async {
  for (final change in changes) {
    final result = await manager.requestFileRename(
      change.source.path,
      change.temporaryPath,
    );
    if (result != null && !result.success) {
      throw Exception(result.message);
    }
  }
  for (final change in changes) {
    final result = await manager.requestFileRename(
      change.temporaryPath,
      change.updated.path,
    );
    if (result != null && !result.success) {
      throw Exception(result.message);
    }
  }
}

String _targetSampleFileName(
  PolySampleRegion region,
  List<PolySampleRegion> regions,
  Map<String, int> reservedNames,
) {
  final extension = p.extension(region.fileName);
  final prefix = _sampleNamePrefix(region.fileName);
  final rootName =
      region.rootName ??
      (region.rootMidi == null
          ? null
          : PolyMultisampleParser.midiToNoteName(region.rootMidi!));
  if (rootName == null) return region.fileName;

  final parts = <String>[if (prefix.isNotEmpty) prefix, rootName];
  final low = _effectiveLow(region);
  if (low != null && low != region.rootMidi) {
    parts.add('SW$low');
  }
  if (_shouldWriteVelocity(region, regions)) {
    parts.add('V${region.velocityLayer ?? 1}');
  }
  if (_shouldWriteRoundRobin(region, regions)) {
    parts.add('RR${region.roundRobin ?? 1}');
  }

  final stem = parts.join('_');
  final count = (reservedNames[stem] ?? 0) + 1;
  reservedNames[stem] = count;
  return count == 1 ? '$stem$extension' : '${stem}__dup$count$extension';
}

String _sampleNamePrefix(String fileName) {
  final stem = p.basenameWithoutExtension(fileName);
  final parts = stem.split('_');
  var noteIndex = -1;
  for (var i = 0; i < parts.length; i++) {
    if (_isNoteTag(parts[i])) noteIndex = i;
  }
  if (noteIndex <= 0) return noteIndex == 0 ? '' : stem;
  return parts.take(noteIndex).join('_');
}

bool _isNoteTag(String value) {
  return RegExp(r'^[A-Ga-g](?:#|b)?-?\d+$').hasMatch(value);
}

bool _hasVelocityTag(String fileName) {
  return RegExp(
    r'(?:^|_)V\d+(?=$|_)',
  ).hasMatch(p.basenameWithoutExtension(fileName).toUpperCase());
}

bool _hasRoundRobinTag(String fileName) {
  return RegExp(
    r'(?:^|_)RR\d+(?=$|_)',
  ).hasMatch(p.basenameWithoutExtension(fileName).toUpperCase());
}

bool _shouldWriteVelocity(
  PolySampleRegion region,
  List<PolySampleRegion> regions,
) {
  return _hasVelocityTag(region.fileName) ||
      _sortedSampleLanes(regions).length > 1;
}

bool _shouldWriteRoundRobin(
  PolySampleRegion region,
  List<PolySampleRegion> regions,
) {
  if (_hasRoundRobinTag(region.fileName)) return true;
  final low = _effectiveLow(region);
  if (low == null) return false;
  final siblings = regions.where((candidate) {
    return candidate.path != region.path &&
        (candidate.velocityLayer ?? 1) == (region.velocityLayer ?? 1) &&
        candidate.rootMidi == region.rootMidi &&
        _effectiveLow(candidate) == low;
  });
  return siblings.isNotEmpty || (region.roundRobin ?? 1) != 1;
}

String _replaceBasename(String path, String fileName, {required bool isNt}) {
  if (isNt) {
    final dir = p.posix.dirname(path);
    return dir == '.' ? fileName : p.posix.join(dir, fileName);
  }
  return p.join(p.dirname(path), fileName);
}

String _replaceDisplayBasename(String displayName, String fileName) {
  final normalized = displayName.replaceAll('\\', '/');
  final dir = p.posix.dirname(normalized);
  return dir == '.' ? fileName : p.posix.join(dir, fileName);
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.warning = false,
  });

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = warning
        ? colorScheme.onTertiaryContainer
        : colorScheme.onSecondaryContainer;
    final background = warning
        ? colorScheme.tertiaryContainer
        : colorScheme.secondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DraftStatusChip extends StatelessWidget {
  const _DraftStatusChip({required this.dirty});

  final bool dirty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dirty
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.55)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        dirty ? 'Unsaved draft' : 'Draft only',
        style: TextStyle(
          color: dirty
              ? colorScheme.onTertiaryContainer
              : colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _KeyMapSection extends StatefulWidget {
  const _KeyMapSection({
    required this.instrument,
    required this.selected,
    required this.lanes,
    required this.minMidi,
    required this.maxMidi,
    required this.onSelectRegion,
  });

  final PolySampleInstrument instrument;
  final PolySampleRegion? selected;
  final List<_SampleLane> lanes;
  final int minMidi;
  final int maxMidi;
  final ValueChanged<PolySampleRegion> onSelectRegion;

  @override
  State<_KeyMapSection> createState() => _KeyMapSectionState();
}

class _KeyMapSectionState extends State<_KeyMapSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollHorizontally(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scrollController.hasClients) {
      return;
    }
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    final next = (_scrollController.offset + delta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final range = _rangeLabel(widget.instrument.regions);
    return SizedBox(
      height: 300,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  Text('Key Map', style: theme.textTheme.titleSmall),
                  const SizedBox(width: 12),
                  Text(
                    'read-only overview',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    range,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final keyCount = widget.maxMidi - widget.minMidi;
                  final canvasWidth = math.max(
                    constraints.maxWidth,
                    keyCount * 24.0 + 80,
                  );
                  return Listener(
                    onPointerSignal: _scrollHorizontally,
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: canvasWidth,
                          height: constraints.maxHeight,
                          child: CustomPaint(
                            painter: _KeyboardMapPainter(
                              regions: widget.instrument.regions,
                              selected: widget.selected,
                              lanes: widget.lanes,
                              minMidi: widget.minMidi,
                              maxMidi: widget.maxMidi,
                              colorScheme: colorScheme,
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (details) {
                                final region = _regionAtPosition(
                                  details.localPosition,
                                  Size(canvasWidth, constraints.maxHeight),
                                );
                                if (region != null) {
                                  widget.onSelectRegion(region);
                                }
                              },
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rangeLabel(List<PolySampleRegion> regions) {
    final extents = _midiExtentsForRegions(regions);
    if (extents.isEmpty) return 'No mapped notes';
    extents.sort();
    return '${PolyMultisampleParser.midiToNoteName(extents.first)} - '
        '${PolyMultisampleParser.midiToNoteName(extents.last)}';
  }

  PolySampleRegion? _regionAtPosition(Offset position, Size size) {
    final layout = _MapLayout.fromRegions(
      widget.instrument.regions,
      widget.lanes,
      size,
      minMidi: widget.minMidi,
      maxMidi: widget.maxMidi,
    );
    if (position.dx < layout.left ||
        position.dx > layout.right ||
        position.dy < layout.zoneTop ||
        position.dy > layout.zoneBottom) {
      return null;
    }

    final zones = _mapZonesFor(widget.instrument.regions);
    for (final zone in zones.reversed) {
      final layerIndex = layout.sortedLanes.indexOf(zone.lane);
      final lane = layerIndex < 0 ? 0 : layerIndex;
      final range = zone.range;
      final x0 =
          layout.left +
          ((range.start - layout.minMidi) / layout.midiSpan) * layout.width;
      final x1 =
          layout.left +
          ((range.end + 1 - layout.minMidi) / layout.midiSpan) * layout.width;
      final y0 = layout.zoneTop + lane * layout.laneHeight;
      final y1 = y0 + layout.laneHeight;
      final rect = Rect.fromLTRB(x0, y0, x1, y1);
      if (rect.contains(position)) {
        return zone.pick(widget.selected);
      }
    }
    return null;
  }
}

class _MapLayout {
  _MapLayout({
    required this.minMidi,
    required this.maxMidi,
    required this.left,
    required this.right,
    required this.width,
    required this.zoneTop,
    required this.zoneBottom,
    required this.laneHeight,
    required this.sortedLanes,
    required this.keyboardTop,
    required this.keyboardBottom,
  });

  final int minMidi;
  final int maxMidi;
  final double left;
  final double right;
  final double width;
  final double zoneTop;
  final double zoneBottom;
  final double laneHeight;
  final List<_SampleLane> sortedLanes;
  final double keyboardTop;
  final double keyboardBottom;

  int get midiSpan => maxMidi - minMidi;

  static _MapLayout fromRegions(
    List<PolySampleRegion> regions,
    List<_SampleLane> lanes,
    Size size, {
    required int minMidi,
    required int maxMidi,
  }) {
    final sortedLanes = lanes.isEmpty ? _sortedSampleLanes(regions) : lanes;

    final left = sortedLanes.length > 1 ? 58.0 : 18.0;
    final right = size.width - 18.0;
    final width = math.max(1.0, right - left);
    const labelHeight = 26.0;
    const keyboardHeight = 36.0;
    const bottomPadding = 8.0;
    final zoneTop = labelHeight;
    final zoneBottom = size.height - keyboardHeight - bottomPadding;
    final zoneHeight = math.max(22.0, zoneBottom - zoneTop);
    final laneHeight = zoneHeight / sortedLanes.length;
    return _MapLayout(
      minMidi: minMidi,
      maxMidi: maxMidi,
      left: left,
      right: right,
      width: width,
      zoneTop: zoneTop,
      zoneBottom: zoneBottom,
      laneHeight: laneHeight,
      sortedLanes: sortedLanes,
      keyboardTop: zoneBottom,
      keyboardBottom: size.height - bottomPadding,
    );
  }
}

class _SampleLane implements Comparable<_SampleLane> {
  const _SampleLane(this.velocity);

  final int velocity;

  String get label => 'V$velocity';

  @override
  int compareTo(_SampleLane other) {
    return velocity.compareTo(other.velocity);
  }

  @override
  bool operator ==(Object other) {
    return other is _SampleLane && velocity == other.velocity;
  }

  @override
  int get hashCode => velocity.hashCode;
}

_SampleLane _laneFor(PolySampleRegion region) {
  return _SampleLane(region.velocityLayer ?? 1);
}

List<_SampleLane> _sortedSampleLanes(List<PolySampleRegion> regions) {
  final lanes =
      regions
          .where((region) => region.rootMidi != null)
          .map(_laneFor)
          .toSet()
          .toList()
        ..sort();
  if (lanes.isEmpty) {
    lanes.add(const _SampleLane(1));
  }
  return lanes;
}

class _RangeBounds {
  const _RangeBounds({required this.start, required this.end});

  final int start;
  final int end;

  String get label =>
      '${PolyMultisampleParser.midiToNoteName(start)} - '
      '${PolyMultisampleParser.midiToNoteName(end)}';
}

class _MapZone {
  const _MapZone({
    required this.lane,
    required this.range,
    required this.rootMidi,
    required this.regions,
  });

  final _SampleLane lane;
  final _RangeBounds range;
  final int rootMidi;
  final List<PolySampleRegion> regions;

  bool contains(PolySampleRegion? region) {
    if (region == null) return false;
    return regions.any((candidate) => candidate.path == region.path);
  }

  PolySampleRegion pick(PolySampleRegion? selected) {
    if (contains(selected)) return selected!;
    return regions.first;
  }

  String get label {
    final first = regions.first;
    final root =
        first.rootName ?? PolyMultisampleParser.midiToNoteName(rootMidi);
    final velocity = 'V${first.velocityLayer ?? 1}';
    final rrs = regions.map((region) => region.roundRobin ?? 1).toSet().toList()
      ..sort();
    if (rrs.length <= 1) return '$root $velocity';
    return '$root $velocity RR${rrs.first}-${rrs.last}';
  }

  String get compactLabel {
    final first = regions.first;
    final root =
        first.rootName ?? PolyMultisampleParser.midiToNoteName(rootMidi);
    final rrs = regions.map((region) => region.roundRobin ?? 1).toSet().toList()
      ..sort();
    if (rrs.length <= 1) return root;
    return 'R${rrs.first}-${rrs.last}';
  }
}

List<_MapZone> _mapZonesFor(List<PolySampleRegion> regions) {
  final groups = <String, List<PolySampleRegion>>{};
  for (final region in regions.where((region) => region.rootMidi != null)) {
    final low = _effectiveLow(region);
    if (low == null) continue;
    final key = '${region.velocityLayer ?? 1}|$low|${region.rootMidi}';
    groups.putIfAbsent(key, () => <PolySampleRegion>[]).add(region);
  }

  final zones = <_MapZone>[];
  for (final group in groups.values) {
    group.sort((a, b) {
      final rrCompare = (a.roundRobin ?? 1).compareTo(b.roundRobin ?? 1);
      if (rrCompare != 0) return rrCompare;
      return a.displayName.compareTo(b.displayName);
    });
    final first = group.first;
    final range = _rangeBoundsForRegion(first, regions);
    if (range == null) continue;
    zones.add(
      _MapZone(
        lane: _laneFor(first),
        range: range,
        rootMidi: first.rootMidi!,
        regions: group,
      ),
    );
  }
  zones.sort((a, b) {
    final laneCompare = a.lane.compareTo(b.lane);
    if (laneCompare != 0) return laneCompare;
    final lowCompare = a.range.start.compareTo(b.range.start);
    if (lowCompare != 0) return lowCompare;
    return a.rootMidi.compareTo(b.rootMidi);
  });
  return zones;
}

List<PolySampleRegion> _withExplicitSwitchPoints(
  List<PolySampleRegion> regions,
) {
  final output = List<PolySampleRegion>.of(regions);
  for (var i = 0; i < output.length; i++) {
    final region = output[i];
    final root = region.rootMidi;
    if (root == null) continue;
    output[i] = region.copyWith(switchPoint: (region.switchPoint ?? root));
  }
  return output;
}

int? _effectiveLow(PolySampleRegion region) {
  final root = region.rootMidi;
  if (root == null) return null;
  return (region.switchPoint ?? root).clamp(0, 127).toInt();
}

bool _sameBoundaryGroup(PolySampleRegion a, PolySampleRegion b) {
  return a.rootMidi != null &&
      b.rootMidi != null &&
      a.rootMidi == b.rootMidi &&
      _effectiveLow(a) == _effectiveLow(b);
}

List<PolySampleRegion> _keyBoundaryRegions(List<PolySampleRegion> regions) {
  final boundaries = regions
      .where((candidate) => candidate.rootMidi != null)
      .toList();
  boundaries.sort((a, b) {
    final lowCompare = _effectiveLow(a)!.compareTo(_effectiveLow(b)!);
    if (lowCompare != 0) return lowCompare;
    final rootCompare = (a.rootMidi ?? 999).compareTo(b.rootMidi ?? 999);
    if (rootCompare != 0) return rootCompare;
    return a.path.compareTo(b.path);
  });
  return boundaries;
}

List<PolySampleRegion> _keyBoundaryRegionsInLane(
  PolySampleRegion region,
  List<PolySampleRegion> regions,
) {
  final velocity = region.velocityLayer ?? 1;
  return _keyBoundaryRegions(
    regions
        .where((candidate) => (candidate.velocityLayer ?? 1) == velocity)
        .toList(),
  );
}

PolySampleRegion? _previousRegionInLane(
  PolySampleRegion region,
  List<PolySampleRegion> regions,
) {
  final boundaries = _keyBoundaryRegionsInLane(region, regions);
  final low = _effectiveLow(region);
  if (low == null) return null;
  PolySampleRegion? previous;
  for (final candidate in boundaries) {
    final candidateLow = _effectiveLow(candidate)!;
    if (candidateLow >= low) break;
    previous = candidate;
  }
  return previous;
}

PolySampleRegion? _nextRegionInLane(
  PolySampleRegion region,
  List<PolySampleRegion> regions,
) {
  final boundaries = _keyBoundaryRegionsInLane(region, regions);
  final low = _effectiveLow(region);
  if (low == null) return null;
  for (final candidate in boundaries) {
    if (_effectiveLow(candidate)! > low) return candidate;
  }
  return null;
}

List<PolySampleRegion> _boundarySiblings(
  PolySampleRegion region,
  List<PolySampleRegion> regions,
) {
  final low = _effectiveLow(region);
  if (low == null) return [region];
  return regions.where((candidate) {
    return _sameBoundaryGroup(region, candidate);
  }).toList();
}

List<PolySampleRegion> _roundRobinSiblings(
  PolySampleRegion region,
  List<PolySampleRegion> regions,
) {
  return _boundarySiblings(region, regions).where((candidate) {
    return (candidate.velocityLayer ?? 1) == (region.velocityLayer ?? 1);
  }).toList();
}

PolySampleRegion? _regionInSnapshot(
  PolySampleRegion region,
  List<PolySampleRegion> regions,
) {
  for (final candidate in regions) {
    if (candidate.path == region.path) return candidate;
  }
  return null;
}

int _lowMinFor(PolySampleRegion region, List<PolySampleRegion> regions) {
  final previous = _previousRegionInLane(region, regions);
  if (previous == null) return 0;
  return math.min(127, _effectiveLow(previous)! + 1);
}

int _lowMaxFor(PolySampleRegion region, List<PolySampleRegion> regions) {
  final min = _lowMinFor(region, regions);
  final next = _nextRegionInLane(region, regions);
  if (next == null) return 127;
  return math.max(min, _effectiveLow(next)! - 1);
}

int _highFor(PolySampleRegion region, List<PolySampleRegion> regions) {
  final next = _nextRegionInLane(region, regions);
  if (next == null) return 127;
  return math.max(_effectiveLow(region)!, _effectiveLow(next)! - 1);
}

int _highMaxFor(PolySampleRegion region, List<PolySampleRegion> regions) {
  final min = _highMinFor(region);
  final next = _nextRegionInLane(region, regions);
  if (next == null) return 127;
  final afterNext = _nextRegionInLane(next, regions);
  if (afterNext == null) return math.max(min, 126);
  return math.max(min, _effectiveLow(afterNext)! - 2);
}

int _highMinFor(PolySampleRegion region) {
  return _effectiveLow(region) ?? 0;
}

List<int> _midiExtentsForRegions(List<PolySampleRegion> regions) {
  final extents = <int>[];
  for (final region in regions) {
    if (_effectiveLow(region) case final low?) {
      extents.add(low);
      extents.add(_highFor(region, regions));
    }
  }
  return extents;
}

int _initialMapMinMidi(List<PolySampleRegion> regions) {
  final extents = _midiExtentsForRegions(regions);
  if (extents.isEmpty) return 24;
  extents.sort();
  return (((extents.first / 12).floor() * 12) - 12).clamp(0, 120).toInt();
}

int _initialMapMaxMidi(List<PolySampleRegion> regions, int minMidi) {
  final extents = _midiExtentsForRegions(regions);
  if (extents.isEmpty) return 96;
  extents.sort();
  return (((extents.last / 12).ceil() * 12) + 12)
      .clamp(minMidi + 12, 127)
      .toInt();
}

PolySampleRegion _updateRoot(PolySampleRegion region, int midi) {
  final root = midi.clamp(0, 127).toInt();
  return region.copyWith(
    rootMidi: root,
    rootName: PolyMultisampleParser.midiToNoteName(root),
  );
}

_RangeBounds? _rangeBoundsForRegion(
  PolySampleRegion region,
  List<PolySampleRegion> regions,
) {
  final index = regions.indexWhere(
    (candidate) => candidate.path == region.path,
  );
  return _rangeBoundsForRegionAtIndex(index, regions);
}

_RangeBounds? _rangeBoundsForRegionAtIndex(
  int index,
  List<PolySampleRegion> regions,
) {
  if (index < 0 || index >= regions.length) return null;
  final region = regions[index];
  if (region.rootMidi == null) return null;
  final start = _effectiveLow(region)!;
  final end = _highFor(region, regions);

  return _RangeBounds(start: start, end: end);
}

class _SampleList extends StatefulWidget {
  const _SampleList({
    required this.regions,
    required this.selected,
    required this.onSelectRegion,
    required this.onChangeRegion,
    required this.onChangeRoot,
    required this.onChangeVelocity,
    required this.onChangeLow,
    required this.onChangeHigh,
  });

  final List<PolySampleRegion> regions;
  final PolySampleRegion? selected;
  final ValueChanged<PolySampleRegion> onSelectRegion;
  final ValueChanged<PolySampleRegion> onChangeRegion;
  final void Function(PolySampleRegion region, int value) onChangeRoot;
  final void Function(PolySampleRegion region, int value) onChangeVelocity;
  final void Function(PolySampleRegion region, int value) onChangeLow;
  final void Function(PolySampleRegion region, int value) onChangeHigh;

  @override
  State<_SampleList> createState() => _SampleListState();
}

const double _sampleListRowHeight = 52;
const double _sampleListSeparatorHeight = 1;

class _SampleListState extends State<_SampleList> {
  final ScrollController _scrollController = ScrollController();
  String? _lastSelectedPath;

  @override
  void didUpdateWidget(covariant _SampleList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedPath = widget.selected?.path;
    if (selectedPath != null && selectedPath != _lastSelectedPath) {
      _lastSelectedPath = selectedPath;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final index = widget.regions.indexWhere(
          (region) => region.path == selectedPath,
        );
        if (index < 0) return;
        final rowTop =
            index * (_sampleListRowHeight + _sampleListSeparatorHeight);
        final centered =
            rowTop -
            ((_scrollController.position.viewportDimension -
                    _sampleListRowHeight) /
                2);
        final target = centered.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Text('Samples', style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${widget.regions.length} files',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              itemCount: widget.regions.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colorScheme.outlineVariant),
              itemBuilder: (context, index) {
                final region = widget.regions[index];
                return SizedBox(
                  height: _sampleListRowHeight,
                  child: _SampleListRow(
                    region: region,
                    regions: widget.regions,
                    selected: region.path == widget.selected?.path,
                    onTap: () => widget.onSelectRegion(region),
                    onChangeRegion: widget.onChangeRegion,
                    onChangeRoot: widget.onChangeRoot,
                    onChangeVelocity: widget.onChangeVelocity,
                    onChangeLow: widget.onChangeLow,
                    onChangeHigh: widget.onChangeHigh,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleListRow extends StatelessWidget {
  const _SampleListRow({
    required this.region,
    required this.regions,
    required this.selected,
    required this.onTap,
    required this.onChangeRegion,
    required this.onChangeRoot,
    required this.onChangeVelocity,
    required this.onChangeLow,
    required this.onChangeHigh,
  });

  final PolySampleRegion region;
  final List<PolySampleRegion> regions;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<PolySampleRegion> onChangeRegion;
  final void Function(PolySampleRegion region, int value) onChangeRoot;
  final void Function(PolySampleRegion region, int value) onChangeVelocity;
  final void Function(PolySampleRegion region, int value) onChangeLow;
  final void Function(PolySampleRegion region, int value) onChangeHigh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final range = _rangeBoundsForRegion(region, regions);
    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.16)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.audio_file,
                size: 20,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  region.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _SampleNoteStepper(
                label: 'Root',
                value: region.rootMidi,
                onChanged: (value) => onChangeRoot(region, value),
              ),
              const SizedBox(width: 6),
              if (range != null) ...[
                _SampleNoteStepper(
                  label: 'Low',
                  value: range.start,
                  min: _lowMinFor(region, regions),
                  max: _lowMaxFor(region, regions),
                  onChanged: (value) => onChangeLow(region, value),
                ),
                const SizedBox(width: 6),
                _SampleNoteStepper(
                  label: 'High',
                  value: range.end,
                  min: _highMinFor(region),
                  max: _highMaxFor(region, regions),
                  onChanged: _nextRegionInLane(region, regions) == null
                      ? null
                      : (value) => onChangeHigh(region, value),
                ),
                const SizedBox(width: 6),
              ],
              _SampleNumberStepper(
                label: 'Vel',
                value: region.velocityLayer ?? 1,
                min: 1,
                max: 16,
                onChanged: (value) => onChangeVelocity(region, value),
              ),
              const SizedBox(width: 6),
              _SampleNumberStepper(
                label: 'RR',
                value: region.roundRobin ?? 1,
                min: 1,
                max: 32,
                onChanged: (value) =>
                    onChangeRegion(region.copyWith(roundRobin: value)),
              ),
              const SizedBox(width: 10),
              _IssueLabel(region: region),
            ],
          ),
        ),
      ),
    );
  }
}

class _SampleNoteStepper extends StatelessWidget {
  const _SampleNoteStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 127,
  });

  final String label;
  final int? value;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final current = value ?? 60;
    return _SampleEditStepper(
      label: label,
      value: value == null
          ? '-'
          : PolyMultisampleParser.midiToNoteName(current),
      onDecrement: onChanged == null || current <= min
          ? null
          : () => onChanged!(current - 1),
      onIncrement: onChanged == null || current >= max
          ? null
          : () => onChanged!(current + 1),
    );
  }
}

class _SampleNumberStepper extends StatelessWidget {
  const _SampleNumberStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SampleEditStepper(
      label: label,
      value: value.toString(),
      onDecrement: value <= min ? null : () => onChanged(value - 1),
      onIncrement: value >= max ? null : () => onChanged(value + 1),
    );
  }
}

class _SampleEditStepper extends StatelessWidget {
  const _SampleEditStepper({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 32,
      constraints: const BoxConstraints(minWidth: 104),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease $label',
            onPressed: onDecrement,
            icon: const Icon(Icons.remove),
            iconSize: 14,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 32),
          ),
          Expanded(
            child: Text(
              '$label $value',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Increase $label',
            onPressed: onIncrement,
            icon: const Icon(Icons.add),
            iconSize: 14,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 32),
          ),
        ],
      ),
    );
  }
}

class _IssueLabel extends StatelessWidget {
  const _IssueLabel({required this.region});

  final PolySampleRegion region;

  @override
  Widget build(BuildContext context) {
    if (region.issues.isEmpty) {
      return const Text('OK');
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      region.issues.map(_issueText).join(', '),
      style: TextStyle(color: colorScheme.tertiary),
    );
  }

  String _issueText(PolySampleIssue issue) {
    return switch (issue) {
      PolySampleIssue.missingRootNote => 'No root',
      PolySampleIssue.unsupportedFileType => 'Unsupported',
    };
  }
}

class _SampleInspector extends StatelessWidget {
  const _SampleInspector({
    required this.region,
    required this.regions,
    required this.waveform,
    required this.canPreviewAudio,
    required this.isPreviewPlaying,
    required this.loopPreviewEnabled,
    required this.waveformMessage,
    required this.loopDraft,
    required this.loopDirty,
    required this.savingLoop,
    required this.onChangeRegion,
    required this.onChangeRoot,
    required this.onChangeVelocity,
    required this.onChangeLow,
    required this.onChangeHigh,
    required this.onChangeLoop,
    required this.onSaveLoop,
    required this.onTogglePreview,
    required this.onToggleLoopPreview,
  });

  final PolySampleRegion? region;
  final List<PolySampleRegion> regions;
  final Future<WavOverview?>? waveform;
  final bool canPreviewAudio;
  final bool isPreviewPlaying;
  final bool loopPreviewEnabled;
  final String? waveformMessage;
  final _LoopMarkerDraft? loopDraft;
  final bool loopDirty;
  final bool savingLoop;
  final ValueChanged<PolySampleRegion> onChangeRegion;
  final void Function(PolySampleRegion region, int value) onChangeRoot;
  final void Function(PolySampleRegion region, int value) onChangeVelocity;
  final void Function(PolySampleRegion region, int value) onChangeLow;
  final void Function(PolySampleRegion region, int value) onChangeHigh;
  final void Function(PolySampleRegion region, _LoopMarkerDraft markers)
  onChangeLoop;
  final Future<void> Function()? onSaveLoop;
  final Future<void> Function(PolySampleRegion region) onTogglePreview;
  final Future<void> Function(bool enabled) onToggleLoopPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final r = region;
    if (r == null) {
      return const Center(child: Text('No sample selected'));
    }
    final range = _rangeBoundsForRegion(r, regions);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sample', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            r.fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _NoteStepper(
            label: 'Root',
            value: r.rootMidi,
            onChanged: (value) => onChangeRoot(r, value),
          ),
          if (range != null) ...[
            _NoteStepper(
              label: 'Low',
              value: range.start,
              min: _lowMinFor(r, regions),
              max: _lowMaxFor(r, regions),
              onChanged: (value) => onChangeLow(r, value),
            ),
            _NoteStepper(
              label: 'High',
              value: range.end,
              min: _highMinFor(r),
              max: _highMaxFor(r, regions),
              onChanged: _nextRegionInLane(r, regions) == null
                  ? null
                  : (value) => onChangeHigh(r, value),
            ),
            const SizedBox(height: 8),
          ],
          _NumberStepper(
            label: 'Velocity',
            value: r.velocityLayer ?? 1,
            min: 1,
            max: 16,
            onChanged: (value) => onChangeVelocity(r, value),
          ),
          _NumberStepper(
            label: 'Round robin',
            value: r.roundRobin ?? 1,
            min: 1,
            max: 32,
            onChanged: (value) => onChangeRegion(r.copyWith(roundRobin: value)),
          ),
          const SizedBox(height: 24),
          _WaveformSection(
            waveform: waveform,
            canPreviewAudio: canPreviewAudio,
            isPreviewPlaying: isPreviewPlaying,
            loopPreviewEnabled: loopPreviewEnabled,
            unavailableMessage: waveformMessage,
            loopDraft: loopDraft,
            loopDirty: loopDirty,
            savingLoop: savingLoop,
            onChanged: (markers) => onChangeLoop(r, markers),
            onSaveLoop: onSaveLoop,
            onTogglePreview: () => onTogglePreview(r),
            onToggleLoopPreview: onToggleLoopPreview,
          ),
          const Spacer(),
          Text(
            r.path,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteStepper extends StatelessWidget {
  const _NoteStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 127,
  });

  final String label;
  final int? value;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final current = value ?? 60;
    return _InspectorStepperShell(
      label: label,
      value: value == null
          ? '-'
          : PolyMultisampleParser.midiToNoteName(current),
      onDecrement: onChanged == null || current <= min
          ? null
          : () => onChanged!(current - 1),
      onIncrement: onChanged == null || current >= max
          ? null
          : () => onChanged!(current + 1),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value ?? min;
    return _InspectorStepperShell(
      label: label,
      value: value?.toString() ?? min.toString(),
      onDecrement: current <= min ? null : () => onChanged(current - 1),
      onIncrement: current >= max ? null : () => onChanged(current + 1),
    );
  }
}

class _LoopMarkerDraft {
  const _LoopMarkerDraft({
    required this.loopStartFrame,
    required this.loopEndFrame,
  });

  final int loopStartFrame;
  final int loopEndFrame;

  factory _LoopMarkerDraft.fromWaveform(WavOverview waveform) {
    return _LoopMarkerDraft(
      loopStartFrame: waveform.loopStart ?? 0,
      loopEndFrame: waveform.loopEnd ?? math.max(0, waveform.frameCount - 1),
    ).clamped(waveform.frameCount);
  }

  _LoopMarkerDraft clamped(int frameCount) {
    final maxFrame = math.max(0, frameCount - 1);
    final loopStart = loopStartFrame.clamp(0, maxFrame).toInt();
    final loopEnd = loopEndFrame.clamp(loopStart, maxFrame).toInt();
    return _LoopMarkerDraft(loopStartFrame: loopStart, loopEndFrame: loopEnd);
  }

  _LoopMarkerDraft copyWith({
    int? loopStartFrame,
    int? loopEndFrame,
    required int frameCount,
  }) {
    return _LoopMarkerDraft(
      loopStartFrame: loopStartFrame ?? this.loopStartFrame,
      loopEndFrame: loopEndFrame ?? this.loopEndFrame,
    ).clamped(frameCount);
  }

  _LoopMarkerDraft snappedToZeroCrossings(WavOverview waveform) {
    final radius = math.max(32, waveform.sampleRate ~/ 100);
    return _LoopMarkerDraft(
      loopStartFrame: waveform.nearestZeroCrossing(
        loopStartFrame,
        searchRadius: radius,
      ),
      loopEndFrame: waveform.nearestZeroCrossing(
        loopEndFrame,
        searchRadius: radius,
      ),
    ).clamped(waveform.frameCount);
  }

  @override
  bool operator ==(Object other) {
    return other is _LoopMarkerDraft &&
        other.loopStartFrame == loopStartFrame &&
        other.loopEndFrame == loopEndFrame;
  }

  @override
  int get hashCode => Object.hash(loopStartFrame, loopEndFrame);
}

class _WaveformSection extends StatelessWidget {
  const _WaveformSection({
    required this.waveform,
    required this.canPreviewAudio,
    required this.isPreviewPlaying,
    required this.loopPreviewEnabled,
    required this.unavailableMessage,
    required this.loopDraft,
    required this.loopDirty,
    required this.savingLoop,
    required this.onChanged,
    required this.onSaveLoop,
    required this.onTogglePreview,
    required this.onToggleLoopPreview,
  });

  final Future<WavOverview?>? waveform;
  final bool canPreviewAudio;
  final bool isPreviewPlaying;
  final bool loopPreviewEnabled;
  final String? unavailableMessage;
  final _LoopMarkerDraft? loopDraft;
  final bool loopDirty;
  final bool savingLoop;
  final ValueChanged<_LoopMarkerDraft> onChanged;
  final Future<void> Function()? onSaveLoop;
  final Future<void> Function() onTogglePreview;
  final Future<void> Function(bool enabled) onToggleLoopPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final future = waveform;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Waveform', style: theme.textTheme.titleSmall),
            ),
            Tooltip(
              message: loopDirty
                  ? 'Save loop points to WAV metadata'
                  : 'Loop points are unchanged',
              child: OutlinedButton.icon(
                onPressed: loopDirty && !savingLoop ? onSaveLoop : null,
                icon: Icon(
                  savingLoop ? Icons.hourglass_top : Icons.save,
                  size: 16,
                ),
                label: Text(savingLoop ? 'Saving...' : 'Save loop'),
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: canPreviewAudio
                  ? (isPreviewPlaying ? 'Stop sample preview' : 'Play sample')
                  : 'Audio preview needs a local or mounted WAV',
              child: IconButton(
                onPressed: canPreviewAudio ? onTogglePreview : null,
                icon: Icon(isPreviewPlaying ? Icons.stop : Icons.play_arrow),
              ),
            ),
            Tooltip(
              message: canPreviewAudio
                  ? 'Continuously audition current loop markers'
                  : 'Loop preview needs a local or mounted WAV',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Loop',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: canPreviewAudio
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.48,
                            ),
                    ),
                  ),
                  Switch(
                    value: loopPreviewEnabled && canPreviewAudio,
                    onChanged: canPreviewAudio ? onToggleLoopPreview : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.34,
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: future == null
                ? _WaveformMessage(
                    text: unavailableMessage ?? 'No sample selected',
                  )
                : FutureBuilder<WavOverview?>(
                    future: future,
                    builder: (context, snapshot) {
                      final overview = snapshot.data;
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (overview == null) {
                        return const _WaveformMessage(
                          text: 'Waveform unavailable for this sample',
                        );
                      }
                      final markers =
                          loopDraft ?? _LoopMarkerDraft.fromWaveform(overview);
                      return _WaveformEditor(
                        waveform: overview,
                        markers: markers,
                        colorScheme: colorScheme,
                        onChanged: onChanged,
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<WavOverview?>(
          future: future,
          builder: (context, snapshot) {
            final overview = snapshot.data;
            if (overview == null) {
              return const SizedBox.shrink();
            }
            final markers =
                loopDraft ?? _LoopMarkerDraft.fromWaveform(overview);
            final maxFrame = math.max(1, overview.frameCount - 1).toDouble();
            return Column(
              children: [
                RangeSlider(
                  values: RangeValues(
                    markers.loopStartFrame.clamp(0, maxFrame).toDouble(),
                    markers.loopEndFrame.clamp(0, maxFrame).toDouble(),
                  ),
                  min: 0,
                  max: maxFrame,
                  onChanged: (values) => onChanged(
                    _LoopMarkerDraft(
                      loopStartFrame: values.start.round(),
                      loopEndFrame: values.end.round(),
                    ).snappedToZeroCrossings(overview),
                  ),
                ),
                _LoopFineControls(
                  markers: markers,
                  waveform: overview,
                  onChanged: onChanged,
                ),
                const SizedBox(height: 4),
                Text(
                  '${overview.frameCount} frames, '
                  '${overview.durationSeconds.toStringAsFixed(2)}s. '
                  'Drag loop bars or nudge. Save loop writes WAV smpl metadata.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WaveformMessage extends StatelessWidget {
  const _WaveformMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LoopHandle { start, end }

class _WaveformEditor extends StatefulWidget {
  const _WaveformEditor({
    required this.waveform,
    required this.markers,
    required this.colorScheme,
    required this.onChanged,
  });

  final WavOverview waveform;
  final _LoopMarkerDraft markers;
  final ColorScheme colorScheme;
  final ValueChanged<_LoopMarkerDraft> onChanged;

  @override
  State<_WaveformEditor> createState() => _WaveformEditorState();
}

class _WaveformEditorState extends State<_WaveformEditor> {
  _LoopHandle? _activeHandle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final handle = _nearestHandle(details.localPosition.dx, size.width);
            _moveHandle(handle, details.localPosition.dx, size.width);
          },
          onPanStart: (details) {
            _activeHandle = _nearestHandle(
              details.localPosition.dx,
              size.width,
            );
            _moveHandle(_activeHandle!, details.localPosition.dx, size.width);
          },
          onPanUpdate: (details) {
            final handle = _activeHandle;
            if (handle == null) return;
            _moveHandle(handle, details.localPosition.dx, size.width);
          },
          onPanEnd: (_) => _activeHandle = null,
          onPanCancel: () => _activeHandle = null,
          child: CustomPaint(
            painter: _WaveformPainter(
              waveform: widget.waveform,
              markers: widget.markers,
              colorScheme: widget.colorScheme,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  _LoopHandle _nearestHandle(double x, double width) {
    final startX = _frameX(widget.markers.loopStartFrame, width);
    final endX = _frameX(widget.markers.loopEndFrame, width);
    return (x - startX).abs() <= (x - endX).abs()
        ? _LoopHandle.start
        : _LoopHandle.end;
  }

  void _moveHandle(_LoopHandle handle, double x, double width) {
    final frame = _snapFrame(_frameFromX(x, width));
    final next = switch (handle) {
      _LoopHandle.start => widget.markers.copyWith(
        loopStartFrame: math.min(frame, widget.markers.loopEndFrame),
        frameCount: widget.waveform.frameCount,
      ),
      _LoopHandle.end => widget.markers.copyWith(
        loopEndFrame: math.max(frame, widget.markers.loopStartFrame),
        frameCount: widget.waveform.frameCount,
      ),
    };
    widget.onChanged(next);
  }

  int _snapFrame(int frame) {
    final radius = math.max(32, widget.waveform.sampleRate ~/ 100);
    return widget.waveform.nearestZeroCrossing(frame, searchRadius: radius);
  }

  int _frameFromX(double x, double width) {
    final maxFrame = math.max(1, widget.waveform.frameCount - 1);
    final ratio = width <= 0 ? 0.0 : (x / width).clamp(0.0, 1.0);
    return (ratio * maxFrame).round();
  }

  double _frameX(int frame, double width) {
    final maxFrame = math.max(1, widget.waveform.frameCount - 1);
    return (frame.clamp(0, maxFrame) / maxFrame) * width;
  }
}

class _LoopFineControls extends StatelessWidget {
  const _LoopFineControls({
    required this.markers,
    required this.waveform,
    required this.onChanged,
  });

  final _LoopMarkerDraft markers;
  final WavOverview waveform;
  final ValueChanged<_LoopMarkerDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LoopFineRow(
          label: 'Start',
          value: markers.loopStartFrame,
          onNudge: (delta) => _changeStart(delta),
          onSnap: () => _snapStart(),
        ),
        _LoopFineRow(
          label: 'End',
          value: markers.loopEndFrame,
          onNudge: (delta) => _changeEnd(delta),
          onSnap: () => _snapEnd(),
        ),
      ],
    );
  }

  void _changeStart(int delta) {
    onChanged(
      markers.copyWith(
        loopStartFrame: markers.loopStartFrame + delta,
        frameCount: waveform.frameCount,
      ),
    );
  }

  void _changeEnd(int delta) {
    onChanged(
      markers.copyWith(
        loopEndFrame: markers.loopEndFrame + delta,
        frameCount: waveform.frameCount,
      ),
    );
  }

  void _snapStart() {
    onChanged(
      markers.copyWith(
        loopStartFrame: waveform.nearestZeroCrossing(markers.loopStartFrame),
        frameCount: waveform.frameCount,
      ),
    );
  }

  void _snapEnd() {
    onChanged(
      markers.copyWith(
        loopEndFrame: waveform.nearestZeroCrossing(markers.loopEndFrame),
        frameCount: waveform.frameCount,
      ),
    );
  }
}

class _LoopFineRow extends StatelessWidget {
  const _LoopFineRow({
    required this.label,
    required this.value,
    required this.onNudge,
    required this.onSnap,
  });

  final String label;
  final int value;
  final ValueChanged<int> onNudge;
  final VoidCallback onSnap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          _TinyNudgeButton(label: '-100', onPressed: () => onNudge(-100)),
          _TinyNudgeButton(label: '-1', onPressed: () => onNudge(-1)),
          Expanded(
            child: Center(
              child: Text(
                value.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          _TinyNudgeButton(label: '+1', onPressed: () => onNudge(1)),
          _TinyNudgeButton(label: '+100', onPressed: () => onNudge(100)),
          TextButton(onPressed: onSnap, child: const Text('Zero')),
        ],
      ),
    );
  }
}

class _TinyNudgeButton extends StatelessWidget {
  const _TinyNudgeButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 28,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          textStyle: Theme.of(context).textTheme.labelSmall,
        ),
        child: Text(label),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.waveform,
    required this.markers,
    required this.colorScheme,
  });

  final WavOverview waveform;
  final _LoopMarkerDraft markers;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final path = Path();
    final peaks = waveform.peaks;
    if (peaks.isEmpty) return;

    for (var i = 0; i < peaks.length; i++) {
      final x = peaks.length == 1 ? 0.0 : (i / (peaks.length - 1)) * size.width;
      final y = centerY + peaks[i].max * centerY * -0.82;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    for (var i = peaks.length - 1; i >= 0; i--) {
      final x = peaks.length == 1 ? 0.0 : (i / (peaks.length - 1)) * size.width;
      final y = centerY + peaks[i].min * centerY * -0.82;
      path.lineTo(x, y);
    }
    path.close();

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      Paint()
        ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
    canvas.drawPath(
      path,
      Paint()..color = colorScheme.primary.withValues(alpha: 0.56),
    );

    _drawRange(
      canvas,
      size,
      markers.loopStartFrame,
      markers.loopEndFrame,
      colorScheme.secondary.withValues(alpha: 0.14),
    );
    _drawMarker(
      canvas,
      size,
      markers.loopStartFrame,
      colorScheme.secondary,
      'LS',
    );
    _drawMarker(
      canvas,
      size,
      markers.loopEndFrame,
      colorScheme.secondary,
      'LE',
    );
  }

  void _drawRange(Canvas canvas, Size size, int start, int end, Color color) {
    final x0 = _frameX(start, size.width);
    final x1 = _frameX(end, size.width);
    canvas.drawRect(
      Rect.fromLTRB(x0, 0, x1, size.height),
      Paint()..color = color,
    );
  }

  void _drawMarker(
    Canvas canvas,
    Size size,
    int frame,
    Color color,
    String label,
  ) {
    final x = _frameX(frame, size.width);
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = (x + 4).clamp(2.0, size.width - painter.width - 2);
    painter.paint(canvas, Offset(labelX, 4));
  }

  double _frameX(int frame, double width) {
    final maxFrame = math.max(1, waveform.frameCount - 1);
    return (frame.clamp(0, maxFrame) / maxFrame) * width;
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.waveform != waveform ||
        oldDelegate.markers != markers ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _InspectorStepperShell extends StatelessWidget {
  const _InspectorStepperShell({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Decrease $label',
                    onPressed: onDecrement,
                    icon: const Icon(Icons.remove),
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Increase $label',
                    onPressed: onIncrement,
                    icon: const Icon(Icons.add),
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardMapPainter extends CustomPainter {
  _KeyboardMapPainter({
    required this.regions,
    required this.selected,
    required this.lanes,
    required this.minMidi,
    required this.maxMidi,
    required this.colorScheme,
  });

  final List<PolySampleRegion> regions;
  final PolySampleRegion? selected;
  final List<_SampleLane> lanes;
  final int minMidi;
  final int maxMidi;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final sortedLanes = lanes.isEmpty ? _sortedSampleLanes(regions) : lanes;
    final left = sortedLanes.length > 1 ? 58.0 : 18.0;
    final right = size.width - 18.0;
    final width = math.max(1.0, right - left);
    const labelHeight = 26.0;
    const keyboardHeight = 36.0;
    const bottomPadding = 8.0;
    final zoneTop = labelHeight;
    final zoneBottom = size.height - keyboardHeight - bottomPadding;
    final zoneHeight = math.max(22.0, zoneBottom - zoneTop);
    final laneHeight = zoneHeight / sortedLanes.length;
    final keyboardTop = zoneBottom;
    final keyboardBottom = size.height - bottomPadding;
    final whiteKeyRect = Rect.fromLTRB(
      left,
      keyboardTop,
      right,
      keyboardBottom,
    );
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    final softGridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    final keyboardBase = Paint()
      ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.10);

    for (var i = 0; i < sortedLanes.length; i++) {
      final lane = sortedLanes[i];
      final laneTop = zoneTop + i * laneHeight;
      final laneBottom = laneTop + laneHeight;
      if (i.isOdd) {
        canvas.drawRect(
          Rect.fromLTRB(0, laneTop, size.width, laneBottom),
          Paint()
            ..color = colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.12,
            ),
        );
      }
      if (sortedLanes.length > 1) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: lane.label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        labelPainter.paint(
          canvas,
          Offset(10, laneTop + (laneHeight - labelPainter.height) / 2),
        );
      }
      canvas.drawLine(
        Offset(left, laneBottom),
        Offset(right, laneBottom),
        softGridPaint,
      );
    }

    for (var midi = minMidi; midi <= maxMidi; midi += 12) {
      final x = left + ((midi - minMidi) / (maxMidi - minMidi)) * width;
      canvas.drawLine(Offset(x, zoneTop), Offset(x, keyboardBottom), gridPaint);
    }

    final zones = _mapZonesFor(regions);
    for (final zone in zones) {
      final layerIndex = sortedLanes.indexOf(zone.lane);
      final lane = layerIndex < 0 ? 0 : layerIndex;
      final range = zone.range;
      final x0 = left + ((range.start - minMidi) / (maxMidi - minMidi)) * width;
      final x1 =
          left + ((range.end + 1 - minMidi) / (maxMidi - minMidi)) * width;
      final y0 = zoneTop + lane * laneHeight;
      final y1 = y0 + laneHeight;
      final selectedRegion = zone.contains(selected);
      final rect = Rect.fromLTRB(x0 + 1, y0 + 1, x1 - 1, y1 - 1);
      canvas.drawRect(
        rect,
        Paint()
          ..color = selectedRegion
              ? colorScheme.tertiary.withValues(alpha: 0.66)
              : colorScheme.primary.withValues(alpha: 0.36),
      );
      if (selectedRegion) {
        canvas.drawRect(
          rect.deflate(1),
          Paint()
            ..color = colorScheme.onSurface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (rect.width > 14 && rect.height > 14) {
        final label = rect.width >= 46 ? zone.label : zone.compactLabel;
        final labelPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: selectedRegion
                  ? Colors.black.withValues(alpha: 0.88)
                  : colorScheme.onSurface.withValues(alpha: 0.82),
              fontSize: rect.width >= 46 ? (selectedRegion ? 10 : 9) : 8,
              fontWeight: selectedRegion ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          maxLines: 1,
          ellipsis: '...',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rect.width - 8);
        canvas.save();
        canvas.clipRect(rect.deflate(3));
        labelPainter.paint(
          canvas,
          Offset(
            rect.left + 4,
            rect.top + (rect.height - labelPainter.height) / 2,
          ),
        );
        canvas.restore();
      }
    }

    canvas.drawRect(whiteKeyRect, keyboardBase);

    for (var midi = minMidi; midi < maxMidi; midi++) {
      final x0 = left + ((midi - minMidi) / (maxMidi - minMidi)) * width;
      final x1 = left + ((midi + 1 - minMidi) / (maxMidi - minMidi)) * width;
      final note = midi % 12;
      final isBlack = _isBlackNote(note);
      if (isBlack) {
        continue;
      }
      final keyRect = Rect.fromLTRB(x0, keyboardTop, x1, keyboardBottom);
      final paint = Paint()
        ..color = colorScheme.onSurface.withValues(alpha: 0.78);
      canvas.drawRect(keyRect.deflate(0.75), paint);
      canvas.drawLine(
        Offset(keyRect.left, keyRect.top),
        Offset(keyRect.left, keyRect.bottom),
        gridPaint,
      );
    }

    for (var midi = minMidi; midi < maxMidi; midi++) {
      final note = midi % 12;
      final isBlack = _isBlackNote(note);
      if (!isBlack) {
        continue;
      }
      final x0 = left + ((midi - minMidi) / (maxMidi - minMidi)) * width;
      final x1 = left + ((midi + 1 - minMidi) / (maxMidi - minMidi)) * width;
      final center = (x0 + x1) / 2;
      final blackWidth = (x1 - x0) * 0.72;
      final keyRect = Rect.fromLTRB(
        center - blackWidth / 2,
        keyboardTop,
        center + blackWidth / 2,
        keyboardTop + ((keyboardBottom - keyboardTop) * 0.64),
      );
      final paint = Paint()
        ..color = colorScheme.surfaceContainerLowest.withValues(alpha: 0.98);
      canvas.drawRect(keyRect, paint);
      canvas.drawRect(keyRect, gridPaint);
    }

    final selectedRoot = selected?.rootMidi;
    if (selectedRoot != null) {
      final root = selectedRoot.clamp(minMidi, maxMidi);
      final x0 = left + ((root - minMidi) / (maxMidi - minMidi)) * width;
      final x1 = left + ((root + 1 - minMidi) / (maxMidi - minMidi)) * width;
      final selectedPaint = Paint()
        ..color = colorScheme.tertiary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRect(
        Rect.fromLTRB(x0, keyboardTop, x1, keyboardBottom).deflate(1.5),
        selectedPaint,
      );
    }

    for (var midi = minMidi; midi <= maxMidi; midi += 12) {
      final x = left + ((midi - minMidi) / (maxMidi - minMidi)) * width;
      final textPainter = TextPainter(
        text: TextSpan(
          text: PolyMultisampleParser.midiToNoteName(midi),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x + 3, 7));
    }
  }

  @override
  bool shouldRepaint(covariant _KeyboardMapPainter oldDelegate) {
    return true;
  }

  bool _isBlackNote(int note) {
    return note == 1 || note == 3 || note == 6 || note == 8 || note == 10;
  }
}
