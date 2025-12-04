import 'package:flutter/cupertino.dart';
import '../../core/constants/app_constants.dart';
import '../pages/post/post_detail_page.dart';
import 'pages/desktop_home_page.dart';
import 'pages/desktop_hot_page.dart';
import 'pages/desktop_popular_page.dart';
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
              // Separator
              Container(
                width: 1,
                color: isDark
                    ? AppColors.darkSeparator
                    : AppColors.lightSeparator,
              ),
              // Main content
              Expanded(
                child: _buildMainContent(),
              ),
            ],
          ),
          // Full-screen post detail overlay
          if (_postDetailArgs != null)
            _buildPostDetailOverlay(isDark),
        ],
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
      default:
        return DesktopHomePage(
          onPostTap: _openPostDetail,
          onSearchTap: _openSearch,
        );
    }
  }

  Widget _buildPostDetailOverlay(bool isDark) {
    // Use a unique key based on postIds and initialIndex to force rebuild when post changes
    final key = ValueKey('${_postDetailArgs!.postIds.hashCode}_${_postDetailArgs!.initialIndex}');
    
    return Container(
      color: isDark
          ? CupertinoColors.black.withOpacity(0.85)
          : CupertinoColors.white.withOpacity(0.95),
      child: Stack(
        children: [
          PostDetailPage(
            key: key,
            postIds: _postDetailArgs!.postIds,
            initialIndex: _postDetailArgs!.initialIndex,
            onSearchTag: _openSearch,
          ),
          // Back button
          Positioned(
            top: 12,
            left: 12,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark
                  ? CupertinoColors.systemGrey.withValues(alpha: 0.3)
                  : CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(8),
              onPressed: _closePostDetail,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.back,
                    size: 18,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
