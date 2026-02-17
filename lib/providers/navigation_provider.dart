import 'package:flutter/foundation.dart';

/// Manages navigation state that persists across mobile/desktop UI switches
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String? _searchQuery;
  bool _sidebarCollapsed = false;

  int get currentIndex => _currentIndex;
  String? get searchQuery => _searchQuery;
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

  int desktopToMobileIndex(int desktopIndex) {
    switch (desktopIndex) {
      case 0: return 0;
      case 1: return 1;
      case 2: return 2;
      case 3: return 4;
      case 4: return 4;
      case 5: return 3;
      case 6: return 3;
      default: return 0;
    }
  }

  int mobileToDesktopIndex(int mobileIndex) {
    switch (mobileIndex) {
      case 0: return 0;
      case 1: return 1;
      case 2: return 2;
      case 3: return 5;
      case 4: return 3;
      default: return 0;
    }
  }

  int getMobileIndex() => desktopToMobileIndex(_currentIndex);
  int getDesktopIndex() => _currentIndex;

  void setFromMobileIndex(int mobileIndex) {
    final desktopIndex = mobileToDesktopIndex(mobileIndex);
    if (_currentIndex != desktopIndex) {
      _currentIndex = desktopIndex;
      notifyListeners();
    }
  }

  void setFromDesktopIndex(int desktopIndex) {
    if (_currentIndex != desktopIndex) {
      _currentIndex = desktopIndex;
      notifyListeners();
    }
  }

  /// Clear search query (e.g. when switching nav tabs)
  void clearSearch() {
    if (_searchQuery != null) {
      _searchQuery = null;
      notifyListeners();
    }
  }
}
