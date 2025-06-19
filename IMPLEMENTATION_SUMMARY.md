# Disting NT SysEx Protocol - Missing Messages Implementation

## Overview
This document summarizes the implementation of the previously missing message types from the Expert Sleepers Disting NT SysEx Protocol specification.

## Implemented Missing Messages

### 1. Execute Lua (0x08)
**File**: `lib/domain/sysex/requests/execute_lua.dart`

**Purpose**: Executes Lua script text on the module and receives output via Lua Output response.

**Request Format**: 
```
F0 00 21 27 6D <ID> 08 <Lua script text> F7
```

**Implementation Details**:
- Takes a Lua script string as input
- Converts script to UTF-8 bytes
- Script text is not null-terminated (F7 indicates message end)
- Module responds with 0x09 Lua Output message if script produces output

### 2. Install Lua (0x09)
**File**: `lib/domain/sysex/requests/install_lua.dart`

**Purpose**: Installs Lua code in a specific algorithm slot for rapid iteration.

**Request Format**: 
```
F0 00 21 27 6D <ID> 09 <algorithm index> <Lua script text> F7
```

**Implementation Details**:
- Takes algorithm index (7-bit) and Lua script string
- Algorithm index specifies which Lua Script algorithm slot to use
- Script is installed to memory (not saved to SD card) for testing
- Module responds with 0x09 Lua Output message if script produces output

### 3. Set Parameter String (0x53)
**File**: `lib/domain/sysex/requests/set_parameter_string.dart`

**Purpose**: Sets string-type parameters (text fields, filenames, etc.) on the module.

**Request Format**: 
```
F0 00 21 27 6D <ID> 53 <algorithm index> <parameter number> <string value> 00 F7
```

**Implementation Details**:
- Takes algorithm index, parameter number, and string value
- Uses 16-bit encoding for algorithm index and parameter number
- String value is null-terminated ASCII text
- Used for parameters that accept text input rather than numeric values

### 4. Lua Output Response (0x09)
**File**: `lib/domain/sysex/responses/lua_output_response.dart`

**Purpose**: Receives text output from Lua script execution.

**Response Format**: 
```
F0 00 21 27 6D <ID> 09 <output text> F7
```

**Implementation Details**:
- Parses ASCII text output from Lua scripts
- Text ends when SysEx message ends (no null terminator before F7)
- Used as response for both Execute Lua and Install Lua operations

## Updated Components

### Response Factory
**File**: `lib/domain/sysex/response_factory.dart`
- Added import for `LuaOutputResponse`
- Added case for `DistingNTRespMessageType.respLuaOutput`

### Message Type Enums
**File**: `lib/domain/disting_nt_sysex.dart`
- Added `executeLua(0x08)` to request message types
- Added `installLua(0x09)` to request message types  
- Added `setParameterString(0x53)` to request message types
- Added `respLuaOutput(0x09)` to response message types

### Higher-Level Interface
**Files**: 
- `lib/domain/i_disting_midi_manager.dart` (Interface)
- `lib/domain/disting_midi_manager.dart` (Real implementation)
- `lib/domain/mock_disting_midi_manager.dart` (Mock implementation)
- `lib/domain/offline_disting_midi_manager.dart` (Offline implementation)

**Added Methods**:
- `Future<void> setParameterString(int algorithmIndex, int parameterNumber, String value)`
- `Future<String?> executeLua(String luaScript)`
- `Future<String?> installLua(int algorithmIndex, String luaScript)`

**Implementation Notes**:
- Real implementation uses proper SysEx message scheduling and expects optional Lua output responses
- Mock implementation returns simulated responses for testing
- Offline implementation throws `UnsupportedError` for Lua operations (requires real hardware)

## Test Coverage
**File**: `test/sysex_decode_test.dart`
- Added encoding tests for Execute Lua messages
- Added encoding tests for Install Lua messages  
- Added encoding tests for Set Parameter String messages
- Added decoding tests for Lua Output responses
- All tests pass successfully

## Protocol Compliance
The implementation is now **100% compliant** with the Expert Sleepers Disting NT SysEx Protocol specification. All documented message types are implemented with proper encoding/decoding, message scheduling, and error handling.

## Usage Examples

### Execute Lua Script
```dart
final output = await midiManager.executeLua('print("Hello World")');
// output: "Hello World" (if script produces output)
```

### Install Lua in Algorithm Slot
```dart
final output = await midiManager.installLua(2, 'x = 42; print(x)');
// Installs script in algorithm slot 2, output: "42" (if script produces output)
```

### Set Parameter String Value
```dart
await midiManager.setParameterString(1, 3, "filename.wav");
// Sets parameter 3 of algorithm 1 to "filename.wav"
``` 