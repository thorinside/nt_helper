import 'dart:typed_data';

import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/interfaces/preset_file_system.dart';

class PresetFileSystemImpl implements PresetFileSystem {
  final IDistingMidiManager manager;
  PresetFileSystemImpl(this.manager);

  @override
  Future<List<String>> listFiles(
    String directoryPath, {
    bool recursive = false,
  }) async {
    final listing = await manager.requestDirectoryListing(directoryPath);
    if (listing == null) return [];

    final result = <String>[];
    for (final entry in listing.entries) {
      // Hardware appends '/' to directory names — strip it for path construction
      final entryName = entry.name.endsWith('/')
          ? entry.name.substring(0, entry.name.length - 1)
          : entry.name;
      final entryPath = '$directoryPath/$entryName';
      if (entry.isDirectory) {
        if (recursive) {
          result.addAll(await listFiles(entryPath, recursive: true));
        }
      } else {
        result.add(entryPath);
      }
    }
    return result;
  }

  @override
  Future<Uint8List?> readFile(String relativePath) {
    return manager.requestFileDownload(relativePath);
  }
}
