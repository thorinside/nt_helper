import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/models/template_metadata.dart';
import 'package:nt_helper/ui/template_manager/create_template_from_preset_dialog.dart';
import 'package:nt_helper/ui/template_manager/template_apply_dialog.dart';
import 'package:nt_helper/ui/template_manager/template_slot_selection_list.dart';

typedef TemplateDeviceApplyCallback =
    Future<void> Function(
      FullPresetDetails template,
      List<int> selectedIndices,
    );

typedef CurrentPresetSourceLoader = Future<FullPresetDetails?> Function();

class TemplateManagerScreen extends StatefulWidget {
  final AppDatabase? database;
  final TemplateDeviceApplyCallback? onApplyDevice;
  final VoidCallback? onCancelDeviceApply;
  final CurrentPresetSourceLoader? loadCurrentPresetSource;

  const TemplateManagerScreen({
    super.key,
    this.database,
    this.onApplyDevice,
    this.onCancelDeviceApply,
    this.loadCurrentPresetSource,
  });

  @override
  State<TemplateManagerScreen> createState() => _TemplateManagerScreenState();
}

class _TemplateManagerScreenState extends State<TemplateManagerScreen> {
  late Future<List<FullPresetDetails>> _templatesFuture;
  FullPresetDetails? _selected;
  Set<int> _selectedSlots = {};
  bool _isApplying = false;
  int _applyRun = 0;

  AppDatabase get _database => widget.database ?? context.read<AppDatabase>();

  @override
  void initState() {
    super.initState();
    _templatesFuture = _database.presetsDao.getTemplates();
  }

  @override
  void dispose() {
    if (_isApplying) {
      widget.onCancelDeviceApply?.call();
    }
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _templatesFuture = _database.presetsDao.getTemplates();
      _selected = null;
      _selectedSlots = {};
    });
  }

  Future<void> _editSelectedMetadata() async {
    final template = _selected;
    if (_isApplying || template == null) return;

    final saved = await _EditTemplateMetadataDialog.show(
      context,
      template: template,
      database: _database,
    );
    if (mounted && saved == true) {
      _refresh();
    }
  }

  Future<void> _deleteSelectedTemplate() async {
    final template = _selected;
    if (_isApplying || template == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text('Delete "${template.preset.name}" from saved templates?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _database.presetsDao.deletePreset(template.preset.id);
    if (mounted) _refresh();
  }

  Set<int> _allSlotIndices(FullPresetDetails template) {
    return {for (var i = 0; i < template.slots.length; i++) i};
  }

  void _selectTemplate(FullPresetDetails template) {
    setState(() {
      _selected = template;
      _selectedSlots = _allSlotIndices(template);
    });
  }

  Future<void> _applySelected(BuildContext context) async {
    final template = _selected;
    if (_isApplying || template == null || _selectedSlots.isEmpty) return;

    final selected = _selectedSlots.toList()..sort();
    final applyDevice = widget.onApplyDevice;
    if (applyDevice == null) {
      await TemplateApplyDialog.show(
        context,
        database: _database,
        template: template,
        selectedIndices: _selectedSlots,
      );
      return;
    }

    final applyRun = ++_applyRun;
    setState(() => _isApplying = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await applyDevice(template, selected);
      if (!mounted || applyRun != _applyRun) return;
      setState(() => _isApplying = false);
      if (navigator.canPop()) {
        navigator.pop();
      }
    } catch (error) {
      if (!mounted || applyRun != _applyRun) return;
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted && applyRun == _applyRun) {
        setState(() => _isApplying = false);
      }
    }
  }

  void _cancelApply() {
    if (!_isApplying) return;
    _applyRun++;
    widget.onCancelDeviceApply?.call();
    setState(() => _isApplying = false);
  }

  Future<void> _createFromCurrentPreset() async {
    final loader = widget.loadCurrentPresetSource;
    if (loader == null) return;

    final source = await loader();
    if (!mounted) return;
    if (source == null || source.slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No current preset slots to template.')),
      );
      return;
    }

    await CreateTemplateFromPresetDialog.show(
      context,
      database: _database,
      source: source,
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Manager'),
        actions: [
          IconButton(
            tooltip: 'Refresh templates',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<FullPresetDetails>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading templates: ${snapshot.error}'),
            );
          }

          final templates = snapshot.data ?? const <FullPresetDetails>[];
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No templates found.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('New from current preset'),
                    onPressed: widget.loadCurrentPresetSource == null
                        ? null
                        : () => _createFromCurrentPreset(),
                  ),
                ],
              ),
            );
          }
          if (_selected == null) {
            _selected = templates.first;
            _selectedSlots = _allSlotIndices(_selected!);
          }
          final selected = _selected!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              final list = _TemplateManagerList(
                templates: templates,
                selectedId: selected.preset.id,
                canCreateFromCurrentPreset:
                    widget.loadCurrentPresetSource != null,
                onCreateFromCurrentPreset: () => _createFromCurrentPreset(),
                canModifySelected: !_isApplying,
                onEditSelected: _editSelectedMetadata,
                onDeleteSelected: _deleteSelectedTemplate,
                onSelected: _isApplying ? (_) {} : _selectTemplate,
              );
              final detail = _TemplateManagerDetail(
                template: selected,
                selectedSlots: _selectedSlots,
                isApplying: _isApplying,
                appliesToDevice: widget.onApplyDevice != null,
                onApplySelected: () => _applySelected(context),
                onCancelApply: _cancelApply,
                onSelectionChanged: (next) {
                  if (_isApplying) return;
                  setState(() => _selectedSlots = next);
                },
              );

              if (narrow) {
                return Column(
                  children: [
                    SizedBox(height: 220, child: list),
                    const Divider(height: 1),
                    Expanded(child: detail),
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(width: 320, child: list),
                  const VerticalDivider(width: 1),
                  Expanded(child: detail),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TemplateManagerList extends StatelessWidget {
  final List<FullPresetDetails> templates;
  final int selectedId;
  final bool canCreateFromCurrentPreset;
  final VoidCallback onCreateFromCurrentPreset;
  final bool canModifySelected;
  final VoidCallback onEditSelected;
  final VoidCallback onDeleteSelected;
  final ValueChanged<FullPresetDetails> onSelected;

  const _TemplateManagerList({
    required this.templates,
    required this.selectedId,
    required this.canCreateFromCurrentPreset,
    required this.onCreateFromCurrentPreset,
    required this.canModifySelected,
    required this.onEditSelected,
    required this.onDeleteSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<FullPresetDetails>>{};
    for (final template in templates) {
      final category = template.preset.category?.trim();
      grouped
          .putIfAbsent(
            category == null || category.isEmpty ? 'Uncategorized' : category,
            () => [],
          )
          .add(template);
    }
    final categories = grouped.keys.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'New from current preset',
                icon: const Icon(Icons.add),
                onPressed: canCreateFromCurrentPreset
                    ? onCreateFromCurrentPreset
                    : null,
              ),
              IconButton(
                tooltip: 'Edit metadata',
                icon: const Icon(Icons.edit_outlined),
                onPressed: canModifySelected ? onEditSelected : null,
              ),
              IconButton(
                tooltip: 'Delete template',
                icon: const Icon(Icons.delete_outline),
                onPressed: canModifySelected ? onDeleteSelected : null,
              ),
              const Spacer(),
              Text(
                '${templates.length}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: [
              for (final category in categories) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (final template
                    in grouped[category]!
                      ..sort((a, b) => a.preset.name.compareTo(b.preset.name)))
                  _TemplateListTile(
                    template: template,
                    selected: template.preset.id == selectedId,
                    onTap: () => onSelected(template),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TemplateListTile extends StatelessWidget {
  final FullPresetDetails template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateListTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = TemplateMetadata.fromJsonString(
      template.preset.templateMetadata,
    );
    final firstTag = metadata.tags.isEmpty ? null : metadata.tags.first;

    return ListTile(
      selected: selected,
      leading: const Icon(Icons.star_outline),
      title: Text(template.preset.name),
      subtitle: Text('${template.slots.length} slots'),
      trailing: firstTag == null
          ? null
          : Chip(label: Text(firstTag), visualDensity: VisualDensity.compact),
      onTap: onTap,
    );
  }
}

class _EditTemplateMetadataDialog extends StatefulWidget {
  final FullPresetDetails template;
  final AppDatabase database;

  const _EditTemplateMetadataDialog({
    required this.template,
    required this.database,
  });

  static Future<bool?> show(
    BuildContext context, {
    required FullPresetDetails template,
    required AppDatabase database,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) =>
          _EditTemplateMetadataDialog(template: template, database: database),
    );
  }

  @override
  State<_EditTemplateMetadataDialog> createState() =>
      _EditTemplateMetadataDialogState();
}

class _EditTemplateMetadataDialogState
    extends State<_EditTemplateMetadataDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  late final TextEditingController _authorController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final metadata = TemplateMetadata.fromJsonString(
      widget.template.preset.templateMetadata,
    );
    _nameController = TextEditingController(text: widget.template.preset.name);
    _categoryController = TextEditingController(
      text: widget.template.preset.category ?? '',
    );
    _descriptionController = TextEditingController(
      text: metadata.description ?? '',
    );
    _tagsController = TextEditingController(text: metadata.tags.join(', '));
    _authorController = TextEditingController(text: metadata.author ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final metadata = TemplateMetadata(
        description: _nullIfEmpty(_descriptionController.text),
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(growable: false),
        author: _nullIfEmpty(_authorController.text),
      );
      await widget.database.presetsDao.updateTemplateMetadata(
        presetId: widget.template.preset.id,
        name: name,
        category: _nullIfEmpty(_categoryController.text),
        templateMetadata: metadata.toJsonString(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty && !_saving;

    return AlertDialog(
      title: const Text('Edit template metadata'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('edit-template-name'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (_) => setState(() {}),
              ),
              TextField(
                key: const ValueKey('edit-template-category'),
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                key: const ValueKey('edit-template-description'),
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                key: const ValueKey('edit-template-tags'),
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags'),
              ),
              TextField(
                key: const ValueKey('edit-template-author'),
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save'),
          onPressed: canSave ? _save : null,
        ),
      ],
    );
  }
}

class _TemplateManagerDetail extends StatelessWidget {
  final FullPresetDetails template;
  final Set<int> selectedSlots;
  final bool isApplying;
  final bool appliesToDevice;
  final VoidCallback onApplySelected;
  final VoidCallback? onCancelApply;
  final ValueChanged<Set<int>> onSelectionChanged;

  const _TemplateManagerDetail({
    required this.template,
    required this.selectedSlots,
    required this.isApplying,
    required this.appliesToDevice,
    required this.onApplySelected,
    this.onCancelApply,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = TemplateMetadata.fromJsonString(
      template.preset.templateMetadata,
    );
    final tags = metadata.tags.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                template.preset.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if ((template.preset.category ?? '').isNotEmpty)
                Text('Category: ${template.preset.category!}'),
              if (tags.isNotEmpty) Chip(label: Text(tags)),
              if ((metadata.author ?? '').isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 18),
                    const SizedBox(width: 6),
                    Text(metadata.author!),
                  ],
                ),
            ],
          ),
        ),
        if ((metadata.description ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(metadata.description!),
          ),
        const Divider(height: 1),
        Expanded(
          child: TemplateSlotSelectionList(
            template: template,
            selectedIndices: selectedSlots,
            onSelectionChanged: onSelectionChanged,
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isApplying && appliesToDevice) ...[
                Text(
                  'Applying ${selectedSlots.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onCancelApply,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                icon: isApplying
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.playlist_add),
                label: const Text('Apply selected'),
                onPressed: selectedSlots.isEmpty || isApplying
                    ? null
                    : onApplySelected,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
