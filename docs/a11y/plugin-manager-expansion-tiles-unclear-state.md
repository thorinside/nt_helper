# Plugin Manager: Expansion Tile State and Actions Not Clearly Announced

**Severity:** Medium

**Status: Addressed (2026-02-06)** — in commit 664e27b

**Files affected:**
- `lib/ui/plugin_manager_screen.dart` (lines 821-857, `_buildPluginTypeSection`)
- `lib/ui/plugin_manager_screen.dart` (lines 860-921, `_buildPluginCard`)

## Description

1. **Plugin count badges**: Styled containers with numbers lack semantic labels.
2. **Expansion tile state**: No announcement when sections expand/collapse.
3. **Delete button**: Uses color-only (red) to indicate destructive action.
4. **Plugin type icons**: CircleAvatar icons have no semantic label.
5. **RefreshIndicator**: Pull-to-refresh may not be discoverable.

## Impact on blind users

Blind users can navigate the plugin list but may miss counts, won't understand icon meanings, and the destructive delete action lacks non-visual emphasis.

## Recommended fix

Add semantic labels to plugin cards, count badges, and delete buttons with appropriate hints.
