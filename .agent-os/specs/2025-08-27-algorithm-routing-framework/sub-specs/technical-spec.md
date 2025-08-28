# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-27-algorithm-routing-framework/spec.md

> Created: 2025-08-27
> Version: 1.0.0

## Technical Requirements

### Core Architecture

#### AlgorithmRouting Base Class
- **Location**: `lib/domain/routing/algorithm_routing.dart`
- **Type**: Abstract base class
- **Pattern**: Simple abstract base class with virtual methods for subclass implementation
- **State Management**: Immutable state with Freezed data classes
- **Error Handling**: Simple nullable returns or boolean validation results

```dart
abstract class AlgorithmRouting {
  // Abstract methods for subclass implementation
  List<Port> generateInputPorts(Algorithm algorithm);
  List<Port> generateOutputPorts(Algorithm algorithm);
  bool validateConnection(String sourcePortId, String targetPortId);
  RoutingValidationResult validateRoutingState(List<Connection> connections);
  
  // Common methods with default behavior (can be overridden)
  RoutingState createInitialState(Algorithm algorithm);
  RoutingState addConnection(RoutingState state, Connection connection);
  RoutingState removeConnection(RoutingState state, String connectionId);
  
  // Serialization support
  Map<String, dynamic> toJson(RoutingState state);
  RoutingState fromJson(Map<String, dynamic> json, Algorithm algorithm);
}
```

#### Concrete Routing Implementations
- **PolyAlgorithmRouting**: Polyphonic routing with gate input and virtual CV ports based on algorithm properties
- **MultiChannelAlgorithmRouting**: Width-based routing with configurable channel count (default: 1 for normal algorithms, N for width-based algorithms)

#### State Management Integration
- **Pattern**: BLoC/Cubit pattern consistent with existing codebase
- **State Classes**: Immutable Freezed data classes for type safety
- **Events**: Command pattern for routing operations
- **Persistence**: JSON serialization for preset storage

### Flutter/Dart Specific Implementation

#### Type Safety
```dart
// Sealed classes for exhaustive pattern matching
@freezed
sealed class RoutingType with _$RoutingType {
  const factory RoutingType.normal() = NormalRoutingType;
  const factory RoutingType.poly(int maxVoices) = PolyRoutingType;
  const factory RoutingType.multiChannel(List<ChannelConfig> channels) = MultiChannelRoutingType;
}

// Port validation with custom types
enum PortCompatibility { compatible, incompatible, requiresConversion }

// Routing result types
@freezed 
sealed class RoutingResult<T> with _$RoutingResult<T> {
  const factory RoutingResult.success(T data) = RoutingSuccess<T>;
  const factory RoutingResult.failure(RoutingError error) = RoutingFailure<T>;
}
```

#### Dependency Injection
- **Pattern**: get_it service locator for routing factory registration
- **Registration**: Algorithm-specific routing type mapping
- **Lifecycle**: Singleton routing services with proper disposal

#### Memory Management
- **Streams**: Proper StreamSubscription management with disposal
- **State Retention**: WeakReference for algorithm-routing associations
- **Connection Pooling**: Reuse of port validation objects

### State Management Patterns

#### RoutingEditorCubit Enhancement
```dart
class RoutingEditorCubit extends Cubit<RoutingEditorState> {
  final Map<int, AlgorithmRouting> _routingInstances = {};
  final RoutingFactory _routingFactory;
  
  // Enhanced state processing with routing framework
  void _processSynchronizedState(List<Slot> slots) {
    final algorithms = <RoutingAlgorithm>[];
    final connections = <Connection>[];
    
    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final routing = _routingFactory.createRouting(slot.algorithm);
      _routingInstances[i] = routing;
      
      final routingState = routing.createInitialState(slot.algorithm);
      final inputPorts = routing.generateInputPorts(slot.algorithm);
      final outputPorts = routing.generateOutputPorts(slot.algorithm);
      
      algorithms.add(RoutingAlgorithm(
        index: i,
        algorithm: slot.algorithm,
        inputPorts: inputPorts,
        outputPorts: outputPorts,
        routingType: routing.routingType,
      ));
      
      connections.addAll(routingState.connections);
    }
    
    emit(RoutingEditorState.loaded(/*...*/));
  }
}
```

#### Connection Management
- **Validation Pipeline**: Multi-stage validation with early failure detection
- **Conflict Resolution**: Algorithm-specific conflict handling strategies
- **Change Notifications**: Stream-based updates for UI reactivity


### Integration Requirements

#### Algorithm Integration
```dart
// Extended Algorithm model with routing metadata
class Algorithm {
  final int algorithmIndex;
  final String guid;
  final String name;
  final RoutingType supportedRoutingType; // NEW
  final List<PortDefinition> portDefinitions; // NEW
}

// Port definition metadata
class PortDefinition {
  final String id;
  final String name;
  final PortType type;
  final PortDirection direction;
  final bool isRequired;
  final List<String> compatiblePortTypes;
}
```


#### Preset System Integration
```dart
// Enhanced preset model with routing state
class PresetData {
  final String name;
  final List<Slot> slots;
  final Map<int, RoutingState> routingStates; // NEW - per algorithm routing state
  final List<Connection> globalConnections; // NEW - cross-algorithm connections
}
```


### Error Handling Strategy

- **Simple Error Handling**: Return nullable types or Result objects for validation operations
- **State Consistency**: Ensure routing state remains valid after any operation

### Testing Strategy Integration

#### Unit Testing
- **Mock Routing**: Injectable mock routing implementations for testing
- **State Verification**: Comprehensive state transition testing
- **Performance Testing**: Automated performance regression detection

#### Integration Testing
- **End-to-End**: Complete routing workflow testing with mock hardware
- **Persistence Testing**: Routing state save/load verification
- **UI Integration**: Widget testing with routing state changes

### Code Generation Requirements

#### Freezed Integration
- **State Classes**: All routing state classes use Freezed for immutability
- **Union Types**: Sealed classes for routing types and results
- **JSON Serialization**: Automatic JSON codec generation

#### Build Runner Configuration
```yaml
# pubspec.yaml additions
dev_dependencies:
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_annotation: ^4.8.1
  json_serializable: ^6.7.1
```

## Approach

### Implementation Phases

#### Phase 1: Core Framework (Week 1-2)
1. **Base Class Design**: Create abstract AlgorithmRouting with template methods
2. **State Models**: Define Freezed state classes and data structures
3. **Validation Framework**: Implement port compatibility and connection validation
4. **Unit Tests**: Comprehensive test suite for core framework

#### Phase 2: Concrete Implementations (Week 3-4)  
1. **PolyAlgorithmRouting**: Polyphonic routing with gate + virtual CV ports implementation
2. **MultiChannelAlgorithmRouting**: Width-based routing implementation (handles both normal width=1 and multi-width scenarios)
3. **Integration Tests**: Cross-implementation compatibility testing

#### Phase 3: State Management Integration (Week 5-6)
1. **Cubit Enhancement**: Extend RoutingEditorCubit with routing framework
2. **Factory Pattern**: Implement routing factory with DI registration
3. **Performance Optimization**: Optimize state updates and memory usage
4. **UI Integration**: Update UI components to consume new routing API

#### Phase 4: Persistence & MIDI Integration (Week 7-8)
1. **Database Schema**: Update database tables for routing state persistence
2. **JSON Serialization**: Implement robust save/load for routing configurations
3. **MIDI Translation**: Build abstraction layer for MIDI message generation
4. **End-to-End Testing**: Complete workflow testing with hardware simulation

### Migration Strategy

#### Backward Compatibility
- **Existing Code**: Current routing logic remains functional during migration
- **Gradual Adoption**: New framework can be enabled per-algorithm basis
- **Rollback Plan**: Feature flag allows reverting to legacy routing

#### Data Migration
- **Preset Conversion**: Automatic migration of existing presets to new format
- **State Translation**: Legacy routing data converted to new state format
- **Validation**: Migration validation ensures no data loss

### Risk Mitigation

- **Testing**: Comprehensive unit tests for all routing implementations
- **API Stability**: Simple, consistent interface across all routing types  
- **Compatibility**: Maintain backward compatibility with existing routing data

## External Dependencies

### Flutter Framework Dependencies
- **Flutter SDK**: 3.19.0+ (stable channel)
- **Dart SDK**: 3.3.0+ (null safety and pattern matching)

### Required Packages
```yaml
dependencies:
  # State Management
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
  
  # Immutable State
  freezed: ^2.4.6
  freezed_annotation: ^2.4.1
  
  # JSON Serialization  
  json_annotation: ^4.8.1
  json_serializable: ^6.7.1
  
  # Dependency Injection
  get_it: ^7.6.4
  injectable: ^2.3.2
  
  # Database
  drift: ^2.14.1
  
  # Utilities
  collection: ^1.17.2
  meta: ^1.10.0

dev_dependencies:
  # Code Generation
  build_runner: ^2.4.7  
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  injectable_generator: ^2.4.1
  
  # Testing
  mockito: ^5.4.2
  build_runner: ^2.4.7
```

### Development Tools
- **IDE Support**: IntelliJ IDEA or VS Code with Dart/Flutter plugins
- **Code Analysis**: flutter_lints for consistent code style
- **Testing**: Built-in Flutter test framework with mockito for mocking

### Hardware Requirements
- **Development**: Physical Disting NT module for integration testing
- **CI/CD**: Mock MIDI interface for automated testing
- **Performance Testing**: Various hardware configurations for performance validation

### API Compatibility
- **MIDI Standards**: Compliance with MIDI 1.0 and SysEx specifications
- **Expert Sleepers**: Compatibility with Disting NT SysEx protocol
- **Future Proofing**: Extensible design for potential MIDI 2.0 support