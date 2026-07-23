import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:nt_helper/algorithm_controller/algorithm_controller.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/ui/algorithm_registry.dart';
import 'package:nt_helper/ui/widgets/algorithm_controller/lua_algorithm_controller_view.dart';
import 'package:nt_helper/ui/widgets/section_parameter_controller.dart';
import 'package:nt_helper/ui/widgets/section_parameter_list_view.dart';
import 'package:nt_helper/ui/widgets/slot_editor_mode_selector.dart';

class SlotDetailView extends StatefulWidget {
  final Slot slot;
  final int slotIndex;
  final List<String> units;
  final FirmwareVersion firmwareVersion;
  final SectionParameterController? sectionController;
  final bool spreadsheetEditingMode;
  final VoidCallback? onToggleSpreadsheetEditingMode;
  final bool spreadsheetToggleEnabled;

  const SlotDetailView({
    super.key,
    required this.slot,
    required this.slotIndex,
    required this.units,
    required this.firmwareVersion,
    this.sectionController,
    this.spreadsheetEditingMode = false,
    this.onToggleSpreadsheetEditingMode,
    this.spreadsheetToggleEnabled = true,
  });

  @override
  State<SlotDetailView> createState() => _SlotDetailViewState();
}

class _SlotDetailViewState extends State<SlotDetailView>
    with AutomaticKeepAliveClientMixin {
  bool _controllerEditingMode = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant SlotDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slot.algorithm.guid != widget.slot.algorithm.guid ||
        widget.spreadsheetEditingMode) {
      _controllerEditingMode = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final definition = AlgorithmControllerRegistry.bundled.findForGuid(
      widget.slot.algorithm.guid,
    );
    final mode = widget.spreadsheetEditingMode
        ? SlotEditorMode.spreadsheet
        : _controllerEditingMode && definition != null
        ? SlotEditorMode.controller
        : SlotEditorMode.standard;
    final modeSelector = SlotEditorModeSelector(
      mode: mode,
      controllerName: definition?.name,
      enabled: widget.spreadsheetToggleEnabled,
      onSelected: (selectedMode) => _selectMode(selectedMode, definition),
    );

    if (mode == SlotEditorMode.controller && definition != null) {
      return SafeArea(
        child: Column(
          children: [
            _standaloneActionRow(modeSelector),
            Expanded(
              child: LuaAlgorithmControllerView(
                definition: definition,
                slot: widget.slot,
                slotIndex: widget.slotIndex,
                units: widget.units,
                onError: _handleControllerError,
              ),
            ),
          ],
        ),
      );
    }

    if (mode == SlotEditorMode.standard) {
      final view = AlgorithmViewRegistry.findViewFor(
        widget.slot,
        widget.slotIndex,
        widget.firmwareVersion,
      );
      if (view != null) {
        return SafeArea(
          child: Column(
            children: [
              _standaloneActionRow(modeSelector),
              Expanded(child: view),
            ],
          ),
        );
      }
    }

    // Create a set of list sections for the parameters of the
    // algorithm initially based off Os' organization on the module firmware.

    return SafeArea(
      child: SectionParameterListView(
        slot: widget.slot,
        slotIndex: widget.slotIndex,
        units: widget.units,
        pages: widget.slot.pages,
        sectionController: widget.sectionController,
        spreadsheetEditingMode: widget.spreadsheetEditingMode,
        editorModeSelector: modeSelector,
      ),
    );
  }

  Widget _standaloneActionRow(Widget modeSelector) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [modeSelector],
      ),
    );
  }

  void _selectMode(
    SlotEditorMode mode,
    AlgorithmControllerDefinition? definition,
  ) {
    if (!widget.spreadsheetToggleEnabled) return;
    switch (mode) {
      case SlotEditorMode.standard:
        if (_controllerEditingMode) {
          setState(() => _controllerEditingMode = false);
        }
        if (widget.spreadsheetEditingMode) {
          widget.onToggleSpreadsheetEditingMode?.call();
        }
        return;
      case SlotEditorMode.spreadsheet:
        if (_controllerEditingMode) {
          setState(() => _controllerEditingMode = false);
        }
        if (!widget.spreadsheetEditingMode) {
          widget.onToggleSpreadsheetEditingMode?.call();
        }
        return;
      case SlotEditorMode.controller:
        if (definition == null) return;
        if (widget.spreadsheetEditingMode) {
          widget.onToggleSpreadsheetEditingMode?.call();
        }
        if (!_controllerEditingMode) {
          setState(() => _controllerEditingMode = true);
          SemanticsService.sendAnnouncement(
            View.of(context),
            '${definition.name} shown',
            TextDirection.ltr,
          );
        }
        return;
    }
  }

  void _handleControllerError(String message) {
    if (!mounted || !_controllerEditingMode) return;
    setState(() => _controllerEditingMode = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message. Returned to the standard editor.')),
    );
  }
}
