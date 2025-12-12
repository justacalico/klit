import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/debouncer.dart';
import '../../../data/models/models.dart';
import '../../../data/services/services.dart';
import '../../pages/post/post_detail_page.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../widgets/desktop_toolbar.dart';

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

class _DesktopSearchPageState extends State<DesktopSearchPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _tagDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
  int _gridColumns = 4;
  String? _selectedRating;
  String _selectedOrder = 'id_desc';
  bool _showFilters = false;
  
  // Animation for filters
  late AnimationController _filterAnimationController;
  late Animation<double> _filterSlideAnimation;
  late Animation<double> _filterFadeAnimation;
  
  // Tag suggestions
  List<Tag> _tagSuggestions = [];
  bool _showTagSuggestions = false;
  bool _isLoadingTags = false;

  final Map<String, String> _orderOptions = {
    'id_desc': 'Newest',
    'id_asc': 'Oldest',
    'score': 'Score',
    'favcount': 'Favorites',
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize filter animation
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _filterSlideAnimation = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(
        parent: _filterAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _filterFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _filterAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
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
    _filterAnimationController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _tagDebouncer.dispose();
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
      final words = text.split(' ');
      if (words.isNotEmpty) {
        words[words.length - 1] = tagName;
      } else {
        words.add(tagName);
      }
      _searchController.text = '${words.join(' ')} ';
    } else {
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
    
    _focusNode.requestFocus();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

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

    widget.onPostTap(PostDetailArguments(
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
    ));
  }

  void _loadMore() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final settingsProvider = context.read<SettingsProvider>();
    context.read<PostsProvider>().searchPosts(
          query: query,
          refresh: false,
          rating: _selectedRating,
          order: _selectedOrder,
          safeMode: settingsProvider.safeMode,
        );
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
          children: [
            _buildToolbar(context, isDark),
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
        ),
        // Floating filters panel with animation
        if (_showFilters || _filterAnimationController.isAnimating)
          AnimatedBuilder(
            animation: _filterAnimationController,
            builder: (context, child) {
              return Positioned(
                top: 60 + _filterSlideAnimation.value,
                left: 220,
                right: 20,
                child: Opacity(
                  opacity: _filterFadeAnimation.value,
                  child: _buildFilters(context, isDark),
                ),
              );
            },
          ),
        // Tag suggestions overlay
        if (_showTagSuggestions && _tagSuggestions.isNotEmpty)
          Positioned(
            top: 52, // Below toolbar
            left: 48, // Aligned with search field
            right: 150, // Leave space for buttons
            child: _buildTagSuggestions(isDark),
          ),
        // Loading indicator
        if (_isLoadingTags && !_showTagSuggestions)
          Positioned(
            top: 56,
            left: 48,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? CupertinoColors.black.withValues(alpha: 0.8)
                    : CupertinoColors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(radius: 8),
                  SizedBox(width: 8),
                  Text('Loading...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTagSuggestions(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 350),
      margin: const EdgeInsets.only(right: 100),
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
                        CupertinoColors.white.withValues(alpha: 0.95),
                        CupertinoColors.white.withValues(alpha: 0.9),
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
                      : CupertinoColors.black.withValues(alpha: 0.15),
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
                return _buildTagSuggestionItem(tag, isDark, index == _tagSuggestions.length - 1);
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
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: tag.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tag.name.replaceAll('_', ' '),
                style: TextStyle(
                  color: tag.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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

  Widget _buildToolbar(BuildContext context, bool isDark) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF18181B).withValues(alpha: 0.85),
                      const Color(0xFF1F1F23).withValues(alpha: 0.9),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.85),
                      const Color(0xFFFAFAFC).withValues(alpha: 0.9),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? DesktopToolbarColors.primaryPurple.withValues(alpha: 0.15)
                    : DesktopToolbarColors.primaryPurple.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Search icon with gradient
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DesktopToolbarColors.primaryIndigo,
                      DesktopToolbarColors.primaryPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: DesktopToolbarColors.primaryPurple.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.search,
                  size: 16,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CupertinoTextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  placeholder: 'Search tags...',
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
                  ),
                  placeholderStyle: TextStyle(
                    fontSize: 15,
                    color: isDark 
                        ? CupertinoColors.systemGrey 
                        : CupertinoColors.systemGrey2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF27272A).withValues(alpha: 0.6)
                        : const Color(0xFFF4F4F5).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? DesktopToolbarColors.primaryPurple.withValues(alpha: 0.2)
                          : DesktopToolbarColors.primaryPurple.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  onChanged: (value) {
                    if (value.endsWith(' ')) {
                      setState(() {
                        _showTagSuggestions = false;
                        _tagSuggestions = [];
                      });
                      return;
                    }
                    
                    final currentWord = _getCurrentWord();
                    _tagDebouncer.run(() {
                      _fetchTagSuggestions(currentWord);
                    });
                  },
                  onSubmitted: (_) {
                    setState(() {
                      _showTagSuggestions = false;
                      _tagSuggestions = [];
                    });
                    _performSearch();
                  },
                ),
              ),
              const SizedBox(width: 12),
              DesktopToolbarButton(
                icon: CupertinoIcons.search,
                tooltip: 'Search',
                onPressed: () {
                  setState(() {
                    _showTagSuggestions = false;
                    _tagSuggestions = [];
                  });
                  _performSearch();
                },
              ),
              const SizedBox(width: 8),
              DesktopToolbarButton(
                icon: _showFilters
                    ? CupertinoIcons.slider_horizontal_below_rectangle
                    : CupertinoIcons.slider_horizontal_3,
                tooltip: 'Toggle Filters',
                onPressed: _toggleFilters,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF18181B).withValues(alpha: 0.85),
                      const Color(0xFF1F1F23).withValues(alpha: 0.9),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                      const Color(0xFFF4F4F5).withValues(alpha: 0.95),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? DesktopToolbarColors.primaryPurple.withValues(alpha: 0.2)
                  : DesktopToolbarColors.primaryPurple.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? CupertinoColors.black.withValues(alpha: 0.4)
                    : CupertinoColors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: DesktopToolbarColors.primaryPurple.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Rating filter
                const Text('Rating:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CupertinoSlidingSegmentedControl<String>(
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
                ),
                const SizedBox(width: 24),
                // Order filter
                const Text('Sort:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CupertinoSlidingSegmentedControl<String>(
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
                ),
                const SizedBox(width: 24),
                // Grid size
                _buildGridSizeSelector(isDark),
              ],
            ),
          ),
        ),
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
                  onPressed: () {
                    context.read<SettingsProvider>().clearSearchHistory();
                  }, minimumSize: Size(0, 0),
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
