import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart'; // Removed unused import
import 'package:nt_helper/cubit/disting_cubit.dart'; // To get DistingManager if needed
import 'package:nt_helper/db/database.dart';
// Import needed for ParameterWithUnit used in _AlgorithmExpansionTile
import 'package:nt_helper/db/daos/metadata_dao.dart'; // For AlgorithmEntry
import 'package:nt_helper/db/daos/presets_dao.dart'; // For PresetEntry
import 'package:nt_helper/ui/metadata_sync/metadata_sync_cubit.dart';

class MetadataSyncPage extends StatelessWidget {
  // Accept DistingCubit as a parameter
  final DistingCubit distingCubit;

  const MetadataSyncPage({super.key, required this.distingCubit});

  @override
  Widget build(BuildContext context) {
    // Get AppDatabase from context (RepositoryProvider)
    final database = context.read<AppDatabase>();
    // Use the passed distingCubit to get the manager
    final distingManager = distingCubit.disting(); // Get manager (can be null!)
    final bool isConnected = distingManager != null;

    return BlocProvider(
      create: (context) =>
          MetadataSyncCubit(distingManager, database)..loadLocalData(),
      child: Builder(builder: (context) {
        // Use Builder to get context with Cubit
        return Scaffold(
            appBar: AppBar(
              title: const Text('Local Data / Sync'),
              leading: BlocBuilder<MetadataSyncCubit, MetadataSyncState>(
                  builder: (context, state) {
                // Back button should always work now, just pop
                return BackButton(onPressed: () => Navigator.maybePop(context));
              }),
              actions: [
                BlocBuilder<MetadataSyncCubit, MetadataSyncState>(
                  builder: (context, state) {
                    final isBusy = state.maybeMap(
                        syncingMetadata: (_) => true,
                        savingPreset: (_) => true,
                        loadingPreset: (_) => true,
                        deletingPreset: (_) => true,
                        orElse: () => false);
                    final canSync = isConnected && !isBusy;
                    return IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: 'Sync Metadata From Device',
                      onPressed: canSync
                          ? () => _showSyncConfirmationDialog(context)
                          : null,
                    );
                  },
                ),
                BlocBuilder<MetadataSyncCubit, MetadataSyncState>(
                  builder: (context, state) {
                    final isBusy = state.maybeMap(
                        syncingMetadata: (_) => true,
                        savingPreset: (_) => true,
                        loadingPreset: (_) => true,
                        deletingPreset: (_) => true,
                        orElse: () => false);
                    final canSave = isConnected && !isBusy;
                    return IconButton(
                      icon: const Icon(Icons.save_alt_outlined),
                      tooltip: 'Save Current Device Preset',
                      onPressed: canSave
                          ? () => context
                              .read<MetadataSyncCubit>()
                              .saveCurrentPreset()
                          : null,
                    );
                  },
                ),
              ],
            ),
            body: BlocConsumer<MetadataSyncCubit, MetadataSyncState>(
              listener: (context, state) {
                // Show snackbars on operation outcomes
                state.whenOrNull(
                  metadataSyncSuccess: (message) =>
                      _showSnackBar(context, message, Colors.green),
                  metadataSyncFailure: (error) => _showSnackBar(
                      context, error, Theme.of(context).colorScheme.error),
                  presetSaveSuccess: (message) =>
                      _showSnackBar(context, message, Colors.green),
                  presetSaveFailure: (error) => _showSnackBar(
                      context, error, Theme.of(context).colorScheme.error),
                  presetDeleteSuccess:
                      (message) => // Added listener for delete success
                          _showSnackBar(context, message, Colors.green),
                  presetDeleteFailure:
                      (error) => // Added listener for delete failure
                          _showSnackBar(context, error,
                              Theme.of(context).colorScheme.error),
                  presetLoadSuccess: (message) =>
                      _showSnackBar(context, message, Colors.green),
                  presetLoadFailure: (error) => _showSnackBar(
                      context, error, Theme.of(context).colorScheme.error),
                  failure: (error) => _showSnackBar(
                      context,
                      "Error loading data: $error",
                      Theme.of(context).colorScheme.error),
                );
              },
              builder: (context, state) {
                // Determine if an operation is in progress
                final bool isOperationInProgress = state.maybeMap(
                    syncingMetadata: (_) => true,
                    savingPreset: (_) => true,
                    loadingPreset: (_) => true,
                    deletingPreset: (_) => true,
                    orElse: () => false);

                // Loading states (initial or refresh)
                if (state is Idle || state is LoadingPreset) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Failure states
                if (state is Failure ||
                    state is MetadataSyncFailure ||
                    state is PresetSaveFailure ||
                    state is PresetDeleteFailure ||
                    state is PresetLoadFailure) {
                  String errorMsg = state.mapOrNull(
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
                              onPressed: () =>
                                  context.read<MetadataSyncCubit>().reset(),
                              child: const Text("Retry"))
                        ]),
                  ));
                }

                // Busy states (Syncing, Saving, Deleting) show progress indicator
                if (state is SyncingMetadata ||
                    state is SavingPreset ||
                    state is DeletingPreset) {
                  return Center(child: _buildProgressIndicator(context, state));
                }

                // Data loaded state (also shown during transient success states before reload)
                if (state is ViewingLocalData ||
                    state is MetadataSyncSuccess ||
                    state is PresetSaveSuccess ||
                    state is PresetDeleteSuccess ||
                    state is PresetLoadSuccess) {
                  // Try to get data, might be null during success states before reload
                  List<AlgorithmEntry> algos = state.maybeMap(
                      viewingLocalData: (s) => s.algorithms, orElse: () => []);
                  Map<String, int> counts = state.maybeMap(
                      viewingLocalData: (s) => s.parameterCounts,
                      orElse: () => {});
                  List<PresetEntry> presets = state.maybeMap(
                      viewingLocalData: (s) => s.presets, orElse: () => []);

                  // If data is empty during a success state, show loading briefly
                  if (state is! ViewingLocalData &&
                      presets.isEmpty &&
                      algos.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return _buildDataView(
                    context,
                    algos, // Use potentially empty list during transition
                    counts,
                    presets,
                    isConnected,
                    isOperationInProgress, // Pass busy status
                  );
                }

                // Fallback (should not be reached)
                return const Center(child: Text("Unhandled state"));
              },
            ));
      }),
    );
  }

  // Helper to show snackbars
  void _showSnackBar(
      BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context)
        .removeCurrentSnackBar(); // Remove previous snackbar
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor));
  }

  // Progress Indicator Widget (No changes needed from previous version)
  Widget _buildProgressIndicator(
      BuildContext context, MetadataSyncState state) {
    // ... (implementation from previous step) ...
    String mainMessage = "Processing...";
    double? progressValue; // Null for indeterminate

    state.maybeWhen(
      syncingMetadata: (progress, mainMsg, subMsg, processed, total) {
        mainMessage = mainMsg;
        progressValue = progress > 0 ? progress : null; // Show progress if > 0
      },
      savingPreset: () => mainMessage = "Saving Preset...",
      loadingPreset: () =>
          mainMessage = "Loading...", // Covers preset load and data load
      deletingPreset: () => mainMessage = "Deleting Preset...", // Added message
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
          style:
              Theme.of(context).textTheme.titleMedium, // Keep consistent style
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Confirmation Dialog for Metadata Sync
  void _showSyncConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sync Metadata?'),
          content: const Text(
              'This process reads all algorithm data from the device and requires clearing the current preset. Save any work on the device first! Continue?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Sync'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<MetadataSyncCubit>().startMetadataSync();
              },
            ),
          ],
        );
      },
    );
  }

  // Tabbed Data View Widget (No major changes needed from previous step)
  Widget _buildDataView(
    BuildContext context,
    List<AlgorithmEntry> algorithms,
    Map<String, int> parameterCounts,
    List<PresetEntry> presets,
    bool isConnected,
    bool isOperationInProgress,
  ) {
    // ... (implementation from previous step) ...
    return DefaultTabController(
      length: 2, // Two tabs: Presets and Algorithms
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
                    isConnected: isConnected,
                    isOperationInProgress: isOperationInProgress,
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
  final bool isConnected;
  final bool isOperationInProgress; // To disable load button

  const _PresetListView(
      {required this.presets,
      required this.isConnected,
      required this.isOperationInProgress,
      super.key // Added key
      });

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
        // Use local time for display
        final formattedDate =
            preset.lastModified.toLocal().toString(); // Simple fallback
        // Can load if connected AND no other operation is in progress
        final canLoad = isConnected && !isOperationInProgress;
        final canDelete =
            !isOperationInProgress; // Can always delete unless busy

        return ListTile(
          key: ValueKey(preset.id),
          title: Text(preset.name.trim()), // Trim the name for display
          subtitle: Text("Saved: $formattedDate"), // Use simple string date
          trailing: Row(
            mainAxisSize: MainAxisSize.min, // Prevent row from expanding
            children: [
              // Load Button
              IconButton(
                icon: const Icon(Icons.upload_file_outlined),
                tooltip: 'Send to NT',
                color: canLoad
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                onPressed: canLoad
                    ? () => _showLoadConfirmationDialog(context, preset)
                    : null,
              ),
              // Delete Button
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
  void _showLoadConfirmationDialog(BuildContext context, PresetEntry preset) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Send Preset to NT?'),
          content: Text(
              'This will overwrite the current preset on the connected Disting NT with "${preset.name}". Continue?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
            ),
            TextButton(
              child: const Text('Send'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                try {
                  // Fetch full details before calling cubit
                  final fullDetails = await context
                      .read<AppDatabase>()
                      .presetsDao
                      .getFullPresetDetails(preset.id);
                  if (fullDetails != null) {
                    // Call cubit method with full details
                    // Use 'context' from the outer scope, not dialogContext
                    context
                        .read<MetadataSyncCubit>()
                        .loadPresetToDevice(fullDetails);
                  } else {
                    // Handle error: Preset details not found
                    // Call ScaffoldMessenger directly
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "Error: Could not load details for preset '${preset.name}'"),
                        backgroundColor: Theme.of(context).colorScheme.error));
                  }
                } catch (e) {
                  // Handle potential error during fetch
                  // Call ScaffoldMessenger directly
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Error fetching preset details: $e"),
                      backgroundColor: Theme.of(context).colorScheme.error));
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Helper function for Delete Confirmation Dialog
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
                Navigator.of(dialogContext).pop(); // Close dialog
              },
            ),
            TextButton(
              // Make delete action visually distinct
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                // Call cubit method
                context.read<MetadataSyncCubit>().deletePreset(preset.id);
              },
            ),
          ],
        );
      },
    );
  }
}

// --- Widget for Algorithm Metadata List View (Previously _DataListView) ---
// Converted to StatefulWidget for filtering
class _AlgorithmMetadataListView extends StatefulWidget {
  final List<AlgorithmEntry> algorithms;
  final Map<String, int> parameterCounts;

  const _AlgorithmMetadataListView(
      {required this.algorithms,
      required this.parameterCounts,
      super.key // Added key
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
            "No algorithm metadata found. Connect to a device and perform a 'Sync Metadata' operation.",
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

// --- StatefulWidget for Algorithm Expansion Tile (No changes needed here) ---
class _AlgorithmExpansionTile extends StatefulWidget {
  final AlgorithmEntry algorithm;
  final int parameterCount;

  const _AlgorithmExpansionTile(
      {required this.algorithm,
      required this.parameterCount,
      super.key // Added key
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
      print("Error fetching parameters for ${widget.algorithm.guid}: $e");
      print("Stack trace:\n$stacktrace");
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
