import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Cache entry for listDirectoryInSession results, might still be useful
// for performance if the same directory is listed multiple times *within* a session.
class _ListCacheEntry {
  final List<String> contents;
  final DateTime expiryTime;

  _ListCacheEntry(this.contents, this.expiryTime);

  bool get isValid => DateTime.now().isBefore(expiryTime);
}

class IosFileAccessService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.nt_helper/ios_file_access',
  );

  final Map<String, _ListCacheEntry> _listDirectoryCache = {};
  static const Duration _cacheDuration = Duration(
    seconds: 2,
  ); // Short cache for in-session listings

  /// Prompts the user to pick a directory. The native side will create and store
  /// a security-scoped bookmark for this directory.
  /// Returns the path string of the selected directory (which is also used as the bookmark key
  /// and implicitly the session ID for subsequent operations) on success, or null.
  Future<String?> pickDirectoryAndCreateBookmark() async {
    try {
      final String? path = await _channel.invokeMethod(
        'pickDirectoryAndStoreBookmark',
      );
      // This path will be used as the session identifier by convention.
      return path;
    } catch (e) {
      debugPrint('Error in pickDirectoryAndCreateBookmark: $e');
      return null;
    }
  }

  /// Starts an access session for a previously bookmarked directory.
  /// This must be called before listDirectoryInSession or readFileInSession.
  /// [bookmarkedPathKey] is the path obtained from pickDirectoryAndCreateBookmark.
  /// Returns true on success, false on failure.
  Future<bool> startAccessSession({required String bookmarkedPathKey}) async {
    try {
      final bool? success = await _channel.invokeMethod('startAccessSession', {
        'bookmarkedPathKey': bookmarkedPathKey,
      });
      return success ?? false;
    } catch (e) {
      debugPrint('Error starting access session for $bookmarkedPathKey: $e');
      return false;
    }
  }

  /// Lists the contents of a directory within an active access session.
  /// [sessionId] must be the bookmarkedPathKey used to start the session.
  /// [directoryPathToList] is the full path of the directory to list.
  Future<List<String>?> listDirectoryInSession({
    required String sessionId,
    required String directoryPathToList,
  }) async {
    final cacheKey =
        '$sessionId::$directoryPathToList'; // Session-aware cache key
    final cachedEntry = _listDirectoryCache[cacheKey];

    if (cachedEntry != null && cachedEntry.isValid) {
      debugPrint(
        'iOS File Access: Returning cached list for $directoryPathToList in session $sessionId',
      );
      return List<String>.from(cachedEntry.contents); // Return a copy
    }

    try {
      final List<dynamic>? result = await _channel.invokeMethod(
        'listDirectoryInSession',
        {
          'sessionId':
              sessionId, // Corresponds to bookmarkedPathKey on native side
          'directoryPathToList': directoryPathToList,
        },
      );

      if (result != null) {
        final contents = result.cast<String>();
        _listDirectoryCache[cacheKey] = _ListCacheEntry(
          contents,
          DateTime.now().add(_cacheDuration),
        );
        debugPrint(
          'iOS File Access: Fetched and cached list for $directoryPathToList in session $sessionId',
        );
        return contents;
      } else {
        _listDirectoryCache.remove(cacheKey);
        debugPrint(
          'iOS File Access: Native list returned null for $directoryPathToList in session $sessionId, not caching.',
        );
        return null;
      }
    } catch (e) {
      debugPrint(
        'Error listing directory $directoryPathToList in session $sessionId: $e',
      );
      _listDirectoryCache.remove(cacheKey);
      return null;
    }
  }

  /// Reads a file within an active access session.
  /// [sessionId] must be the bookmarkedPathKey used to start the session.
  /// [filePathToRead] is the full path of the file to read.
  Future<Uint8List?> readFileInSession({
    required String sessionId,
    required String filePathToRead,
  }) async {
    try {
      final Uint8List? fileData = await _channel.invokeMethod(
        'readFileInSession',
        {
          'sessionId':
              sessionId, // Corresponds to bookmarkedPathKey on native side
          'filePathToRead': filePathToRead,
        },
      );
      return fileData;
    } catch (e) {
      debugPrint(
        'Error reading file $filePathToRead in session $sessionId: $e',
      );
      return null;
    }
  }

  /// Stops an access session, releasing the security-scoped resource.
  /// [sessionId] must be the bookmarkedPathKey used to start the session.
  Future<void> stopAccessSession({required String sessionId}) async {
    try {
      await _channel.invokeMethod('stopAccessSession', {
        'sessionId': sessionId,
      });
      debugPrint('iOS File Access: Session $sessionId stopped.');
      // Optionally clear all cache entries related to this session if desired,
      // though timed expiry might be sufficient.
      _listDirectoryCache.removeWhere(
        (key, value) => key.startsWith('$sessionId::'),
      );
    } catch (e) {
      debugPrint('Error stopping access session $sessionId: $e');
    }
  }
}
