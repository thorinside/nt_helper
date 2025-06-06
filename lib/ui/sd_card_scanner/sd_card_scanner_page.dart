import 'package:flutter/material.dart';
import 'dart:io'; // Import for Platform
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BLoC package
import 'package:nt_helper/db/database.dart'; // For AppDatabase
import 'package:nt_helper/models/parsed_preset_data.dart'; // Added import for ParsedPresetData
import 'package:nt_helper/ui/sd_card_scanner/bloc/sd_card_scanner_bloc.dart';
import 'package:nt_helper/ui/sd_card_scanner/bloc/sd_card_scanner_event.dart'; // Added import for events
import 'package:nt_helper/ui/sd_card_scanner/sd_card_scanner_state.dart'; // For ScanStatus
import 'package:nt_helper/util/file_system_utils.dart';
import 'package:path/path.dart' as p; // For joining paths
import 'package:nt_helper/ui/sd_card_scanner/widgets/sd_card_selection_card.dart';
import 'package:nt_helper/ui/sd_card_scanner/widgets/scanning_progress_card.dart'; // Import progress card
import 'package:nt_helper/ui/sd_card_scanner/widgets/scanned_card_management_item.dart'; // Import management item
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:docman/docman.dart' as docman; // For DocumentFile type checking
import 'package:nt_helper/ui/common/log_display_page.dart'; // Import the log page

// Model for scanned card data
class ScannedCardData {
  final String id; // Path to the SD card root can serve as a unique ID
  String name;
  DateTime? lastScanDate; // Made nullable
  int presetCount;
  List<ParsedPresetData> parsedPresets; // Store parsed presets for this card

  ScannedCardData({
    required this.id,
    required this.name,
    this.lastScanDate, // Made nullable, no longer required
    required this.presetCount,
    this.parsedPresets = const [],
  });
}

class SdCardScannerPage extends StatelessWidget {
  const SdCardScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (blocContext) =>
          SdCardScannerBloc(blocContext.read<AppDatabase>())
            ..add(const LoadScannedCards()), // Load cards on creation
      child: const _SdCardScannerView(),
    );
  }
}

// New private widget to build the UI, listening to the BLoC
class _SdCardScannerView extends StatelessWidget {
  const _SdCardScannerView();

  // Method to show the dialog for new card scanning or rescan
  void _showSdCardSelectionDialog(BuildContext context,
      {String? existingSdCardRootPath,
      String? existingCardName,
      bool isRescan = false}) {
    final sdCardScannerBloc = context.read<SdCardScannerBloc>();

    showDialog(
      context: context,
      barrierDismissible:
          sdCardScannerBloc.state.status != ScanStatus.findingFiles &&
              sdCardScannerBloc.state.status != ScanStatus.parsing &&
              sdCardScannerBloc.state.status != ScanStatus.saving,
      builder: (BuildContext dialogContext) {
        return BlocBuilder<SdCardScannerBloc, SdCardScannerState>(
            bloc: sdCardScannerBloc,
            builder: (context, state) {
              final bool isScanningInDialog =
                  state.status == ScanStatus.findingFiles ||
                      state.status == ScanStatus.parsing ||
                      state.status == ScanStatus.saving;

              return AlertDialog(
                title: const Text('Scan SD Card'), // General title
                content: SingleChildScrollView(
                  // Assuming SdCardSelectionCard is updated as per previous instructions
                  // to handle sdCardRoot and relativePresetsPath input.
                  child: SdCardSelectionCard(
                    initialSdCardRootPath: existingSdCardRootPath,
                    initialCardName: existingCardName,
                    isRescan: isRescan,
                    onScanRequested: (dynamic pickedSdCardRootIdentifier,
                        String relativePresetsPath, String cardName) {
                      Navigator.of(dialogContext).pop(); // Close dialog first

                      if (pickedSdCardRootIdentifier == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('SD Card Root not selected.')),
                        );
                        return;
                      }

                      String sdCardRootPathOrUriString;
                      if (!kIsWeb &&
                          Platform.isAndroid &&
                          pickedSdCardRootIdentifier is docman.DocumentFile) {
                        sdCardRootPathOrUriString =
                            pickedSdCardRootIdentifier.uri.toString();
                      } else if (pickedSdCardRootIdentifier is String) {
                        sdCardRootPathOrUriString = pickedSdCardRootIdentifier;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Error: Invalid SD Card Root directory type.')),
                        );
                        return;
                      }

                      if (isRescan) {
                        sdCardScannerBloc.add(RescanCardRequested(
                            cardIdPath:
                                sdCardRootPathOrUriString, // This is the SD card root
                            relativePresetsPath: relativePresetsPath,
                            cardName: cardName));
                      } else {
                        sdCardScannerBloc.add(ScanRequested(
                            sdCardRootPathOrUri: sdCardRootPathOrUriString,
                            relativePresetsPath: relativePresetsPath,
                            cardName: cardName));
                      }
                    },
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: isScanningInDialog
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SD Card Scanner'),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.developer_mode), // Or any other suitable icon
            tooltip: 'View Scan Logs',
            onPressed: () {
              Navigator.of(context).push(LogDisplayPage.route());
            },
          ),
        ],
      ),
      body: BlocConsumer<SdCardScannerBloc, SdCardScannerState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red),
            );
            context.read<SdCardScannerBloc>().add(const ClearMessages());
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green),
            );
            context.read<SdCardScannerBloc>().add(const ClearMessages());
          }
        },
        builder: (context, state) {
          final bool isScanning = state.status == ScanStatus.findingFiles ||
              state.status == ScanStatus.parsing ||
              state.status == ScanStatus.saving;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: isScanning
                ? _buildScanningUI(context, state) // Pass context here
                : _buildInitialOrCompleteUI(state, context),
          );
        },
      ),
      floatingActionButton: BlocBuilder<SdCardScannerBloc, SdCardScannerState>(
        builder: (context, state) {
          final bool isScanning = state.status == ScanStatus.findingFiles ||
              state.status == ScanStatus.parsing ||
              state.status == ScanStatus.saving;
          return isScanning
              ? const SizedBox.shrink() // Hide FAB when scanning
              : FloatingActionButton.extended(
                  onPressed: () =>
                      _showSdCardSelectionDialog(context, isRescan: false),
                  icon: const Icon(Icons.add_circle_outline), // Changed Icon
                  label: const Text('Scan SD Card'), // Changed FAB label
                );
        },
      ),
    );
  }

  Widget _buildScanningUI(BuildContext context, SdCardScannerState state) {
    // Added context parameter
    return Center(
      child: ScanningProgressCard(
        progress: state.scanProgress,
        filesProcessed: state.filesProcessed,
        totalFiles: state.totalFiles,
        currentFile: state.currentFile,
        onCancel: () => context
            .read<SdCardScannerBloc>()
            .add(const ScanCancelled()), // context is now defined
      ),
    );
  }

  Widget _buildInitialOrCompleteUI(
      SdCardScannerState state, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Scanned SD Cards',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text('${state.scannedCards.length} card(s)',
                style: Theme.of(context).textTheme.bodySmall)
          ],
        ),
        const SizedBox(height: 8),
        if (state.scannedCards.isEmpty && state.status != ScanStatus.initial)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  state.status == ScanStatus.error && state.errorMessage != null
                      ? state.errorMessage!
                      : 'No SD cards have been scanned yet. Click the "+" button below to specify an SD card root and its presets path.', // Updated empty state text
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: state.status == ScanStatus.error
                          ? Colors.red
                          : Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else if (state.status == ScanStatus.initial)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.builder(
              itemCount: state.scannedCards.length,
              itemBuilder: (context, index) {
                final card = state.scannedCards[index];
                return ScannedCardManagementItem(
                  key: ValueKey(card.id),
                  cardName: card.name,
                  lastScanDate: card.lastScanDate,
                  presetCount: card.presetCount,
                  onRescan: () {
                    _showSdCardSelectionDialog(context,
                        existingSdCardRootPath:
                            card.id, // card.id is the root path/URI
                        existingCardName: card.name,
                        isRescan: true);
                  },
                  onRemove: () => context
                      .read<SdCardScannerBloc>()
                      .add(RemoveCardRequested(cardIdPath: card.id)),
                );
              },
            ),
          ),
      ],
    );
  }
}
