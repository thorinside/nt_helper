# Commit History

## All Commits for Video Stream Stability Fix

### Commit 1: `5f0b22d`
**Message**: fix(video): add first-frame callback to UsbVideoManager
**Files**: `lib/domain/video/usb_video_manager.dart`
**Changes**: +13 lines
**Purpose**: Add Completer-based signal for when first frame actually arrives

### Commit 2: `33a50e6`
**Message**: fix(video): replace polling with reactive stream connection
**Files**: 
- `lib/domain/video/usb_video_manager.dart`
- `lib/ui/widgets/floating_video_overlay.dart`
**Changes**: +60 lines, -23 lines
**Purpose**: Replace 500ms polling with reactive subscription, fix 4 race conditions

### Commit 3: `fe3ecee`
**Message**: fix(video): use frameData directly instead of async displayFrame
**Files**: `lib/ui/widgets/floating_video_overlay.dart`
**Changes**: +4 lines, -4 lines
**Purpose**: Fix UI rendering race - use frameData immediately instead of waiting for async callback

## Total Changes
- Files modified: 2
- Lines added: 77
- Lines removed: 27
- Net change: +50 lines

## Verification
- ✅ All commits pass `flutter analyze`
- ✅ All guardrails respected
- ⏸️ Manual testing pending
