import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:klit/app/data/nav_items.dart';
import 'package:klit/app/routes/app_routes.dart';

export 'package:klit/app/data/nav_items.dart' show NavItem;

class NavigationState {
  const NavigationState({
    required this.items,
    this.mobilePrimaryCount = 4,
    this.currentPath = AppRoutes.home,
    this.sidebarCollapsed = false,
    this.profileViewUserId,
    this.profileViewUsername,
    this.searchInitialQuery,
  });

  final List<NavItem> items;
  final int mobilePrimaryCount;
  final String currentPath;
  final bool sidebarCollapsed;
  final int? profileViewUserId;
  final String? profileViewUsername;
  final String? searchInitialQuery;

  int get currentIndex {
    final i = items.indexWhere((e) => e.path == currentPath);
    return i >= 0 ? i : 0;
  }

  NavigationState copyWith({
    List<NavItem>? items,
    int? mobilePrimaryCount,
    String? currentPath,
    bool? sidebarCollapsed,
    int? profileViewUserId,
    String? profileViewUsername,
    String? searchInitialQuery,
  }) {
    return NavigationState(
      items: items ?? this.items,
      mobilePrimaryCount: mobilePrimaryCount ?? this.mobilePrimaryCount,
      currentPath: currentPath ?? this.currentPath,
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      profileViewUserId: profileViewUserId ?? this.profileViewUserId,
      profileViewUsername: profileViewUsername ?? this.profileViewUsername,
      searchInitialQuery: searchInitialQuery ?? this.searchInitialQuery,
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  bool _requestSearchFocus = false;

  @override
  NavigationState build() {
    return NavigationState(
      items: appNavItems,
      mobilePrimaryCount: 4,
    );
  }

  void setPath(String path, {int? profileUserId, String? profileUsername}) {
    state = state.copyWith(
      currentPath: path,
      profileViewUserId: profileUserId ?? (path == AppRoutes.profile ? null : state.profileViewUserId),
      profileViewUsername: profileUsername ?? (path == AppRoutes.profile ? null : state.profileViewUsername),
      searchInitialQuery: path == AppRoutes.search ? state.searchInitialQuery : null,
    );
  }

  void clearSearchInitialQuery() {
    state = state.copyWith(searchInitialQuery: null);
  }

  void setSearchInitialQuery(String? query) {
    state = state.copyWith(searchInitialQuery: query);
  }

  void requestSearchFocus() {
    _requestSearchFocus = true;
  }

  bool takeRequestSearchFocus() {
    final v = _requestSearchFocus;
    _requestSearchFocus = false;
    return v;
  }

  void toggleSidebar() {
    state = state.copyWith(sidebarCollapsed: !state.sidebarCollapsed);
  }

  void setSidebarCollapsed(bool collapsed) {
    state = state.copyWith(sidebarCollapsed: collapsed);
  }

  String goTo(int index) {
    if (index < 0 || index >= state.items.length) return state.currentPath;
    final path = state.items[index].path;
    state = state.copyWith(
      currentPath: path,
      profileViewUserId: path == AppRoutes.profile ? null : state.profileViewUserId,
      profileViewUsername: path == AppRoutes.profile ? null : state.profileViewUsername,
      searchInitialQuery: path == AppRoutes.home ? null : state.searchInitialQuery,
    );
    if (path == AppRoutes.search) _requestSearchFocus = true;
    return path;
  }
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState>(NavigationNotifier.new);
