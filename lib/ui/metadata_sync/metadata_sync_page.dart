import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart'
    show IDistingMidiManager;
import 'package:nt_helper/ui/metadata_sync/metadata_sync_cubit.dart';
import 'package:nt_helper/disting_app.dart'; // Import DistingApp for the route name

class MetadataSyncPage extends StatelessWidget {
  // Accept DistingCubit as a parameter
  final DistingCubit distingCubit;

  const MetadataSyncPage({super.key, required this.distingCubit});

  @override
  Widget build(BuildContext context) {
    // Get AppDatabase from context (RepositoryProvider)
    final database = context.read<AppDatabase>();
    // Get manager instance (if any) from DistingCubit state later
    // final distingManager = distingCubit.disting(); // No longer needed here
    // final bool isConnected = distingManager != null; // Determined by DistingState

    // Provide MetadataSyncCubit without manager initially
    return BlocProvider(
      create: (context) => MetadataSyncCubit(database)..loadLocalData(),
      child: BlocBuilder<DistingCubit, DistingState>(
          // Rebuild the whole page based on DistingState (online/offline)
          bloc: distingCubit,
          builder: (context, distingState) {
            // Determine online/offline/connected status from DistingState
            final bool isOffline = distingState.maybeMap(
                synchronized: (s) => s.offline, orElse: () => false);
            final bool isConnected = distingState.maybeMap(
                synchronized: (s) =>
                    !s.offline, // Connected if sync'd and not offline
                connected: (_) => true,
                orElse: () => false);

            // Get the current manager if available (online or offline)
            final currentManager = distingCubit.disting();

            // Provide the DistingCubit down the tree using BlocProvider.value
            return BlocProvider.value(
              value: distingCubit,
              child: Scaffold(
                appBar: AppBar(
                  title: Text('Offline Data'),
                  leading:
                      BackButton(onPressed: () => Navigator.maybePop(context)),
                  actions: [
                    // --- Offline Mode Toggle --- (Interacts with DistingCubit)
                    BlocBuilder<MetadataSyncCubit, MetadataSyncState>(
                        // Still watch MetadataSyncCubit for busy state
                        builder: (metaCtx, metaState) {
                      // Busy state checks (simplified, check both cubits)
                      final isMetaBusy = metaState is! ViewingLocalData &&
                          metaState is! Idle &&
                          metaState is! Failure;
                      final isDistingBusy = distingState.maybeMap(
                          synchronized: (s) => s.loading, orElse: () => false);
                      final isBusy = isMetaBusy || isDistingBusy;

                      return IconButton(
                        icon: Icon(isOffline ? Icons.wifi_off : Icons.wifi),
                        tooltip: isOffline ? 'Go Online' : 'Work Offline',
                        onPressed: isBusy
                            ? null
                            : () {
                                if (isOffline) {
                                  // Use the distingCubit variable directly
                                  distingCubit.goOnline();
                                } else {
                                  // Use the distingCubit variable directly
                                  distingCubit.goOffline();
                                }
                              },
                      );
                    }),
                    // --- Sync Metadata Button --- (Uses MetadataSyncCubit)
                    BlocBuilder<MetadataSyncCubit, MetadataSyncState>(
                      builder: (metaCtx, metaState) {
                        final isMetaBusy = metaState is! ViewingLocalData &&
                            metaState is! Idle &&
                            metaState is! Failure;
                        final isDistingBusy = distingState.maybeMap(
                            synchronized: (s) => s.loading,
                            orElse: () => false);
                        final isBusy = isMetaBusy || isDistingBusy;
                        // Can sync if connected and not busy
                        final canSync = isConnected && !isBusy;
                        return IconButton(
                          icon: const Icon(Icons.sync),
                          tooltip: 'Sync From Device',
                          // Pass manager only if action is possible
                          onPressed: canSync && currentManager != null
                              ? () => _showSyncConfirmationDialog(
                                  metaCtx, currentManager)
                              : null,
                        );
                      },
                    ),
                    // --- Save Preset Button --- (Uses MetadataSyncCubit)
                    BlocBuilder<MetadataSyncCubit, MetadataSyncState>(
                      builder: (metaCtx, metaState) {
                        final isMetaBusy = metaState is! ViewingLocalData &&
                            metaState is! Idle &&
                            metaState is! Failure;
                        final isDistingBusy = distingState.maybeMap(
                            synchronized: (s) => s.loading,
                            orElse: () => false);
                        final isBusy = isMetaBusy || isDistingBusy;
                        // Can save if connected and not busy
                        final canSave = isConnected && !isBusy;
                        return IconButton(
                          icon: const Icon(Icons.save_alt_outlined),
                          tooltip: 'Save Current Device Preset',
                          // Pass manager only if action is possible
                          onPressed: canSave && currentManager != null
                              ? () => metaCtx
                                  .read<MetadataSyncCubit>()
                                  .saveCurrentPreset(currentManager)
                              : null,
                        );
                      },
                    ),
                    // --- Scan SD Card Button ---
                    BlocBuilder<MetadataSyncCubit, MetadataSyncState>(
                      builder: (metaCtx, metaState) {
                        // Reuse busy logic or simplify if not dependent on metaState specifics
                        final isMetaBusy = metaState is! ViewingLocalData &&
                            metaState is! Idle &&
                            metaState is! Failure;
                        final isDistingBusy = distingState.maybeMap(
                            synchronized: (s) => s.loading,
                            orElse: () => false);
                        final isBusy = isMetaBusy || isDistingBusy;

                        return IconButton(
                          icon: const Icon(Icons.sd_storage_outlined),
                          tooltip: 'Scan SD Card Presets',
                          onPressed: isBusy
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                      context, DistingApp.sdCardScannerRoute);
                                },
                        );
                      },
                    ),
                  ],
                ),
                // Body uses MetadataSyncCubit for DB data, DistingCubit for state
                body: BlocBuilder<MetadataSyncCubit, MetadataSyncState>(
                    builder: (metaCtx, metaState) {
                  final isOperationInProgress =
                      metaState is! ViewingLocalData &&
                          metaState is! Idle &&
                          metaState is! Failure;

                  if (metaState is Idle || metaState is LoadingPreset) {
                    // Show spinner if metadata cubit is loading
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (metaState is Failure ||
                      metaState is MetadataSyncFailure ||
                      metaState is PresetSaveFailure ||
                      metaState is PresetDeleteFailure ||
                      metaState is PresetLoadFailure) {
                    String errorMsg = metaState.mapOrNull(
                          failure: (s) => s.error,
                          metadataSyncFailure: (s) => s.error,
                          presetSaveFailure: (s) => s.error,
                          presetDeleteFailure: (s) => s.error,
                          presetLoadFailure: (s) => s.error,
                        ) ??
                        "An unknown error occurred.";
                    return Center(
                        child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                                size: 48),
                            const SizedBox(height: 16),
                            Text(errorMsg, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            TextButton(
                                onPressed: () {
                                  // Reset only MetadataSyncCubit, let user handle Disting mode
                                  metaCtx.read<MetadataSyncCubit>().reset();
                                  metaCtx
                                      .read<MetadataSyncCubit>()
                                      .loadLocalData(); // Reload list
                                  // If DistingCubit was also in error, user uses toggle
                                },
                                child: const Text("Retry Loading List"))
                          ]),
                    ));
                  }

                  if (metaState is SyncingMetadata ||
                      metaState is SavingPreset ||
                      metaState is DeletingPreset) {
                    return Center(
                        child: _buildProgressIndicator(context, metaState));
                  }

                  // Primarily use ViewingLocalData state
                  if (metaState is ViewingLocalData) {
                    // Offline highlighting removed for now
                    return _buildDataView(
                      metaCtx,
                      metaState.algorithms,
                      metaState.parameterCounts,
                      metaState.presets,
                      isConnected,
                      isOperationInProgress,
                      isOffline,
                      null, // No loaded preset ID passed
                    );
                  }
                  // Handle transient success states - might briefly show loading
                  if (metaState is MetadataSyncSuccess ||
                      metaState is PresetSaveSuccess ||
                      metaState is PresetDeleteSuccess ||
                      metaState is PresetLoadSuccess) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Fallback
                  return const Center(child: Text("Unhandled state"));
                }),
              ),
            );
          }),
    );
  }

  // Progress Indicator Widget
  Widget _buildProgressIndicator(
      BuildContext context, MetadataSyncState state) {
    String mainMessage = "Processing...";
    double? progressValue; // Null for indeterminate

    state.maybeWhen(
      syncingMetadata: (progress, mainMsg, subMsg, processed, total) {
        mainMessage = mainMsg;
        progressValue = progress > 0 ? progress : null; // Show progress if > 0
      },
      savingPreset: () => mainMessage = "Saving Preset...",
      deletingPreset: () => mainMessage = "Deleting Preset...",
      orElse: () {
        mainMessage = "Please wait..."; // Generic fallback
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progressValue,
          minHeight: 8,
          backgroundColor: Colors.grey[300],
        ),
        const SizedBox(height: 12),
        Text(
          mainMessage,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Confirmation Dialog for Metadata Sync (Manager passed in)
  void _showSyncConfirmationDialog(
      BuildContext metaContext, IDistingMidiManager manager) {
    showDialog(
      context: metaContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sync Metadata?'),
          content: const Text(
              'This process reads all algorithm data from the device and may require clearing the current preset. Save any work on the device first! Continue?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Sync'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Call cubit with manager
                metaContext
                    .read<MetadataSyncCubit>()
                    .startMetadataSync(manager);
              },
            ),
          ],
        );
      },
    );
  }

  // Tabbed Data View Widget
  Widget _buildDataView(
    BuildContext builderContext,
    List<AlgorithmEntry> algorithms,
    Map<String, int> parameterCounts,
    List<PresetEntry> presets,
    bool isConnected,
    bool isOperationInProgress,
    bool isOffline,
    int? loadedOfflinePresetId,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.save_alt), text: "Saved Presets"),
              Tab(icon: Icon(Icons.memory), text: "Synced Algorithms"),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TabBarView(
                children: [
                  // --- Presets Tab ---
                  _PresetListView(
                    presets: presets,
                    isOperationInProgress: isOperationInProgress,
                    isOffline: isOffline,
                    loadedOfflinePresetId: loadedOfflinePresetId,
                    // Use builderContext to find cubits
                    distingCubit: BlocProvider.of<DistingCubit>(builderContext),
                    metadataSyncCubit:
                        BlocProvider.of<MetadataSyncCubit>(builderContext),
                  ),
                  // --- Algorithms Tab ---
                  _AlgorithmMetadataListView(
                    algorithms: algorithms,
                    parameterCounts: parameterCounts,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Widget for Preset List View ---
class _PresetListView extends StatelessWidget {
  final List<PresetEntry> presets;
  final bool isOperationInProgress;
  final bool isOffline;
  final int? loadedOfflinePresetId;
  final DistingCubit distingCubit;
  final MetadataSyncCubit metadataSyncCubit; // Added MetadataSyncCubit

  const _PresetListView(
      {required this.presets,
      required this.isOperationInProgress,
      required this.isOffline,
      this.loadedOfflinePresetId,
      required this.distingCubit,
      required this.metadataSyncCubit});

  @override
  Widget build(BuildContext context) {
    if (presets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "No presets found.",
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }

    // Sort presets by name for consistent order
    final sortedPresets = List<PresetEntry>.from(presets)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ListView.separated(
      itemCount: sortedPresets.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1), // Add divider
      itemBuilder: (context, index) {
        final preset = sortedPresets[index];
        final formattedDate = preset.lastModified.toLocal().toString();

        // Offline highlighting removed (loadedOfflinePresetId is always null)
        final bool isCurrentlyLoadedOffline = false;

        // Determine button states
        final bool canLoad = !isOperationInProgress;
        final bool canDelete = !isOperationInProgress;

        return ListTile(
          key: ValueKey(preset.id),
          selected: isCurrentlyLoadedOffline,
          selectedTileColor:
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          title: Text(preset.name.trim()),
          subtitle: Text("Saved: $formattedDate"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Load Button (Calls different cubits based on mode)
              IconButton(
                icon: Icon(
                  isOffline ? Icons.edit_note : Icons.upload_file_outlined,
                  color: canLoad
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                tooltip: isOffline ? 'Load Preset Offline' : 'Send to NT',
                onPressed: canLoad
                    ? () => _showLoadConfirmationDialog(
                        context,
                        preset,
                        isOffline,
                        distingCubit,
                        metadataSyncCubit) // Pass both cubits
                    : null,
              ),
              // Delete Button (Calls MetadataSyncCubit)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: canDelete
                        ? Theme.of(context).colorScheme.error
                        : Colors.grey),
                tooltip: 'Delete Saved Preset',
                onPressed: canDelete
                    ? () => _showDeleteConfirmationDialog(context, preset)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper function for Load Confirmation Dialog
  void _showLoadConfirmationDialog(
      BuildContext context, // BuildContext from ListView item
      PresetEntry preset,
      bool isOffline,
      DistingCubit distingCubit,
      MetadataSyncCubit metadataSyncCubit // Pass both cubits
      ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title:
              Text(isOffline ? 'Load Preset Offline?' : 'Send Preset to NT?'),
          content: Text(isOffline
              ? 'Load "${preset.name}" for offline use?' // Simplified message
              : 'Send "${preset.name}" to device? This overwrites current device state.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(isOffline ? 'Load Offline' : 'Send'),
              onPressed: () async {
                // Pop the dialog first
                Navigator.of(dialogContext).pop();
                try {
                  // Fetch full details (still needed)
                  final fullDetails = await context // Use outer context for DB
                      .read<AppDatabase>()
                      .presetsDao
                      .getFullPresetDetails(preset.id);

                  if (fullDetails != null) {
                    // Call correct Cubit based on mode
                    if (isOffline) {
                      distingCubit.loadPresetOffline(fullDetails);
                      // After loading offline, pop the metadata page
                      // Use the original context from the list item builder
                      if (context.mounted) {
                        // Check if the widget is still mounted
                        Navigator.of(context).pop();
                      }
                    } else {
                      // Need manager instance for online load
                      final onlineManager = distingCubit.disting();
                      if (onlineManager != null) {
                        metadataSyncCubit.loadPresetToDevice(
                            fullDetails, onlineManager);
                      } else {
                        // Should not happen if button is enabled correctly
                        throw Exception(
                            "Cannot load preset: Online manager not available.");
                      }
                    }
                  } else {
                    // Show error if details couldn't be loaded
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "Error: Could not load details for preset '${preset.name}'"),
                          backgroundColor:
                              Theme.of(context).colorScheme.error));
                    }
                  }
                } catch (e) {
                  // Show error if fetching/loading failed
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text("Error fetching/loading preset details: $e"),
                        backgroundColor: Theme.of(context).colorScheme.error));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Helper function for Delete Confirmation Dialog (Uses MetadataSyncCubit)
  void _showDeleteConfirmationDialog(BuildContext context, PresetEntry preset) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Preset?'),
          content: Text(
              'Are you sure you want to permanently delete the saved preset "${preset.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Delete uses MetadataSyncCubit from context
                context.read<MetadataSyncCubit>().deletePreset(preset.id);
              },
            ),
          ],
        );
      },
    );
  }
}

// --- Widget for Algorithm Metadata List View (Stateful for filtering) ---
class _AlgorithmMetadataListView extends StatefulWidget {
  final List<AlgorithmEntry> algorithms;
  final Map<String, int> parameterCounts;

  const _AlgorithmMetadataListView(
      {required this.algorithms, required this.parameterCounts // Added key
      });

  @override
  State<_AlgorithmMetadataListView> createState() =>
      _AlgorithmMetadataListViewState();
}

class _AlgorithmMetadataListViewState
    extends State<_AlgorithmMetadataListView> {
  late final TextEditingController _filterController;
  late List<AlgorithmEntry> _filteredAlgorithms;

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController();
    // Initialize with all algorithms sorted
    _filteredAlgorithms = _sortAlgorithms(widget.algorithms);

    _filterController.addListener(_filterList);
  }

  @override
  void didUpdateWidget(covariant _AlgorithmMetadataListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the underlying algorithm list changes, re-apply filter
    if (widget.algorithms != oldWidget.algorithms) {
      _filterList();
    }
  }

  @override
  void dispose() {
    _filterController.removeListener(_filterList);
    _filterController.dispose();
    super.dispose();
  }

  // Helper to sort algorithms by name
  List<AlgorithmEntry> _sortAlgorithms(List<AlgorithmEntry> algorithms) {
    final sorted = List<AlgorithmEntry>.from(algorithms)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  void _filterList() {
    final query = _filterController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredAlgorithms = _sortAlgorithms(widget.algorithms);
      } else {
        _filteredAlgorithms = _sortAlgorithms(widget.algorithms
            .where((algo) => algo.name.toLowerCase().contains(query))
            .toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle the case where the initial list might be empty
    if (widget.algorithms.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "No algorithms found. Connect your NT and perform a 'Sync From Device'.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _filterController,
            decoration: InputDecoration(
              labelText: "Filter Algorithms",
              hintText: "Enter algorithm name...",
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              // Add clear button
              suffixIcon: _filterController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _filterController.clear();
                        // _filterList will be called by the listener
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          // Display message if filter results are empty
          child: _filteredAlgorithms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No algorithms match "${_filterController.text}".',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _filteredAlgorithms.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final algo = _filteredAlgorithms[index];
                    final count = widget.parameterCounts[algo.guid] ?? 0;
                    return _AlgorithmExpansionTile(
                        algorithm: algo, parameterCount: count);
                  },
                ),
        ),
      ],
    );
  }
}

// --- StatefulWidget for Algorithm Expansion Tile ---
class _AlgorithmExpansionTile extends StatefulWidget {
  final AlgorithmEntry algorithm;
  final int parameterCount;

  const _AlgorithmExpansionTile({
    required this.algorithm,
    required this.parameterCount,
  });

  @override
  State<_AlgorithmExpansionTile> createState() =>
      _AlgorithmExpansionTileState();
}

class _AlgorithmExpansionTileState extends State<_AlgorithmExpansionTile> {
  bool _isLoading = false;
  List<ParameterWithUnit>? _parameters;
  String? _error;

  Future<void> _fetchParameters() async {
    if (_isLoading || _parameters != null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dao = context.read<AppDatabase>().metadataDao;
      final details = await dao.getFullAlgorithmDetails(widget.algorithm.guid);

      if (mounted) {
        setState(() {
          _parameters = details?.parameters ?? [];
          _isLoading = false;
          if (_parameters!.isEmpty && widget.parameterCount > 0) {
            _error =
                "Parameter count is ${widget.parameterCount}, but no parameters were loaded.";
          }
        });
      }
    } catch (e, stacktrace) {
      debugPrint("Error fetching parameters for ${widget.algorithm.guid}: $e");
      debugPrint("Stack trace:\n$stacktrace");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Failed to load parameters: ${e.toString()}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: PageStorageKey(widget.algorithm.guid),
      title: Text(widget.algorithm.name),
      subtitle: Text("Params: ${widget.parameterCount}"),
      childrenPadding:
          const EdgeInsets.only(left: 32.0, right: 16.0, bottom: 8.0),
      onExpansionChanged: (isExpanding) {
        if (isExpanding && _parameters == null && !_isLoading) {
          _fetchParameters();
        }
      },
      children: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          ),
        if (_parameters != null && !_isLoading && _error == null)
          if (_parameters!.isEmpty && widget.parameterCount > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                  child: Text("No parameters found.",
                      style: TextStyle(fontStyle: FontStyle.italic))),
            )
          else if (_parameters!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _parameters!.map((paramWithUnit) {
                final param = paramWithUnit.parameter;
                final pageName = paramWithUnit.pageName ?? 'Unknown Page';

                return ListTile(
                  isThreeLine: true,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(param.name,
                      style: Theme.of(context).textTheme.bodyMedium),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Page: $pageName (#${param.parameterNumber})",
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Range: ${param.minValue ?? '-'} to ${param.maxValue ?? '-'} (Def: ${param.defaultValue ?? '-'}), Unit: ${paramWithUnit.unitString ?? '-'}",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                    child: Text("No parameters for this algorithm.",
                        style: TextStyle(fontStyle: FontStyle.italic)))),
      ],
    );
  }
}
