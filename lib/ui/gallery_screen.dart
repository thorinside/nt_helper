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
          create: (context) =>
              GalleryCubit(galleryService)..loadGallery(),
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

    return Row(
      children: [
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
          onPressed: () => context
              .read<GalleryCubit>()
              .loadGallery(forceRefresh: true),
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
              onPressed: () => context
                  .read<GalleryCubit>()
                  .loadGallery(forceRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSearchAndFilters(GalleryState state) {
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
        children: [
          // Search bar
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
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Category filter
              if (state is GalleryLoaded &&
                  state.gallery.categories.isNotEmpty)
                PopupMenuButton<String?>(
                  child: Chip(
                    avatar: Icon(
                      Icons.category,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                    label: Text(state.selectedCategory ?? 'All Categories'),
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
                    ...(state is GalleryLoaded
                            ? state.gallery.categories
                            : [])
                        .map(
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
                ),

              // Type filter
              PopupMenuButton<GalleryPluginType?>(
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
                      ? (state.selectedType?.displayName ?? 'All Types')
                      : 'All Types'),
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
              ),

              // Featured filter
              FilterChip(
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
              ),

              // Verified filter
              FilterChip(
                avatar: Icon(
                  Icons.verified,
                  size: 18,
                  color: (state is GalleryLoaded && state.showVerifiedOnly)
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                ),
                label: const Text('Verified'),
                selected:
                    state is GalleryLoaded ? state.showVerifiedOnly : false,
                selectedColor: Theme.of(context).colorScheme.primary,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: (state is GalleryLoaded && state.showVerifiedOnly)
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                ),
                onSelected: (selected) {
                  context.read<GalleryCubit>().applyFilters(
                        verified: selected,
                      );
                },
              ),

              // Clear filters
              if (state is GalleryLoaded &&
                  (state.selectedCategory != null ||
                      state.selectedType != null ||
                      state.showFeaturedOnly ||
                      state.showVerifiedOnly ||
                      _searchController.text.isNotEmpty))
                ActionChip(
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
                ),
            ],
          ),

          // Results count
          const SizedBox(height: 8),
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

  Widget _buildPluginGrid(GalleryState state) {
    final filteredPlugins = state is GalleryLoaded
        ? state.filteredPlugins
        : <GalleryPlugin>[];

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


  Widget _buildPluginCard(GalleryPlugin plugin, GalleryState state, BuildContext parentContext) {
    if (state is! GalleryLoaded) return const SizedBox.shrink();

    final author = plugin.getAuthor(state.gallery);
    final category = plugin.getCategory(state.gallery);

    final width = MediaQuery.of(context).size.width;
    final isNarrowScreen = width < 375;
    
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
                                  color:
                                      Theme.of(context).colorScheme.secondary,
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
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
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
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12), // 12px bottom margin
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Shrink to fit content
                  children: [
                    // Fixed description area (5 lines) with padding
                    Container(
                      height: 116, // Fixed height for 5 lines + padding (100 + 16)
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
                            Text(
                              plugin.formattedRating,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
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
                    
                    const SizedBox(height: 8), // Reduced spacing above button

                    // Action button at bottom
                    SizedBox(
                      width: double.infinity,
                      child: () {
                        final queue = state is GalleryLoaded
                            ? state.queue
                            : <QueuedPlugin>[];
                        final isInQueue =
                            queue.any((q) => q.plugin.id == plugin.id);

                        return ElevatedButton.icon(
                          onPressed: isInQueue
                              ? () => parentContext
                                  .read<GalleryCubit>()
                                  .removeFromQueue(plugin.id)
                              : () => parentContext
                                  .read<GalleryCubit>()
                                  .addToQueue(plugin),
                          icon: Icon(isInQueue
                              ? Icons.remove_from_queue
                              : Icons.add_to_queue),
                          label:
                              Text(isInQueue ? 'Remove' : 'Add to Queue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInQueue
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: isInQueue
                                ? Theme.of(context).colorScheme.onError
                                : Theme.of(context).colorScheme.onPrimary,
                          ),
                        );
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
        final queue =
            state is GalleryLoaded ? state.queue : <QueuedPlugin>[];

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
                    onPressed: queue
                            .any((q) => q.status == QueuedPluginStatus.queued)
                        ? () => context.read<GalleryCubit>().clearQueue()
                        : null,
                    child: const Text('Clear All'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed:
                        queue.any((q) => q.status == QueuedPluginStatus.queued)
                            ? _installQueue
                            : null,
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
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context
                        .read<GalleryCubit>()
                        .removeFromQueue(plugin.id),
                    tooltip: queuedPlugin.status == QueuedPluginStatus.failed
                        ? 'Dismiss error'
                        : 'Remove from queue',
                  )
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

  void _showPluginDetails(GalleryPlugin plugin) {
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<GalleryCubit, GalleryState>(
        builder: (context, state) {
          if (state is! GalleryLoaded) return const SizedBox.shrink();

          return _PluginDetailsDialog(
            plugin: plugin,
            gallery: state.gallery,
            galleryService: widget.galleryService,
          );
        },
      ),
    );
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
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Plugin details dialog
class _PluginDetailsDialog extends StatelessWidget {
  final GalleryPlugin plugin;
  final Gallery gallery;
  final GalleryService galleryService;

  const _PluginDetailsDialog({
    required this.plugin,
    required this.gallery,
    required this.galleryService,
  });

  @override
  Widget build(BuildContext context) {
    final author = plugin.getAuthor(gallery);
    final category = plugin.getCategory(gallery);

    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              plugin.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (author != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'by ${author.name}',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tags and metadata
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(plugin.type.displayName),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                ),
                if (category != null)
                  Chip(
                    label: Text(category.name),
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                  ),
                ...plugin.tags.map(
                  (tag) => Chip(
                    label: Text(tag),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plugin.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (plugin.longDescription != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        plugin.longDescription!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Metrics
                    Row(
                      children: [
                        Icon(
                          Icons.download,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${plugin.formattedDownloads} downloads',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plugin.formattedRating,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            const SizedBox(height: 16),
            Row(
              children: [
                if (plugin.repository.url.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Open URL
                    },
                    icon: const Icon(Icons.code),
                    label: const Text('View Source'),
                  ),
                const Spacer(),
                BlocBuilder<GalleryCubit, GalleryState>(
                  builder: (context, state) {
                    final queue = state is GalleryLoaded
                        ? state.queue
                        : <QueuedPlugin>[];
                    final isInQueue =
                        queue.any((q) => q.plugin.id == plugin.id);

                    return ElevatedButton.icon(
                      onPressed: isInQueue
                          ? () => context
                              .read<GalleryCubit>()
                              .removeFromQueue(plugin.id)
                          : () => context
                              .read<GalleryCubit>()
                              .addToQueue(plugin),
                      icon: Icon(isInQueue
                          ? Icons.remove_from_queue
                          : Icons.add_to_queue),
                      label: Text(
                          isInQueue ? 'Remove from Queue' : 'Add to Queue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInQueue
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: isInQueue
                            ? Theme.of(context).colorScheme.onError
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

