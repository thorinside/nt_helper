# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-09-09-preset-browser-navigation/spec.md

> Created: 2025-09-09
> Status: Ready for Implementation

## Tasks

- [ ] 1. Create PresetBrowserCubit and State Management
  - [ ] 1.1 Write tests for PresetBrowserCubit state transitions
  - [ ] 1.2 Create PresetBrowserState with Freezed (initial, loading, loaded, error states)
  - [ ] 1.3 Implement PresetBrowserCubit with navigation history and panel state management
  - [ ] 1.4 Add directory caching mechanism for SysEx responses
  - [ ] 1.5 Implement sorting logic (alphabetic/date toggle)
  - [ ] 1.6 Verify all state management tests pass

- [ ] 2. Build Three-Panel Navigation Widget
  - [ ] 2.1 Write tests for ThreePanelNavigator widget
  - [ ] 2.2 Create ThreePanelNavigator widget with Row and three flex panels
  - [ ] 2.3 Implement DirectoryPanel widget for reusable panel display
  - [ ] 2.4 Add selection highlighting and item interaction handlers
  - [ ] 2.5 Implement folder/file icons with proper visual distinction
  - [ ] 2.6 Add horizontal LinearProgressIndicator below panels
  - [ ] 2.7 Verify all widget tests pass

- [ ] 3. Integrate SysEx Directory Operations
  - [ ] 3.1 Write tests for directory traversal logic
  - [ ] 3.2 Connect requestDirectoryListing() to PresetBrowserCubit
  - [ ] 3.3 Implement root directory detection (/presets fallback to /)
  - [ ] 3.4 Add firmware version and offline state checks
  - [ ] 3.5 Handle DirectoryListing parsing into FileSystemItem models
  - [ ] 3.6 Implement error handling for timeouts and failed operations
  - [ ] 3.7 Verify all SysEx integration tests pass

- [ ] 4. Add Navigation Controls and History
  - [ ] 4.1 Write tests for navigation controls
  - [ ] 4.2 Implement back button with navigation history stack
  - [ ] 4.3 Add sorting toggle button (alphabetic/date)
  - [ ] 4.4 Integrate SharedPreferences preset history (key: 'presetHistory')
  - [ ] 4.5 Build full path construction for selected files
  - [ ] 4.6 Create return Map with sdCardPath, action, displayName
  - [ ] 4.7 Verify all navigation tests pass

- [ ] 5. Connect to SynchronizedScreen Menu
  - [ ] 5.1 Write integration tests for menu option
  - [ ] 5.2 Add new PopupMenuItem for three-panel browser
  - [ ] 5.3 Implement dialog launch and result handling
  - [ ] 5.4 Maintain compatibility with existing LoadPresetDialog
  - [ ] 5.5 Test preset loading workflow end-to-end
  - [ ] 5.6 Verify all integration tests pass