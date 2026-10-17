/// Normalizes an API root or Chat Completions URL without changing its host.
/// Credentials belong in headers, never a URL that can appear in diagnostics.
Uri chatCompletionsUri(String baseUrl) {
  final uri = Uri.tryParse(baseUrl.trim());
  if (uri == null ||
      !const ['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw const FormatException(
      'Enter an HTTP(S) endpoint without embedded credentials or a fragment.',
    );
  }
  var path = uri.path.replaceFirst(RegExp(r'/+$'), '');
  if (path.isEmpty) path = '/v1';
  if (!path.endsWith('/chat/completions')) path = '$path/chat/completions';
  return uri.replace(path: path);
}

Uri compatibleModelsUri(String baseUrl) {
  final uri = chatCompletionsUri(baseUrl);
  return uri.replace(
    path:
        '${uri.path.substring(0, uri.path.length - '/chat/completions'.length)}/models',
  );
}

const geminiChatUrl =
    'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions';
const openRouterChatUrl = 'https://openrouter.ai/api/v1/chat/completions';
const defaultLocalBaseUrl = 'http://127.0.0.1:11434/v1';
