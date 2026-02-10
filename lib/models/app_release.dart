class AppRelease {
  final String version;
  final String tagName;
  final String body;
  final DateTime publishedAt;
  final Map<String, String> platformAssets;

  const AppRelease({
    required this.version,
    required this.tagName,
    required this.body,
    required this.publishedAt,
    required this.platformAssets,
  });

  factory AppRelease.fromGitHubJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    final version =
        tagName.startsWith('v') ? tagName.substring(1) : tagName;

    final assets = json['assets'] as List<dynamic>? ?? [];
    final platformAssets = <String, String>{};
    for (final asset in assets) {
      final name = (asset['name'] as String? ?? '').toLowerCase();
      final url = asset['browser_download_url'] as String? ?? '';
      if (url.isEmpty) continue;
      if (name.contains('macos')) {
        platformAssets['macos'] = url;
      } else if (name.contains('windows')) {
        platformAssets['windows'] = url;
      } else if (name.contains('linux')) {
        platformAssets['linux'] = url;
      }
    }

    return AppRelease(
      version: version,
      tagName: tagName,
      body: json['body'] as String? ?? '',
      publishedAt: DateTime.tryParse(
            json['published_at'] as String? ?? '',
          ) ??
          DateTime.now(),
      platformAssets: platformAssets,
    );
  }
}
