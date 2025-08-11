# PRP: Plugin Gallery Documentation Links (Updated)

## Context

```yaml
context:
  implementation:
    - approach: "Direct browser launch instead of in-app viewer"
    - rationale: "Simpler implementation, full GitHub rendering with Mermaid"
    
  patterns:
    - file: lib/ui/gallery_screen.dart:88-133
      copy: "Direct URL launching pattern"
    - file: lib/models/gallery_models.dart:332
      copy: "hasReadmeDocumentation getter"
    
  benefits:
    - "No need for complex SVG/badge rendering fixes"
    - "Native GitHub rendering with syntax highlighting"
    - "Mermaid diagrams work out of the box"
    - "Reduced app size (no markdown/SVG dependencies)"
```

## Implementation

### Current Approach: Direct Browser Launch

**LOCATION** lib/ui/gallery_screen.dart:
  - METHOD: _showReadmeDialog opens GitHub URL with #readme anchor
  - DEPENDENCY: url_launcher package for cross-platform URL opening
  - BEHAVIOR: Constructs GitHub URL and launches in external browser

### Benefits Over In-App Viewer

1. **Rendering Quality**: GitHub's native rendering handles all edge cases
2. **Maintenance**: No need to maintain markdown/SVG rendering code
3. **Features**: Users get full GitHub features (code navigation, search, etc.)
4. **Size**: Smaller app bundle without markdown_widget and flutter_svg

### User Experience

- Documentation button in plugin card opens browser immediately
- GitHub URL includes #readme anchor to jump to documentation
- Fallback error handling if URL cannot be launched
- Works consistently across all platforms

## Removed Components

- `lib/ui/widgets/markdown_viewer_dialog.dart` - In-app viewer (deleted)
- `lib/services/readme_service.dart` - README fetching service (deleted)
- `markdown_widget` and `flutter_svg` dependencies (removed)
- README caching logic in gallery_cubit (cleaned up)

## Dependencies

Current minimal dependency:
```yaml
dependencies:
  url_launcher: ^6.3.1
```

## Testing

Manual test:
1. Open gallery screen
2. Click documentation icon on any plugin
3. Verify browser opens to GitHub repository README
4. Verify #readme anchor scrolls to documentation