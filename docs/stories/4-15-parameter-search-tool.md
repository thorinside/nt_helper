# Story 4.15: Add Parameter Search Tool for Preset and Slot Level

**Status:** Done
**Priority:** High
**Epic:** Epic 4 - MCP Integration & Improvements
**Assignee:** TBD

---

## Summary

Add MCP tools to search for parameters by name across a preset or within a single slot. This enables users and LLMs to discover which slots contain a specific parameter and understand the full impact of specification-dependent parameter duplication (e.g., finding all instances of "Divisor" across all channels).

**Problem It Solves:**
- User asks: "Which slots have a 'Speed' parameter?"
- Current solution: Manual inspection of each slot via `getCurrentPreset()`
- Proposed solution: `searchParametersByName()` returns all slots with that parameter
- Bonus: Shows all duplicated parameters for spec-dependent algorithms (all "1:Divisor", "2:Divisor", etc. in Clock Divider)

---

## Acceptance Criteria

1. **AC-1:** Enhanced `search()` tool accepts `target` and `scope` parameters
   - **Parameter:** `target` (string): What to search for - `"algorithm"` (existing) or `"parameter"` (new)
   - **Parameters for parameter search:**
     - `query` (string, required): Parameter name to search for (case-insensitive)
     - `scope` (string, required): `"preset"` or `"slot"`
     - `slot_index` (int, required if `scope: "slot"`): Which slot to search in
     - `partial_match` (boolean, optional, default false): If true, find parameters containing the query

2. **AC-2:** `search(target: "parameter", scope: "preset", ...)`
   - **Returns:**
     ```json
     {
       "target": "parameter",
       "scope": "preset",
       "query": "Speed",
       "partial_match": false,
       "total_matches": 3,
       "results": [
         {
           "slot_index": 0,
           "algorithm_name": "LFO",
           "algorithm_guid": "lfo ",
           "matches": [
             {
               "parameter_number": 7,
               "parameter_name": "1:Speed",
               "min": 0,
               "max": 16383,
               "value": 8605
             }
           ]
         },
         {
           "slot_index": 2,
           "algorithm_name": "LFO",
           "algorithm_guid": "lfo ",
           "matches": [
             {
               "parameter_number": 24,
               "parameter_name": "2:Speed",
               "min": 0,
               "max": 16383,
               "value": 8605
             },
             {
               "parameter_number": 41,
               "parameter_name": "3:Speed",
               "min": 0,
               "max": 16383,
               "value": 8605
             }
           ]
         }
       ]
     }
     ```

3. **AC-3:** `search(target: "parameter", scope: "slot", slot_index: 2, ...)`
   - **Returns:**
     ```json
     {
       "target": "parameter",
       "scope": "slot",
       "slot_index": 2,
       "algorithm_name": "Clock Divider",
       "algorithm_guid": "clkd",
       "query": "Divisor",
       "partial_match": false,
       "total_matches": 24,
       "matches": [
         {
           "parameter_number": 3,
           "parameter_name": "1:Divisor",
           "min": 1,
           "max": 32,
           "value": 2
         },
         {
           "parameter_number": 4,
           "parameter_name": "1:Divisor",
           "min": 0,
           "max": 5,
           "value": 1
         },
         {
           "parameter_number": 5,
           "parameter_name": "1:Divisor",
           "min": 0,
           "max": 9,
           "value": 1
         },
         {
           "parameter_number": 14,
           "parameter_name": "2:Divisor",
           "min": 1,
           "max": 32,
           "value": 2
         }
       ]
     }
     ```

4. **AC-4:** Partial matching works correctly
   - Search for "Speed" returns "Speed" but not "Multiplier"
   - Search for "Div" with `partial_match: true` returns "Divisor", "Divide", etc.
   - Case-insensitive: "speed" matches "1:Speed", "2:Speed"

5. **AC-5:** Handle edge cases
   - Empty results return `"total_matches": 0, "matches": []`
   - Invalid slot index returns helpful error
   - Missing required parameters returns helpful error
   - Invalid search_scope returns error

6. **AC-6:** Specification-dependent parameters are all shown
   - Clock Divider with 8 channels shows all "1:Divisor", "2:Divisor", ... "8:Divisor" matches
   - Not just the first occurrence (unlike `setParameterValue` which matches first)
   - Helps LLM understand the full scope of a parameter across channels

7. **AC-7:** All tests pass, zero warnings, no regressions
   - Unit tests for exact and partial matching
   - Test with specification-dependent algorithms (Clock Divider, LFO)
   - Test edge cases (empty results, invalid slots)
   - Integration tests with real preset data

---

## Technical Details

### Implementation Location

**File:** `lib/mcp/tools/disting_tools.dart`

**Enhanced Method:**
```dart
Future<String> search(Map<String, dynamic> params) async {
  final String? target = params['target'] as String?;

  // Existing algorithm search logic...
  if (target == 'algorithm') {
    return searchAlgorithms(params);
  }

  if (target == 'parameter') {
    // New parameter search implementation
    final String? query = params['query'] as String?;
    final String? scope = params['scope'] as String?;
    final int? slotIndex = params['slot_index'] as int?;
    final bool partialMatch = params['partial_match'] as bool? ?? false;

    // Validate inputs
    // Call appropriate helper based on scope
    if (scope == 'preset') {
      return _searchParametersInPreset(query!, partialMatch);
    } else if (scope == 'slot') {
      return _searchParametersInSlot(slotIndex!, query!, partialMatch);
    }
  }
}

Future<String> _searchParametersInPreset(
  String query,
  bool partialMatch,
) async {
  // Get all slots via controller
  // For each slot with parameters:
  //   - Find matches (exact or partial)
  //   - Add to results with slot and algorithm info
  // Return aggregated results with search metadata
}

Future<String> _searchParametersInSlot(
  int slotIndex,
  String query,
  bool partialMatch,
) async {
  // Validate slot_index
  // Get parameters for slot
  // Find all matches (exact or partial)
  // Return results with slot and algorithm info
}

// Helper method for reusable matching logic
List<ParameterInfo> _findMatchingParameters(
  List<ParameterInfo> parameters,
  String searchQuery,
  bool partialMatch,
) {
  return parameters.where((p) {
    if (partialMatch) {
      return p.name.toLowerCase().contains(searchQuery.toLowerCase());
    } else {
      return p.name.toLowerCase() == searchQuery.toLowerCase();
    }
  }).toList();
}
```

### Response Format

Returns structured JSON with:
- Search metadata (target, scope, query, partial_match flag)
- Slot/algorithm context (for preset-level search)
- Match count and list of all matches
- For each match: parameter number, name, value, min, max

### Example Workflow

**Scenario:** User wants to find all parameters named "Type" across the preset

1. User calls `search(target: "parameter", scope: "preset", query: "Type")`
2. Tool returns:
   ```json
   {
     "target": "parameter",
     "scope": "preset",
     "query": "Type",
     "partial_match": false,
     "results": [
       {
         "slot_index": 0,
         "algorithm_name": "Euclidean",
         "matches": [{"parameter_number": 2, "parameter_name": "1:Type", ...}]
       },
       {
         "slot_index": 2,
         "algorithm_name": "Clock Divider",
         "matches": [
           {"parameter_number": 2, "parameter_name": "1:Type", ...},
           {"parameter_number": 13, "parameter_name": "2:Type", ...},
           // ... channels 3-8
         ]
       }
     ]
   }
   ```
3. User sees that Euclidean in slot 0 has "Type" and Clock Divider in slot 2 has per-channel "Type" parameters
4. User can now make informed decisions about parameter editing

---

## Testing Plan

1. **Exact Match Tests:**
   - Search for "Speed" finds all "1:Speed", "2:Speed", etc. in LFO
   - Search for "Type" finds algorithm-specific Type parameters
   - Case-insensitive search works

2. **Partial Match Tests:**
   - Search for "Div" with partial_match=true finds "Divisor", "Divide" (if it exists)
   - Search for "1:" with partial_match=true finds all Channel 1 parameters

3. **Edge Cases:**
   - Search for non-existent parameter returns empty results
   - Invalid slot index returns error
   - Missing parameter_name returns error

4. **Specification-Dependent Tests:**
   - Clock Divider with 8 channels returns all 8 channels' parameters for "Divisor"
   - LFO with 4 channels returns all 4 channels' parameters for "Speed"

5. **Integration Tests:**
   - Real preset with mixed algorithms (some spec-dependent, some not)
   - Verify correct scoping and count

---

## Files to Modify

- `lib/mcp/tools/disting_tools.dart` - Add search methods and helper
- `test/services/disting_tools_test.dart` - Add comprehensive tests

---

## Story Dependencies

- Story 4.14 (Specification Passing) - prerequisite, ensures spec-dependent parameters return full list
- Story 4.12 (Parameter Numbering) - ensures parameter_number is accurate
- This story (4.15) - enables parameter search functionality

---

## User Value

- **LLM-Friendly:** Discover parameters without parsing full preset
- **Debugging:** Understand which slots have conflicting parameters
- **Specification Awareness:** See all duplicated parameters from specification variants
- **Discovery:** Find parameters by partial name matching
