# nt_helper

nt_helper helps users manage a Disting NT module and use an in-app chat assistant to inspect and control module state.

## Language

**OpenAI Subscription (Codex)**:
A chat provider option that uses a user's ChatGPT subscription entitlement through their Codex sign-in. It is distinct from OpenAI API-key usage. Users choose the subscription model in chat settings, with `gpt-5.4-mini` as the default.
_Avoid_: OpenAI OAuth app, OpenAI API key, generic OpenAI subscription

**Codex Auth Refresh Permission**:
A remembered user consent allowing nt_helper to refresh local Codex ChatGPT credentials after OpenAI rejects a request as unauthorized. Without it, the user refreshes Codex auth outside nt_helper.
_Avoid_: automatic OAuth takeover, implicit refresh
