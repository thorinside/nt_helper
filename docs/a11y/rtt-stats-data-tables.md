# RTT Stats Dialog Data Tables Accessibility

**Severity: Low**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/rtt_stats_dialog.dart` (lines 131-173, 268-316)

## Description

The `RttStatsDialog` uses `DataTable` widgets to display RTT statistics. While Flutter's `DataTable` has built-in accessibility support, there are some issues:

1. **Horizontal scrolling data tables**: Both data tables are wrapped in `SingleChildScrollView(scrollDirection: Axis.horizontal)` (lines 149, 279). Horizontally scrolling content is difficult for screen reader users because VoiceOver's swipe-right gesture navigates to the next element rather than scrolling horizontally.

2. **No table summary**: The data tables have no accessible summary describing what data they contain. Column headers are present but there's no overview.

3. **Summary card stat items**: The `_buildStatItem` widget (lines 236-265) uses `Icon` + `Column(label, value)` in a `Row`. The icon adds visual flair but creates noise in the accessibility tree. Each stat (Requests, Timeouts, Avg RTT, etc.) would be better as a single semantic unit.

4. **Color-coded timeout values**: Timeout cells use red color styling when > 0 (line 300-304). This color distinction is lost on screen readers.

5. **No-connection/no-data states**: The empty states (lines 62-96) use `Icon` + `Text` but the icons are decorative noise.

## Impact on Blind Users

- Minor: This is a developer/debug tool
- Horizontally scrolling tables require special navigation techniques
- Color-coded values lose their emphasis

## Recommended Fix

1. Hide decorative icons in empty states:

```dart
ExcludeSemantics(
  child: Icon(Icons.wifi_off, size: 64, color: Colors.grey),
),
```

2. Group stat items semantically:

```dart
Semantics(
  label: '$label: $value',
  excludeSemantics: true,
  child: Row(/* existing _buildStatItem content */),
)
```

3. Add text indicator for high timeout counts:

```dart
DataCell(
  Text(
    timeouts > 0 ? '$timeouts (elevated)' : '$timeouts',
    style: timeouts > 0
        ? TextStyle(color: Colors.red.shade700)
        : null,
  ),
),
```
