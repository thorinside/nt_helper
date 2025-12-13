# Story 12.3: Migrate Gallery Service to GraphQL API

Status: ready

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

5. Refactor `fetchGallery()` to use GraphQL `plugins` query with `verified: true` filter
6. Fetch categories via separate `categories` query
7. Map GraphQL response to existing `Gallery`, `GalleryPlugin`, `PluginCategory` models
8. Preserve existing 1-hour client-side cache behavior (optional: reduce to 15 minutes since server cache is removed)
9. `isCollection` field populated correctly from GraphQL response
10. `guid` field populated correctly from GraphQL response
11. `collectionGuids` field added to model and populated (new field for future use)

### Model Updates

12. Add `collectionGuids` field to `GalleryPlugin` model: `@Default([]) List<String> collectionGuids`
13. Update `gallery_models.dart` with new field
14. Run `flutter pub run build_runner build` to regenerate freezed files
15. Update JSON schema `docs/plugin_gallery_schema.json` with `collectionGuids` array field

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

16. Authors data not available in plugin query - derive from `authorId` or fetch separately if needed
17. For now, use repository owner as author identifier (existing behavior)
18. Author display name can be fetched on-demand if detailed author info is needed

### Backward Compatibility

19. Existing `searchPlugins()` method continues to work unchanged
20. Existing `addToQueue()` and installation flow unchanged
21. All existing tests pass
22. `flutter analyze` passes with zero warnings

### Error Handling

23. Network errors throw `GalleryException` with descriptive message
24. GraphQL errors (partial data) handled gracefully
25. Fallback to cached data on network failure (if cache exists)

### Local Cache Persistence

26. Persist gallery JSON to local storage (file or SharedPreferences)
27. On app launch, load from local cache first (instant display)
28. Background refresh from GraphQL if cache is stale (>24 hours or user-triggered)
29. Cache includes timestamp for staleness check
30. Reduces server load - gallery data changes infrequently

### GUID-Based Plugin Lookup

31. Build a GUID → GalleryPlugin lookup map from cached gallery data
32. Add `getPluginByGuid(String guid)` method to GalleryService
33. Method returns `GalleryPlugin?` - null if GUID not found in gallery
34. Lookup map rebuilt when gallery cache is refreshed
35. For C++ collections, also index by each GUID in `collectionGuids`

This enables the app to display rich metadata for community plugins when their GUID matches a gallery entry:
- Plugin name instead of raw GUID
- Author information
- Description
- Repository link
- Installation status (if also tracking installations)

## Tasks / Subtasks

- [ ] Task 1: Update models (AC: 12-15)
  - [ ] Add `@Default([]) List<String> collectionGuids` to `GalleryPlugin` in `gallery_models.dart`
  - [ ] Run `flutter pub run build_runner build`
  - [ ] Update `docs/plugin_gallery_schema.json` with collectionGuids field
  - [ ] Verify generated files compile correctly

- [ ] Task 2: Refactor fetchGallery (AC: 1-11, 16-18)
  - [ ] Add `graphqlEndpoint` to SettingsService with default value
  - [ ] Create `_fetchPluginsViaGraphQL()` private method
  - [ ] Create `_fetchCategoriesViaGraphQL()` private method
  - [ ] Create `_mapGraphQLToGallery()` to convert response to Gallery model
  - [ ] Handle plugin type enum mapping (LUA/THREEPOT/CPP → lua/threepot/cpp)
  - [ ] Derive author map from plugin data (use authorId or repositoryOwner)
  - [ ] Update `fetchGallery()` to call GraphQL methods
  - [ ] Preserve cache behavior with `_cachedGallery` and `_lastFetch`

- [ ] Task 3: Implement local cache persistence (AC: 26-30)
  - [ ] Create cache file path using `path_provider` (applicationDocumentsDirectory)
  - [ ] Save gallery JSON + timestamp to `gallery_cache.json` after successful fetch
  - [ ] Load from cache file on `fetchGallery()` if exists and not forcing refresh
  - [ ] Add `_cacheTimestamp` field to track when cache was written
  - [ ] Consider cache stale after 24 hours (configurable)
  - [ ] Background refresh: return cached data immediately, fetch new data async

- [ ] Task 4: Implement GUID lookup (AC: 31-35)
  - [ ] Add `Map<String, GalleryPlugin> _guidLookup = {}` private field
  - [ ] Create `_buildGuidLookup(Gallery gallery)` that populates map from:
    - Single plugins: `plugin.guid` → plugin
    - Collections: each GUID in `plugin.collectionGuids` → plugin
  - [ ] Call `_buildGuidLookup()` after caching gallery in `fetchGallery()`
  - [ ] Add public `GalleryPlugin? getPluginByGuid(String guid)` method
  - [ ] Handle case-insensitive GUID matching (GUIDs are 4 chars, case matters but be lenient)

- [ ] Task 5: Testing and validation (AC: 19-25)
  - [ ] Verify `searchPlugins()` works with GraphQL data
  - [ ] Verify `addToQueue()` works with GraphQL data
  - [ ] Verify `getPluginByGuid()` returns correct plugin for known GUIDs
  - [ ] Verify `getPluginByGuid()` returns null for unknown GUIDs
  - [ ] Test network error handling
  - [ ] Test cache fallback behavior
  - [ ] Run `flutter analyze` - zero warnings
  - [ ] Run existing gallery tests
  - [ ] Manual test: verify isCollection shows correctly for airwindows
  - [ ] Manual test: verify guid shows for C++ plugins

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

- [ ] GraphQL client fetches plugins successfully
- [ ] `isCollection: true` displays correctly for airwindows and expert-sleepers-examples
- [ ] `guid` field populated for C++ plugins (e.g., "TidS" for Tides)
- [ ] All existing gallery functionality works unchanged
- [ ] `flutter analyze` passes with zero warnings
- [ ] Story status updated to "done"

## File List

- lib/services/gallery_service.dart (modified)
- lib/services/settings_service.dart (modified)
- lib/models/gallery_models.dart (modified)
- lib/models/gallery_models.freezed.dart (regenerated)
- lib/models/gallery_models.g.dart (regenerated)
- docs/plugin_gallery_schema.json (modified)
- docs/sprint-artifacts/sprint-status.yaml (modified)
