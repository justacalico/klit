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

/// Design constants for the purple/indigo mobile theme
class _ThemeColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
}

/// Search page
class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with RouteAware {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  final _tagDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final _focusNode = FocusNode();

  bool _showHistory = true;
  bool _showTagSuggestions = false;
  List<Tag> _tagSuggestions = [];
  bool _isLoadingTags = false;
  String? _selectedRating;
  String _selectedOrder = 'id_desc';

  // Route observer for detecting navigation events
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

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
    // Listen for focus changes to close tag suggestions
    _focusNode.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _showTagSuggestions) {
      setState(() {
        _showTagSuggestions = false;
        _tagSuggestions = [];
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _focusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _debouncer.dispose();
    _tagDebouncer.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this page from another page
    // Re-enable the search field by requesting focus after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_focusNode.hasFocus) {
        // Don't auto-focus, just ensure the field is interactive
        // User can tap to focus if they want
      }
    });
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
    // Don't fetch or show suggestions if not focused
    if (!_focusNode.hasFocus) {
      setState(() {
        _tagSuggestions = [];
        _showTagSuggestions = false;
      });
      return;
    }

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

    if (mounted && _focusNode.hasFocus) {
      result.when(
        success: (tags) {
          setState(() {
            _tagSuggestions = tags;
            _showTagSuggestions = tags.isNotEmpty && _focusNode.hasFocus;
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
    } else if (mounted) {
      setState(() {
        _tagSuggestions = [];
        _showTagSuggestions = false;
        _isLoadingTags = false;
      });
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

    // Close tag suggestions and history when searching
    setState(() {
      _showHistory = false;
      _showTagSuggestions = false;
      _tagSuggestions = [];
    });

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
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.85)
            : CupertinoColors.white.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? _ThemeColors.primaryPurple.withValues(alpha: 0.15)
                : _ThemeColors.primaryPurple.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _ThemeColors.primaryIndigo,
                    _ThemeColors.primaryPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: _ThemeColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.search,
                size: 14,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Search'),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: _ThemeColors.primaryPurple,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Search field in body for better focus handling
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _buildSearchField(),
                ),
                _buildFilters(),
                Expanded(
                  child: _showHistory
                      ? _buildSearchHistory()
                      : _buildSearchResults(),
                ),
              ],
            ),
            // Tag suggestions overlay - adjusted position
            if (_showTagSuggestions && _tagSuggestions.isNotEmpty && _focusNode.hasFocus)
              Positioned(
                top: 56, // Below search field
                left: 0,
                right: 0,
                child: _buildTagSuggestions(),
              ),
            // Loading indicator for tags
            if (_isLoadingTags && !_showTagSuggestions)
              Positioned(
                top: 64,
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
        // Cancel any pending tag fetches
        _tagDebouncer.cancel();
        setState(() {
          _showTagSuggestions = false;
          _tagSuggestions = [];
          _isLoadingTags = false;
        });
        // Unfocus to ensure suggestions stay closed
        _focusNode.unfocus();
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    VoidCallback? onTap, {
    bool disabled = false,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: disabled
              ? (isDark
                  ? const Color(0xFF2C2C2E).withValues(alpha: 0.4)
                  : CupertinoColors.systemGrey4.resolveFrom(context))
              : (isDark
                  ? const Color(0xFF2C2C2E).withValues(alpha: 0.6)
                  : const Color(0xFFF3F4F6).withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: disabled
                ? Colors.transparent
                : (isDark
                    ? _ThemeColors.primaryPurple.withValues(alpha: 0.2)
                    : _ThemeColors.primaryPurple.withValues(alpha: 0.1)),
            width: 1,
          ),
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
                      : (isDark
                          ? CupertinoColors.white.withValues(alpha: 0.8)
                          : const Color(0xFF374151)),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down, 
              size: 14,
              color: disabled
                  ? CupertinoColors.systemGrey.resolveFrom(context)
                  : _ThemeColors.primaryPurple.withValues(alpha: 0.7),
            ),
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

  Widget _buildSearchResults() {
    return Consumer<PostsProvider>(
      builder: (context, postsProvider, _) {
        final settingsProvider = context.read<SettingsProvider>();
        return PostsGrid(
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
