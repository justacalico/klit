import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/utils/debouncer.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../post/post_detail_page.dart';

/// Search page
class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  final _focusNode = FocusNode();
  
  bool _isGridView = true;
  bool _showHistory = true;
  String? _selectedRating;
  String _selectedOrder = 'id_desc';

  final List<String> _ratingOptions = ['Any', 's', 'q', 'e'];
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
      _showHistory = false;
      _performSearch();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _showHistory = true);
      return;
    }

    setState(() => _showHistory = false);
    
    final settingsProvider = context.read<SettingsProvider>();
    context.read<PostsProvider>().searchPosts(
      query: query,
      refresh: true,
      rating: _selectedRating,
      order: _selectedOrder,
      safeMode: settingsProvider.safeMode,
    );
    
    settingsProvider.addToSearchHistory(query);
  }

  void _onPostTap(Post post) {
    final postsProvider = context.read<PostsProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final posts = postsProvider.searchResults;
    final index = posts.indexWhere((p) => p.id == post.id);
    
    Navigator.of(context).pushNamed(
      AppRoutes.postDetail,
      arguments: PostDetailArguments(
        postIds: posts.map((p) => p.id).toList(),
        initialIndex: index >= 0 ? index : 0,
        hasMore: postsProvider.hasMoreSearch,
        onLoadMore: () async {
          await postsProvider.searchPosts(
            query: postsProvider.currentSearchQuery,
            rating: _selectedRating,
            order: _selectedOrder,
            safeMode: settingsProvider.safeMode,
          );
          return postsProvider.searchResults.map((p) => p.id).toList();
        },
      ),
    );
  }

  void _onHistoryItemTap(String query) {
    _searchController.text = query;
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = context.watch<SettingsProvider>().gridSize;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: _buildSearchField(),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: _showHistory
                  ? _buildSearchHistory()
                  : _buildSearchResults(gridSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return CupertinoSearchTextField(
      controller: _searchController,
      focusNode: _focusNode,
      placeholder: 'Search tags...',
      onChanged: (value) {
        _debouncer.run(() {
          if (value.isNotEmpty) {
            _performSearch();
          } else {
            setState(() => _showHistory = true);
          }
        });
      },
      onSubmitted: (_) => _performSearch(),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              'Rating: ${_selectedRating ?? 'Any'}',
              () => _showRatingPicker(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              'Sort: ${_orderOptions[_selectedOrder]}',
              () => _showOrderPicker(),
            ),
          ),
          const SizedBox(width: 8),
          ViewToggleButton(
            isGrid: _isGridView,
            onToggle: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_down, size: 14),
          ],
        ),
      ),
    );
  }

  void _showRatingPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Rating'),
        actions: _ratingOptions.map((rating) {
          final label = rating == 'Any'
              ? 'Any'
              : rating == 's'
                  ? 'Safe'
                  : rating == 'q'
                      ? 'Questionable'
                      : 'Explicit';
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedRating = rating == 'Any' ? null : rating;
              });
              if (!_showHistory) _performSearch();
            },
            child: Text(label),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showOrderPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Sort By'),
        actions: _orderOptions.entries.map((entry) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedOrder = entry.key;
              });
              if (!_showHistory) _performSearch();
            },
            child: Text(entry.value),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        if (settings.searchHistory.isEmpty) {
          return const EmptyState(
            icon: CupertinoIcons.clock,
            title: 'No Search History',
            message: 'Your recent searches will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: settings.searchHistory.length,
          itemBuilder: (context, index) {
            final item = settings.searchHistory[index];
            return CupertinoListTile(
              leading: const Icon(CupertinoIcons.clock),
              title: Text(item.query),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Could add delete individual history item
                },
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 18,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              onTap: () => _onHistoryItemTap(item.query),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(int gridSize) {
    return Consumer<PostsProvider>(
      builder: (context, postsProvider, _) {
        final settingsProvider = context.read<SettingsProvider>();
        return _isGridView
            ? PostsGrid(
                posts: postsProvider.searchResults,
                columns: gridSize,
                isLoading: postsProvider.isLoadingSearch,
                hasMore: postsProvider.hasMoreSearch,
                error: postsProvider.searchError,
                onPostTap: _onPostTap,
                onLoadMore: () {
                  postsProvider.searchPosts(
                    query: _searchController.text.trim(),
                    safeMode: settingsProvider.safeMode,
                  );
                },
                onRetry: _performSearch,
              )
            : PostsList(
                posts: postsProvider.searchResults,
                isLoading: postsProvider.isLoadingSearch,
                hasMore: postsProvider.hasMoreSearch,
                error: postsProvider.searchError,
                onPostTap: _onPostTap,
                onLoadMore: () {
                  postsProvider.searchPosts(
                    query: _searchController.text.trim(),
                    safeMode: settingsProvider.safeMode,
                  );
                },
                onRetry: _performSearch,
              );
      },
    );
  }
}
