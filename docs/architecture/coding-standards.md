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
- Prefer adding to an existing delegate/mixin over creating a new one, if the responsibility is the same.
- Add a `dispose()` method on delegates that own timers/subscriptions and call it from `DistingCubit.close()`.
- Use `DistingCubit._emitState(...)` from delegates instead of calling `emit(...)` directly (because `emit` is protected and should only be called from the Cubit itself).
- Keep extraction cohesive: one delegate per concern (connection, plugin management, parameter fetch/retry, parameter refresh/polling).

**Don’t**:
- Don’t expand the Cubit surface area just to satisfy a mixin (prefer delegates when this happens).
- Don’t introduce debug logging as part of refactors.
- Don’t change behavior while extracting unless explicitly requested.

### Where New Code Should Go (Avoid Re-refactoring)

When adding features to the app, treat `lib/cubit/disting_cubit.dart` as a facade:
- Public Cubit API and simple forwarding methods live on `DistingCubit`.
- Real behavior belongs in a delegate/mixin.

**Prefer an ops mixin** (`*_ops.dart`) when:
- It’s a user-facing “command” (preset/slot/algorithm operations).
- It reads/writes state but doesn’t need its own timers/subscriptions/lifecycle.

**Prefer a delegate** (`*_delegate.dart`) when:
- The code needs timers, stream subscriptions, retry queues, or background polling.
- The code needs access to multiple private helpers/fields.
- The code is a cohesive subsystem (connection, monitoring, SD card, plugins, mappings, etc).

**Checklist for adding a new delegate**
1. Create `lib/cubit/disting_cubit_<topic>_delegate.dart` with `part of 'disting_cubit.dart';`.
2. Add a `part 'disting_cubit_<topic>_delegate.dart';` entry to `lib/cubit/disting_cubit.dart`.
3. Add a `late final _<Topic>Delegate _<topic>Delegate = _<Topic>Delegate(this);` field.
4. Add (or update) forwarding methods on `DistingCubit` to call into the delegate.
5. If the delegate owns resources, add `dispose()` and call it from `DistingCubit.close()`.

**Keep delegates cohesive**
- Avoid “misc” delegates; if it doesn’t fit, it probably indicates a missing domain boundary.
- If a new method fits an existing delegate (same responsibility), add it there.
