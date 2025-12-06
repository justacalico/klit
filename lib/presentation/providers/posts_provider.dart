import 'package:flutter/cupertino.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';

/// Provider for posts data
class PostsProvider extends ChangeNotifier {
  final ApiService _apiService;

  // Posts lists
  List<Post> _latestPosts = [];
  List<Post> _hotPosts = [];
  List<Post> _popularPosts = [];
  List<Post> _searchResults = [];

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

  PostsProvider({required ApiService apiService}) : _apiService = apiService;

  // Getters
  List<Post> get latestPosts => _latestPosts;
  List<Post> get hotPosts => _hotPosts;
  List<Post> get popularPosts => _popularPosts;
  List<Post> get searchResults => _searchResults;

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

  /// Load latest posts
  /// If [safeMode] is true, only safe-rated posts will be returned
  Future<void> loadLatestPosts({bool refresh = false, bool safeMode = false}) async {
    if (_isLoadingLatest) return;
    if (!refresh && !_hasMoreLatest) return;

    if (refresh) {
      _latestPage = 1;
      _hasMoreLatest = true;
    }

    _isLoadingLatest = true;
    _latestError = null;
    notifyListeners();

    final result = await _apiService.getPosts(
      page: _latestPage,
      limit: ApiConstants.defaultPageSize,
      tags: 'score:>20',
      order: 'id_desc',
      safeMode: safeMode,
    );

    result.when(
      success: (posts) {
        if (refresh) {
          _latestPosts = posts;
        } else {
          _latestPosts = [..._latestPosts, ...posts];
        }
        _hasMoreLatest = posts.length >= ApiConstants.defaultPageSize;
        _latestPage++;
      },
      failure: (error) {
        _latestError = error.message;
      },
    );

    _isLoadingLatest = false;
    notifyListeners();
  }

  /// Load hot posts (high score recent posts)
  /// If [safeMode] is true, only safe-rated posts will be returned
  Future<void> loadHotPosts({bool refresh = false, bool safeMode = false}) async {
    if (_isLoadingHot) return;
    if (!refresh && !_hasMoreHot) return;

    if (refresh) {
      _hotPage = 1;
      _hasMoreHot = true;
    }

    _isLoadingHot = true;
    _hotError = null;
    notifyListeners();

    // Hot posts are sorted by score with a time range
    String timeTag;
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

    final result = await _apiService.getPosts(
      page: _hotPage,
      limit: ApiConstants.defaultPageSize,
      tags: timeTag,
      order: 'score',
      safeMode: safeMode,
    );

    result.when(
      success: (posts) {
        if (refresh) {
          _hotPosts = posts;
        } else {
          _hotPosts = [..._hotPosts, ...posts];
        }
        _hasMoreHot = posts.length >= ApiConstants.defaultPageSize;
        _hotPage++;
      },
      failure: (error) {
        _hotError = error.message;
      },
    );

    _isLoadingHot = false;
    notifyListeners();
  }

  /// Set hot time range and refresh
  void setHotTimeRange(String range) {
    if (_hotTimeRange != range) {
      _hotTimeRange = range;
      loadHotPosts(refresh: true);
    }
  }

  /// Load popular posts
  Future<void> loadPopularPosts({bool refresh = false}) async {
    if (_isLoadingPopular) return;
    if (!refresh && !_hasMorePopular) return;

    if (refresh) {
      _popularPage = 1;
      _hasMorePopular = true;
    }

    _isLoadingPopular = true;
    _popularError = null;
    notifyListeners();

    final result = await _apiService.getPopularPosts(
      scale: _popularTimeRange,
      page: _popularPage,
    );

    result.when(
      success: (posts) {
        if (refresh) {
          _popularPosts = posts;
        } else {
          _popularPosts = [..._popularPosts, ...posts];
        }
        _hasMorePopular = posts.length >= ApiConstants.defaultPageSize;
        _popularPage++;
      },
      failure: (error) {
        _popularError = error.message;
      },
    );

    _isLoadingPopular = false;
    notifyListeners();
  }

  /// Set popular time range and refresh
  void setPopularTimeRange(String range) {
    if (_popularTimeRange != range) {
      _popularTimeRange = range;
      loadPopularPosts(refresh: true);
    }
  }

  /// Search posts
  Future<void> searchPosts({
    required String query,
    bool refresh = false,
    String? rating,
    String? order,
  }) async {
    if (_isLoadingSearch) return;
    if (!refresh && !_hasMoreSearch) return;

    if (refresh || query != _currentSearchQuery) {
      _searchPage = 1;
      _hasMoreSearch = true;
      _currentSearchQuery = query;
    }

    _isLoadingSearch = true;
    _searchError = null;
    notifyListeners();

    final result = await _apiService.getPosts(
      page: _searchPage,
      limit: ApiConstants.defaultPageSize,
      tags: query,
      rating: rating,
      order: order,
    );

    result.when(
      success: (posts) {
        if (refresh || _searchPage == 1) {
          _searchResults = posts;
        } else {
          _searchResults = [..._searchResults, ...posts];
        }
        _hasMoreSearch = posts.length >= ApiConstants.defaultPageSize;
        _searchPage++;
      },
      failure: (error) {
        _searchError = error.message;
      },
    );

    _isLoadingSearch = false;
    notifyListeners();
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _currentSearchQuery = '';
    _searchPage = 1;
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
