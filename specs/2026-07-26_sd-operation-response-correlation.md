# SD Operation Response Correlation

**Date:** 2026-07-26

## Context

All Disting NT SD-card requests use SysEx message type `0x7A`. A successful
response contains both a status byte and the SD operation byte:

```text
[status = 0, operation, ...operation data]
```

An error response contains a non-zero status and a null-terminated message, but
does not contain an operation byte:

```text
[status != 0, ...error message, 0]
```

`RequestKey` currently correlates only the outer `0x7A` message type. A delayed
response from one SD operation can therefore complete a different operation's
typed future. During Gallery installation, a delayed directory-listing response
can be accepted by an upload waiter and parsed as `DirectoryListing`, producing
a runtime type error instead of an upload result.

## Required behavior

1. Every response-bearing SD request identifies its `SdCardOperation` in its
   `RequestKey`.
2. A successful `0x7A` response matches only a request for the operation encoded
   in the response.
3. A successful response for a different operation is left unmatched so the
   current request can continue waiting for its own response.
4. Because the wire protocol omits the operation from error responses, an SD
   error matches the one active SD request and completes it with a typed
   `SdCardOperationException`.
5. SD response parsing selects a directory listing or file download only after
   confirming a successful status. All other SD responses parse as status
   responses.
6. Response-bearing SD operations use one attempt and a ten-second timeout.
   The protocol has no request identifier, so automatic retries can create
   duplicate replies that cannot be distinguished from a later request.
7. Gallery download, artifact selection, install paths, public MIDI-manager
   interfaces, and the 512-byte upload chunk limit remain unchanged.

## Design

### `SdCardOperation`

Add one domain enum as the source of truth for the wire operation codes:

| Operation | Code |
|---|---:|
| directory listing | 1 |
| file download | 2 |
| file delete | 3 |
| file upload | 4 |
| file rename | 5 |
| remount | 6 |
| directory create | 7 |
| plug-in rescan | 8 |

The same enum is used by request encoders, response parsing, request keys, and
the MIDI manager. Unknown response operation codes remain unmatched.

### Request matching

Extend `RequestKey` with an optional `sdCardOperation`.

- For non-`0x7A` responses, existing matching is unchanged.
- For successful `0x7A` responses, the derived operation must equal the
  requested operation.
- For error `0x7A` responses, no operation can be derived. Such a response may
  match an active key that specifies any SD operation because the sequential
  scheduler guarantees there is only one active request.
- This is the strongest error correlation the wire format permits; an
  operation-less stale error cannot be distinguished from an error for the
  active request.
- Equality, hashing, strict stale-response matching, and diagnostics include
  the new discriminator.

### Error completion

Before normal response parsing, the scheduler recognizes an SD error payload
and completes the request with:

```dart
SdCardOperationException(
  operation: request.key.sdCardOperation!,
  message: decodedFirmwareMessage,
)
```

This prevents an `SdCardStatus` value from being passed to a completer expecting
`DirectoryListing` or `FileChunk`.

### MIDI-manager locality

Add one private `_sendSdRequest<T>` helper to `DistingMidiManager`. It owns:

- the outer response type `0x7A`;
- the operation-aware `RequestKey`;
- the ten-second timeout;
- the single-attempt retry policy;
- the response expectation.

Existing public methods keep their current signatures and return types. Plug-in
rescan remains fire-and-forget. Remount uses operation 6 and the real `0x7A`
outer response type instead of the virtual `respSdStatus` type.

## Critical files

| File | Change |
|---|---|
| `lib/domain/sd_card_operation.dart` | Operation codes and typed SD exception |
| `lib/domain/request_key.dart` | Operation-aware correlation |
| `lib/domain/disting_message_scheduler.dart` | Typed SD error completion |
| `lib/domain/sysex/response_factory.dart` | Status-first SD response selection |
| `lib/domain/sysex/requests/request_*.dart` | Use shared operation codes |
| `lib/domain/disting_midi_manager.dart` | Centralize SD scheduling policy |
| `test/domain/disting_midi_manager_sd_operation_test.dart` | Public manager regression for the Gallery upload sequence |
| `test/domain/disting_message_scheduler_test.dart` | Wire-level regressions |
| `test/domain/request_key_test.dart` | Focused key value/matching tests |
| `test/domain/sysex/responses/sd_status_response_test.dart` | SD parser selection tests |

## Test seam

The primary seam is the public `DistingMessageScheduler.sendRequest` interface:
tests inject real wire frames through the MIDI stream and assert the
caller-visible future result.

Regression coverage:

1. A directory-listing waiter ignores a file-upload ACK, then completes from a
   directory-listing response.
2. A file-upload waiter ignores a directory-listing response, then completes
   from an upload ACK.
3. An operation-less SD error completes a directory-listing waiter with
   `SdCardOperationException`, not a runtime generic type error.
4. `RequestKey` equality and strict matching include the operation.
5. `ResponseFactory` classifies successful operations 1 and 2 by operation, but
   classifies all error payloads as SD status responses.

## Acceptance

- Installing a Gallery C++ plug-in cannot fail because a directory-listing
  response completes an upload future.
- Wrong-operation successful SD responses do not consume the active waiter.
- Firmware SD errors retain their message and requested operation.
- Existing non-SD request correlation remains unchanged.
- Focused tests, `flutter analyze`, and the full `flutter test` suite pass.
