# Chat agent runtime options

Research date: 2026-10-17. No nt_helper dependencies or runtime code changed.

## Bundled Node + Pi Durable

A desktop Flutter app can ship a private Node runtime and bundled JavaScript
helper, launch it with `Process.start`, and communicate over framed stdin/stdout
or a private local endpoint. Users need not install Node/npm. This is a packaged
sidecar, not a native Dart library or an in-process Dart FFI library.

Measured on macOS ARM64 using the official Node **v24.22.0** archive (SHA-256
checked against the release's SHASUMS256.txt):

| Component | Uncompressed bytes | gzip bytes |
|---|---:|---:|
| Official `bin/node` | 122,503,472 | 39,269,883 |
| Minified ESM dependency bundle | 972,514 | 258,159 |

The bundle imports installed Pi Durable **1.1.0**, Chord, pi-ai's model registry,
OpenAI and Anthropic providers, and Node SQLite storage. It exposes an opening
function; it does not include a working Flutter bridge or packaging/signing.
Sizes were obtained with esbuild and gzip level 9, not from a built nt_helper
release. Core payload is approximately **118 MiB installed**, approximately
**38 MiB gzip**. Budget roughly 120–140 MiB installed / 40–55 MiB compressed per
architecture pending actual packaging. These are additions to nt_helper, not its
total size. Shipping multiple architecture runtimes increases the payload.

The Homebrew Node launcher is dynamically linked and only about 130 KiB; that is
not the standalone runtime size and must not be used for this estimate.

Distribution alternatives:

- Private Node executable + bundled `.mjs`: simplest initial layout.
- Node Single Executable Application (SEA): embeds code into a Node executable;
  it does not remove the Node runtime cost. Features vary by Node release.
- In-process libnode embedding: possible through native integration but more
  complex than a helper and not a route to removing V8/runtime size.

Desktop requires per-platform builds and helper lifecycle management. macOS also
requires correct nested-code signing, sandbox/hardened-runtime entitlement work,
and distribution-path review. Standard iOS Flutter apps cannot use the desktop
`Process.start` sidecar design; Android likewise needs a separate native runtime
integration if a JavaScript runtime is required. Do not describe this as a simple
all-platform packaging change.

Pi Durable is experimental. Its durable transcript/task model is useful for
reconnection and interrupted runs, but hardware mutations must remain non-replay-
safe. A restart must not repeat an uncertain encoder/button gesture. Model
subscription OAuth compatibility is a separate question from provider API-key
support and must be checked before replacing nt_helper's existing adapters.

Sources:

- [Node release archive](https://nodejs.org/dist/v24.22.0/node-v24.22.0-darwin-arm64.tar.gz)
- [Release checksums](https://nodejs.org/dist/v24.22.0/SHASUMS256.txt)
- [Node SEA documentation](https://nodejs.org/api/single-executable-applications.html)
- [Pi Durable source/readme](https://github.com/earendil-works/pi/tree/main/packages/durable)
- Local primary source: installed `@earendil-works/pi-durable` 1.1.0 README and package.json.

## Native Dart candidates

Package versions/dates below were read from pub.dev's package API. Documentation
claims were cross-checked with published package archives where noted. None was
integrated into nt_helper or evaluated against live NT tools during this research.

### Dartantic: direct Flutter fit

- `dartantic_ai` **3.4.2**, published 2026-07-02.
- Native Dart agentic multi-step tool calling, streaming, multimodal inputs,
  multiple providers, and MCP integration.
- `dartantic_chat` **0.3.1** provides Flutter chat widgets and a Dartantic provider;
  its README identifies it as a fork of Flutter's AI Toolkit.
- History is managed/persisted by the application. The documented examples save
  and restore serialized messages; this is not Pi Durable's task-checkpoint model.
- This can replace both provider/tool-loop plumbing and chat UI, but cancellation,
  image tool results, subscriptions, history integrity and hardware cleanup still
  need an integration spike.

Sources:
[Overview](https://docs.dartantic.ai/),
[tool loop](https://docs.dartantic.ai/tool-calling),
[history ownership](https://docs.dartantic.ai/multi-turn-chat),
[chat integration](https://docs.dartantic.ai/dartantic-chat/feature-integration),
[package](https://pub.dev/packages/dartantic_ai),
[chat widgets](https://pub.dev/packages/dartantic_chat).

### Genkit Dart: newer, stronger session abstraction

- `genkit`, `genkit_openai`, and `genkit_anthropic` **1.0.0**, published 2026-10-07.
- Official Genkit project. The agent API packages model loops, history, tools,
  streaming, sessions/snapshots, aborts and interrupts.
- **Agents remain Beta/experimental**, despite the core package's 1.0 version.
  Agent imports are `experimental.dart`; `FileSessionStore` is in
  `experimental_io.dart`.
- These symbols were verified in the published genkit 1.0.0 archive, not merely
  inferred from unreleased website examples.
- Local in-process agents and remote clients share a chat API. Official Flutter
  tutorials emphasize a remote/backend deployment. Verify the local runtime and
  selected provider plugins in a native Flutter release build before promising a
  drop-in all-platform in-process replacement. No Node runtime is inherently
  needed by the Dart library; the development UI/CLI is a separate concern.
- Snapshot/session persistence is not evidence of exactly-once hardware execution
  or equivalence to Pi Durable's interruption semantics.

Sources:
[Agent overview](https://genkit.dev/docs/dart/agents/overview/),
[run and stream](https://genkit.dev/docs/dart/agents/run/),
[tool loop](https://genkit.dev/docs/dart/tool-calling/),
[Flutter tutorial](https://genkit.dev/docs/app-frameworks/flutter/),
[published package](https://pub.dev/packages/genkit),
[source](https://github.com/genkit-ai/genkit-dart).

### Other options

- **LangChain.dart** (`langchain` 0.9.0, 2026-08-27) offers agents/tool abstractions
  and provider integrations. A broader framework than nt_helper likely needs;
  Dart support does not imply the full Python LangGraph durable runtime exists.
  [Source](https://github.com/davidmigloz/langchain_dart)
- **Flutter AI Toolkit** (`flutter_ai_toolkit` 1.0.0) is principally Flutter chat
  UI/provider integration. It should not be confused with a general durable agent
  runtime. [Source](https://github.com/flutter/ai)

Native Dart libraries add compiled application code/dependencies rather than a
Node/V8 executable. Their actual release-size delta needs a before/after build;
no numeric native-Dart size estimate was measured here.

## Recommendation for nt_helper

Follow-up: [Genkit migration assessment](genkit-chat-migration.md) documents a
successful native AOT feasibility probe, dependency resolution against nt_helper,
and a staged in-process migration with subscription-authentication caveats.

First compare a small Dartantic integration with Genkit's experimental local
agent API, reusing the existing ToolRegistry as native callbacks rather than
looping through the app's own HTTP MCP endpoint. Keep the external MCP API intact.
Choose Pi Durable's desktop sidecar if its specific durability/recovery semantics
outweigh the runtime and distribution cost.

Acceptance checks for either native candidate: screenshot results reach the model
as images; multi-turn tool chains complete; cancel releases held controls and
returns the UI to idle; provider errors surface clearly; transcript restart is
coherent; interrupted hardware commands are not replayed; existing subscription
login paths work or have an explicit supported replacement. Agent libraries do
not automatically fix rendering, authentication, or unsafe tool behavior.
