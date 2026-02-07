# CPU Monitor Widget: Information Only in Tooltip

**Severity:** Medium

**Status: Addressed (2026-02-06)** — in commit 664e27b

**Files affected:**
- `lib/ui/cpu_monitor_widget.dart` (lines 131-167, `_buildCpuDisplay`)

## Description

The `CpuMonitorWidget` displays CPU usage as "XX% | YY%" text inside a small container. Detailed slot-by-slot breakdown is only available via a `Tooltip`. Issues:

1. **Tooltip content is inaccessible**: The detailed CPU breakdown is in a tooltip (lines 131-133). Tooltips require long-press or hover on mobile, which conflicts with VoiceOver navigation gestures.

2. **No semantic label on the container**: The container with the memory icon and percentage text has no `Semantics` wrapper. Screen readers will read the icon and text separately.

3. **High usage warning is color-only**: When CPU usage exceeds 90%, the color changes to red. There is no text or semantic indicator of the high usage state.

4. **Small touch/tap target**: The CPU monitor container is compact, potentially below the 48x48 minimum.

## Impact on blind users

Blind users will hear fragmented information like "memory" and some percentages, but won't understand that this shows CPU usage, which core each percentage refers to, or when CPU usage is critically high.

## Recommended fix

Wrap the widget in a `Semantics` widget:
```dart
Semantics(
  label: isLoading
      ? 'CPU monitor: loading'
      : 'CPU usage: Core 1 ${cpu1 ?? 0}%, Core 2 ${cpu2 ?? 0}%${isHighUsage ? ", warning: high usage" : ""}',
  child: Tooltip(...),
)
```
