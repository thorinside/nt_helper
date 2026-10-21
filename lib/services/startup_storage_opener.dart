import 'dart:io';

import 'package:flutter/services.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/services/database_integrity_service.dart';
import 'package:nt_helper/services/macos_library_storage.dart';
import 'package:nt_helper/utils/app_directory.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class OpenedStartupLibrary {
  const OpenedStartupLibrary(this.database, {this.location, this.recovery});
  final AppDatabase database;
  final String? location;
  final LibraryRecovery? recovery;
}

/// Resolves authority on macOS; other platforms retain their storage policy.
/// A returned database has completed real SQLite/schema work, not just construction.
class StartupStorageOpener {
  StartupStorageOpener({
    bool? isMacOS,
    this.docsProvider,
    this.supportProvider,
    this.checkpoint,
    this.requestAccess = _requestAccess,
    this.releaseAccess = _releaseAccess,
  }) : isMacOS = isMacOS ?? Platform.isMacOS;

  final bool isMacOS;
  final Future<Directory> Function()? docsProvider;
  final Future<Directory> Function()? supportProvider;
  final StorageCheckpoint? checkpoint;
  final Future<bool> Function(String) requestAccess;
  final Future<void> Function() releaseAccess;
  String? legacyAccessDirectory;

  static const _accessChannel = MethodChannel(
    'com.nt_helper.app/legacy_storage_access',
  );
  static Future<bool> _requestAccess(String path) async =>
      await _accessChannel.invokeMethod<bool>('select', path) ?? false;
  static Future<void> _releaseAccess() =>
      _accessChannel.invokeMethod<void>('release');

  Future<OpenedStartupLibrary> open({
    bool selectLegacyDirectory = false,
  }) async {
    AppDatabase? database;
    Directory? documents;
    var accessRequested = false;
    final requestedDirectory = legacyAccessDirectory;
    legacyAccessDirectory = null;
    try {
      try {
        await getAppDirectory(
          isMacOS: isMacOS,
          docsProvider: () async {
            documents =
                await (docsProvider ?? getApplicationDocumentsDirectory)();
            // Selected authority bypasses this provider altogether, including
            // if another process selected A since the previous blocked attempt.
            if (selectLegacyDirectory && requestedDirectory != null) {
              accessRequested = true;
              if (!await requestAccess(requestedDirectory)) {
                legacyAccessDirectory = requestedDirectory;
                throw const StorageFailure(
                  StorageFailureKind.access,
                  'Folder selection cancelled; storage access is unchanged. Retry when access is available',
                );
              }
            }
            return documents!;
          },
          supportProvider: supportProvider,
          storageCheckpoint: checkpoint,
        );
        if (!isMacOS) {
          final integrity = await DatabaseIntegrityService.checkIntegrity();
          if (integrity.isCorrupt) {
            await DatabaseIntegrityService.deleteDatabase();
          }
        }
        final selected = isMacOS ? selectedLibrary : null;
        database = selected == null
            ? AppDatabase()
            : await selected.open(checkpoint: checkpoint);
        await database.select(database.algorithms).get();
        return OpenedStartupLibrary(
          database,
          location: selected?.file.path,
          recovery: selected?.recovery,
        );
      } finally {
        // prepare() has released source exclusion and closed source resources.
        if (accessRequested) await releaseAccess();
      }
    } catch (error) {
      await database?.close();
      // Offer selection only for an observed legacy-path access failure, never
      // as a supposed remedy for destination denial or selected-A unavailability.
      final cause = error is StorageFailure ? error.cause : error;
      if (isMacOS &&
          documents != null &&
          cause is FileSystemException &&
          [1, 13].contains(cause.osError?.errorCode) &&
          cause.path != null &&
          (cause.path == documents!.path ||
              p.isWithin(documents!.path, cause.path!))) {
        legacyAccessDirectory =
            p.basename(cause.path!).startsWith(libraryFileName)
            ? File(cause.path!).parent.path
            : cause.path;
      }
      if (isMacOS) {
        throw classifyStorageFailure(
          error,
          'Cannot resolve or open library storage',
        );
      }
      rethrow;
    }
  }
}
