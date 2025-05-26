import 'dart:typed_data';

import 'package:flutter/services.dart';

class IosFileAccessService {
  static const MethodChannel _channel =
      MethodChannel('com.example.nt_helper/ios_file_access');

  /// Prompts the user to pick a directory using UIDocumentPickerViewController.
  ///
  /// If successful, it natively creates a security-scoped bookmark for the selected
  /// directory's URL, stores this bookmark in UserDefaults (keyed by the URL's path),
  /// and returns the path string of the selected directory.
  ///
  /// Returns the path string of the selected directory on success, or null on failure/cancel.
  Future<String?> pickDirectoryAndStoreBookmark() async {
    try {
      final String? directoryPath =
          await _channel.invokeMethod('pickDirectoryAndStoreBookmark');
      return directoryPath;
    } on PlatformException catch (e) {
      // Handle potential exceptions or log them
      print("Failed to pick directory and store bookmark: '${e.message}'.");
      return null;
    }
  }

  /// Lists the contents of a previously bookmarked directory.
  ///
  /// [bookmarkedPath] should be the path string obtained from a successful
  /// call to [pickDirectoryAndStoreBookmark].
  ///
  /// Returns a list of maps, where each map contains:
  /// - 'uri': The absolute file URI string.
  /// - 'relativePath': The path of the file relative to the bookmarked directory.
  ///
  /// Returns null if the bookmark is invalid, access cannot be granted, or an error occurs.
  Future<List<Map<String, String>>?> listBookmarkedDirectoryContents(
      String bookmarkedPath) async {
    try {
      final List<dynamic>? results = await _channel.invokeMethod(
          'listBookmarkedDirectoryContents',
          {'bookmarkedPath': bookmarkedPath});
      return results
          ?.map((item) => Map<String, String>.from(item as Map))
          .toList();
    } on PlatformException catch (e) {
      print("Failed to list directory contents: '${e.message}'.");
      return null;
    }
  }

  /// Reads the contents of a file within a bookmarked directory.
  ///
  /// [bookmarkedPath] should be the path string of the parent bookmarked directory.
  /// [relativePath] is the path of the file relative to the bookmarked directory.
  ///
  /// Returns Uint8List of the file contents on success, or null on failure.
  Future<Uint8List?> readBookmarkedFile(
      String bookmarkedPath, String relativePath) async {
    try {
      final Uint8List? fileData = await _channel.invokeMethod(
          'readBookmarkedFile',
          {'bookmarkedPath': bookmarkedPath, 'relativePath': relativePath});
      return fileData;
    } on PlatformException catch (e) {
      print("Failed to read file: '${e.message}'.");
      return null;
    }
  }
}
