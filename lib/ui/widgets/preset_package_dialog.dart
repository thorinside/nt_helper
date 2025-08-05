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
import 'package:nt_helper/db/database.dart';

/// Dialog for creating preset packages
class PresetPackageDialog extends StatefulWidget {
  final String presetFilePath; // e.g., "presets/MyPreset.json"
  final PresetFileSystem fileSystem;
  final AppDatabase database;

  const PresetPackageDialog({
    super.key,
    required this.presetFilePath,
    required this.fileSystem,
    required this.database,
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
      final presetBytes =
          await widget.fileSystem.readFile(widget.presetFilePath);
      if (presetBytes == null) throw Exception('Preset file not found');

      final presetJson = utf8.decode(presetBytes);
      final presetData = jsonDecode(presetJson) as Map<String, dynamic>;

      setState(() {
        dependencies = PresetAnalyzer.analyzeDependencies(presetData);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing preset: $e')),
      );
    } finally {
      setState(() => isAnalyzing = false);
    }
  }

  Future<void> _createPackage() async {
    setState(() => isPackaging = true);

    // Save context references before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final presetName =
          widget.presetFilePath.split('/').last.replaceAll('.json', '');
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Preset Package',
        fileName: '${presetName}_package.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (outputPath != null) {
        final packageCreator =
            PackageCreator(widget.fileSystem, widget.database);
        final packageBytes = await packageCreator.createPackage(
          presetFilePath: widget.presetFilePath,
          config: config,
          onProgress: (status) => setState(() => _status = status),
        );

        await File(outputPath).writeAsBytes(packageBytes);

        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Package created successfully!')),
        );
        navigator.pop();
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error creating package: $e')),
      );
    } finally {
      setState(() => isPackaging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presetName = widget.presetFilePath.split('/').last;

    return AlertDialog(
      title: Text('Package: $presetName'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAnalyzing) ...[
              const Center(child: CircularProgressIndicator()),
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
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Text(_status,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center),
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
          onPressed:
              dependencies != null && !isPackaging ? _createPackage : null,
          child: isPackaging
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
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
            const Text('Dependencies:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (dependencies!.wavetables.isNotEmpty)
              Text('Wavetables: ${dependencies!.wavetables.length}'),
            if (dependencies!.sampleFolders.isNotEmpty)
              Text('Sample folders: ${dependencies!.sampleFolders.length}'),
            if (dependencies!.multisampleFolders.isNotEmpty)
              Text(
                  'Multisample folders: ${dependencies!.multisampleFolders.length}'),
            if (dependencies!.fmBanks.isNotEmpty)
              Text('FM banks: ${dependencies!.fmBanks.length}'),
            if (dependencies!.threePotPrograms.isNotEmpty)
              Text(
                  'Three Pot programs: ${dependencies!.threePotPrograms.length}'),
            if (dependencies!.luaScripts.isNotEmpty)
              Text('Lua scripts: ${dependencies!.luaScripts.length}'),
            if (dependencies!.communityPlugins.isNotEmpty) ...[
              Text(
                  'Community plugins: ${dependencies!.communityPlugins.length}'),
              if (config.includeCommunityPlugins)
                const Text('✓ Will be included in package',
                    style: TextStyle(color: Colors.green, fontSize: 12))
              else
                const Text('⚠️ Requires manual installation',
                    style: TextStyle(color: Colors.orange, fontSize: 12)),
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
            const Text('Package Options:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Include Wavetables'),
              value: config.includeWavetables,
              onChanged: (value) => setState(
                  () => config = config.copyWith(includeWavetables: value)),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Include Samples & Multisamples'),
              value: config.includeSamples,
              onChanged: (value) => setState(
                  () => config = config.copyWith(includeSamples: value)),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Include FM Banks'),
              value: config.includeFMBanks,
              onChanged: (value) => setState(
                  () => config = config.copyWith(includeFMBanks: value)),
              dense: true,
            ),
            CheckboxListTile(
              title: const Text('Include Three Pot Programs'),
              value: config.includeThreePot,
              onChanged: (value) => setState(
                  () => config = config.copyWith(includeThreePot: value)),
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
                  () => config = config.copyWith(includeReadme: value)),
              dense: true,
            ),
            if (dependencies?.hasCommunityPlugins == true)
              CheckboxListTile(
                title: const Text('Include Community Plugins'),
                subtitle: const Text(
                    'Package community plugins with preset (default: false)'),
                value: config.includeCommunityPlugins,
                onChanged: (value) {
                  setState(() =>
                      config = config.copyWith(includeCommunityPlugins: value));
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
