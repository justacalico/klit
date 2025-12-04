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
      _postDetailArgs = null;
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
      child: Row(
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
          // Post detail panel (if open)
          if (_postDetailArgs != null) ...[
            Container(
              width: 1,
              color: isDark
                  ? AppColors.darkSeparator
                  : AppColors.lightSeparator,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: _buildPostDetailPanel(),
            ),
          ],
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

  Widget _buildPostDetailPanel() {
    // Use a unique key based on postIds and initialIndex to force rebuild when post changes
    final key = ValueKey('${_postDetailArgs!.postIds.hashCode}_${_postDetailArgs!.initialIndex}');
    
    return Stack(
      children: [
        PostDetailPage(
          key: key,
          postIds: _postDetailArgs!.postIds,
          initialIndex: _postDetailArgs!.initialIndex,
          onSearchTag: _openSearch,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: _closePostDetail,
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}
