import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/debouncer.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';
import '../../core/types/navigation_args.dart';
import '../../providers/providers.dart';
import '../layout/layout_scope.dart';
import '../shell/mobile_header.dart';
import '../widgets/widgets.dart';

/// Unified search page - reused from desktop search logic.
/// When [feedMode] is true, search toolbar and history are hidden (feed view).
/// When [onBack] is non-null (e.g. when shown as a route), toolbar shows a back button and no extra nav bar is needed.
class UiSearchPage extends StatefulWidget {
  final String? initialQuery;
  final bool feedMode;
  final void Function(PostDetailArguments) onPostTap;

  /// When set, toolbar shows a back button (e.g. when page is pushed as a route). Caller should not use a separate nav bar.
  final VoidCallback? onBack;

  /// When non-empty, search runs on each host and results are merged (multi-host feed).
  final List<String>? hostUrls;

  /// When in feed mode, title shown in the toolbar (e.g. feed name). Ignored when not feed mode.
  final String? feedTitle;
  /// Initial rating filter when opened as feed: null/'all', 's', 'q', 'e'.
  final String? initialRating;
  /// Initial sort order when opened as feed: e.g. 'id_desc', 'score'.
  final String? initialOrder;

  const UiSearchPage({
    super.key,
    this.initialQuery,
    this.feedMode = false,
    this.onBack,
    this.hostUrls,
    this.feedTitle,
    this.initialRating,
    this.initialOrder,
    required this.onPostTap,
  });

  @override
  State<UiSearchPage> createState() => _UiSearchPageState();
}

class _UiSearchPageState extends State<UiSearchPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _tagDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
  String? _selectedRating;
  String _selectedOrder = 'id_desc';
  bool _showFilters = false;
  String _currentTagPrefix = '';

  List<Tag> _tagSuggestions = [];
  bool _showTagSuggestions = false;

  late AnimationController _filterCtrl;
  late Animation<double> _filterSlide;
  late Animation<double> _filterFade;

  final Map<String, String> _orderOptions = {
    'id_desc': 'Newest',
    'id_asc': 'Oldest',
    'score': 'Score',
    'favcount': 'Favorites',
  };

  @override
  void initState() {
    super.initState();
    _filterCtrl = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _filterSlide = Tween<double>(
      begin: -20,
      end: 0,
    ).animate(CurvedAnimation(parent: _filterCtrl, curve: Curves.easeOutCubic));
    _filterFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _filterCtrl, curve: Curves.easeOutCubic));

    if (widget.initialRating != null) {
      _selectedRating = widget.initialRating == 'all' ? null : widget.initialRating;
    }
    if (widget.initialOrder != null) {
      _selectedOrder = widget.initialOrder!;
    }
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
    if (!widget.feedMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final mode = LayoutScope.maybeOf(context);
        if (mode != null && !mode.isMobile) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant UiSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _selectedRating = widget.initialRating == null || widget.initialRating == 'all'
          ? null
          : widget.initialRating;
    }
    if (oldWidget.initialOrder != widget.initialOrder && widget.initialOrder != null) {
      _selectedOrder = widget.initialOrder!;
    }
    if (oldWidget.initialQuery != widget.initialQuery &&
        widget.initialQuery != null &&
        widget.initialQuery != _searchController.text) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _tagDebouncer.dispose();
    super.dispose();
  }

  String _getCurrentWord() {
    final text = _searchController.text;
    final cursorPos = _searchController.selection.baseOffset;
    String rawWord;
    if (cursorPos < 0 || cursorPos > text.length) {
      rawWord = text.split(' ').last;
    } else {
      final before = text.substring(0, cursorPos);
      final words = before.split(' ');
      rawWord = words.isNotEmpty ? words.last : '';
    }
    if (rawWord.startsWith('-')) {
      _currentTagPrefix = '-';
      return rawWord.substring(1);
    } else if (rawWord.startsWith('~')) {
      _currentTagPrefix = '~';
      return rawWord.substring(1);
    } else {
      _currentTagPrefix = '';
      return rawWord;
    }
  }

  Future<void> _fetchTagSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      if (_showTagSuggestions) {
        setState(() {
          _tagSuggestions = [];
          _showTagSuggestions = false;
        });
      }
      return;
    }
    final api = context.read<ApiService>();
    final result = await api.searchTags(query: query, limit: 10);
    if (mounted) {
      result.when(
        success: (tags) {
          setState(() {
            _tagSuggestions = tags;
            _showTagSuggestions = tags.isNotEmpty;
          });
        },
        failure: (_) {
          setState(() {
            _tagSuggestions = [];
            _showTagSuggestions = false;
          });
        },
      );
    }
  }

  void _closeTagSuggestions() {
    if (_showTagSuggestions || _tagSuggestions.isNotEmpty) {
      setState(() {
        _showTagSuggestions = false;
        _tagSuggestions = [];
      });
    }
    _tagDebouncer.cancel();
  }

  void _insertTagSuggestion(String tagName) {
    final tagWithPrefix = '$_currentTagPrefix$tagName';
    final text = _searchController.text;
    final cursorPos = _searchController.selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) {
      final words = text.split(' ');
      if (words.isNotEmpty) {
        words[words.length - 1] = tagWithPrefix;
      } else {
        words.add(tagWithPrefix);
      }
      _searchController.text = '${words.join(' ')} ';
    } else {
      final before = text.substring(0, cursorPos);
      final after = text.substring(cursorPos);
      final lastSpace = before.lastIndexOf(' ');
      final newBefore = lastSpace >= 0
          ? '${before.substring(0, lastSpace + 1)}$tagWithPrefix '
          : '$tagWithPrefix ';
      _searchController.text = newBefore + after;
      _searchController.selection = TextSelection.collapsed(
        offset: newBefore.length,
      );
    }
    _closeTagSuggestions();
    _currentTagPrefix = '';
    _focusNode.requestFocus();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    _closeTagSuggestions();
    final sp = context.read<SettingsProvider>();
    final pp = context.read<PostsProvider>();
    final hostUrls = widget.hostUrls;
    if (hostUrls != null && hostUrls.isNotEmpty) {
      pp.searchPostsMultiHost(
        query: query,
        hostUrls: hostUrls,
        refresh: true,
        rating: _selectedRating,
        order: _selectedOrder,
        safeMode: sp.safeMode,
      );
    } else {
      pp.searchPosts(
        query: query,
        refresh: true,
        rating: _selectedRating,
        order: _selectedOrder,
        safeMode: sp.safeMode,
      );
    }
    if (!widget.feedMode) {
      sp.addToSearchHistory(query);
    }
  }

  void _onPostTap(Post post) {
    final pp = context.read<PostsProvider>();
    final sp = context.read<SettingsProvider>();
    final posts = pp.searchResults;
    final idx = posts.indexWhere((p) => p.id == post.id);
    final hostUrls = widget.hostUrls;
    final postHostUrls = pp.searchPostHostUrls;

    widget.onPostTap(
      PostDetailArguments(
        postIds: posts.map((p) => p.id).toList(),
        initialIndex: idx >= 0 ? idx : 0,
        hasMore: pp.hasMoreSearch,
        postHostUrls:
            (postHostUrls != null && postHostUrls.length == posts.length)
            ? postHostUrls
            : null,
        initialPosts: List<Post?>.from(posts),
        onLoadMore: () async {
          if (hostUrls != null && hostUrls.isNotEmpty) {
            await pp.searchPostsMultiHost(
              query: pp.currentSearchQuery,
              hostUrls: hostUrls,
              refresh: false,
              rating: _selectedRating,
              order: _selectedOrder,
              safeMode: sp.safeMode,
            );
          } else {
            await pp.searchPosts(
              query: pp.currentSearchQuery,
              rating: _selectedRating,
              order: _selectedOrder,
              safeMode: sp.safeMode,
            );
          }
          return pp.searchResults.map((p) => p.id).toList();
        },
      ),
    );
  }

  void _loadMore() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final sp = context.read<SettingsProvider>();
    final pp = context.read<PostsProvider>();
    final hostUrls = widget.hostUrls;
    if (hostUrls != null && hostUrls.isNotEmpty) {
      pp.searchPostsMultiHost(
        query: query,
        hostUrls: hostUrls,
        refresh: false,
        rating: _selectedRating,
        order: _selectedOrder,
        safeMode: sp.safeMode,
      );
    } else {
      pp.searchPosts(
        query: query,
        refresh: false,
        rating: _selectedRating,
        order: _selectedOrder,
        safeMode: sp.safeMode,
      );
    }
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterCtrl.forward();
    } else {
      _filterCtrl.reverse();
    }
  }

  void _showFiltersBottomSheet(BuildContext context, bool isDark) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        final isOled = ctx.watch<SettingsProvider>().themeMode == 3;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildFilters(ctx, isDark, vertical: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final isOled = context.watch<SettingsProvider>().themeMode == 3;
    final mode = LayoutScope.of(context);
    final isMobile = mode.isMobile;
    final feedMode = widget.feedMode;
    const stackedHeaderHeight = MobileHeaderHeights.large * 2;
    const feedHeaderHeight = MobileHeaderHeights.large;
    final tagSuggestionsTop = feedMode
        ? feedHeaderHeight + 2
        : stackedHeaderHeight + 2;

    return KeyedSubtree(
      key: const ValueKey('search-page'),
      child: Stack(
        children: [
          Column(
            children: [
              if (feedMode && widget.onBack != null)
                _buildFeedToolbar(context, isDark)
              else if (!feedMode) ...[
                _buildSearchTitleBar(context, isDark, isOled),
                _buildToolbar(context, isDark, isMobile),
              ],
              Expanded(
                child: feedMode
                    ? _buildResults(context)
                    : (isMobile
                          ? _buildResults(context)
                          : Row(
                              children: [
                                _buildHistorySidebar(context, isDark, isOled),
                                Container(
                                  width: 1,
                                  color: AppColors.resolveSeparator(
                                    isDark,
                                    isOled: isOled,
                                  ),
                                ),
                                Expanded(child: _buildResults(context)),
                              ],
                            )),
              ),
            ],
          ),
          if (!isMobile && (_showFilters || _filterCtrl.isAnimating))
            AnimatedBuilder(
              animation: _filterCtrl,
              builder: (_, _) => Positioned(
                top: stackedHeaderHeight + _filterSlide.value,
                left: 220,
                right: 20,
                child: Opacity(
                  opacity: _filterFade.value,
                  child: _buildFilters(context, isDark),
                ),
              ),
            ),
          if (_showTagSuggestions && _tagSuggestions.isNotEmpty)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeTagSuggestions,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    Positioned(
                      top: tagSuggestionsTop,
                      left: isMobile ? 16 : 48,
                      right: isMobile ? 16 : 150,
                      child: _buildTagSuggestions(isDark),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Toolbar for feed mode: back button + feed title so user can exit the feed.
  Widget _buildFeedToolbar(BuildContext context, bool isDark) {
    final title = widget.feedTitle?.isNotEmpty == true
        ? widget.feedTitle!
        : 'Feed';
    final isOled = context.watch<SettingsProvider>().themeMode == 3;
    return MobileHeaderSection(
      barHeight: MobileHeaderHeights.large,
      variant: MobileHeaderVariant.glass,
      isDark: isDark,
      isOled: isOled,
      applySafeTopInset: false,
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onBack,
            child: const Icon(CupertinoIcons.back),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTitleBar(BuildContext context, bool isDark, bool isOled) {
    return MobileHeader(
      title: 'Search',
      icon: CupertinoIcons.search,
      barHeight: MobileHeaderHeights.large,
      variant: MobileHeaderVariant.solid,
      isDark: isDark,
      isOled: isOled,
      applySafeTopInset: false,
    );
  }

  Widget _buildToolbar(BuildContext context, bool isDark, bool isMobile) {
    final isOled = context.watch<SettingsProvider>().themeMode == 3;
    return MobileHeaderSection(
      barHeight: MobileHeaderHeights.large,
      variant: MobileHeaderVariant.glass,
      isDark: isDark,
      isOled: isOled,
      applySafeTopInset: false,
      child: Row(
        children: [
          if (widget.onBack != null) ...[
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: widget.onBack,
              child: const Icon(CupertinoIcons.back),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
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
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                      : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              onChanged: (v) {
                if (v.isEmpty) {
                  _closeTagSuggestions();
                  return;
                }
                if (v.endsWith(' ')) {
                  _closeTagSuggestions();
                } else {
                  final w = _getCurrentWord();
                  if (w.length >= 2) {
                    _tagDebouncer.run(() => _fetchTagSuggestions(w));
                  } else {
                    _closeTagSuggestions();
                  }
                }
              },
              onSubmitted: (_) {
                _closeTagSuggestions();
                _performSearch();
              },
            ),
          ),
          const SizedBox(width: 12),
          _ToolbarBtn(
            icon: CupertinoIcons.search,
            onTap: () {
              _closeTagSuggestions();
              _performSearch();
            },
          ),
          const SizedBox(width: 8),
          _ToolbarBtn(
            icon: (isMobile ? false : _showFilters)
                ? CupertinoIcons.slider_horizontal_below_rectangle
                : CupertinoIcons.slider_horizontal_3,
            onTap: isMobile
                ? () => _showFiltersBottomSheet(context, isDark)
                : _toggleFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildTagSuggestions(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 350),
      margin: const EdgeInsets.only(right: 100),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.14)
                : CupertinoColors.white.withValues(alpha: 0.95),
            border: Border.all(
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.15)
                  : CupertinoColors.black.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _tagSuggestions.length,
            itemBuilder: (_, i) {
              final tag = _tagSuggestions[i];
              return GestureDetector(
                onTap: () => _insertTagSuggestion(tag.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: i < _tagSuggestions.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? CupertinoColors.white.withValues(alpha: 0.1)
                                  : CupertinoColors.black.withValues(
                                      alpha: 0.05,
                                    ),
                              width: 0.5,
                            ),
                          )
                        : null,
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
                        tag.postCount >= 1000000
                            ? '${(tag.postCount / 1000000).toStringAsFixed(1)}m'
                            : (tag.postCount >= 1000
                                  ? '${(tag.postCount / 1000).toStringAsFixed(1)}k'
                                  : '${tag.postCount}'),
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    bool isDark, {
    bool vertical = false,
  }) {
    final textColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final ratingControl = CupertinoSlidingSegmentedControl<String>(
      groupValue: _selectedRating ?? 'all',
      children: {
        'all': Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('All', style: TextStyle(fontSize: 12, color: textColor)),
        ),
        's': Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Safe', style: TextStyle(fontSize: 12, color: textColor)),
        ),
        'q': Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Questionable',
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ),
        'e': Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Explicit',
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ),
      },
      onValueChanged: (v) {
        setState(() => _selectedRating = v == 'all' ? null : v);
        if (_searchController.text.isNotEmpty) _performSearch();
      },
    );
    final sortControl = CupertinoSlidingSegmentedControl<String>(
      groupValue: _selectedOrder,
      children: {
        for (final e in _orderOptions.entries)
          e.key: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              e.value,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ),
      },
      onValueChanged: (v) {
        if (v != null) {
          setState(() => _selectedOrder = v);
          if (_searchController.text.isNotEmpty) _performSearch();
        }
      },
    );

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Rating', style: TextStyle(fontSize: 13, color: textColor)),
          const SizedBox(height: 8),
          ratingControl,
          const SizedBox(height: 20),
          Text('Sort', style: TextStyle(fontSize: 13, color: textColor)),
          const SizedBox(height: 8),
          sortControl,
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF18181B).withValues(alpha: 0.85)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
              : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text('Rating:', style: TextStyle(fontSize: 13, color: textColor)),
            const SizedBox(width: 8),
            ratingControl,
            const SizedBox(width: 24),
            Text('Sort:', style: TextStyle(fontSize: 13, color: textColor)),
            const SizedBox(width: 8),
            sortControl,
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySidebar(BuildContext context, bool isDark, bool isOled) {
    return Container(
      width: 200,
      color: AppColors.resolveScaffoldBackground(isDark, isOled: isOled),
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
                  minimumSize: Size.zero,
                  onPressed: () =>
                      context.read<SettingsProvider>().clearSearchHistory(),
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
              builder: (_, sp, _) {
                final history = sp.searchHistory;
                if (history.isEmpty) {
                  return Center(
                    child: Text(
                      'No recent searches',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (_, i) {
                    final item = history[i];
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
      builder: (_, pp, _) {
        if (pp.searchResults.isEmpty && !pp.isLoadingSearch) {
          if (widget.feedMode) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.rectangle_stack_fill,
                    size: 64,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts in this feed',
                    style: TextStyle(
                      fontSize: 18,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
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
        if (pp.searchResults.isEmpty && pp.isLoadingSearch && widget.feedMode) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(radius: 16),
                const SizedBox(height: 16),
                Text(
                  'Loading feed…',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollEndNotification) {
              final m = n.metrics;
              if (m.pixels >= m.maxScrollExtent - 200 &&
                  pp.hasMoreSearch &&
                  !pp.isLoadingSearch) {
                _loadMore();
              }
            }
            return false;
          },
          child: PostsGrid(
            posts: pp.searchResults,
            isLoading: pp.isLoadingSearch,
            hasMore: pp.hasMoreSearch,
            error: pp.searchError,
            onPostTap: _onPostTap,
            onLoadMore: _loadMore,
            onRetry: _performSearch,
          ),
        );
      },
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final isOled = context.watch<SettingsProvider>().themeMode == 3;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark || isOled)
              ? AppColors.resolveSecondaryBackground(
                  isDark,
                  isOled: isOled,
                ).withValues(alpha: 0.6)
              : const Color(0xFFF3F4F6).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
