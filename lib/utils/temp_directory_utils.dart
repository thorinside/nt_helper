import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Utility for obtaining a writable temporary directory.
///
/// On macOS Tahoe, `getTemporaryDirectory()` from `path_provider` can fail or
/// return an unwritable directory. This utility tries `getTemporaryDirectory()`
/// first, tests writability with a probe file, and falls back to
/// `Directory.systemTemp` if the primary fails.
class TempDirectoryUtils {
  /// Returns a writable temporary directory.
  ///
  /// Tries `getTemporaryDirectory()` first, verifying writability with a probe
  /// file. Falls back to `Directory.systemTemp` if the primary provider fails
  /// or returns an unwritable directory.
  ///
  /// The [primaryProvider] and [fallbackProvider] parameters are exposed for
  /// testing only.
  static Future<Directory> getWritableTempDirectory({
    @visibleForTesting Future<Directory> Function()? primaryProvider,
    @visibleForTesting Directory Function()? fallbackProvider,
  }) async {
    final primary = primaryProvider ?? getTemporaryDirectory;
    final fallback = fallbackProvider ?? (() => Directory.systemTemp);

    // Attempt 1: path_provider
    try {
      final dir = await primary();
      if (await isWritable(dir)) return dir;
    } catch (_) {
      // Fall through to fallback
    }

    // Attempt 2: Directory.systemTemp
    final fallbackDir = fallback();
    if (await isWritable(fallbackDir)) return fallbackDir;

    throw const FileSystemException('No writable temporary directory found');
  }

  /// Tests whether [dir] exists and is writable by creating and deleting a
  /// probe file.
  @visibleForTesting
  static Future<bool> isWritable(Directory dir) async {
    try {
      if (!await dir.exists()) return false;
      final probe = File(path.join(dir.path, '.nt_helper_write_test'));
      await probe.writeAsBytes([0]);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
