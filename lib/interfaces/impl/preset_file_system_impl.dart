

import 'dart:typed_data';

import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/interfaces/preset_file_system.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

class PresetFileSystemImpl implements PresetFileSystem {

  final IDistingMidiManager manager;
  PresetFileSystemImpl(this.manager);

  @override
  Future<List<String>> listFiles(String directoryPath, {bool recursive = false}) async {
    final root = await manager.requestDirectoryListing(directoryPath);

    if (root == null) {
      return [];
    }

    return root.entries.fold<List<String>>([], (list, DirectoryEntry entry) async {
      if (entry.isDirectory) {
        if (recursive) {
          final subList = await listFiles(entry.name, recursive: true);
          list.addAll(subList);
        }
      } else {
        list.add(entry.name);
      }
      return list;
    } as List<String> Function(List<String> previousValue, DirectoryEntry element));
  }

  @override
  Future<Uint8List?> readFile(String relativePath) {
    return manager.requestFileDownload(relativePath);
  }

}