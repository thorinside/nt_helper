import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/db/database.dart'; // For AppDatabase and appDatabaseProvider
import 'package:nt_helper/models/parsed_preset_data.dart';
import 'package:nt_helper/ui/sd_card_scanner/sd_card_scanner_state.dart';
import 'package:nt_helper/util/file_system_utils.dart';
import 'package:nt_helper/util/preset_parser_utils.dart';
import 'package:nt_helper/ui/sd_card_scanner/sd_card_scanner_page.dart'
    show ScannedCardData;
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' hide Column;
import 'package:docman/docman.dart' as docman;
import 'package:nt_helper/util/in_app_logger.dart';

import 'sd_card_scanner_event.dart';

class SdCardScannerBloc extends Bloc<SdCardScannerEvent, SdCardScannerState> {
  final AppDatabase _db;

  SdCardScannerBloc(this._db) : super(const SdCardScannerState()) {
    on<LoadScannedCards>(_onLoadScannedCards);
    on<ScanRequested>(_onScanRequested);
    on<RescanCardRequested>(_onRescanCardRequested);
    on<ScanCancelled>(_onScanCancelled);
    on<RemoveCardRequested>(_onRemoveCardRequested);
    on<ClearMessages>(_onClearMessages);

    add(const LoadScannedCards());
  }

  Future<void> _onLoadScannedCards(
    LoadScannedCards event,
    Emitter<SdCardScannerState> emit,
  ) async {
    emit(state.copyWith(
        status: ScanStatus.initial,
        scannedCards: [],
        errorMessage: null,
        successMessage: null));
    try {
      final cardsWithCounts =
          await _db.sdCardsDao.getAllSdCardsWithPresetCounts();

      final uiCards = cardsWithCounts.map((cardWithCount) {
        return ScannedCardData(
          id: cardWithCount.sdCard.systemIdentifier ?? '',
          name: cardWithCount.sdCard.userLabel,
          presetCount: cardWithCount.presetCount,
          lastScanDate: null,
        );
      }).toList();
      emit(state.copyWith(
        status: ScanStatus.complete,
        scannedCards: uiCards,
        successMessage: null,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage: e.toString(),
          successMessage: null));
    }
  }

  Future<void> _onScanRequested(
    ScanRequested event,
    Emitter<SdCardScannerState> emit,
  ) async {
    await _performScanAndSaveOperations(event.path, event.cardName, emit,
        isRescan: false);
  }

  Future<void> _onRescanCardRequested(
    RescanCardRequested event,
    Emitter<SdCardScannerState> emit,
  ) async {
    await _performScanAndSaveOperations(event.cardIdPath, event.cardName, emit,
        isRescan: true);
    add(const LoadScannedCards());
  }

  Future<void> _performScanAndSaveOperations(
      String cardIdentifier, String cardName, Emitter<SdCardScannerState> emit,
      {bool isRescan = false}) async {
    final String operationType = isRescan ? "Rescan" : "Scan";
    emit(state.copyWith(
        status: ScanStatus.findingFiles,
        currentFile: "Preparing for $operationType of '$cardName'...",
        scanProgress: 0.0,
        filesProcessed: 0,
        totalFiles: 0,
        errorMessage: null,
        successMessage: null));

    dynamic sdCardRootIdentifier = cardIdentifier;
    String displayPath = cardIdentifier;

    // --- iOS Debug: Print selected root path and check existence ---
    if (!kIsWeb && Platform.isIOS && sdCardRootIdentifier is String) {
      InAppLogger().log(
          "iOS - Selected SD Card Root Path from FilePicker: $sdCardRootIdentifier");
      try {
        final rootDir = Directory(sdCardRootIdentifier);
        final exists = await rootDir.exists();
        InAppLogger().log(
            "iOS - Root Directory ($sdCardRootIdentifier) reported exists: $exists");
      } catch (e) {
        InAppLogger().log("iOS - Error checking rootDir.exists(): $e");
      }
    }
    // --- End iOS Debug ---

    if (!kIsWeb &&
        Platform.isAndroid &&
        cardIdentifier.startsWith('content://')) {
      try {
        sdCardRootIdentifier =
            await docman.DocumentFile.fromUri(cardIdentifier);
        if (sdCardRootIdentifier == null || !sdCardRootIdentifier.exists) {
          emit(state.copyWith(
              status: ScanStatus.error,
              errorMessage:
                  "Error: Could not access SD card at '$cardIdentifier'. Please re-select. DocumentFile is null or does not exist."));
          return;
        }
        displayPath = sdCardRootIdentifier.name ?? cardIdentifier;
      } catch (e) {
        InAppLogger().log(
            'Error getting DocumentFile from URI $cardIdentifier: ${e.toString()}');
        emit(state.copyWith(
            status: ScanStatus.error,
            errorMessage:
                "Error accessing SD card at '$cardIdentifier'. Details: ${e.toString()}"));
        return;
      }
    }

    emit(state.copyWith(
        status: ScanStatus.findingFiles,
        currentFile: "Locating 'presets' directory in $displayPath..."));

    dynamic presetsDirIdentifier;
    String presetsDisplayPath = "presets"; // Default display name

    if (sdCardRootIdentifier is docman.DocumentFile) {
      presetsDirIdentifier = await sdCardRootIdentifier.find('presets');
      if (presetsDirIdentifier == null ||
          !presetsDirIdentifier.exists ||
          !presetsDirIdentifier.isDirectory) {
        emit(state.copyWith(
            status: ScanStatus.error,
            errorMessage:
                "Error: Could not find or access 'presets' directory on '$displayPath'. It may not exist or is not a directory."));
        return;
      }
      presetsDisplayPath = presetsDirIdentifier.name ?? "presets";
    } else if (sdCardRootIdentifier is String) {
      presetsDirIdentifier = p.join(sdCardRootIdentifier, 'presets');

      // --- iOS Debug: Print expected presets path and check existence ---
      if (!kIsWeb && Platform.isIOS) {
        InAppLogger()
            .log("iOS - Calculated presets path: $presetsDirIdentifier");
        try {
          final presetsDirObj = Directory(presetsDirIdentifier as String);
          final presetsExists = await presetsDirObj.exists();
          InAppLogger().log(
              "iOS - Presets Directory ($presetsDirIdentifier) reported exists: $presetsExists");
        } catch (e) {
          InAppLogger().log("iOS - Error checking presetsDirObj.exists(): $e");
        }
      }
      // --- End iOS Debug ---

      // For desktop, check if this path exists and is a directory
      final desktopPresetsDir = Directory(presetsDirIdentifier as String);
      if (!await desktopPresetsDir.exists()) {
        emit(state.copyWith(
            status: ScanStatus.error,
            errorMessage:
                "Error: Could not find 'presets' directory at '$presetsDirIdentifier'."));
        return;
      }
      presetsDisplayPath =
          presetsDirIdentifier; // Use the full path for display on desktop
    } else {
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage:
              "Internal error: Invalid SD card root identifier type. Path: $sdCardRootIdentifier"));
      return;
    }

    final isValid =
        await FileSystemUtils.isValidDistingSdCard(sdCardRootIdentifier);
    if (!isValid) {
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage:
              "Error: '$displayPath' is not a valid Disting SD Card (missing /presets folder)."));
      return;
    }

    emit(state.copyWith(
        status: ScanStatus.findingFiles,
        currentFile: "Finding preset files in $presetsDisplayPath..."));

    final List<(String uri, String relativePath)> presetFileIdentifiers;
    try {
      presetFileIdentifiers =
          await FileSystemUtils.findPresetFiles(presetsDirIdentifier);
    } catch (e, s) {
      InAppLogger().log('Error finding preset files: $e\n$s');
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage: "Failed to find preset files: ${e.toString()}"));
      return;
    }

    if (presetFileIdentifiers.isEmpty) {
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage: "No preset files (.json) found in $displayPath."));
      return;
    }

    emit(state.copyWith(
        status: ScanStatus.parsing,
        totalFiles: presetFileIdentifiers.length,
        currentFile:
            "Found ${presetFileIdentifiers.length} files. Starting parse..."));

    final List<ParsedPresetData> parsedPresets = [];
    int processedFileCount = 0;

    for (final (fileUri, fileRelativePath) in presetFileIdentifiers) {
      processedFileCount++;
      // Update progress before parsing each file
      emit(state.copyWith(
        scanProgress: processedFileCount / presetFileIdentifiers.length,
        currentFile:
            "Parsing: $fileRelativePath ($processedFileCount/${presetFileIdentifiers.length})",
        filesProcessed: processedFileCount,
      ));

      final parsedData = await PresetParserUtils.parsePresetFile(
        fileUri,
        sdCardRootPathOrUri: cardIdentifier,
        knownRelativePath: fileRelativePath,
      );

      if (parsedData != null) {
        parsedPresets.add(parsedData);
      } else {
        InAppLogger()
            .log('Failed to parse preset: $fileRelativePath (URI: $fileUri)');
      }
    }

    if (state.status == ScanStatus.cancelled) {
      emit(state.copyWith(
          status: ScanStatus.cancelled,
          successMessage: '$operationType cancelled by user.'));
      return;
    }

    emit(state.copyWith(
        status: ScanStatus.saving,
        currentFile: "Saving $operationType results..."));

    try {
      await _db.transaction(() async {
        SdCardEntry? existingCard =
            await _db.sdCardsDao.getSdCardBySystemIdentifier(cardIdentifier);
        int sdCardId;

        final nowUtc = DateTime.now().toUtc();

        if (existingCard != null) {
          sdCardId = existingCard.id;
          await _db.sdCardsDao.updateSdCard(existingCard
              .toCompanion(false)
              .copyWith(userLabel: Value(cardName)));
        } else {
          final sdCardCompanion = SdCardsCompanion.insert(
            systemIdentifier: Value(cardIdentifier),
            userLabel: cardName,
          );
          sdCardId = await _db.sdCardsDao.insertSdCard(sdCardCompanion);
        }

        await _db.indexedPresetFilesDao.deletePresetsForSdCard(sdCardId);

        List<IndexedPresetFilesCompanion> presetEntries = [];
        for (var parsedData in parsedPresets) {
          presetEntries.add(IndexedPresetFilesCompanion.insert(
            sdCardId: sdCardId,
            relativePath: parsedData.relativePath,
            fileName: parsedData.fileName,
            absolutePathAtScanTime: parsedData.absolutePathAtScanTime,
            algorithmNameFromPreset: Value(parsedData.algorithmName),
            notesFromPreset: Value(parsedData.notes),
            otherExtractedMetadataJson: Value(parsedData.otherMetadataJson),
            lastSeenUtc: nowUtc,
          ));
        }

        if (presetEntries.isNotEmpty) {
          await _db.batch((batch) {
            batch.insertAll(_db.indexedPresetFiles, presetEntries);
          });
        }
      });

      emit(state.copyWith(
          status: ScanStatus.complete,
          successMessage:
              "$operationType complete for $cardName. Found ${parsedPresets.length} presets.",
          scanProgress: 0.0,
          filesProcessed: 0,
          totalFiles: 0,
          currentFile: ''));
    } catch (e, s) {
      InAppLogger().log('Error saving $operationType results: $e\n$s');
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage:
              "Failed to save $operationType results: ${e.toString()}"));
    }
    add(const LoadScannedCards());
  }

  void _onScanCancelled(ScanCancelled event, Emitter<SdCardScannerState> emit) {
    if (state.status == ScanStatus.parsing ||
        state.status == ScanStatus.findingFiles ||
        state.status == ScanStatus.validating) {
      emit(state.copyWith(
          status: ScanStatus.cancelled,
          successMessage: 'Scan cancelled by user.'));
    } else {
      InAppLogger().log("BLOC: Cannot cancel scan in status: ${state.status}");
    }
  }

  Future<void> _onRemoveCardRequested(
    RemoveCardRequested event,
    Emitter<SdCardScannerState> emit,
  ) async {
    emit(state.copyWith(
        status: ScanStatus.saving, successMessage: null, errorMessage: null));
    try {
      // First, get the SD card by its system identifier to find its primary key ID
      final SdCardEntry? cardToDelete =
          await _db.sdCardsDao.getSdCardBySystemIdentifier(event.cardIdPath);

      if (cardToDelete != null) {
        // Delete associated presets using the card's primary key ID
        await _db.indexedPresetFilesDao.deletePresetsForSdCard(cardToDelete.id);
        // Delete the SD card itself using its primary key ID
        await _db.sdCardsDao.deleteSdCard(cardToDelete.id);

        add(const LoadScannedCards());
        emit(state.copyWith(
            successMessage:
                "Card '${cardToDelete.userLabel}' removed successfully.",
            status: ScanStatus.complete));
      } else {
        InAppLogger().log(
            'Error removing card: Card not found with identifier ${event.cardIdPath}');
        emit(state.copyWith(
            status: ScanStatus.error,
            errorMessage: "Failed to remove card: Card not found."));
      }
    } catch (e) {
      InAppLogger().log('Error removing card ${event.cardIdPath}: $e');
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage: "Failed to remove card: ${e.toString()}"));
    }
  }

  void _onClearMessages(ClearMessages event, Emitter<SdCardScannerState> emit) {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }
}
