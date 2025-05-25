import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
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
        status: ScanStatus.initial, scannedCards: [], errorMessage: null));
    try {
      final cardsWithCounts =
          await _db.sdCardsDao.getAllSdCardsWithPresetCounts();

      final uiCards = cardsWithCounts.map((cardWithCount) {
        return ScannedCardData(
          id: cardWithCount.sdCard.systemIdentifier ??
              '', // Handle nullable systemIdentifier
          name: cardWithCount.sdCard.userLabel ??
              'Unnamed Card', // userLabel is non-nullable in DB, but good practice
          presetCount: cardWithCount.presetCount,
          lastScanDate: null,
        );
      }).toList();
      emit(state.copyWith(status: ScanStatus.complete, scannedCards: uiCards));
    } catch (e) {
      emit(
          state.copyWith(status: ScanStatus.error, errorMessage: e.toString()));
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
    String cardPath,
    String cardName,
    Emitter<SdCardScannerState> emit,
    String operationType, // "Scan" or "Rescan" for messages
  ) async {
    emit(state.copyWith(
        status: ScanStatus.validating,
        currentFile: "Validating path for $operationType...",
        errorMessage: null,
        successMessage: null,
        scanProgress: 0.0,
        filesProcessed: 0,
        totalFiles: 0));

    final isValid = await FileSystemUtils.isValidDistingSdCard(cardPath);
    if (!isValid) {
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage:
              "Error: '$cardPath' is not a valid Disting SD Card (missing /presets folder)."));
      return;
    }

    final presetsPath = p.join(cardPath, 'presets');
    emit(state.copyWith(
        status: ScanStatus.findingFiles,
        currentFile: "Finding preset files in $presetsPath..."));

    final List<String> presetFilePaths =
        await FileSystemUtils.findPresetFiles(presetsPath);
    if (presetFilePaths.isEmpty) {
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage: "No preset files (.json) found in $presetsPath."));
      return;
    }

    emit(state.copyWith(
        status: ScanStatus.parsing,
        totalFiles: presetFilePaths.length,
        currentFile:
            "Found ${presetFilePaths.length} files. Starting parse..."));

    List<(String, ParsedPresetData)> successfullyParsedWithPaths = [];
    for (int i = 0; i < presetFilePaths.length; i++) {
      if (state.status == ScanStatus.cancelled) break;
      final filePath = presetFilePaths[i];

      emit(state.copyWith(
        filesProcessed: i + 1,
        currentFile: "Parsing: ${p.basename(filePath)}",
        scanProgress: (i + 1) / presetFilePaths.length,
      ));

      final parsedData = await PresetParserUtils.parsePresetFile(filePath,
          sdCardRootPath: cardPath);
      if (parsedData != null) {
        successfullyParsedWithPaths.add((filePath, parsedData));
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
            await _db.sdCardsDao.getSdCardBySystemIdentifier(cardPath);
        int sdCardId;
        if (existingCard != null) {
          sdCardId = existingCard.id;
          if (existingCard.userLabel != cardName) {
            await _db.sdCardsDao.updateSdCard(existingCard
                .toCompanion(false)
                .copyWith(userLabel: Value(cardName)));
          }
        } else {
          final sdCardCompanion = SdCardsCompanion.insert(
            systemIdentifier: Value(cardPath),
            userLabel: cardName,
          );
          sdCardId = await _db.sdCardsDao.insertSdCard(sdCardCompanion);
        }

        await _db.indexedPresetFilesDao.deletePresetsForSdCard(sdCardId);

        List<IndexedPresetFilesCompanion> presetEntries = [];
        for (var (filePath, pData) in successfullyParsedWithPaths) {
          presetEntries.add(IndexedPresetFilesCompanion.insert(
            sdCardId: sdCardId,
            relativePath: pData.relativePath,
            fileName: pData.fileName,
            absolutePathAtScanTime: pData.absolutePathAtScanTime,
            algorithmNameFromPreset: Value(pData.algorithmName),
            notesFromPreset: Value(pData.notes),
            otherExtractedMetadataJson: Value(pData.otherMetadataJson),
            lastSeenUtc: DateTime.now().toUtc(),
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
              "$operationType complete for $cardName. Found ${successfullyParsedWithPaths.length} presets.",
          scanProgress: 0.0,
          filesProcessed: 0,
          totalFiles: 0,
          currentFile: ''));
    } catch (e, s) {
      debugPrint('Error saving $operationType results: $e\\n$s');
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage:
              "Failed to save $operationType results: ${e.toString()}"));
    }
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
        // First delete associated presets
        await _db.indexedPresetFilesDao.deletePresetsForSdCard(cardToDelete.id);
        // Then delete the card
        await _db.sdCardsDao.deleteSdCard(cardToDelete.id);
        emit(state.copyWith(
            successMessage: "Removed card: ${cardToDelete.userLabel}"));
      } else {
        emit(state.copyWith(
            status: ScanStatus.error,
            errorMessage:
                "Failed to remove card: Card not found at path ${event.cardIdPath}"));
      }
    } catch (e, s) {
      debugPrint('Error removing card: $e\n$s');
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage: "Failed to remove card: ${e.toString()}"));
    }
    add(const LoadScannedCards()); // Reload from DB
  }

  void _onClearMessages(ClearMessages event, Emitter<SdCardScannerState> emit) {
    emit(state.copyWith(
        errorMessage: null, successMessage: null, newlyScannedCard: null));
  }
}
