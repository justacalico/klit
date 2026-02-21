import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/constants/constants.dart';
import '../../core/extensions/extensions.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';
import '../../providers/providers.dart';
import '../layout/layout_scope.dart';
import '../shell/toolbar.dart';
import '../theme.dart';

/// Unified profile page - single file for all layouts.
/// When [username] is set, shows that user's profile (e.g. from "View profile" on a post). Otherwise shows the current account's profile.
class UiProfilePage extends StatefulWidget {
  final void Function(String route)? onNavigate;
  final String? username;

  const UiProfilePage({super.key, this.onNavigate, this.username});

  @override
  State<UiProfilePage> createState() => _UiProfilePageState();
}

class _UiProfilePageState extends State<UiProfilePage> {
  User? _user;
  String? _avatarUrl;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  bool get _viewingOtherUser => widget.username != null && widget.username!.isNotEmpty;

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
            const Text(
              'Guest Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to save favorites, vote, and view your profile',
              style: TextStyle(color: CupertinoColors.systemGrey),
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
              style: const TextStyle(color: CupertinoColors.systemGrey),
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
            const Text(
              'Not logged in',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to view your profile',
              style: TextStyle(color: CupertinoColors.systemGrey),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              _buildProfileHero(host, _user!, isDark),
              const SizedBox(height: 20),
              _buildStatsGrid(_user!, isDark, isOled, isNarrow),
              const SizedBox(height: 20),
              _buildAccountInfoCard(_user!, isDark, isOled),
              if (!_viewingOtherUser) ...[
                const SizedBox(height: 20),
                _buildActionsCard(context, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero(String host, User user, bool isDark) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final levelColor = _getLevelColor(user.level);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryPurple.withValues(alpha: 0.12),
                      UIColors.primaryIndigo.withValues(alpha: 0.08),
                    ]
                  : [
                      UIColors.primaryPurple.withValues(alpha: 0.08),
                      UIColors.primaryIndigo.withValues(alpha: 0.06),
                    ],
            ),
            border: Border.all(
              color: UIColors.primaryPurple.withValues(
                alpha: isDark ? 0.25 : 0.15,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildAvatar(initial, isDark),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      user.levelString,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: levelColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    host.replaceAll(RegExp(r'https?://'), ''),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey,
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
      _StatItem(CupertinoIcons.heart_fill, 'Favorites', user.favoriteCount.compact, AppColors.explicitColor),
      _StatItem(CupertinoIcons.cloud_upload_fill, 'Uploads', user.postUploadCount.compact, AppColors.primaryBlue),
      _StatItem(CupertinoIcons.pencil, 'Post Edits', user.postUpdateCount.compact, AppColors.primaryGreen),
      _StatItem(CupertinoIcons.text_badge_plus, 'Note Updates', user.noteUpdateCount.compact, UIColors.primaryPurple),
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
          children: stats.map((s) => SizedBox(
            width: itemWidth,
            child: _buildStatTile(s, isDark, isOled),
          )).toList(),
        );
      },
    );
  }

  Widget _buildStatTile(_StatItem item, bool isDark, bool isOled) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: item.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? CupertinoColors.systemGrey : const Color(0xFF6B7280),
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
        color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Text(
              'Account Info',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.value.label,
                        style: const TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      Text(
                        e.value.value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
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

  Widget _buildActionsCard(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            onPressed: _navigateToSettingsAccount,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: UIColors.primaryIndigo.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.person_2, color: UIColors.primaryIndigo, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Manage Accounts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: UIColors.primaryIndigo,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            onPressed: () => _showSignOutConfirmation(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.destructiveRed.withValues(alpha: 0.12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_right_square,
                    color: CupertinoColors.destructiveRed,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (mounted) {
                navigator.pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
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
