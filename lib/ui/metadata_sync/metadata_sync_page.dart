import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart'; // To get DistingManager if needed
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/ui/metadata_sync/metadata_sync_cubit.dart';

class MetadataSyncPage extends StatelessWidget {
  const MetadataSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get dependencies needed by the MetadataSyncCubit
    // We assume DistingCubit is already provided higher up if we need the manager
    // If Disting is connected, get the manager, otherwise disable sync?
    final distingCubit = BlocProvider.of<DistingCubit>(context);
    final database = context.read<AppDatabase>(); // From RepositoryProvider
    final distingManager = distingCubit.disting(); // Get manager (can be null!)

    return BlocProvider(
      create: (context) => MetadataSyncCubit(distingManager!, database),
      // Note: Potential issue if distingManager is null. Consider disabling the button
      // or handling the null case within the cubit or here.
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Sync Algorithm Metadata'),
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
              bool isSyncing = state is Syncing;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (distingManager == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            "Please connect to a Disting NT first.",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: Theme.of(context).colorScheme.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Text(
                        'This process will query the connected Disting NT for all available algorithm definitions (parameters, units, pages, etc.) and save them to the local database for offline use and faster loading.\n\nIt will temporarily clear the current preset on the device during the sync.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 30),
                      if (state is Idle || state is Success || state is Failure)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.sync),
                          label: const Text('Start Full Sync'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            textStyle: Theme.of(context).textTheme.titleMedium,
                          ),
                          // Disable button if not connected or already syncing
                          onPressed: (isSyncing || distingManager == null)
                              ? null
                              : () =>
                                  context.read<MetadataSyncCubit>().startSync(),
                        ),
                      if (state is Syncing)
                        Column(
                          children: [
                            CircularProgressIndicator(value: state.progress),
                            const SizedBox(height: 20),
                            Text(
                              state.message,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      if (state is Success)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Text(state.message,
                              style: TextStyle(color: Colors.green[700])),
                        ),
                      if (state is Failure)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Text(state.error,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        ),
                      if (state is Success || state is Failure)
                        Padding(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: TextButton(
                            onPressed: () =>
                                context.read<MetadataSyncCubit>().reset(),
                            child: const Text('OK / Reset'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          )),
    );
  }
}
