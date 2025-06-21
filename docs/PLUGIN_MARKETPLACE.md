# Disting NT Plugin Marketplace

## Overview

The Disting NT Plugin Marketplace is a centralized system for discovering, downloading, and installing community-created plugins for the Disting NT module. The marketplace uses a JSON-based schema hosted on the internet that contains metadata about available plugins, their GitHub repositories, and installation instructions.

## Architecture

### Marketplace JSON File
- **Location**: Hosted on a public URL (e.g., GitHub Pages, CDN)
- **Format**: JSON file following the defined schema
- **Updates**: Updated periodically by maintainers
- **Caching**: Client apps can cache with TTL for performance

### Plugin Distribution
- **Source**: GitHub repositories with releases
- **Format**: ZIP archives containing plugin files
- **Installation**: Automatic download, extraction, and installation to SD card
- **Organization**: Plugins organized by author subdirectories

## Schema Structure

### Top-Level Properties

#### Metadata
```json
{
  "version": "1.0.0",
  "lastUpdated": "2024-01-15T10:30:00Z",
  "metadata": {
    "name": "Disting NT Community Marketplace",
    "description": "Official community marketplace...",
    "maintainer": {
      "name": "Expert Sleepers",
      "email": "support@expert-sleepers.co.uk"
    }
  }
}
```

#### Categories
Plugins are organized into logical categories:
- **synthesis**: Oscillators, filters, sound generation
- **effects**: Audio processing and effects
- **sequencing**: Sequencers and rhythm generators
- **utility**: Tools and utilities
- **experimental**: Cutting-edge algorithms

#### Authors
Author information indexed by GitHub username:
```json
{
  "authors": {
    "username": {
      "name": "Display Name",
      "bio": "Short biography",
      "verified": true,
      "socialLinks": {
        "github": "username",
        "twitter": "handle"
      }
    }
  }
}
```

### Plugin Schema

#### Required Fields
- **id**: Unique identifier (kebab-case)
- **name**: Human-readable name
- **description**: Short description
- **type**: Plugin type (`lua`, `threepot`, `cpp`)
- **author**: GitHub username
- **repository**: GitHub repository information
- **releases**: Release version information
- **installation**: Installation configuration

#### Repository Information
```json
{
  "repository": {
    "owner": "github-username",
    "name": "repository-name",
    "url": "https://github.com/username/repo",
    "branch": "main"
  }
}
```

#### Installation Configuration
```json
{
  "installation": {
    "targetPath": "lua/",
    "subdirectory": "author-name",
    "assetPattern": ".*\\.zip$",
    "extractPattern": ".*\\.lua$"
  }
}
```

This configuration means:
- Download ZIP files from GitHub releases
- Extract `.lua` files from the archive
- Install to `programs/lua/author-name/` on the SD card

#### Release Management
```json
{
  "releases": {
    "latest": "v2.1.0",
    "stable": "v2.0.3",
    "beta": "v2.2.0-beta.1"
  }
}
```

Supports different release channels:
- **latest**: Most recent release (may include pre-releases)
- **stable**: Latest stable release
- **beta**: Latest beta/pre-release

## Installation Workflow

### 1. Discovery
- App fetches marketplace JSON from hosted URL
- Parses available plugins, categories, and authors
- Displays in marketplace UI with filtering/search

### 2. Selection
- User browses plugins by category or search
- Views plugin details, screenshots, documentation
- Selects desired release version (stable/latest/beta)

### 3. Download
- App fetches GitHub releases API for the repository
- Finds release matching the selected version
- Downloads ZIP asset matching `assetPattern`

### 4. Extraction
- Extracts files matching `extractPattern` from ZIP
- Validates file types and extensions
- Prepares files for installation

### 5. Installation
- Determines target path: `programs/{targetPath}{subdirectory}/`
- Creates necessary directories on SD card
- Copies extracted files to target location
- Updates local plugin registry

## Directory Structure on SD Card

```
programs/
├── lua/
│   ├── synthwizard/
│   │   ├── granular-delay.lua
│   │   └── other-plugins.lua
│   └── community-dev/
│       ├── euclidean-sequencer.lua
│       └── chord-generator.lua
├── three_pot/
│   └── community-dev/
│       └── chord-generator.3pot
└── plug-ins/
    ├── official-pack.o
    └── other-plugins.o
```

## Plugin Types

### Lua Scripts (.lua)
- **Target**: `programs/lua/`
- **Subdirectories**: Organized by author
- **Extensions**: `.lua`
- **Description**: User-programmable algorithms

### 3pot Plugins (.3pot)
- **Target**: `programs/three_pot/`
- **Subdirectories**: Organized by author
- **Extensions**: `.3pot`
- **Description**: Three-parameter algorithms

### C++ Plugins (.o)
- **Target**: `programs/plug-ins/`
- **Subdirectories**: Usually flat (no subdirectories)
- **Extensions**: `.o`
- **Description**: Compiled native algorithms

## Verification and Security

### Author Verification
- **verified**: Boolean flag for trusted authors
- Verified authors have additional privileges
- Verification managed by marketplace maintainers

### Plugin Verification
- **verified**: Boolean flag for reviewed plugins
- Indicates plugin has been tested and approved
- Helps users identify quality/safe plugins

### Content Moderation
- Marketplace maintainers review submissions
- Can remove plugins that violate guidelines
- Community reporting system for issues

## Implementation Considerations

### GitHub API Integration
- Use GitHub Releases API to fetch release information
- Handle rate limiting appropriately
- Cache release data to reduce API calls

### Error Handling
- Network connectivity issues
- Invalid ZIP files or missing assets
- SD card write permissions
- Insufficient storage space

### User Experience
- Progress indicators for downloads
- Offline mode with cached marketplace data
- Update notifications for installed plugins
- Rollback capability for failed installations

### Performance
- Lazy loading of plugin details
- Image caching for screenshots/avatars
- Background downloads
- Incremental marketplace updates

## Future Enhancements

### Community Features
- User ratings and reviews
- Plugin recommendations
- Usage statistics and analytics
- Community forums integration

### Advanced Installation
- Dependency management between plugins
- Plugin collections/bundles
- Automatic updates for installed plugins
- Version conflict resolution

### Developer Tools
- Plugin submission workflow
- Automated testing and validation
- Documentation generation
- Release automation

## Example URLs

### Marketplace JSON
```
https://expertsleepers.github.io/disting-nt-marketplace/marketplace.json
```

### GitHub Repository
```
https://github.com/synthwizard/disting-granular-delay
```

### Release API
```
https://api.github.com/repos/synthwizard/disting-granular-delay/releases/tags/v2.1.0
```

### Asset Download
```
https://github.com/synthwizard/disting-granular-delay/releases/download/v2.1.0/granular-delay-v2.1.0.zip
```

This marketplace system provides a robust, scalable foundation for community plugin distribution while maintaining security and ease of use. 