# Algorithm Documentation Screen: Missing Heading Semantics

**Severity:** Low

**Files affected:**
- `lib/ui/algorithm_documentation_screen.dart` (entire file)

## Description

Section titles ("Description", "Categories", "I/O Ports", "Specifications", "Parameters", "Features") use `textTheme.titleLarge` styling but lack `Semantics(header: true)` annotation. Port icons are decorative but not excluded from semantics. Parameter details use bullet separators that may be read awkwardly.

## Impact on blind users

Screen reader users cannot use heading navigation to jump between sections. For algorithms with many parameters, they must linearly swipe through all content. Decorative icons add noise.

## Recommended fix

1. Add `Semantics(header: true)` to section titles.
2. Add `ExcludeSemantics` to decorative port icons.
3. Add semantic labels to parameter detail strings for natural reading.
