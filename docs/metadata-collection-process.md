# Metadata Collection Process

## Overview

This document describes the process for collecting all factory algorithm metadata from Disting NT hardware and generating an updated bundled metadata file with I/O flags support.

## Prerequisites

1. **Hardware:** Disting NT with latest firmware that supports I/O flags in SysEx 0x43 responses
2. **Connection:** Stable MIDI connection to hardware
3. **Time:** Allocate 1-2 hours for complete metadata collection
4. **Mode:** Run app in debug mode (metadata export is debug-only)

## Process Steps

### Step 1: Connect to Hardware

1. Launch nt_helper application
2. Connect to Disting NT via MIDI
3. Verify connection is stable and firmware version supports I/O flags
4. Check connection status in app UI

### Step 2: Sync All Algorithm Metadata

1. Navigate to **Offline Data** screen (Settings → Offline Data or equivalent)
2. Tap **Sync All Algorithms** button
3. Monitor progress dialog:
   - Shows progress bar (0-100%)
   - Shows current algorithm being processed
   - Displays total algorithms processed / total
4. Wait for completion (approximately 30-60 minutes)
5. Verify all algorithms synced successfully
6. Check for any errors in the sync log

**Important:** Do not disconnect hardware or close app during sync.

### Step 3: Verify Metadata Collection

1. After sync completes, check database has I/O flags:
   - Open any algorithm parameter details
   - Verify I/O flag data is present
2. Check algorithm count matches expected factory algorithms (~100)
3. Spot-check known algorithms for correct I/O flags

### Step 4: Export Full Metadata

1. On **Offline Data** screen, tap **Export Metadata** button (debug-only, three-dot menu)
2. **Debug Metadata Export Dialog** opens showing:
   - Export preview with table counts
   - Estimated file size
3. Tap **Choose Save Location**
4. Select save location (e.g., Desktop/full_metadata_v2.json)
5. Tap **Export Full Metadata**
6. Wait for export to complete
7. Note the file path for next step

**Export includes:**
- All algorithms (with GUIDs, names, specifications)
- All parameters (with I/O flags, min/max, defaults, units)
- All parameter enums
- All parameter pages
- All units

### Step 5: Validate Exported Metadata

1. Open exported JSON file in text editor
2. Verify JSON structure:
   - `exportVersion: 2` (indicates I/O flags present)
   - `exportType: "full_metadata"`
   - `exportDate` is current
3. Check `summary` section for expected counts
4. Spot-check parameters have `ioFlags` field:
   ```json
   {
     "algorithmGuid": "clck",
     "parameterNumber": 0,
     "name": "Clock",
     "minValue": 0,
     "maxValue": 1000,
     "defaultValue": 120,
     "unitId": 532,
     "powerOfTen": 0,
     "rawUnitIndex": 11,
     "ioFlags": 4
   }
   ```
5. Verify file size is reasonable (~4-5MB, similar to old version)

### Step 6: Backup Current Bundled Metadata

1. Navigate to project root: `/Users/nealsanche/nosuch/nt_helper/`
2. Backup current bundled file:
   ```bash
   cp assets/metadata/full_metadata.json assets/metadata/full_metadata_v1_backup.json
   ```
3. Verify backup created successfully

### Step 7: Replace Bundled Metadata

1. Copy exported file to bundle location:
   ```bash
   cp /path/to/exported/full_metadata_v2.json assets/metadata/full_metadata.json
   ```
2. Verify file replaced successfully
3. Check file size and modification date

### Step 8: Test New Bundled Metadata

1. Delete app database to force fresh import:
   - On macOS: `rm ~/Library/Containers/com.example.nt_helper/Data/Library/Application\ Support/nt_helper/database.sqlite`
   - Or use app's "Clear All Data" debug option
2. Restart app
3. Verify metadata imports successfully on first launch
4. Check offline mode has I/O flags for all parameters
5. Test routing editor visualization uses I/O flags
6. Verify no errors in console logs

### Step 9: Run Tests

1. Run full test suite:
   ```bash
   flutter test
   ```
2. Verify all tests pass
3. Check for any warnings related to metadata

### Step 10: Update Documentation

1. Update story file with completion notes
2. Update sprint status to mark story as done
3. Add changelog entry about metadata bundle update
4. Document export date and firmware version used

## Verification Checklist

Before committing the new bundled metadata:

- [ ] JSON is valid (validated with JSON validator)
- [ ] Export version is 2
- [ ] All factory algorithms present (count ~100)
- [ ] All parameters have ioFlags field
- [ ] Flag values are in valid range (0-15 or null)
- [ ] File size is reasonable (~4-5MB)
- [ ] Fresh install loads successfully
- [ ] Offline mode shows I/O flags
- [ ] No database errors
- [ ] Routing editor works with I/O flags
- [ ] All tests pass
- [ ] flutter analyze passes

## Rollback Procedure

If new metadata causes issues:

1. Restore backup:
   ```bash
   cp assets/metadata/full_metadata_v1_backup.json assets/metadata/full_metadata.json
   ```
2. Rebuild app
3. Test to verify rollback successful

## Known Algorithms to Spot-Check

These algorithms should have specific I/O flags:

- **clck (Clock):** Clock parameter should have `isInput = true` (ioFlags & 4 = 4)
- **pycv (Poly CV):** Gate outputs should have `isOutput = true` (ioFlags & 8 = 8)
- **eucl (Euclidean):** Output mode parameters should have `isOutputMode = true` (ioFlags & 2 = 2)
- **AA algorithms (Audio processing):** Should have `isAudio = true` for audio I/O (ioFlags & 1 = 1)

## Troubleshooting

### Sync fails partway through
- Restart device and app
- Resume sync (if supported) or start fresh
- Check MIDI connection stability

### Export dialog not available
- Verify app is running in debug mode
- Check `kDebugMode` is true
- Rebuild in debug configuration

### Exported file missing ioFlags
- Verify firmware supports I/O flags
- Re-sync metadata from hardware
- Check parameter info responses include I/O flags

### Fresh install fails to load metadata
- Check JSON is valid
- Verify file path in pubspec.yaml
- Check import service logs for errors

## File Locations

- **Current bundled metadata:** `assets/metadata/full_metadata.json`
- **Backup location:** `assets/metadata/full_metadata_v1_backup.json`
- **Export service:** `lib/services/algorithm_json_exporter.dart`
- **Import service:** `lib/services/metadata_import_service.dart`
- **Sync service:** `lib/services/metadata_sync_service.dart`
- **Export dialog:** `lib/ui/widgets/debug_metadata_export_dialog.dart`

## Related Stories

- **Story 7.3** - Adds I/O flags to ParameterInfo (runtime)
- **Story 7.7** - Adds I/O flags to database schema and JSON import/export
- **Story 7.8** - This story (metadata collection and bundle update)

## Metadata Export Format (v2)

```json
{
  "exportDate": "2025-11-18T...",
  "exportVersion": 2,
  "exportType": "full_metadata",
  "debugExport": true,
  "tables": {
    "units": [...],
    "algorithms": [...],
    "specifications": [...],
    "parameters": [
      {
        "algorithmGuid": "...",
        "parameterNumber": 0,
        "name": "...",
        "minValue": 0,
        "maxValue": 100,
        "defaultValue": 50,
        "unitId": 521,
        "powerOfTen": 0,
        "rawUnitIndex": 1,
        "ioFlags": 8  // NEW IN V2
      }
    ],
    "parameterEnums": [...],
    "parameterPages": [...],
    "parameterPageItems": [...],
    "metadataCache": [...]
  },
  "summary": {
    "totalAlgorithms": 100,
    "totalParameters": 2500,
    ...
  }
}
```

## Success Criteria

This story is complete when:

1. All factory algorithm metadata collected from hardware with I/O flags
2. Exported metadata file generated successfully (v2 format)
3. Bundled metadata replaced in assets/
4. Fresh install loads new metadata successfully
5. Offline mode has I/O flags for all parameters
6. All tests pass
7. Documentation updated
8. Story marked as done in sprint status
