# Playback Controls Sliders Use Opacity for Disabled State

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected
- `lib/ui/widgets/step_sequencer/playback_controls.dart` (lines 495-535, 537-577)

## Description

The Gate Length and Trigger Length sliders are conditionally disabled based on Gate Type:
- When Gate Type = Gate: Gate Length enabled, Trigger Length disabled
- When Gate Type = Trigger: Gate Length disabled, Trigger Length enabled

The disabled state is communicated via `Opacity(opacity: 0.5)` (lines 507, 549) and by passing `null` to `onChanged` on the `Slider`. While passing `null` to `onChanged` does make the slider semantically disabled, the `Opacity` wrapper adds no semantic information.

The `Tooltip` (lines 509-512, 551-554) provides good contextual info ("Disabled when Gate Type is Trigger") which works with VoiceOver.

Additionally, the slider labels use `Slider.label` (lines 527, 569) which only shows during drag - screen reader users won't see this tooltip.

## Impact on Blind Users

- Disabled sliders are correctly disabled via null onChanged (good)
- Tooltip provides context for why disabled (good)
- The text label above the slider ("Gate Length: 50%") is readable (good)
- Minor: the label text and slider are not semantically grouped

## Recommended Fix

The existing implementation is mostly acceptable. For improvement:

```dart
Semantics(
  label: 'Gate Length: $currentValue%',
  enabled: !isDisabled,
  slider: true,
  hint: isDisabled ? 'Disabled when Gate Type is Trigger' : null,
  child: Column(
    children: [
      Text('Gate Length: $currentValue%', ...),
      Slider(...),
    ],
  ),
)
```
