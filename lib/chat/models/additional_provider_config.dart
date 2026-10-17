/// Configuration for a separately authenticated chat endpoint. Never included
/// in conversation checkpoints. Keys use the existing local settings storage.
class AdditionalProviderConfig {
  final String apiKey;
  final String model;
  final String baseUrl;
  final int? contextWindowTokens;

  const AdditionalProviderConfig({
    this.apiKey = '',
    this.model = '',
    this.baseUrl = '',
    this.contextWindowTokens,
  });

  Map<String, dynamic> toJson() => {
    'api_key': apiKey,
    'model': model,
    'base_url': baseUrl,
    if (contextWindowTokens != null)
      'context_window_tokens': contextWindowTokens,
  };

  factory AdditionalProviderConfig.fromJson(Map<String, dynamic> json) =>
      AdditionalProviderConfig(
        apiKey: json['api_key'] as String? ?? '',
        model: json['model'] as String? ?? '',
        baseUrl: json['base_url'] as String? ?? '',
        contextWindowTokens: json['context_window_tokens'] as int?,
      );
}
