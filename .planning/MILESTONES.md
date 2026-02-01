# Project Milestones: nt_helper

## v2.10 14-bit MIDI Detection (Shipped: 2026-02-01)

**Delivered:** Intelligent 14-bit MIDI CC auto-detection with byte order analysis and mapping editor auto-configuration

**Phases completed:** 1-3 (4 plans total)

**Key accomplishments:**
- Extended MidiEventType enum with cc14BitLowFirst/cc14BitHighFirst byte order variants
- Built MidiDetectionEngine with parallel 7-bit/14-bit CC detection and variance-based byte order analysis
- Integrated engine into MidiListenerCubit via delegation pattern (56% code reduction)
- Updated status messages to concise "14-bit CC X Ch Y" format
- Auto-configuration of mapping editor from 14-bit detection results
- 45 tests across 3 test files, zero analyze warnings throughout

**Stats:**
- 8 files created/modified
- 1,238 lines of Dart added
- 3 phases, 4 plans, 7 tasks
- 1 day from start to ship

**Git range:** `feat(01-01)` → `docs(v2.10)`

**What's next:** User acceptance testing with physical MIDI controllers, then potential v2 enhancements (value preview, NRPN detection)

---

## v2.9 — Pre-GSD

**Status:** Complete (shipped)
**Phases:** N/A (predates GSD tracking)

Everything through v2.9.0+187 was built before GSD milestone tracking.

Validated capabilities: MIDI device connection, preset management, algorithm loading, parameter control, mapping editor, 7-bit CC detection, note detection, routing visualization, SD card scanning, demo/offline modes, Lua reload, hardware commands, CPU monitoring.
