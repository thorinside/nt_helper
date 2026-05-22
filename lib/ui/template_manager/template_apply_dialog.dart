import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';

enum _TemplateApplyTarget { device, preset }

class TemplateApplyDialog extends StatefulWidget {
  final AppDatabase? database;
  final FullPresetDetails template;
  final Set<int> selectedIndices;
  final Future<void> Function()? onApplyDevice;
  final VoidCallback? onCancelDeviceApply;

  const TemplateApplyDialog({
    super.key,
    this.database,
    required this.template,
    required this.selectedIndices,
    this.onApplyDevice,
    this.onCancelDeviceApply,
  });

  static Future<void> show(
    BuildContext context, {
    AppDatabase? database,
    required FullPresetDetails template,
    required Set<int> selectedIndices,
    Future<void> Function()? onApplyDevice,
    VoidCallback? onCancelDeviceApply,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 560,
          child: TemplateApplyDialog(
            database: database,
            template: template,
            selectedIndices: selectedIndices,
            onApplyDevice: onApplyDevice,
            onCancelDeviceApply: onCancelDeviceApply,
          ),
        ),
      ),
    );
  }

  @override
  State<TemplateApplyDialog> createState() => _TemplateApplyDialogState();
}

class _TemplateApplyDialogState extends State<TemplateApplyDialog> {
  late Future<List<FullPresetDetails>> _targetsFuture;
  _TemplateApplyTarget _target = _TemplateApplyTarget.preset;
  int? _targetPresetId;
  bool _inFlight = false;
  bool _overwrite = false;
  String? _message;
  String? _error;

  AppDatabase get _database => widget.database ?? context.read<AppDatabase>();

  @override
  void initState() {
    super.initState();
    _targetsFuture = _database.presetsDao.getNonTemplates();
  }

  @override
  void dispose() {
    if (_inFlight && _target == _TemplateApplyTarget.device) {
      widget.onCancelDeviceApply?.call();
    }
    super.dispose();
  }

  Future<void> _apply(List<FullPresetDetails> targets) async {
    if (_inFlight || widget.selectedIndices.isEmpty) return;
    setState(() {
      _inFlight = true;
      _message = null;
      _error = null;
    });

    try {
      if (_target == _TemplateApplyTarget.device) {
        await (widget.onApplyDevice?.call() ?? Future<void>.value());
        if (!mounted) return;
        setState(() {
          _message = _appliedMessage(widget.selectedIndices.length);
        });
      } else {
        final targetId =
            _targetPresetId ??
            (targets.isEmpty ? null : targets.first.preset.id);
        if (targetId == null) {
          throw StateError('No target preset available.');
        }
        final target = targets.firstWhere((t) => t.preset.id == targetId);
        final selected = widget.selectedIndices.toList()..sort();
        final result = await _database.presetsDao.applyTemplateSlots(
          templateId: widget.template.preset.id,
          targetPresetId: targetId,
          templateSlotIndices: selected,
          insertionOffset: target.slots.length,
          overwrite: _overwrite,
        );
        if (!mounted) return;
        final applied = result.insertedSlotIndices.length;
        setState(() {
          _message = result.warning == null
              ? _appliedMessage(applied)
              : '${_appliedMessage(applied)} ${result.warning}';
        });
      }
    } on TemplateSpaceException catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            '${error.current} existing + ${error.applied} selected exceeds the '
            '${error.limit}-slot limit.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _inFlight = false);
      }
    }
  }

  String _appliedMessage(int count) {
    return 'Applied $count ${count == 1 ? 'slot' : 'slots'}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FullPresetDetails>>(
      future: _targetsFuture,
      builder: (context, snapshot) {
        final targets = snapshot.data ?? const <FullPresetDetails>[];
        if (_targetPresetId == null && targets.isNotEmpty) {
          _targetPresetId = targets.first.preset.id;
        }

        return PopScope(
          canPop: !_inFlight,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Apply template slots',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.selectedIndices.length} selected from '
                  '${widget.template.preset.name}',
                ),
                const SizedBox(height: 12),
                SegmentedButton<_TemplateApplyTarget>(
                  segments: const [
                    ButtonSegment(
                      value: _TemplateApplyTarget.preset,
                      icon: Icon(Icons.library_music_outlined),
                      label: Text('Local preset'),
                    ),
                    ButtonSegment(
                      value: _TemplateApplyTarget.device,
                      icon: Icon(Icons.memory),
                      label: Text('Current device'),
                    ),
                  ],
                  selected: {_target},
                  onSelectionChanged: _inFlight
                      ? null
                      : (next) => setState(() => _target = next.single),
                ),
                const SizedBox(height: 12),
                if (_target == _TemplateApplyTarget.preset)
                  snapshot.connectionState == ConnectionState.waiting
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<int>(
                          initialValue: _targetPresetId,
                          decoration: const InputDecoration(
                            labelText: 'Target preset',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final target in targets)
                              DropdownMenuItem(
                                value: target.preset.id,
                                child: Text(target.preset.name),
                              ),
                          ],
                          onChanged: _inFlight
                              ? null
                              : (value) => setState(() {
                                  _targetPresetId = value;
                                }),
                        ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _overwrite,
                  onChanged: _inFlight
                      ? null
                      : (value) => setState(() => _overwrite = value),
                  title: const Text('Replace existing slots'),
                ),
                if (_message != null)
                  Text(
                    _message!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_inFlight && _target == _TemplateApplyTarget.device)
                      TextButton(
                        onPressed: widget.onCancelDeviceApply,
                        child: const Text('Cancel'),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: _inFlight
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.playlist_add),
                      label: const Text('Apply selected'),
                      onPressed: _inFlight || widget.selectedIndices.isEmpty
                          ? null
                          : () => _apply(targets),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
