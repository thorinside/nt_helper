import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/models/template_metadata.dart';
import 'package:nt_helper/ui/template_manager/template_slot_selection_list.dart';

class TemplateManagerScreen extends StatefulWidget {
  final AppDatabase? database;

  const TemplateManagerScreen({super.key, this.database});

  @override
  State<TemplateManagerScreen> createState() => _TemplateManagerScreenState();
}

class _TemplateManagerScreenState extends State<TemplateManagerScreen> {
  late Future<List<FullPresetDetails>> _templatesFuture;
  FullPresetDetails? _selected;
  Set<int> _selectedSlots = {};

  AppDatabase get _database => widget.database ?? context.read<AppDatabase>();

  @override
  void initState() {
    super.initState();
    _templatesFuture = _database.presetsDao.getTemplates();
  }

  void _refresh() {
    setState(() {
      _templatesFuture = _database.presetsDao.getTemplates();
      _selected = null;
      _selectedSlots = {};
    });
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
            return const Center(child: Text('No templates found.'));
          }
          final selected = _selected ?? templates.first;
          _selected ??= selected;

          return LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              final list = _TemplateManagerList(
                templates: templates,
                selectedId: selected.preset.id,
                onSelected: (template) {
                  setState(() {
                    _selected = template;
                    _selectedSlots = {};
                  });
                },
              );
              final detail = _TemplateManagerDetail(
                template: selected,
                selectedSlots: _selectedSlots,
                onSelectionChanged: (next) {
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
  final ValueChanged<FullPresetDetails> onSelected;

  const _TemplateManagerList({
    required this.templates,
    required this.selectedId,
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
                onPressed: null,
              ),
              IconButton(
                tooltip: 'Edit metadata',
                icon: const Icon(Icons.edit_outlined),
                onPressed: null,
              ),
              IconButton(
                tooltip: 'Delete template',
                icon: const Icon(Icons.delete_outline),
                onPressed: null,
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

class _TemplateManagerDetail extends StatelessWidget {
  final FullPresetDetails template;
  final Set<int> selectedSlots;
  final ValueChanged<Set<int>> onSelectionChanged;

  const _TemplateManagerDetail({
    required this.template,
    required this.selectedSlots,
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
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Insert')),
                  ButtonSegment(value: true, label: Text('Replace')),
                ],
                selected: const {false},
                onSelectionChanged: (_) {},
              ),
              FilledButton.icon(
                icon: const Icon(Icons.playlist_add),
                label: const Text('Apply selected'),
                onPressed: selectedSlots.isEmpty ? null : () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
