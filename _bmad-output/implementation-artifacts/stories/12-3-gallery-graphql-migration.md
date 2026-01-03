# Story 12.3: Migrate Gallery Service to GraphQL API

Status: Done

## Story

As the NT Helper app,
I want to fetch plugin gallery data from the GraphQL API instead of the REST endpoint,
So that I get accurate real-time data including `isCollection` and `guid` fields without caching delays.

## Epic Context

This story is part of Epic 12 focused on UX improvements. The Plugin Gallery currently uses a REST endpoint (`/api/gallery.json`) that has aggressive caching and data synchronization issues. The GraphQL API used by the web frontend provides accurate, real-time data.

- **Goal**: Use the same data source as the web frontend for consistency
- **Value**: Accurate `isCollection` display, proper `guid` values, reduced data staleness
- **Constraints**: Must maintain backward compatibility with existing gallery features
- **Reference**: Web frontend queries at `nt_gallery/frontend/src/lib/graphql/queries.ts`

## Background

### Current Implementation

The `GalleryService` (`lib/services/gallery_service.dart`) fetches from:
```
https://nt-gallery.nosuch.dev/api/gallery.json
```

This REST endpoint:
- Has 1-hour Redis cache TTL
- Returns stale cached data even after server updates
- Requires server-side cache invalidation for updates
- Uses a custom JSON schema transformation

### How isCollection is Determined

For C++ plugins, `is_collection` is computed during plugin detection/publishing:
- The server downloads the release zip and extracts all `.o` files
- Each `.o` file is scanned for its 4-character GUID
- Multiple GUIDs → `is_collection: true`, `collection_guids: ["GUID1", "GUID2", ...]`
- Single GUID → `is_collection: false`, `guid: "GUID"`

For Lua/3pot plugins, `is_collection` defaults to `false` (no automatic detection).

This data is stored in the database at publish time. Both GraphQL and REST read from the same database - the REST endpoint just has caching issues.

### GraphQL Endpoint

The backend provides GraphQL at:
```
https://nt-gallery-backend.fly.dev/api/graphql
```

Query for plugins:
```graphql
query GetPlugins($filter: PluginFilterInput) {
  plugins(filter: $filter) {
    id
    slug
    name
    description
    pluginType
    categoryId
    authorId
    repositoryOwner
    repositoryName
    repositoryUrl
    installationPath
    minFirmwareVersion
    verified
    verificationStatus
    featured
    featuredAt
    featuredReason
    latestReleaseTag
    latestReleaseUrl
    latestReleaseDate
    guid
    isCollection
    collectionGuids
    selectedArtifactUrl
    selectedArtifactName
    createdAt
    updatedAt
    downloadCount
  }
}

query GetCategories {
  categories {
    id
    name
    sortOrder
  }
}
```

Filter options:
```graphql
input PluginFilterInput {
  verified: Boolean
  featured: Boolean
  categoryId: String
  pluginType: PluginType  # LUA, THREEPOT, CPP
  authorId: UUID
  searchQuery: String
}
```

## Acceptance Criteria

### GraphQL Integration (No New Dependencies)

1. Use existing `http` package - GraphQL is just JSON via POST
2. GraphQL endpoint URL configurable via `SettingsService` (default: `https://nt-gallery-backend.fly.dev/api/graphql`)
3. Send query as JSON body: `{"query": "{ plugins(...) { ... } }"}`
4. Parse response JSON: `response['data']['plugins']`
5. Handle network errors gracefully with appropriate exceptions

### Gallery Service Refactor

6. Refactor `fetchGallery()` to use GraphQL `plugins` query with `verified: true` filter
7. Fetch categories via separate `categories` query
8. Map GraphQL response to existing `Gallery`, `GalleryPlugin`, `PluginCategory` models
9. Preserve existing 1-hour client-side cache behavior (optional: reduce to 15 minutes since server cache is removed)
10. `isCollection` field populated correctly from GraphQL response
11. `guid` field populated correctly from GraphQL response
12. `collectionGuids` field added to model and populated (new field for future use)

### Model Updates

13. Add `collectionGuids` field to `GalleryPlugin` model: `@Default([]) List<String> collectionGuids`
14. Update `gallery_models.dart` with new field
15. Run `flutter pub run build_runner build` to regenerate freezed files
16. Update JSON schema `docs/plugin_gallery_schema.json` with `collectionGuids` array field

### Field Mapping

Map GraphQL fields to existing model fields:

| GraphQL Field | Model Field | Notes |
|---------------|-------------|-------|
| `slug` | `id` | Use slug as plugin ID |
| `name` | `name` | Direct map |
| `description` | `description` | Direct map |
| `description` | `longDescription` | Same as description (no separate field) |
| `pluginType` | `type` | Map LUA→lua, THREEPOT→threepot, CPP→cpp |
| `categoryId` | `category` | Direct map |
| `repositoryOwner` | `repository.owner` | Direct map |
| `repositoryName` | `repository.name` | Direct map |
| `repositoryUrl` | `repository.url` | Direct map |
| `installationPath` | `installation.targetPath` | Direct map |
| `selectedArtifactUrl` | `installation.downloadUrl` | Direct map |
| `latestReleaseTag` | `releases.latest` | Direct map |
| `minFirmwareVersion` | `compatibility.minFirmwareVersion` | Direct map |
| `featured` | `featured` | Direct map |
| `verified` | `verified` | Direct map |
| `isCollection` | `isCollection` | Direct map |
| `guid` | `guid` | Direct map |
| `collectionGuids` | `collectionGuids` | New field, direct map |
| `createdAt` | `createdAt` | Direct map |
| `updatedAt` | `updatedAt` | Direct map |
| `downloadCount` | `metrics.downloads` | Direct map |

### Authors Handling

17. Authors data not available in plugin query - derive from `authorId` or fetch separately if needed
18. For now, use repository owner as author identifier (existing behavior)
19. Author display name can be fetched on-demand if detailed author info is needed

### Backward Compatibility

20. Existing `searchPlugins()` method continues to work unchanged
21. Existing `addToQueue()` and installation flow unchanged
22. All existing tests pass
23. `flutter analyze` passes with zero warnings

### Error Handling

24. Network errors throw `GalleryException` with descriptive message
25. GraphQL errors (partial data) handled gracefully
26. Fallback to cached data on network failure (if cache exists)

### Local Cache Persistence

27. Persist gallery JSON to local storage (file or SharedPreferences)
28. On app launch, load from local cache first (instant display)
29. Background refresh from GraphQL if cache is stale (>24 hours or user-triggered)
30. Cache includes timestamp for staleness check
31. Reduces server load - gallery data changes infrequently

### GUID-Based Plugin Lookup

32. Build a GUID → GalleryPlugin lookup map from cached gallery data
33. Add `getPluginByGuid(String guid)` method to GalleryService
34. Method returns `GalleryPlugin?` - null if GUID not found in gallery
35. Lookup map rebuilt when gallery cache is refreshed
36. For C++ collections, also index by each GUID in `collectionGuids`

This enables the app to display rich metadata for community plugins when their GUID matches a gallery entry:
- Plugin name instead of raw GUID
- Author information
- Description
- Repository link
- Installation status (if also tracking installations)

## Tasks / Subtasks

- [x] Task 1: Update models (AC: 13-16)
  - [x] Add `@Default([]) List<String> collectionGuids` to `GalleryPlugin` in `gallery_models.dart`
  - [x] Run `flutter pub run build_runner build`
  - [x] Update `docs/plugin_gallery_schema.json` with collectionGuids field
  - [x] Verify generated files compile correctly

- [x] Task 2: Refactor fetchGallery (AC: 1-12, 17-19)
  - [x] Add `graphqlEndpoint` to SettingsService with default value
  - [x] Create `_fetchPluginsViaGraphQL()` private method
  - [x] Create `_fetchCategoriesViaGraphQL()` private method
  - [x] Create `_mapGraphQLToGallery()` to convert response to Gallery model
  - [x] Handle plugin type enum mapping (LUA/THREEPOT/CPP → lua/threepot/cpp)
  - [x] Derive author map from plugin data (use authorId or repositoryOwner)
  - [x] Update `fetchGallery()` to call GraphQL methods
  - [x] Preserve cache behavior with `_cachedGallery` and `_lastFetch`

- [x] Task 3: Implement local cache persistence (AC: 27-31)
  - [x] Create cache file path using `path_provider` (applicationDocumentsDirectory)
  - [x] Save gallery JSON + timestamp to `gallery_cache.json` after successful fetch
  - [x] Load from cache file on `fetchGallery()` if exists and not forcing refresh
  - [x] Add `_cacheTimestamp` field to track when cache was written
  - [x] Consider cache stale after 24 hours (configurable)
  - [x] Background refresh: return cached data immediately, fetch new data async

- [x] Task 4: Implement GUID lookup (AC: 32-36)
  - [x] Add `Map<String, GalleryPlugin> _guidLookup = {}` private field
  - [x] Create `_buildGuidLookup(Gallery gallery)` that populates map from:
    - Single plugins: `plugin.guid` → plugin
    - Collections: each GUID in `plugin.collectionGuids` → plugin
  - [x] Call `_buildGuidLookup()` after caching gallery in `fetchGallery()`
  - [x] Add public `GalleryPlugin? getPluginByGuid(String guid)` method
  - [x] Handle case-insensitive GUID matching (GUIDs are 4 chars, case matters but be lenient)

- [x] Task 5: Testing and validation (AC: 20-26)
  - [x] Verify `searchPlugins()` works with GraphQL data
  - [x] Verify `addToQueue()` works with GraphQL data
  - [x] Verify `getPluginByGuid()` returns correct plugin for known GUIDs
  - [x] Verify `getPluginByGuid()` returns null for unknown GUIDs
  - [x] Test network error handling
  - [x] Test cache fallback behavior
  - [x] Run `flutter analyze` - zero warnings
  - [x] Run existing gallery tests
  - [x] Manual test: verify isCollection shows correctly for airwindows
  - [x] Manual test: verify guid shows for C++ plugins

## Technical Notes

### GraphQL Query Example

```dart
const String getPluginsQuery = r'''
  query GetPlugins($filter: PluginFilterInput) {
    plugins(filter: $filter) {
      slug
      name
      description
      pluginType
      categoryId
      repositoryOwner
      repositoryName
      repositoryUrl
      installationPath
      minFirmwareVersion
      verified
      featured
      featuredReason
      latestReleaseTag
      latestReleaseUrl
      selectedArtifactUrl
      guid
      isCollection
      collectionGuids
      createdAt
      updatedAt
      downloadCount
    }
  }
''';

const String getCategoriesQuery = r'''
  query GetCategories {
    categories {
      id
      name
      sortOrder
    }
  }
''';
```

### Simple HTTP-based GraphQL Request

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<dynamic>> fetchPluginsViaGraphQL(String endpoint) async {
  final response = await http.post(
    Uri.parse(endpoint),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'query': getPluginsQuery}),
  );

  if (response.statusCode != 200) {
    throw GalleryException('GraphQL request failed: ${response.statusCode}');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;

  if (json.containsKey('errors')) {
    throw GalleryException('GraphQL error: ${json['errors']}');
  }

  return json['data']['plugins'] as List<dynamic>;
}
```

### Settings Service Addition

```dart
// In SettingsService
static const String _defaultGraphQLEndpoint =
    'https://nt-gallery-backend.fly.dev/api/graphql';

String get graphqlEndpoint =>
    _prefs?.getString('graphql_endpoint') ?? _defaultGraphQLEndpoint;
```

### GUID Lookup Implementation

```dart
// In GalleryService
Map<String, GalleryPlugin> _guidLookup = {};

void _buildGuidLookup(Gallery gallery) {
  _guidLookup.clear();
  for (final plugin in gallery.plugins) {
    // Index single plugins by their GUID
    if (plugin.guid != null && plugin.guid!.isNotEmpty) {
      _guidLookup[plugin.guid!] = plugin;
    }
    // Index collection plugins by each GUID in collectionGuids
    for (final guid in plugin.collectionGuids) {
      _guidLookup[guid] = plugin;
    }
  }
}

/// Look up a plugin by its 4-character GUID
/// Returns null if no matching plugin found in gallery
GalleryPlugin? getPluginByGuid(String guid) {
  return _guidLookup[guid];
}
```

### Usage Example - Enriching Community Plugin Display

```dart
// When displaying a community C++ plugin loaded from the device:
final devicePlugin = slot.algorithm; // Has GUID like "TidS"
final guid = devicePlugin.guid;

if (guid != null) {
  final galleryPlugin = galleryService.getPluginByGuid(guid);
  if (galleryPlugin != null) {
    // Display rich metadata from gallery
    Text(galleryPlugin.name); // "Tides Port" instead of "TidS"
    Text(galleryPlugin.description);
    Text('by ${galleryPlugin.author}');
  } else {
    // Fallback to device info only
    Text(devicePlugin.name);
  }
}
```

## Out of Scope

- User authentication for GraphQL (public endpoint only)
- Real-time subscriptions (future enhancement)
- Offline-first with local GraphQL cache persistence
- Author detail fetching (use existing authorId approach)

## Definition of Done

- [x] GraphQL client fetches plugins successfully
- [x] `isCollection: true` displays correctly for airwindows and expert-sleepers-examples
- [x] `guid` field populated for C++ plugins (e.g., "TidS" for Tides)
- [x] All existing gallery functionality works unchanged
- [x] `flutter analyze` passes with zero warnings
- [x] Story status updated to "done"

## File List

- lib/services/gallery_service.dart (modified)
- lib/services/settings_service.dart (modified)
- lib/models/gallery_models.dart (modified)
- lib/models/gallery_models.freezed.dart (regenerated)
- lib/models/gallery_models.g.dart (regenerated)
- docs/plugin_gallery_schema.json (modified)
- docs/sprint-artifacts/sprint-status.yaml (modified)
- test/services/gallery_service_guid_lookup_test.dart (new)

## Change Log

- 2025-12-13: Implemented GraphQL API integration for gallery service, replacing REST endpoint
- 2025-12-13: Added collectionGuids field to GalleryPlugin model
- 2025-12-13: Implemented multi-tier caching (memory + file-based with 24hr stale threshold)
- 2025-12-13: Added GUID lookup functionality with getPluginByGuid() method
- 2025-12-13: Added graphqlEndpoint setting to SettingsService
- 2025-12-13: Created unit tests for GUID lookup and model serialization
- 2025-12-13: [Review] Fixed missing graphqlEndpoint in resetToDefaults()
- 2025-12-13: [Review] Added @visibleForTesting initializeGuidLookup() for proper unit testing
- 2025-12-13: [Review] Added 3 new integration tests for GUID lookup functionality
- 2025-12-13: [Review] Staged previously untracked test file
- 2025-12-13: [Review] Manual testing verified - isCollection and GUID display working correctly

## Senior Developer Review (AI)

**Review Date:** 2025-12-13
**Reviewer:** Code Review Workflow

### Issues Found and Fixed

| Severity | Issue | Resolution |
|----------|-------|------------|
| HIGH | Test file not staged (would be lost on commit) | Staged `test/services/gallery_service_guid_lookup_test.dart` |
| HIGH | Task 5 marked complete but has incomplete subtasks | Changed Task 5 to `[ ]` incomplete |
| MEDIUM | `graphqlEndpoint` not reset in `resetToDefaults()` | Added `setGraphqlEndpoint(defaultGraphqlEndpoint)` call |
| MEDIUM | Tests didn't actually exercise GUID lookup | Added `initializeGuidLookup()` method and 3 integration tests |

### Issues Noted (Not Fixed)

| Severity | Issue | Reason |
|----------|-------|--------|
| MEDIUM | GraphQL endpoint not editable in Settings UI | Feature enhancement, not a bug - AC only requires SettingsService |
| MEDIUM | Silent cache failures | By design per project rules (no debug logging) |
| LOW | Legacy `galleryUrl` getter unused | May be needed for backward compatibility |

### Verification

- `flutter analyze`: ✅ No issues
- `flutter test`: ✅ 1281 tests pass (12 GUID lookup tests)
- All HIGH and MEDIUM issues fixed

### Manual Testing Complete

- [x] Verify isCollection shows correctly for airwindows
- [x] Verify guid shows for C++ plugins

**Story completed and ready for commit.**

## Dev Agent Record

### Implementation Plan
- Implemented GraphQL integration using existing http package (no new dependencies)
- Added `_fetchPluginsViaGraphQL()` and `_fetchCategoriesViaGraphQL()` methods
- Created `_mapGraphQLToGallery()` to transform GraphQL response to existing models
- Implemented file-based cache persistence using path_provider
- Built GUID lookup map that indexes both single-plugin GUIDs and collection GUIDs

### Completion Notes
- All 1278 tests pass (including 9 new tests for GUID lookup)
- `flutter analyze` passes with zero warnings
- GraphQL queries use `verified: true` filter to only fetch verified plugins
- Cache strategy: 1-hour memory cache, 24-hour file cache with background refresh
- GUID lookup supports case-insensitive matching as fallback
- Manual testing pending for airwindows collection and C++ plugin GUID display
