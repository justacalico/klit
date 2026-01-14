import 'package:flutter/foundation.dart';

/// Manages navigation state that persists across mobile/desktop UI switches
/// 
/// This provider ensures that when the user resizes the window and the UI
/// switches between mobile and desktop modes, the navigation state is preserved.
class NavigationProvider extends ChangeNotifier {
  /// Current navigation index
  /// 
  /// Mobile mapping:
  /// - 0: Home
  /// - 1: Hot
  /// - 2: Popular
  /// - 3: Profile
  /// - 4: Settings
  /// 
  /// Desktop mapping:
  /// - 0: Home
  /// - 1: Hot
  /// - 2: Popular
  /// - 3: Settings
  /// - 4: Search
  /// - 5: Profile
  /// - 6: Favorites
  int _currentIndex = 0;
  
  /// Search query if search is active
  String? _searchQuery;
  
  /// Whether sidebar is collapsed (desktop only)
  bool _sidebarCollapsed = false;

  int get currentIndex => _currentIndex;
  String? get searchQuery => _searchQuery;
  bool get sidebarCollapsed => _sidebarCollapsed;

  /// Set the current navigation index
  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Set search query and optionally navigate to search
  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Open search with optional query
  void openSearch([String? query]) {
    _searchQuery = query;
    _currentIndex = 4; // Search index on desktop
    notifyListeners();
  }

  /// Toggle sidebar collapsed state
  void toggleSidebar() {
    _sidebarCollapsed = !_sidebarCollapsed;
    notifyListeners();
  }

  /// Set sidebar collapsed state
  void setSidebarCollapsed(bool collapsed) {
    if (_sidebarCollapsed != collapsed) {
      _sidebarCollapsed = collapsed;
      notifyListeners();
    }
  }

  /// Convert desktop index to mobile index
  /// 
  /// Desktop: 0=Home, 1=Hot, 2=Popular, 3=Settings, 4=Search, 5=Profile, 6=Favorites
  /// Mobile: 0=Home, 1=Hot, 2=Popular, 3=Profile, 4=Settings
  int desktopToMobileIndex(int desktopIndex) {
    switch (desktopIndex) {
      case 0: return 0; // Home
      case 1: return 1; // Hot
      case 2: return 2; // Popular
      case 3: return 4; // Settings
      case 4: return 4; // Search -> Settings (no search tab in mobile nav)
      case 5: return 3; // Profile
      case 6: return 3; // Favorites -> Profile (no favorites tab in mobile nav)
      default: return 0;
    }
  }

  /// Convert mobile index to desktop index
  /// 
  /// Mobile: 0=Home, 1=Hot, 2=Popular, 3=Profile, 4=Settings
  /// Desktop: 0=Home, 1=Hot, 2=Popular, 3=Settings, 4=Search, 5=Profile, 6=Favorites
  int mobileToDesktopIndex(int mobileIndex) {
    switch (mobileIndex) {
      case 0: return 0; // Home
      case 1: return 1; // Hot
      case 2: return 2; // Popular
      case 3: return 5; // Profile
      case 4: return 3; // Settings
      default: return 0;
    }
  }

  /// Get the appropriate index for mobile UI based on current state
  int getMobileIndex() {
    return desktopToMobileIndex(_currentIndex);
  }

  /// Get the appropriate index for desktop UI based on current state
  int getDesktopIndex() {
    return _currentIndex;
  }

  /// Update from mobile index
  void setFromMobileIndex(int mobileIndex) {
    final desktopIndex = mobileToDesktopIndex(mobileIndex);
    if (_currentIndex != desktopIndex) {
      _currentIndex = desktopIndex;
      notifyListeners();
    }
  }

  /// Update from desktop index
  void setFromDesktopIndex(int desktopIndex) {
    if (_currentIndex != desktopIndex) {
      _currentIndex = desktopIndex;
      notifyListeners();
    }
  }
}
