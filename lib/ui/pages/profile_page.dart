import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/constants/constants.dart';
import '../../core/extensions/extensions.dart';
import '../../core/types/navigation_args.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';
import '../../providers/providers.dart';
import '../layout/layout_scope.dart';
import '../shell/toolbar.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

/// Unified profile page - single file for all layouts.
/// When [username] is set, shows that user's profile (e.g. from "View profile" on a post). Otherwise shows the current account's profile.
class UiProfilePage extends StatefulWidget {
  final void Function(String route)? onNavigate;
  final void Function(PostDetailArguments)? onPostTap;
  final String? username;

  const UiProfilePage({
    super.key,
    this.onNavigate,
    this.onPostTap,
    this.username,
  });

  @override
  State<UiProfilePage> createState() => _UiProfilePageState();
}

class _UiProfilePageState extends State<UiProfilePage> {
  User? _user;
  String? _avatarUrl;
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0;

  // Uploads tab
  List<Post> _uploads = [];
  int _uploadsPage = 1;
  bool _uploadsLoading = false;
  bool _uploadsLoadingMore = false;
  bool _uploadsHasMore = true;
  String? _uploadsError;

  // Favorites tab
  List<Post> _favorites = [];
  int _favoritesPage = 1;
  bool _favoritesLoading = false;
  bool _favoritesLoadingMore = false;
  bool _favoritesHasMore = true;
  String? _favoritesError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  bool get _viewingOtherUser =>
      widget.username != null && widget.username!.isNotEmpty;

  Future<void> _loadProfile() async {
    final apiService = context.read<ApiService>();
    final String? loadUsername = _viewingOtherUser
        ? widget.username
        : context.read<AuthProvider>().currentAccount?.username;

    if (!_viewingOtherUser && loadUsername == null) {
      setState(() {
        _isLoading = false;
        _error = 'Not logged in';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await apiService.getUserProfile(loadUsername!);

    if (mounted) {
      result.when(
        success: (user) async {
          if (!_viewingOtherUser &&
              user.blacklistedTags != null &&
              user.blacklistedTags!.isNotEmpty) {
            final settingsProvider = context.read<SettingsProvider>();
            settingsProvider.setBlacklist(user.blacklistedTags!);
          }
          String? avatarUrl;
          if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
            avatarUrl = user.avatarUrl!.startsWith(RegExp(r'https?://'))
                ? user.avatarUrl
                : '${apiService.baseUrl}/${user.avatarUrl!.startsWith('/') ? user.avatarUrl!.substring(1) : user.avatarUrl}';
          } else if (user.avatarId != null && user.avatarId!.isNotEmpty) {
            final postId = int.tryParse(user.avatarId!);
            if (postId != null) {
              final postResult = await apiService.getPostById(postId);
              postResult.when(
                success: (post) {
                  avatarUrl = post.preview.url ?? post.sample.url;
                },
                failure: (_) {},
              );
            }
          }
          if (mounted) {
            setState(() {
              _user = user;
              _avatarUrl = avatarUrl;
              _isLoading = false;
            });
          }
        },
        failure: (error) {
          setState(() {
            _error = error.message;
            _isLoading = false;
          });
        },
      );
    }
  }

  Future<void> _loadUploads({bool refresh = false}) async {
    if (_user == null) return;
    if (refresh) {
      setState(() {
        _uploadsPage = 1;
        _uploadsHasMore = true;
        _uploadsLoading = true;
        _uploadsError = null;
      });
    } else if (_uploadsPage > 1) {
      setState(() => _uploadsLoadingMore = true);
    }

    final apiService = context.read<ApiService>();
    final settingsProvider = context.read<SettingsProvider>();
    final result = await apiService.getPosts(
      tags: 'user:${_user!.name}',
      order: 'desc',
      page: _uploadsPage,
      limit: 50,
      safeMode: settingsProvider.safeMode,
    );

    if (!mounted) return;
    result.when(
      success: (posts) {
        setState(() {
          if (refresh || _uploadsPage == 1) {
            _uploads = posts;
          } else {
            _uploads.addAll(posts);
          }
          _uploadsHasMore = posts.length >= 50;
          _uploadsLoading = false;
          _uploadsLoadingMore = false;
        });
      },
      failure: (error) {
        setState(() {
          _uploadsError = error.message;
          _uploadsLoading = false;
          _uploadsLoadingMore = false;
        });
      },
    );
  }

  Future<void> _loadFavorites({bool refresh = false}) async {
    if (_user == null) return;
    if (refresh) {
      setState(() {
        _favoritesPage = 1;
        _favoritesHasMore = true;
        _favoritesLoading = true;
        _favoritesError = null;
      });
    } else if (_favoritesPage > 1) {
      setState(() => _favoritesLoadingMore = true);
    }

    final apiService = context.read<ApiService>();
    final settingsProvider = context.read<SettingsProvider>();
    final result = await apiService.getFavorites(
      username: _user!.name,
      page: _favoritesPage,
      limit: 50,
      safeMode: settingsProvider.safeMode,
    );

    if (!mounted) return;
    result.when(
      success: (posts) {
        setState(() {
          if (refresh || _favoritesPage == 1) {
            _favorites = posts;
          } else {
            _favorites.addAll(posts);
          }
          _favoritesHasMore = posts.length >= 50;
          _favoritesLoading = false;
          _favoritesLoadingMore = false;
        });
      },
      failure: (error) {
        setState(() {
          _favoritesError = error.message;
          _favoritesLoading = false;
          _favoritesLoadingMore = false;
        });
      },
    );
  }

  void _navigateToSettingsAccount() {
    Navigator.of(context).pushNamed(AppRoutes.settings, arguments: 'account');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return KeyedSubtree(
      key: const ValueKey('profile-page'),
      child: Column(
        children: [
          _buildToolbar(isDark),
          Expanded(child: _buildContent(isDark)),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isDark) {
    if (_viewingOtherUser) {
      return PageToolbar(
        title: widget.username ?? '',
        icon: CupertinoIcons.person_fill,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
        actions: [
          ToolbarButton(
            icon: CupertinoIcons.refresh,
            tooltip: 'Refresh',
            onPressed: _loadProfile,
          ),
        ],
      );
    }
    return PageToolbar(
      title: 'Profile',
      icon: CupertinoIcons.person_fill,
      actions: [
        ToolbarButton(
          icon: CupertinoIcons.refresh,
          tooltip: 'Refresh',
          onPressed: _loadProfile,
        ),
        const SizedBox(width: 8),
        ToolbarButton(
          icon: CupertinoIcons.gear,
          tooltip: 'Account Settings',
          onPressed: _navigateToSettingsAccount,
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    final authProvider = context.watch<AuthProvider>();

    if (!_viewingOtherUser && authProvider.isGuest) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.person_crop_circle,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Guest Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to save favorites, vote, and view your profile',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () {
                authProvider.logout();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final account = authProvider.currentAccount;
    if (!_viewingOtherUser && (account == null || _user == null)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.person_crop_circle,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'Not logged in',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to view your profile',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    }

    if (_user == null) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    final mode = LayoutScope.of(context);
    final isNarrow = !mode.isDesktop;
    final isOled = context.watch<SettingsProvider>().themeMode == 3;
    final host = _viewingOtherUser
        ? context.read<SettingsProvider>().host
        : account?.host ?? context.read<SettingsProvider>().host;

    return Column(
      children: [
        _buildProfileTabBar(isDark, isOled),
        Expanded(
          child: IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildMainTabContent(host, isDark, isOled, isNarrow),
              _buildUploadsTabContent(isDark),
              _buildFavoritesTabContent(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTabBar(bool isDark, bool isOled) {
    const labels = ['Main', 'Uploads', 'Favorites'];
    final bg = isDark
        ? const Color(0xFF0F1015)
        : AppColors.resolveSecondaryBackground(isDark, isOled: isOled);
    const selectedBg = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    );
    final unselectedBg = isDark
        ? CupertinoColors.white.withValues(alpha: 0.04)
        : CupertinoColors.black.withValues(alpha: 0.03);
    final unselectedTextColor = isDark
        ? const Color(0xFFB4B8C8)
        : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                .withValues(alpha: isDark ? 0.08 : 0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(
                alpha: isDark ? 0.32 : 0.08,
              ),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(3, (index) {
            final selected = _selectedTabIndex == index;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() => _selectedTabIndex = index);
                    if (index == 1 && _uploads.isEmpty && !_uploadsLoading) {
                      _loadUploads(refresh: true);
                    }
                    if (index == 2 &&
                        _favorites.isEmpty &&
                        !_favoritesLoading) {
                      _loadFavorites(refresh: true);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: selected ? selectedBg : null,
                      color: selected ? null : unselectedBg,
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.2,
                              ),
                            )
                          : Border.all(
                              color:
                                  (isDark
                                          ? CupertinoColors.white
                                          : CupertinoColors.black)
                                      .withValues(alpha: 0.05),
                            ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selected
                            ? (isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.black)
                            : unselectedTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMainTabContent(
    String host,
    bool isDark,
    bool isOled,
    bool isNarrow,
  ) {
    final hostLabel = host.replaceAll(RegExp(r'https?://'), '');
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHero(hostLabel, _user!, isDark),
              const SizedBox(height: 14),
              _buildStatsGrid(_user!, isDark, isOled, isNarrow),
              const SizedBox(height: 16),
              _buildAccountInfoCard(_user!, isDark, isOled),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadsTabContent(bool isDark) {
    if (_uploads.isEmpty && _uploadsLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }
    if (_uploads.isEmpty && _uploadsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _uploadsError!,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: () => _loadUploads(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_uploads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.cloud_upload_fill,
              size: 64,
              color: AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No uploads',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _viewingOtherUser
                  ? 'This user has not uploaded any posts'
                  : 'Your uploads will appear here',
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return PostsGrid(
      posts: _uploads,
      isLoading: _uploadsLoadingMore,
      hasMore: _uploadsHasMore,
      onPostTap: _onUploadsPostTap,
      onLoadMore: () async {
        setState(() => _uploadsPage++);
        await _loadUploads();
      },
      onRetry: () => _loadUploads(refresh: true),
    );
  }

  Widget _buildFavoritesTabContent(bool isDark) {
    if (_favorites.isEmpty && _favoritesLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }
    if (_favorites.isEmpty && _favoritesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              _favoritesError!,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: () => _loadFavorites(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.heart,
              size: 64,
              color: AppColors.explicitColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _viewingOtherUser
                  ? 'This user has no favorites'
                  : 'Posts you favorite will appear here',
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return PostsGrid(
      posts: _favorites,
      isLoading: _favoritesLoadingMore,
      hasMore: _favoritesHasMore,
      onPostTap: _onFavoritesPostTap,
      onLoadMore: () async {
        setState(() => _favoritesPage++);
        await _loadFavorites();
      },
      onRetry: () => _loadFavorites(refresh: true),
    );
  }

  void _onUploadsPostTap(Post post) {
    final index = _uploads.indexWhere((p) => p.id == post.id);
    widget.onPostTap?.call(
      PostDetailArguments(
        postIds: _uploads.map((p) => p.id).toList(),
        initialIndex: index >= 0 ? index : 0,
        hasMore: _uploadsHasMore,
        initialPosts: List<Post?>.from(_uploads),
        onLoadMore: () async {
          setState(() => _uploadsPage++);
          await _loadUploads();
          return _uploads.map((p) => p.id).toList();
        },
      ),
    );
  }

  void _onFavoritesPostTap(Post post) {
    final index = _favorites.indexWhere((p) => p.id == post.id);
    widget.onPostTap?.call(
      PostDetailArguments(
        postIds: _favorites.map((p) => p.id).toList(),
        initialIndex: index >= 0 ? index : 0,
        hasMore: _favoritesHasMore,
        initialPosts: List<Post?>.from(_favorites),
        onLoadMore: () async {
          setState(() => _favoritesPage++);
          await _loadFavorites();
          return _favorites.map((p) => p.id).toList();
        },
      ),
    );
  }

  Widget _buildProfileHero(String hostLabel, User user, bool isDark) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final levelColor = _getLevelColor(user.level);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF181124), const Color(0xFF0E1020)]
                  : [
                      UIColors.primaryPurple.withValues(alpha: 0.08),
                      UIColors.primaryIndigo.withValues(alpha: 0.06),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? UIColors.primaryPurple.withValues(alpha: 0.4)
                  : UIColors.primaryPurple.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: UIColors.primaryPurple.withValues(
                  alpha: isDark ? 0.18 : 0.08,
                ),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: UIColors.primaryPurple.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: UIColors.primaryPurple.withValues(alpha: 0.25),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: _buildAvatar(initial, isDark),
              ),
              const SizedBox(height: 14),
              Text(
                user.name,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark
                      ? CupertinoColors.white
                      : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: levelColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      user.levelString,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: levelColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.05)
                          : CupertinoColors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      hostLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFB8B8C2)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
              if (user.isBanned) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.explicitColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Banned',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.explicitColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String initial, bool isDark) {
    const size = 96.0;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            UIColors.primaryIndigo.withValues(alpha: 0.9),
            UIColors.primaryPurple.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
    if (_avatarUrl == null || _avatarUrl!.isEmpty) return fallback;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: _avatarUrl!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          placeholder: (_, _) => fallback,
          errorWidget: (_, _, _) => fallback,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(User user, bool isDark, bool isOled, bool isNarrow) {
    final stats = [
      _StatItem(
        CupertinoIcons.heart_fill,
        'Favorites',
        user.favoriteCount.compact,
        AppColors.explicitColor,
      ),
      _StatItem(
        CupertinoIcons.cloud_upload_fill,
        'Uploads',
        user.postUploadCount.compact,
        AppColors.primaryBlue,
      ),
      _StatItem(
        CupertinoIcons.pencil,
        'Post Edits',
        user.postUpdateCount.compact,
        AppColors.primaryGreen,
      ),
      _StatItem(
        CupertinoIcons.text_badge_plus,
        'Note Updates',
        user.noteUpdateCount.compact,
        UIColors.primaryPurple,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = isNarrow ? 2 : 4;
        final spacing = 12.0;
        final totalSpacing = (crossCount - 1) * spacing;
        final itemWidth = (constraints.maxWidth - totalSpacing) / crossCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats
              .map(
                (s) => SizedBox(
                  width: itemWidth,
                  child: _buildStatTile(s, isDark, isOled),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildStatTile(_StatItem item, bool isDark, bool isOled) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0E1016)
            : AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.color.withValues(alpha: isDark ? 0.28 : 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(
              alpha: isDark ? 0.24 : 0.06,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: item.color.withValues(alpha: 0.3)),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: isDark
                        ? CupertinoColors.white
                        : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFA3A8B8)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(User user, bool isDark, bool isOled) {
    final rows = <_InfoRow>[
      _InfoRow('User ID', '#${user.id}'),
      _InfoRow('Member Since', user.createdAt.relativeTime),
      _InfoRow('Account Age', user.accountAge),
      _InfoRow(
        'Feedback',
        '+${user.positiveFeedbackCount} / ${user.neutralFeedbackCount} / -${user.negativeFeedbackCount}',
      ),
    ];
    if (user.canApprovePosts) rows.add(const _InfoRow('Can Approve', 'Yes'));
    if (user.canUploadFree) rows.add(const _InfoRow('Unlimited Upload', 'Yes'));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F1118)
            : AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? CupertinoColors.white : CupertinoColors.black)
              .withValues(alpha: isDark ? 0.08 : 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.person_crop_rectangle,
                  size: 16,
                  color: isDark
                      ? const Color(0xFFB9BED0)
                      : const Color(0xFF4B5563),
                ),
                const SizedBox(width: 8),
                Text(
                  'Account Info',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? CupertinoColors.white
                        : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Container(
              height: 1,
              color: AppColors.resolveSeparator(isDark, isOled: isOled),
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          e.value.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFA0A5B5)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          e.value.value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? CupertinoColors.white
                                : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Container(
                      height: 1,
                      color: AppColors.resolveSeparator(isDark, isOled: isOled),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level >= 34) return AppColors.explicitColor;
    if (level >= 32) return AppColors.primaryPurple;
    if (level >= 30) return AppColors.primaryGreen;
    return AppColors.primaryBlue;
  }
}

class _StatItem {
  const _StatItem(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _InfoRow {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
}
