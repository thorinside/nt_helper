# GitHub Actions Workflow Integration

This document explains how to integrate the automated release notes generation with your existing GitHub Actions workflow.

## 🚧 Current Limitation

The Claude Code system cannot directly modify workflow files in `.github/workflows/` due to GitHub App permission restrictions. However, we've created scripts and configurations that you can easily integrate manually.

## 🔧 Integration Steps

### 1. Update `tag-build.yml` workflow

Replace the existing "Create GitHub Release" step in `.github/workflows/tag-build.yml` with:

```yaml
      - name: Generate Release Notes
        id: release_notes
        run: |
          chmod +x ./scripts/release-notes-for-workflow.sh
          ./scripts/release-notes-for-workflow.sh ${{ github.ref_name }}

      - name: Create GitHub Release
        uses: ncipollo/release-action@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          tag: ${{ github.ref_name }}
          name: "${{ github.ref_name }} - Automated Release"
          bodyFile: release_notes.md
          draft: false
          prerelease: false
          generateReleaseNotes: true
```

### 2. Files Already Created

The following files have been created and are ready to use:

- ✅ `.github/release.yml` - Configures automatic PR categorization
- ✅ `scripts/release-notes-for-workflow.sh` - Workflow-compatible release notes script  
- ✅ `scripts/generate-release-notes.sh` - Manual release notes generation
- ✅ `RELEASE_PROCESS.md` - Complete documentation

## 🎯 What This Achieves

After integration, your releases will automatically have:

### Beautiful Categorized Changelogs
```markdown
## 🚀 What's New in v1.62.0

### ✨ Features
- feat: Add ES-5 direct output support for Clock Multiplier
- feat: Implement drag-and-drop preset package installation

### 🔧 Improvements  
- refactor: Optimize routing visualization performance
- update: Enhanced mobile UI responsiveness

### 🐛 Bug Fixes
- fix: Resolve cross-platform installation issues
- fix: Address MIDI connection timeout problems

### 📋 Pull Requests
- feat: Add platform-native image sharing for mobile routing editor (#79)

---
**Full Changelog**: https://github.com/thorinside/nt_helper/compare/v1.61.0...v1.62.0
```

### Automatic Categorization
Based on commit message prefixes:
- `feat:`, `add:`, `new:` → ✨ Features
- `fix:`, `bug:` → 🐛 Bug Fixes  
- `improve:`, `enhance:`, `update:`, `refactor:` → 🔧 Improvements
- `docs:`, `doc:` → 📚 Documentation
- Messages with `#[number]` → 📋 Pull Requests

## 🧪 Testing

Before modifying your workflow, test the release notes generation:

```bash
# Test with current version
./scripts/generate-release-notes.sh

# Test with specific version
./scripts/generate-release-notes.sh v1.61.0
```

## 📝 Current Workflow Change Needed

**Original (lines 30-38 in tag-build.yml):**
```yaml
      - name: Create GitHub Release
        uses: ncipollo/release-action@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          tag: ${{ github.ref_name }}
          name: "Release ${{ github.ref_name }}"
          body: "Automated release for version ${{ github.ref_name }}"
          draft: false
          prerelease: false
```

**New (replace with):**
```yaml
      - name: Generate Release Notes
        id: release_notes
        run: |
          chmod +x ./scripts/release-notes-for-workflow.sh
          ./scripts/release-notes-for-workflow.sh ${{ github.ref_name }}

      - name: Create GitHub Release
        uses: ncipollo/release-action@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          tag: ${{ github.ref_name }}
          name: "${{ github.ref_name }} - Automated Release"
          bodyFile: release_notes.md
          draft: false
          prerelease: false
          generateReleaseNotes: true
```

## ✅ Next Steps

1. Make the workflow changes above manually
2. Test with your next release
3. Enjoy beautiful, automated release notes!

The system will automatically:
- Parse commits since last release
- Categorize by type with emojis
- Include PR references
- Generate comparison links
- Create professional changelog format