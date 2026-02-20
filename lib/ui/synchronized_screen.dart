import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:nt_helper/ui/add_algorithm_screen.dart';
import 'package:nt_helper/constants.dart';
import 'package:nt_helper/core/platform/platform_interaction_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show AlgorithmInfo, DisplayMode;

import 'package:nt_helper/ui/widgets/floating_video_overlay.dart';
import 'package:nt_helper/cubit/video_frame_cubit.dart';
import 'package:nt_helper/models/preset_action.dart';
import 'package:nt_helper/ui/widgets/preset_browser_dialog.dart';
import 'package:nt_helper/cubit/preset_browser_cubit.dart';

import 'package:nt_helper/ui/performance_screen.dart';
import 'package:nt_helper/ui/widgets/rename_preset_dialog.dart';
import 'package:nt_helper/ui/widgets/rename_slot_dialog.dart';
import 'package:nt_helper/ui/widgets/routing/consolidate_buses_dialog.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_widget.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_controller.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/core/routing/node_layout_algorithm.dart';
import 'package:nt_helper/services/key_binding_service.dart';
import 'package:nt_helper/services/mcp_server_service.dart';
import 'package:nt_helper/services/settings_service.dart';

import 'package:nt_helper/ui/cpu_monitor_widget.dart';
import 'package:nt_helper/ui/metadata_sync/metadata_sync_page.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart';
import 'package:nt_helper/ui/plugin_manager_screen.dart';
import 'package:nt_helper/ui/widgets/shortcut_help_overlay.dart';

import 'package:nt_helper/util/extensions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/ui/widgets/algorithm_list_view.dart';
import 'package:nt_helper/ui/widgets/disting_version.dart';
import 'package:nt_helper/ui/widgets/slot_detail_view.dart';
import 'package:nt_helper/ui/widgets/mcp_status_indicator.dart';
import 'package:nt_helper/ui/widgets/debug_panel.dart';
import 'package:nt_helper/ui/widgets/section_parameter_controller.dart';
import 'package:nt_helper/services/debug_service.dart';
import 'package:nt_helper/ui/firmware/firmware_update_screen.dart';
import 'package:nt_helper/ui/widgets/app_update_banner.dart';
import 'package:nt_helper/ui/widgets/app_update_dialog.dart';
import 'package:nt_helper/ui/widgets/contextual_help_bar.dart';
import 'package:nt_helper/models/app_release.dart';
import 'package:nt_helper/services/app_update_service.dart';

enum EditMode { parameters, routing, both }

/// Help text for algorithm name interactions
const String _algorithmNameHelpText =
    'Double-click: Focus algorithm UI  •  Long-press: Rename algorithm';

class SynchronizedScreen extends StatefulWidget {
  final List<Slot> slots;
  final List<AlgorithmInfo> algorithms;
  final List<String> units;
  final String presetName;
  final String distingVersion;
  final FirmwareVersion firmwareVersion;
  final Uint8List? screenshot;
  final bool loading;
  final PlatformInteractionService? platformService;

  const SynchronizedScreen({
    super.key,
    required this.slots,
    required this.algorithms,
    required this.units,
    required this.presetName,
    required this.distingVersion,
    required this.firmwareVersion,
    required this.screenshot,
    required this.loading,
    this.platformService,
  });

  @override
  State<SynchronizedScreen> createState() => _SynchronizedScreenState();
}

class _SynchronizedScreenState extends State<SynchronizedScreen>
    with TickerProviderStateMixin {
  late final PlatformInteractionService _platformService;
  final RoutingEditorController _editorController = RoutingEditorController();
  final KeyBindingService _keyBindingService = KeyBindingService();
  final FocusNode _screenFocusNode = FocusNode();
  late int _selectedIndex;
  late TabController _tabController;
  EditMode _currentMode = EditMode.parameters;
  double _splitDividerPosition = SettingsService.defaultSplitDividerPosition;
  bool _showDebugPanel = true;
  bool _showContextualHelp = true;
  String? _contextualHelpText;
  AppRelease? _availableAppUpdate;
  AppUpdateService? _appUpdateService;
  RoutingEditorCubit? _routingEditorCubit;
  late final Widget _cachedRoutingCanvas = _buildRoutingCanvas();
  StreamSubscription<RoutingEditorState>? _routingFocusSub;
  bool _isSyncingSelection = false;
  bool _isAddAlgorithmOpen = false;
  bool _isBrowsePresetsOpen = false;
  bool _isShortcutHelpOpen = false;
  final SectionParameterController _sectionController =
      SectionParameterController();

  @override
  void initState() {
    super.initState();
    _platformService = widget.platformService ?? PlatformInteractionService();
    _selectedIndex = 0;
    _tabController = TabController(length: widget.slots.length, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Initialize debug service in debug mode
    if (kDebugMode) {
      DebugService().initialize();
      _showDebugPanel = SettingsService().showDebugPanel;
    }

    // Initialize contextual help setting
    _showContextualHelp = SettingsService().showContextualHelp;

    // Initialize split divider position
    _splitDividerPosition = SettingsService().splitDividerPosition;

    // Re-acquire focus when it drifts outside the screen's subtree
    // (e.g. after an inline text editor is removed from the tree)
    _screenFocusNode.addListener(_reclaimFocusIfLost);

    // Check for app updates on desktop
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      _checkForAppUpdate();
    }

    // Determine the new_valid_index based on the current _selectedIndex and the new slots length.
    int newValidIndex = _selectedIndex;

    if (widget.slots.isEmpty) {
      newValidIndex = 0;
    } else {
      if (newValidIndex >= widget.slots.length) {
        newValidIndex = widget.slots.length - 1;
      }
      // Ensure index is not negative (shouldn't happen with current logic elsewhere but good safeguard)
      if (newValidIndex < 0) {
        newValidIndex = 0;
      }
    }

    // If the state variable _selectedIndex needs to be updated for other parts of the UI or internal logic.
    if (_selectedIndex != newValidIndex) {
      setState(() {
        _selectedIndex = newValidIndex;
      });
    }

    // Set the TabController's index to the new_valid_index that was just calculated.
    _tabController.index = newValidIndex;
  }

  void _reclaimFocusIfLost() {
    if (!_screenFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_screenFocusNode.hasFocus) {
          // Don't steal focus when a dialog/bottom sheet/pushed screen is active
          final route = ModalRoute.of(context);
          if (route != null && !route.isCurrent) return;

          // Don't steal focus from text fields (e.g. in non-route overlays)
          final primaryFocus = FocusManager.instance.primaryFocus;
          if (primaryFocus?.context
                  ?.findAncestorWidgetOfExactType<EditableText>() !=
              null) {
            return;
          }
          _screenFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _screenFocusNode.removeListener(_reclaimFocusIfLost);
    _screenFocusNode.dispose();
    _routingFocusSub?.cancel();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _routingEditorCubit?.close();
    _sectionController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SynchronizedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slots.length != oldWidget.slots.length) {
      _tabController.dispose();
      _tabController = TabController(length: widget.slots.length, vsync: this);
      _tabController.addListener(_handleTabSelection);
      // Clamp selectedIndex into valid range [0, slots.length-1] (or 0 if no slots).
      final int maxIndex = widget.slots.isEmpty ? 0 : widget.slots.length - 1;
      int newIndex = _selectedIndex.clamp(0, maxIndex);
      if (newIndex != _selectedIndex) {
        setState(() {
          _selectedIndex = newIndex;
        });
      }
      _tabController.index = newIndex;
    }
  }

  void _handleTabSelection() {
    if (_tabController.index != _selectedIndex) {
      setState(() {
        _selectedIndex = _tabController.index;
      });
      _syncSelectionToRouting(_selectedIndex);
      if (!_tabController.indexIsChanging &&
          _selectedIndex < widget.slots.length) {
        final slot = widget.slots[_selectedIndex];
        final name = slot.algorithm.name;
        SemanticsService.sendAnnouncement(
          WidgetsBinding.instance.platformDispatcher.views.first,
          'Slot ${_selectedIndex + 1}: $name',
          TextDirection.ltr,
        );
      }
    }
  }

  Future<void> _checkForAppUpdate() async {
    _appUpdateService ??= AppUpdateService();
    final release = await _appUpdateService!.checkForUpdate();
    if (!mounted || release == null) return;

    final settings = SettingsService();
    final dismissed = settings.dismissedUpdateVersion;
    if (dismissed == release.version) return;

    setState(() => _availableAppUpdate = release);
  }

  void _dismissAppUpdate() {
    final version = _availableAppUpdate?.version;
    if (version != null) {
      SettingsService().setDismissedUpdateVersion(version);
    }
    setState(() => _availableAppUpdate = null);
  }

  void _showAppUpdateDialog(AppRelease release) {
    _appUpdateService ??= AppUpdateService();
    showDialog(
      context: context,
      builder: (ctx) =>
          AppUpdateDialog(release: release, updateService: _appUpdateService!),
    );
  }

  RoutingEditorCubit _getOrCreateRoutingCubit(DistingCubit distingCubit) {
    if (_routingEditorCubit == null) {
      _routingEditorCubit = RoutingEditorCubit(distingCubit);
      _routingEditorCubit!.injectLayoutAlgorithm(NodeLayoutAlgorithm());
      _routingFocusSub = _routingEditorCubit!.stream.listen(
        _onRoutingStateChanged,
      );
    }
    return _routingEditorCubit!;
  }

  void _onRoutingStateChanged(RoutingEditorState routingState) {
    if (_isSyncingSelection) return;
    if (routingState is! RoutingEditorStateLoaded) return;

    final focusedIds = routingState.focusedAlgorithmIds;
    if (focusedIds.length != 1) return;

    final focusedId = focusedIds.first;
    final algorithm = routingState.algorithms
        .where((a) => a.id == focusedId)
        .firstOrNull;
    if (algorithm == null) return;

    final slotIndex = algorithm.index;
    if (slotIndex == _selectedIndex) return;
    if (slotIndex < 0 || slotIndex >= widget.slots.length) return;

    _isSyncingSelection = true;
    setState(() {
      _selectedIndex = slotIndex;
      _tabController.animateTo(slotIndex);
    });
    _isSyncingSelection = false;
  }

  static final _digitKeyToPageIndex = {
    LogicalKeyboardKey.digit1: 0,
    LogicalKeyboardKey.digit2: 1,
    LogicalKeyboardKey.digit3: 2,
    LogicalKeyboardKey.digit4: 3,
    LogicalKeyboardKey.digit5: 4,
    LogicalKeyboardKey.digit6: 5,
    LogicalKeyboardKey.digit7: 6,
    LogicalKeyboardKey.digit8: 7,
    LogicalKeyboardKey.digit9: 8,
    LogicalKeyboardKey.digit0: 9,
  };

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Only handle bare digit keys (no modifiers held)
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final hasModifier = pressed.any(
      (k) =>
          k == LogicalKeyboardKey.controlLeft ||
          k == LogicalKeyboardKey.controlRight ||
          k == LogicalKeyboardKey.metaLeft ||
          k == LogicalKeyboardKey.metaRight ||
          k == LogicalKeyboardKey.altLeft ||
          k == LogicalKeyboardKey.altRight,
    );
    if (hasModifier) return KeyEventResult.ignored;

    final pageIndex = _digitKeyToPageIndex[event.logicalKey];
    if (pageIndex != null && _currentMode != EditMode.routing) {
      _sectionController.goToPage(_selectedIndex, pageIndex);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _syncSelectionToRouting(int slotIndex) {
    if (_isSyncingSelection) return;
    _isSyncingSelection = true;
    _routingEditorCubit?.setFocusedAlgorithmBySlotIndex(slotIndex);
    _isSyncingSelection = false;
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 900;
    final cubit = context.read<DistingCubit>();
    final routingCubit = _getOrCreateRoutingCubit(cubit);

    final isOffline = switch (cubit.state) {
      DistingStateSynchronized(offline: final o) => o,
      _ => false,
    };

    Widget scaffold;

    // Fall back to single mode if split-screen conditions aren't met
    final screenWidth = MediaQuery.of(context).size.width;
    if (_currentMode == EditMode.both && !_canShowSplitScreen(screenWidth)) {
      _currentMode = EditMode.parameters;
    }

    // Use a conditional widget based on screen width
    if (isWideScreen && widget.slots.isNotEmpty) {
      // Wide screen layout with vertical list
      scaffold = Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(context, isWideScreen),
        body: Column(
          children: [
            Expanded(
              child: _currentMode == EditMode.both
                  ? _buildSplitView()
                  : IndexedStack(
                      index: _currentMode == EditMode.routing ? 1 : 0,
                      children: [_buildWideScreenBody(), _cachedRoutingCanvas],
                    ),
            ),
            AppUpdateBanner(
              release: _availableAppUpdate,
              onWhatsNew: () {
                if (_availableAppUpdate != null) {
                  _showAppUpdateDialog(_availableAppUpdate!);
                }
              },
              onDismiss: _dismissAppUpdate,
            ),
            if (_showContextualHelp)
              ContextualHelpBar(helpText: _contextualHelpText),
            if (kDebugMode && _showDebugPanel)
              DebugPanel(
                onDismiss: () {
                  setState(() {
                    _showDebugPanel = false;
                  });
                  SettingsService().setShowDebugPanel(false);
                },
              ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
        floatingActionButton: _buildFloatingActionButton(),
        bottomNavigationBar: _buildBottomAppBar(),
      );
    } else {
      // Default layout with TabBar
      scaffold = Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(context, isWideScreen),
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentMode == EditMode.routing ? 1 : 0,
                children: [_buildBody(), _cachedRoutingCanvas],
              ),
            ),
            AppUpdateBanner(
              release: _availableAppUpdate,
              onWhatsNew: () {
                if (_availableAppUpdate != null) {
                  _showAppUpdateDialog(_availableAppUpdate!);
                }
              },
              onDismiss: _dismissAppUpdate,
            ),
            if (_showContextualHelp)
              ContextualHelpBar(helpText: _contextualHelpText),
            if (kDebugMode && _showDebugPanel)
              DebugPanel(
                onDismiss: () {
                  setState(() {
                    _showDebugPanel = false;
                  });
                  SettingsService().setShowDebugPanel(false);
                },
              ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
        floatingActionButton: _buildFloatingActionButton(),
        bottomNavigationBar: _buildBottomAppBar(),
      );
    }

    return Shortcuts(
      shortcuts: _keyBindingService.globalShortcuts,
      child: Actions(
        actions: _keyBindingService.buildGlobalActions(
          onSavePreset: () {
            cubit.requireDisting().requestSavePreset();
            SemanticsService.sendAnnouncement(
              View.of(context),
              'Preset saved',
              TextDirection.ltr,
            );
          },
          onNewPreset: () => _handleNewPresetShortcut(cubit),
          onBrowsePresets: () =>
              widget.loading || isOffline ? null : _handleBrowsePresets(cubit),
          onAddAlgorithm: () => _handleAddAlgorithmShortcut(cubit),
          onRefresh: () {
            if (!widget.loading && !isOffline) {
              cubit.refresh();
              SemanticsService.sendAnnouncement(
                View.of(context),
                'Refreshing',
                TextDirection.ltr,
              );
            }
          },
          onShowShortcutHelp: () => _handleShowShortcutHelp(),
          onSwitchToParameters: () {
            setState(() => _currentMode = EditMode.parameters);
            SemanticsService.sendAnnouncement(
              View.of(context),
              'Switched to Parameters mode',
              TextDirection.ltr,
            );
          },
          onSwitchToRouting: () {
            setState(() => _currentMode = EditMode.routing);
            SemanticsService.sendAnnouncement(
              View.of(context),
              'Switched to Routing mode',
              TextDirection.ltr,
            );
          },
          onSwitchToBoth: () {
            final screenWidth = MediaQuery.of(context).size.width;
            if (_canShowSplitScreen(screenWidth)) {
              setState(() => _currentMode = EditMode.both);
              SemanticsService.sendAnnouncement(
                View.of(context),
                'Switched to Split View mode',
                TextDirection.ltr,
              );
            }
          },
          onPreviousSlot: () {
            if (widget.slots.isNotEmpty && _selectedIndex > 0) {
              final newIndex = _selectedIndex - 1;
              setState(() {
                _selectedIndex = newIndex;
                _tabController.animateTo(newIndex);
              });
              _syncSelectionToRouting(newIndex);
              SemanticsService.sendAnnouncement(
                View.of(context),
                'Slot ${newIndex + 1}: ${widget.slots[newIndex].algorithm.name} selected',
                TextDirection.ltr,
              );
            }
          },
          onNextSlot: () {
            if (widget.slots.isNotEmpty &&
                _selectedIndex < widget.slots.length - 1) {
              final newIndex = _selectedIndex + 1;
              setState(() {
                _selectedIndex = newIndex;
                _tabController.animateTo(newIndex);
              });
              _syncSelectionToRouting(newIndex);
              SemanticsService.sendAnnouncement(
                View.of(context),
                'Slot ${newIndex + 1}: ${widget.slots[newIndex].algorithm.name} selected',
                TextDirection.ltr,
              );
            }
          },
        ),
        child: Focus(
          focusNode: _screenFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: BlocProvider.value(value: routingCubit, child: scaffold),
        ),
      ),
    );
  }

  Future<void> _handleShowShortcutHelp() async {
    if (_isShortcutHelpOpen) return;
    _isShortcutHelpOpen = true;
    try {
      await showDialog(
        context: context,
        builder: (_) => const ShortcutHelpOverlay(),
      );
    } finally {
      _isShortcutHelpOpen = false;
    }
  }

  void _handleNewPresetShortcut(DistingCubit cubit) {
    if (widget.loading) return;
    cubit.newPreset();
    SemanticsService.sendAnnouncement(
      View.of(context),
      'New preset created',
      TextDirection.ltr,
    );
  }

  Future<void> _handleAddAlgorithmShortcut(DistingCubit cubit) async {
    if (_isAddAlgorithmOpen) return;
    _isAddAlgorithmOpen = true;
    try {
      final view = View.of(context);
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
              value: cubit, child: const AddAlgorithmScreen()),
        ),
      );

      if (result != null && result is Map) {
        await cubit.onAlgorithmSelected(
          result['algorithm'],
          result['specValues'],
        );
        SemanticsService.sendAnnouncement(
          view,
          'Algorithm added',
          TextDirection.ltr,
        );
      }
    } finally {
      _isAddAlgorithmOpen = false;
    }
  }

  Future<void> _handleBrowsePresets(DistingCubit cubit) async {
    if (_isBrowsePresetsOpen) return;
    _isBrowsePresetsOpen = true;
    try {
      final currentState = cubit.state;
      if (currentState is DistingStateSynchronized && context.mounted) {
        final midiManager = cubit.disting();
        if (midiManager != null) {
          final prefs = await SharedPreferences.getInstance();
          if (!mounted) return;
          final presetInfo = await showDialog(
            context: context,
            builder: (context) => BlocProvider(
              create: (context) =>
                  PresetBrowserCubit(midiManager: midiManager, prefs: prefs),
              child: PresetBrowserDialog(distingCubit: cubit),
            ),
          );
          if (presetInfo != null && presetInfo is Map) {
            final sdCardPath = presetInfo['sdCardPath'];
            final action = presetInfo['action'] as PresetAction?;
            if (sdCardPath != null && sdCardPath.isNotEmpty && action != null) {
              switch (action) {
                case PresetAction.load:
                  cubit.loadPreset(sdCardPath, false);
                  break;
                case PresetAction.append:
                  break;
                case PresetAction.export:
                  break;
              }
            }
          }
        }
      }
    } finally {
      _isBrowsePresetsOpen = false;
    }
  }

  Widget _buildSplitView() {
    const double dividerWidth = 8.0;
    const double minPaneWidth = 500.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - dividerWidth;
        final minFraction = minPaneWidth / availableWidth;
        final maxFraction = (1.0 - minFraction).clamp(minFraction, 1.0);
        final clampedPosition =
            _splitDividerPosition.clamp(minFraction, maxFraction);
        final leftFlex = (clampedPosition * 1000).round();
        final rightFlex = ((1.0 - clampedPosition) * 1000).round();

        return Row(
          children: [
            Expanded(
              flex: leftFlex,
              child: _buildWideScreenBody(),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    final newPosition = _splitDividerPosition +
                        details.delta.dx / availableWidth;
                    _splitDividerPosition =
                        newPosition.clamp(minFraction, maxFraction);
                  });
                },
                onHorizontalDragEnd: (_) {
                  SettingsService()
                      .setSplitDividerPosition(_splitDividerPosition);
                },
                child: Container(
                  width: dividerWidth,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: rightFlex,
              child: _cachedRoutingCanvas,
            ),
          ],
        );
      },
    );
  }

  Widget _buildWideScreenBody() {
    return Row(
      children: [
        // Left side algorithm list
        Container(
          width: 250,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: AlgorithmListView(
            slots: widget.slots,
            selectedIndex: _selectedIndex,
            onSelectionChanged: (index) {
              setState(() {
                _selectedIndex = index;
                _tabController.animateTo(index);
              });
              _syncSelectionToRouting(index);
            },
            onHelpTextChanged: _showContextualHelp
                ? (text) => setState(() => _contextualHelpText = text)
                : null,
            onMoveUp: widget.loading
                ? null
                : (index) async {
                    final cubit = context.read<DistingCubit>();
                    final newIndex = await cubit.moveAlgorithmUp(index);
                    setState(() {
                      _selectedIndex = newIndex;
                    });
                    _tabController.animateTo(newIndex);
                    return newIndex;
                  },
            onMoveDown: widget.loading
                ? null
                : (index) async {
                    final cubit = context.read<DistingCubit>();
                    final currentState = cubit.state;
                    int slotCount = 0;
                    if (currentState is DistingStateSynchronized) {
                      slotCount = currentState.slots.length;
                    }
                    if (index < slotCount - 1) {
                      final newIndex = await cubit.moveAlgorithmDown(index);
                      setState(() {
                        _selectedIndex = newIndex;
                      });
                      _tabController.animateTo(newIndex);
                      return newIndex;
                    }
                    return index;
                  },
            onDelete: widget.loading
                ? null
                : (index) {
                    final cubit = context.read<DistingCubit>();
                    cubit.onRemoveAlgorithm(index);
                  },
          ),
        ),
        // Right side content
        Expanded(
          child: widget.slots.isNotEmpty
              ? IndexedStack(
                  index: _selectedIndex,
                  children: widget.slots.mapIndexed((index, slot) {
                    return SlotDetailView(
                      key: ValueKey("$index - ${slot.algorithm.guid}"),
                      slot: slot,
                      slotIndex: index,
                      units: widget.units,
                      firmwareVersion: widget.firmwareVersion,
                      sectionController: _sectionController,
                    );
                  }).toList(),
                )
              : Center(
                  child: Text(
                    "No algorithms",
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Builder(
      builder: (context) {
        return FloatingActionButton.small(
          tooltip: "Add Algorithm to Preset",
          onPressed: () async {
            final cubit = context.read<DistingCubit>();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: cubit,
                  child: const AddAlgorithmScreen(),
                ),
              ),
            );

            if (result != null && result is Map) {
              await cubit.onAlgorithmSelected(
                result['algorithm'],
                result['specValues'],
              );
              SemanticsService.sendAnnouncement(
                WidgetsBinding.instance.platformDispatcher.views.first,
                'Algorithm added',
                TextDirection.ltr,
              );
            }
          },
          child: Icon(
            Icons.add_circle_rounded,
            semanticLabel: 'Add Algorithm to Preset',
          ),
        );
      },
    );
  }

  Widget _buildRoutingCanvas() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with routing controls
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
                builder: (context, state) {
                  final isMobile = _platformService.isMobilePlatform();
                  final buttonStyle = isMobile
                      ? const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
                        )
                      : null;
                  return Row(
                    children: [
                      // Zoom controls
                      if (state is RoutingEditorStateLoaded) ...[
                        IconButton(
                          onPressed: () =>
                              context.read<RoutingEditorCubit>().zoomOut(),
                          icon: const Icon(
                            Icons.zoom_out,
                            semanticLabel: 'Zoom out',
                          ),
                          tooltip: 'Zoom out (Ctrl/Cmd + -)',
                          style: buttonStyle,
                        ),
                        Container(
                          constraints: BoxConstraints(
                            minWidth: isMobile ? 60 : 80,
                          ),
                          child: DropdownButton<double>(
                            value: _findClosestZoomLevel(state.zoomLevel),
                            onChanged: (value) {
                              if (value != null) {
                                context.read<RoutingEditorCubit>().setZoomLevel(
                                  value,
                                );
                              }
                            },
                            items: RoutingEditorCubit.availableZoomLevels.map((
                              zoom,
                            ) {
                              return DropdownMenuItem<double>(
                                value: zoom,
                                child: Text('${(zoom * 100).round()}%'),
                              );
                            }).toList(),
                            underline: const SizedBox.shrink(),
                            isDense: true,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              context.read<RoutingEditorCubit>().zoomIn(),
                          icon: const Icon(
                            Icons.zoom_in,
                            semanticLabel: 'Zoom in',
                          ),
                          tooltip: 'Zoom in (Ctrl/Cmd + +)',
                          style: buttonStyle,
                        ),
                        IconButton(
                          onPressed: () =>
                              context.read<RoutingEditorCubit>().resetZoom(),
                          icon: const Icon(
                            Icons.zoom_out_map,
                            semanticLabel: 'Reset zoom',
                          ),
                          tooltip: 'Reset zoom (100%)',
                          style: buttonStyle,
                        ),
                        SizedBox(width: isMobile ? 4 : 8),
                        Container(
                          height: 24,
                          width: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        SizedBox(width: isMobile ? 4 : 8),
                      ],
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          semanticLabel: 'Refresh Routing',
                        ),
                        style: buttonStyle,
                        onPressed: state.maybeWhen(
                          loaded:
                              (
                                physicalInputs,
                                physicalOutputs,
                                es5Inputs,
                                algorithms,
                                connections,
                                buses,
                                portOutputModes,
                                nodePositions,
                                zoomLevel,
                                panOffset,
                                isHardwareSynced,
                                isPersistenceEnabled,
                                lastSyncTime,
                                lastPersistTime,
                                lastError,
                                subState,
                                focusedAlgorithmIds,
                                cascadeScrollTarget,
                                auxBusUsage,
                                hasExtendedAuxBuses,
                              ) => () {
                                context
                                    .read<RoutingEditorCubit>()
                                    .refreshRouting();
                              },
                          orElse: () => null,
                        ),
                        tooltip: 'Refresh Routing',
                      ),
                      // Layout Algorithm Button
                      state.maybeWhen(
                        loaded:
                            (
                              physicalInputs,
                              physicalOutputs,
                              es5Inputs,
                              algorithms,
                              connections,
                              buses,
                              portOutputModes,
                              nodePositions,
                              zoomLevel,
                              panOffset,
                              isHardwareSynced,
                              isPersistenceEnabled,
                              lastSyncTime,
                              lastPersistTime,
                              lastError,
                              subState,
                              focusedAlgorithmIds,
                              cascadeScrollTarget,
                              auxBusUsage,
                              hasExtendedAuxBuses,
                            ) {
                              // Show loading during layout calculation
                              if (subState == SubState.syncing) {
                                return IconButton(
                                  icon: const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  onPressed: null,
                                  tooltip: 'Calculating Layout...',
                                  style: buttonStyle,
                                );
                              }

                              // Show normal layout button
                              return IconButton(
                                icon: const Icon(
                                  Icons.auto_fix_high,
                                  semanticLabel: 'Apply Layout Algorithm',
                                ),
                                onPressed: () {
                                  context
                                      .read<RoutingEditorCubit>()
                                      .applyLayoutAlgorithm();
                                },
                                tooltip: 'Apply Layout Algorithm',
                                style: buttonStyle,
                              );
                            },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      // Optimize AUX Buses
                      state.maybeWhen(
                        loaded:
                            (
                              physicalInputs,
                              physicalOutputs,
                              es5Inputs,
                              algorithms,
                              connections,
                              buses,
                              portOutputModes,
                              nodePositions,
                              zoomLevel,
                              panOffset,
                              isHardwareSynced,
                              isPersistenceEnabled,
                              lastSyncTime,
                              lastPersistTime,
                              lastError,
                              subState,
                              focusedAlgorithmIds,
                              cascadeScrollTarget,
                              auxBusUsage,
                              hasExtendedAuxBuses,
                            ) {
                              return IconButton(
                                icon: const Icon(
                                  Icons.compress,
                                  semanticLabel: 'Optimize Buses',
                                ),
                                onPressed: () async {
                                  final cubit = context
                                      .read<RoutingEditorCubit>();
                                  final plan = cubit.buildConsolidationPlan();
                                  if (plan == null) {
                                    if (context.mounted) {
                                      _editorController.showError(
                                        'No AUX buses can be consolidated',
                                      );
                                    }
                                    return;
                                  }
                                  if (!context.mounted) return;
                                  await showDialog(
                                    context: context,
                                    builder: (_) => ConsolidateBusesDialog(
                                      plan: plan,
                                      cubit: cubit,
                                    ),
                                  );
                                },
                                tooltip: 'Optimize AUX Buses',
                                style: buttonStyle,
                              );
                            },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      // Center View
                      IconButton(
                        icon: const Icon(
                          Icons.center_focus_strong,
                          semanticLabel: 'Center View',
                        ),
                        onPressed: () => _editorController.fitToView(),
                        tooltip: 'Center View',
                        style: buttonStyle,
                      ),

                      // Share/Copy Nodes Image (tight bounds, 24px margin)
                      IconButton(
                        icon: Icon(
                          isMobile ? Icons.share : Icons.image_outlined,
                          semanticLabel: isMobile
                              ? 'Share Nodes Image'
                              : 'Copy Nodes Image',
                        ),
                        onPressed: () {
                          if (isMobile) {
                            _editorController.shareNodesImage();
                          } else {
                            _editorController.copyNodesImage();
                          }
                        },
                        tooltip: isMobile
                            ? 'Share Nodes Image'
                            : 'Copy Nodes Image',
                        style: buttonStyle,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Routing Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return RoutingEditorWidget(
                  controller: _editorController,
                  canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
                  showPhysicalPorts: true,
                  onConnectionCreated: (source, target) {
                    context.read<RoutingEditorCubit>().createConnection(
                      sourcePortId: source,
                      targetPortId: target,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _canShowSplitScreen(double width) {
    return !_platformService.isMobilePlatform() && width >= 1008;
  }

  BottomAppBar _buildBottomAppBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenWidth > 900;
    bool isMobile = _platformService.isMobilePlatform();

    return BottomAppBar(
      child: Row(
        children: [
          // Left side - Mode switcher
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SegmentedButton<EditMode>(
              multiSelectionEnabled: true,
              emptySelectionAllowed: false,
              segments: [
                ButtonSegment(
                  value: EditMode.parameters,
                  label: isWideScreen ? const Text('Parameters') : null,
                  icon: const Icon(Icons.tune, semanticLabel: 'Parameters'),
                  tooltip: 'Parameters mode',
                ),
                ButtonSegment(
                  value: EditMode.routing,
                  label: isWideScreen ? const Text('Routing') : null,
                  icon: const Icon(
                    Icons.account_tree,
                    semanticLabel: 'Routing',
                  ),
                  tooltip: 'Routing mode',
                ),
              ],
              selected: _currentMode == EditMode.both
                  ? {EditMode.parameters, EditMode.routing}
                  : {_currentMode},
              onSelectionChanged: (Set<EditMode> modes) {
                setState(() {
                  if (modes.length == 2 && _canShowSplitScreen(screenWidth)) {
                    _currentMode = EditMode.both;
                  } else if (modes.length == 2) {
                    // Can't split - keep only the newly clicked one
                    final newMode = modes.firstWhere(
                      (m) =>
                          m !=
                          (_currentMode == EditMode.both
                              ? EditMode.parameters
                              : _currentMode),
                      orElse: () => modes.first,
                    );
                    _currentMode = newMode;
                  } else if (modes.length == 1) {
                    _currentMode = modes.first;
                  }
                });
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.comfortable,
              ),
            ),
          ),

          const SizedBox(width: 24),

          BlocBuilder<DistingCubit, DistingState>(
            buildWhen: (previous, current) {
              final prevOffline = previous is DistingStateSynchronized &&
                  previous.offline;
              final currOffline = current is DistingStateSynchronized &&
                  current.offline;
              return prevOffline != currOffline;
            },
            builder: (context, state) {
              final isOffline = switch (state) {
                DistingStateSynchronized(offline: final o) => o,
                _ => false,
              };

              if (isOffline) {
                // Show "Offline Data" button when offline
                return IconButton(
                  tooltip: "Offline Data",
                  icon: const Icon(
                    Icons.sync_alt_rounded,
                    semanticLabel: 'Offline Data',
                  ),
                  onPressed: () {
                    final distingCubit = context.read<DistingCubit>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MetadataSyncPage(distingCubit: distingCubit),
                      ),
                    );
                  },
                );
              } else {
                // Show platform-adaptive view mode buttons when online
                return isMobile
                    ? Semantics(
                        label: 'View Options',
                        hint: 'Opens display mode menu',
                        button: true,
                        child: IconButton(
                          tooltip: "View Options",
                          icon: const Icon(
                            Icons.view_list,
                            semanticLabel: 'View Options',
                          ),
                          onPressed: () => _showDisplayModeBottomSheet(context),
                        ),
                      )
                    : Row(
                        children: [
                          IconButton(
                            tooltip: "Parameter View",
                            onPressed: () {
                              context.read<DistingCubit>().setDisplayMode(
                                DisplayMode.parameters,
                              );
                            },
                            icon: const Icon(
                              Icons.list_alt_rounded,
                              semanticLabel: 'Parameter View',
                            ),
                          ),
                          IconButton(
                            tooltip: "Algorithm UI",
                            onPressed: () {
                              context.read<DistingCubit>().setDisplayMode(
                                DisplayMode.algorithmUI,
                              );
                            },
                            icon: const Icon(
                              Icons.line_axis_rounded,
                              semanticLabel: 'Algorithm UI',
                            ),
                          ),
                          IconButton(
                            tooltip: "Overview UI",
                            onPressed: () {
                              context.read<DistingCubit>().setDisplayMode(
                                DisplayMode.overview,
                              );
                            },
                            icon: const Icon(
                              Icons.line_weight_rounded,
                              semanticLabel: 'Overview UI',
                            ),
                          ),
                          IconButton(
                            tooltip: "Overview VU Meters",
                            onPressed: () {
                              context.read<DistingCubit>().setDisplayMode(
                                DisplayMode.overviewVUs,
                              );
                            },
                            icon: const Icon(
                              Icons.leaderboard_rounded,
                              semanticLabel: 'Overview VU Meters',
                            ),
                          ),
                        ],
                      );
              }
            },
          ),

          const Spacer(),

          // MCP server status indicator (desktop only)
          if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
            ChangeNotifierProvider.value(
              value: McpServerService.instance,
              child: Consumer<McpServerService>(
                builder: (context, mcpService, child) {
                  return const McpStatusIndicator();
                },
              ),
            ),
          const SizedBox(width: 8),
          // Only show version on tablets and desktop, not mobile
          if (!isMobile)
            BlocBuilder<DistingCubit, DistingState>(
              buildWhen: (previous, current) {
                // Only rebuild when availableFirmwareUpdate changes
                final prevUpdate = previous is DistingStateSynchronized
                    ? previous.availableFirmwareUpdate
                    : null;
                final currUpdate = current is DistingStateSynchronized
                    ? current.availableFirmwareUpdate
                    : null;
                return prevUpdate != currUpdate;
              },
              builder: (context, state) {
                final updateAvailable = state is DistingStateSynchronized
                    ? state.availableFirmwareUpdate
                    : null;
                final isDesktop =
                    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Firmware update indicator (desktop only)
                    if (updateAvailable != null && isDesktop)
                      Tooltip(
                        message:
                            'Update available: v${updateAvailable.version}',
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_circle_up,
                            semanticLabel:
                                'Firmware update available: v${updateAvailable.version}',
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            final distingCubit = context.read<DistingCubit>();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FirmwareUpdateScreen(
                                  distingCubit: distingCubit,
                                ),
                              ),
                            );
                          },
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    if (updateAvailable != null && isDesktop)
                      const SizedBox(width: 4),
                    DistingVersion(
                      distingVersion: widget.distingVersion,
                      requiredVersion: Constants.requiredDistingVersion,
                      onTap: isDesktop
                          ? () {
                              final distingCubit = context.read<DistingCubit>();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FirmwareUpdateScreen(
                                    distingCubit: distingCubit,
                                  ),
                                ),
                              );
                            }
                          : null,
                      onHelpTextChanged: _showContextualHelp && isDesktop
                          ? (text) => setState(() => _contextualHelpText = text)
                          : null,
                    ),
                  ],
                );
              },
            ),
          // CPU Monitor Widget - only in wide-screen mode
          if (isWideScreen) ...[
            const SizedBox(width: 16),
            const CpuMonitorWidget(),
          ],
          // Spacer for FAB so it doesn't cover the version/CPU info
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  void _showDisplayModeBottomSheet(BuildContext context) {
    // Capture the cubit instance before the builder (bottom sheet creates new overlay route)
    final distingCubit = context.read<DistingCubit>();
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBottomSheetHeader(),
              _buildDisplayModeOption(
                distingCubit,
                sheetContext,
                icon: Icons.list_alt_rounded,
                title: 'Parameter View',
                subtitle: 'Hardware parameter list',
                mode: DisplayMode.parameters,
              ),
              _buildDisplayModeOption(
                distingCubit,
                sheetContext,
                icon: Icons.line_axis_rounded,
                title: 'Algorithm UI',
                subtitle: 'Custom algorithm interface',
                mode: DisplayMode.algorithmUI,
              ),
              _buildDisplayModeOption(
                distingCubit,
                sheetContext,
                icon: Icons.line_weight_rounded,
                title: 'Overview UI',
                subtitle: 'All slots overview',
                mode: DisplayMode.overview,
              ),
              _buildDisplayModeOption(
                distingCubit,
                sheetContext,
                icon: Icons.leaderboard_rounded,
                title: 'Overview VU Meters',
                subtitle: 'VU meter display',
                mode: DisplayMode.overviewVUs,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisplayModeOption(
    DistingCubit distingCubit,
    BuildContext sheetContext, {
    required IconData icon,
    required String title,
    required String subtitle,
    required DisplayMode mode,
  }) {
    return Semantics(
      label: '$title. $subtitle',
      button: true,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () {
          Navigator.pop(sheetContext);
          distingCubit.setDisplayMode(mode);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
    );
  }

  Widget _buildBottomSheetHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hardware Display Mode',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (widget.slots.isNotEmpty) {
      return TabBarView(
        controller: _tabController,
        children: widget.slots.mapIndexed((index, slot) {
          return SlotDetailView(
            key: ValueKey("$index - ${slot.algorithm.guid}"),
            slot: slot,
            slotIndex: index,
            units: widget.units,
            firmwareVersion: widget.firmwareVersion,
            sectionController: _sectionController,
          );
        }).toList(),
      );
    }
    return Center(
      child: Semantics(
        liveRegion: true,
        child: Text(
          "No algorithms in preset. Tap the + button to add one.",
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isWideScreen) {
    final cubit = context.read<DistingCubit>();
    return AppBar(
      title: const Text('NT Helper'),
      titleTextStyle: Theme.of(context).textTheme.titleLarge,
      actions: _buildAppBarActions(cubit),
      elevation: 0,
      scrolledUnderElevation: 0,
      notificationPredicate: (ScrollNotification notification) =>
          notification.depth == 1,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(
          66.0, // Consistent height for both modes
        ),
        child: Column(
          children: [
            _buildPresetInfoEditor(context), // The preset info
            // Always reserve space for tab bar to prevent jumping
            SizedBox(
              height: 26.0,
              child: !isWideScreen && _currentMode == EditMode.parameters
                  ? _buildTabBar(context)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(DistingCubit cubit) {
    final isOffline = switch (cubit.state) {
      DistingStateSynchronized(offline: final o) => o,
      _ => false,
    };

    return [
      // Refresh: Only disabled by loading OR offline
      IconButton(
        icon: const Icon(Icons.refresh_rounded, semanticLabel: 'Refresh'),
        tooltip: 'Refresh',
        onPressed: widget.loading || isOffline
            ? null
            : () {
                cubit.refresh();
              },
      ),
      // Mode-specific actions with AnimatedSwitcher
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: _buildModeSpecificActions(cubit),
      ),
      // Overflow menu
      _buildOverflowMenu(cubit),
    ];
  }

  Widget _buildModeSpecificActions(DistingCubit cubit) {
    return Row(
      key: ValueKey(_currentMode),
      mainAxisSize: MainAxisSize.min,
      children: switch (_currentMode) {
        EditMode.parameters => _buildParameterModeActions(cubit),
        EditMode.routing => _buildRoutingModeActions(),
        EditMode.both => [
          ..._buildParameterModeActions(cubit),
          ..._buildRoutingModeActions(),
        ],
      },
    );
  }

  List<Widget> _buildParameterModeActions(DistingCubit cubit) {
    return [
      // Move Up
      Builder(
        builder: (ctx) {
          return IconButton(
            icon: const Icon(
              Icons.arrow_upward_rounded,
              semanticLabel: 'Move Algorithm Up',
            ),
            tooltip: 'Move Algorithm Up',
            onPressed: widget.loading
                ? null
                : () async {
                    final newIndex = await cubit.moveAlgorithmUp(
                      _selectedIndex,
                    );
                    setState(() {
                      _selectedIndex = newIndex;
                    });
                    _tabController.animateTo(newIndex);
                  },
          );
        },
      ),
      // Move Down
      Builder(
        builder: (ctx) {
          return IconButton(
            icon: const Icon(
              Icons.arrow_downward_rounded,
              semanticLabel: 'Move Algorithm Down',
            ),
            tooltip: 'Move Algorithm Down',
            onPressed: widget.loading
                ? null
                : () async {
                    final currentState = cubit.state;
                    int slotCount = 0;
                    if (currentState is DistingStateSynchronized) {
                      slotCount = currentState.slots.length;
                    }
                    if (_selectedIndex < slotCount - 1) {
                      final newIndex = await cubit.moveAlgorithmDown(
                        _selectedIndex,
                      );
                      setState(() {
                        _selectedIndex = newIndex;
                      });
                      _tabController.animateTo(newIndex);
                    }
                  },
          );
        },
      ),
      // Remove Algorithm
      Builder(
        builder: (ctx) {
          return IconButton(
            icon: const Icon(
              Icons.delete_forever_rounded,
              semanticLabel: 'Remove Algorithm',
            ),
            tooltip: 'Remove Algorithm',
            onPressed: widget.loading
                ? null
                : () async {
                    cubit.onRemoveAlgorithm(_selectedIndex);
                  },
          );
        },
      ),
    ];
  }

  List<Widget> _buildRoutingModeActions() {
    return [
      // Placeholder for future routing actions
    ];
  }

  Widget _buildOverflowMenu(DistingCubit cubit) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, semanticLabel: 'More options'),
      itemBuilder: (popupCtx) {
        // Get offline status here for menu items that need it
        final isOffline = switch (cubit.state) {
          DistingStateSynchronized(offline: final o) => o,
          _ => false,
        };
        return [
          PopupMenuItem(
            value: "wake",
            enabled: !widget.loading && !isOffline,
            onTap: widget.loading || isOffline
                ? null
                : () {
                    cubit.requireDisting().requestWake();
                  },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Wake Display'), Icon(Icons.alarm_on_rounded)],
            ),
          ),
          PopupMenuItem(
            value: "browse",
            enabled: !widget.loading && !isOffline,
            onTap: widget.loading || isOffline
                ? null
                : () async {
                    final currentState = cubit.state;
                    final isMounted = context.mounted;
                    if (currentState is DistingStateSynchronized && isMounted) {
                      final midiManager = cubit.disting();
                      if (midiManager != null) {
                        final prefs = await SharedPreferences.getInstance();
                        // ignore: use_build_context_synchronously
                        var presetInfo = await showDialog(
                          // ignore: use_build_context_synchronously
                          context: popupCtx,
                          builder: (context) => BlocProvider(
                            create: (context) => PresetBrowserCubit(
                              midiManager: midiManager,
                              prefs: prefs,
                            ),
                            child: PresetBrowserDialog(distingCubit: cubit),
                          ),
                        );
                        if (presetInfo != null && presetInfo is Map) {
                          final sdCardPath = presetInfo['sdCardPath'];
                          final action = presetInfo['action'] as PresetAction?;
                          if (sdCardPath != null &&
                              sdCardPath.isNotEmpty &&
                              action != null) {
                            switch (action) {
                              case PresetAction.load:
                                cubit.loadPreset(sdCardPath, false);
                                break;
                              case PresetAction.append:
                                // Append is not directly supported, could be handled differently
                                break;
                              case PresetAction.export:
                                // Export is not applicable for browse
                                break;
                            }
                          }
                        }
                      }
                    }
                  },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Browse Presets'), Icon(Icons.folder_open)],
            ),
          ),

          PopupMenuItem(
            value: "new",
            enabled: !widget.loading,
            onTap: widget.loading
                ? null
                : () async {
                    final currentState = cubit.state;
                    bool hasAlgorithms = false;

                    if (currentState is DistingStateSynchronized) {
                      hasAlgorithms = currentState.slots.isNotEmpty;
                    }

                    if (hasAlgorithms) {
                      // Show confirmation dialog
                      final result = await showDialog<String>(
                        context:
                            popupCtx, // Use the context from the PopupMenuItem
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Create New Preset?'),
                          content: const Text(
                            'The current preset has algorithms. Creating a new preset will clear them.\n\nWould you like to save the current preset first?',
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop('cancel');
                              },
                            ),
                            TextButton(
                              child: const Text('Discard & New'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop('new_discard');
                              },
                            ),
                            TextButton(
                              child: const Text('Save First & New'),
                              onPressed: () {
                                Navigator.of(
                                  dialogContext,
                                ).pop('save_first_new');
                              },
                            ),
                          ],
                        ),
                      );

                      if (result == 'new_discard') {
                        cubit.newPreset();
                      } else if (result == 'save_first_new') {
                        cubit.requireDisting().requestSavePreset();
                        // It's generally okay to call newPreset() immediately after
                        // requestSavePreset() for MIDI operations. The device handles
                        // commands sequentially.
                        cubit.newPreset();
                      }
                      // If 'cancel' or dialog dismissed, do nothing.
                    } else {
                      // No algorithms, proceed directly
                      cubit.newPreset();
                    }
                  },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('New Preset'), Icon(Icons.fiber_new_rounded)],
            ),
          ),
          PopupMenuItem(
            value: "save",
            enabled: !widget.loading,
            onTap: widget.loading
                ? null
                : () {
                    cubit.requireDisting().requestSavePreset();
                  },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Save Preset'), Icon(Icons.save_alt_rounded)],
            ),
          ),
          // Video: Disabled by loading OR offline
          PopupMenuItem(
            value: 'screenshot',
            enabled: !widget.loading && !isOffline,
            onTap: widget.loading || isOffline
                ? null
                : () {
                    _showScreenshotOverlay(popupCtx);
                  },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Video'), Icon(Icons.videocam)],
            ),
          ),
          // Perform: Disabled by loading OR offline
          PopupMenuItem(
            value: 'perform',
            enabled: !widget.loading && !isOffline,
            onTap: widget.loading || isOffline
                ? null
                : () {
                    final midiListener = popupCtx.read<MidiListenerCubit>();
                    Navigator.push(
                      popupCtx,
                      MaterialPageRoute(
                        builder: (_) => MultiBlocProvider(
                          providers: [
                            BlocProvider.value(value: cubit),
                            BlocProvider.value(value: midiListener),
                          ],
                          child: PerformanceScreen(units: widget.units),
                        ),
                      ),
                    );
                  },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Perform'), Icon(Icons.library_music)],
            ),
          ),
          // Plugin Manager: Always enabled
          PopupMenuItem(
            value: 'plugin_manager',
            enabled: !widget.loading,
            onTap: widget.loading
                ? null
                : () {
                    final distingCubit = popupCtx.read<DistingCubit>();
                    Navigator.push(
                      popupCtx,
                      MaterialPageRoute(
                        builder: (_) => PluginManagerScreen(
                          distingCubit: distingCubit,
                          database: distingCubit.database,
                        ),
                      ),
                    );
                  },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Plugin Manager'), Icon(Icons.extension_rounded)],
            ),
          ),
          // Switch Devices: Only disabled by loading (Fix context usage)
          PopupMenuItem(
            value: 'Switch Devices',
            enabled: !widget.loading,
            onTap: widget.loading
                ? null
                : () {
                    popupCtx.read<DistingCubit>().goOnline();
                  },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Switch'), Icon(Icons.login_rounded)],
            ),
          ),
          // Settings: Only disabled by loading
          PopupMenuItem(
            value: 'Settings',
            enabled: !widget.loading,
            onTap: widget.loading
                ? null
                : () async {
                    // Get the midi manager and algorithms for RTT stats
                    final cubit = popupCtx.read<DistingCubit>();
                    final state = cubit.state;
                    final midiManager =
                        state is DistingStateSynchronized && !state.offline
                        ? cubit.requireDisting()
                        : null;
                    final algorithms = state is DistingStateSynchronized
                        ? state.algorithms
                        : null;
                    // Original call to show the dialog
                    final result = await popupCtx.showSettingsDialog(
                      midiManager: midiManager,
                      algorithms: algorithms,
                    );

                    // Logic copied and adapted from _DistingPageState._handleSettingsDialog
                    if (result == true && popupCtx.mounted) {
                      // Ensure context is still valid
                      final settings = SettingsService();
                      final mcpInstance = McpServerService.instance;
                      final bool isMcpEnabledAfterDialog = settings.mcpEnabled;
                      final bool isServerStillRunningBeforeAction =
                          mcpInstance.isRunning;

                      if (Platform.isMacOS ||
                          Platform.isWindows ||
                          Platform.isLinux) {
                        final bindAddress = settings.mcpRemoteConnections
                            ? InternetAddress.anyIPv4
                            : InternetAddress.loopbackIPv4;
                        if (isMcpEnabledAfterDialog) {
                          if (!isServerStillRunningBeforeAction) {
                            await mcpInstance.start(bindAddress: bindAddress).catchError((e) {});
                          } else {
                            if (mcpInstance.boundAddress?.address != bindAddress.address) {
                              await mcpInstance.restart(bindAddress: bindAddress).catchError((e) {});
                            }
                          }
                        } else {
                          // MCP Setting is OFF
                          if (isServerStillRunningBeforeAction) {
                            await mcpInstance.stop().catchError((e) {});
                          }
                        }
                      }
                    } else {}
                  },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Settings'), Icon(Icons.settings)],
            ),
          ),
          // Sync Metadata: Only disabled by loading
          PopupMenuItem(
            value: 'sync_metadata',
            enabled: !widget.loading,
            onTap: widget.loading
                ? null
                : () {
                    final distingCubit = popupCtx.read<DistingCubit>();
                    Navigator.push(
                      popupCtx,
                      MaterialPageRoute(
                        builder: (_) =>
                            MetadataSyncPage(distingCubit: distingCubit),
                      ),
                    );
                  },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Offline Data'), Icon(Icons.sync_alt_rounded)],
            ),
          ),
          // Firmware: Desktop only, disabled when loading
          if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
            PopupMenuItem(
              value: 'firmware',
              enabled: !widget.loading,
              onTap: widget.loading
                  ? null
                  : () {
                      final distingCubit = popupCtx.read<DistingCubit>();
                      Navigator.push(
                        popupCtx,
                        MaterialPageRoute(
                          builder: (_) =>
                              FirmwareUpdateScreen(distingCubit: distingCubit),
                        ),
                      );
                    },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Firmware'), Icon(Icons.system_update)],
              ),
            ),
          // About: Always enabled (Fix context usage for Theme)
          PopupMenuItem(
            value: 'about',
            enabled: true,
            onTap: widget.loading
                ? null
                : () async {
                    final info = await PackageInfo.fromPlatform();
                    if (!popupCtx.mounted) return;
                    showDialog<String>(
                      context: popupCtx,
                      builder: (dialogCtx) => AboutDialog(
                        applicationName: "NT Helper",
                        applicationVersion:
                            "${info.version} (${info.buildNumber})",
                        applicationLegalese:
                            "Written by Neal Sanche (Thorinside), 2026, No Rights Reserved.",
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Text(
                                  "Disting Firmware: ${widget.distingVersion}",
                                  style: Theme.of(
                                    dialogCtx,
                                  ).textTheme.bodySmall,
                                ),
                                if (Platform.isMacOS ||
                                    Platform.isLinux ||
                                    Platform.isWindows) ...[
                                  const SizedBox(height: 16),
                                  _UpdateCheckButton(
                                    onUpdateFound: (release) {
                                      Navigator.of(dialogCtx).pop();
                                      _showAppUpdateDialog(release);
                                    },
                                    updateService: _appUpdateService ??=
                                        AppUpdateService(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
            child: const Text('About'),
          ),
        ];
      },
    );
  }

  Padding _buildPresetInfoEditor(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: 'Preset: ${widget.presetName.trim()}',
            hint: 'Double tap to rename preset',
            child: InkWell(
              onTap: () async {
                var cubit = context.read<DistingCubit>();

                final newName = await showDialog<String>(
                  context: context,
                  builder: (context) =>
                      RenamePresetDialog(initialName: widget.presetName),
                );

                if (newName != null &&
                    newName.isNotEmpty &&
                    newName != widget.presetName) {
                  cubit.renamePreset(newName);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Preset:\u2007',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          TextSpan(
                            text: widget.presetName.trim(),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return BlocBuilder<DistingCubit, DistingState>(
      buildWhen: (previous, current) {
        if (previous.runtimeType != current.runtimeType) {
          return true;
        }
        if (previous is! DistingStateSynchronized ||
            current is! DistingStateSynchronized) {
          return true;
        }
        if (previous.slots.length != current.slots.length) {
          return true;
        }
        for (int i = 0; i < previous.slots.length; i++) {
          if (previous.slots[i].algorithm.name !=
              current.slots[i].algorithm.name) {
            return true;
          }
        }
        return false;
      },
      builder: (context, state) {
        return switch (state) {
          DistingStateSynchronized(slots: final syncState) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorAnimation: TabIndicatorAnimation.elastic,
              indicatorWeight: 1,
              enableFeedback: true,
              dividerHeight: 0,
              tabs: List<Widget>.generate(syncState.length, (index) {
                final slot = syncState[index];
                final displayName = slot.algorithm.name;

                return Semantics(
                  label: 'Slot ${index + 1}: $displayName',
                  hint: 'Double tap to select. Long press to rename.',
                  customSemanticsActions: {
                    const CustomSemanticsAction(
                      label: 'Rename algorithm',
                    ): () async {
                      var cubit = context.read<DistingCubit>();
                      final newName = await showDialog<String>(
                        context: context,
                        builder: (dialogCtx) =>
                            RenameSlotDialog(initialName: displayName),
                      );
                      if (newName != null && newName != displayName) {
                        cubit.renameSlot(index, newName);
                      }
                    },
                    const CustomSemanticsAction(
                      label: 'Focus algorithm UI',
                    ): () {
                      var cubit = context.read<DistingCubit>();
                      cubit.disting()?.let((manager) {
                        manager.requestSetFocus(index, 0);
                        manager.requestSetDisplayMode(DisplayMode.algorithmUI);
                      });
                    },
                  },
                  child: MouseRegion(
                    onEnter: (_) {
                      if (_showContextualHelp) {
                        setState(() {
                          _contextualHelpText = _algorithmNameHelpText;
                        });
                      }
                    },
                    onExit: (_) {
                      setState(() {
                        _contextualHelpText = null;
                      });
                    },
                    child: GestureDetector(
                      onDoubleTap: () async {
                        var cubit = context.read<DistingCubit>();
                        cubit.disting()?.let((manager) {
                          manager.requestSetFocus(index, 0);
                          manager.requestSetDisplayMode(
                            DisplayMode.algorithmUI,
                          );
                        });
                        if (SettingsService().hapticsEnabled) {
                          Haptics.vibrate(HapticsType.medium);
                        }
                      },
                      onLongPress: () async {
                        var cubit = context.read<DistingCubit>();
                        final newName = await showDialog<String>(
                          context: context,
                          builder: (dialogCtx) =>
                              RenameSlotDialog(initialName: displayName),
                        );
                        if (newName != null && newName != displayName) {
                          cubit.renameSlot(index, newName);
                        }
                      },
                      child: Tab(text: displayName),
                    ),
                  ),
                );
              }),
            ),
          ),
          _ => const Center(child: Text("Loading slots...")),
        };
      },
    );
  }

  void _showScreenshotOverlay(BuildContext context) {
    final cubit = context.read<DistingCubit>();

    // Create a VideoFrameCubit for this overlay
    final videoFrameCubit = VideoFrameCubit();

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => FloatingVideoOverlay(
        overlayEntry: overlayEntry,
        cubit: cubit,
        videoFrameCubit: videoFrameCubit,
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  double _findClosestZoomLevel(double currentZoom) {
    final levels = RoutingEditorCubit.availableZoomLevels;
    double closest = levels.first;
    double minDifference = (currentZoom - closest).abs();

    for (final level in levels) {
      final difference = (currentZoom - level).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closest = level;
      }
    }

    return closest;
  }
}

class _UpdateCheckButton extends StatefulWidget {
  final void Function(AppRelease release) onUpdateFound;
  final AppUpdateService updateService;

  const _UpdateCheckButton({
    required this.onUpdateFound,
    required this.updateService,
  });

  @override
  State<_UpdateCheckButton> createState() => _UpdateCheckButtonState();
}

class _UpdateCheckButtonState extends State<_UpdateCheckButton> {
  bool _checking = false;
  String? _message;

  Future<void> _check({bool skipVersionCheck = false}) async {
    setState(() {
      _checking = true;
      _message = null;
    });

    final release = await widget.updateService.checkForUpdate(
      forceRefresh: true,
      skipVersionCheck: skipVersionCheck,
    );

    if (!mounted) return;

    if (release != null) {
      widget.onUpdateFound(release);
    } else {
      setState(() {
        _checking = false;
        _message = "You're up to date!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _checking
              ? null
              : () => _check(
                  skipVersionCheck:
                      kDebugMode &&
                      HardwareKeyboard.instance.logicalKeysPressed.any(
                        (k) =>
                            k == LogicalKeyboardKey.shiftLeft ||
                            k == LogicalKeyboardKey.shiftRight,
                      ),
                ),
          icon: _checking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.system_update),
          label: Text(_checking ? 'Checking...' : 'Check for Updates'),
        ),
        const SizedBox(height: 8),
        Visibility(
          visible: _message != null,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Text(
            _message ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
