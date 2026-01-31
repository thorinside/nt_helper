# Technical Decisions

## 2026-01-11 - Implementation Decisions

### Decision 1: Use Completer for First Frame Signal
**Context**: Need to know when first frame actually arrives, not just when stream is "declared" streaming.

**Options Considered**:
1. Add new VideoStreamState variant (e.g., `.ready`)
2. Use Completer<void> internally
3. Use StreamController for first-frame events

**Decision**: Option 2 - Completer<void>

**Rationale**:
- Guardrail: Must NOT change VideoStreamState enum (high blast radius)
- Completer is simple, one-shot signal (perfect for "first frame")
- No additional stream overhead
- Easy to reset on disconnect

### Decision 2: Reactive Pattern with Immediate Check
**Context**: stateStream.listen() only gets future states, misses current state.

**Options Considered**:
1. Keep polling with shorter interval
2. Subscribe to stream only
3. Check current state + subscribe to future

**Decision**: Option 3 - Hybrid approach

**Rationale**:
- Eliminates polling entirely (per user requirement)
- Handles both "already streaming" and "will stream" cases
- No timing assumptions
- Reactive pattern as requested

### Decision 3: Connection Guard Flag
**Context**: Async handler called synchronously allows duplicate connections.

**Options Considered**:
1. Make handler synchronous (can't - needs await)
2. Cancel previous attempt when new one starts
3. Guard flag to prevent duplicates

**Decision**: Option 3 - Boolean guard

**Rationale**:
- Simplest solution
- Prevents race without cancellation complexity
- Clear intent in code
- No risk of canceling legitimate connection

### Decision 4: Retry on Null VideoManager
**Context**: videoManager created async, but connection attempt is immediate.

**Options Considered**:
1. Make startVideoStream() awaitable
2. Retry with delay
3. Subscribe to cubit state for videoManager creation

**Decision**: Option 2 - Retry with 100ms delay

**Rationale**:
- Minimal change to existing flow
- Matches existing 100ms delay pattern in codebase
- Simple to understand and maintain
- Avoids coupling to cubit internals
