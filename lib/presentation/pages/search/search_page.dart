import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../core/utils/debouncer.dart';
import '../../../data/models/models.dart';
import '../../../data/services/services.dart';
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
  final _tagDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final _focusNode = FocusNode();

  bool _isGridView = true;
  bool _showHistory = true;
  bool _showTagSuggestions = false;
  List<Tag> _tagSuggestions = [];
  bool _isLoadingTags = false;
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
    _tagDebouncer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Get the current word being typed (after the last space)
  String _getCurrentWord() {
    final text = _searchController.text;
    final cursorPos = _searchController.selection.baseOffset;
    if (cursorPos < 0) return text.split(' ').last;

    final textBeforeCursor = text.substring(0, cursorPos);
    final words = textBeforeCursor.split(' ');
    return words.isNotEmpty ? words.last : '';
  }

  /// Fetch tag suggestions from the API
  Future<void> _fetchTagSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _tagSuggestions = [];
        _showTagSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingTags = true);

    final apiService = context.read<ApiService>();
    final result = await apiService.searchTags(query: query, limit: 10);

    if (mounted) {
      result.when(
        success: (tags) {
          setState(() {
            _tagSuggestions = tags;
            _showTagSuggestions = tags.isNotEmpty;
            _isLoadingTags = false;
          });
        },
        failure: (_) {
          setState(() {
            _tagSuggestions = [];
            _showTagSuggestions = false;
            _isLoadingTags = false;
          });
        },
      );
    }
  }

  /// Insert a tag suggestion into the search field
  void _insertTagSuggestion(String tagName) {
    final text = _searchController.text;
    final cursorPos = _searchController.selection.baseOffset;

    if (cursorPos < 0) {
      // Simple case: just append
      final words = text.split(' ');
      if (words.isNotEmpty) {
        words[words.length - 1] = tagName;
      } else {
        words.add(tagName);
      }
      _searchController.text = '${words.join(' ')} ';
    } else {
      // Replace the current word being typed
      final textBeforeCursor = text.substring(0, cursorPos);
      final textAfterCursor = text.substring(cursorPos);

      final lastSpaceIndex = textBeforeCursor.lastIndexOf(' ');
      final newTextBeforeCursor = lastSpaceIndex >= 0
          ? '${textBeforeCursor.substring(0, lastSpaceIndex + 1)}$tagName '
          : '$tagName ';

      _searchController.text = newTextBeforeCursor + textAfterCursor;
      _searchController.selection = TextSelection.collapsed(
        offset: newTextBeforeCursor.length,
      );
    }

    setState(() {
      _showTagSuggestions = false;
      _tagSuggestions = [];
    });
  }

  /// Check if safe mode should be enforced (guest mode OR safe mode setting)
  bool _shouldEnforceSafeMode(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    return authProvider.isGuest || settingsProvider.safeMode;
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _showHistory = true);
      return;
    }

    setState(() => _showHistory = false);

    final settingsProvider = context.read<SettingsProvider>();
    final safeMode = _shouldEnforceSafeMode(context);
    context.read<PostsProvider>().searchPosts(
      query: query,
      refresh: true,
      rating: _selectedRating,
      order: _selectedOrder,
      safeMode: safeMode,
    );

    settingsProvider.addToSearchHistory(query);
  }

  void _onPostTap(Post post) {
    final postsProvider = context.read<PostsProvider>();
    final posts = postsProvider.searchResults;
    final index = posts.indexWhere((p) => p.id == post.id);
    final safeMode = _shouldEnforceSafeMode(context);

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
            safeMode: safeMode,
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
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

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
        child: Stack(
          children: [
            Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _showHistory
                      ? _buildSearchHistory()
                      : _buildSearchResults(gridSize),
                ),
              ],
            ),
            // Tag suggestions overlay
            if (_showTagSuggestions && _tagSuggestions.isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTagSuggestions(),
              ),
            // Loading indicator for tags
            if (_isLoadingTags && !_showTagSuggestions)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.black.withValues(alpha: 0.7)
                          : CupertinoColors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoActivityIndicator(),
                        SizedBox(width: 8),
                        Text(
                          'Loading suggestions...',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSuggestions() {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      constraints: const BoxConstraints(maxHeight: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        CupertinoColors.white.withValues(alpha: 0.14),
                        CupertinoColors.white.withValues(alpha: 0.08),
                      ]
                    : [
                        CupertinoColors.white.withValues(alpha: 0.9),
                        CupertinoColors.white.withValues(alpha: 0.8),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.15)
                    : CupertinoColors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? CupertinoColors.black.withValues(alpha: 0.4)
                      : CupertinoColors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _tagSuggestions.length,
              itemBuilder: (context, index) {
                final tag = _tagSuggestions[index];
                return _buildTagSuggestionItem(
                  tag,
                  isDark,
                  index == _tagSuggestions.length - 1,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagSuggestionItem(Tag tag, bool isDark, bool isLast) {
    return GestureDetector(
      onTap: () => _insertTagSuggestion(tag.name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.1)
                        : CupertinoColors.black.withValues(alpha: 0.05),
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            // Tag category indicator
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: tag.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Tag name
            Expanded(
              child: Text(
                tag.name.replaceAll('_', ' '),
                style: TextStyle(
                  color: tag.color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Post count
            Text(
              _formatCount(tag.postCount),
              style: TextStyle(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.5)
                    : CupertinoColors.black.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}m';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  Widget _buildSearchField() {
    return CupertinoSearchTextField(
      controller: _searchController,
      focusNode: _focusNode,
      placeholder: 'Search tags...',
      onChanged: (value) {
        // Close suggestions if user typed a space (completed a tag)
        if (value.endsWith(' ')) {
          setState(() {
            _showTagSuggestions = false;
            _tagSuggestions = [];
          });
          return;
        }

        // Fetch tag suggestions for the current word
        final currentWord = _getCurrentWord();
        _tagDebouncer.run(() {
          _fetchTagSuggestions(currentWord);
        });

        // Perform search after debounce
        _debouncer.run(() {
          if (value.isNotEmpty) {
            _performSearch();
          } else {
            setState(() => _showHistory = true);
          }
        });
      },
      onSubmitted: (_) {
        setState(() {
          _showTagSuggestions = false;
          _tagSuggestions = [];
        });
        _performSearch();
      },
    );
  }

  Widget _buildFilters() {
    final isGuest = context.read<AuthProvider>().isGuest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              // In guest mode, always show 'Safe' and disable the picker
              isGuest ? 'Rating: Safe' : 'Rating: ${_selectedRating ?? 'Any'}',
              isGuest ? null : () => _showRatingPicker(),
              disabled: isGuest,
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

  Widget _buildFilterChip(
    String label,
    VoidCallback? onTap, {
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: disabled
              ? CupertinoColors.systemGrey4.resolveFrom(context)
              : CupertinoColors.systemGrey5.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: disabled
                      ? CupertinoColors.systemGrey.resolveFrom(context)
                      : null,
                ),
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
