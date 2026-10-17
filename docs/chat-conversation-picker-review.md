# Conversation picker: Impeccable review

Scope: the local chat-history picker and its chat-header entry points. Mode:
**Operate**. Preserve nt_helper's existing Material 3 theme, semantic colours,
typography and standard controls. No app-wide redesign or new dependencies.

## Audit: initial implementation

Source-based native/Flutter audit of the first implementation, before the
following distill/delight/harden passes. Not a VoiceOver/TalkBack certification
or physical-device acceptance result.

**Platform verdict:** a conventional native Material dialog, not a web-shaped
control. The established app is Material across desktop/mobile; do not replace
that identity with unrelated platform styling for this one feature.

| Dimension | Score / 4 | Finding |
|---|---:|---|
| Accessibility | 2 | Repeated generic delete labels; fixed-height error text risks clipping with enlarged type. |
| Performance | 3 | Virtualized list and small metadata sidecars; no attachments loaded merely to browse. |
| Appearance/theming | 4 | Standard Material components inherit light/dark semantic roles. |
| Platform conformance | 3 | Familiar controls; primary emphasis incorrectly favours Close over New chat. |
| Adaptivity | 3 | Bounded dialog and scrolling; enlarged text/keyboard states needed explicit coverage. |
| **Total** | **15 / 20** | **Good; address weak dimensions before delivery.** |

Five actionable findings: one P1, four P2; no verified P0 or P3 findings.

- **P1 — Fixed-height failure message.** Picker's 20-point error slot cannot
  accommodate larger or wrapped text. Impact: recovery information may be
  clipped. Material accessibility/text scaling. **Harden:** use naturally sized
  error content inside the flexible body.
- **P2 — Repeated destructive controls.** Every row exposes a delete icon with
  the same generic label. Impact: visual competition and ambiguous screen-reader
  actions. **Distill:** named row-options menus, with confirmed deletion inside.
- **P2 — Reversed action hierarchy.** Filled Close competes with secondary New
  chat. Impact: the strongest affordance dismisses rather than helps the user.
  **Distill:** one clear New chat action; standard close icon/Escape.
- **P2 — No finding aid.** Titles plus absolute dates require scanning all saved
  chats. Impact grows with history length. **Delight:** local title search,
  recent-first date groups and type-then-Enter selection.
- **P2 — Read error has no recovery action.** Impact: users must dismiss and
  reopen to retry. **Harden:** explicit retry without changing stored files.

Positive findings to retain: native focus traversal and dismissal, semantic
colour roles, lazy rows, local-only metadata browsing, and no tool/model calls
when opening saved history.

## Applied direction

**Delight thesis:** returning to a conversation should feel like finding your
place, not restarting an operation on your NT.

- Distill: remove repeated chat icons, the redundant footer Close action and
  the permanently empty error slot. Keep rows flat; move deletion into options.
- Delight: Today/Yesterday/Earlier groups, a textual Current chat marker and
  check, search-and-Enter, input focus after selection, and immediate landing at
  the selected chat's latest message. Empty drafts stay restorable but do not
  clutter the list. No celebration, sound, authored motion or extra assets.
- Harden: clear search/no-results recovery, retry for read errors, long-title
  truncation with the full accessible name, 48-point secondary action targets,
  scrollable confirmation copy, semantic errors and keyboard-inset checks.
- Protect: search is scoped with the existing digit/period shortcut blocker;
  typing a firmware version must not operate the underlying device UI.
- Preserve: Escape/Back dismisses, selection never resumes generation, provider
  settings/credentials are not copied into saved sessions, and memory notes /
  separate text snapshots are explicitly distinguished from saved chats.

## Verification and limits

Two bounded widget-render inspection rounds covered desktop light/dark,
320 × 480 compact layout and 200% text scaling. Final evidence:
`evidence/chat-conversations/` (reproduction instructions alongside the images).
The actual picker and app theme are rendered with illustrative metadata; these
are not physical-device, full-app or assistive-technology certification. No
browser detector applies to this Flutter/native surface.

The confirmation run passed **23** persistence/picker checks, including opt-in
capture, and the earlier run passed **31** unchanged existing/header regressions
(**54 distinct focused checks** total). Analyzer clean; no full suite rerun.
Coverage includes search + Enter, Escape, clear/no-results, delete confirmation
and failure, read retry, 200%/RTL titles, keyboard insets, file/Genkit attachment
round trips, saved references, isolated contexts and close/restore races.

The single correction batch fixed the verified enlarged-header crowding, a menu
label overflow and the retry callback. The final polish pass preserved semantic
colours, normal focus/hover states and the existing app identity. No further
cosmetic iteration is scheduled.

Final pass: **polish** for consistency against the existing theme, not another
visual redesign. Remaining live acceptance: the user verifies history across a
real app restart and interaction with their NT.
