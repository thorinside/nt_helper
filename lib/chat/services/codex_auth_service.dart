import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class CodexAuthException implements Exception {
  final String message;

  const CodexAuthException(this.message);

  @override
  String toString() => message;
}

class CodexAuthSnapshot {
  final String accessToken;
  final String refreshToken;
  final String? idToken;
  final String? accountId;

  const CodexAuthSnapshot({
    required this.accessToken,
    required this.refreshToken,
    this.idToken,
    this.accountId,
  });

  Map<String, String> get authHeaders => {
    'Authorization': 'Bearer $accessToken',
    if (accountId != null && accountId!.isNotEmpty)
      'ChatGPT-Account-ID': accountId!,
  };
}

class CodexAuthService {
  final http.Client _client;
  final String authFilePath;

  static const clientId = 'app_EMoamEEZ73f0CkXaXp7hrann';
  static const tokenUrl = 'https://auth.openai.com/oauth/token';

  CodexAuthService({http.Client? client, String? authFilePath})
    : _client = client ?? http.Client(),
      authFilePath = authFilePath ?? defaultAuthFilePath();

  static String defaultAuthFilePath() {
    final home = Platform.isWindows
        ? Platform.environment['USERPROFILE']
        : Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw const CodexAuthException('Unable to locate home directory.');
    }
    return p.join(home, '.codex', 'auth.json');
  }

  Future<bool> authFound() async {
    try {
      await loadAuth();
      return true;
    } on CodexAuthException {
      return false;
    } on FileSystemException {
      return false;
    } on FormatException {
      return false;
    }
  }

  Future<CodexAuthSnapshot> loadAuth() async {
    final file = File(authFilePath);
    if (!await file.exists()) {
      throw const CodexAuthException(
        'Codex ChatGPT auth not found. Run `codex login` in a terminal, then try again.',
      );
    }

    final root = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final tokens = root['tokens'];
    if (tokens is! Map<String, dynamic>) {
      throw const CodexAuthException(
        'Codex auth file does not contain tokens.',
      );
    }

    final accessToken = _nonEmptyString(tokens['access_token']);
    final refreshToken = _nonEmptyString(tokens['refresh_token']);
    if (accessToken == null || refreshToken == null) {
      throw const CodexAuthException(
        'Codex auth file is missing an access or refresh token.',
      );
    }

    return CodexAuthSnapshot(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: _nonEmptyString(tokens['id_token']),
      accountId: _nonEmptyString(tokens['account_id']),
    );
  }

  void dispose() {
    _client.close();
  }

  Future<CodexAuthSnapshot> refreshAuth() async {
    final current = await loadAuth();
    final response = await _client.post(
      Uri.parse(tokenUrl),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'client_id': clientId,
        'grant_type': 'refresh_token',
        'refresh_token': current.refreshToken,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CodexAuthException(
        'Codex ChatGPT auth refresh failed (${response.statusCode}). Run `codex login` in a terminal, then try again.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = _nonEmptyString(decoded['access_token']);
    if (accessToken == null) {
      throw const CodexAuthException(
        'Codex auth refresh did not return an access token.',
      );
    }

    final file = File(authFilePath);
    final root = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final rawTokens = root['tokens'];
    final tokens = rawTokens is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawTokens)
        : <String, dynamic>{};

    final idToken = _nonEmptyString(decoded['id_token']);
    final refreshToken = _nonEmptyString(decoded['refresh_token']);
    tokens['access_token'] = accessToken;
    if (idToken != null) tokens['id_token'] = idToken;
    if (refreshToken != null) tokens['refresh_token'] = refreshToken;

    final accountId =
        _accountIdFromAccessToken(accessToken) ??
        _nonEmptyString(tokens['account_id']) ??
        current.accountId;
    if (accountId != null) tokens['account_id'] = accountId;

    root['tokens'] = tokens;
    root['last_refresh'] = DateTime.now().toUtc().toIso8601String();
    await _writeJsonBestEffortAtomic(file, root);

    return CodexAuthSnapshot(
      accessToken: accessToken,
      refreshToken: refreshToken ?? current.refreshToken,
      idToken: idToken ?? current.idToken,
      accountId: accountId,
    );
  }

  Future<void> _writeJsonBestEffortAtomic(
    File destination,
    Map<String, dynamic> data,
  ) async {
    final directory = destination.parent;
    if (!await directory.exists()) await directory.create(recursive: true);
    final temp = File(
      p.join(
        directory.path,
        'auth.json.${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );
    await temp.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(data)}\n',
      flush: true,
    );

    if (!Platform.isWindows) {
      try {
        final mode = await destination.exists()
            ? (await destination.stat()).mode & 0x1ff
            : 0x180;
        await Process.run('chmod', [mode.toRadixString(8), temp.path]);
      } on Object {
        // Keep the refreshed credentials usable even if chmod is unavailable.
      }
    }

    try {
      await temp.rename(destination.path);
    } on FileSystemException {
      if (Platform.isWindows && await destination.exists()) {
        await destination.delete();
        await temp.rename(destination.path);
        return;
      }
      rethrow;
    }
  }

  static String? _nonEmptyString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _accountIdFromAccessToken(String accessToken) {
    final payload = _jwtPayload(accessToken);
    final auth = payload['https://api.openai.com/auth'];
    if (auth is Map<String, dynamic>) {
      return _nonEmptyString(auth['chatgpt_account_id']);
    }
    return null;
  }

  static Map<String, dynamic> _jwtPayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) return const {};
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded);
      return payload is Map<String, dynamic> ? payload : const {};
    } on Object {
      return const {};
    }
  }
}
