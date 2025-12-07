import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:provider/provider.dart';
import '../../../data/models/user.dart';
import '../../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn || authProvider.currentAccount == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final apiService = ApiService();
      final result = await apiService.getUserProfile(authProvider.currentAccount!.username);
      result.when(
        success: (user) {
          setState(() {
            _user = user;
            _isLoading = false;
            _error = null;
          });
        },
        failure: (error) {
          setState(() {
            _error = error.message;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark = settingsProvider.themeMode == 2 ||
        settingsProvider.themeMode == 3 ||
        (settingsProvider.themeMode == 0 &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final isOled = settingsProvider.themeMode == 3;

    // Show guest profile if in guest mode
    if (authProvider.isGuest) {
      return _buildGuestProfile(context, isDark, isOled);
    }

    if (!authProvider.isLoggedIn) {
      return _buildNotLoggedIn(context, isDark, isOled);
    }

    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null) {
      return _buildError(context, isDark, isOled);
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: const Text('Profile'),
          backgroundColor: isOled
              ? CupertinoColors.black.withValues(alpha: 0.8)
              : isDark
                  ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.8)
                  : CupertinoColors.systemBackground.withValues(alpha: 0.8),
        ),
        CupertinoSliverRefreshControl(
          onRefresh: _loadUserStats,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildProfileHeader(context, authProvider, isDark, isOled),
              const SizedBox(height: 20),
              _buildStatsSection(context, isDark, isOled),
              const SizedBox(height: 20),
              _buildAccountInfoSection(context, authProvider, isDark, isOled),
              const SizedBox(height: 20),
              _buildActionsSection(context, authProvider, isDark, isOled),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildNotLoggedIn(BuildContext context, bool isDark, bool isOled) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLiquidGlassContainer(
              isDark: isDark,
              isOled: isOled,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  CupertinoColors.systemBlue.withValues(alpha: 0.3),
                                  CupertinoColors.systemBlue.withValues(alpha: 0.1),
                                ]
                              : [
                                  CupertinoColors.systemBlue.withValues(alpha: 0.2),
                                  CupertinoColors.systemBlue.withValues(alpha: 0.1),
                                ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.person_circle,
                        size: 64,
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.8)
                            : CupertinoColors.systemBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Not Logged In',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Log in to view your profile, favorites, and more',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.6)
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      color: CupertinoColors.systemBlue,
                      borderRadius: BorderRadius.circular(14),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/login');
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestProfile(BuildContext context, bool isDark, bool isOled) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLiquidGlassContainer(
              isDark: isDark,
              isOled: isOled,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  CupertinoColors.systemGrey.withValues(alpha: 0.3),
                                  CupertinoColors.systemGrey.withValues(alpha: 0.1),
                                ]
                              : [
                                  CupertinoColors.systemGrey.withValues(alpha: 0.2),
                                  CupertinoColors.systemGrey.withValues(alpha: 0.1),
                                ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.person_circle,
                        size: 64,
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.8)
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Guest Mode',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'re browsing as a guest.\nSign in to save favorites, vote, and more.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.6)
                            : CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      color: CupertinoColors.systemBlue,
                      borderRadius: BorderRadius.circular(14),
                      onPressed: () {
                        context.read<AuthProvider>().logout();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, bool isDark, bool isOled) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: _buildLiquidGlassContainer(
          isDark: isDark,
          isOled: isOled,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CupertinoColors.systemRed.withValues(alpha: 0.3),
                        CupertinoColors.systemRed.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 48,
                    color: CupertinoColors.systemRed,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error Loading Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.6)
                        : CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 24),
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: CupertinoColors.systemBlue,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _loadUserStats,
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: CupertinoColors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidGlassContainer({
    required bool isDark,
    required bool isOled,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isOled
                  ? [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.02),
                    ]
                  : isDark
                      ? [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.06),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.6),
                        ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOled
                  ? Colors.white.withValues(alpha: 0.08)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isOled ? 0.4 : 0.1),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, AuthProvider authProvider, bool isDark, bool isOled) {
    // e926 doesn't provide avatar URLs directly, so we always show default
    final username = authProvider.currentAccount?.username ?? 'Unknown';

    return _buildLiquidGlassContainer(
      isDark: isDark,
      isOled: isOled,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar with glow effect
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemBlue.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CupertinoColors.systemBlue.withValues(alpha: 0.3),
                        CupertinoColors.systemPurple.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: _buildDefaultAvatar(isDark),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CupertinoColors.systemGreen.withValues(alpha: 0.3),
                          CupertinoColors.systemGreen.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CupertinoColors.systemGreen.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    CupertinoColors.systemGreen.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _user?.levelString ?? 'Member',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemGreen.darkColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isDark) {
    return Center(
      child: Icon(
        CupertinoIcons.person_fill,
        size: 40,
        color: isDark
            ? CupertinoColors.white.withValues(alpha: 0.6)
            : CupertinoColors.systemGrey,
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isDark, bool isOled) {
    return _buildLiquidGlassContainer(
      isDark: isDark,
      isOled: isOled,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CupertinoColors.systemPurple.withValues(alpha: 0.3),
                        CupertinoColors.systemPurple.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.chart_bar_fill,
                    size: 20,
                    color: isDark
                        ? CupertinoColors.systemPurple.withValues(alpha: 0.8)
                        : CupertinoColors.systemPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: CupertinoIcons.heart_fill,
                    label: 'Favorites',
                    value: _user?.favoriteCount.toString() ?? '0',
                    color: CupertinoColors.systemPink,
                    isDark: isDark,
                    isOled: isOled,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: CupertinoIcons.photo_fill,
                    label: 'Uploads',
                    value: _user?.postUploadCount.toString() ?? '0',
                    color: CupertinoColors.systemBlue,
                    isDark: isDark,
                    isOled: isOled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: CupertinoIcons.tag_fill,
                    label: 'Tag Edits',
                    value: _user?.postUpdateCount.toString() ?? '0',
                    color: CupertinoColors.systemOrange,
                    isDark: isDark,
                    isOled: isOled,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: CupertinoIcons.text_bubble_fill,
                    label: 'Note Edits',
                    value: _user?.noteUpdateCount.toString() ?? '0',
                    color: CupertinoColors.systemTeal,
                    isDark: isDark,
                    isOled: isOled,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required bool isOled,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOled
              ? [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ]
              : isDark
                  ? [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ]
                  : [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.05),
                    ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.6)
                  : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection(
      BuildContext context, AuthProvider authProvider, bool isDark, bool isOled) {
    return _buildLiquidGlassContainer(
      isDark: isDark,
      isOled: isOled,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CupertinoColors.systemBlue.withValues(alpha: 0.3),
                        CupertinoColors.systemBlue.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.info_circle_fill,
                    size: 20,
                    color: isDark
                        ? CupertinoColors.systemBlue.withValues(alpha: 0.8)
                        : CupertinoColors.systemBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Account Info',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              icon: CupertinoIcons.person,
              label: 'Username',
              value: authProvider.currentAccount?.username ?? 'Unknown',
              isDark: isDark,
            ),
            _buildInfoRow(
              icon: CupertinoIcons.number,
              label: 'User ID',
              value: _user?.id.toString() ?? 'N/A',
              isDark: isDark,
            ),
            _buildInfoRow(
              icon: CupertinoIcons.calendar,
              label: 'Member Since',
              value: _formatDateTime(_user?.createdAt),
              isDark: isDark,
            ),
            _buildInfoRow(
              icon: CupertinoIcons.shield,
              label: 'Level',
              value: _user?.levelString ?? 'Member',
              isDark: isDark,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark
                ? CupertinoColors.white.withValues(alpha: 0.5)
                : CupertinoColors.systemGrey,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.6)
                  : CupertinoColors.systemGrey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(
      BuildContext context, AuthProvider authProvider, bool isDark, bool isOled) {
    return _buildLiquidGlassContainer(
      isDark: isDark,
      isOled: isOled,
      child: Column(
        children: [
          _buildActionTile(
            icon: CupertinoIcons.heart_fill,
            label: 'My Favorites',
            color: CupertinoColors.systemPink,
            isDark: isDark,
            onTap: () => Navigator.of(context).pushNamed('/favorites'),
          ),
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
          _buildActionTile(
            icon: CupertinoIcons.gear,
            label: 'Settings',
            color: CupertinoColors.systemGrey,
            isDark: isDark,
            onTap: () => Navigator.of(context).pushNamed('/settings'),
          ),
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
          ),
          _buildActionTile(
            icon: CupertinoIcons.square_arrow_right,
            label: 'Log Out',
            color: CupertinoColors.systemRed,
            isDark: isDark,
            isDestructive: true,
            onTap: () => _showLogoutConfirmation(context, authProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: isDestructive
                      ? CupertinoColors.systemRed
                      : isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.3)
                  : CupertinoColors.systemGrey.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, AuthProvider authProvider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Log Out'),
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.logout();
            },
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
