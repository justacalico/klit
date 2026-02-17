import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/debouncer.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';
import '../../presentation/pages/post/post_detail_page.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/widgets/widgets.dart';

/// Unified search page - reused from desktop search logic.
class UiSearchPage extends StatefulWidget {
  final String? initialQuery;
  final void Function(PostDetailArguments) onPostTap;

  const UiSearchPage({
    super.key,
    this.initialQuery,
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
    _filterCtrl = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    _filterSlide = Tween<double>(begin: -20, end: 0).animate(CurvedAnimation(parent: _filterCtrl, curve: Curves.easeOutCubic));
    _filterFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _filterCtrl, curve: Curves.easeOutCubic));

    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
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
      if (words.isNotEmpty) words[words.length - 1] = tagWithPrefix;
      else words.add(tagWithPrefix);
      _searchController.text = '${words.join(' ')} ';
    } else {
      final before = text.substring(0, cursorPos);
      final after = text.substring(cursorPos);
      final lastSpace = before.lastIndexOf(' ');
      final newBefore = lastSpace >= 0
          ? '${before.substring(0, lastSpace + 1)}$tagWithPrefix '
          : '$tagWithPrefix ';
      _searchController.text = newBefore + after;
      _searchController.selection = TextSelection.collapsed(offset: newBefore.length);
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
    context.read<PostsProvider>().searchPosts(
      query: query,
      refresh: true,
      rating: _selectedRating,
      order: _selectedOrder,
      safeMode: sp.safeMode,
    );
    sp.addToSearchHistory(query);
  }

  void _onPostTap(Post post) {
    final pp = context.read<PostsProvider>();
    final sp = context.read<SettingsProvider>();
    final posts = pp.searchResults;
    final idx = posts.indexWhere((p) => p.id == post.id);

    widget.onPostTap(PostDetailArguments(
      postIds: posts.map((p) => p.id).toList(),
      initialIndex: idx >= 0 ? idx : 0,
      hasMore: pp.hasMoreSearch,
      onLoadMore: () async {
        await pp.searchPosts(
          query: pp.currentSearchQuery,
          rating: _selectedRating,
          order: _selectedOrder,
          safeMode: sp.safeMode,
        );
        return pp.searchResults.map((p) => p.id).toList();
      },
    ));
  }

  void _loadMore() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final sp = context.read<SettingsProvider>();
    context.read<PostsProvider>().searchPosts(
      query: query,
      refresh: false,
      rating: _selectedRating,
      order: _selectedOrder,
      safeMode: sp.safeMode,
    );
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) _filterCtrl.forward();
    else _filterCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Stack(
      children: [
        Column(
          children: [
            _buildToolbar(context, isDark),
            Expanded(
              child: Row(
                children: [
                  _buildHistorySidebar(context, isDark),
                  Container(width: 1, color: isDark ? AppColors.darkSeparator : AppColors.lightSeparator),
                  Expanded(child: _buildResults(context)),
                ],
              ),
            ),
          ],
        ),
        if (_showFilters || _filterCtrl.isAnimating)
          AnimatedBuilder(
            animation: _filterCtrl,
            builder: (_, __) => Positioned(
              top: 60 + _filterSlide.value,
              left: 220,
              right: 20,
              child: Opacity(opacity: _filterFade.value, child: _buildFilters(context, isDark)),
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
                    top: 52,
                    left: 48,
                    right: 150,
                    child: _buildTagSuggestions(isDark),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, bool isDark) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF18181B).withValues(alpha: 0.85), const Color(0xFF1F1F23).withValues(alpha: 0.9)]
              : [const Color(0xFFFFFFFF).withValues(alpha: 0.85), const Color(0xFFFAFAFC).withValues(alpha: 0.9)],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF3A3A3C).withValues(alpha: 0.5) : const Color(0xFFE5E5E7).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
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
            child: const Icon(CupertinoIcons.search, size: 16, color: CupertinoColors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: CupertinoTextField(
              controller: _searchController,
              focusNode: _focusNode,
              placeholder: 'Search tags...',
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              style: TextStyle(fontSize: 15, color: isDark ? CupertinoColors.white : const Color(0xFF1F2937)),
              placeholderStyle: TextStyle(fontSize: 15, color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A).withValues(alpha: 0.6) : const Color(0xFFF4F4F5).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.2) : const Color(0xFF8B5CF6).withValues(alpha: 0.15), width: 1),
              ),
              onChanged: (v) {
                if (v.isEmpty) {
                  _closeTagSuggestions();
                  return;
                }
                if (v.endsWith(' ')) _closeTagSuggestions();
                else {
                  final w = _getCurrentWord();
                  if (w.length >= 2) _tagDebouncer.run(() => _fetchTagSuggestions(w));
                  else _closeTagSuggestions();
                }
              },
              onSubmitted: (_) {
                _closeTagSuggestions();
                _performSearch();
              },
            ),
          ),
          const SizedBox(width: 12),
          _ToolbarBtn(icon: CupertinoIcons.search, onTap: () { _closeTagSuggestions(); _performSearch(); }),
          const SizedBox(width: 8),
          _ToolbarBtn(icon: _showFilters ? CupertinoIcons.slider_horizontal_below_rectangle : CupertinoIcons.slider_horizontal_3, onTap: _toggleFilters),
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
            color: isDark ? CupertinoColors.white.withValues(alpha: 0.14) : CupertinoColors.white.withValues(alpha: 0.95),
            border: Border.all(color: isDark ? CupertinoColors.white.withValues(alpha: 0.15) : CupertinoColors.black.withValues(alpha: 0.1), width: 0.5),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: i < _tagSuggestions.length - 1
                        ? Border(bottom: BorderSide(color: isDark ? CupertinoColors.white.withValues(alpha: 0.1) : CupertinoColors.black.withValues(alpha: 0.05), width: 0.5))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(color: tag.color, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(tag.name.replaceAll('_', ' '), style: TextStyle(color: tag.color, fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      Text(
                        tag.postCount >= 1000000 ? '${(tag.postCount / 1000000).toStringAsFixed(1)}m' : (tag.postCount >= 1000 ? '${(tag.postCount / 1000).toStringAsFixed(1)}k' : '${tag.postCount}'),
                        style: TextStyle(color: isDark ? CupertinoColors.white.withValues(alpha: 0.5) : CupertinoColors.black.withValues(alpha: 0.4), fontSize: 13),
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

  Widget _buildFilters(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B).withValues(alpha: 0.85) : const Color(0xFFFFFFFF).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.2) : const Color(0xFF8B5CF6).withValues(alpha: 0.15), width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Rating:', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: _selectedRating ?? 'all',
              children: const {
                'all': Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('All', style: TextStyle(fontSize: 12))),
                's': Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Safe', style: TextStyle(fontSize: 12))),
                'q': Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Questionable', style: TextStyle(fontSize: 12))),
                'e': Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Explicit', style: TextStyle(fontSize: 12))),
              },
              onValueChanged: (v) {
                setState(() => _selectedRating = v == 'all' ? null : v);
                if (_searchController.text.isNotEmpty) _performSearch();
              },
            ),
            const SizedBox(width: 24),
            const Text('Sort:', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: _selectedOrder,
              children: {for (final e in _orderOptions.entries) e.key: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(e.value, style: const TextStyle(fontSize: 12)))},
              onValueChanged: (v) {
                if (v != null) {
                  setState(() => _selectedOrder = v);
                  if (_searchController.text.isNotEmpty) _performSearch();
                }
              },
            ),
          ],
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
                Text('History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => context.read<SettingsProvider>().clearSearchHistory(),
                  child: Text('Clear', style: TextStyle(fontSize: 12, color: CupertinoTheme.of(context).primaryColor)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SettingsProvider>(
              builder: (_, sp, __) {
                final history = sp.searchHistory;
                if (history.isEmpty) {
                  return Center(
                    child: Text('No recent searches', style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                  );
                }
                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (_, i) {
                    final item = history[i];
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      onPressed: () {
                        _searchController.text = item.query;
                        _performSearch();
                      },
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.clock, size: 14, color: CupertinoColors.secondaryLabel),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.query, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
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
      builder: (_, pp, __) {
        if (pp.searchResults.isEmpty && !pp.isLoadingSearch) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.search, size: 64, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                const SizedBox(height: 16),
                Text('Search for posts', style: TextStyle(fontSize: 18, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                const SizedBox(height: 8),
                Text('Enter tags to find posts', style: TextStyle(fontSize: 14, color: CupertinoColors.tertiaryLabel.resolveFrom(context))),
              ],
            ),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollEndNotification) {
              final m = n.metrics;
              if (m.pixels >= m.maxScrollExtent - 200 && pp.hasMoreSearch && !pp.isLoadingSearch) _loadMore();
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CupertinoTheme.brightnessOf(context) == Brightness.dark ? const Color(0xFF2C2C2E).withValues(alpha: 0.6) : const Color(0xFFF3F4F6).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
