import 'package:flutter/foundation.dart';

/// Manages navigation state that persists across mobile/desktop UI switches
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String? _searchQuery;
  String? _feedTitle;
  List<String>? _hostUrls;
  String? _initialRating;
  String? _initialOrder;
  bool _sidebarCollapsed = false;

  int get currentIndex => _currentIndex;
  String? get searchQuery => _searchQuery;
  String? get feedTitle => _feedTitle;
  List<String>? get hostUrls => _hostUrls;
  String? get initialRating => _initialRating;
  String? get initialOrder => _initialOrder;
  bool get sidebarCollapsed => _sidebarCollapsed;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void openSearch([String? query]) {
    _searchQuery = query;
    _feedTitle = null;
    _hostUrls = null;
    _initialRating = null;
    _initialOrder = null;
    _currentIndex = 4;
    notifyListeners();
  }

  void openFeed({
    required String query,
    required String feedTitle,
    List<String>? hostUrls,
    String? rating,
    String? order,
  }) {
    _searchQuery = query;
    _feedTitle = feedTitle;
    _hostUrls = hostUrls != null && hostUrls.isNotEmpty ? hostUrls : null;
    _initialRating = rating;
    _initialOrder = order ?? 'id_desc';
    _currentIndex = 4;
    notifyListeners();
  }

  void toggleSidebar() {
    _sidebarCollapsed = !_sidebarCollapsed;
    notifyListeners();
  }

  void setSidebarCollapsed(bool collapsed) {
    if (_sidebarCollapsed != collapsed) {
      _sidebarCollapsed = collapsed;
      notifyListeners();
    }
  }

  /// Current page id (0=Home, 1=Hot, 2=Popular, 3=Settings, 4=Search, 5=Profile, 6=Favorites, 7=Feeds).
  /// Mobile nav bar uses the same ids in navOrder; position is navOrder.indexOf(id).
  int getMobileIndex() => _currentIndex;
  int getDesktopIndex() => _currentIndex;

  void setFromMobileIndex(int pageId) {
    if (_currentIndex != pageId) {
      _currentIndex = pageId;
      notifyListeners();
    }
  }

  void setFromDesktopIndex(int desktopIndex) {
    if (_currentIndex != desktopIndex) {
      _currentIndex = desktopIndex;
      notifyListeners();
    }
  }

  /// Clear search query and feed params (e.g. when switching nav tabs)
  void clearSearch() {
    final changed = _searchQuery != null ||
        _feedTitle != null ||
        _hostUrls != null ||
        _initialRating != null ||
        _initialOrder != null;
    if (changed) {
      _searchQuery = null;
      _feedTitle = null;
      _hostUrls = null;
      _initialRating = null;
      _initialOrder = null;
      notifyListeners();
    }
  }
}
