import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:nt_helper/algorithm_controller/algorithm_controller.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/ui/algorithm_registry.dart';
import 'package:nt_helper/ui/widgets/algorithm_controller/lua_algorithm_controller_view.dart';
import 'package:nt_helper/ui/widgets/section_parameter_controller.dart';
import 'package:nt_helper/ui/widgets/section_parameter_list_view.dart';
import 'package:nt_helper/ui/widgets/slot_editor_action_bar.dart';
import 'package:nt_helper/ui/widgets/slot_editor_mode.dart';
import 'package:nt_helper/ui/widgets/slot_editor_mode_selector.dart';

class SlotDetailView extends StatefulWidget {
  final Slot slot;
  final int slotIndex;
  final List<String> units;
  final FirmwareVersion firmwareVersion;
  final SectionParameterController? sectionController;
  final SlotEditorMode editorMode;
  final ValueChanged<SlotEditorMode> onEditorModeChanged;
  final bool editorModeEnabled;

  const SlotDetailView({
    super.key,
    required this.slot,
    required this.slotIndex,
    required this.units,
    required this.firmwareVersion,
    required this.editorMode,
    required this.onEditorModeChanged,
    this.sectionController,
    this.editorModeEnabled = true,
  });

  @override
  State<SlotDetailView> createState() => _SlotDetailViewState();
}

class _SlotDetailViewState extends State<SlotDetailView>
    with AutomaticKeepAliveClientMixin {
  late bool _controllerSectionsCollapsed;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controllerSectionsCollapsed = SettingsService().startPagesCollapsed;
  }

  @override
  void didUpdateWidget(covariant SlotDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slot.algorithm.guid != widget.slot.algorithm.guid) {
      _controllerSectionsCollapsed = SettingsService().startPagesCollapsed;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final definition = AlgorithmControllerRegistry.bundled.findForGuid(
      widget.slot.algorithm.guid,
    );
    final mode =
        widget.editorMode == SlotEditorMode.controller && definition == null
        ? SlotEditorMode.standard
        : widget.editorMode;
    final modeSelector = SlotEditorModeSelector(
      mode: mode,
      controllerName: definition?.name,
      enabled: widget.editorModeEnabled,
      onSelected: (selectedMode) => _selectMode(selectedMode, definition),
    );

    if (mode == SlotEditorMode.controller && definition != null) {
      return SafeArea(
        child: Column(
          children: [
            SlotEditorActionBar(
              slot: widget.slot,
              editorModeSelector: modeSelector,
              sectionsCollapsed: _controllerSectionsCollapsed,
              onToggleSections: _toggleControllerSections,
            ),
            Expanded(
              child: LuaAlgorithmControllerView(
                definition: definition,
                slot: widget.slot,
                slotIndex: widget.slotIndex,
                units: widget.units,
                sectionsCollapsed: _controllerSectionsCollapsed,
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
              SlotEditorActionBar(
                slot: widget.slot,
                editorModeSelector: modeSelector,
                sectionsCollapsed: false,
              ),
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
        spreadsheetEditingMode: mode == SlotEditorMode.spreadsheet,
        editorModeSelector: modeSelector,
      ),
    );
  }

  void _toggleControllerSections() {
    setState(
      () => _controllerSectionsCollapsed = !_controllerSectionsCollapsed,
    );
    SemanticsService.sendAnnouncement(
      View.of(context),
      _controllerSectionsCollapsed
          ? 'All controller sections collapsed'
          : 'All controller sections expanded',
      TextDirection.ltr,
    );
  }

  void _selectMode(
    SlotEditorMode mode,
    AlgorithmControllerDefinition? definition,
  ) {
    if (!widget.editorModeEnabled ||
        mode == widget.editorMode ||
        mode == SlotEditorMode.controller && definition == null) {
      return;
    }
    widget.onEditorModeChanged(mode);
  }

  void _handleControllerError(String message) {
    if (!mounted || widget.editorMode != SlotEditorMode.controller) return;
    widget.onEditorModeChanged(SlotEditorMode.standard);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message. Returned to the standard editor.')),
    );
  }
}
