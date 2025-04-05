import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart'; // To get DistingManager if needed
import 'package:nt_helper/db/database.dart';
// Import needed for ParameterWithUnit used in _AlgorithmExpansionTile
import 'package:nt_helper/db/daos/metadata_dao.dart';
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
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Sync Algorithm Metadata'),
            leading: BlocBuilder<MetadataSyncCubit, MetadataSyncState>(
                builder: (context, state) {
              // Show back button normally, but make it reset state when viewing data
              return BackButton(
                onPressed: () {
                  if (state.maybeMap(
                      viewingData: (_) => true, orElse: () => false)) {
                    context.read<MetadataSyncCubit>().reset();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
              );
            }),
          ),
          body: BlocConsumer<MetadataSyncCubit, MetadataSyncState>(
            listener: (context, state) {
              // Optional: Show snackbars on success/failure
              state.whenOrNull(
                success: (message) => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(
                        content: Text(message), backgroundColor: Colors.green)),
                failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(error),
                        backgroundColor: Theme.of(context).colorScheme.error)),
              );
            },
            builder: (context, state) {
              // Use state.map which forces handling all states
              return state.map(
                // --- Idle State ---
                idle: (_) => _buildControlsView(context, isConnected, state),
                // --- Syncing State ---
                syncing: (syncState) =>
                    _buildControlsView(context, isConnected, syncState),
                // --- Success State ---
                success: (successState) =>
                    _buildControlsView(context, isConnected, successState),
                // --- Failure State ---
                failure: (failureState) =>
                    _buildControlsView(context, isConnected, failureState),
                // --- Viewing Data State ---
                // Updated to use _DataListView
                viewingData: (viewState) => _DataListView(
                  algorithms: viewState.algorithms,
                  parameterCounts: viewState.parameterCounts,
                ),
              );
            },
          )),
    );
  }

  // Consolidated widget for Sync Controls
  Widget _buildControlsView(
    BuildContext context,
    bool isConnected,
    MetadataSyncState state,
  ) {
    final isSyncing = state.maybeMap(syncing: (_) => true, orElse: () => false);
    final syncState = state.maybeMap(syncing: (s) => s, orElse: () => null);
    final statusMessage = state.maybeMap(
        success: (s) => s.message, failure: (s) => s.error, orElse: () => null);
    final isError = state.maybeMap(failure: (_) => true, orElse: () => false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Disconnected message (only show if relevant and not showing another message)
            if (!isConnected && !isSyncing && statusMessage == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  "Please connect to a Disting NT first to sync.",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),

            // Explanatory text (show when not syncing)
            if (!isSyncing)
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Text(
                  'Sync algorithm definitions from the device to the local database for offline use.\n\nWarning: This process will clear the current device preset. Save any work before continuing.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            const SizedBox(height: 15),

            // --- Action Buttons (Show when NOT syncing) ---
            if (!isSyncing) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text('Start Full Sync'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                onPressed: !isConnected // Disable if not connected
                    ? null
                    : () => context.read<MetadataSyncCubit>().startSync(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.storage_rounded),
                  label: const Text('View Synced Data'),
                  onPressed: () =>
                      context.read<MetadataSyncCubit>().viewSyncedData(),
                ),
              ),
            ],
            // --- Cancel Button (Show ONLY when syncing) ---
            if (isSyncing)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Sync'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.5)),
                  ),
                  onPressed: () =>
                      context.read<MetadataSyncCubit>().cancelSync(),
                ),
              ),

            const SizedBox(height: 20),

            // --- Progress / Status Message Area ---
            // Show progress only when syncing
            if (isSyncing && syncState != null)
              _buildProgressIndicator(context, syncState),

            // Show status message ONLY when not syncing and there IS a status message (Success/Failure)
            if (!isSyncing && statusMessage != null)
              _buildStatusMessage(
                context,
                statusMessage,
                isError
                    ? Theme.of(context).colorScheme.error
                    : Colors.green[700],
              ),

            // Reset Button (Show on Success/Failure or Cancelled state, which is a failure state)
            if (state.maybeMap(
                success: (_) => true,
                failure: (_) => true,
                orElse: () => false))
              _buildResetButton(context),
          ],
        ),
      ),
    );
  }

  // Helper for progress indicator + text (Accepts Syncing state)
  Widget _buildProgressIndicator(BuildContext context, Syncing syncState) {
    final progress = syncState.progress;
    final mainMessage = syncState.mainMessage; // Use mainMessage from state

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress > 0 ? progress : null,
          minHeight: 8,
          backgroundColor: Colors.grey[300],
        ),
        const SizedBox(height: 12), // Adjusted spacing

        // Main Status Message (e.g., "Processing Algorithm X (15/128)")
        Container(
          height: 40, // Give it enough height for potentially two lines
          alignment: Alignment.center,
          child: Text(
            mainMessage, // Display mainMessage
            style:
                Theme.of(context).textTheme.titleMedium, // Back to titleMedium
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper for status messages
  Widget _buildStatusMessage(
      BuildContext context, String message, Color? color) {
    // Use a fixed-height container here too for consistency
    return Container(
      height: 40, // Match the height in _buildProgressIndicator
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Text(
          message,
          style: TextStyle(color: color),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Helper for reset button
  Widget _buildResetButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: TextButton(
        onPressed: () => context.read<MetadataSyncCubit>().reset(),
        child: const Text('OK / Reset'),
      ),
    );
  }

  // REMOVED: _buildDataView - Replaced by _DataListView below
}

// --- New Widget for Data List View ---
class _DataListView extends StatelessWidget {
  final List<AlgorithmEntry> algorithms;
  final Map<String, int> parameterCounts;

  const _DataListView({
    required this.algorithms,
    required this.parameterCounts,
  });

  @override
  Widget build(BuildContext context) {
    if (algorithms.isEmpty) {
      // Provide a way back if the list is empty after attempting to view
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("No algorithm metadata found in the local database."),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => context.read<MetadataSyncCubit>().reset(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: algorithms.length,
      itemBuilder: (context, index) {
        final algo = algorithms[index];
        final count = parameterCounts[algo.guid] ?? 0; // Get count from map
        // Use the new stateful tile widget
        return _AlgorithmExpansionTile(algorithm: algo, parameterCount: count);
      },
    );
  }
}

// --- New StatefulWidget for each Algorithm Tile ---
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
  List<ParameterWithUnit>? _parameters; // Store fetched parameters
  String? _error;

  Future<void> _fetchParameters() async {
    // Avoid fetching if already loading or already fetched parameters
    if (_isLoading || _parameters != null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Access DAO directly via context.read (AppDatabase provided higher up)
      final dao = context.read<AppDatabase>().metadataDao;
      // Fetch full details which includes ParameterWithUnit list
      final details = await dao.getFullAlgorithmDetails(widget.algorithm.guid);

      if (mounted) {
        // Check if widget is still in the tree before updating state
        setState(() {
          _parameters = details?.parameters ?? []; // Store fetched params
          _isLoading = false;
          // Check if the fetched list is empty despite the count being > 0
          if (_parameters!.isEmpty && widget.parameterCount > 0) {
            _error =
                "Parameter count is ${widget.parameterCount}, but no parameters were loaded.";
          }
        });
      }
    } catch (e, stacktrace) {
      // Corrected print statement for clarity
      print("Error fetching parameters for ${widget.algorithm.guid}: $e");
      print("Stack trace:\n$stacktrace");
      if (mounted) {
        // Check if widget is still in the tree before updating state
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
      key: PageStorageKey(
          widget.algorithm.guid), // Maintain expansion state on scroll
      title: Text(widget.algorithm.name),
      subtitle: Text("Params: ${widget.parameterCount}"), // Display count
      childrenPadding:
          const EdgeInsets.only(left: 32.0, right: 16.0, bottom: 8.0),
      onExpansionChanged: (isExpanding) {
        // Fetch data only when expanding for the first time
        if (isExpanding && _parameters == null && !_isLoading) {
          _fetchParameters();
        }
      },
      children: [
        // --- Loading State ---
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        // --- Error State ---
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          ),
        // --- Data State ---
        if (_parameters != null && !_isLoading && _error == null)
          // Show message if count > 0 but list is empty (but no error occurred during fetch)
          if (_parameters!.isEmpty && widget.parameterCount > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                  child: Text("No parameters found.",
                      style: TextStyle(fontStyle: FontStyle.italic))),
            )
          // Build list of parameters if available
          else if (_parameters!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _parameters!.map((paramWithUnit) {
                final param = paramWithUnit.parameter;
                final pageName =
                    paramWithUnit.pageName ?? 'Unknown Page'; // Get page name

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
                        // First line: Page and Parameter number
                        "Page: $pageName (#${param.parameterNumber})",
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        // Second line: Min/Max/Default and Unit
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
          // If parameters list is empty AND count was 0, show simple message
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
