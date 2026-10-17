# Chat providers

Chat Settings supports Anthropic and OpenAI (including the existing Claude and
Codex subscription modes), plus three separately configured options:

| Provider | Connection | Configuration |
|---|---|---|
| Google Gemini | Google's OpenAI-compatible Chat Completions API | Gemini API key, model ID |
| OpenRouter | `https://openrouter.ai/api/v1` | OpenRouter API key, model ID |
| Local / OpenAI-compatible | Configurable Chat Completions endpoint | Server URL, model ID, optional API key/context window |

Genkit still owns the agent loop. These options reuse the existing abortable,
streaming OpenAI-compatible transport; no Node sidecar or new plugin dependency
is introduced. No existing subscription authentication or model is replaced.

## Configuration

Choose a provider, enter its credential where required, refresh the model list
using the icon beside Model, and choose or type a model ID. Save commits only the
selected additional profile; Cancel changes nothing. Credentials do not fall back
to a different provider's keys. The legacy OpenAI custom endpoint is retained.

For Ollama, the usual URL is `http://127.0.0.1:11434/v1`; LM Studio normally uses
`http://127.0.0.1:1234/v1`. API roots and complete `/chat/completions` URLs are
accepted. Localhost means the device running nt_helper: a phone needs a reachable
server address instead. HTTPS is recommended off-device; mobile transport policy,
local-network permissions, firewall and server binding may additionally apply.
No TLS verification or platform network policy is weakened by this change.

An optional local context value should match the server's configured context,
not merely the model's advertised maximum. Without an override, local uses an
8192-token advisory fallback. The server must have enough context for the NT tool
catalogue and conversation. Discovery supplies cloud context limits when present;
manually entered unknown cloud models use a conservative 32768-token fallback.

## Compatibility and safety

- Choose a function-calling model for NT tools; screenshot interpretation also
  requires vision. Discovery cannot guarantee every model/server capability.
- OpenRouter discovery excludes models explicitly advertising no tool support;
  generation requests require the routed provider to support the supplied
  parameters. Gemini discovery uses Google's paginated native model catalog.
- Text, extracted file text and images use the common transport. Raw PDF/binary
  support is not added to these three options; the existing attachment guard
  explains unsupported files before sending a model request.
- Gemini function-call signatures and OpenRouter reasoning metadata survive
  streaming, Genkit history repair and persisted conversations. Opaque fields are
  replayed only to their originating endpoint and model, never used as commands.
- Settings/credentials are separate from chat checkpoints and retain the existing
  local-preferences storage policy, not a new encrypted credential vault.
- Settings deliberately contain controls and labels, not instructional prose.
  Errors/loading remain available through fixed-slot icons, tooltips and live
  semantics. Security-consent confirmations are retained.

## Verification

Focused HTTP/Genkit fixtures cover all three new options through a streamed
model → tool screenshot → model loop, credential isolation, metadata persistence,
endpoint normalization, keyless local access, catalogs, profile saving/cancel,
late-response isolation and fixed control geometry. Existing transport, catalog,
settings-reset and history regressions were also checked. No full suite rerun.

The OpenRouter public model-catalog shape was checked live without an API key.
No paid Gemini/OpenRouter generation or real local-model inference was run.
Actual provider-account/model and cross-platform acceptance remain live testing.
Native-widget evidence: `evidence/chat-providers/`.
