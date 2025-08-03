# PRP: Plugin Version Tracking and Update Notifications

## Feature Overview
Implement plugin version tracking to highlight when newer versions are available in the plugin gallery, making it easier for users to keep their plugins up-to-date.

## Current State Analysis

### Existing Infrastructure
1. **Database Schema (v5)**:
   - `PluginInstallations` table exists with version tracking columns
   - Unused in current implementation (gallery_service.dart:366-384 commented out)
   - Complete DAO with version query methods ready

2. **Gallery Integration**:
   - Fetches plugin metadata with version channels (latest/stable/beta)
   - No comparison with installed versions
   - No update detection mechanism

3. **Missing Components**:
   - pub_semver dependency not included
   - No version comparison utilities
   - No UI indicators for updates
   - Database tracking commented out

## Technical Approach

### 1. Database Migration (Schema v5 → v6)

**Reference**: `/Users/nealsanche/nosuch/nt_helper/PRPs/ai_docs/drift_migration_reference.md`

Add columns to `PluginInstallations` table:
- `availableVersion` (text, nullable) - Latest version from gallery
- `updateAvailable` (text, default 'false') - Update flag
- `lastChecked` (datetime, nullable) - Last update check timestamp

Migration implementation in `lib/db/database.dart`:
```dart
@override
int get schemaVersion => 6; // Increment from 5

// In migration strategy
if (from <= 5) {
  try {
    debugPrint("Adding version tracking columns to plugin_installations table...");
    await m.addColumn(pluginInstallations, pluginInstallations.availableVersion);
    await m.addColumn(pluginInstallations, pluginInstallations.updateAvailable);
    await m.addColumn(pluginInstallations, pluginInstallations.lastChecked);
    debugPrint("Migration successful: Added version tracking columns.");
  } catch (e) {
    debugPrint("Migration error adding version tracking: $e");
  }
}
```

### 2. Version Comparison Service

**Reference**: `/Users/nealsanche/nosuch/nt_helper/PRPs/ai_docs/semver_implementation_guide.md`

Create `lib/services/version_comparison_service.dart`:
- Parse and compare semantic versions using pub_semver
- Handle GitHub tag formats (v-prefix)
- Fallback for non-semver versions (date-based, custom)
- Determine best available version from channels

### 3. Plugin Update Checker

Create `lib/services/plugin_update_checker.dart`:
- Check installed plugins against gallery versions
- Update database with available versions
- Batch update checks with rate limiting
- Cache results for 1 hour minimum

### 4. Gallery Service Enhancement

Modify `lib/services/gallery_service.dart`:
- Uncomment database tracking (lines 366-384, 395-412)
- Add update check on gallery fetch
- Integrate version comparison
- Update installation records

### 5. UI Enhancements

#### Gallery Screen (`lib/ui/gallery_screen.dart`)
- Add update badge to plugin cards
- Show "Update Available" indicator
- Display version info (installed vs available)
- Quick update action button

#### Plugin Details Dialog
- Show version comparison details
- Changelog link to GitHub releases
- Version selection with update path

### 6. Cubit State Management

Update `lib/cubit/disting_cubit.dart`:
- Add update check trigger
- Emit states for update availability
- Handle batch update operations

## Implementation Blueprint

### Phase 1: Database & Core Services
```bash
# 1. Add pub_semver dependency
# 2. Implement database migration (v6)
# 3. Create version_comparison_service.dart
# 4. Create plugin_update_checker.dart
# 5. Run migration tests
```

### Phase 2: Gallery Integration
```bash
# 1. Uncomment database tracking in gallery_service
# 2. Add update checking logic
# 3. Integrate with plugin installation flow
# 4. Test with mock gallery data
```

### Phase 3: UI Implementation
```bash
# 1. Design update indicators (badges, colors)
# 2. Modify plugin card widgets
# 3. Add version info to details dialog
# 4. Implement update actions
# 5. Test UI responsiveness
```

## Key Implementation Files

### Core Files to Modify:
1. `pubspec.yaml` - Add pub_semver: ^2.1.4
2. `lib/db/tables.dart` - Add version tracking columns
3. `lib/db/database.dart` - Implement migration v6
4. `lib/services/gallery_service.dart` - Enable DB tracking
5. `lib/ui/gallery_screen.dart` - Add update indicators

### New Files to Create:
1. `lib/services/version_comparison_service.dart`
2. `lib/services/plugin_update_checker.dart`
3. `test/services/version_comparison_test.dart`
4. `test/db/migration_v6_test.dart`

## Error Handling Strategy

1. **Version Parsing Failures**: Fallback to string comparison
2. **Network Failures**: Use cached version data
3. **Migration Failures**: Continue with degraded functionality
4. **Rate Limiting**: Respect gallery API limits

## Testing Strategy

### Unit Tests:
- Version comparison edge cases
- Migration rollback scenarios
- Update detection logic
- Cache expiration

### Integration Tests:
- Gallery fetch with update checks
- Database migration paths
- UI update indicators

### Manual Tests:
- Install plugin, then check for updates
- Offline mode behavior
- Multiple version channel scenarios

## Validation Gates

```bash
# 1. Flutter Analysis
flutter analyze

# 2. Database Migration Test
flutter test test/db/migration_v6_test.dart

# 3. Version Comparison Tests
flutter test test/services/version_comparison_test.dart

# 4. Integration Tests
flutter test integration_test/plugin_update_test.dart

# 5. Build Verification
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## Implementation Tasks

1. **Setup Dependencies** [2h]
   - Add pub_semver to pubspec.yaml
   - Update dependencies

2. **Database Migration** [3h]
   - Add version tracking columns
   - Implement migration v6
   - Test migration paths

3. **Version Comparison Service** [4h]
   - Implement semver comparison
   - Handle edge cases
   - Add comprehensive tests

4. **Plugin Update Checker** [4h]
   - Create update detection logic
   - Integrate with gallery service
   - Add caching mechanism

5. **Gallery Service Updates** [3h]
   - Enable database tracking
   - Add update checks
   - Test installation flow

6. **UI Implementation** [6h]
   - Design update indicators
   - Modify plugin cards
   - Add version details
   - Implement update actions

7. **Testing & Validation** [4h]
   - Write unit tests
   - Create integration tests
   - Manual testing
   - Bug fixes

**Total Estimated Time**: 26 hours

## Success Criteria

1. Users can see which plugins have updates available
2. Version comparison works for semver and custom formats
3. Database migration completes without data loss
4. Update checks don't impact performance
5. UI clearly indicates update availability
6. All validation gates pass

## Additional Resources

- Semantic Versioning: https://semver.org/
- pub_semver package: https://pub.dev/packages/pub_semver
- Drift Migrations: https://drift.simonbinder.eu/docs/advanced-features/migrations/
- Flutter Testing: https://docs.flutter.dev/testing

## Notes

- The PluginInstallations table infrastructure already exists but is commented out
- Consider implementing background update checks in future iteration
- Rate limit gallery API calls to avoid overwhelming the server
- Consider adding "Auto-update" feature in future version

**Confidence Score: 8/10**

The existing database structure and commented code provide a solid foundation. The main complexity lies in handling various version formats and ensuring smooth UI integration. The phased approach minimizes risk while delivering value incrementally.