name: "Routing Canvas Node Positions Persistence"
description: "Persist user-customized node positions in the routing canvas using SharedPreferences"

---

## Goal

**Feature Goal**: Enable persistent storage of user-customized node positions in the routing canvas, ensuring layout preferences are maintained across app sessions and navigation.

**Deliverable**: A SharedPreferences-based persistence layer that automatically saves and restores node positions when users customize the routing canvas layout.

**Success Definition**: When a user arranges nodes in the routing canvas and navigates away or restarts the app, their custom layout is restored exactly as they left it.

## User Persona

**Target User**: Disting NT module users who work with complex algorithm chains

**Use Case**: Users spend time arranging algorithm nodes for clarity, then lose their layout when navigating to other screens or restarting the app

**User Journey**: 
1. User opens routing canvas with default grid layout
2. User drags nodes to create a clearer visual arrangement
3. User navigates to main editor to adjust parameters
4. User returns to routing canvas - custom layout is preserved
5. User closes and reopens app - custom layout still preserved

**Pain Points Addressed**: 
- Lost work when carefully arranged layouts disappear
- Frustration having to repeatedly reorganize nodes
- Cognitive load of re-understanding algorithm flow

## Why

- Improved user experience by respecting user's mental model and organizational preferences
- Reduced cognitive load by maintaining familiar layouts
- Enhanced workflow efficiency by eliminating repetitive reorganization
- Aligns with standard UI/UX expectations for customizable interfaces

## What

Users will be able to:
- Have their custom node positions automatically saved when modified
- See their custom layouts restored when returning to the routing canvas
- Have layouts persist across app restarts
- Reset to default grid layout if desired

### Success Criteria

- [ ] Node positions persist when navigating between screens
- [ ] Node positions persist across app restarts
- [ ] Positions are saved per preset (using preset name as key)
- [ ] Performance remains smooth during drag operations (debounced saves)
- [ ] Graceful fallback to grid layout if restoration fails

## All Needed Context

### Context Completeness Check

_This PRP provides complete implementation details for an engineer unfamiliar with the codebase to successfully implement node position persistence._

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- url: https://docs.flutter.dev/cookbook/persistence/key-value#save-and-read-data
  why: Official Flutter SharedPreferences implementation guide
  critical: Shows async initialization patterns and error handling

- url: https://docs.flutter.dev/data-and-backend/serialization/json#serializing-json-inside-model-classes
  why: JSON serialization patterns for complex objects in Flutter
  critical: Map<int, Object> serialization requires string key conversion

- file: lib/services/settings_service.dart
  why: Existing SharedPreferences patterns and conventions in codebase
  pattern: Singleton service with init(), private keys, getter/setter patterns
  gotcha: Must call init() before use, uses null-aware operators for defaults

- file: lib/cubit/node_routing_cubit.dart
  why: Current state management for node positions
  pattern: Cubit pattern with state updates, subscription to DistingCubit
  gotcha: Must preserve hasUserRepositioned flag to prevent layout recalculation

- file: lib/models/node_position.dart
  why: Data model with existing JSON serialization
  pattern: Freezed model with fromJson/toJson already implemented
  gotcha: Uses freezed code generation - run build_runner after changes

- file: lib/ui/widgets/load_preset_dialog.dart
  why: Example of persisting StringList to SharedPreferences
  pattern: Direct SharedPreferences usage for simple collections
  gotcha: Uses getInstance() in widget, not through service

- file: lib/ui/routing/routing_canvas.dart
  why: UI widget that triggers position updates
  pattern: Delegates all logic to cubit via callbacks
  gotcha: Position updates happen during drag - need debouncing
```

### Current Codebase Structure

Key files for this feature:
```
lib/
├── cubit/
│   ├── node_routing_cubit.dart        # State management for routing canvas
│   └── node_routing_state.dart        # State models including nodePositions Map
├── models/
│   └── node_position.dart             # NodePosition model with JSON support
├── services/
│   └── settings_service.dart          # SharedPreferences wrapper service
└── ui/
    └── routing/
        ├── routing_canvas.dart        # Canvas UI widget
        └── node_routing_widget.dart   # Parent widget providing cubit
```

### Desired Implementation Structure

```
lib/
├── services/
│   └── node_positions_persistence_service.dart  # New service for position persistence
├── cubit/
│   └── node_routing_cubit.dart                  # Modified to use persistence service
└── test/
    └── services/
        └── node_positions_persistence_service_test.dart  # Unit tests
```

### Known Gotchas & Constraints

```dart
// CRITICAL: SharedPreferences only supports primitive types
// Map<int, NodePosition> must be serialized as JSON string

// CRITICAL: Integer keys in Maps must be converted to strings for JSON
// jsonEncode(map) with int keys will fail

// CRITICAL: Position updates during drag are frequent
// Must debounce saves to avoid performance issues

// CRITICAL: Preset name changes invalidate saved positions
// Use preset name as key, accept position loss on rename

// CRITICAL: Algorithm reordering changes indices
// Current code attempts to preserve by name, must maintain this
```

## Implementation Blueprint

### Data Models and Structure

The existing `NodePosition` model already has JSON serialization:

```dart
// Already exists in lib/models/node_position.dart
@freezed
sealed class NodePosition with _$NodePosition {
  const factory NodePosition({
    required int algorithmIndex,
    required double x,
    required double y,
    @Default(200.0) double width,
    @Default(100.0) double height,
  }) = _NodePosition;

  factory NodePosition.fromJson(Map<String, dynamic> json) =>
      _$NodePositionFromJson(json);
}
```

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: CREATE lib/services/node_positions_persistence_service.dart
  - IMPLEMENT: NodePositionsPersistenceService singleton class
  - FOLLOW pattern: lib/services/settings_service.dart (singleton, init, async methods)
  - NAMING: Private static key constants with underscore prefix
  - KEY FORMAT: 'node_positions_<preset_name>' for position data
  - METHODS: savePositions(), loadPositions(), clearPositions()
  - SERIALIZATION: Convert Map<int, NodePosition> to Map<String, dynamic> for JSON
  - DEBOUNCING: Implement 500ms debounce for save operations
  - ERROR HANDLING: Return empty map on load failure, log errors with debugPrint

Task 2: MODIFY lib/cubit/node_routing_cubit.dart constructor and init
  - ADD: NodePositionsPersistenceService as dependency
  - MODIFY: initializeFromRouting() to load saved positions
  - PATTERN: Check for saved positions before calculating grid layout
  - PRESERVE: hasUserRepositioned flag logic
  - KEY: Use current preset name from DistingCubit

Task 3: MODIFY lib/cubit/node_routing_cubit.dart updateNodePosition method
  - ADD: Call to persistence service (debounced)
  - REMOVE: Existing TODO comment about persistence
  - PRESERVE: All existing state update logic
  - PATTERN: Save after state emission, not before

Task 4: ADD reset to default functionality in node_routing_cubit.dart
  - IMPLEMENT: resetToDefaultLayout() method
  - ACTION: Clear saved positions, recalculate grid layout
  - STATE: Set hasUserRepositioned to false
  - EMIT: Updated state with new positions

Task 5: MODIFY lib/ui/routing_page.dart to inject service
  - MODIFY: NodeRoutingCubit instantiation
  - ADD: NodePositionsPersistenceService() as parameter
  - PATTERN: Similar to AlgorithmMetadataService injection

Task 6: MODIFY lib/main.dart initialization
  - ADD: NodePositionsPersistenceService().init() after SettingsService
  - PATTERN: Follow existing service initialization order
  - PLACEMENT: Before runApp() call

Task 7: CREATE test/services/node_positions_persistence_service_test.dart
  - IMPLEMENT: Unit tests for save/load/clear operations
  - TEST: JSON serialization with integer keys
  - TEST: Debouncing behavior
  - TEST: Error handling for corrupted data
  - MOCK: SharedPreferences using shared_preferences_mocks package
  - PATTERN: Follow existing service test patterns
```

### Implementation Patterns & Key Details

```dart
// Service structure pattern
class NodePositionsPersistenceService {
  static NodePositionsPersistenceService? _instance;
  SharedPreferences? _prefs;
  Timer? _saveTimer;
  Map<int, NodePosition>? _pendingPositions;
  String? _pendingKey;
  
  factory NodePositionsPersistenceService() {
    _instance ??= NodePositionsPersistenceService._internal();
    return _instance!;
  }
  
  NodePositionsPersistenceService._internal();
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // CRITICAL: Convert Map<int, NodePosition> to Map<String, dynamic>
  Future<void> savePositions(String presetName, Map<int, NodePosition> positions) async {
    _pendingPositions = positions;
    _pendingKey = 'node_positions_$presetName';
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _flushPendingPositions);
  }
  
  Future<void> _flushPendingPositions() async {
    if (_pendingPositions == null || _pendingKey == null) return;
    
    try {
      final Map<String, dynamic> serializable = _pendingPositions!.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      );
      await _prefs?.setString(_pendingKey!, jsonEncode(serializable));
    } catch (e) {
      debugPrint('Failed to save node positions: $e');
    }
    _pendingPositions = null;
    _pendingKey = null;
  }
  
  Future<Map<int, NodePosition>> loadPositions(String presetName) async {
    try {
      final key = 'node_positions_$presetName';
      final jsonString = _prefs?.getString(key);
      if (jsonString == null) return {};
      
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map(
        (key, value) => MapEntry(int.parse(key), NodePosition.fromJson(value)),
      );
    } catch (e) {
      debugPrint('Failed to load node positions: $e');
      return {};
    }
  }
}

// Cubit integration pattern
class NodeRoutingCubit extends Cubit<NodeRoutingState> {
  final NodePositionsPersistenceService _persistenceService;
  
  Future<void> initializeFromRouting(...) async {
    // Load saved positions if available
    final presetName = _distingCubit.state.maybeMap(
      orElse: () => 'default',
      loaded: (s) => s.currentPreset?.name ?? 'default',
    );
    
    final savedPositions = await _persistenceService.loadPositions(presetName);
    
    if (savedPositions.isNotEmpty) {
      // Use saved positions
      nodePositions = savedPositions;
      hasUserRepositioned = true;
    } else if (!hasUserRepositioned) {
      // Calculate default grid layout
      nodePositions = layoutService.calculateGridLayout(...);
    }
  }
}
```

### Integration Points

```yaml
INITIALIZATION:
  - add to: lib/main.dart
  - pattern: "await NodePositionsPersistenceService().init();"
  - placement: After SettingsService().init()

DEPENDENCY INJECTION:
  - modify: lib/ui/routing_page.dart
  - pattern: "NodeRoutingCubit(widget.cubit, AlgorithmMetadataService(), NodePositionsPersistenceService())"

STATE UPDATES:
  - modify: lib/cubit/node_routing_cubit.dart
  - methods: initializeFromRouting, updateNodePosition, resetToDefaultLayout
  - preserve: Existing state management patterns
```

## Validation Loop

### Level 1: Syntax & Style (Immediate Feedback)

```bash
# After creating new service file
flutter analyze lib/services/node_positions_persistence_service.dart

# After modifying existing files
flutter analyze lib/cubit/node_routing_cubit.dart
flutter analyze lib/ui/routing_page.dart
flutter analyze lib/main.dart

# Run code generation for freezed models if needed
flutter packages pub run build_runner build --delete-conflicting-outputs

# Full project analysis - MUST have zero issues
flutter analyze

# Expected: Zero errors, warnings, or info messages
```

### Level 2: Unit Tests (Component Validation)

```bash
# Test the new persistence service
flutter test test/services/node_positions_persistence_service_test.dart -v

# Test affected cubits
flutter test test/cubit/node_routing_cubit_test.dart -v

# Run all tests to ensure no regressions
flutter test

# Expected: All tests pass
```

### Level 3: Integration Testing (System Validation)

```bash
# Run the app and test manually
flutter run

# Manual test checklist:
# 1. Open routing canvas with a preset
# 2. Drag nodes to custom positions
# 3. Navigate to main editor
# 4. Return to routing canvas - positions preserved
# 5. Restart app (hot restart in Flutter)
# 6. Open same preset - positions still preserved
# 7. Switch presets - different positions for each
# 8. Test reset to default (if UI added)

# Test with different presets
# Test with algorithm reordering
# Test error recovery (corrupt SharedPreferences)
```

### Level 4: Performance Validation

```bash
# Monitor debug console during drag operations
# Should see minimal "Saving positions" debug messages (debounced)

# Check SharedPreferences size
# On Android: adb shell run-as com.nosuch.nt_helper ls -la /data/data/com.nosuch.nt_helper/shared_prefs/

# Performance profiling
flutter run --profile
# Open DevTools and check Performance tab during drag operations
# Frame rendering should stay above 60fps
```

## Final Validation Checklist

### Technical Validation

- [ ] All 4 validation levels completed successfully
- [ ] No flutter analyze errors or warnings
- [ ] All existing tests still pass
- [ ] New service has comprehensive unit tests
- [ ] No performance degradation during drag operations

### Feature Validation

- [ ] Node positions persist when navigating between screens
- [ ] Node positions persist across app restarts
- [ ] Different presets maintain separate layouts
- [ ] Debouncing prevents excessive saves during drag
- [ ] Graceful handling of corrupted/missing data
- [ ] Algorithm reordering preserves positions where possible

### Code Quality Validation

- [ ] Follows existing SharedPreferences patterns from SettingsService
- [ ] Uses consistent key naming with underscore prefix
- [ ] Proper error handling with debugPrint logging
- [ ] No breaking changes to existing functionality
- [ ] Service properly initialized in main.dart

### Documentation & Deployment

- [ ] Code is self-documenting with clear method names
- [ ] Debug messages are informative but not verbose
- [ ] SharedPreferences keys are namespaced to avoid conflicts

---

## Anti-Patterns to Avoid

- ❌ Don't save on every drag event - use debouncing
- ❌ Don't store positions in app-level state if preset-specific
- ❌ Don't fail silently - log errors with debugPrint
- ❌ Don't assume SharedPreferences is always available - handle null
- ❌ Don't forget to convert int keys to strings for JSON
- ❌ Don't create new persistence patterns - follow SettingsService
- ❌ Don't skip the flutter analyze zero-tolerance requirement