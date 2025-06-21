import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/models/marketplace_models.dart';
import 'package:nt_helper/services/marketplace_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/ui/marketplace/marketplace_cubit.dart';

/// A beautiful marketplace screen for discovering and installing plugins
class MarketplaceScreen extends StatelessWidget {
  final DistingCubit distingCubit;
  final MarketplaceService marketplaceService;

  const MarketplaceScreen({
    super.key,
    required this.distingCubit,
    required this.marketplaceService,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MarketplaceCubit(marketplaceService)..loadMarketplace(),
      child: _MarketplaceView(
        distingCubit: distingCubit,
        marketplaceService: marketplaceService,
      ),
    );
  }
}

class _MarketplaceView extends StatefulWidget {
  final DistingCubit distingCubit;
  final MarketplaceService marketplaceService;

  const _MarketplaceView({
    required this.distingCubit,
    required this.marketplaceService,
  });

  @override
  State<_MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<_MarketplaceView>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  // UI state
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to search changes
    _searchController.addListener(() {
      context.read<MarketplaceCubit>().applyFilters(
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
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              _buildHeader(state),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMarketplaceTab(state),
                    _buildQueueTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(MarketplaceState state) {
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
          if (state is MarketplaceLoaded) ...[
            const SizedBox(height: 8),
            Text(
              state.marketplace.metadata.description,
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

  Widget _buildHeaderActions(MarketplaceState state) {
    final queueCount = state is MarketplaceLoaded ? state.queue.length : 0;

    return Row(
      children: [
        Badge(
          isLabelVisible: queueCount > 0,
          label: Text('$queueCount'),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              _tabController.animateTo(1);
            },
            tooltip: 'Install Queue ($queueCount)',
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context
              .read<MarketplaceCubit>()
              .loadMarketplace(forceRefresh: true),
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _showSettingsDialog,
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
            icon: BlocBuilder<MarketplaceCubit, MarketplaceState>(
              builder: (context, state) {
                final queueCount =
                    state is MarketplaceLoaded ? state.queue.length : 0;
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

  Widget _buildMarketplaceTab(MarketplaceState state) {
    if (state is MarketplaceInitial) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is MarketplaceLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading marketplace...'),
          ],
        ),
      );
    } else if (state is MarketplaceLoaded) {
      return Column(
        children: [
          _buildSearchAndFilters(state),
          Expanded(
            child: _buildPluginGrid(state),
          ),
        ],
      );
    } else if (state is MarketplaceError) {
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
              'Failed to load marketplace',
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
                  .read<MarketplaceCubit>()
                  .loadMarketplace(forceRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSearchAndFilters(MarketplaceState state) {
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
                        context.read<MarketplaceCubit>().clearFilters();
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
              if (state is MarketplaceLoaded &&
                  state.marketplace.categories.isNotEmpty)
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
                    context.read<MarketplaceCubit>().applyFilters(
                          category: value,
                        );
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...(state is MarketplaceLoaded
                            ? state.marketplace.categories
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
              PopupMenuButton<MarketplacePluginType?>(
                child: Chip(
                  avatar: Icon(
                    Icons.extension,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                  label: Text(state is MarketplaceLoaded
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
                  context.read<MarketplaceCubit>().applyFilters(
                        type: value,
                      );
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<MarketplacePluginType?>(
                    value: null,
                    child: Text('All Types'),
                  ),
                  ...MarketplacePluginType.values.map(
                    (type) => PopupMenuItem<MarketplacePluginType>(
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
                  color: (state is MarketplaceLoaded && state.showFeaturedOnly)
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                ),
                label: const Text('Featured'),
                selected:
                    state is MarketplaceLoaded ? state.showFeaturedOnly : false,
                selectedColor: Theme.of(context).colorScheme.primary,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: (state is MarketplaceLoaded && state.showFeaturedOnly)
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                ),
                onSelected: (selected) {
                  context.read<MarketplaceCubit>().applyFilters(
                        featured: selected,
                      );
                },
              ),

              // Verified filter
              FilterChip(
                avatar: Icon(
                  Icons.verified,
                  size: 18,
                  color: (state is MarketplaceLoaded && state.showVerifiedOnly)
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                ),
                label: const Text('Verified'),
                selected:
                    state is MarketplaceLoaded ? state.showVerifiedOnly : false,
                selectedColor: Theme.of(context).colorScheme.primary,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: (state is MarketplaceLoaded && state.showVerifiedOnly)
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                ),
                onSelected: (selected) {
                  context.read<MarketplaceCubit>().applyFilters(
                        verified: selected,
                      );
                },
              ),

              // Clear filters
              if (state is MarketplaceLoaded &&
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
                    context.read<MarketplaceCubit>().clearFilters();
                  },
                ),
            ],
          ),

          // Results count
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                state is MarketplaceLoaded
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

  Widget _buildPluginGrid(MarketplaceState state) {
    final filteredPlugins = state is MarketplaceLoaded
        ? state.filteredPlugins
        : <MarketplacePlugin>[];

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

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.67, // Makes cards 1.5x taller than wide
      ),
      itemCount: filteredPlugins.length,
      itemBuilder: (context, index) {
        return _buildPluginCard(filteredPlugins[index], state);
      },
    );
  }

  int _getCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildPluginCard(MarketplacePlugin plugin, MarketplaceState state) {
    if (state is! MarketplaceLoaded) return const SizedBox.shrink();

    final author = plugin.getAuthor(state.marketplace);
    final category = plugin.getCategory(state.marketplace);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPluginDetails(plugin),
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
                            if (plugin.featured)
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            if (plugin.verified) ...[
                              if (plugin.featured) const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                            if (plugin.featured || plugin.verified)
                              const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                plugin.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
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

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plugin.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (author != null) ...[
                      Row(
                        children: [
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
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.download,
                          size: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plugin.formattedDownloads,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          plugin.formattedRating,
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
                    const Spacer(),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: BlocBuilder<MarketplaceCubit, MarketplaceState>(
                        builder: (context, state) {
                          final queue = state is MarketplaceLoaded
                              ? state.queue
                              : <QueuedPlugin>[];
                          final isInQueue =
                              queue.any((q) => q.plugin.id == plugin.id);

                          return ElevatedButton.icon(
                            onPressed: isInQueue
                                ? () => context
                                    .read<MarketplaceCubit>()
                                    .removeFromQueue(plugin.id)
                                : () => context
                                    .read<MarketplaceCubit>()
                                    .addToQueue(plugin),
                            icon: Icon(isInQueue
                                ? Icons.remove_shopping_cart
                                : Icons.add_shopping_cart),
                            label: Text(isInQueue ? 'Remove' : 'Add to Queue'),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTab() {
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, state) {
        final queue =
            state is MarketplaceLoaded ? state.queue : <QueuedPlugin>[];

        if (queue.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
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
                        ? () => context.read<MarketplaceCubit>().clearQueue()
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
    return BlocBuilder<MarketplaceCubit, MarketplaceState>(
      builder: (context, state) {
        if (state is! MarketplaceLoaded) return const SizedBox.shrink();

        final author = plugin.getAuthor(state.marketplace);

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
            trailing: queuedPlugin.status == QueuedPluginStatus.queued
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context
                        .read<MarketplaceCubit>()
                        .removeFromQueue(plugin.id),
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

  IconData _getPluginIcon(MarketplacePluginType type) {
    switch (type) {
      case MarketplacePluginType.lua:
        return Icons.code;
      case MarketplacePluginType.threepot:
        return Icons.tune;
      case MarketplacePluginType.cpp:
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

  void _showPluginDetails(MarketplacePlugin plugin) {
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<MarketplaceCubit, MarketplaceState>(
        builder: (context, state) {
          if (state is! MarketplaceLoaded) return const SizedBox.shrink();

          return _PluginDetailsDialog(
            plugin: plugin,
            marketplace: state.marketplace,
            marketplaceService: widget.marketplaceService,
          );
        },
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => _MarketplaceSettingsDialog(
        marketplaceService: widget.marketplaceService,
      ),
    );
  }

  Future<void> _installQueue() async {
    try {
      await widget.marketplaceService.installQueuedPlugins(
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
}

// Plugin details dialog
class _PluginDetailsDialog extends StatelessWidget {
  final MarketplacePlugin plugin;
  final Marketplace marketplace;
  final MarketplaceService marketplaceService;

  const _PluginDetailsDialog({
    required this.plugin,
    required this.marketplace,
    required this.marketplaceService,
  });

  @override
  Widget build(BuildContext context) {
    final author = plugin.getAuthor(marketplace);
    final category = plugin.getCategory(marketplace);

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
                          if (plugin.featured)
                            Icon(
                              Icons.star,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          if (plugin.verified) ...[
                            if (plugin.featured) const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                          if (plugin.featured || plugin.verified)
                            const SizedBox(width: 8),
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
                BlocBuilder<MarketplaceCubit, MarketplaceState>(
                  builder: (context, state) {
                    final queue = state is MarketplaceLoaded
                        ? state.queue
                        : <QueuedPlugin>[];
                    final isInQueue =
                        queue.any((q) => q.plugin.id == plugin.id);

                    return ElevatedButton.icon(
                      onPressed: isInQueue
                          ? () => context
                              .read<MarketplaceCubit>()
                              .removeFromQueue(plugin.id)
                          : () => context
                              .read<MarketplaceCubit>()
                              .addToQueue(plugin),
                      icon: Icon(isInQueue
                          ? Icons.remove_shopping_cart
                          : Icons.add_shopping_cart),
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

// Marketplace settings dialog
class _MarketplaceSettingsDialog extends StatefulWidget {
  final MarketplaceService marketplaceService;

  const _MarketplaceSettingsDialog({
    required this.marketplaceService,
  });

  @override
  State<_MarketplaceSettingsDialog> createState() =>
      _MarketplaceSettingsDialogState();
}

class _MarketplaceSettingsDialogState
    extends State<_MarketplaceSettingsDialog> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: widget.marketplaceService.marketplaceUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Marketplace Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Marketplace URL',
              hintText: 'Enter the URL to the marketplace JSON file',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.marketplaceService.setMarketplaceUrl(_urlController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
