# Plan: Accurate disting NT module icon in firmware-update screen

## Goal

The animated flow diagram on the firmware-update screen renders a Disting NT module on the right end of the connection. The current artwork is wrong: it draws a tall-and-narrow silhouette, places the screen mid-upper, draws three round knobs (no buttons) with no row arrangement, and shows no jacks. Replace it with a small but recognisable depiction of the actual disting NT faceplate. Do not change the icon's container size or its call sites — only the artwork.

## Authoritative reference

Per <https://www.expert-sleepers.co.uk/distingNT.html> and the supplied product photo description (the live page does not enumerate the layout — it links to the user manual — so the supplied photo description is the authoritative source for layout):

- 22 HP × 3U (~112 mm × 128 mm). Roughly square, only slightly taller than wide (~0.875 W/H).
- Top edge: small "Z" logo centred at top; USB-C port near the upper-left edge.
- Display: wide landscape OLED occupying most of the width, near the top.
- Below the display: a horizontal row of **three** rotary encoders.
- Below the encoders: a horizontal row of **two** large round push-buttons, sitting roughly under the outer two encoders (NOT three, NOT flanking the encoders).
- Lower half — two jack groupings:
  - Left grid of **12 input jacks** in roughly **4 rows × 3 columns**.
  - Right column-pair of **6 output jacks** in roughly **3 rows × 2 columns**.
- Bottom edge: small "expert sleepers / disting NT" text label.

## Current state (verified)

| Concern | Location |
|---|---|
| Icon implementation | `lib/ui/firmware/firmware_flow_diagram.dart:165-193` (`_FlowDiagramPainter._drawDistingIcon`) |
| Painter wiring | same file: `_FlowDiagramPainter.paint()` lines 117-140 (`iconSize = 50.0`, `distingX = size.width - padding - iconSize / 2`) |
| Widget host | `FirmwareFlowDiagram` widget (same file, lines 9-102) — fixed `Size(double.infinity, 150)` |
| Only call site | `lib/ui/firmware/firmware_update_screen.dart:783-787` — `SizedBox(height: 150, child: FirmwareFlowDiagram(...))` |
| App-level grep for other module depictions | `_drawDistingIcon` / `drawDisting` / `module_icon` / `nt_module` / `NTModule` / `DistingIcon` — only `firmware_flow_diagram.dart` matches |

The icon is drawn entirely in code by a `CustomPainter` — no asset to swap. Existing module body is `width: size * 0.5, height: size` (i.e. 25 × 50 logical px inside the 50×50 bounding box) — that's the tall-and-narrow look the spec calls out as wrong.

There is no existing widget test for `FirmwareFlowDiagram` (`test/ui/firmware/` does not exist).

## Approach

Use a `CustomPainter` redraw — same primitive-shape pattern the file already uses, no new asset, fully theme-aware, resolution-independent. Lowest-risk option.

### Container size — preserved exactly

- `iconSize = 50.0` constant unchanged.
- `FirmwareFlowDiagram` widget size unchanged (`Size(double.infinity, 150)`).
- Call-site `SizedBox(height: 150, ...)` unchanged.
- `padding`, `distingX`, `lineEnd` arithmetic in `paint()` unchanged.
- Computer↔module geometry on the canvas is identical.

### Module silhouette — corrected to ~square

The module body's drawn rectangle changes from `size * 0.5 × size` (tall-and-narrow, ratio 0.5) to roughly `size * 0.85 × size` (slightly portrait, ratio ~0.85, matching the real ~0.875 ratio). At `size = 50`, the body becomes ~42.5 × 50 logical px — still inside the 50×50 bounding box, so the connection-line endpoint (`distingX - iconSize/2 - 10`) remains clear of the module body.

This is the inner-silhouette change called out by the spec ("Roughly square / slightly portrait — NOT tall-and-narrow"). The bounding box and rendered height are unchanged.

### New artwork (top → bottom inside the ~42 × 50 module body)

```
┌──────────────────────────┐  ← module body (rounded rect, stroke = onSurface)
│  ┌────────────────────┐  │  ← OLED: landscape rect, ~80% inner width, near top
│  │═══   ═══════       │  │     (subtle "text" hints: 1-2 short horizontal lines)
│  └────────────────────┘  │
│                          │
│      o     o     o       │  ← row of THREE encoders (filled circles)
│                          │
│        ●           ●     │  ← row of TWO buttons (larger filled circles)
│                          │
│   • • •         • •      │  ← jacks: LEFT input grid (4 rows × 3 cols)
│   • • •         • •      │           RIGHT output column-pair (3 rows × 2 cols)
│   • • •         • •      │
│   • • •                  │
└──────────────────────────┘
```

Concrete proportions, relative to `size` (50 at the call site):

- **Module body:** rounded rect, width `size * 0.85`, height `size`, radius 3, stroked `theme.colorScheme.onSurface` strokeWidth 2 (matches existing). Inner padding `~size * 0.04`.
- **Screen:** rounded rect, width `~size * 0.70`, height `~size * 0.13`, top edge at `~size * 0.06` below module top, centred horizontally. Stroked `onSurface`, filled `surface`. Two short horizontal lines inside (each `width ~size * 0.18`, strokeWidth 1, alpha ~0.6) hint at on-screen text.
- **Encoder row:** y at `~size * 0.30` below module top. Three filled circles (`fill = onSurface`), radius `~size * 0.04`, centred horizontally, spaced `~size * 0.20` apart.
- **Button row:** y at `~size * 0.46` below module top. Two filled circles (`fill = onSurface`), radius `~size * 0.05` (slightly larger than encoders to read as buttons), x-positions roughly under the leftmost and rightmost encoders.
- **Jack grid (left, inputs):** 4 rows × 3 columns of small filled circles (`fill = onSurface`), radius `~size * 0.020`. x-range `~size * 0.06` to `~size * 0.36` of module body. y-range `~size * 0.60` to `~size * 0.94`.
- **Jack column-pair (right, outputs):** 3 rows × 2 columns of small filled circles (`fill = onSurface`), radius `~size * 0.020`. x-range `~size * 0.55` to `~size * 0.78`. y-range `~size * 0.62` to `~size * 0.90`.
- A faint horizontal divider (alpha ~0.3, strokeWidth 1) at `~size * 0.56` separates the controls section from the jacks section, reinforcing the two-zone layout.

Top "Z" logo, USB-C port, and bottom "expert sleepers / disting NT" text are NOT drawn — at 50 px tall they would render as noise. The proportions above are the load-bearing readability cues.

### Theming

- Stroke colour for body / screen / divider: `theme.colorScheme.onSurface` (existing pattern).
- Fill for encoders / buttons / jacks: `theme.colorScheme.onSurface` (existing knob fill).
- Screen interior fill: `theme.colorScheme.surface` (so it reads as a recess on coloured backgrounds, falls back gracefully on light/dark themes).
- Faint divider: `theme.colorScheme.onSurface.withValues(alpha: 0.3)`.
- Screen "text" hint lines: `theme.colorScheme.onSurface.withValues(alpha: 0.6)`.
- No hardcoded hex anywhere.

## Files to modify

| File | Change | Rationale |
|---|---|---|
| `lib/ui/firmware/firmware_flow_diagram.dart` | Rewrite `_drawDistingIcon` body (lines 165-193). No signature changes; same `iconSize` math in `paint()`. | The icon to replace. |
| `test/ui/firmware/firmware_flow_diagram_test.dart` | NEW — pump `FirmwareFlowDiagram` inside a `SizedBox(width: 600, height: 150)`, verify it builds without overflow for several `FlashStage` values plus `isError = true`. | Acceptance criterion: at least one new widget test pumps the new icon widget at the documented size. |
| `docs/plans/firmware-update-module-icon_plan.md` | THIS FILE — created/updated in Step 1. | Required artefact. |

No `pubspec.yaml`, no `assets/`, no other UI files: app-wide grep confirmed the disting NT module is depicted in exactly one place.

## Acceptance criteria checklist

- [ ] Icon silhouette is roughly square / slightly portrait (`width = size * 0.85`, `height = size`), NOT tall-and-narrow.
- [ ] OLED screen drawn near top as a wide landscape rectangle.
- [ ] Three encoders in a horizontal row directly below the screen.
- [ ] Two round buttons in a horizontal row directly below the encoders, positioned under the outer two encoders.
- [ ] Lower half shows: a 4×3 left grid of input-jack circles AND a 3×2 right column-pair of output-jack circles.
- [ ] Same `iconSize = 50.0`, same `Size(double.infinity, 150)`, same call-site `SizedBox(height: 150)`.
- [ ] All colours via `theme.colorScheme.*` — no hardcoded hex.
- [ ] `flutter analyze` clean.
- [ ] `flutter test test/ui/firmware/firmware_flow_diagram_test.dart` passes.
- [ ] No other tests regress.

## Out of scope

- Firmware-update logic, progress reporting, layout outside the icon.
- Animation behaviour (pulse / dashed line / flow dots — keep as-is).
- Accessibility semantics (already covered by the `Semantics` wrapper at lines 68-100; addressed previously per `docs/a11y/11-firmware-flow-diagram-no-semantics.md`).
- Any other module depictions (none exist — verified by app-wide grep for `_drawDistingIcon`, `drawDisting`, `module_icon`, `nt_module`, `NTModule`, `DistingIcon`).
- Asset files. The icon is fully procedural in `_drawDistingIcon`; no asset is created or replaced.

## Gaps integrated

Five Haiku gap-analysis subagents reviewed the initial draft of this plan in parallel. Their findings converged on three load-bearing issues; a fourth recurring observation was about test coverage. Each is addressed inline above, and is also called out here so a reviewer can see the analysis trail.

### Gap A — Module body too narrow (raised by all 5 agents)

**Finding.** The first draft used `width: size * 0.5, height: size` (aspect 0.50). The real Disting NT is ~22 HP × 3U → ~112 mm × 128 mm → aspect 0.875. A 0.50 silhouette renders as "tall-and-skinny", not "tall-rectangular". One agent: "the module will appear noticeably squat compared to the actual portrait Eurorack form factor"; another: "42% narrower than the real module".

**Resolution (already in plan).** Module body is now `width: size * 0.85, height: size`, ratio 0.85 — within ~3% of the real 0.875. See *Module silhouette — corrected to ~square* above. The bounding box (`iconSize = 50`), the widget size, and the call site are all unchanged; only the inner rectangle is wider.

### Gap B — Jack/screen detail unreadable at 50 px (raised by 4 of 5 agents)

**Finding.** In the original draft, the module body was 25 px wide and the proposed jack grid was 6 cols × 3 rows of `~0.9 px` radius circles. Agents called this "indistinguishable dots, aliasing artifacts, visual noise". The screen at `size * 0.13` (~6 px tall) inside a 25-px-wide body was also borderline.

**Resolution (already in plan).** Two changes resolve this:

1. The wider body (Gap A) gives ~42 px of inner width to work with rather than ~25 px.
2. The jack array was redesigned to match the *real* module — a left 4×3 input grid plus a right 3×2 output column-pair — at radius `size * 0.020` (≈ 1 px) over the wider body. With ~30 % of the module width per group and 4-row vertical span, dot pitch is ≥ 3 px in both axes, well above antialiasing noise floor.
3. Bottom-edge text and top-edge logo/USB-C are explicitly omitted (would render as noise at this size). The plan documents this trade-off.

### Gap C — Test coverage shallow (raised by 2 agents)

**Finding.** The first draft only said "verify it builds without overflow". `_FlowDiagramPainter` switches on `stage` and `isError` to choose connection-line style and status-indicator style; a single-stage test would miss regressions in the other branches.

**Resolution (already in plan).** The widget test now exercises **multiple `FlashStage` values plus the `isError = true` case**, asserting (a) the `CustomPaint` is laid out at its documented size and (b) `tester.takeException()` is null after each pump. Implementation note for Step 3: `FirmwareFlowDiagram` starts a `repeat()` `AnimationController`, so tests must use `pump(Duration)` rather than `pumpAndSettle()` (which would spin forever) and dispose between cases.

### Gap D — 1× DPR readability of small features (raised in round-2 audit by Agent #5)

**Finding.** Even with the wider body, the round-2 readability audit noted that at 1× device pixel ratio:
- jack circles at radius `size * 0.022` (≈ 1.1 px) antialias toward gray mush;
- encoder vs. button radius distinction (`0.04` vs. `0.05` → 2.0 vs. 2.5 px) reads as "two same-size dots";
- screen "text" hint strokes at strokeWidth 1, alpha 0.6 are nearly invisible on light themes.

**Resolution.** Implementation tweaks (no signature, size, or call-site changes):
- `jackRadius`: `size * 0.022` → `size * 0.026` (≈ 1.3 px) — small bump above the antialias floor.
- `encoderRadius`: `size * 0.04` → `size * 0.035`; `buttonRadius`: `size * 0.05` → `size * 0.055`. Buttons are now ~57% larger than encoders (was ~25%) — the "large round push-button" cue from the spec is now visually unmissable at 1× DPR.
- Hint stroke: alpha `0.6` → `0.7`, strokeWidth `1` → `1.2`. Still subordinate to the screen border, but legible on light themes.

### Gap E — Test coverage breadth (raised in round-2 audit by Agent #3 and Agent #4)

**Finding.** The first-pass test only exercised the default light theme at 600×150. Two recurring asks:
1. Verify the icon also renders cleanly under a dark theme (the `screen` interior fills with `theme.colorScheme.surface`, which behaves differently in dark mode).
2. Verify a narrower width (e.g. 300×150) does not cause overflow — desktop windows can be resized below 600 px.

**Resolution.** Added two test cases in `test/ui/firmware/firmware_flow_diagram_test.dart`:
- `renders under a dark theme without throwing` — pumps with `ThemeData(brightness: Brightness.dark)`.
- `renders at a narrower width without overflow` — pumps inside a 300×150 SizedBox.
The pump helper now accepts `brightness` and `width` parameters.

### Confirmations from the audit (no action needed)

- **Single call site.** `FirmwareFlowDiagram` is referenced only at `firmware_update_screen.dart:783-787`. `iconSize = 50.0` is a single constant inside the painter. No hidden instantiation elsewhere — verified by grep.
- **No other module depictions.** Searches for `drawDisting`, `_drawDistingIcon`, `module_icon`, `nt_module`, `NTModule`, `DistingIcon` returned only `firmware_flow_diagram.dart`. `lib/ui/widgets/performance/hardware_preview_widget.dart` was inspected and is a parameter-overlay widget, not a module-faceplate depiction. No consistency updates needed elsewhere.
- **Theme integration.** Every colour in the painter resolves through `theme.colorScheme.*`; no hardcoded hex values exist or are introduced.
- **Test directory.** `test/ui/firmware/` did not exist before this work — writing the new test file creates it implicitly.
- **Golden-file tests.** The repo has no `goldens/` directory and no precedent for golden-file tests; not introduced here.
