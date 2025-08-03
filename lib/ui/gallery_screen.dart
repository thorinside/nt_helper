import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:nt_helper/models/gallery_models.dart';
import 'package:nt_helper/services/gallery_service.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/ui/gallery/gallery_cubit.dart';
import 'package:nt_helper/ui/widgets/plugin_selection_dialog.dart';
import 'package:nt_helper/services/plugin_metadata_extractor.dart';
import 'package:nt_helper/utils/responsive.dart';

/// A beautiful gallery screen for discovering and installing plugins
class GalleryScreen extends StatelessWidget {
  final DistingCubit distingCubit;
  final GalleryService galleryService;

  const GalleryScreen({
    super.key,
    required this.distingCubit,
    required this.galleryService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: distingCubit),
        BlocProvider(
          create: (context) => GalleryCubit(galleryService)..loadGallery(),
        ),
      ],
      child: _GalleryView(
        distingCubit: distingCubit,
        galleryService: galleryService,
      ),
    );
  }
}

class _GalleryView extends StatefulWidget {
  final DistingCubit distingCubit;
  final GalleryService galleryService;

  const _GalleryView({
    required this.distingCubit,
    required this.galleryService,
  });

  @override
  State<_GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<_GalleryView>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  // UI state
  late TabController _tabController;

  // Drag and drop state
  bool _isDragOver = false;
  bool _isInstalling = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to search changes
    _searchController.addListener(() {
      context.read<GalleryCubit>().applyFilters(
            searchQuery: _searchController.text,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GalleryCubit, GalleryState>(
      builder: (context, state) {
        Widget content = Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              _buildHeader(state),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGalleryTab(state),
                    _buildQueueTab(),
                  ],
                ),
              ),
            ],
          ),
        );

        // Only add drag and drop on desktop platforms
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.windows ||
                defaultTargetPlatform == TargetPlatform.macOS ||
                defaultTargetPlatform == TargetPlatform.linux)) {
          return DropTarget(
            onDragDone: _handleDragDone,
            onDragEntered: _handleDragEntered,
            onDragExited: _handleDragExited,
            child: Stack(
              children: [
                content,
                if (_isDragOver) _buildDragOverlay(),
                if (_isInstalling) _buildInstallOverlay(),
              ],
            ),
          );
        }

        return content;
      },
    );
  }

  Widget _buildHeader(GalleryState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Plugin Gallery',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const Spacer(),
              _buildHeaderActions(state),
            ],
          ),
          if (state is GalleryLoaded) ...[
            const SizedBox(height: 8),
            Text(
              state.gallery.metadata.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderActions(GalleryState state) {
    final queueCount = state is GalleryLoaded ? state.queue.length : 0;
    final updateCount = state is GalleryLoaded 
        ? state.updateInfo.values.where((info) => info.updateAvailable).length 
        : 0;
    final isRefreshing = state is GalleryLoading;

    return Row(
      children: [
        // Update check button with badge
        Badge(
          isLabelVisible: updateCount > 0,
          label: Text('$updateCount'),
          child: IconButton(
            icon: isRefreshing 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Icon(
                    updateCount > 0 ? Icons.update : Icons.sync,
                    color: updateCount > 0 ? Colors.orange : null,
                  ),
            onPressed: isRefreshing 
                ? null 
                : () => context.read<GalleryCubit>().refreshUpdates(),
            tooltip: isRefreshing 
                ? 'Refreshing gallery...'
                : updateCount > 0 
                    ? 'Updates available ($updateCount) - Tap to refresh'
                    : 'Refresh gallery',
          ),
        ),
        Badge(
          isLabelVisible: queueCount > 0,
          label: Text('$queueCount'),
          child: IconButton(
            icon: const Icon(Icons.download_for_offline),
            onPressed: () {
              _tabController.animateTo(1);
            },
            tooltip: 'Install Queue ($queueCount)',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              context.read<GalleryCubit>().loadGallery(forceRefresh: true),
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.showSettingsDialog(),
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            icon: const Icon(Icons.explore),
            text: 'Explore',
          ),
          Tab(
            icon: BlocBuilder<GalleryCubit, GalleryState>(
              builder: (context, state) {
                final queueCount =
                    state is GalleryLoaded ? state.queue.length : 0;
                return Badge(
                  isLabelVisible: queueCount > 0,
                  label: Text('$queueCount'),
                  child: const Icon(Icons.download_for_offline),
                );
              },
            ),
            text: 'Queue',
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab(GalleryState state) {
    if (state is GalleryInitial) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is GalleryLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading gallery...'),
          ],
        ),
      );
    } else if (state is GalleryLoaded) {
      return Column(
        children: [
          _buildSearchAndFilters(state),
          Expanded(
            child: _buildPluginGrid(state),
          ),
        ],
      );
    } else if (state is GalleryError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load gallery',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<GalleryCubit>().loadGallery(forceRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSearchAndFilters(GalleryState state) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getScreenPadding(context);
    final filterSpacing = Responsive.getFilterSpacing(context);
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          if (isMobile) ...[
            // Mobile layout: Search bar on first line
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search plugins...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<GalleryCubit>().clearFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            SizedBox(height: filterSpacing),
            
            // Mobile layout: Filters on second line
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryFilter(state),
                  SizedBox(width: filterSpacing),
                  _buildTypeFilter(state),
                  SizedBox(width: filterSpacing),
                  _buildFeaturedFilter(state),
                  if (state is GalleryLoaded &&
                      (state.selectedCategory != null ||
                          state.selectedType != null ||
                          state.showFeaturedOnly ||
                          _searchController.text.isNotEmpty)) ...[
                    SizedBox(width: filterSpacing),
                    _buildClearFilter(),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Desktop layout: Single row with search and filters
            Row(
              children: [
                // Search field - takes available space
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search plugins...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context.read<GalleryCubit>().clearFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Filter chips in a row
                _buildCategoryFilter(state),
                const SizedBox(width: 8),
                _buildTypeFilter(state),
                const SizedBox(width: 8),
                _buildFeaturedFilter(state),
                const SizedBox(width: 8),

                // Clear filters
                if (state is GalleryLoaded &&
                    (state.selectedCategory != null ||
                        state.selectedType != null ||
                        state.showFeaturedOnly ||
                        _searchController.text.isNotEmpty))
                  _buildClearFilter(),
              ],
            ),
          ],

          // Results count
          SizedBox(height: isMobile ? filterSpacing : 12),
          Row(
            children: [
              Text(
                state is GalleryLoaded
                    ? '${state.filteredPlugins.length} plugin${state.filteredPlugins.length == 1 ? '' : 's'}'
                    : '0 plugins',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(GalleryState state) {
    if (state is! GalleryLoaded || state.gallery.categories.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return PopupMenuButton<String?>(
      child: Chip(
        avatar: Icon(
          Icons.category,
          size: 18,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.7),
        ),
        label: Text(state.selectedCategory ?? 'Category'),
        deleteIcon: Icon(
          Icons.arrow_drop_down,
          size: 18,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.7),
        ),
        onDeleted: () {},
      ),
      onSelected: (value) {
        context.read<GalleryCubit>().applyFilters(
              category: value,
            );
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String?>(
          value: null,
          child: Text('All Categories'),
        ),
        ...(state.gallery.categories).map(
          (cat) => PopupMenuItem<String>(
            value: cat.id,
            child: Row(
              children: [
                if (cat.icon != null) ...[
                  Icon(_getIconData(cat.icon!), size: 16),
                  const SizedBox(width: 8),
                ],
                Text(cat.name),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilter(GalleryState state) {
    return PopupMenuButton<GalleryPluginType?>(
      child: Chip(
        avatar: Icon(
          Icons.extension,
          size: 18,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.7),
        ),
        label: Text(state is GalleryLoaded
            ? (state.selectedType?.displayName ?? 'Type')
            : 'Type'),
        deleteIcon: Icon(
          Icons.arrow_drop_down,
          size: 18,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.7),
        ),
        onDeleted: () {},
      ),
      onSelected: (value) {
        context.read<GalleryCubit>().applyFilters(
              type: value,
            );
      },
      itemBuilder: (context) => [
        const PopupMenuItem<GalleryPluginType?>(
          value: null,
          child: Text('All Types'),
        ),
        ...GalleryPluginType.values.map(
          (type) => PopupMenuItem<GalleryPluginType>(
            value: type,
            child: Text(type.displayName),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedFilter(GalleryState state) {
    return FilterChip(
      avatar: Icon(
        Icons.star,
        size: 18,
        color: (state is GalleryLoaded && state.showFeaturedOnly)
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.7),
      ),
      label: const Text('Featured'),
      selected:
          state is GalleryLoaded ? state.showFeaturedOnly : false,
      selectedColor: Theme.of(context).colorScheme.primary,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: (state is GalleryLoaded && state.showFeaturedOnly)
            ? Theme.of(context).colorScheme.onPrimary
            : null,
      ),
      onSelected: (selected) {
        context.read<GalleryCubit>().applyFilters(
              featured: selected,
            );
      },
    );
  }

  Widget _buildClearFilter() {
    return ActionChip(
      avatar: Icon(
        Icons.clear,
        size: 18,
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.7),
      ),
      label: const Text('Clear'),
      onPressed: () {
        _searchController.clear();
        context.read<GalleryCubit>().clearFilters();
      },
    );
  }

  Widget _buildPluginGrid(GalleryState state) {
    final filteredPlugins =
        state is GalleryLoaded ? state.filteredPlugins : <GalleryPlugin>[];

    if (filteredPlugins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No plugins found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.start, // Left-justify the cards
        spacing: 12, // Horizontal spacing between cards
        runSpacing: 12, // Vertical spacing between rows
        children: filteredPlugins.map((plugin) {
          return _buildPluginCard(plugin, state, context);
        }).toList(),
      ),
    );
  }

  Widget _buildPluginCard(
      GalleryPlugin plugin, GalleryState state, BuildContext parentContext) {
    if (state is! GalleryLoaded) return const SizedBox.shrink();

    final author = plugin.getAuthor(state.gallery);
    final category = plugin.getCategory(state.gallery);

    final width = MediaQuery.of(context).size.width;
    final isNarrowScreen = width < 375;

    // Get update information for this plugin
    final updateInfo = state.updateInfo[plugin.id];
    final hasUpdate = updateInfo?.hasUpdate ?? false;
    final isInstalled = updateInfo != null;

    return SizedBox(
      width: 320,
      height: isNarrowScreen ? null : 305, // Flexible height for narrow screens
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badges
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (plugin.featured) ...[
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (hasUpdate) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'UPDATE',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (isInstalled && !hasUpdate) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'INSTALLED',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                plugin.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                plugin.type.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondary,
                                    ),
                              ),
                            ),
                            if (category != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  category.name,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content with fixed layout sections
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(8, 8, 8, 12), // 12px bottom margin
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Shrink to fit content
                children: [
                  // Fixed description area (5 lines) with padding
                  Container(
                    height:
                        116, // Fixed height for 5 lines + padding (100 + 16)
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      plugin.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 16), // Space after description

                  // Metadata section (author, downloads, ratings)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (author != null) ...[
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                author.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else
                            const Spacer(),
                          if (plugin.formattedLatestVersion.isNotEmpty)
                            Text(
                              plugin.formattedLatestVersion,
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                            ),
                        ],
                      ),
                      // Version information row
                      if (isInstalled) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hasUpdate
                                    ? 'v${updateInfo.installedVersion} → v${updateInfo.availableVersion}'
                                    : 'v${updateInfo.installedVersion} (up to date)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: hasUpdate
                                          ? Colors.orange
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                      fontWeight: hasUpdate
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8), // Reduced spacing above button

                  // Action button at bottom
                  SizedBox(
                    width: double.infinity,
                    child: () {
                      final isInQueue =
                          state.queue.any((q) => q.plugin.id == plugin.id);

                      // Determine button state based on update and queue status
                      if (isInQueue) {
                        // Plugin is in queue - show remove button
                        return ElevatedButton.icon(
                          onPressed: () => parentContext
                              .read<GalleryCubit>()
                              .removeFromQueue(plugin.id),
                          icon: const Icon(Icons.remove_from_queue),
                          label: const Text('Remove'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Theme.of(context).colorScheme.onError,
                          ),
                        );
                      } else if (hasUpdate) {
                        // Plugin has update available - show update button
                        return ElevatedButton.icon(
                          onPressed: () async => await parentContext
                              .read<GalleryCubit>()
                              .addToQueue(plugin),
                          icon: const Icon(Icons.update),
                          label: const Text('Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        );
                      } else if (isInstalled) {
                        // Plugin is installed and up to date - show installed status
                        return ElevatedButton.icon(
                          onPressed: null, // No action needed - updates are detected automatically
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Installed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.green,
                            disabledForegroundColor: Colors.white,
                          ),
                        );
                      } else {
                        // Plugin not installed - show add to queue button
                        return ElevatedButton.icon(
                          onPressed: () async => await parentContext
                              .read<GalleryCubit>()
                              .addToQueue(plugin),
                          icon: const Icon(Icons.add_to_queue),
                          label: const Text('Add to Queue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        );
                      }
                    }(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTab() {
    return BlocBuilder<GalleryCubit, GalleryState>(
      builder: (context, state) {
        final queue = state is GalleryLoaded ? state.queue : <QueuedPlugin>[];

        if (queue.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_for_offline_outlined,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your queue is empty',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add plugins from the explore tab to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Explore Plugins'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Queue header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${queue.length} plugin${queue.length == 1 ? '' : 's'} queued',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        queue.any((q) => q.status == QueuedPluginStatus.queued)
                            ? () => context.read<GalleryCubit>().clearQueue()
                            : null,
                    child: const Text('Clear All'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _canInstallQueue(queue) ? _installQueue : null,
                    icon: const Icon(Icons.download),
                    label: const Text('Install All'),
                  ),
                ],
              ),
            ),

            // Queue list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  return _buildQueueItem(queue[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQueueItem(QueuedPlugin queuedPlugin) {
    final plugin = queuedPlugin.plugin;
    return BlocBuilder<GalleryCubit, GalleryState>(
      builder: (context, state) {
        if (state is! GalleryLoaded) return const SizedBox.shrink();

        final author = plugin.getAuthor(state.gallery);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                _getPluginIcon(plugin.type),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              plugin.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (author != null) Text('by ${author.name}'),
                Text('Version: ${queuedPlugin.selectedVersion}'),
                if (queuedPlugin.isCollection) ...[
                  Text(
                    queuedPlugin.hasSelectedPlugins
                        ? queuedPlugin.selectionSummary
                        : 'Collection (selection needed)',
                    style: TextStyle(
                      color: queuedPlugin.hasSelectedPlugins
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.error,
                      fontSize: 12,
                      fontWeight: queuedPlugin.hasSelectedPlugins
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                  ),
                ],
                if (queuedPlugin.status != QueuedPluginStatus.queued) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusIcon(queuedPlugin.status),
                      const SizedBox(width: 4),
                      Text(_getStatusText(queuedPlugin.status)),
                      if (queuedPlugin.progress != null) ...[
                        const SizedBox(width: 8),
                        Text('${(queuedPlugin.progress! * 100).toInt()}%'),
                      ],
                    ],
                  ),
                  if (queuedPlugin.progress != null &&
                      queuedPlugin.status != QueuedPluginStatus.completed &&
                      queuedPlugin.status != QueuedPluginStatus.failed) ...[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: queuedPlugin.progress),
                  ],
                  if (queuedPlugin.errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      queuedPlugin.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ],
            ),
            trailing: (queuedPlugin.status == QueuedPluginStatus.queued ||
                    queuedPlugin.status == QueuedPluginStatus.failed)
                ? _buildQueueActions(queuedPlugin)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(QueuedPluginStatus status) {
    switch (status) {
      case QueuedPluginStatus.queued:
        return const Icon(Icons.schedule, size: 16);
      case QueuedPluginStatus.downloading:
        return const Icon(Icons.download, size: 16);
      case QueuedPluginStatus.extracting:
        return const Icon(Icons.archive, size: 16);
      case QueuedPluginStatus.installing:
        return const Icon(Icons.install_desktop, size: 16);
      case QueuedPluginStatus.completed:
        return Icon(Icons.check_circle,
            size: 16, color: Theme.of(context).colorScheme.primary);
      case QueuedPluginStatus.failed:
        return Icon(Icons.error,
            size: 16, color: Theme.of(context).colorScheme.error);
      case QueuedPluginStatus.analyzing:
        return Icon(Icons.query_builder,
            size: 16, color: Theme.of(context).colorScheme.error);
    }
  }

  String _getStatusText(QueuedPluginStatus status) {
    switch (status) {
      case QueuedPluginStatus.queued:
        return 'Queued';
      case QueuedPluginStatus.downloading:
        return 'Downloading...';
      case QueuedPluginStatus.extracting:
        return 'Extracting...';
      case QueuedPluginStatus.installing:
        return 'Installing...';
      case QueuedPluginStatus.completed:
        return 'Completed';
      case QueuedPluginStatus.failed:
        return 'Failed';
      case QueuedPluginStatus.analyzing:
        return 'Analyzing...';
    }
  }

  IconData _getPluginIcon(GalleryPluginType type) {
    switch (type) {
      case GalleryPluginType.lua:
        return Icons.code;
      case GalleryPluginType.threepot:
        return Icons.tune;
      case GalleryPluginType.cpp:
        return Icons.memory;
    }
  }

  bool _canInstallQueue(List<QueuedPlugin> queue) {
    // Check if there are any queued plugins
    final queuedPlugins =
        queue.where((q) => q.status == QueuedPluginStatus.queued);
    if (queuedPlugins.isEmpty) return false;

    // Check if all collections have valid selections
    for (final queuedPlugin in queuedPlugins) {
      if (queuedPlugin.isCollection && !queuedPlugin.hasSelectedPlugins) {
        // Collection without selection - cannot install
        return false;
      }
      if (queuedPlugin.isCollection && queuedPlugin.selectedPluginCount == 0) {
        // Collection with no selected plugins - cannot install
        return false;
      }
    }

    return true;
  }

  Widget _buildQueueActions(QueuedPlugin queuedPlugin) {
    final plugin = queuedPlugin.plugin;

    // For collections, show both Choose and Remove buttons
    if (queuedPlugin.isCollection) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Choose button for collections (always show for potential collections)
          IconButton(
            icon: Icon(
              queuedPlugin.hasSelectedPlugins ? Icons.edit : Icons.tune,
              color: queuedPlugin.hasSelectedPlugins
                  ? null
                  : Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _showPluginSelectionDialog(queuedPlugin),
            tooltip: queuedPlugin.hasSelectedPlugins
                ? 'Edit plugin selection'
                : 'Choose plugins to install',
          ),
          // Remove button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                context.read<GalleryCubit>().removeFromQueue(plugin.id),
            tooltip: queuedPlugin.status == QueuedPluginStatus.failed
                ? 'Dismiss error'
                : 'Remove from queue',
          ),
        ],
      );
    }

    // For single plugins, show only remove button
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: () => context.read<GalleryCubit>().removeFromQueue(plugin.id),
      tooltip: queuedPlugin.status == QueuedPluginStatus.failed
          ? 'Dismiss error'
          : 'Remove from queue',
    );
  }

  Future<void> _showPluginSelectionDialog(QueuedPlugin queuedPlugin) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading plugin collection...'),
            ],
          ),
        ),
      );

      // Download and extract plugin list
      var galleryCubit = context.read<GalleryCubit>();
      final galleryService = galleryCubit.galleryService;
      debugPrint(
          '[PluginDialog] Downloading archive for ${queuedPlugin.plugin.name}');
      final archiveBytes = await galleryService.downloadPluginArchive(
        queuedPlugin.plugin,
        queuedPlugin.selectedVersion,
      );
      debugPrint('[PluginDialog] Downloaded ${archiveBytes.length} bytes');

      // Check if this is actually a collection with multiple installable plugins
      final installableCount =
          await PluginMetadataExtractor.countInstallablePlugins(
        archiveBytes,
        queuedPlugin.plugin,
      );
      debugPrint('[PluginDialog] Found $installableCount installable plugins');

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // If exactly one installable plugin, auto-select it and skip dialog
      if (installableCount == 1) {
        debugPrint('[PluginDialog] Single plugin detected, auto-selecting');
        final availablePlugins =
            await PluginMetadataExtractor.extractPluginsFromArchive(
          archiveBytes,
          queuedPlugin.plugin,
        );

        // Auto-select only installable plugins (.o, .lua, .3pot)
        final autoSelectedPlugins = availablePlugins
            .map((p) => p.copyWith(
                selected:
                    const ['.o', '.lua', '.3pot'].contains('.${p.fileType}')))
            .toList();
        galleryCubit.updateQueuedPluginSelection(
          queuedPlugin.plugin.id,
          autoSelectedPlugins,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Auto-selected single plugin from ${queuedPlugin.plugin.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // Handle case where no installable plugins found
      if (installableCount == 0) {
        debugPrint('[PluginDialog] No installable plugins found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No installable plugins found in ${queuedPlugin.plugin.name}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Multiple installable plugins - show selection dialog
      final availablePlugins =
          await PluginMetadataExtractor.extractPluginsFromArchive(
        archiveBytes,
        queuedPlugin.plugin,
      );
      debugPrint(
          '[PluginDialog] Extraction returned ${availablePlugins.length} plugins');

      // Initialize selection from existing state, or select all if first time
      final existingSelection = queuedPlugin.selectedPlugins;
      final hasExistingSelection = existingSelection.isNotEmpty;

      for (int i = 0; i < availablePlugins.length; i++) {
        if (hasExistingSelection) {
          final existing = existingSelection.firstWhere(
            (p) => p.relativePath == availablePlugins[i].relativePath,
            orElse: () => availablePlugins[i],
          );
          availablePlugins[i] =
              availablePlugins[i].copyWith(selected: existing.selected);
        } else {
          // First time - select all installable plugins by default
          final isInstallable = const ['.o', '.lua', '.3pot']
              .contains('.${availablePlugins[i].fileType}');
          availablePlugins[i] =
              availablePlugins[i].copyWith(selected: isInstallable);
        }
      }

      // Show selection dialog
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => PluginSelectionDialog(
          plugin: queuedPlugin.plugin,
          availablePlugins: availablePlugins,
          onSelectionChanged: (selectedPlugins) {
            debugPrint(
                '[PluginDialog] Selection changed: ${selectedPlugins.where((p) => p.selected).length} of ${selectedPlugins.length} plugins selected');
            galleryCubit.updateQueuedPluginSelection(
              queuedPlugin.plugin.id,
              selectedPlugins,
            );
          },
        ),
      );
    } catch (e) {
      // Close loading dialog if it's still open
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load plugin collection: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  IconData _getIconData(String iconName) {
    // Map icon names to Flutter icons
    switch (iconName.toLowerCase()) {
      case 'audio_file':
        return Icons.audio_file;
      case 'graphic_eq':
        return Icons.graphic_eq;
      case 'piano':
        return Icons.piano;
      case 'queue_music':
        return Icons.queue_music;
      case 'tune':
        return Icons.tune;
      case 'extension':
        return Icons.extension;
      default:
        return Icons.category;
    }
  }

  Future<void> _installQueue() async {
    try {
      await widget.galleryService.installQueuedPlugins(
        distingInstallPlugin: (fileName, fileData, {onProgress}) async {
          // Use the DistingCubit's installPlugin method
          await context.read<DistingCubit>().installPlugin(
                fileName,
                fileData,
                onProgress: onProgress,
              );
        },
        onPluginStart: (plugin) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Installing ${plugin.plugin.name}...'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        onPluginComplete: (plugin) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully installed ${plugin.plugin.name}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
        onPluginError: (plugin, error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to install ${plugin.plugin.name}: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Installation failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Drag and drop handlers
  void _handleDragEntered(DropEventDetails details) {
    setState(() {
      _isDragOver = true;
    });
  }

  void _handleDragExited(DropEventDetails details) {
    setState(() {
      _isDragOver = false;
    });
  }

  void _handleDragDone(DropDoneDetails details) {
    setState(() {
      _isDragOver = false;
    });

    // Filter files by extension
    final allowedExtensions = {'.lua', '.3pot', '.o'};
    final validFiles = details.files.where((file) {
      final extension = file.path.toLowerCase().split('.').last;
      return allowedExtensions.contains('.$extension');
    }).toList();

    if (validFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please drop valid plugin files (.lua, .3pot, or .o)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (validFiles.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please drop only one file at a time'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Install the single file
    _installDroppedFile(validFiles.first);
  }

  Future<void> _installDroppedFile(XFile file) async {
    setState(() {
      _isInstalling = true;
    });

    try {
      // Read file data
      final fileBytes = await file.readAsBytes();
      final fileName = file.name;

      // Install using the Disting cubit
      if (!mounted) return;
      await context.read<DistingCubit>().installPlugin(
        fileName,
        fileBytes,
        onProgress: (progress) {
          // Progress callback for future use
        },
      );

      setState(() {
        _isInstalling = false;
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully installed "$fileName"'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      setState(() {
        _isInstalling = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to install "${file.name}": $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildDragOverlay() {
    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Drop plugin files here to install',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Supports .lua, .3pot, and .o files',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstallOverlay() {
    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Installing plugin...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few moments',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
