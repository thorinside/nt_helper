# Technical Specification

> Created: 2025-09-08  
> Version: 2.0.0 (Simplified)

## Implementation Steps

### Step 1: Add Mapping Icon to Algorithm Node

**File**: `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/routing/algorithm_node_widget.dart`

**Current code location**: Line 168-174 (leadingIcon section)

**Change**: Modify the `_buildTitleBar` method to show mapping icon when slot has mapped parameters.

**Code pattern to add**:
```dart
// Get slot data from cubit to check for mappings
final cubit = context.read<DistingCubit>();
final state = cubit.state;
bool hasAnyMappings = false;

if (state is DistingStateSynchronized) {
  final slot = state.slots.firstWhere((s) => s.slotIndex == widget.slotNumber - 1);
  hasAnyMappings = slot.parameters.any((p) => p.mappingData != null);
}

// Show mapping icon if any parameters are mapped
Widget? leadingIcon;
if (hasAnyMappings) {
  leadingIcon = Transform.scale(
    scale: 0.6,
    child: IconButton.filledTonal(
      style: IconButton.styleFrom(
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      icon: const Icon(Icons.map_sharp),
      onPressed: null, // Just an indicator, not clickable
    ),
  );
}
```

### Step 2: Add Mapped Parameter Menu Items

**File**: `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/routing/algorithm_node_widget.dart`

**Current code location**: Line 200-227 (PopupMenuButton itemBuilder)

**Change**: Modify the PopupMenuButton's itemBuilder to include mapped parameters.

**Code pattern**:
```dart
itemBuilder: (context) {
  List<PopupMenuItem<String>> items = [];
  
  // Add mapped parameter items first
  final cubit = context.read<DistingCubit>();
  final state = cubit.state;
  if (state is DistingStateSynchronized) {
    final slot = state.slots.firstWhere((s) => s.slotIndex == widget.slotNumber - 1);
    final mappedParams = slot.parameters.where((p) => p.mappingData != null).toList();
    
    for (final param in mappedParams) {
      items.add(PopupMenuItem(
        value: 'mapping_${param.parameterNumber}',
        child: Row(
          children: [
            const Icon(Icons.map_sharp, size: 18),
            const SizedBox(width: 8),
            Text(param.name),
          ],
        ),
      ));
    }
    
    if (mappedParams.isNotEmpty) {
      items.add(const PopupMenuDivider());
    }
  }
  
  // Add existing delete item
  items.add(PopupMenuItem(
    value: 'delete',
    enabled: widget.onDelete != null,
    child: Row(
      children: [
        Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
        const SizedBox(width: 8),
        Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
      ],
    ),
  ));
  
  return items;
}
```

### Step 3: Handle Menu Item Selection

**File**: `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/routing/algorithm_node_widget.dart`

**Current code location**: Line 223-227 (onSelected callback)

**Change**: Add handling for mapping parameter selections.

**Code pattern**:
```dart
onSelected: (value) {
  if (value == 'delete') {
    _handleDelete();
  } else if (value.startsWith('mapping_')) {
    final paramNumber = int.parse(value.substring(8));
    _handleMappingEdit(paramNumber);
  }
}
```

### Step 4: Add Mapping Editor Launch Method

**File**: `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/routing/algorithm_node_widget.dart`

**Add new method**:
```dart
Future<void> _handleMappingEdit(int parameterNumber) async {
  final cubit = context.read<DistingCubit>();
  final state = cubit.state;
  
  if (state is! DistingStateSynchronized) return;
  
  final slot = state.slots.firstWhere((s) => s.slotIndex == widget.slotNumber - 1);
  final parameter = slot.parameters.firstWhere((p) => p.parameterNumber == parameterNumber);
  
  final data = parameter.mappingData ?? PackedMappingData.filler();
  final myMidiCubit = context.read<MidiListenerCubit>();
  
  final updatedData = await showModalBottomSheet<PackedMappingData>(
    context: context,
    isScrollControlled: true,
    builder: (context) => MappingEditorBottomSheet(
      myMidiCubit: myMidiCubit,
      data: data,
      slots: state.slots,
    ),
  );
  
  if (updatedData != null) {
    cubit.setParameterMapping(
      widget.slotNumber - 1,
      parameterNumber,
      updatedData,
    );
  }
}
```

### Step 5: Add Required Imports

**File**: `/Users/nealsanche/nosuch/nt_helper/lib/ui/widgets/routing/algorithm_node_widget.dart`

**Add to top of file**:
```dart
import 'package:nt_helper/cubit/midi_listener_cubit.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/ui/synchronized_screen.dart';
```

## Dependencies

- **DistingCubit**: Already imported, provides slot and parameter data
- **MidiListenerCubit**: Need to import for MIDI operations  
- **MappingEditorBottomSheet**: Need to import from synchronized_screen.dart
- **PackedMappingData**: Need to import from database.dart

## Testing

1. Load an algorithm with mapped parameters
2. Verify mapping icon appears on node
3. Click overflow menu and verify mapped parameter items appear
4. Click a mapped parameter item and verify mapping editor opens
5. Make changes and verify they save correctly