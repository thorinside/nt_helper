import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:nt_helper/models/firmware_release.dart';
import 'package:nt_helper/models/firmware_version.dart';

/// Exception thrown during firmware download operations
class FirmwareDownloadException implements Exception {
  final String message;
  const FirmwareDownloadException(this.message);

  @override
  String toString() => 'FirmwareDownloadException: $message';
}

/// Service for checking firmware versions and downloading updates
class FirmwareVersionService {
  static const String _firmwarePageUrl =
      'https://expert-sleepers.co.uk/distingNTfirmwareupdates.html';
  static const String _baseUrl = 'https://expert-sleepers.co.uk/';

  /// Cached firmware releases for the session
  List<FirmwareRelease>? _cachedReleases;
  DateTime? _lastFetch;
  final Duration _cacheTimeout = const Duration(minutes: 30);

  /// HTTP client (can be injected for testing)
  final http.Client _httpClient;

  FirmwareVersionService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Fetch available firmware versions from Expert Sleepers website
  ///
  /// Results are cached for the session to avoid repeated network requests.
  Future<List<FirmwareRelease>> fetchAvailableVersions({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid
    if (!forceRefresh &&
        _cachedReleases != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTimeout) {
      return _cachedReleases!;
    }

    try {
      final response = await _httpClient
          .get(Uri.parse(_firmwarePageUrl))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw FirmwareDownloadException(
          'Failed to fetch firmware page: HTTP ${response.statusCode}',
        );
      }

      final releases = _parseHtml(response.body);
      _cachedReleases = releases;
      _lastFetch = DateTime.now();

      return releases;
    } catch (e) {
      if (e is FirmwareDownloadException) rethrow;
      throw FirmwareDownloadException('Network error: $e');
    }
  }

  /// Parse HTML to extract firmware releases
  List<FirmwareRelease> _parseHtml(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final releases = <FirmwareRelease>[];

    // Find the firmware table - look for table with version info
    final tables = document.querySelectorAll('table');

    for (final table in tables) {
      final rows = table.querySelectorAll('tr');

      for (final row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.length < 3) continue;

        // Try to extract version, date, and changelog from cells
        final release = _parseTableRow(cells);
        if (release != null) {
          releases.add(release);
        }
      }
    }

    // Sort by version (newest first)
    releases.sort((a, b) => b.compareToVersion(a.version));

    return releases;
  }

  /// Parse a single table row to extract firmware release info
  FirmwareRelease? _parseTableRow(List<dynamic> cells) {
    String? version;
    DateTime? releaseDate;
    String? downloadUrl;
    final changelog = <String>[];

    for (final cell in cells) {
      final text = cell.text.trim();

      // Check for version number (X.Y.Z format)
      if (version == null && _isVersionString(text)) {
        version = text;
        continue;
      }

      // Check for date (DD/MM/YYYY format)
      if (releaseDate == null) {
        final date = _parseDate(text);
        if (date != null) {
          releaseDate = date;
          continue;
        }
      }

      // Check for download link
      if (downloadUrl == null) {
        final links = cell.querySelectorAll('a');
        for (final link in links) {
          final href = link.attributes['href'];
          if (href != null && href.endsWith('.zip') && href.contains('distingNT')) {
            downloadUrl = _resolveUrl(href);
            break;
          }
        }
      }

      // Extract changelog items from lists
      final listItems = cell.querySelectorAll('li');
      for (final item in listItems) {
        final itemText = item.text.trim();
        if (itemText.isNotEmpty) {
          changelog.add(itemText);
        }
      }
    }

    // Require at minimum version and download URL
    if (version == null || downloadUrl == null) {
      return null;
    }

    return FirmwareRelease(
      version: version,
      releaseDate: releaseDate ?? DateTime.now(),
      changelog: changelog,
      downloadUrl: downloadUrl,
    );
  }

  /// Check if a string looks like a version number (X.Y.Z)
  bool _isVersionString(String text) {
    final versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
    return versionRegex.hasMatch(text);
  }

  /// Parse date in DD/MM/YYYY or D/M/YYYY format
  DateTime? _parseDate(String text) {
    // Try DD/MM/YYYY or D/M/YYYY format
    final dateRegex = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    final match = dateRegex.firstMatch(text);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      try {
        return DateTime(year, month, day);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Resolve relative URL to absolute URL
  String _resolveUrl(String href) {
    if (href.startsWith('http://') || href.startsWith('https://')) {
      return href;
    }
    return '$_baseUrl$href';
  }

  /// Get the latest available firmware version
  FirmwareRelease? getLatestVersion(List<FirmwareRelease> versions) {
    if (versions.isEmpty) return null;
    // Versions are already sorted newest first
    return versions.first;
  }

  /// Check if an update is available compared to current version
  ///
  /// [currentVersion] - The currently installed firmware version (e.g., "1.11.0")
  /// [available] - List of available firmware releases
  bool isUpdateAvailable(String currentVersion, List<FirmwareRelease> available) {
    final latest = getLatestVersion(available);
    if (latest == null) return false;

    // Use FirmwareVersion class for robust comparison
    // It uses regex to extract numeric parts, handling versions like "1.13.0beta"
    final currentFw = FirmwareVersion(currentVersion);
    final latestFw = FirmwareVersion(latest.version);

    // Update available if latest is greater than current
    return latestFw.isGreaterThan(currentFw);
  }

  /// Download firmware package to temp directory
  ///
  /// Returns the path to the downloaded .zip file.
  /// Emits progress through [onProgress] callback (0.0 to 1.0).
  Future<String> downloadFirmware(
    FirmwareRelease version, {
    void Function(double progress)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'distingNT_${version.version}.zip';
    final filePath = path.join(tempDir.path, fileName);

    try {
      final request = http.Request('GET', Uri.parse(version.downloadUrl));
      final response = await _httpClient.send(request);

      if (response.statusCode != 200) {
        throw FirmwareDownloadException(
          'Download failed: HTTP ${response.statusCode}',
        );
      }

      final file = File(filePath);
      final sink = file.openWrite();
      final contentLength = response.contentLength ?? 0;
      int bytesReceived = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          onProgress(bytesReceived / contentLength);
        }
      }

      await sink.close();

      // Verify the ZIP is valid
      await _verifyZip(filePath);

      return filePath;
    } catch (e) {
      // Clean up partial download on failure
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      if (e is FirmwareDownloadException) rethrow;
      throw FirmwareDownloadException('Download error: $e');
    }
  }

  /// Verify that the downloaded ZIP is valid by attempting to list its entries.
  ///
  /// Expert Sleepers firmware packages contain:
  /// - bootable_images/disting_NT.bin - the firmware binary
  /// - write_image_mac.sh / write_image_win.bat / write_image_lnx.sh - flash scripts
  /// - MANIFEST.json - package manifest
  Future<void> _verifyZip(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      if (archive.isEmpty) {
        throw FirmwareDownloadException('ZIP archive is empty');
      }

      // Check for expected firmware file (disting_NT.bin in bootable_images/)
      final hasFirmware = archive.any(
        (file) =>
            file.name.toLowerCase().contains('disting') &&
            file.name.toLowerCase().endsWith('.bin'),
      );
      if (!hasFirmware) {
        throw FirmwareDownloadException(
          'ZIP does not contain expected firmware file (disting_NT.bin)',
        );
      }
    } catch (e) {
      if (e is FirmwareDownloadException) rethrow;
      throw FirmwareDownloadException('ZIP verification failed: corrupted archive');
    }
  }

  /// Delete a downloaded firmware package
  Future<void> deleteFirmwarePackage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silently ignore deletion errors - file may already be gone
    }
  }

  /// Clear cached firmware release data
  void clearCache() {
    _cachedReleases = null;
    _lastFetch = null;
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}
