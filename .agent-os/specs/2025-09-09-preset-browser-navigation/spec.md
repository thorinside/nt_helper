# Spec Requirements Document

> Spec: Three-Panel Preset Browser Navigation
> Created: 2025-09-09

## Overview

Implement a three-panel preset browser navigation system similar to macOS Finder for browsing and loading Disting NT presets via SysEx directory traversal. This feature will replace the broken preset loading functionality and provide an intuitive, beautiful interface for navigating preset collections with visual feedback during SysEx operations.

## User Stories

### Preset Collection Browser

As a Disting NT user, I want to browse my preset collection using a three-panel navigation interface, so that I can quickly navigate through nested directories and find the presets I need.

The user opens the preset browser from the SynchronizedScreen menu. They see their preset directory structure in the first panel. When they select a directory, its contents appear in the second panel. Selecting a subdirectory shows its contents in the third panel. A progress bar appears during SysEx read operations, providing visual feedback. They can navigate back using a back button, sort by name or date, and quickly access recent presets.

### Flexible Root Directory Support

As a user with a custom preset directory structure, I want the browser to automatically detect my preset root directory, so that I can access my presets regardless of where they're stored on the SD card.

When the user opens the preset browser, the system first checks for /presets directory. If it doesn't exist, the browser starts at the root / directory of the SD card. This ensures all users can access their presets regardless of their storage configuration.

## Spec Scope

1. **Three-Panel Navigation Interface** - Miller columns style navigation with three panels showing directory hierarchy
2. **SysEx Directory Traversal** - Integration with existing SysEx commands for reading directory contents from Disting NT
3. **Visual Progress Feedback** - Horizontal progress bar during SysEx operations to indicate loading state
4. **Sorting Options** - Toggle between alphabetic and date-based sorting for files and directories
5. **Recent Presets Display** - Quick access to recently loaded presets in the interface

## Out of Scope

- Creating or editing presets within the browser
- Preset preview functionality before loading
- Batch operations on multiple presets
- Cloud storage or network preset sharing

## Expected Deliverable

1. Three-panel preset browser dialog accessible from SynchronizedScreen menu that displays directory contents via SysEx traversal
2. Working navigation with back button, sorting toggle, and visual folder/file icons
3. Successful preset loading with full path construction (/presets/...) when user selects a JSON file

## Spec Documentation

- Tasks: @.agent-os/specs/2025-09-09-preset-browser-navigation/tasks.md
- Technical Specification: @.agent-os/specs/2025-09-09-preset-browser-navigation/sub-specs/technical-spec.md