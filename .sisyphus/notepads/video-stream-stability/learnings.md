# Video Stream Stability - Learnings

## 2026-01-11 - Implementation Session

### Issues Discovered

1. **Completer Timing Race**: `_firstFrameCompleter` was initialized AFTER 100ms delay, but frames could arrive during that delay. Fixed by moving initialization before delay.

2. **State Stream Race**: `stateStream.listen()` only receives FUTURE state changes. If already streaming when widget initializes, connection never happens. Fixed by checking `currentState` immediately.

3. **VideoManager Null Race**: `videoManager` is created async by `startVideoStream()`, but `_connectVideoFrameCubitReactive()` runs immediately. Fixed by adding retry loop with 100ms delay.

4. **Duplicate Connection Attempts**: `handleStreamingState()` is async but called synchronously, allowing multiple simultaneous connection attempts. Fixed by adding `_isConnecting` flag.

5. **UI Rendering Race**: `displayFrame` updated via async callback, so first frame never displayed. Widget checked `displayFrame` which was null, showing "Waiting..." even though frames arrived. Fixed by using `frameData` directly instead of waiting for `displayFrame`.

### Patterns Applied

- **Completer Pattern**: Used `Completer<void>` to signal first frame arrival
- **Reactive Subscription**: Replaced polling with `stateStream.listen()`
- **Immediate State Check**: Check current state + subscribe to future changes
- **Connection Guard**: Boolean flag to prevent duplicate async operations
- **Direct Frame Rendering**: Use state data directly instead of async callbacks

### Code Changes

**Files Modified**:
- `lib/domain/video/usb_video_manager.dart` - Added first-frame callback
- `lib/ui/widgets/floating_video_overlay.dart` - Reactive connection + UI fix

**Commits**:
- `5f0b22d` - Add first-frame callback to UsbVideoManager
- `33a50e6` - Replace polling with reactive stream connection (includes 4 race fixes)
- `[new]` - Use frameData directly instead of async displayFrame

### Key Insight

The original bug was actually TWO separate issues:
1. **Connection race conditions** (4 separate races) - Fixed in Tasks 1 & 2
2. **UI rendering race** - Frames arrived but weren't displayed due to async callback timing

Both needed to be fixed for video to work.
