import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:nt_helper/add_algorithm_screen.dart';
import 'package:nt_helper/constants.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/floating_screenshot_overlay.dart';
import 'package:nt_helper/load_preset_dialog.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/packed_mapping_data_editor.dart';
import 'package:nt_helper/performance_screen.dart';
import 'package:nt_helper/rename_preset_dialog.dart';
import 'package:nt_helper/rename_slot_dialog.dart';
import 'package:nt_helper/routing_page.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/ui/algorithm_registry.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart';
import 'package:nt_helper/ui/reset_outputs_dialog.dart';
import 'package:nt_helper/util/extensions.dart';
import 'package:nt_helper/util/version_util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nt_helper/ui/metadata_sync/metadata_sync_page.dart';
import '../db/daos/presets_dao.dart';

class SynchronizedScreen extends StatelessWidget {
  final List<Slot> slots;
  final List<AlgorithmInfo> algorithms;
  final List<String> units;
  final String presetName;
  final String distingVersion;
  final Uint8List? screenshot;
  final bool loading;

  const SynchronizedScreen({
    super.key,
    required this.slots,
    required this.algorithms,
    required this.units,
    required this.presetName,
    required this.distingVersion,
    required this.screenshot,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: slots.length,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(context),
        body: _buildBody(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
        floatingActionButton: _buildFloatingActionButton(),
        bottomNavigationBar: _buildBottomAppBar(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Builder(builder: (context) {
      return FloatingActionButton.small(
        tooltip: "Add Algorithm to Preset",
        onPressed: () async {
          final cubit = context.read<DistingCubit>();
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
          }
        },
        child: Icon(Icons.add_circle_rounded),
      );
    });
  }

  BottomAppBar _buildBottomAppBar() {
    return BottomAppBar(
      child: Row(
        children: [
          Builder(builder: (context) {
            final isOffline = context.watch<DistingCubit>().state.maybeMap(
                  synchronized: (s) => s.offline,
                  orElse: () =>
                      false, // Default to not offline if state is not synchronized
                );

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
                      context
                          .read<DistingCubit>()
                          .setDisplayMode(DisplayMode.parameters);
                    },
                    icon: Icon(Icons.list_alt_rounded),
                  ),
                  IconButton(
                    tooltip: "Algorithm UI",
                    onPressed: () {
                      context
                          .read<DistingCubit>()
                          .setDisplayMode(DisplayMode.algorithmUI);
                    },
                    icon: Icon(Icons.line_axis_rounded),
                  ),
                  IconButton(
                    tooltip: "Overview UI",
                    onPressed: () {
                      context
                          .read<DistingCubit>()
                          .setDisplayMode(DisplayMode.overview);
                    },
                    icon: Icon(Icons.line_weight_rounded),
                  ),
                  IconButton(
                    tooltip: "Overview VU Meters",
                    onPressed: () {
                      context
                          .read<DistingCubit>()
                          .setDisplayMode(DisplayMode.overviewVUs);
                    },
                    icon: Icon(Icons.leaderboard_rounded),
                  ),
                ],
              );
            }
          }),
          SizedBox.fromSize(
            size: Size.fromWidth(24),
          ),
          DistingVersion(
              distingVersion: distingVersion,
              requiredVersion: Constants.requiredDistingVersion),
        ],
      ),
    );
  }

  AnimatedSwitcher _buildBody() {
    return AnimatedSwitcher(
      duration: Duration(seconds: 1),
      child: Builder(builder: (context) {
        return slots.isNotEmpty
            ? TabBarView(
                children: slots.mapIndexed((index, slot) {
                  return SlotDetailView(
                    key: ValueKey("$index - ${slot.algorithm.guid}"),
                    slot: slot,
                    units: units,
                  );
                }).toList(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "No algorithms",
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              );
      }),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('NT Helper'),
      actions: _buildAppBarActions(),
      elevation: 0,
      scrolledUnderElevation: 3,
      notificationPredicate: (ScrollNotification notification) =>
          notification.depth == 1,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(66.0),
        child: Column(
          children: [
            _buildPresetInfoEditor(context), // The TabBar
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  flex: 1,
                  child: _buildTabBar(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      // Refresh: Only disabled by loading OR offline
      Builder(builder: (ctx) {
        final isOffline = ctx.watch<DistingCubit>().state.maybeMap(
              synchronized: (s) => s.offline,
              orElse: () => false,
            );
        return IconButton(
          icon: Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: loading || isOffline // <-- Updated condition
              ? null
              : () {
                  ctx.read<DistingCubit>().refresh();
                },
        );
      }),
      // Wake: Disabled by loading OR offline
      Builder(builder: (ctx) {
        final isOffline = ctx.watch<DistingCubit>().state.maybeMap(
              synchronized: (s) => s.offline,
              orElse: () => false,
            );
        return IconButton(
          icon: Icon(Icons.alarm_on_rounded),
          tooltip: "Wake",
          onPressed: loading || isOffline
              ? null
              : () {
                  ctx.read<DistingCubit>().requireDisting().requestWake();
                },
        );
      }),
      // Move Up: Only disabled by loading
      Builder(builder: (ctx) {
        return IconButton(
          icon: const Icon(Icons.arrow_upward_rounded),
          tooltip: 'Move Algorithm Up',
          onPressed: loading
              ? null
              : () async {
                  final tabController = DefaultTabController.of(ctx);
                  if (tabController.index > 0) {
                    final newIndex = await ctx
                        .read<DistingCubit>()
                        .moveAlgorithmUp(tabController.index);
                    tabController.animateTo(newIndex);
                  }
                },
        );
      }),
      // Move Down: Only disabled by loading
      Builder(builder: (ctx) {
        return IconButton(
          icon: const Icon(Icons.arrow_downward_rounded),
          tooltip: 'Move Algorithm Down',
          onPressed: loading
              ? null
              : () async {
                  final tabController = DefaultTabController.of(ctx);
                  final cubit = ctx.read<DistingCubit>();
                  final currentState = cubit.state;
                  int slotCount = 0;
                  if (currentState is DistingStateSynchronized) {
                    slotCount = currentState.slots.length;
                  }
                  if (tabController.index < slotCount - 1) {
                    final newIndex =
                        await cubit.moveAlgorithmDown(tabController.index);
                    tabController.animateTo(newIndex);
                  }
                },
        );
      }),
      // Remove Algorithm: Only disabled by loading
      Builder(
        builder: (ctx) {
          return IconButton(
              icon: const Icon(Icons.delete_forever_rounded),
              tooltip: 'Remove Algorithm',
              onPressed: loading
                  ? null
                  : () async {
                      ctx.read<DistingCubit>().onRemoveAlgorithm(
                          DefaultTabController.of(ctx).index);
                    });
        },
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (popupCtx) {
          // Get offline status here for menu items that need it
          final isOffline = popupCtx.read<DistingCubit>().state.maybeMap(
                synchronized: (s) => s.offline,
                orElse: () => false,
              );
          return [
            // New: Only disabled by loading
            PopupMenuItem(
              value: "new",
              enabled: !loading,
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New Preset'),
                    Icon(Icons.fiber_new_rounded)
                  ]),
              onTap: loading
                  ? null
                  : () {
                      popupCtx.read<DistingCubit>().newPreset();
                    },
            ),
            // Load: Disabled by loading OR offline
            PopupMenuItem(
              value: "load",
              enabled: !loading && !isOffline,
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Load Preset'),
                    Icon(Icons.file_upload_rounded)
                  ]),
              onTap: loading || isOffline
                  ? null
                  : () async {
                      var cubit = popupCtx.read<DistingCubit>();
                      final preset = await showDialog<dynamic>(
                        context: popupCtx,
                        builder: (dialogCtx) =>
                            LoadPresetDialog(initialName: ""),
                      );
                      if (preset == null) return;
                      cubit.loadPreset(
                          preset["name"] as String, preset["append"] as bool);
                    },
            ),
            // Save: Disabled by loading ONLY
            PopupMenuItem(
              value: "save",
              enabled: !loading,
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Save Preset'),
                    Icon(Icons.save_alt_rounded)
                  ]),
              onTap: loading
                  ? null
                  : () {
                      popupCtx
                          .read<DistingCubit>()
                          .requireDisting()
                          .requestSavePreset();
                    },
            ),
            // Routing: Disabled by loading OR offline
            PopupMenuItem(
              value: 'routing',
              enabled: !loading && !isOffline,
              onTap: loading || isOffline
                  ? null
                  : () async {
                      final routingInformation = popupCtx
                          .read<DistingCubit>()
                          .buildRoutingInformation();
                      Navigator.push(
                        popupCtx,
                        MaterialPageRoute(
                            builder: (_) =>
                                RoutingPage(routing: routingInformation)),
                      );
                    },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Routing'), Icon(Icons.route_rounded)],
              ),
            ),
            // Screenshot: Disabled by loading OR offline
            PopupMenuItem(
              value: 'screenshot',
              enabled: !loading && !isOffline,
              onTap: loading || isOffline
                  ? null
                  : () {
                      _showScreenshotOverlay(popupCtx);
                    },
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Screenshot'),
                    Icon(Icons.screenshot_monitor_rounded),
                  ]),
            ),
            // Perform: Disabled by loading OR offline
            PopupMenuItem(
              value: 'perform',
              enabled: !loading && !isOffline,
              onTap: loading || isOffline
                  ? null
                  : () {
                      final cubit = popupCtx.read<DistingCubit>();
                      final midiListener = popupCtx.read<MidiListenerCubit>();
                      Navigator.push(
                        popupCtx,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(value: cubit),
                              BlocProvider.value(value: midiListener),
                            ],
                            child: PerformanceScreen(units: units),
                          ),
                        ),
                      );
                    },
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Perform'),
                    Icon(Icons.library_music),
                  ]),
            ),
            // Switch Devices: Only disabled by loading (Fix context usage)
            PopupMenuItem(
              value: 'Switch Devices',
              enabled: !loading,
              onTap: loading
                  ? null
                  : () {
                      popupCtx.read<DistingCubit>().goOnline();
                    },
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('Switch'), Icon(Icons.login_rounded)]),
            ),
            // Settings: Only disabled by loading
            PopupMenuItem(
              value: 'Settings',
              enabled: !loading,
              onTap: loading
                  ? null
                  : () async {
                      await popupCtx.showSettingsDialog();
                    },
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text('Settings'), Icon(Icons.settings)]),
            ),
            // Sync Metadata: Only disabled by loading
            PopupMenuItem(
              value: 'sync_metadata',
              enabled: !loading,
              onTap: loading
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
              onTap: loading
                  ? null
                  : () async {
                      final info = await PackageInfo.fromPlatform();
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
                                  Text("Disting Firmware: $distingVersion",
                                      style: Theme.of(dialogCtx)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
              child: Text('About'),
            ),
          ];
        },
      ),
    ];
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
                builder: (context) => RenamePresetDialog(
                  initialName: presetName,
                ),
              );

              if (newName != null &&
                  newName.isNotEmpty &&
                  newName != presetName) {
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
                              fontWeight:
                                  FontWeight.bold, // Make 'Preset: ' bold
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      TextSpan(
                        text: presetName.trim(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
          )
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return BlocBuilder<DistingCubit, DistingState>(
      builder: (context, state) {
        return state.maybeMap(
          synchronized: (syncState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorAnimation: TabIndicatorAnimation.elastic,
                indicatorWeight: 1,
                enableFeedback: true,
                dividerHeight: 0,
                tabs: List<Widget>.generate(syncState.slots.length, (index) {
                  final slot = syncState.slots[index];
                  // Use slot.algorithm.name directly (includes custom name)
                  final displayName = slot.algorithm.name;

                  return GestureDetector(
                    onLongPress: () async {
                      var cubit = context.read<DistingCubit>();
                      // Use the current displayName for the dialog initial value
                      final newName = await showDialog<String>(
                        context: context,
                        builder: (dialogCtx) => RenameSlotDialog(
                          initialName: displayName,
                        ),
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
            );
          },
          orElse: () => const Center(child: Text("Loading slots...")),
        );
      },
    );
  }

  void _showScreenshotOverlay(BuildContext context) {
    final cubit = context.read<DistingCubit>();

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: kBottomNavigationBarHeight + 16,
        right: 16,
        child: FloatingScreenshotOverlay(
          overlayEntry: overlayEntry,
          cubit: cubit,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }
}

class DistingVersion extends StatelessWidget {
  const DistingVersion({
    super.key,
    required this.distingVersion,
    required this.requiredVersion,
  });

  final String distingVersion;
  final String requiredVersion;

  @override
  Widget build(BuildContext context) {
    final isNotSupported =
        isVersionUnsupported(distingVersion, requiredVersion);
    return Tooltip(
      message:
          isNotSupported ? "nt_helper requires at least $requiredVersion" : "",
      child: Text(distingVersion,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isNotSupported
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              )),
    );
  }
}

class SlotDetailView extends StatefulWidget {
  final Slot slot;
  final List<String> units;

  const SlotDetailView({super.key, required this.slot, required this.units});

  @override
  State<SlotDetailView> createState() => _SlotDetailViewState();
}

class _SlotDetailViewState extends State<SlotDetailView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Provide a full replacement view
    final view = AlgorithmViewRegistry.findViewFor(widget.slot);
    if (view != null) return view;

    // Create a set of list sections for the parameters of the
    // algorithm initially based off Os' organization on the module firmware.

    return SafeArea(
      child: SectionParameterListView(
        slot: widget.slot,
        units: widget.units,
        pages: widget.slot.pages,
      ),
    );
  }
}

class SectionParameterListView extends StatefulWidget {
  final Slot slot;
  final List<String> units;
  final ParameterPages pages;

  const SectionParameterListView({
    super.key,
    required this.slot,
    required this.units,
    required this.pages,
  });

  @override
  State<SectionParameterListView> createState() =>
      _SectionParameterListViewState();
}

class _SectionParameterListViewState extends State<SectionParameterListView> {
  late final List<ExpansionTileController> _tileControllers;
  var _isCollapsed = false;

  @override
  void initState() {
    _tileControllers = List.generate(
        widget.pages.pages.length, (_) => ExpansionTileController());
    super.initState();
  }

  void _collapseAllTiles() {
    for (var element in _tileControllers) {
      _isCollapsed ? element.expand() : element.collapse();
    }
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      data: ListTileThemeData(
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
      ),
      child: ExpansionTileTheme(
        data: ExpansionTileThemeData(
          shape: RoundedRectangleBorder(
            side: BorderSide.none,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Tooltip(
                  message: _isCollapsed ? 'Expand all' : 'Collapse all',
                  child: IconButton.filledTonal(
                    onPressed: () {
                      _collapseAllTiles();
                    },
                    enableFeedback: true,
                    icon: _isCollapsed
                        ? Icon(Icons.keyboard_double_arrow_down_sharp)
                        : Icon(Icons.keyboard_double_arrow_up_sharp),
                  ),
                ),
                PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'Reset Outputs',
                            onTap: () {
                              showResetOutputsDialog(
                                context: context,
                                initialCvInput: 0,
                                onReset: (outputIndex) {
                                  context
                                      .read<DistingCubit>()
                                      .resetOutputs(widget.slot, outputIndex);
                                },
                              );
                            },
                            child: Text('Reset Outputs'),
                          ),
                        ]),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                cacheExtent: double.infinity,
                padding: EdgeInsets.only(bottom: 24, left: 8, right: 8),
                itemCount: widget.pages.pages.length,
                itemBuilder: (context, index) {
                  final page = widget.pages.pages.elementAt(index);
                  return ExpansionTile(
                    initiallyExpanded: true,
                    controller: _tileControllers.elementAt(index),
                    title: Text(page.name),
                    children: page.parameters.map(
                      (parameterNumber) {
                        // Debug Print here
                        debugPrint(
                            "[UI Build] Slot: '${widget.slot.algorithm.name}', Page: '${page.name}', Param#: $parameterNumber, Mapping List Len: ${widget.slot.mappings.length}, Enums List Len: ${widget.slot.enums.length}, Values List Len: ${widget.slot.values.length}, ValueStrings Len: ${widget.slot.valueStrings.length}");

                        final value =
                            widget.slot.values.elementAt(parameterNumber);
                        final enumStrings =
                            widget.slot.enums.elementAt(parameterNumber);
                        final mapping = widget.slot.mappings
                            .elementAtOrNull(parameterNumber);
                        final valueString =
                            widget.slot.valueStrings.elementAt(parameterNumber);
                        var parameterInfo =
                            widget.slot.parameters.elementAt(parameterNumber);
                        final unit = parameterInfo.getUnitString(widget.units);

                        return ParameterEditorView(
                          parameterInfo: parameterInfo,
                          value: value,
                          enumStrings: enumStrings,
                          mapping: mapping,
                          valueString: valueString,
                          unit: unit,
                        );
                      },
                    ).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParameterListView extends StatelessWidget {
  final Slot slot;
  final List<String> units;

  const ParameterListView({
    super.key,
    required this.slot,
    required this.units,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      cacheExtent: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      itemCount: slot.parameters.length,
      itemBuilder: (context, index) {
        final parameter = slot.parameters.elementAt(index);
        final value = slot.values.elementAt(index);
        final enumStrings = slot.enums.elementAt(index);
        final mapping = slot.mappings.elementAtOrNull(index);
        final valueString = slot.valueStrings.elementAt(index);
        final unit = parameter.getUnitString(units);

        return ParameterEditorView(
          parameterInfo: parameter,
          value: value,
          enumStrings: enumStrings,
          mapping: mapping,
          valueString: valueString,
          unit: unit,
        );
      },
    );
  }
}

class ParameterEditorView extends StatelessWidget {
  final ParameterInfo parameterInfo;
  final ParameterValue value;
  final ParameterEnumStrings enumStrings;
  final Mapping? mapping;
  final ParameterValueString valueString;
  final String? unit;

  const ParameterEditorView({
    super.key,
    required this.parameterInfo,
    required this.value,
    required this.enumStrings,
    required this.mapping,
    required this.valueString,
    this.unit,
  });

  @override
  Widget build(BuildContext context) => ParameterViewRow(
        name: parameterInfo.name,
        min: parameterInfo.min,
        max: parameterInfo.max,
        algorithmIndex: parameterInfo.algorithmIndex,
        parameterNumber: parameterInfo.parameterNumber,
        powerOfTen: parameterInfo.powerOfTen,
        defaultValue: parameterInfo.defaultValue,
        displayString: valueString.value.isNotEmpty ? valueString.value : null,
        dropdownItems:
            enumStrings.values.isNotEmpty ? enumStrings.values : null,
        isOnOff: (enumStrings.values.isNotEmpty &&
            enumStrings.values[0] == "Off" &&
            enumStrings.values[1] == "On"),
        initialValue: (value.value >= parameterInfo.min &&
                value.value <= parameterInfo.max)
            ? value.value
            : parameterInfo.defaultValue,
        unit: unit,
        mappingData: mapping?.packedMappingData,
      );
}

class ParameterViewRow extends StatefulWidget {
  final String name;
  final int min;
  final int max;
  final int defaultValue;
  final String?
      displayString; // For additional display string instead of dropdown
  final String? unit;
  final int powerOfTen;
  final List<String>? dropdownItems; // For enums as a dropdown
  final bool isOnOff; // Whether the parameter is an "on/off" type
  final int initialValue;
  final int algorithmIndex;
  final int parameterNumber;
  final PackedMappingData? mappingData;

  const ParameterViewRow({
    super.key,
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.parameterNumber,
    required this.algorithmIndex,
    this.unit,
    this.powerOfTen = 0,
    this.displayString,
    this.dropdownItems,
    this.isOnOff = false,
    this.mappingData,
    required this.initialValue,
  });

  @override
  State<ParameterViewRow> createState() => _ParameterViewRowState();
}

class _ParameterViewRowState extends State<ParameterViewRow> {
  late int currentValue;
  late bool isChecked;
  bool isChanging = false;
  bool _showAlternateEditor = false;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
    isChecked = widget.isOnOff && currentValue == 1;
  }

  @override
  void didUpdateWidget(covariant ParameterViewRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update internal state when the widget is updated
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        currentValue = widget.initialValue;
        isChecked = widget.isOnOff && currentValue == 1;
      });
    }
  }

  void _updateCubitValue(int value) {
    // Send updated value to the Cubit
    context.read<DistingCubit>().updateParameterValue(
          algorithmIndex: widget.algorithmIndex,
          parameterNumber: widget.parameterNumber,
          value: value,
          userIsChangingTheValue:
              widget.displayString?.isNotEmpty == true ? false : isChanging,
        );
  }

  DateTime? _lastSent;
  Duration throttleDuration = const Duration(milliseconds: 100);

  void onSliderChanged(int value) async {
    final now = DateTime.now();
    if (_lastSent == null || now.difference(_lastSent!) > throttleDuration) {
      // Enough time has passed -> proceed
      _lastSent = now;
      _updateCubitValue(value);
    }

    if (SettingsService().hapticsEnabled) {
      Haptics.vibrate(HapticsType.light);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Check if we are on a wide screen or a smaller screen
    bool widescreen = MediaQuery.of(context).size.width > 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      child: Row(
        key: ValueKey(widescreen),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MappingEditButton(widget: widget),
          // Name column with reduced width
          Expanded(
            flex: widescreen ? 2 : 3,
            child: GestureDetector(
              onLongPress: () {
                // Get the manager from the cubit
                final manager = context.read<DistingCubit>().requireDisting();
                // Call requestSetFocus on the manager
                manager.requestSetFocus(
                  widget.algorithmIndex,
                  widget.parameterNumber,
                );
                if (SettingsService().hapticsEnabled) {
                  Haptics.vibrate(HapticsType.medium);
                }
              },
              child: Text(
                cleanTitle(widget.name),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                softWrap: false,
                textAlign: TextAlign.start,
                style:
                    widescreen ? textTheme.titleMedium : textTheme.labelMedium,
              ),
            ),
          ),

          // Slider column
          Expanded(
              flex: widescreen ? 8 : 6, // Decreased flex
              // Proportionally larger space for the slider
              child: GestureDetector(
                onDoubleTap: () => _showAlternateEditor
                    ? {}
                    : setState(() {
                        currentValue = widget.defaultValue;
                        _updateCubitValue(currentValue);
                      }),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 150),
                  child: SizedBox(
                    height: 45,
                    child: _showAlternateEditor
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 16,
                            children: [
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      currentValue = min(
                                          max(currentValue - 1, widget.min),
                                          widget.max);
                                    });
                                    _updateCubitValue(currentValue);
                                  },
                                  child: Text("-"),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      currentValue = min(
                                          max(currentValue + 1, widget.min),
                                          widget.max);
                                    });
                                    _updateCubitValue(currentValue);
                                  },
                                  child: Text("+"),
                                )
                              ])
                        : Slider(
                            value: currentValue.toDouble(),
                            min: widget.min.toDouble(),
                            max: widget.max.toDouble(),
                            divisions: (widget.max - widget.min > 0)
                                ? widget.max - widget.min
                                : null,
                            onChangeStart: (value) {
                              isChanging = true;
                            },
                            onChangeEnd: (value) {
                              isChanging = false;
                              setState(() {
                                currentValue = value.toInt();
                                if (widget.isOnOff) {
                                  isChecked = currentValue == 1;
                                }
                              });
                              _updateCubitValue(currentValue);
                            },
                            onChanged: (value) {
                              setState(() {
                                currentValue = value.toInt();
                                if (widget.isOnOff) {
                                  isChecked = currentValue == 1;
                                }
                              });
                              // Throttle a bit
                              onSliderChanged(currentValue);
                            },
                          ),
                  ),
                ),
              )),
          // Control column
          Expanded(
            flex: widescreen ? 4 : 5, // Increased flex
            child: Align(
              alignment: Alignment.centerLeft,
              child: widget.isOnOff
                  ? Checkbox(
                      value: isChecked,
                      onChanged: (value) {
                        setState(() {
                          isChecked = value!;
                          currentValue = isChecked ? 1 : 0;
                        });
                        _updateCubitValue(currentValue);
                      },
                    )
                  : widget.dropdownItems != null
                      ? DropdownMenu(
                          requestFocusOnTap: false,
                          initialSelection: widget.dropdownItems![currentValue],
                          inputDecorationTheme: const InputDecorationTheme(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          textStyle: widescreen
                              ? textTheme.labelLarge
                              : textTheme.labelMedium,
                          dropdownMenuEntries: widget.dropdownItems!
                              .map((item) =>
                                  DropdownMenuEntry(value: item, label: item))
                              .toList(),
                          onSelected: (value) {
                            setState(() {
                              currentValue = min(
                                  max(widget.dropdownItems!.indexOf(value!),
                                      widget.min),
                                  widget.max);
                            });
                            _updateCubitValue(currentValue);
                          },
                        )
                      : widget.name.toLowerCase().contains("note")
                          ? Text(midiNoteToNoteString(currentValue))
                          : widget.displayString != null
                              ? GestureDetector(
                                  onLongPress: () => setState(() {
                                    // Show alternate editor
                                    _showAlternateEditor =
                                        !_showAlternateEditor;
                                  }),
                                  child: Text(
                                    widget.displayString!,
                                    overflow: TextOverflow.ellipsis,
                                    style: widescreen
                                        ? textTheme.labelLarge
                                        : textTheme.labelSmall,
                                  ),
                                )
                              : widget.unit != null
                                  ? Text(
                                      formatWithUnit(
                                        currentValue,
                                        name: widget.name,
                                        min: widget.min,
                                        max: widget.max,
                                        unit: widget.unit,
                                        powerOfTen: widget.powerOfTen,
                                      ),
                                      style: widescreen
                                          ? textTheme.labelLarge
                                          : textTheme.labelSmall,
                                    )
                                  : Text(
                                      currentValue.toString(),
                                      style: widescreen
                                          ? textTheme.labelLarge
                                          : textTheme.labelSmall,
                                    ),
            ),
          ),
        ],
      ),
    );
  }

  String cleanTitle(String name) {
    // If name starts with a number followed by a colon, strip that off
    final RegExp regex = RegExp(r'^\d+:\s*');
    return name.replaceAll(regex, '');
  }
}

class MappingEditButton extends StatelessWidget {
  const MappingEditButton({
    super.key,
    required this.widget,
  });

  final ParameterViewRow widget;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.6,
      child: Builder(
        builder: (context) {
          final bool hasMapping = widget.mappingData != null &&
              widget.mappingData != PackedMappingData.filler() &&
              widget.mappingData?.isMapped() == true;

          // Define your two styles:
          final ButtonStyle defaultStyle = IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          );
          final ButtonStyle mappedStyle = IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            backgroundColor: Theme.of(context)
                .colorScheme
                .primaryContainer, // or any color you prefer
          );

          return IconButton.filledTonal(
            // Decide which style to use based on `hasMapping`
            style: hasMapping ? mappedStyle : defaultStyle,
            icon: const Icon(Icons.map_sharp),
            tooltip: 'Edit mapping',
            onPressed: () async {
              final cubit = context.read<DistingCubit>();
              final currentState = cubit.state;
              List<Slot> currentSlots = [];
              if (currentState is DistingStateSynchronized) {
                currentSlots = currentState.slots;
              }

              final data = widget.mappingData ?? PackedMappingData.filler();
              final myMidiCubit = context.read<MidiListenerCubit>();
              final updatedData = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return MappingEditorBottomSheet(
                    myMidiCubit: myMidiCubit,
                    data: data,
                    slots: currentSlots,
                  );
                },
              );

              if (updatedData != null) {
                cubit.saveMapping(
                  widget.algorithmIndex,
                  widget.parameterNumber,
                  updatedData,
                );
              }
            },
          );
        },
      ),
    );
  }
}

class MappingEditorBottomSheet extends StatelessWidget {
  const MappingEditorBottomSheet({
    super.key,
    required this.myMidiCubit,
    required this.data,
    required this.slots,
  });

  final MidiListenerCubit myMidiCubit;
  final PackedMappingData data;
  final List<Slot> slots;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom > 0
              ? MediaQuery.of(context).viewInsets.bottom
              : MediaQuery.of(context).padding.bottom,
        ),
        child: SingleChildScrollView(
          child: BlocProvider.value(
            value: myMidiCubit,
            child: PackedMappingDataEditor(
              initialData: data,
              slots: slots,
              onSave: (updatedData) {
                // do something with updatedData
                Navigator.of(context).pop(updatedData);
              },
            ),
          ),
        ),
      ),
    );
  }
}

String formatWithUnit(
  int currentValue, {
  required int min,
  required int max,
  required String name,
  String? unit,
  required int powerOfTen,
}) {
  if (unit == null || unit.isEmpty) return currentValue.toString();

  final trimmedUnit = unit.trim();
  return '${((currentValue / pow(10, powerOfTen)).toStringAsFixed(powerOfTen))} $trimmedUnit';
}

String midiNoteToNoteString(int midiNoteNumber) {
  if (midiNoteNumber == -1) return "";

  if (midiNoteNumber < 0 || midiNoteNumber > 127) {
    throw ArgumentError('MIDI note number must be between 0 and 127.');
  }

  // Note names
  List<String> noteNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];

  // Calculate the octave and note index
  int octave = (midiNoteNumber ~/ 12) - 1;
  String note = noteNames[midiNoteNumber % 12];

  return '$note$octave';
}
