# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-09-08-routing-editor-mapping-integration/spec.md

> Created: 2025-09-08
> Status: Ready for Implementation

## Tasks

### 1. Implement Algorithm Node Mapping Integration

#### 1.1 Write Widget Tests for Mapping Icon Display
- Create widget tests for AlgorithmNodeWidget with mapped parameters
- Test mapping icon appears when slot has mapped parameters
- Test mapping icon does not appear when no parameters are mapped
- Test icon styling and positioning matches design specifications
- Verify icon is indicator-only (not clickable)

#### 1.2 Add Mapping Icon to Algorithm Node Widget
- Modify `_buildTitleBar` method in `algorithm_node_widget.dart`
- Add logic to check for mapped parameters in slot data
- Implement conditional mapping icon display using Transform.scale with IconButton.filledTonal
- Use Icons.map_sharp with proper theming (primaryContainer colors)
- Position icon as leadingIcon in title bar

#### 1.3 Write Tests for Popup Menu Items
- Create widget tests for popup menu with mapped parameter items
- Test mapped parameters appear as menu items with mapping icon
- Test menu divider appears between mapped items and delete item
- Test menu item text matches parameter names
- Test empty state when no mapped parameters exist

#### 1.4 Add Mapped Parameter Menu Items
- Modify PopupMenuButton itemBuilder in `algorithm_node_widget.dart`
- Add logic to extract mapped parameters from slot data
- Create PopupMenuItem entries for each mapped parameter
- Include Icons.map_sharp and parameter name in menu item display
- Add PopupMenuDivider between mapped items and existing delete item
- Maintain existing delete item functionality

#### 1.5 Write Tests for Menu Selection Handling
- Create widget tests for menu item selection callbacks
- Test mapping parameter selection calls correct handler with parameter number
- Test delete item selection maintains existing behavior
- Mock mapping editor launch and verify correct parameters passed

#### 1.6 Implement Menu Selection Handler
- Add onSelected callback handling for mapping menu items
- Parse parameter number from 'mapping_' prefixed values
- Create `_handleMappingEdit` method to launch mapping editor
- Maintain existing delete handling functionality

#### 1.7 Add Mapping Editor Launch Implementation
- Implement `_handleMappingEdit` method in `algorithm_node_widget.dart`
- Extract slot and parameter data from DistingCubit state
- Use existing or create filler PackedMappingData for parameter
- Launch MappingEditorBottomSheet with showModalBottomSheet
- Handle mapping data updates via DistingCubit.setParameterMapping

#### 1.8 Add Required Imports and Dependencies
- Import MidiListenerCubit from cubit/midi_listener_cubit.dart
- Import PackedMappingData from db/database.dart
- Import MappingEditorBottomSheet from ui/synchronized_screen.dart
- Verify all imports are properly organized

#### 1.9 Integration Testing
- Test complete workflow: load algorithm → verify icon → open menu → select mapping → edit mapping → save
- Test with multiple mapped parameters on single algorithm
- Test with algorithms that have no mapped parameters
- Test edge cases: empty mapping data, invalid parameter numbers
- Verify performance impact is minimal on routing editor

#### 1.10 Verify All Tests Pass
- Run `flutter test` and ensure all widget tests pass
- Run `flutter analyze` and verify zero warnings/errors
- Test manually on device to verify UI behavior matches specifications
- Confirm mapping editor integration works end-to-end