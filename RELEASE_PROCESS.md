# Release Process

This document explains how to create releases with automatically generated, beautiful release notes.

> **⚠️ Integration Required**: To enable automatic release notes, see [WORKFLOW_INTEGRATION.md](./WORKFLOW_INTEGRATION.md) for the one-time workflow setup.

## 🚀 Quick Release

To create a new release with automatic changelog generation:

```bash
# For a minor version bump (1.61.0 → 1.62.0)
./version && git push && git push --tags

# For a patch version bump (1.61.0 → 1.61.1)  
./version patch && git push && git push --tags

# For a major version bump (1.61.0 → 2.0.0)
./version major && git push && git push --tags
```

## 📝 How Release Notes Are Generated

The GitHub Actions workflow automatically generates beautiful, categorized release notes by:

### 1. **Commit Message Analysis**
The system scans commit messages since the last release and categorizes them:

- **✨ Features**: `feat:`, `add:`, `new:`, `feature:`
- **🔧 Improvements**: `improve:`, `enhance:`, `update:`, `refactor:`
- **🐛 Bug Fixes**: `fix:`, `bug:`
- **📚 Documentation**: `docs:`, `doc:`
- **📋 Pull Requests**: Messages containing `#[number]`
- **🔄 Other Changes**: Everything else

### 2. **GitHub's Auto-Generate Feature**
Uses GitHub's built-in release notes generation for additional PR context.

### 3. **Release Template Configuration**
The `.github/release.yml` file configures automatic categorization based on PR labels:

- 🚀 New Features
- 🐛 Bug Fixes  
- 🔧 Improvements & Refactoring
- 📱 Mobile & Platform Support
- 🎛️ Hardware Integration
- 🎨 UI/UX Improvements
- 📚 Documentation
- ⚙️ Development & Tooling

## 💡 Best Practices for Great Release Notes

### Commit Message Format
Use conventional commit format for automatic categorization:

```bash
feat: add ES-5 direct output support for Clock Multiplier
fix: resolve cross-platform drag-and-drop installation issues  
docs: update routing system architecture documentation
refactor: improve MIDI connection handling
```

### PR Labels
Add relevant labels to your PRs for proper categorization:
- `feature`, `enhancement`, `feat`, `new`
- `bug`, `fix`, `bugfix`, `hotfix`  
- `mobile`, `ios`, `android`, `platform`
- `hardware`, `midi`, `disting`, `eurorack`, `es5`
- `ui`, `ux`, `design`, `styling`
- `documentation`, `docs`

## 🔧 Manual Release Notes Generation

To generate release notes manually for testing or backfilling:

```bash
# Generate notes for the latest tag
./scripts/generate-release-notes.sh

# Generate notes for a specific tag
./scripts/generate-release-notes.sh v1.61.0

# Generate notes comparing two specific tags
./scripts/generate-release-notes.sh v1.61.0 v1.60.0
```

## 📋 Release Workflow

1. **Development**: Work on features, create PRs with proper labels
2. **Merge**: Merge PRs with descriptive commit messages
3. **Version Bump**: Run `./version [major|minor|patch]`
4. **Push**: `git push && git push --tags`
5. **Automation**: GitHub Actions automatically:
   - Creates the release
   - Generates beautiful changelog
   - Builds and uploads artifacts
   - Publishes to app stores

## 🎯 Result

Your releases will now have beautiful, categorized changelogs like:

```markdown
## 🚀 What's New in v1.61.0

### ✨ Features
- feat: Add platform-native image sharing for mobile routing editor (#79)

### 🔧 Improvements  
- refactor: Optimize routing visualization performance
- update: Enhanced mobile UI responsiveness

### 📋 Pull Requests
- feat: Add platform-native image sharing for mobile routing editor (#79)

---
**Full Changelog**: https://github.com/thorinside/nt_helper/compare/v1.60.0...v1.61.0
```

The system automatically handles version comparison, categorization, and formatting—no manual changelog maintenance required!