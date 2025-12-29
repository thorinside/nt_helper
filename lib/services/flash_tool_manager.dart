import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:nt_helper/models/flash_progress.dart';

/// Manages the nt-flash tool binary - auto-downloading from GitHub releases
class FlashToolManager {
  final http.Client _httpClient;
  static const String _githubApiUrl =
      'https://api.github.com/repos/thorinside/nt-flash/releases/latest';

  FlashToolManager({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Get the path to the nt-flash tool, downloading if not present
  Future<String> getToolPath() async {
    final toolDir = await _getToolDirectory();
    final binaryName = _getBinaryName();
    final toolPath = path.join(toolDir.path, binaryName);

    if (await _isToolPresent(toolPath)) {
      return toolPath;
    }

    await _downloadTool(toolDir.path, binaryName);
    return toolPath;
  }

  /// Get the directory where the tool is stored
  Future<Directory> _getToolDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    final toolDir = Directory(path.join(appSupport.path, 'nt-flash'));
    if (!await toolDir.exists()) {
      await toolDir.create(recursive: true);
    }
    return toolDir;
  }

  /// Check if the tool is present and executable (on Unix)
  Future<bool> _isToolPresent(String toolPath) async {
    final file = File(toolPath);
    if (!await file.exists()) {
      return false;
    }

    // On Unix, check executable permission
    if (Platform.isLinux || Platform.isMacOS) {
      final stat = await file.stat();
      // Check if any execute bit is set (owner, group, or other)
      return (stat.mode & 0x49) != 0; // 0x49 = 0111 in octal (execute bits)
    }

    return true;
  }

  /// Get the binary name after extraction
  String _getBinaryName() {
    if (Platform.isWindows) {
      return 'nt-flash.exe';
    }
    return 'nt-flash';
  }

  /// Get the platform keyword used in asset names (macos, windows, linux)
  String _getPlatformKeyword() {
    if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isLinux) {
      return 'linux';
    }
    throw UnsupportedError('Platform not supported for firmware updates');
  }

  /// Download and extract the tool from GitHub releases
  Future<void> _downloadTool(String toolDir, String binaryName) async {
    // Fetch latest release info from GitHub API
    final releaseResponse = await _httpClient.get(
      Uri.parse(_githubApiUrl),
      headers: {'Accept': 'application/vnd.github.v3+json'},
    );

    if (releaseResponse.statusCode != 200) {
      throw FlashToolDownloadException(
        'Failed to fetch release info: HTTP ${releaseResponse.statusCode}',
      );
    }

    final releaseData = jsonDecode(releaseResponse.body) as Map<String, dynamic>;
    final assets = releaseData['assets'] as List<dynamic>?;

    if (assets == null || assets.isEmpty) {
      throw const FlashToolDownloadException('No assets found in release');
    }

    // Find the matching archive asset by platform keyword
    final platformKeyword = _getPlatformKeyword();
    String? downloadUrl;
    String? assetFileName;
    for (final asset in assets) {
      final assetName = asset['name'] as String?;
      if (assetName != null && assetName.contains(platformKeyword)) {
        downloadUrl = asset['browser_download_url'] as String?;
        assetFileName = assetName;
        break;
      }
    }

    if (downloadUrl == null || assetFileName == null) {
      throw FlashToolDownloadException(
        'No $platformKeyword release asset found',
      );
    }

    // Download the archive
    final archiveResponse = await _httpClient.get(Uri.parse(downloadUrl));

    if (archiveResponse.statusCode != 200) {
      throw FlashToolDownloadException(
        'Failed to download archive: HTTP ${archiveResponse.statusCode}',
      );
    }

    // Extract the binary from the archive
    await _extractBinary(
      archiveResponse.bodyBytes,
      assetFileName,
      toolDir,
      binaryName,
    );

    final toolPath = path.join(toolDir, binaryName);

    // Set executable permission on Unix
    if (Platform.isLinux || Platform.isMacOS) {
      final chmodResult = await Process.run('chmod', ['+x', toolPath]);
      if (chmodResult.exitCode != 0) {
        throw FlashToolDownloadException(
          'Failed to set executable permission: ${chmodResult.stderr}',
        );
      }
    }

    // On macOS, remove quarantine attribute (best effort)
    if (Platform.isMacOS) {
      await _removeQuarantineAttribute(toolPath);
    }
  }

  /// Extract the nt-flash binary from a zip or tar.gz archive
  Future<void> _extractBinary(
    List<int> archiveBytes,
    String assetFileName,
    String toolDir,
    String binaryName,
  ) async {
    Archive archive;

    if (assetFileName.endsWith('.zip')) {
      archive = ZipDecoder().decodeBytes(archiveBytes);
    } else if (assetFileName.endsWith('.tar.gz')) {
      final tarBytes = GZipDecoder().decodeBytes(archiveBytes);
      archive = TarDecoder().decodeBytes(tarBytes);
    } else {
      throw FlashToolDownloadException(
        'Unsupported archive format: $assetFileName',
      );
    }

    // Find the nt-flash binary in the archive
    ArchiveFile? binaryFile;
    for (final file in archive) {
      // The binary is named 'nt-flash' (or 'nt-flash.exe' on Windows)
      // It may be in a subdirectory like 'nt-flash-v1.1.0-macos/'
      final fileName = path.basename(file.name);
      if (fileName == binaryName && file.isFile) {
        binaryFile = file;
        break;
      }
    }

    if (binaryFile == null) {
      throw FlashToolDownloadException(
        'Binary $binaryName not found in archive',
      );
    }

    // Write the binary to the tool directory
    final outputPath = path.join(toolDir, binaryName);
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(binaryFile.content as List<int>);
  }

  /// Remove macOS quarantine attribute (best effort - logs warning on failure)
  Future<void> _removeQuarantineAttribute(String toolPath) async {
    try {
      final result = await Process.run(
        'xattr',
        ['-d', 'com.apple.quarantine', toolPath],
      );
      if (result.exitCode != 0) {
        // Log warning but don't fail - the attribute might not exist
        // which is fine (exitCode 1 with "No such xattr")
        final stderr = result.stderr.toString().trim();
        if (!stderr.contains('No such xattr')) {
          debugPrint('Warning: Failed to remove quarantine attribute: $stderr');
        }
      }
    } catch (e) {
      // xattr command might not be available, log but don't fail
      debugPrint('Warning: xattr command failed: $e');
    }
  }

  /// Visible for testing - get platform keyword
  static String getPlatformKeywordForTesting({
    required bool isMacOS,
    required bool isWindows,
    required bool isLinux,
  }) {
    if (isMacOS) {
      return 'macos';
    } else if (isWindows) {
      return 'windows';
    } else if (isLinux) {
      return 'linux';
    }
    throw UnsupportedError('Platform not supported for firmware updates');
  }

  /// Visible for testing - get binary name
  static String getBinaryNameForTesting({
    required bool isWindows,
  }) {
    return isWindows ? 'nt-flash.exe' : 'nt-flash';
  }
}
