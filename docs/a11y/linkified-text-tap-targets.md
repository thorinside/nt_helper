# Linkified Text Has No Semantic Link Role

**Severity: Medium**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected
- `lib/ui/widgets/linkified_text.dart` (lines 46-102)

## Description

The `LinkifiedText` widget detects URLs in text and makes them clickable using `TextSpan` with `TapGestureRecognizer` (line 83). URLs are shortened to display only the domain name (e.g., "expert-sleepers.co.uk" instead of the full URL).

Issues:
- `TapGestureRecognizer` on a `TextSpan` does create an accessibility node, but it's announced as tappable text, not as a link
- The shortened URL display means screen reader users hear "expert-sleepers.co.uk" without the full context of what the link points to
- No `Semantics(link: true)` wrapper to indicate these are links
- The actual full URL is not communicated to screen readers

## Impact on Blind Users

- Links are detectable (TapGestureRecognizer creates accessibility nodes) but are not announced as links
- Users may not realize they can tap to open a URL
- The shortened URL hides the full destination

## Recommended Fix

While `TextSpan` with recognizer does work with VoiceOver, adding explicit semantics improves the experience:

```dart
TextSpan(
  text: shortUrl,
  style: defaultLinkStyle,
  recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(url),
  semanticsLabel: 'Link: $url', // Full URL for screen readers
)
```
