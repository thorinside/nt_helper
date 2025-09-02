# Algorithm Routing Framework - Lite Summary

OOP abstraction layer for managing MIDI routing patterns in Disting NT with base `AlgorithmRouting` class and two specialized routing implementations (`PolyAlgorithmRouting`, `MultiChannelAlgorithmRouting`).

## Key Points
- Replaces procedural routing logic with clean, extensible OOP architecture
- Provides unified API for different routing patterns with type-safe operations
- Separates routing concerns from UI rendering and state management
- Includes connection management, validation, serialization, and change notifications
- Integrates with algorithms, UI canvas, MIDI layer, and preset system
- Maintains backward compatibility while enabling future routing pattern extensions