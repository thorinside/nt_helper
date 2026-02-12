import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nt_helper/models/app_release.dart';
import 'package:nt_helper/services/version_comparison_service.dart';
import 'package:nt_helper/utils/sandbox_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum InstallOutcome { success, needsRestart, error }

class InstallResult {
  final InstallOutcome outcome;
  final String message;
  final String? folderPath;

  const InstallResult({
    required this.outcome,
    required this.message,
    this.folderPath,
  });
}

class AppUpdateService {
  final http.Client _httpClient;
  final String? _currentVersionOverride;
  static const String _githubApiUrl =
      'https://api.github.com/repos/thorinside/nt_helper/releases/latest';

  AppRelease? _cachedRelease;
  DateTime? _lastCheckTime;
  static const _cacheDuration = Duration(hours: 1);

  AppUpdateService({http.Client? httpClient, String? currentVersion})
      : _httpClient = httpClient ?? http.Client(),
        _currentVersionOverride = currentVersion;

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;

  Future<AppRelease?> checkForUpdate({
    bool forceRefresh = false,
    bool skipVersionCheck = false,
  }) async {
    if (!_isDesktop) return null;
    if (Platform.isMacOS && SandboxUtils.isSandboxed) return null;

    if (!forceRefresh &&
        _cachedRelease != null &&
        _lastCheckTime != null &&
        DateTime.now().difference(_lastCheckTime!) < _cacheDuration) {
      return _cachedRelease;
    }

    try {
      final response = await _httpClient.get(
        Uri.parse(_githubApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final release = AppRelease.fromGitHubJson(json);

      final currentVersion = _currentVersionOverride ??
          (await PackageInfo.fromPlatform()).version;

      _lastCheckTime = DateTime.now();

      if (skipVersionCheck ||
          VersionComparisonService.hasUpdate(currentVersion, release.version)) {
        _cachedRelease = release;
        return release;
      }

      _cachedRelease = null;
      return null;
    } catch (e) {
      debugPrint('App update check failed: $e');
      return null;
    }
  }

  Future<String> downloadUpdate(
    AppRelease release, {
    void Function(double progress)? onProgress,
  }) async {
    final platformKey = _getPlatformKeyword();
    final url = release.platformAssets[platformKey];
    if (url == null) {
      throw Exception('No download available for $platformKey');
    }

    final request = http.Request('GET', Uri.parse(url));
    final streamedResponse = await _httpClient.send(request);

    final contentLength = streamedResponse.contentLength ?? 0;
    final bytes = <int>[];
    var received = 0;

    await for (final chunk in streamedResponse.stream) {
      bytes.addAll(chunk);
      received += chunk.length;
      if (contentLength > 0 && onProgress != null) {
        onProgress(received / contentLength);
      }
    }

    final tempDir = await _getUpdateDirectory();
    final zipPath = path.join(
      tempDir.path,
      'nt_helper_update_${release.version}.zip',
    );
    await File(zipPath).writeAsBytes(bytes);
    return zipPath;
  }

  Future<InstallResult> installUpdate(String zipPath) async {
    try {
      final tempDir = await _getUpdateDirectory();
      final extractDir = Directory(
        path.join(tempDir.path, 'nt_helper_update_extracted'),
      );
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      if (Platform.isMacOS) {
        // Use ditto to extract on macOS — preserves code signatures,
        // notarization tickets, symlinks, and file permissions.
        final result = await Process.run(
          'ditto',
          ['-x', '-k', zipPath, extractDir.path],
        );
        if (result.exitCode != 0) {
          return InstallResult(
            outcome: InstallOutcome.error,
            message: 'Failed to extract update: ${result.stderr}',
          );
        }
        return await _installMacOS(extractDir);
      }

      // Non-macOS: use Dart archive package
      final zipBytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      for (final file in archive) {
        final filePath = path.join(extractDir.path, file.name);
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }

      if (Platform.isLinux) {
        return await _installLinux(extractDir);
      } else if (Platform.isWindows) {
        return await _installWindows(extractDir);
      }

      return const InstallResult(
        outcome: InstallOutcome.error,
        message: 'Platform not supported for auto-update',
      );
    } catch (e) {
      return InstallResult(
        outcome: InstallOutcome.error,
        message: 'Install failed: $e',
      );
    }
  }

  Future<InstallResult> _installMacOS(Directory extractDir) async {
    final exePath = Platform.resolvedExecutable;
    // Go up 3 levels: MacOS -> Contents -> App.app
    final appBundlePath = path.dirname(
      path.dirname(path.dirname(exePath)),
    );

    // Find the .app in the extracted directory
    final entities = await extractDir.list().toList();
    Directory? sourceApp;
    for (final entity in entities) {
      if (entity is Directory && entity.path.endsWith('.app')) {
        sourceApp = entity;
        break;
      }
    }

    if (sourceApp == null) {
      return const InstallResult(
        outcome: InstallOutcome.error,
        message: 'Could not find .app bundle in update archive',
      );
    }

    final targetDir = path.dirname(appBundlePath);

    if (_canWriteTo(targetDir)) {
      final result = await Process.run(
        'ditto',
        [sourceApp.path, path.join(targetDir, path.basename(sourceApp.path))],
      );
      if (result.exitCode == 0) {
        await _removeQuarantineAttribute(appBundlePath);
        return const InstallResult(
          outcome: InstallOutcome.needsRestart,
          message: 'Update installed. Restart to use the new version.',
        );
      }
    }

    // Fallback: copy to ~/Downloads
    return _fallbackToDownloads(sourceApp.path, path.basename(sourceApp.path));
  }

  Future<InstallResult> _installLinux(Directory extractDir) async {
    final exePath = Platform.resolvedExecutable;
    final appDir = path.dirname(exePath);

    if (_canWriteTo(appDir)) {
      final result = await Process.run(
        'cp',
        ['-Rf', '${extractDir.path}/.', appDir],
      );
      if (result.exitCode == 0) {
        await Process.run('chmod', ['+x', exePath]);
        return const InstallResult(
          outcome: InstallOutcome.needsRestart,
          message: 'Update installed. Restart to use the new version.',
        );
      }
    }

    // Fallback: copy to ~/Downloads
    return _fallbackToDownloads(extractDir.path, 'nt_helper');
  }

  Future<InstallResult> _installWindows(Directory extractDir) async {
    final exePath = Platform.resolvedExecutable;
    final appDir = path.dirname(exePath);
    final currentPid = pid;

    final scriptContent = '''
Start-Sleep -Seconds 2
try {
  Wait-Process -Id $currentPid -Timeout 10 -ErrorAction SilentlyContinue
} catch {}
Copy-Item -Path "${extractDir.path}\\*" -Destination "$appDir" -Recurse -Force
Start-Process "$exePath"
''';

    final tempDir = await _getUpdateDirectory();
    final scriptPath = path.join(tempDir.path, 'nt_helper_update.ps1');
    await File(scriptPath).writeAsString(scriptContent);

    await Process.start(
      'powershell',
      ['-ExecutionPolicy', 'Bypass', '-File', scriptPath],
      mode: ProcessStartMode.detached,
    );

    return const InstallResult(
      outcome: InstallOutcome.needsRestart,
      message: 'Update script launched. The app will restart automatically.',
    );
  }

  Future<void> _removeQuarantineAttribute(String appPath) async {
    try {
      await Process.run('xattr', ['-rd', 'com.apple.quarantine', appPath]);
    } catch (e) {
      debugPrint('Warning: Failed to remove quarantine attribute: $e');
    }
  }

  bool _canWriteTo(String dirPath) {
    try {
      final testFile = File(path.join(dirPath, '.nt_helper_write_test'));
      testFile.writeAsStringSync('test');
      testFile.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<InstallResult> _fallbackToDownloads(
    String sourcePath,
    String name,
  ) async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    final downloadsDir = Directory(path.join(home, 'Downloads'));

    if (!await downloadsDir.exists()) {
      return const InstallResult(
        outcome: InstallOutcome.error,
        message: 'Cannot find Downloads folder.',
      );
    }

    final destPath = path.join(downloadsDir.path, name);

    // Remove existing if present
    final existing = Directory(destPath);
    if (await existing.exists()) {
      await existing.delete(recursive: true);
    }

    final copyResult = Platform.isMacOS
        ? await Process.run('ditto', [sourcePath, destPath])
        : await Process.run('cp', ['-Rf', sourcePath, destPath]);
    if (copyResult.exitCode != 0) {
      return const InstallResult(
        outcome: InstallOutcome.error,
        message: 'Failed to copy update to Downloads.',
      );
    }

    if (Platform.isMacOS) {
      await _removeQuarantineAttribute(destPath);
    }

    return InstallResult(
      outcome: InstallOutcome.success,
      message: 'Update saved to ~/Downloads/$name. Install it manually from there.',
      folderPath: downloadsDir.path,
    );
  }

  Future<Directory> _getUpdateDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    final updateDir = Directory(path.join(appSupport.path, 'app-update'));
    if (!await updateDir.exists()) {
      await updateDir.create(recursive: true);
    }
    return updateDir;
  }

  String _getPlatformKeyword() {
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    throw UnsupportedError('Platform not supported for app updates');
  }
}
