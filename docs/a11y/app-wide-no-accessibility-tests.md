# Zero Accessibility Tests

**Severity: High**

**Status: Addressed (2026-02-06)** — Created test/ui/accessibility/ with widget_semantics_test.dart (semantics, dialogs, bottom sheets) and routing_accessibility_test.dart (contrast ratios, WCAG compliance)

## Files Affected
- `test/` directory (95+ test files, none for accessibility)

## Description

The test suite contains 95+ test files covering business logic, MIDI communication, state management, and widget rendering. However, there are **zero tests** specifically for accessibility:

- No semantic label verification
- No contrast ratio tests
- No keyboard navigation tests
- No focus management tests
- No screen reader announcement tests

Without automated accessibility testing, regressions are inevitable as features are added or modified.

## Recommended Fix

1. Add `flutter_test` semantics assertions to existing widget tests:
   ```dart
   expect(find.bySemanticsLabel('Parameter name'), findsOneWidget);
   ```

2. Add dedicated accessibility test files for critical workflows:
   - Parameter editing with screen reader
   - Routing connection creation via keyboard
   - Preset save/load announcement verification

3. Consider adding `accessibility_tools` or similar package to dev dependencies for automated a11y checking during development

4. Add golden tests with semantics tree dumps to catch regressions
