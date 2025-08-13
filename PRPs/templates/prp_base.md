name: "Flutter NT Helper PRP Template - Feature Implementation with Test Requirements"
description: |
  Template for implementing features in the NT Helper Flutter application with emphasis on
  MIDI SysEx communication, state management, and cross-platform compatibility.

---

## Goal

**Feature Goal**: [Specific, measurable end state of what needs to be built for the NT Helper app]

**Deliverable**: [Concrete artifact - new UI screen, service, cubit, MIDI handler, database feature, etc.]

**Success Definition**: [How you'll know this is complete and working, including test coverage]

## User Persona (if applicable)

**Target User**: [Disting NT users, musicians, sound designers, etc.]

**Use Case**: [Primary scenario - preset editing, algorithm management, parameter mapping, etc.]

**User Journey**: [Step-by-step flow of how user interacts with this feature]

**Pain Points Addressed**: [Specific user frustrations with Disting NT management this feature solves]

## Why

- [Value for Disting NT users and workflow improvements]
- [Integration with existing NT Helper features]
- [Problems this solves for hardware control and preset management]

## What

[User-visible behavior and technical requirements specific to Disting NT control]

### Success Criteria

- [ ] Feature works across all platforms (Windows, macOS, Linux, iOS, Android)
- [ ] MIDI SysEx communication tested with mock and real hardware
- [ ] State management properly handled via Cubit pattern
- [ ] Unit tests achieve minimum 80% coverage
- [ ] `flutter analyze` shows zero errors/warnings
- [ ] [Additional specific measurable outcomes]

## All Needed Context

### Context Completeness Check

_Before writing this PRP, validate: "If someone knew nothing about this codebase, would they have everything needed to implement this successfully?"_

### Documentation & References

```yaml
# MUST READ - Include these in your context window
- file: CLAUDE.md
  why: Core codebase concepts and architecture patterns
  critical: Cubit state management, MIDI interface design, debugging standards

- file: lib/cubit/disting_cubit.dart
  why: Main state management pattern for all features
  pattern: Cubit pattern with proper state transitions
  gotcha: Always use debugPrint(), never print()

- file: lib/domain/i_disting_midi_manager.dart
  why: MIDI communication interface all features must use
  pattern: Interface-based design with mock/offline/live implementations
  
- file: lib/db/database.dart
  why: Drift ORM patterns for data persistence
  pattern: DAO pattern for database operations

- file: [specific existing feature file for pattern reference]
  why: [Pattern to follow for similar feature implementation]
  pattern: [Brief description of what pattern to extract]
```

### Current Codebase tree (run `tree` in the root of the project) to get an overview of the codebase

```bash

```

### Desired Codebase tree with files to be added and responsibility of file

```bash

```

### Known Gotchas of our codebase & Library Quirks

```dart
// CRITICAL: Always use debugPrint() instead of print() for logging
// CRITICAL: Zero tolerance for flutter analyze errors - must pass before commit
// CRITICAL: MIDI operations require proper error handling for disconnection scenarios
// CRITICAL: Cubit states must be immutable - use copyWith() pattern
// CRITICAL: Database migrations must be backward compatible
// CRITICAL: Feature branches required, PR approval needed before merge
// CRITICAL: Mock MIDI manager for unit tests using mockito
// CRITICAL: Generate mocks with: flutter pub run build_runner build
```

## Implementation Blueprint

### Data models and structure

Create the core data models with type safety and null safety.

```dart
Examples:
 - Domain models in lib/models/ (e.g., Algorithm, ParameterInfo, PresetData)
 - Database entities with Drift ORM in lib/db/
 - State classes for Cubit in lib/cubit/
 - SysEx request/response classes in lib/domain/sysex/
 - Freezed data classes for immutability (if applicable)
```

### Implementation Tasks (ordered by dependencies)

```yaml
Task 1: CREATE lib/models/{feature}_model.dart
  - IMPLEMENT: Domain models with proper null safety and immutability
  - FOLLOW pattern: lib/models/algorithm_specification.dart (class structure)
  - NAMING: CamelCase for classes, camelCase for properties
  - PLACEMENT: Domain models in lib/models/

Task 2: CREATE/MODIFY lib/db/daos/{feature}_dao.dart (if database needed)
  - IMPLEMENT: DAO with Drift ORM for data persistence
  - FOLLOW pattern: lib/db/daos/presets_dao.dart (DAO structure)
  - NAMING: {Feature}Dao class with standard CRUD methods
  - DEPENDENCIES: Import models from Task 1
  - PLACEMENT: Database layer in lib/db/daos/

Task 3: CREATE lib/services/{feature}_service.dart
  - IMPLEMENT: Service class for business logic
  - FOLLOW pattern: lib/services/[existing_similar_service].dart (service structure)
  - NAMING: {Feature}Service class with descriptive methods
  - DEPENDENCIES: Import models and DAOs from previous tasks
  - PLACEMENT: Service layer in lib/services/

Task 4: CREATE/MODIFY lib/cubit/{feature}_cubit.dart and {feature}_state.dart
  - IMPLEMENT: Cubit for state management with immutable states
  - FOLLOW pattern: lib/cubit/disting_cubit.dart (Cubit pattern)
  - NAMING: {Feature}Cubit and {Feature}State classes
  - DEPENDENCIES: Import services from Task 3
  - PLACEMENT: State management in lib/cubit/

Task 5: CREATE lib/ui/{feature}/{feature}_screen.dart (if UI needed)
  - IMPLEMENT: Flutter UI screen/widget with proper state management
  - FOLLOW pattern: lib/ui/synchronized_screen.dart (UI structure)
  - NAMING: {Feature}Screen or {Feature}Widget
  - DEPENDENCIES: Use BlocBuilder/BlocListener for Cubit
  - PLACEMENT: UI layer in lib/ui/

Task 6: CREATE test/{feature}_test.dart
  - IMPLEMENT: Unit tests using flutter_test and mockito
  - FOLLOW pattern: test/enum_parameter_test.dart (test structure)
  - GENERATE MOCKS: Use @GenerateMocks annotation
  - COVERAGE: Test all public methods, edge cases, error handling
  - NAMING: test_{method}_{scenario} function naming
  - PLACEMENT: Tests in test/ directory

Task 7: MODIFY lib/services/mcp_server_service.dart (if MCP integration needed)
  - INTEGRATE: Add new MCP tool methods
  - FOLLOW pattern: Existing tool implementations
  - NAMING: Descriptive tool function names
  - DEPENDENCIES: Import feature service
  - PRESERVE: Existing tool registrations
```

### Implementation Patterns & Key Details

```dart
// Show critical patterns and gotchas - keep concise, focus on non-obvious details

// Example: Service method pattern
class FeatureService {
  final Database _database;
  final DistingController _controller;
  
  Future<Result> performOperation({required OperationParams params}) async {
    try {
      // PATTERN: Input validation first
      _validateParams(params);
      
      // PATTERN: MIDI operations with error handling
      final response = await _controller.sendRequest(request);
      
      // GOTCHA: Always handle disconnection scenarios
      if (response == null) {
        throw MidiDisconnectedException();
      }
      
      // PATTERN: Update database if needed
      await _database.transaction(() async {
        // Batch operations here
      });
      
      return Result.success(data: response);
    } catch (e) {
      debugPrint('Operation failed: $e');
      return Result.error(message: e.toString());
    }
  }
}

// Example: Cubit pattern with immutable state
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit() : super(const FeatureState.initial());
  
  Future<void> performAction() async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final result = await _service.performOperation();
      emit(state.copyWith(
        isLoading: false,
        data: result,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
}

// Example: Test pattern with mockito
@GenerateMocks([DistingController, Database])
void main() {
  group('Feature Tests', () {
    late MockDistingController mockController;
    late FeatureService service;
    
    setUp(() {
      mockController = MockDistingController();
      service = FeatureService(controller: mockController);
    });
    
    test('should handle successful operation', () async {
      when(mockController.sendRequest(any))
          .thenAnswer((_) async => expectedResponse);
      
      final result = await service.performOperation(params);
      
      expect(result.isSuccess, true);
      verify(mockController.sendRequest(any)).called(1);
    });
  });
}
```

### Integration Points

```yaml
DATABASE:
  - migration: "Add to lib/db/migrations.dart if schema changes needed"
  - dao: "Create new DAO in lib/db/daos/ for data persistence"
  - drift: "Run build_runner after schema changes: flutter pub run build_runner build"

STATE:
  - cubit: "Register in main app providers if new Cubit created"
  - pattern: "BlocProvider<FeatureCubit>(create: (_) => FeatureCubit())"

UI:
  - navigation: "Add route to Navigator if new screen"
  - widgets: "Place reusable widgets in lib/ui/widgets/"

MIDI:
  - sysex: "Create request/response classes in lib/domain/sysex/"
  - interface: "Implement through i_disting_midi_manager.dart"

MCP:
  - tools: "Register in lib/services/mcp_server_service.dart"
  - pattern: "Add tool method following existing patterns"
```

## Validation Loop

### Level 1: Syntax & Style (Immediate Feedback)

```bash
# Run after each file creation - fix before proceeding
flutter analyze                      # Static analysis - MUST have zero errors/warnings

# Auto-format code
dart format lib/{new_files}.dart     # Format specific files
dart format lib/                     # Format all library code
dart format test/                    # Format all test code

# Expected: Zero errors. If errors exist, READ output and fix before proceeding.
# This is CRITICAL - the project has zero tolerance for analyze errors
```

### Level 2: Unit Tests (Component Validation)

```bash
# Generate mocks for testing (run after creating new mockable classes)
flutter pub run build_runner build --delete-conflicting-outputs

# Test specific feature
flutter test test/{feature}_test.dart

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# View coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
# xdg-open coverage/html/index.html  # Linux
# start coverage/html/index.html  # Windows

# Expected: All tests pass with minimum 80% coverage for new code
# If failing, debug root cause and fix implementation
```

### Level 3: Integration Testing (System Validation)

```bash
# Build and run the application (choose platform)
flutter run -d macos      # macOS
flutter run -d windows    # Windows
flutter run -d linux      # Linux
flutter run -d chrome     # Web browser
flutter run               # Default device

# Test MIDI connectivity (requires hardware or virtual MIDI)
# 1. Connect Disting NT via USB
# 2. Launch app and verify MIDI ports appear
# 3. Test connection and basic operations

# Test database operations
# Verify database is created and migrations run
sqlite3 ~/.nt_helper/nt_helper.db ".tables"

# Test MCP server (desktop platforms only)
# 1. Launch app with MCP server enabled
# 2. Test connection with MCP client
# Example: npx @modelcontextprotocol/inspector

# Platform-specific testing
flutter build apk          # Android APK
flutter build ios          # iOS (requires Xcode)
flutter build macos        # macOS app
flutter build windows      # Windows exe
flutter build linux        # Linux executable

# Expected: App launches, connects to MIDI, database works, MCP server responds
```

### Level 4: Creative & Domain-Specific Validation

```bash
# MIDI SysEx Testing (Disting NT specific)
# Test with mock MIDI manager in demo mode
# Verify SysEx request/response handling
# Check parameter value updates reflect in UI

# Performance Profiling
flutter run --profile
# Use Flutter DevTools for performance analysis
flutter pub global activate devtools
flutter pub global run devtools

# Memory leak detection
# Monitor memory usage during extended operation
# Check for proper disposal of controllers and streams

# Cross-platform validation
# Test on minimum supported versions:
# - iOS 12.0+
# - Android API 21+
# - macOS 10.14+
# - Windows 10+
# - Linux (Ubuntu 20.04+)

# Accessibility testing
flutter test --update-goldens  # Update golden files for widget tests

# Real hardware testing (if available)
# 1. Connect actual Disting NT module
# 2. Test all MIDI operations
# 3. Verify preset load/save
# 4. Test parameter mappings (CV, MIDI, I2C)
# 5. Verify algorithm loading and management

# Expected: All platform-specific features work, MIDI communication stable
```

## Final Validation Checklist

### Technical Validation

- [ ] All 4 validation levels completed successfully
- [ ] All tests pass: `flutter test`
- [ ] No analysis errors: `flutter analyze` (ZERO tolerance)
- [ ] Code properly formatted: `dart format lib/ test/ --set-exit-if-changed`
- [ ] Mocks generated successfully: `flutter pub run build_runner build`
- [ ] Minimum 80% test coverage for new code

### Feature Validation

- [ ] All success criteria from "What" section met
- [ ] Works on all target platforms (Windows, macOS, Linux, iOS, Android)
- [ ] MIDI communication tested with mock and (if available) real hardware
- [ ] Error cases handled gracefully with proper error messages
- [ ] Integration points work as specified
- [ ] User persona requirements satisfied (if applicable)

### Code Quality Validation

- [ ] Follows existing codebase patterns and naming conventions
- [ ] File placement matches project structure (lib/, test/, etc.)
- [ ] Anti-patterns avoided (check against Anti-Patterns section)
- [ ] Dependencies properly managed in pubspec.yaml
- [ ] Cubit state management properly implemented

### Documentation & Deployment

- [ ] Code is self-documenting with clear variable/function names
- [ ] debugPrint() used for logging (never print())
- [ ] Unit tests document expected behavior
- [ ] Feature branch created and PR ready for review

---

## Anti-Patterns to Avoid

- ❌ Don't use print() - always use debugPrint()
- ❌ Don't create new patterns when existing ones work
- ❌ Don't skip flutter analyze - must have zero errors
- ❌ Don't ignore failing tests - fix them
- ❌ Don't mutate Cubit states - use copyWith()
- ❌ Don't hardcode values that should be configurable
- ❌ Don't catch all exceptions - be specific
- ❌ Don't skip unit tests for new features
- ❌ Don't commit without running flutter analyze
