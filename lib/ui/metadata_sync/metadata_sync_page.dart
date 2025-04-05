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
      create: (context) => MetadataSyncCubit(distingManager, database),
      child: Builder(builder: (context) {
        // Use Builder to get context with Cubit
        return Scaffold(
            appBar: AppBar(
              title: const Text('Sync / Preset Management'),
              leading: BlocBuilder<MetadataSyncCubit, MetadataSyncState>(
                  builder: (context, state) {
                // Back button resets state when viewing data
                return BackButton(
                  onPressed: () {
                    if (state is ViewingLocalData) {
                      // Check type directly
                      context.read<MetadataSyncCubit>().reset();
                    } else {
                      // Only pop if not currently busy
                      state.maybeWhen(
                        idle: () => Navigator.maybePop(context),
                        metadataSyncSuccess: (_) => Navigator.maybePop(context),
                        metadataSyncFailure: (_) => Navigator.maybePop(context),
                        presetSaveSuccess: (_) => Navigator.maybePop(context),
                        presetSaveFailure: (_) => Navigator.maybePop(context),
                        presetLoadSuccess: (_) => Navigator.maybePop(context),
                        presetLoadFailure: (_) => Navigator.maybePop(context),
                        failure: (_) => Navigator.maybePop(context),
                        orElse: () {
                          // Don't pop if syncing, saving, loading, or viewing
                        },
                      );
                    }
                  },
                );
              }),
              actions: [
                // Save Preset Button
                BlocBuilder<MetadataSyncCubit, MetadataSyncState>(
                  builder: (context, state) {
                    // Determine if an operation is in progress
                    final isBusy = state.maybeMap(
                        syncingMetadata: (_) => true,
                        savingPreset: (_) => true,
                        loadingPreset: (_) => true,
                        orElse: () => false);
                    // Can save if connected AND not busy
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
                  presetLoadSuccess: (message) =>
                      _showSnackBar(context, message, Colors.green),
                  presetLoadFailure: (error) => _showSnackBar(
                      context, error, Theme.of(context).colorScheme.error),
                  failure: (error) => _showSnackBar(context, "Error: $error",
                      Theme.of(context).colorScheme.error),
                );
              },
              builder: (context, state) {
                // Determine if an operation is in progress
                final bool isOperationInProgress = state.maybeMap(
                    syncingMetadata: (_) => true,
                    savingPreset: (_) => true,
                    loadingPreset: (_) =>
                        true, // Covers preset load AND local data load
                    orElse: () => false);

                // Decide which main view to show
                if (state is ViewingLocalData) {
                  return _buildDataView(
                    context,
                    state.algorithms,
                    state.parameterCounts,
                    state.presets,
                    isConnected,
                    isOperationInProgress, // Pass this to potentially disable actions within the view
                  );
                } else {
                  // All other states show the controls view
                  return _buildControlsView(
                    context,
                    isConnected,
                    state, // Pass the specific state (Idle, Syncing, Success, Failure, etc.)
                    isOperationInProgress,
                  );
                }
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

  // Main controls view (shown when not viewing data)
  Widget _buildControlsView(
    BuildContext context,
    bool isConnected,
    MetadataSyncState state,
    bool isOperationInProgress,
  ) {
    // Get status message and error status from the current state
    final statusMessage = state.maybeMap(
      metadataSyncSuccess: (s) => s.message,
      metadataSyncFailure: (s) => s.error,
      presetSaveSuccess: (s) => s.message,
      presetSaveFailure: (s) => s.error,
      presetLoadSuccess: (s) => s.message,
      presetLoadFailure: (s) => s.error,
      failure: (s) => s.error,
      orElse: () => null,
    );
    final isError = state.maybeMap(
      metadataSyncFailure: (_) => true,
      presetSaveFailure: (_) => true,
      presetLoadFailure: (_) => true,
      failure: (_) => true,
      orElse: () => false,
    );

    return Padding(
      // Consistent page padding
      padding: const EdgeInsets.all(16.0),
      child: Center(
        // Constrain width for very large screens if desired
        // child: ConstrainedBox(
        //   constraints: BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons
          children: [
            // Disconnected message (only if relevant)
            if (!isConnected && !isOperationInProgress && statusMessage == null)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 24.0), // Increased spacing
                child: Text(
                  "Connect to a Disting NT to Sync Metadata or Manage Presets.",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium // Use titleMedium for prominence
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),

            // Explanatory text (show when not busy)
            if (!isOperationInProgress)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 24.0), // Increased spacing
                child: Text(
                  // Use triple double quotes for multi-line string
                  """Sync metadata for offline use or manage locally saved presets.
Warning: Metadata Sync clears the device preset.""",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            // Remove SizedBox(height: 15)

            // Action Buttons (Show when not busy)
            if (!isOperationInProgress) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text('Sync Metadata'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                onPressed: !isConnected
                    ? null
                    : () =>
                        context.read<MetadataSyncCubit>().startMetadataSync(),
              ),
              const SizedBox(height: 16.0), // Standard spacing
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('View Local Data'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12), // Consistent padding
                  textStyle: Theme.of(context)
                      .textTheme
                      .titleSmall, // Slightly smaller for secondary
                ),
                onPressed: () =>
                    context.read<MetadataSyncCubit>().loadLocalData(),
              ),
            ],

            // Add consistent spacing before Progress/Status
            const SizedBox(height: 24.0),

            // Progress / Status Area
            SizedBox(
              height: 60, // Allocate space for indicator + text
              child: isOperationInProgress
                  ? _buildProgressIndicator(context, state)
                  : statusMessage != null
                      ? _buildStatusMessage(
                          context,
                          statusMessage,
                          isError
                              ? Theme.of(context).colorScheme.error
                              : Colors.green[700])
                      : null, // Empty space if nothing to show
            ),

            // Add spacing before Reset/Cancel buttons if they appear
            if (state.maybeMap(
              metadataSyncSuccess: (_) => true,
              metadataSyncFailure: (_) => true,
              presetSaveSuccess: (_) => true,
              presetSaveFailure: (_) => true,
              presetLoadSuccess: (_) => true,
              presetLoadFailure: (_) => true,
              failure: (_) => true,
              syncingMetadata: (_) => true, // Need space if cancel appears
              orElse: () => false,
            ))
              const SizedBox(height: 16.0),

            // Reset Button
            if (state.maybeMap(
              metadataSyncSuccess: (_) => true,
              metadataSyncFailure: (_) => true,
              presetSaveSuccess: (_) => true,
              presetSaveFailure: (_) => true,
              presetLoadSuccess: (_) => true,
              presetLoadFailure: (_) => true,
              failure: (_) => true,
              orElse: () => false,
            ))
              _buildResetButton(context),

            // Cancel Button
            if (state.maybeMap(
                syncingMetadata: (_) => true, orElse: () => false))
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Sync'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                      color:
                          Theme.of(context).colorScheme.error.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: Theme.of(context).textTheme.titleSmall,
                ),
                onPressed: () =>
                    context.read<MetadataSyncCubit>().cancelMetadataSync(),
              ),
          ],
        ),
        // ),
      ),
    );
  }

  // Progress Indicator Widget (Adjust text style)
  Widget _buildProgressIndicator(
      BuildContext context, MetadataSyncState state) {
    // ... [message and progressValue determination remains the same]
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
      orElse: () {},
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
          style: Theme.of(context)
              .textTheme
              .bodyLarge, // Use bodyLarge for status text
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Status Message Widget (Adjust text style and padding)
  Widget _buildStatusMessage(
      BuildContext context, String message, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Vertical padding
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: color), // Use bodyLarge
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Reset Button Widget (Consider styling)
  Widget _buildResetButton(BuildContext context) {
    return TextButton(
      onPressed: () => context.read<MetadataSyncCubit>().reset(),
      child: const Text('OK'),
      // Optional: Add style if needed
      // style: TextButton.styleFrom(...
    );
  }

  // Tabbed Data View Widget (Add padding to TabBarView)
  Widget _buildDataView(
    BuildContext context,
    List<AlgorithmEntry> algorithms,
    Map<String, int> parameterCounts,
    List<PresetEntry> presets,
    bool isConnected,
    bool isOperationInProgress,
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
              // Add padding around the content of the tabs
              padding:
                  const EdgeInsets.only(top: 8.0), // Add space below tab bar
              child: TabBarView(
                children: [
                  _PresetListView(
                    presets: presets,
                    isConnected: isConnected,
                    isOperationInProgress: isOperationInProgress,
                  ),
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

// --- Widget for Preset List View (Add Dividers) ---
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
            "No presets saved locally yet. Connect to a device and use the save button in the top right.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final sortedPresets = List<PresetEntry>.from(presets)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Use ListView.separated to add dividers
    return ListView.separated(
      itemCount: sortedPresets.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1), // Add divider
      itemBuilder: (context, index) {
        final preset = sortedPresets[index];
        final formattedDate = preset.lastModified.toLocal().toString();
        final canLoad = isConnected && !isOperationInProgress;

        return ListTile(
          key: ValueKey(preset.id),
          title: Text(preset.name),
          subtitle: Text("Saved: $formattedDate"),
          trailing: IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Load Preset to Device',
            color:
                canLoad ? Theme.of(context).colorScheme.primary : Colors.grey,
            onPressed: canLoad
                ? () {
                    showDialog(
                      // ... [Dialog remains the same]
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text('Load Preset?'),
                          content: Text(
                              'This will overwrite the current preset on the connected Disting NT with "${preset.name}". Continue?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(dialogContext)
                                    .pop(); // Close dialog
                              },
                            ),
                            TextButton(
                              child: const Text('Load'),
                              onPressed: () {
                                Navigator.of(dialogContext)
                                    .pop(); // Close dialog
                                // Call cubit method
                                context
                                    .read<MetadataSyncCubit>()
                                    .loadPresetToDevice(preset.id);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                : null,
          ),
        );
      },
    );
  }
}

// --- Widget for Algorithm Metadata List View (Previously _DataListView) ---
class _AlgorithmMetadataListView extends StatelessWidget {
  final List<AlgorithmEntry> algorithms;
  final Map<String, int> parameterCounts;

  const _AlgorithmMetadataListView({
    required this.algorithms,
    required this.parameterCounts,
  });

  @override
  Widget build(BuildContext context) {
    if (algorithms.isEmpty) {
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
    // Sort algorithms by name
    final sortedAlgorithms = List<AlgorithmEntry>.from(algorithms)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ListView.builder(
      itemCount: sortedAlgorithms.length,
      itemBuilder: (context, index) {
        final algo = sortedAlgorithms[index];
        final count = parameterCounts[algo.guid] ?? 0;
        return _AlgorithmExpansionTile(algorithm: algo, parameterCount: count);
      },
    );
  }
}

// --- StatefulWidget for Algorithm Expansion Tile (No changes needed here) ---
// (Assuming this widget remains the same as provided previously)
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
