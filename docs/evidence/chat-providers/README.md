# Provider settings widget evidence

Actual `ChatSettingsDialog` renders with the shipped Material theme and
illustrative profiles/model catalogs. API keys are fixture values and masked.
These are widget evidence, not full-app or live-provider acceptance captures.

- `gemini-light.png`, `openrouter-dark.png`, `local-dark.png`: 920 × 760.
- `local-compact.png`: 380 × 640, 150% text scaling; content scrolls.

The final UI follows the request for controls and labels only. Normal helper
paragraphs, model-count copy and storage explanations are absent. Refresh is a
labelled icon; errors/loading have fixed indicator slots and live semantics.

Explicit capture (skipped by default):

```sh
CAPTURE_CHAT_PROVIDERS=1 flutter test --no-pub --concurrency=1 \
  test/chat/ui/additional_provider_settings_test.dart
```

Fonts use SFNS and Material Icons when available on the development Mac.
Assertions do not depend on those fonts. Catalogs are injected: no provider
credentials, paid inference, NT hardware or native build is used by this test.
