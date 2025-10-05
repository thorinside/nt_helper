import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:nt_helper/ui/widgets/load_preset_dialog.dart' show PresetAction;
import 'package:nt_helper/ui/widgets/preset_browser_dialog.dart';
import 'package:nt_helper/cubit/preset_browser_cubit.dart';

import 'package:nt_helper/ui/performance_screen.dart';
import 'package:nt_helper/ui/widgets/rename_preset_dialog.dart';
import 'package:nt_helper/ui/widgets/rename_slot_dialog.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_widget.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_controller.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/core/routing/node_layout_algorithm.dart';
import 'package:nt_helper/services/mcp_server_service.dart';
import 'package:nt_helper/services/settings_service.dart';

import 'package:nt_helper/ui/cpu_monitor_widget.dart';
import 'package:nt_helper/ui/metadata_sync/metadata_sync_page.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart';
import 'package:nt_helper/ui/plugin_manager_screen.dart';

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
import 'package:nt_helper/services/debug_service.dart';

enum EditMode { parameters, routing }

class SynchronizedScreen extends StatefulWidget {
  final List<Slot> slots;
  final List<AlgorithmInfo> algorithms;
  final List<String> units;
  final String presetName;
  final String distingVersion;
  final FirmwareVersion firmwareVersion;
  final Uint8List? screenshot;
  final bool loading;

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
  });

  @override
  State<SynchronizedScreen> createState() => _SynchronizedScreenState();
}

class _SynchronizedScreenState extends State<SynchronizedScreen>
    with TickerProviderStateMixin {
  final _platformService = PlatformInteractionService();
  final RoutingEditorController _editorController = RoutingEditorController();
  late int _selectedIndex;
  late TabController _tabController;
  EditMode _currentMode = EditMode.parameters;
  bool _showDebugPanel = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _tabController = TabController(length: widget.slots.length, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Initialize debug service in debug mode
    if (kDebugMode) {
      DebugService().initialize();
      _showDebugPanel = SettingsService().showDebugPanel;
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

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 900;

    // Use a conditional widget based on screen width
    if (isWideScreen && widget.slots.isNotEmpty) {
      // Wide screen layout with vertical list
      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(context, isWideScreen),
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentMode == EditMode.parameters ? 0 : 1,
                children: [_buildWideScreenBody(), _buildRoutingCanvas()],
              ),
            ),
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
      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(context, isWideScreen),
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentMode == EditMode.parameters ? 0 : 1,
                children: [_buildBody(), _buildRoutingCanvas()],
              ),
            ),
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
                      units: widget.units,
                      firmwareVersion: widget.firmwareVersion,
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
            }
          },
          child: Icon(Icons.add_circle_rounded),
        );
      },
    );
  }

  Widget _buildRoutingCanvas() {
    return BlocProvider(
      create: (context) {
        final cubit = RoutingEditorCubit(context.read<DistingCubit>());
        cubit.injectLayoutAlgorithm(NodeLayoutAlgorithm());
        return cubit;
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with routing controls
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BlocBuilder<RoutingEditorCubit, RoutingEditorState>(
                  builder: (context, state) {
                    return Row(
                      children: [
                        // Zoom controls
                        if (state is RoutingEditorStateLoaded) ...[
                          IconButton(
                            onPressed: () =>
                                context.read<RoutingEditorCubit>().zoomOut(),
                            icon: const Icon(Icons.zoom_out),
                            tooltip: 'Zoom out (Ctrl/Cmd + -)',
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 80),
                            child: DropdownButton<double>(
                              value: _findClosestZoomLevel(state.zoomLevel),
                              onChanged: (value) {
                                if (value != null) {
                                  context
                                      .read<RoutingEditorCubit>()
                                      .setZoomLevel(value);
                                }
                              },
                              items: RoutingEditorCubit.availableZoomLevels.map(
                                (zoom) {
                                  return DropdownMenuItem<double>(
                                    value: zoom,
                                    child: Text('${(zoom * 100).round()}%'),
                                  );
                                },
                              ).toList(),
                              underline: const SizedBox.shrink(),
                              isDense: true,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                context.read<RoutingEditorCubit>().zoomIn(),
                            icon: const Icon(Icons.zoom_in),
                            tooltip: 'Zoom in (Ctrl/Cmd + +)',
                          ),
                          IconButton(
                            onPressed: () =>
                                context.read<RoutingEditorCubit>().resetZoom(),
                            icon: const Icon(Icons.zoom_out_map),
                            tooltip: 'Reset zoom (100%)',
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 24,
                            width: 1,
                            color: Theme.of(context).dividerColor,
                          ),
                          const SizedBox(width: 8),
                        ],
                        IconButton(
                          icon: const Icon(Icons.refresh),
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
                                  );
                                }

                                // Show normal layout button
                                return IconButton(
                                  icon: const Icon(Icons.auto_fix_high),
                                  onPressed: () {
                                    context
                                        .read<RoutingEditorCubit>()
                                        .applyLayoutAlgorithm();
                                  },
                                  tooltip: 'Apply Layout Algorithm',
                                );
                              },
                          orElse: () => const SizedBox.shrink(),
                        ),
                        // Center View
                        IconButton(
                          icon: const Icon(Icons.center_focus_strong),
                          onPressed: () => _editorController.fitToView(),
                          tooltip: 'Center View',
                        ),

                        // Copy Nodes Image (tight bounds, 24px margin)
                        IconButton(
                          icon: const Icon(Icons.image_outlined),
                          onPressed: () => _editorController.copyNodesImage(),
                          tooltip: 'Copy Nodes Image',
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
                    canvasSize: Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ),
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
      ),
    );
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
              segments: [
                ButtonSegment(
                  value: EditMode.parameters,
                  label: isWideScreen ? const Text('Parameters') : null,
                  icon: const Icon(Icons.tune),
                ),
                ButtonSegment(
                  value: EditMode.routing,
                  label: isWideScreen ? const Text('Routing') : null,
                  icon: const Icon(Icons.account_tree),
                ),
              ],
              selected: {_currentMode},
              onSelectionChanged: (Set<EditMode> modes) {
                setState(() {
                  _currentMode = modes.first;
                });
              },
              style: const ButtonStyle(
                // Material 3 styling for prominence
                visualDensity: VisualDensity.comfortable,
              ),
            ),
          ),

          const SizedBox(width: 24),

          Builder(
            builder: (context) {
              final isOffline = switch (context.watch<DistingCubit>().state) {
                DistingStateSynchronized(offline: final o) => o,
                _ => false,
              };

              if (isOffline) {
                // Show "Offline Data" button when offline
                return IconButton(
                  tooltip: "Offline Data",
                  icon: const Icon(Icons.sync_alt_rounded),
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
                // Show regular view mode buttons when online
                return Row(
                  children: [
                    IconButton(
                      tooltip: "Parameter View",
                      onPressed: () {
                        context.read<DistingCubit>().setDisplayMode(
                          DisplayMode.parameters,
                        );
                      },
                      icon: const Icon(Icons.list_alt_rounded),
                    ),
                    IconButton(
                      tooltip: "Algorithm UI",
                      onPressed: () {
                        context.read<DistingCubit>().setDisplayMode(
                          DisplayMode.algorithmUI,
                        );
                      },
                      icon: const Icon(Icons.line_axis_rounded),
                    ),
                    IconButton(
                      tooltip: "Overview UI",
                      onPressed: () {
                        context.read<DistingCubit>().setDisplayMode(
                          DisplayMode.overview,
                        );
                      },
                      icon: const Icon(Icons.line_weight_rounded),
                    ),
                    IconButton(
                      tooltip: "Overview VU Meters",
                      onPressed: () {
                        context.read<DistingCubit>().setDisplayMode(
                          DisplayMode.overviewVUs,
                        );
                      },
                      icon: const Icon(Icons.leaderboard_rounded),
                    ),
                  ],
                );
              }
            },
          ),

          const Spacer(),

          // MCP server status indicator (desktop only)
          if (Platform.isMacOS || Platform.isWindows)
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
            DistingVersion(
              distingVersion: widget.distingVersion,
              requiredVersion: Constants.requiredDistingVersion,
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

  Widget _buildBody() {
    if (widget.slots.isNotEmpty) {
      return TabBarView(
        controller: _tabController,
        children: widget.slots.mapIndexed((index, slot) {
          return SlotDetailView(
            key: ValueKey("$index - ${slot.algorithm.guid}"),
            slot: slot,
            units: widget.units,
            firmwareVersion: widget.firmwareVersion,
          );
        }).toList(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "No algorithms",
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isWideScreen) {
    final cubit = context.read<DistingCubit>();
    return AppBar(
      title: const Text('NT Helper'),
      actions: _buildAppBarActions(cubit),
      elevation: 0,
      scrolledUnderElevation: 3,
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
        icon: const Icon(Icons.refresh_rounded),
        tooltip: 'Refresh',
        onPressed: widget.loading || isOffline
            ? null
            : () {
                cubit.refresh();
              },
      ),
      // Wake: Disabled by loading OR offline
      IconButton(
        icon: const Icon(Icons.alarm_on_rounded),
        tooltip: "Wake",
        onPressed: widget.loading || isOffline
            ? null
            : () {
                cubit.requireDisting().requestWake();
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
      key: ValueKey(_currentMode), // Important for AnimatedSwitcher
      mainAxisSize: MainAxisSize.min,
      children: _currentMode == EditMode.parameters
          ? _buildParameterModeActions(cubit)
          : _buildRoutingModeActions(),
    );
  }

  List<Widget> _buildParameterModeActions(DistingCubit cubit) {
    return [
      // Move Up
      Builder(
        builder: (ctx) {
          return IconButton(
            icon: const Icon(Icons.arrow_upward_rounded),
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
            icon: const Icon(Icons.arrow_downward_rounded),
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
            icon: const Icon(Icons.delete_forever_rounded),
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
      icon: const Icon(Icons.more_vert),
      itemBuilder: (popupCtx) {
        // Get offline status here for menu items that need it
        final isOffline = switch (cubit.state) {
          DistingStateSynchronized(offline: final o) => o,
          _ => false,
        };
        return [
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
                    // Original call to show the dialog
                    final result = await popupCtx.showSettingsDialog();

                    // Logic copied and adapted from _DistingPageState._handleSettingsDialog
                    if (result == true && popupCtx.mounted) {
                      // Ensure context is still valid
                      final settings = SettingsService();
                      final mcpInstance = McpServerService.instance;
                      final bool isMcpEnabledAfterDialog = settings.mcpEnabled;
                      final bool isServerStillRunningBeforeAction =
                          mcpInstance.isRunning;

                      debugPrint(
                        "[SyncScreenSettings] After dialog saved: New MCP Setting: $isMcpEnabledAfterDialog, Server Currently Running (before action): $isServerStillRunningBeforeAction",
                      );

                      if (Platform.isMacOS || Platform.isWindows) {
                        if (isMcpEnabledAfterDialog) {
                          if (!isServerStillRunningBeforeAction) {
                            debugPrint(
                              "[SyncScreenSettings] MCP Setting is ON, Server is OFF. Attempting to START server.",
                            );
                            await mcpInstance.start().catchError((e) {
                              debugPrint(
                                '[SyncScreenSettings] Error starting MCP Server: $e',
                              );
                            });
                            debugPrint(
                              "[SyncScreenSettings] MCP Server START attempt finished. Now Running: ${mcpInstance.isRunning}",
                            );
                          } else {
                            debugPrint(
                              "[SyncScreenSettings] MCP Setting is ON, Server is ALREADY ON. No action taken. Running: ${mcpInstance.isRunning}",
                            );
                          }
                        } else {
                          // MCP Setting is OFF
                          if (isServerStillRunningBeforeAction) {
                            debugPrint(
                              "[SyncScreenSettings] MCP Setting is OFF, Server is ON. Attempting to STOP server.",
                            );
                            await mcpInstance.stop().catchError((e) {
                              debugPrint(
                                '[SyncScreenSettings] Error stopping MCP Server: $e',
                              );
                            });
                            debugPrint(
                              "[SyncScreenSettings] MCP Server STOP attempt finished. Now Running: ${mcpInstance.isRunning}",
                            );
                          } else {
                            debugPrint(
                              "[SyncScreenSettings] MCP Setting is OFF, Server is ALREADY OFF. No action taken. Running: ${mcpInstance.isRunning}",
                            );
                          }
                        }
                      } else {
                        debugPrint(
                          "[SyncScreenSettings] Not on MacOS/Windows. No MCP server action taken.",
                        );
                      }
                    } else {
                      debugPrint(
                        "[SyncScreenSettings] Settings dialog cancelled or no changes saved. No MCP server action taken.",
                      );
                    }
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
                            "Written by Neal Sanche (Thorinside), 2025, No Rights Reserved.",
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
          InkWell(
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
              mainAxisSize: MainAxisSize.min, // Shrinks to fit content
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Preset:\u2007',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold, // Make 'Preset: ' bold
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextSpan(
                        text: widget.presetName.trim(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return BlocBuilder<DistingCubit, DistingState>(
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
                // Use slot.algorithm.name directly (includes custom name)
                final displayName = slot.algorithm.name;

                return GestureDetector(
                  onDoubleTap: () async {
                    var cubit = context.read<DistingCubit>();
                    cubit.disting()?.let((manager) {
                      manager.requestSetFocus(index, 0);
                      manager.requestSetDisplayMode(DisplayMode.algorithmUI);
                    });
                    if (SettingsService().hapticsEnabled) {
                      Haptics.vibrate(HapticsType.medium);
                    }
                  },
                  onLongPress: () async {
                    var cubit = context.read<DistingCubit>();
                    // Use the current displayName for the dialog initial value
                    final newName = await showDialog<String>(
                      context: context,
                      builder: (dialogCtx) =>
                          RenameSlotDialog(initialName: displayName),
                    );

                    if (newName != null && newName != displayName) {
                      // Use slot index directly (algorithmIndex on Algorithm is different)
                      cubit.renameSlot(index, newName);
                    }
                  },
                  // Display the correct name in the Tab
                  child: Tab(text: displayName),
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
    debugPrint('[SynchronizedScreen] _showScreenshotOverlay called');
    final cubit = context.read<DistingCubit>();

    // Create a VideoFrameCubit for this overlay
    final videoFrameCubit = VideoFrameCubit();
    debugPrint(
      '[SynchronizedScreen] Created VideoFrameCubit: $videoFrameCubit',
    );

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => FloatingVideoOverlay(
        overlayEntry: overlayEntry,
        cubit: cubit,
        videoFrameCubit: videoFrameCubit,
      ),
    );

    debugPrint('[SynchronizedScreen] Inserting overlay entry');
    Overlay.of(context).insert(overlayEntry);
    debugPrint('[SynchronizedScreen] Overlay entry inserted successfully');
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
