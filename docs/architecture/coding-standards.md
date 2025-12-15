# Coding Standards

## Code Quality Requirements

**Zero Tolerance Policy**:
- `flutter analyze` MUST pass with zero warnings/errors before commit
- Fix all analyzer issues immediately
- No exceptions

**Linter**: Uses `package:flutter_lints/flutter.yaml`

## Debugging

**CRITICAL**: Always use `debugPrint()`, never `print()`

**Rationale**: `debugPrint()` throttles output and is stripped in release builds

**Example**:
```dart
debugPrint('[RoutingEditor] Processing ${slots.length} slots');
```

## State Management Patterns

**Cubit Pattern** (throughout app):
- Use `flutter_bloc` package
- States defined with `freezed`
- State variants as union types
- Emit new states, never mutate

**Example**:
```dart
@freezed
class MyState with _$MyState {
  const factory MyState.initial() = Initial;
  const factory MyState.loading() = Loading;
  const factory MyState.loaded(Data data) = Loaded;
  const factory MyState.error(String message) = Error;
}

class MyCubit extends Cubit<MyState> {
  MyCubit() : super(const MyState.initial());

  Future<void> loadData() async {
    emit(const MyState.loading());
    try {
      final data = await fetchData();
      emit(MyState.loaded(data));
    } catch (e) {
      emit(MyState.error(e.toString()));
    }
  }
}
```

## Async Patterns

**Use async/await**, not `.then()`:
```dart
// Good
Future<void> doSomething() async {
  final result = await someAsyncOperation();
  processResult(result);
}

// Bad
Future<void> doSomething() {
  return someAsyncOperation().then((result) {
    processResult(result);
  });
}
```

**Stream subscriptions** must be cancelled:
```dart
StreamSubscription? _subscription;

void listen() {
  _subscription = stream.listen((event) {
    // Handle event
  });
}

@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

## Error Handling

**Specific exceptions** over generic:
```dart
// Good
throw StateError('Disting not synchronized');
throw ArgumentError.value(slotIndex, 'slotIndex', 'Invalid slot');

// Bad
throw Exception('Something went wrong');
```

**Null safety**:
- Use `?` for nullable types
- Use `!` only when absolutely certain
- Prefer null checks over force unwrap

## File Organization

**One class per file** (generally)

**File naming**: `snake_case.dart`

**Import ordering**:
1. Dart SDK imports
2. Flutter imports
3. Package imports
4. Local imports

**Example**:
```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';

import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/slot.dart';
```

## Cubit Delegate Pattern

Some Cubits (especially `DistingCubit`) are intentionally decomposed using a delegate + forwarding pattern to keep files maintainable without changing public APIs.

**Pattern**:
- Keep the public Cubit API on the Cubit class (forwarding methods are fine).
- Extract cohesive responsibilities into a private delegate class (e.g. `_PluginDelegate`).
- Implement delegates as `part` files using `part of 'disting_cubit.dart';` so they can access private state safely.

**Do**:
- Prefer delegates for code that needs access to private fields, timers, or multiple helpers.
- Add a `dispose()` method on delegates that own timers/subscriptions and call it from `DistingCubit.close()`.
- Use `DistingCubit._emitState(...)` from delegates instead of calling `emit(...)` directly (because `emit` is protected and should only be called from the Cubit itself).
- Keep extraction cohesive: one delegate per concern (connection, plugin management, parameter fetch/retry, parameter refresh/polling).

**Don’t**:
- Don’t expand the Cubit surface area just to satisfy a mixin (prefer delegates when this happens).
- Don’t introduce debug logging as part of refactors.
- Don’t change behavior while extracting unless explicitly requested.
