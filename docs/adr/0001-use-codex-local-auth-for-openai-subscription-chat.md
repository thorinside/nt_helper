# Use Codex local auth for OpenAI subscription chat

OpenAI Subscription (Codex) chat uses the user's existing desktop Codex sign-in from `~/.codex/auth.json` instead of registering or embedding a new OpenAI OAuth app. The implementation stays in Dart, is desktop-only, stores a separate subscription model setting, and may refresh Codex credentials only after a 401 response and remembered user consent because refresh can rotate tokens and requires atomically updating Codex's auth file.
