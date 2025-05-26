import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
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
      ScanRequested event, Emitter<SdCardScannerState> emit) async {
    await _performScanAndSaveOperations(
        event.path, event.cardName, emit, "Scan");
    add(const LoadScannedCards());
  }

  Future<void> _onRescanCardRequested(
      RescanCardRequested event, Emitter<SdCardScannerState> emit) async {
    await _performScanAndSaveOperations(
        event.cardIdPath, event.cardName, emit, "Rescan");
    add(const LoadScannedCards());
  }

  Future<void> _performScanAndSaveOperations(
    String cardIdentifier,
    String cardName,
    Emitter<SdCardScannerState> emit,
    String operationType,
  ) async {
    emit(state.copyWith(
        status: ScanStatus.validating,
        currentFile: "Validating path for $operationType...",
        errorMessage: null,
        successMessage: null,
        scanProgress: 0.0,
        filesProcessed: 0,
        totalFiles: 0));

    dynamic sdCardRootIdentifier;
    String displayPath = cardIdentifier;

    if (!kIsWeb &&
        Platform.isAndroid &&
        cardIdentifier.startsWith('content://')) {
      try {
        sdCardRootIdentifier =
            await docman.DocumentFile.fromUri(cardIdentifier);
        if (sdCardRootIdentifier == null ||
            !(await sdCardRootIdentifier.exists())) {
          emit(state.copyWith(
              status: ScanStatus.error,
              errorMessage:
                  "Error: Could not access SD card at '$cardIdentifier'. Please re-select."));
          return;
        }
        displayPath = sdCardRootIdentifier.name ?? cardIdentifier;
      } catch (e) {
        emit(state.copyWith(
            status: ScanStatus.error,
            errorMessage:
                "Error accessing Android SD card URI '$cardIdentifier': $e"));
        return;
      }
    } else if (!kIsWeb &&
        Platform.isAndroid &&
        !cardIdentifier.startsWith('content://')) {
      sdCardRootIdentifier = cardIdentifier;
    } else {
      sdCardRootIdentifier = cardIdentifier;
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

    dynamic presetsDirIdentifier;
    String presetsDisplayPath = "presets";

    if (sdCardRootIdentifier is docman.DocumentFile) {
      presetsDirIdentifier = await sdCardRootIdentifier.find('presets');
      if (presetsDirIdentifier == null ||
          !(await presetsDirIdentifier.exists()) ||
          !presetsDirIdentifier.isDirectory) {
        emit(state.copyWith(
            status: ScanStatus.error,
            errorMessage:
                "Error: Could not find or access 'presets' directory on '$displayPath'."));
        return;
      }
      presetsDisplayPath = presetsDirIdentifier.name ?? "presets";
    } else if (sdCardRootIdentifier is String) {
      presetsDirIdentifier = p.join(sdCardRootIdentifier, 'presets');
      presetsDisplayPath = presetsDirIdentifier;
    } else {
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage:
              "Internal error: Invalid SD card root identifier type. Path: $sdCardRootIdentifier"));
      return;
    }

    emit(state.copyWith(
        status: ScanStatus.findingFiles,
        currentFile: "Finding preset files in $presetsDisplayPath..."));

    final List<String> presetFilePathsOrUris =
        await FileSystemUtils.findPresetFiles(presetsDirIdentifier);

    if (presetFilePathsOrUris.isEmpty) {
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage:
              "No preset files (.json) found in $presetsDisplayPath."));
      return;
    }

    emit(state.copyWith(
        status: ScanStatus.parsing,
        totalFiles: presetFilePathsOrUris.length,
        currentFile:
            "Found ${presetFilePathsOrUris.length} files. Starting parse..."));

    List<(String, ParsedPresetData)> successfullyParsedWithOriginalIdentifier =
        [];
    for (int i = 0; i < presetFilePathsOrUris.length; i++) {
      if (state.status == ScanStatus.cancelled) break;
      final fileIdentifier = presetFilePathsOrUris[i];

      String currentFileNameForDisplay;
      if (!kIsWeb &&
          Platform.isAndroid &&
          fileIdentifier.startsWith('content://')) {
        try {
          final tempDocFile = await docman.DocumentFile.fromUri(fileIdentifier);
          currentFileNameForDisplay =
              tempDocFile?.name ?? p.basename(fileIdentifier);
        } catch (_) {
          currentFileNameForDisplay = p.basename(fileIdentifier);
        }
      } else {
        currentFileNameForDisplay = p.basename(fileIdentifier);
      }

      emit(state.copyWith(
        filesProcessed: i + 1,
        currentFile: "Parsing: $currentFileNameForDisplay",
        scanProgress: (i + 1) / presetFilePathsOrUris.length,
      ));

      final parsedData = await PresetParserUtils.parsePresetFile(
        fileIdentifier,
        sdCardRootPathOrUri: cardIdentifier,
      );
      if (parsedData != null) {
        successfullyParsedWithOriginalIdentifier
            .add((fileIdentifier, parsedData));
      }
      await Future.delayed(const Duration(milliseconds: 5));
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
        for (var (fileId, pData) in successfullyParsedWithOriginalIdentifier) {
          presetEntries.add(IndexedPresetFilesCompanion.insert(
            sdCardId: sdCardId,
            relativePath: pData.relativePath,
            fileName: pData.fileName,
            absolutePathAtScanTime: fileId,
            algorithmNameFromPreset: Value(pData.algorithmName),
            notesFromPreset: Value(pData.notes),
            otherExtractedMetadataJson: Value(pData.otherMetadataJson),
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
              "$operationType complete for $cardName. Found ${successfullyParsedWithOriginalIdentifier.length} presets.",
          scanProgress: 0.0,
          filesProcessed: 0,
          totalFiles: 0,
          currentFile: ''));
    } catch (e, s) {
      debugPrint('Error saving $operationType results: $e\n$s');
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
      debugPrint("BLOC: Cannot cancel scan in status: ${state.status}");
    }
  }

  Future<void> _onRemoveCardRequested(
      RemoveCardRequested event, Emitter<SdCardScannerState> emit) async {
    try {
      final cardToDelete =
          await _db.sdCardsDao.getSdCardBySystemIdentifier(event.cardIdPath);
      if (cardToDelete != null) {
        await _db.indexedPresetFilesDao.deletePresetsForSdCard(cardToDelete.id);
        await _db.sdCardsDao.deleteSdCard(cardToDelete.id);
        emit(state.copyWith(
            successMessage: "Removed card: ${cardToDelete.userLabel}"));
      } else {
        emit(state.copyWith(
            status: ScanStatus.error,
            errorMessage:
                "Failed to remove card: Card not found with identifier ${event.cardIdPath}"));
      }
    } catch (e, s) {
      debugPrint('Error removing card: $e\n$s');
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage: "Failed to remove card: ${e.toString()}"));
    }
    add(const LoadScannedCards());
  }

  void _onClearMessages(ClearMessages event, Emitter<SdCardScannerState> emit) {
    emit(state.copyWith(
        errorMessage: null, successMessage: null, newlyScannedCard: null));
  }
}
