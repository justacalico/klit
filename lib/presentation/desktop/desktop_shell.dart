import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../pages/post/post_detail_page.dart';
import 'pages/desktop_favorites_page.dart';
import 'pages/desktop_home_page.dart';
import 'pages/desktop_hot_page.dart';
import 'pages/desktop_popular_page.dart';
import 'pages/desktop_post_detail_page.dart';
import 'pages/desktop_profile_page.dart';
import 'pages/desktop_search_page.dart';
import 'pages/desktop_settings_page.dart';
import 'widgets/desktop_sidebar.dart';

/// Desktop shell with macOS-style sidebar navigation
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;

  // For post detail view
  PostDetailArguments? _postDetailArgs;
  String? _searchQuery;

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _searchQuery = null;
    });
  }

  void _openPostDetail(PostDetailArguments args) {
    setState(() {
      _postDetailArgs = args;
    });
  }

  void _closePostDetail() {
    setState(() {
      _postDetailArgs = null;
    });
  }

  void _openSearch([String? query]) {
    setState(() {
      _selectedIndex = 4; // Search tab
      _searchQuery = query;
      _postDetailArgs = null;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      child: Container(
        // Gradient background that shows through glass elements
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0A0A0C),
                    const Color(0xFF1A1A1E),
                    const Color(0xFF0D0D0F),
                  ]
                : [
                    const Color(0xFFF5F5FA),
                    const Color(0xFFE8E8F0),
                    const Color(0xFFF8F8FC),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
        children: [
          // Main layout with sidebar
          Row(
            children: [
              // Sidebar
              DesktopSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: _onNavItemSelected,
                isCollapsed: _sidebarCollapsed,
                onToggleCollapse: _toggleSidebar,
              ),
              // Main content (no separator - glass effect handles visual separation)
              Expanded(child: _buildMainContent()),
            ],
          ),
          // Full-screen post detail overlay
          if (_postDetailArgs != null) _buildPostDetailOverlay(isDark),
        ],
      ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return DesktopHomePage(
          onPostTap: _openPostDetail,
          onSearchTap: _openSearch,
        );
      case 1:
        return DesktopHotPage(
          onPostTap: _openPostDetail,
          onSearchTap: _openSearch,
        );
      case 2:
        return DesktopPopularPage(
          onPostTap: _openPostDetail,
          onSearchTap: _openSearch,
        );
      case 3:
        return DesktopSettingsPage(
          onNavigate: (route) {
            Navigator.of(context).pushNamed(route);
          },
        );
      case 4:
        return DesktopSearchPage(
          initialQuery: _searchQuery,
          onPostTap: _openPostDetail,
        );
      case 5:
        return DesktopProfilePage(
          onNavigate: (route) {
            Navigator.of(context).pushNamed(route);
          },
        );
      case 6:
        return DesktopFavoritesPage(
          onPostTap: _openPostDetail,
        );
      default:
        return DesktopHomePage(
          onPostTap: _openPostDetail,
          onSearchTap: _openSearch,
        );
    }
  }

  Widget _buildPostDetailOverlay(bool isDark) {
    // Use a unique key based on postIds and initialIndex to force rebuild when post changes
    final key = ValueKey(
      '${_postDetailArgs!.postIds.hashCode}_${_postDetailArgs!.initialIndex}',
    );

    return DesktopPostDetailPage(
      key: key,
      postIds: _postDetailArgs!.postIds,
      initialIndex: _postDetailArgs!.initialIndex,
      onSearchTag: _openSearch,
      onClose: _closePostDetail,
      onLoadMore: _postDetailArgs!.onLoadMore,
      hasMore: _postDetailArgs!.hasMore,
    );
  }
}
