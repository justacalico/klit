import 'package:flutter/foundation.dart';
import '../core/constants/constants.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';
import 'auth_provider.dart';
import 'blacklist_filter.dart';

/// Provider for posts data
class PostsProvider extends ChangeNotifier {
  final ApiService _apiService;
  AuthProvider? _authProvider;

  PostsProvider({required ApiService apiService, AuthProvider? authProvider})
      : _apiService = apiService,
        _authProvider = authProvider;

  void setAuthProvider(AuthProvider? authProvider) {
    _authProvider = authProvider;
  }

  // Posts lists
  List<Post> _latestPosts = [];
  List<Post> _hotPosts = [];
  List<Post> _popularPosts = [];
  List<Post> _searchResults = [];
  /// When multi-host search, host URL per index (same length as _searchResults).
  List<String>? _searchPostHostUrls;
  /// Per-host page index for multi-host load more.
  final Map<String, int> _multiHostPage = {};
  List<String>? _multiHostHostUrls;
  String _multiHostQuery = '';

  // Pagination
  int _latestPage = 1;
  int _hotPage = 1;
  int _popularPage = 1;
  int _searchPage = 1;

  // Loading states
  bool _isLoadingLatest = false;
  bool _isLoadingHot = false;
  bool _isLoadingPopular = false;
  bool _isLoadingSearch = false;

  // Has more
  bool _hasMoreLatest = true;
  bool _hasMoreHot = true;
  bool _hasMorePopular = true;
  bool _hasMoreSearch = true;

  // Error states
  String? _latestError;
  String? _hotError;
  String? _popularError;
  String? _searchError;

  // Current search/filter settings
  String _currentSearchQuery = '';
  String _hotTimeRange = 'day';
  String _popularTimeRange = 'day';
  DateTime? _hotCustomDate;
  DateTime? _popularCustomDate;

  // Blacklist
  List<String> _blacklistLines = [];
  bool _blacklistEnabled = true;

  // Getters
  List<Post> get latestPosts => _latestPosts;
  List<Post> get hotPosts => _hotPosts;
  List<Post> get popularPosts => _popularPosts;
  List<Post> get searchResults => _searchResults;
  /// When multi-host search was used, host URL per result index. Null for single-host.
  List<String>? get searchPostHostUrls => _searchPostHostUrls;

  bool get isLoadingLatest => _isLoadingLatest;
  bool get isLoadingHot => _isLoadingHot;
  bool get isLoadingPopular => _isLoadingPopular;
  bool get isLoadingSearch => _isLoadingSearch;

  bool get hasMoreLatest => _hasMoreLatest;
  bool get hasMoreHot => _hasMoreHot;
  bool get hasMorePopular => _hasMorePopular;
  bool get hasMoreSearch => _hasMoreSearch;

  String? get latestError => _latestError;
  String? get hotError => _hotError;
  String? get popularError => _popularError;
  String? get searchError => _searchError;

  String get currentSearchQuery => _currentSearchQuery;
  String get hotTimeRange => _hotTimeRange;
  String get popularTimeRange => _popularTimeRange;
  DateTime? get hotCustomDate => _hotCustomDate;
  DateTime? get popularCustomDate => _popularCustomDate;

  /// Clear all cached posts data (used when host changes)
  void clearAllPosts() {
    _latestPosts = [];
    _hotPosts = [];
    _popularPosts = [];
    _searchResults = [];

    _latestPage = 1;
    _hotPage = 1;
    _popularPage = 1;
    _searchPage = 1;

    _hasMoreLatest = true;
    _hasMoreHot = true;
    _hasMorePopular = true;
    _hasMoreSearch = true;

    _latestError = null;
    _hotError = null;
    _popularError = null;
    _searchError = null;

    _hotCustomDate = null;
    _popularCustomDate = null;

    notifyListeners();
  }

  /// Update blacklist settings
  void updateBlacklist(List<String> blacklistLines, bool enabled) {
    _blacklistLines = blacklistLines;
    _blacklistEnabled = enabled;
  }

  /// Load latest posts
  /// If [safeMode] is true, only safe-rated posts will be returned
  /// [scoreThreshold] filters posts with score greater than this value (default: 20)
  Future<void> loadLatestPosts({
    bool refresh = false,
    bool safeMode = false,
    int scoreThreshold = 20,
  }) async {
    if (_isLoadingLatest) return;
    if (!refresh && !_hasMoreLatest) return;

    if (refresh) {
      _latestPage = 1;
      _hasMoreLatest = true;
    }

    _isLoadingLatest = true;
    _latestError = null;
    notifyListeners();

    try {
      final result = await _apiService.getPosts(
        page: _latestPage,
        limit: ApiConstants.defaultPageSize,
        tags: 'score:>$scoreThreshold',
        order: 'id_desc',
        safeMode: safeMode,
      );

      if (result.data != null) {
        final posts = result.data!;
        final filteredPosts = filterBlacklistStatic(
          BlacklistFilterInput(
            posts: posts,
            blacklistLines: _blacklistLines,
            enabled: _blacklistEnabled,
          ),
        );
        if (refresh) {
          _latestPosts = filteredPosts;
        } else {
          _latestPosts = [..._latestPosts, ...filteredPosts];
        }
        _hasMoreLatest = posts.length >= ApiConstants.defaultPageSize;
        _latestPage++;
      } else {
        _latestError = result.error!.message;
      }
    } catch (e, st) {
      _latestError = e.toString();
      debugPrint('loadLatestPosts error: $e\n$st');
    } finally {
      _isLoadingLatest = false;
      notifyListeners();
    }
  }

  /// Load hot posts (high score recent posts)
  /// If [safeMode] is true, only safe-rated posts will be returned
  Future<void> loadHotPosts({
    bool refresh = false,
    bool safeMode = false,
  }) async {
    if (_isLoadingHot) return;
    if (!refresh && !_hasMoreHot) return;

    if (refresh) {
      _hotPage = 1;
      _hasMoreHot = true;
    }

    _isLoadingHot = true;
    _hotError = null;
    notifyListeners();

    try {
    // Hot posts are sorted by score with a time range
    String timeTag;
    if (_hotCustomDate != null) {
      // Use custom date - show posts from that specific day/week/month
      final date = _hotCustomDate!;
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      switch (_hotTimeRange) {
        case 'week':
          final endDate = date.add(const Duration(days: 7));
          final endStr =
              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
          timeTag = 'date:>=$dateStr date:<$endStr';
          break;
        case 'month':
          final endDate = DateTime(date.year, date.month + 1, date.day);
          final endStr =
              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
          timeTag = 'date:>=$dateStr date:<$endStr';
          break;
        default:
          timeTag = 'date:$dateStr';
      }
    } else {
      switch (_hotTimeRange) {
        case 'week':
          timeTag = 'date:week';
          break;
        case 'month':
          timeTag = 'date:month';
          break;
        default:
          timeTag = 'date:day';
      }
    }

    final result = await _apiService.getPosts(
      page: _hotPage,
      limit: ApiConstants.defaultPageSize,
      tags: timeTag,
      order: 'score',
      safeMode: safeMode,
    );

    if (result.data != null) {
      final posts = result.data!;
      final filteredPosts = filterBlacklistStatic(
        BlacklistFilterInput(
          posts: posts,
          blacklistLines: _blacklistLines,
          enabled: _blacklistEnabled,
        ),
      );
      if (refresh) {
        _hotPosts = filteredPosts;
      } else {
        _hotPosts = [..._hotPosts, ...filteredPosts];
      }
      _hasMoreHot = posts.length >= ApiConstants.defaultPageSize;
      _hotPage++;
    } else {
      _hotError = result.error!.message;
    }
    } catch (e, st) {
      _hotError = e.toString();
      debugPrint('loadHotPosts error: $e\n$st');
    } finally {
      _isLoadingHot = false;
      notifyListeners();
    }
  }

  /// Set hot time range and refresh
  void setHotTimeRange(String range, {bool safeMode = false}) {
    if (_hotTimeRange != range) {
      _hotTimeRange = range;
      _hotCustomDate = null; // Clear custom date when changing range
      loadHotPosts(refresh: true, safeMode: safeMode);
    }
  }

  /// Set hot custom date and refresh
  void setHotCustomDate(DateTime? date, {bool safeMode = false}) {
    _hotCustomDate = date;
    loadHotPosts(refresh: true, safeMode: safeMode);
  }

  /// Load popular posts
  /// If [safeMode] is true, only safe-rated posts will be returned
  Future<void> loadPopularPosts({
    bool refresh = false,
    bool safeMode = false,
  }) async {
    if (_isLoadingPopular) return;
    if (!refresh && !_hasMorePopular) return;

    if (refresh) {
      _popularPage = 1;
      _hasMorePopular = true;
    }

    _isLoadingPopular = true;
    _popularError = null;
    notifyListeners();

    try {
    final result = await _apiService.getPopularPosts(
      scale: _popularTimeRange,
      page: _popularPage,
      safeMode: safeMode,
      customDate: _popularCustomDate,
    );

    if (result.data != null) {
      final posts = result.data!;
      final filteredPosts = filterBlacklistStatic(
        BlacklistFilterInput(
          posts: posts,
          blacklistLines: _blacklistLines,
          enabled: _blacklistEnabled,
        ),
      );
      if (refresh) {
        _popularPosts = filteredPosts;
      } else {
        _popularPosts = [..._popularPosts, ...filteredPosts];
      }
      _hasMorePopular = posts.length >= ApiConstants.defaultPageSize;
      _popularPage++;
    } else {
      _popularError = result.error!.message;
    }
    } catch (e, st) {
      _popularError = e.toString();
      debugPrint('loadPopularPosts error: $e\n$st');
    } finally {
      _isLoadingPopular = false;
      notifyListeners();
    }
  }

  /// Set popular time range and refresh
  void setPopularTimeRange(String range, {bool safeMode = false}) {
    if (_popularTimeRange != range) {
      _popularTimeRange = range;
      _popularCustomDate = null; // Clear custom date when changing range
      loadPopularPosts(refresh: true, safeMode: safeMode);
    }
  }

  /// Set popular custom date and refresh
  void setPopularCustomDate(DateTime? date, {bool safeMode = false}) {
    _popularCustomDate = date;
    loadPopularPosts(refresh: true, safeMode: safeMode);
  }

  /// Search posts
  /// If [safeMode] is true, only safe-rated posts will be returned
  Future<void> searchPosts({
    required String query,
    bool refresh = false,
    String? rating,
    String? order,
    bool safeMode = false,
  }) async {
    if (_isLoadingSearch) return;
    if (!refresh && !_hasMoreSearch) return;

    if (refresh || query != _currentSearchQuery) {
      _searchPage = 1;
      _hasMoreSearch = true;
      _currentSearchQuery = query;
      _searchPostHostUrls = null;
    }

    _isLoadingSearch = true;
    _searchError = null;
    notifyListeners();

    try {
      final result = await _apiService.getPosts(
        page: _searchPage,
        limit: ApiConstants.defaultPageSize,
        tags: query,
        rating: rating,
        order: order,
        safeMode: safeMode,
      );

      if (result.data != null) {
        final posts = result.data!;
        final filteredPosts = filterBlacklistStatic(
          BlacklistFilterInput(
            posts: posts,
            blacklistLines: _blacklistLines,
            enabled: _blacklistEnabled,
          ),
        );
        if (refresh || _searchPage == 1) {
          _searchResults = filteredPosts;
        } else {
          _searchResults = [..._searchResults, ...filteredPosts];
        }
        _hasMoreSearch = posts.length >= ApiConstants.defaultPageSize;
        _searchPage++;
      } else {
        _searchError = result.error!.message;
      }
    } catch (e, st) {
      _searchError = e.toString();
      debugPrint('searchPosts error: $e\n$st');
    } finally {
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  /// Multi-host search: run search on each host, merge by createdAt desc, apply blacklist.
  Future<void> searchPostsMultiHost({
    required String query,
    required List<String> hostUrls,
    bool refresh = false,
    String? rating,
    String? order,
    bool safeMode = false,
  }) async {
    if (hostUrls.isEmpty) {
      searchPosts(query: query, refresh: refresh, rating: rating, order: order, safeMode: safeMode);
      return;
    }
    if (_isLoadingSearch) return;
    final effectiveRating = safeMode ? 's' : rating;

    if (refresh || query != _multiHostQuery || !_listEquals(hostUrls, _multiHostHostUrls)) {
      _multiHostPage.clear();
      for (final h in hostUrls) {
        _multiHostPage[h] = 1;
      }
      _multiHostQuery = query;
      _multiHostHostUrls = List.from(hostUrls);
      _hasMoreSearch = true;
    }
    if (!_hasMoreSearch) return;

    _isLoadingSearch = true;
    _searchError = null;
    _currentSearchQuery = query;
    notifyListeners();

    try {
      final all = <PostWithSource>[];
      var anyHasMore = false;
      for (final hostUrl in hostUrls) {
        final page = _multiHostPage[hostUrl] ?? 1;
        final account = _authProvider?.getAccountForHost(hostUrl);
        final result = await _apiService.runWithHost(
          hostUrl,
          account?.username,
          account?.apiKey,
          () => _apiService.getPosts(
            page: page,
            limit: ApiConstants.defaultPageSize,
            tags: query,
            rating: effectiveRating,
            order: order,
            safeMode: safeMode,
          ),
        );
        result.when(
          success: (posts) {
            for (final p in posts) {
              all.add(PostWithSource(post: p, hostUrl: hostUrl));
            }
            _multiHostPage[hostUrl] = page + 1;
            if (posts.length >= ApiConstants.defaultPageSize) anyHasMore = true;
          },
          failure: (_) {},
        );
      }
      _hasMoreSearch = anyHasMore;
      all.sort((a, b) => b.post.createdAt.compareTo(a.post.createdAt));
      final passedPosts = filterBlacklistStatic(
        BlacklistFilterInput(
          posts: all.map((e) => e.post).toList(),
          blacklistLines: _blacklistLines,
          enabled: _blacklistEnabled,
        ),
      );
      final allMutable = List<PostWithSource>.from(all);
      final filteredWithSource = <PostWithSource>[];
      for (final p in passedPosts) {
        var i = allMutable.indexWhere((e) => e.post.id == p.id && e.post.createdAt == p.createdAt);
        if (i < 0) i = allMutable.indexWhere((e) => e.post.id == p.id);
        if (i >= 0) filteredWithSource.add(allMutable.removeAt(i));
      }
      final hostUrlsForFiltered = filteredWithSource.map((e) => e.hostUrl).toList();
      final filtered = filteredWithSource.map((e) => e.post).toList();

      if (refresh || (_searchResults.isEmpty && _searchPostHostUrls == null)) {
        _searchResults = filtered;
        _searchPostHostUrls = hostUrlsForFiltered;
      } else {
        _searchResults = [..._searchResults, ...filtered];
        _searchPostHostUrls = [...?_searchPostHostUrls, ...hostUrlsForFiltered];
      }
    } catch (e, st) {
      _searchError = e.toString();
      debugPrint('searchPostsMultiHost error: $e\n$st');
    } finally {
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  static bool _listEquals(List<String>? a, List<String>? b) {
    if (a == b) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _searchPostHostUrls = null;
    _currentSearchQuery = '';
    _searchPage = 1;
    _multiHostPage.clear();
    _multiHostHostUrls = null;
    _multiHostQuery = '';
    _hasMoreSearch = true;
    _searchError = null;
    notifyListeners();
  }

  /// Clear all data
  void clearAll() {
    _latestPosts = [];
    _hotPosts = [];
    _popularPosts = [];
    _searchResults = [];
    _latestPage = 1;
    _hotPage = 1;
    _popularPage = 1;
    _searchPage = 1;
    _hasMoreLatest = true;
    _hasMoreHot = true;
    _hasMorePopular = true;
    _hasMoreSearch = true;
    _latestError = null;
    _hotError = null;
    _popularError = null;
    _searchError = null;
    notifyListeners();
  }
}
