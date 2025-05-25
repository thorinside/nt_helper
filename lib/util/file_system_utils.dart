import 'dart:io'; // Required for Directory and FileSystemEntity
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p; // For joining paths

class FileSystemUtils {
  /// Allows the user to pick a directory using the native file explorer.
  ///
  /// Returns the selected directory path as a [String], or `null` if the
  /// user cancels the dialog.
  static Future<String?> pickSdCardRootDirectory() async {
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      return directoryPath;
    } catch (e) {
      // Handle potential exceptions during file picking, e.g., platform errors
      // You might want to log this error or show a user-friendly message
      print('Error picking directory: $e');
      return null;
    }
  }

  /// Lists the contents (files and directories) of a given directory path.
  ///
  /// Returns a list of [FileSystemEntity] objects.
  /// Returns an empty list if the directory doesn't exist or an error occurs.
  static Future<List<FileSystemEntity>> listDirectoryContents(
      String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        return await dir.list().toList();
      }
      return [];
    } catch (e) {
      print('Error listing directory contents for $path: $e');
      return [];
    }
  }

  /// Checks if the given path appears to be a valid Disting NT SD card root.
  ///
  /// Currently checks for the existence of a subdirectory named "presets".
  static Future<bool> isValidDistingSdCard(String path) async {
    try {
      final presetsPath = p.join(path, 'presets');
      final presetsDir = Directory(presetsPath);
      if (await presetsDir.exists()) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error validating Disting SD card path $path: $e');
      return false;
    }
  }

  /// Recursively finds all .json files within the given directory path.
  ///
  /// Takes the path to a directory (e.g., the '/presets' directory on an SD card),
  /// recursively scans it and all its subdirectories, and returns a list of full
  /// file paths for all files ending with '.json'.
  /// Returns an empty list if the directory doesn't exist or an error occurs.
  static Future<List<String>> findPresetFiles(
      String presetsDirectoryPath) async {
    final directory = Directory(presetsDirectoryPath);

    if (!await directory.exists()) {
      print('Presets directory not found: $presetsDirectoryPath');
      return [];
    }

    final List<String> presetFiles = [];
    try {
      await for (final entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
          presetFiles.add(entity.path);
        }
      }
    } catch (e) {
      print('Error scanning for preset files in $presetsDirectoryPath: $e');
      // Return any files found so far, or an empty list if error was early
      return presetFiles;
    }
    return presetFiles;
  }
}
