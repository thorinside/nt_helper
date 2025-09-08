# Spec Requirements Document

> Spec: Routing Editor Mapping Integration  
> Created: 2025-09-08  
> Status: Planning

## Goal

In the routing editor, show a mapping icon on algorithm nodes that have mapped parameters, and let users click menu items to open the existing mapping editor bottom sheet.

## Requirements

### 1. Show Mapping Icon
- When an algorithm has any mapped parameters, show the mapping icon (Icons.map_sharp) on the left side of the node title bar
- Use the same styling as synchronized_screen.dart: primaryContainer background, 0.6 scale

### 2. Add Menu Items for Mapped Parameters  
- In the existing overflow menu (three dots), add menu items for each mapped parameter
- Show parameter names like "Frequency", "Amplitude", etc.
- Place these above the existing "Delete" item with a divider

### 3. Launch Mapping Editor
- When user taps a mapped parameter menu item, open the existing MappingEditorBottomSheet
- Pass the correct parameter data and slot information
- Handle the returned mapping data to update the parameter

## Implementation Files

- **Main file to modify**: `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/routing/algorithm_node_widget.dart`
- **Reference for mapping logic**: `/Users/nealsanche/nosuch/nt_helper/lib/ui/synchronized_screen.dart` (lines around MappingEditButton)
- **State source**: DistingCubit provides slot data and parameter mappings

## Success Criteria

1. Algorithm nodes show mapping icon when they have mapped parameters
2. Overflow menu shows mapped parameter names as clickable items
3. Clicking a parameter opens the mapping editor bottom sheet
4. Mapping changes are saved and reflected in both routing and synchronized views

## Out of Scope

- Creating new UI components (reuse existing)  
- Modifying the MappingEditorBottomSheet itself
- Adding mapping to input/output nodes
- Any TopAppBar component creation or migration