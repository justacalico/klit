import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../pages/post/post_detail_page.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Desktop search page with advanced filters
class DesktopSearchPage extends StatefulWidget {
  final String? initialQuery;
  final Function(PostDetailArguments) onPostTap;

  const DesktopSearchPage({
    super.key,
    this.initialQuery,
    required this.onPostTap,
  });

  @override
  State<DesktopSearchPage> createState() => _DesktopSearchPageState();
}

class _DesktopSearchPageState extends State<DesktopSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  int _gridColumns = 4;
  String? _selectedRating;
  String _selectedOrder = 'id_desc';
  bool _showFilters = true;

  final Map<String, String> _orderOptions = {
    'id_desc': 'Newest',
    'id_asc': 'Oldest',
    'score': 'Score',
    'favcount': 'Favorites',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    context.read<PostsProvider>().searchPosts(
          query: query,
          refresh: true,
          rating: _selectedRating,
          order: _selectedOrder,
        );

    context.read<SettingsProvider>().addToSearchHistory(query);
  }

  void _onPostTap(Post post) {
    final postsProvider = context.read<PostsProvider>();
    final posts = postsProvider.searchResults;
    final index = posts.indexWhere((p) => p.id == post.id);

    widget.onPostTap(PostDetailArguments(
      postIds: posts.map((p) => p.id).toList(),
      initialIndex: index >= 0 ? index : 0,
    ));
  }

  void _loadMore() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    context.read<PostsProvider>().searchPosts(
          query: query,
          refresh: false,
          rating: _selectedRating,
          order: _selectedOrder,
        );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Column(
      children: [
        _buildToolbar(context, isDark),
        if (_showFilters) _buildFilters(context, isDark),
        Expanded(
          child: Row(
            children: [
              // Search history sidebar
              _buildHistorySidebar(context, isDark),
              Container(
                width: 1,
                color: isDark
                    ? AppColors.darkSeparator
                    : AppColors.lightSeparator,
              ),
              // Results
              Expanded(
                child: _buildResults(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, bool isDark) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSecondaryBackground
            : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkSeparator : AppColors.lightSeparator,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.search),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: _searchController,
              focusNode: _focusNode,
              placeholder: 'Search tags...',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: _performSearch,
            child: const Text('Search'),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            child: Icon(
              _showFilters
                  ? CupertinoIcons.slider_horizontal_below_rectangle
                  : CupertinoIcons.slider_horizontal_3,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSecondaryBackground.withOpacity(0.5)
            : CupertinoColors.systemGrey6,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkSeparator : AppColors.lightSeparator,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Rating filter
          const Text('Rating:', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          CupertinoSlidingSegmentedControl<String>(
            groupValue: _selectedRating ?? 'all',
            children: const {
              'all': Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('All', style: TextStyle(fontSize: 12)),
              ),
              's': Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Safe', style: TextStyle(fontSize: 12)),
              ),
              'q': Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Questionable', style: TextStyle(fontSize: 12)),
              ),
              'e': Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Explicit', style: TextStyle(fontSize: 12)),
              ),
            },
            onValueChanged: (value) {
              setState(() => _selectedRating = value == 'all' ? null : value);
              if (_searchController.text.isNotEmpty) {
                _performSearch();
              }
            },
          ),
          const SizedBox(width: 24),
          // Order filter
          const Text('Sort:', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          CupertinoSlidingSegmentedControl<String>(
            groupValue: _selectedOrder,
            children: {
              for (final entry in _orderOptions.entries)
                entry.key: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(entry.value, style: const TextStyle(fontSize: 12)),
                ),
            },
            onValueChanged: (value) {
              if (value != null) {
                setState(() => _selectedOrder = value);
                if (_searchController.text.isNotEmpty) {
                  _performSearch();
                }
              }
            },
          ),
          const Spacer(),
          // Grid size
          _buildGridSizeSelector(isDark),
        ],
      ),
    );
  }

  Widget _buildHistorySidebar(BuildContext context, bool isDark) {
    return Container(
      width: 200,
      color: isDark ? AppColors.darkBackground : CupertinoColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'History',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () {
                    context.read<SettingsProvider>().clearSearchHistory();
                  },
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                final history = settings.searchHistory;
                if (history.isEmpty) {
                  return Center(
                    child: Text(
                      'No recent searches',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      onPressed: () {
                        _searchController.text = item.query;
                        _performSearch();
                      },
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.clock,
                            size: 14,
                            color: CupertinoColors.secondaryLabel,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.query,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return Consumer<PostsProvider>(
      builder: (context, postsProvider, _) {
        if (postsProvider.searchResults.isEmpty &&
            !postsProvider.isLoadingSearch) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.search,
                  size: 64,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Search for posts',
                  style: TextStyle(
                    fontSize: 18,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter tags to find posts',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                if (postsProvider.hasMoreSearch &&
                    !postsProvider.isLoadingSearch) {
                  _loadMore();
                }
              }
            }
            return false;
          },
          child: PostsGrid(
            posts: postsProvider.searchResults,
            columns: _gridColumns,
            isLoading: postsProvider.isLoadingSearch,
            hasMore: postsProvider.hasMoreSearch,
            error: postsProvider.searchError,
            onPostTap: _onPostTap,
            onLoadMore: _loadMore,
            onRetry: _performSearch,
          ),
        );
      },
    );
  }

  Widget _buildGridSizeSelector(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          CupertinoIcons.square_grid_2x2,
          size: 16,
          color: CupertinoColors.secondaryLabel,
        ),
        const SizedBox(width: 8),
        CupertinoSlidingSegmentedControl<int>(
          groupValue: _gridColumns,
          children: const {
            2: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('2', style: TextStyle(fontSize: 12)),
            ),
            3: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('3', style: TextStyle(fontSize: 12)),
            ),
            4: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('4', style: TextStyle(fontSize: 12)),
            ),
            5: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('5', style: TextStyle(fontSize: 12)),
            ),
          },
          onValueChanged: (value) {
            if (value != null) {
              setState(() => _gridColumns = value);
            }
          },
        ),
      ],
    );
  }
}
