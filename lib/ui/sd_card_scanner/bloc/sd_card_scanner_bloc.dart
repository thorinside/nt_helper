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
import 'package:nt_helper/services/ios_file_access_service.dart'; // Import iOS file access service

import 'sd_card_scanner_event.dart';

class SdCardScannerBloc extends Bloc<SdCardScannerEvent, SdCardScannerState> {
  final AppDatabase _db;
  final IosFileAccessService _iosFileAccessService = IosFileAccessService();

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
    await _performScanAndSaveOperations(event.sdCardRootPathOrUri,
        event.relativePresetsPath, event.cardName, emit,
        isRescan: false);
  }

  Future<void> _onRescanCardRequested(
    RescanCardRequested event,
    Emitter<SdCardScannerState> emit,
  ) async {
    await _performScanAndSaveOperations(
        event.cardIdPath, event.relativePresetsPath, event.cardName, emit,
        isRescan: true);
    add(const LoadScannedCards());
  }

  Future<void> _performScanAndSaveOperations(
      String sdCardRootPathOrUri,
      String relativePresetsPath,
      String cardName,
      Emitter<SdCardScannerState> emit,
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

    dynamic sdCardRootIdentifier = sdCardRootPathOrUri;
    String displayRootPath = sdCardRootPathOrUri;

    String? iosSessionId;
    bool iosSessionStarted = false;

    if (!kIsWeb && Platform.isIOS) {
      iosSessionId = sdCardRootPathOrUri;
      try {
        iosSessionStarted = await _iosFileAccessService.startAccessSession(
            bookmarkedPathKey: iosSessionId);
        if (!iosSessionStarted) {
          InAppLogger().log(
              "iOS Scan: Failed to start session $iosSessionId at start of $operationType.");
          emit(state.copyWith(
              status: ScanStatus.error,
              errorMessage:
                  "Failed to start file access session for $operationType."));
          return;
        }
        InAppLogger()
            .log("iOS Scan: Session $iosSessionId started for $operationType.");
      } catch (e, s) {
        InAppLogger().log(
            'iOS Scan: Error starting session $iosSessionId for $operationType: $e\n$s');
        emit(state.copyWith(
            status: ScanStatus.error,
            errorMessage:
                "Error initializing file access for $operationType: ${e.toString()}"));
        return;
      }
    }

    // Android Specific Root Handling
    if (!kIsWeb &&
        Platform.isAndroid &&
        sdCardRootPathOrUri.startsWith('content://')) {
      try {
        sdCardRootIdentifier =
            await docman.DocumentFile.fromUri(sdCardRootPathOrUri);
        if (sdCardRootIdentifier == null || !sdCardRootIdentifier.exists) {
          emit(state.copyWith(
              status: ScanStatus.error,
              errorMessage:
                  "Error: Could not access SD card root at '$sdCardRootPathOrUri'. DocumentFile null or not found."));
          if (iosSessionStarted) {
            await _iosFileAccessService.stopAccessSession(
                sessionId: iosSessionId!);
          }
          return;
        }
        displayRootPath = sdCardRootIdentifier.name ?? sdCardRootPathOrUri;
      } catch (e) {
        InAppLogger().log(
            'Android: Error getting DocumentFile from $sdCardRootPathOrUri: ${e.toString()}');
        emit(state.copyWith(
            status: ScanStatus.error,
            errorMessage:
                "Error accessing SD card root (Android): ${e.toString()}"));
        if (iosSessionStarted) {
          await _iosFileAccessService.stopAccessSession(
              sessionId: iosSessionId!);
        }
        return;
      }
    }

    String fullDisplayPath = displayRootPath;
    if (relativePresetsPath.isNotEmpty) {
      fullDisplayPath = p.join(displayRootPath, relativePresetsPath);
    }

    emit(state.copyWith(
        status: ScanStatus.validating,
        currentFile: "Validating presets directory: $fullDisplayPath..."));

    final isValidPresetsDir = await FileSystemUtils.isValidDistingSdCard(
        sdCardRootIdentifier, relativePresetsPath,
        sessionId: iosSessionId);
    if (!isValidPresetsDir) {
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage:
              "Error: Presets directory '$fullDisplayPath' is not valid or accessible."));
      if (iosSessionStarted) {
        await _iosFileAccessService.stopAccessSession(sessionId: iosSessionId!);
      }
      return;
    }

    emit(state.copyWith(
        status: ScanStatus.findingFiles,
        currentFile: "Finding preset files in $fullDisplayPath..."));

    List<String> presetFileUrisOrFullPaths = [];
    try {
      presetFileUrisOrFullPaths = await FileSystemUtils.findPresetFiles(
          sdCardRootIdentifier, relativePresetsPath,
          sessionId: iosSessionId);
    } catch (e, s) {
      InAppLogger()
          .log('Error finding preset files during $operationType: $e\n$s');
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage: "Failed to find preset files: ${e.toString()}"));
      // Main finally block will stop the session if it was started
      return;
    }

    if (presetFileUrisOrFullPaths.isEmpty) {
      emit(state.copyWith(
          status: ScanStatus.error,
          errorMessage: "No preset files (.json) found in $fullDisplayPath."));
      // Main finally block will stop the session if it was started
      return;
    }

    emit(state.copyWith(
        status: ScanStatus.parsing,
        totalFiles: presetFileUrisOrFullPaths.length,
        currentFile:
            "Found ${presetFileUrisOrFullPaths.length} files. Parsing..."));

    final List<ParsedPresetData> parsedPresets = [];
    int processedFileCount = 0;

    for (final String fileUriOrFullPath in presetFileUrisOrFullPaths) {
      if (state.status == ScanStatus.cancelled) {
        break;
      }
      processedFileCount++;
      String displayFileName = p.basename(fileUriOrFullPath);
      try {
        if (fileUriOrFullPath.startsWith('file://')) {
          displayFileName =
              p.basename(Uri.parse(fileUriOrFullPath).toFilePath());
        }
      } catch (_) {/* ignore */}

      emit(state.copyWith(
        scanProgress: processedFileCount / presetFileUrisOrFullPaths.length,
        currentFile:
            "Parsing: $displayFileName ($processedFileCount/${presetFileUrisOrFullPaths.length})",
        filesProcessed: processedFileCount,
      ));

      final parsedData = await PresetParserUtils.parsePresetFile(
        fileUriOrFullPath,
        sdCardRootPathOrUri:
            sdCardRootPathOrUri, // This is used as sessionId for iOS by readFileBytes
      );

      if (parsedData != null) {
        parsedPresets.add(parsedData);
      } else {
        InAppLogger()
            .log('$operationType: Failed to parse preset: $fileUriOrFullPath');
      }
    }

    if (state.status == ScanStatus.cancelled) {
      emit(state.copyWith(
          status: ScanStatus.cancelled,
          successMessage: '$operationType cancelled by user.'));
      // Main finally block will stop the session if it was started
      return;
    }

    emit(state.copyWith(
        status: ScanStatus.saving,
        currentFile: "Saving $operationType results..."));

    try {
      await _db.transaction(() async {
        SdCardEntry? existingCard = await _db.sdCardsDao
            .getSdCardBySystemIdentifier(sdCardRootPathOrUri);
        int sdCardId;
        final nowUtc = DateTime.now().toUtc();

        if (existingCard != null) {
          sdCardId = existingCard.id;
          await _db.sdCardsDao.updateSdCard(existingCard
              .toCompanion(false)
              .copyWith(userLabel: Value(cardName)));
        } else {
          final sdCardCompanion = SdCardsCompanion.insert(
              systemIdentifier: Value(sdCardRootPathOrUri),
              userLabel: cardName);
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
          await _db.batch((batch) =>
              batch.insertAll(_db.indexedPresetFiles, presetEntries));
        }
      });

      emit(state.copyWith(
          status: ScanStatus.complete,
          successMessage:
              "$operationType complete for '$cardName'. Found ${parsedPresets.length} presets.",
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
    } finally {
      if (iosSessionStarted) {
        await _iosFileAccessService.stopAccessSession(sessionId: iosSessionId!);
        InAppLogger().log(
            "iOS Scan: Session $iosSessionId stopped in main finally for $operationType.");
      }
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
      final SdCardEntry? cardToDelete =
          await _db.sdCardsDao.getSdCardBySystemIdentifier(event.cardIdPath);

      if (cardToDelete != null) {
        await _db.indexedPresetFilesDao.deletePresetsForSdCard(cardToDelete.id);
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
