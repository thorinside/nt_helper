# Local conversation picker evidence

Actual Flutter widget renders using `ConversationPicker` and the shipped
`AppTheme`, with illustrative conversation metadata. These are not full-app,
physical-device or assistive-technology acceptance captures.

- `desktop-light.png`, `desktop-dark.png`: 920 × 760 viewport, standard text.
- `compact-dark.png`: 320 × 480 viewport, compact controls and scrolling.
- `compact-large-type.png`: 320 × 480 viewport, 200% text scaling.

Two bounded inspection rounds were used. The first exposed a crowded enlarged
header; the correction gives compact layouts a short title and a full-width
storage caption. Functional checks also caught and fixed a wrapping menu label
and retry callback. No decorative animation/assets/dependencies were added.

Reproduce explicitly from the migration worktree:

```sh
CAPTURE_CHAT_PICKER=1 flutter test --no-pub --concurrency=1 \
  test/chat/ui/conversation_picker_test.dart
```

Capture is skipped by default. SFNS and Material Icons are loaded only for this
opt-in render when available on the development Mac; assertions do not rely on
those fonts. No provider calls, NT gestures or app builds are part of these tests.
