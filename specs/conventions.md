# Conventions for all decision-free spec steps (Flutter / Dart)

Read this once per step. Every plan assumes these rules; plans only state what
differs from them.

## Golden rules

1. **Follow the spec's widget trees, labels, and signatures exactly.** Do not
   rename, reword UI strings, reorder parameters, or "improve" anything. If a
   change feels like an improvement, it is out of scope.
2. **Touch only the files the step names.** Never edit generated files
   (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) by hand.
3. **Preserve `const`.** Never add or remove `const` on constructors you move
   or copy; add `const` on new widget constructors only where the analyzer's
   `prefer_const_constructors` lint asks for it.
4. **One step, one commit**, with the exact commit message the step provides.
5. **Never do work from another step**, even when it looks convenient. Each
   step's verification must run against exactly that step's changes.
6. **Accessibility is part of the spec, not decoration.** Every `Semantics`
   wrapper, `semanticLabel`, `liveRegion`, `header: true`, and tooltip named in
   a spec's widget tree is mandatory.
7. **No debug logging. No success snackbars unless the spec names one.**
   Snackbars are for errors/failures only, with the exact message the spec gives.

## Import paths

All imports use the package prefix, never relative paths:

| Need | Import |
|---|---|
| Anything in `lib/` | `import 'package:nt_helper/<path under lib>/<file>.dart';` |
| Cubit base | `import 'package:bloc/bloc.dart';` |
| BlocProvider/BlocBuilder | `import 'package:flutter_bloc/flutter_bloc.dart';` |
| Path manipulation | `import 'package:path/path.dart' as p;` |
| File picking | `import 'package:file_picker/file_picker.dart';` |

## Widget conventions in this repo

- Private widgets in the same file are named `_PascalCase` and take all data via
  constructor parameters.
- Cubits are accessed with `context.read<T>()` for actions and
  `BlocBuilder`/`context.select` for rebuilds; widgets never hold cubit state.
- StatefulWidget + State pairs stay in the same file and move together.
- Screens pushed with `Navigator.push(context, MaterialPageRoute(builder: ...))`
  receive their cubits either by constructor parameter or `BlocProvider.value`.

## Verification (every step, in this order)

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/poly_multisample lib/poly_multisample test/poly_multisample test/ui
flutter analyze          # MUST print "No issues found!". Any issue = step not done.
flutter test <the test files the step names>   # MUST all pass
git add -A && git status --short               # only files the step names may appear
```

If the step names no test files, run
`flutter test test/poly_multisample test/ui/synchronized_screen_bottom_bar_test.dart`.

## Recovery rule (mechanical)

`flutter analyze` errors name exactly what is missing:

- "Undefined name 'X'" / "URI doesn't exist" → add the missing import (see the
  import table above).
- "The named parameter 'X' isn't defined" → the spec's interface table has the
  authoritative parameter list; re-check the spelling against it.
- A test failure whose expectation text matches the spec → your widget tree or
  label differs from the spec; fix the widget, never the test, unless the step
  explicitly says to update that test.

First failure: apply the rule above, re-verify. Second failure on the same
step: run `git checkout -- lib test`, report `FAILED` with the full error
text, and stop. Never improvise around a failing step.
