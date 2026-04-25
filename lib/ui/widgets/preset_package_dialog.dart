import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nt_helper/interfaces/preset_file_system.dart';
import 'package:nt_helper/models/preset_dependencies.dart';
import 'package:nt_helper/models/package_config.dart';
import 'package:nt_helper/services/preset_analyzer.dart';
import 'package:nt_helper/services/package_creator.dart';
import 'package:nt_helper/services/settings_service.dart';

/// Dialog for creating preset packages
class PresetPackageDialog extends StatefulWidget {
  final String presetFilePath; // e.g., "presets/MyPreset.json"
  final PresetFileSystem fileSystem;

  /// Plugin GUID → SD-card file path map, sourced from live AlgorithmInfo.
  /// Required for community-plugin packaging — without it, plugin binaries
  /// cannot be located.
  final Map<String, String>? pluginPaths;

  const PresetPackageDialog({
    super.key,
    required this.presetFilePath,
    required this.fileSystem,
    this.pluginPaths,
  });

  @override
  State<PresetPackageDialog> createState() => _PresetPackageDialogState();
}

class _PresetPackageDialogState extends State<PresetPackageDialog> {
  PresetDependencies? dependencies;
  bool isAnalyzing = false;
  bool isPackaging = false;
  String _status = '';
  PackageConfig config = const PackageConfig();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _analyzeDependencies();
  }

  void _loadSettings() {
    final settings = SettingsService();
    config = config.copyWith(
      includeCommunityPlugins: settings.includeCommunityPlugins,
    );
  }

  Future<void> _analyzeDependencies() async {
    setState(() => isAnalyzing = true);

    try {
      // Load and parse preset JSON directly
      final presetBytes = await widget.fileSystem.readFile(
        widget.presetFilePath,
      );
      if (presetBytes == null) throw Exception('Preset file not found');

      final presetJson = utf8.decode(presetBytes);
      final presetData = jsonDecode(presetJson) as Map<String, dynamic>;

      final deps = PresetAnalyzer.analyzeDependencies(presetData);

      // If plugin paths were provided (from live AlgorithmInfo), add them
      if (widget.pluginPaths != null) {
        deps.pluginPaths.addAll(widget.pluginPaths!);
      }

      setState(() {
        dependencies = deps;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error analyzing preset: $e')));
    } finally {
      setState(() => isAnalyzing = false);
    }
  }

  Future<void> _createPackage() async {
    setState(() => isPackaging = true);

    // Save context references before async operations.
    // `rootNavigator` is the parent that hosts this dialog — we use it
    // to show a follow-up warnings dialog after this one closes (this
    // dialog's own context will be defunct by then).
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    try {
      final presetName = widget.presetFilePath
          .split('/')
          .last
          .replaceAll('.json', '');
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Preset Package',
        fileName: '${presetName}_package.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (outputPath != null) {
        final packageCreator = PackageCreator(widget.fileSystem);
        final packageResult = await packageCreator.createPackage(
          presetFilePath: widget.presetFilePath,
          config: config,
          onProgress: (status) => setState(() => _status = status),
          pluginPaths: widget.pluginPaths,
        );

        await File(outputPath).writeAsBytes(packageResult.zipBytes);

        navigator.pop();

        if (packageResult.hasWarnings && rootNavigator.mounted) {
          // Show in a dialog rather than a snackbar — warning lists can be
          // long (e.g. one entry per missing sample), and the user needs
          // to be able to read them all.
          await showDialog<void>(
            context: rootNavigator.context,
            builder: (ctx) => _PackageWarningsDialog(
              warnings: packageResult.warnings,
            ),
          );
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error creating package: $e')),
      );
    } finally {
      if (mounted) setState(() => isPackaging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presetName = widget.presetFilePath.split('/').last;

    return AlertDialog(
      title: Semantics(
        header: true,
        child: Text('Package: $presetName'),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAnalyzing) ...[
              Center(
                child: Semantics(
                  label: 'Analyzing preset dependencies',
                  child: const CircularProgressIndicator(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Analyzing preset dependencies...'),
            ] else if (dependencies != null) ...[
              Text('Dependencies found: ${dependencies!.totalCount}'),
              const SizedBox(height: 16),
              _buildDependencyList(),
              const SizedBox(height: 16),
              _buildConfigOptions(),
            ],
            if (isPackaging) ...[
              const SizedBox(height: 16),
              Center(
                child: Semantics(
                  label: 'Creating package: $_status',
                  child: const CircularProgressIndicator(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _status,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isPackaging ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: dependencies != null && !isPackaging
              ? _createPackage
              : null,
          child: isPackaging
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Package'),
        ),
      ],
    );
  }

  Widget _buildDependencyList() {
    if (dependencies == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dependencies:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (dependencies!.wavetables.isNotEmpty)
              Text('Wavetables: ${dependencies!.wavetables.length}'),
            if (dependencies!.sampleFolders.isNotEmpty)
              Text('Sample folders: ${dependencies!.sampleFolders.length}'),
            if (dependencies!.sampleFiles.isNotEmpty)
              Text('Sample files: ${dependencies!.sampleFiles.length}'),
            if (dependencies!.granulatorSamples.isNotEmpty)
              Text(
                'Granulator samples: ${dependencies!.granulatorSamples.length}',
              ),
            if (dependencies!.multisampleFolders.isNotEmpty)
              Text(
                'Multisample folders: ${dependencies!.multisampleFolders.length}',
              ),
            if (dependencies!.fmBanks.isNotEmpty)
              Text('FM banks: ${dependencies!.fmBanks.length}'),
            if (dependencies!.threePotPrograms.isNotEmpty)
              Text(
                'Three Pot programs: ${dependencies!.threePotPrograms.length}',
              ),
            if (dependencies!.luaScripts.isNotEmpty)
              Text('Lua scripts: ${dependencies!.luaScripts.length}'),
            if (dependencies!.communityPlugins.isNotEmpty) ...[
              Text(
                'Community plugins: ${dependencies!.communityPlugins.length}',
              ),
              if (config.includeCommunityPlugins)
                const Text(
                  '✓ Will be included in package',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                )
              else
                const Text(
                  '⚠️ Requires manual installation',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
            ],
            if (dependencies!.isEmpty) const Text('No dependencies found'),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Package Options:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Include Wavetables'),
              value: config.includeWavetables,
              onChanged: (value) => setState(
                () => config = config.copyWith(includeWavetables: value),
              ),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Include Samples & Multisamples'),
              value: config.includeSamples,
              onChanged: (value) => setState(
                () => config = config.copyWith(includeSamples: value),
              ),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Include FM Banks'),
              value: config.includeFMBanks,
              onChanged: (value) => setState(
                () => config = config.copyWith(includeFMBanks: value),
              ),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Include Three Pot Programs'),
              value: config.includeThreePot,
              onChanged: (value) => setState(
                () => config = config.copyWith(includeThreePot: value),
              ),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Include Lua Scripts'),
              value: config.includeLua,
              onChanged: (value) =>
                  setState(() => config = config.copyWith(includeLua: value)),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Include README'),
              value: config.includeReadme,
              onChanged: (value) => setState(
                () => config = config.copyWith(includeReadme: value),
              ),
              dense: true,
            ),
            if (dependencies?.hasCommunityPlugins == true)
              CheckboxListTile(
                title: const Text('Include Community Plugins'),
                subtitle: const Text(
                  'Package community plugins with preset (default: on)',
                ),
                value: config.includeCommunityPlugins,
                onChanged: (value) {
                  setState(
                    () => config = config.copyWith(
                      includeCommunityPlugins: value,
                    ),
                  );
                  // Save preference for future exports
                  SettingsService().setIncludeCommunityPlugins(value ?? false);
                },
                dense: true,
              ),
          ],
        ),
      ),
    );
  }
}

/// Modal dialog that surfaces non-fatal warnings produced while
/// collecting dependency files for a preset package (missing files,
/// oversized files, read errors). The package was still written, but
/// some referenced content could not be included — the user needs to
/// see this so they know the package is incomplete.
class _PackageWarningsDialog extends StatelessWidget {
  final List<String> warnings;

  const _PackageWarningsDialog({required this.warnings});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Semantics(
        header: true,
        child: const Text('Package created with warnings'),
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The package was saved, but ${warnings.length} '
              '${warnings.length == 1 ? 'item was' : 'items were'} '
              'skipped or missing:',
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: warnings.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${warnings[i]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
