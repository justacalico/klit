import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/material.dart'
    show Colors, Divider, InkWell, ListTile, Material, ReorderableListView;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/routes.dart';
import '../../core/constants/constants.dart';
import '../layout/layout_scope.dart';
import '../../core/theme/ui_style_manager.dart';
import '../../data/models/models.dart';
import '../../data/models/proxy_config.dart';
import '../../data/services/services.dart';
import '../../data/services/update_service.dart';
import '../../providers/providers.dart';

/// Design constants for the settings page
class _DesignColors {
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentGreen = Color(0xFF22C55E);
}

/// Settings category definition
class _SettingsCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  const _SettingsCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}

/// Unified settings page - single file for all layouts.
class UiSettingsPage extends StatefulWidget {
  final Function(String) onNavigate;

  const UiSettingsPage({super.key, required this.onNavigate});

  @override
  State<UiSettingsPage> createState() => _UiSettingsPageState();
}

class _UiSettingsPageState extends State<UiSettingsPage>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'account';
  /// On mobile: true = show main list (iOS style), false = show selected category sub-page.
  bool _mobileShowMainList = true;
  final _mobileSearchController = TextEditingController();
  final _mobileSearchFocus = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _appVersion = '...';
  String _sidebarSearchQuery = '';
  final _sidebarSearchController = TextEditingController();
  final _sidebarSearchFocus = FocusNode();
  String? _accountAvatarUrl;
  String? _accountAvatarUsername;
  bool _accountAvatarLoading = false;
  /// Glow/border color derived from the account avatar image; null until extracted or when no avatar.
  Color? _accountAvatarPaletteColor;

  static const List<_SettingsCategory> _categories = [
    _SettingsCategory(
      id: 'account',
      title: 'Account',
      icon: CupertinoIcons.person_circle_fill,
      color: _DesignColors.primaryPurple,
    ),
    _SettingsCategory(
      id: 'appearance',
      title: 'Appearance',
      icon: CupertinoIcons.paintbrush_fill,
      color: _DesignColors.primaryIndigo,
    ),
    _SettingsCategory(
      id: 'content',
      title: 'Content',
      icon: CupertinoIcons.photo_fill_on_rectangle_fill,
      color: _DesignColors.accentPink,
    ),
    _SettingsCategory(
      id: 'behavior',
      title: 'Behavior',
      icon: CupertinoIcons.sparkles,
      color: _DesignColors.accentOrange,
    ),
    _SettingsCategory(
      id: 'video',
      title: 'Video',
      icon: CupertinoIcons.play_rectangle_fill,
      color: _DesignColors.primaryIndigo,
    ),
    _SettingsCategory(
      id: 'customization',
      title: 'Customization',
      icon: CupertinoIcons.slider_horizontal_3,
      color: _DesignColors.accentTeal,
    ),
    _SettingsCategory(
      id: 'data',
      title: 'Data',
      icon: CupertinoIcons.tray_full_fill,
      color: CupertinoColors.systemBlue,
    ),
    _SettingsCategory(
      id: 'network',
      title: 'Network',
      icon: CupertinoIcons.globe,
      color: _DesignColors.accentGreen,
    ),
    _SettingsCategory(
      id: 'about',
      title: 'About',
      icon: CupertinoIcons.info_circle_fill,
      color: CupertinoColors.systemGrey,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = packageInfo.version);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sidebarSearchController.dispose();
    _sidebarSearchFocus.dispose();
    _mobileSearchController.dispose();
    _mobileSearchFocus.dispose();
    super.dispose();
  }

  void _selectCategory(String id) {
    if (_selectedCategory == id) return;
    _animationController.reverse().then((_) {
      setState(() => _selectedCategory = id);
      _animationController.forward();
    });
  }

  Future<void> _loadAccountAvatar(BuildContext context, String username) async {
    final api = context.read<ApiService>();
    String? url;
    final userResult = await api.getUserProfile(username);
    await userResult.when(
      success: (user) async {
        if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
          url = user.avatarUrl!.startsWith(RegExp(r'https?://'))
              ? user.avatarUrl
              : '${api.baseUrl}/${user.avatarUrl!.startsWith('/') ? user.avatarUrl!.substring(1) : user.avatarUrl}';
        } else if (user.avatarId != null && user.avatarId!.isNotEmpty) {
          final postId = int.tryParse(user.avatarId!);
          if (postId != null) {
            final postResult = await api.getPostById(postId);
            postResult.when(
              success: (post) {
                url = post.preview.url ?? post.sample.url;
              },
              failure: (_) {},
            );
          }
        }
      },
      failure: (_) {},
    );
    if (mounted) {
      setState(() {
        _accountAvatarUrl = url;
        _accountAvatarUsername = username;
        _accountAvatarLoading = false;
        _accountAvatarPaletteColor = null;
      });
      final u = url;
      if (u != null && u.isNotEmpty) {
        _extractAvatarPalette(u);
      }
    }
  }

  Future<void> _extractAvatarPalette(String imageUrl) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        size: const Size(64, 64),
      );
      if (!mounted || _accountAvatarUrl != imageUrl) return;
      final color = palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.darkVibrantColor?.color ??
          palette.mutedColor?.color;
      if (color != null) {
        setState(() => _accountAvatarPaletteColor = color);
      }
    } catch (_) {
      // Keep default glow on extraction failure
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final isOled = context.watch<SettingsProvider>().themeMode == 3;
    final mode = LayoutScope.of(context);

    return KeyedSubtree(
      key: const ValueKey('settings-page'),
      child: Container(
        color: isOled
            ? AppColors.oledBackground
            : (isDark ? const Color(0xFF0D0D0F) : const Color(0xFFF5F5F7)),
        child: mode.isDesktop
            ? Row(
                children: [
                  _buildSidebar(isDark, isOled),
                  Expanded(child: _buildMainContent(isDark)),
                ],
              )
            : _buildMobileLayout(context, isDark),
      ),
    );
  }

  /// Mobile layout: iOS-style main list of categories, then sub-pages for each
  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    final isOled = context.watch<SettingsProvider>().themeMode == 3;
    if (!_mobileShowMainList) {
      return _buildMobileSubPage(context, isDark, isOled);
    }
    return _buildMobileMainList(context, isDark);
  }

  /// iOS-style main list: search + rows with icon, title, chevron
  Widget _buildMobileMainList(BuildContext context, bool isDark) {
    final query = _mobileSearchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _categories
        : _categories
            .where((c) => c.title.toLowerCase().contains(query))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search bar (iOS "Search Settings" style)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: CupertinoSearchTextField(
            controller: _mobileSearchController,
            focusNode: _mobileSearchFocus,
            placeholder: 'Search Settings',
            style: TextStyle(
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            onChanged: (_) => setState(() {}),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : CupertinoColors.tertiarySystemFill,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final category = filtered[index];
              return _buildMobileMainListRow(category, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileMainListRow(_SettingsCategory category, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _selectCategory(category.id);
          setState(() => _mobileShowMainList = false);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(category.icon, size: 18, color: category.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  category.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 18,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mobile sub-page: nav bar with back + category title, then category content
  Widget _buildMobileSubPage(BuildContext context, bool isDark, bool isOled) {
    final category = _categories.firstWhere((c) => c.id == _selectedCategory);

    return Column(
      children: [
        // Nav bar: back + title (iOS style)
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
            border: Border(
              bottom: BorderSide(
                color: AppColors.resolveSeparator(isDark, isOled: isOled),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: () => setState(() => _mobileShowMainList = true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.back,
                      color: _DesignColors.primaryPurple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 17,
                        color: _DesignColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  category.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 80),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildCategoryContent(isDark),
          ),
        ),
      ],
    );
  }

  /// macOS-style sidebar: search at top, list with blue highlight for selected
  Widget _buildSidebar(bool isDark, bool isOled) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isOled
            ? AppColors.oledSecondaryBackground
            : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F7)),
        border: Border(
          right: BorderSide(
            color: isOled
                ? AppColors.oledSeparator
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E7)),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar (macOS System Settings style)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.08)
                    : CupertinoColors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 16,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _sidebarSearchController,
                      focusNode: _sidebarSearchFocus,
                      padding: EdgeInsets.zero,
                      placeholder: 'Search',
                      placeholderStyle: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                      decoration: const BoxDecoration(),
                      onChanged: (v) =>
                          setState(() => _sidebarSearchQuery = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Category list (selected = light blue background); filter by search
          Expanded(
            child: Builder(
              builder: (context) {
                final query = _sidebarSearchQuery.trim().toLowerCase();
                final list = query.isEmpty
                    ? _categories
                    : _categories
                        .where((c) =>
                            c.title.toLowerCase().contains(query))
                        .toList();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final category = list[index];
                    final isSelected = _selectedCategory == category.id;
                    return _buildCategoryItem(category, isSelected, isDark);
                  },
                );
              },
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Klit $_appVersion',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    _SettingsCategory category,
    bool isSelected,
    bool isDark,
  ) {
    const blueHighlight = Color(0xFFE8F4FC);
    const blueHighlightDark = Color(0xFF2A3F52);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        onTap: () => _selectCategory(category.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? blueHighlightDark : blueHighlight)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                category.icon,
                size: 20,
                color: isSelected
                    ? (isDark ? category.color : CupertinoColors.activeBlue)
                    : (isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    final category = _categories.firstWhere((c) => c.id == _selectedCategory);
    final mode = LayoutScope.of(context);
    final contentPadding = mode.isMobile ? 16.0 : 32.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (card on mobile, bar on desktop)
        _buildContentHeader(category, isDark),
        // Content
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(contentPadding),
              child: _buildCategoryContent(isDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentHeader(_SettingsCategory category, bool isDark) {
    final mode = LayoutScope.of(context);
    final isCompact = mode.isMobile;
    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 32,
        isCompact ? 12 : 24,
        isCompact ? 16 : 32,
        isCompact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: isCompact
            ? (isDark ? const Color(0xFF1C1C1E) : const Color(0xFF2C2C2E))
            : null,
        borderRadius: isCompact ? BorderRadius.circular(16) : null,
        border: isCompact
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? _DesignColors.primaryPurple.withValues(alpha: 0.1)
                      : const Color(0xFFE5E5E7),
                  width: 1,
                ),
              ),
      ),
      margin: isCompact
          ? const EdgeInsets.fromLTRB(16, 0, 16, 12)
          : EdgeInsets.zero,
      child: Row(
        children: [
          Icon(
            category.icon,
            size: isCompact ? 28 : 24,
            color: category.color,
          ),
          SizedBox(width: isCompact ? 14 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: TextStyle(
                    fontSize: isCompact ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getCategoryDescription(category.id),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryDescription(String id) {
    switch (id) {
      case 'account':
        return 'Manage your account and login';
      case 'appearance':
        return 'Customize the look and feel';
      case 'content':
        return 'Configure content display options';
      case 'behavior':
        return 'Adjust app behavior and animations';
      case 'video':
        return 'Video playback settings';
      case 'customization':
        return 'Personalize your experience';
      case 'data':
        return 'Manage search history and cache';
      case 'network':
        return 'Network and proxy settings';
      case 'about':
        return 'About Klit';
      default:
        return '';
    }
  }

  Widget _buildCategoryContent(bool isDark) {
    switch (_selectedCategory) {
      case 'account':
        return _buildAccountContent(isDark);
      case 'appearance':
        return _buildAppearanceContent(isDark);
      case 'content':
        return _buildContentSettings(isDark);
      case 'behavior':
        return _buildBehaviorContent(isDark);
      case 'video':
        return _buildVideoContent(isDark);
      case 'customization':
        return _buildCustomizationContent(isDark);
      case 'data':
        return _buildDataContent(isDark);
      case 'network':
        return _buildNetworkContent(isDark);
      case 'about':
        return _buildAboutContent(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1C1C1E).withValues(alpha: 0.8),
                      const Color(0xFF2C2C2E).withValues(alpha: 0.6),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                      const Color(0xFFF8F8FA).withValues(alpha: 0.8),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? _DesignColors.primaryPurple.withValues(alpha: 0.15)
                  : const Color(0xFFE5E5E7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? CupertinoColors.black.withValues(alpha: 0.3)
                    : CupertinoColors.systemGrey.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2,
                      ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 1,
        color: isDark
            ? _DesignColors.primaryPurple.withValues(alpha: 0.1)
            : const Color(0xFFE5E5E7),
      ),
    );
  }

  // Account Content
  Widget _buildAccountContent(bool isDark) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final account = authProvider.currentAccount;
        final isGuest = authProvider.isGuest;

        if (!isGuest && account != null) {
          if (_accountAvatarUsername != account.username) {
            _accountAvatarUrl = null;
            _accountAvatarUsername = null;
            _accountAvatarPaletteColor = null;
          }
          if (_accountAvatarUrl == null && !_accountAvatarLoading) {
            final username = account.username;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _accountAvatarLoading) return;
              setState(() => _accountAvatarLoading = true);
              _loadAccountAvatar(context, username);
            });
          }
        }

        final avatarUrl = (!isGuest && account != null && _accountAvatarUsername == account.username)
            ? _accountAvatarUrl
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildAccountAvatar(
                        isDark: isDark,
                        isGuest: isGuest,
                        username: account?.username,
                        avatarUrl: avatarUrl,
                        isLoading: _accountAvatarLoading && !isGuest,
                        paletteColor: _accountAvatarPaletteColor,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isGuest
                                  ? 'Guest Mode'
                                  : (account?.username ?? 'Not logged in'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isGuest
                                  ? 'Sign in to access all features'
                                  : (account?.host ?? ''),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.systemGrey2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        color: _DesignColors.primaryPurple,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () {
                          if (isGuest) {
                            authProvider.logout();
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            );
                          } else {
                            widget.onNavigate(AppRoutes.accountManagement);
                          }
                        },
                        child: Text(
                          isGuest ? 'Sign In' : 'Manage',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isGuest) ...[
              const SizedBox(height: 16),
              _buildSettingsCard(
                isDark: isDark,
                child: _buildSettingRow(
                  isDark: isDark,
                  icon: CupertinoIcons.globe,
                  iconColor: _DesignColors.accentGreen,
                  title: 'Server Configuration',
                  subtitle: 'Change API host',
                  trailing: Icon(
                    CupertinoIcons.chevron_right,
                    size: 18,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2,
                  ),
                  onTap: () => widget.onNavigate(AppRoutes.hostSettings),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAccountAvatar({
    required bool isDark,
    required bool isGuest,
    required String? username,
    required String? avatarUrl,
    required bool isLoading,
    Color? paletteColor,
  }) {
    final glowColor = (!isGuest && paletteColor != null)
        ? paletteColor
        : (isGuest
            ? CupertinoColors.systemGrey
            : _DesignColors.primaryPurple);
    final gradientColors = (!isGuest && paletteColor != null)
        ? [
            paletteColor.withValues(alpha: 0.9),
            Color.lerp(paletteColor, _DesignColors.primaryPurple, 0.4)!,
          ]
        : null;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: isGuest
            ? LinearGradient(
                colors: [
                  CupertinoColors.systemGrey.withValues(alpha: 0.3),
                  CupertinoColors.systemGrey.withValues(alpha: 0.2),
                ],
              )
            : (gradientColors != null
                ? LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [
                      _DesignColors.primaryIndigo,
                      _DesignColors.primaryPurple,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: isGuest ? 0.2 : 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isLoading
          ? const Center(
              child: CupertinoActivityIndicator(
                color: CupertinoColors.white,
              ),
            )
          : (avatarUrl != null && avatarUrl.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(
                    child: Text(
                      (username != null && username.isNotEmpty)
                          ? username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Center(
                    child: Text(
                      (username != null && username.isNotEmpty)
                          ? username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: isGuest
                      ? const Icon(
                          CupertinoIcons.person_badge_plus_fill,
                          color: CupertinoColors.white,
                          size: 28,
                        )
                      : Text(
                          (username != null && username.isNotEmpty)
                              ? username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                          ),
                        ),
                ),
    );
  }

  // Appearance Content
  Widget _buildAppearanceContent(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildThemeOption(
                        isDark: isDark,
                        isSelected: settings.themeMode == 0,
                        icon: CupertinoIcons.device_laptop,
                        label: 'Auto',
                        onTap: () => settings.setThemeMode(0),
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        isDark: isDark,
                        isSelected: settings.themeMode == 1,
                        icon: CupertinoIcons.sun_max_fill,
                        label: 'Light',
                        onTap: () => settings.setThemeMode(1),
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        isDark: isDark,
                        isSelected: settings.themeMode == 2,
                        icon: CupertinoIcons.moon_fill,
                        label: 'Dark',
                        onTap: () => settings.setThemeMode(2),
                      ),
                      const SizedBox(width: 12),
                      _buildThemeOption(
                        isDark: isDark,
                        isSelected: settings.themeMode == 3,
                        icon: CupertinoIcons.circle_fill,
                        label: 'OLED',
                        onTap: () => settings.setThemeMode(3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UI Style',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose between performance-focused Material or beautiful Liquid Glass effects',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.systemGrey2
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildUIStyleOption(
                        isDark: isDark,
                        isSelected: settings.uiStyle == UIStyle.liquidGlass,
                        icon: CupertinoIcons.sparkles,
                        label: 'Liquid Glass',
                        description: 'Beautiful blur effects',
                        onTap: () => settings.setUIStyle(UIStyle.liquidGlass),
                      ),
                      const SizedBox(width: 12),
                      _buildUIStyleOption(
                        isDark: isDark,
                        isSelected: settings.uiStyle == UIStyle.material,
                        icon: CupertinoIcons.bolt_fill,
                        label: 'Material',
                        description: 'Performance-focused',
                        onTap: () => settings.setUIStyle(UIStyle.material),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUIStyleOption({
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [_DesignColors.accentTeal, Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? _DesignColors.accentTeal
                  : (isDark
                        ? _DesignColors.accentTeal.withValues(alpha: 0.1)
                        : const Color(0xFFE5E5E7)),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _DesignColors.accentTeal.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? CupertinoColors.white
                    : (isDark
                          ? CupertinoColors.white.withValues(alpha: 0.7)
                          : CupertinoColors.black.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? CupertinoColors.white
                      : (isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? CupertinoColors.white.withValues(alpha: 0.8)
                      : (isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      _DesignColors.primaryIndigo,
                      _DesignColors.primaryPurple,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? _DesignColors.primaryPurple
                  : (isDark
                        ? _DesignColors.primaryPurple.withValues(alpha: 0.1)
                        : const Color(0xFFE5E5E7)),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _DesignColors.primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? CupertinoColors.white
                    : (isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? CupertinoColors.white
                      : (isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Content Settings
  Widget _buildContentSettings(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isAutoMode = settings.gridAutoMode;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Grid Settings Card
            _buildSectionHeader('Post Grid', isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.sparkles,
                    iconColor: _DesignColors.primaryPurple,
                    title: 'Auto Mode',
                    subtitle: 'Automatically adjust grid based on screen size',
                    trailing: CupertinoSwitch(
                      value: settings.gridAutoMode,
                      activeTrackColor: _DesignColors.primaryPurple,
                      onChanged: (value) => settings.setGridAutoMode(value),
                    ),
                  ),
                  _buildDivider(isDark),
                  Opacity(
                    opacity: isAutoMode ? 0.5 : 1.0,
                    child: _buildSettingRow(
                      isDark: isDark,
                      icon: CupertinoIcons.square_grid_2x2_fill,
                      iconColor: _DesignColors.accentPink,
                      title: 'Grid Size',
                      subtitle: isAutoMode
                          ? 'Controlled by Auto Mode'
                          : 'Number of columns in grid view',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: !isAutoMode && settings.gridSize > 2
                                ? () => settings.setGridSize(
                                    settings.gridSize - 1,
                                  )
                                : null,
                            minimumSize: Size(32, 32),
                            child: Icon(
                              CupertinoIcons.minus_circle_fill,
                              size: 24,
                              color: !isAutoMode && settings.gridSize > 2
                                  ? _DesignColors.accentPink
                                  : CupertinoColors.systemGrey,
                            ),
                          ),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '${settings.gridSize}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: !isAutoMode && settings.gridSize < 8
                                ? () => settings.setGridSize(
                                    settings.gridSize + 1,
                                  )
                                : null,
                            minimumSize: Size(32, 32),
                            child: Icon(
                              CupertinoIcons.plus_circle_fill,
                              size: 24,
                              color: !isAutoMode && settings.gridSize < 8
                                  ? _DesignColors.accentPink
                                  : CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.arrow_left_right,
                    iconColor: _DesignColors.primaryIndigo,
                    title: 'Spacing',
                    subtitle: '${settings.gridSpacing.toInt()} pt',
                    trailing: SizedBox(
                      width: 200,
                      child: CupertinoSlider(
                        value: settings.gridSpacing,
                        min: 0,
                        max: 16,
                        divisions: 8,
                        activeColor: _DesignColors.primaryIndigo,
                        onChanged: (value) => settings.setGridSpacing(value),
                      ),
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.square_fill_on_square_fill,
                    iconColor: _DesignColors.accentGreen,
                    title: 'Padding',
                    subtitle: '${settings.gridPadding.toInt()} pt',
                    trailing: SizedBox(
                      width: 200,
                      child: CupertinoSlider(
                        value: settings.gridPadding,
                        min: 0,
                        max: 24,
                        divisions: 12,
                        activeColor: _DesignColors.accentGreen,
                        onChanged: (value) => settings.setGridPadding(value),
                      ),
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.star_fill,
                    iconColor: _DesignColors.accentOrange,
                    title: 'Score Threshold',
                    subtitle:
                        'Minimum score for latest posts (>${settings.scoreThreshold})',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed:
                              settings.scoreThreshold >
                                  AppConstants.minScoreThreshold
                              ? () => settings.setScoreThreshold(
                                  settings.scoreThreshold - 5,
                                )
                              : null,
                          minimumSize: Size(32, 32),
                          child: Icon(
                            CupertinoIcons.minus_circle_fill,
                            size: 24,
                            color:
                                settings.scoreThreshold >
                                    AppConstants.minScoreThreshold
                                ? _DesignColors.accentOrange
                                : CupertinoColors.systemGrey,
                          ),
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '${settings.scoreThreshold}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed:
                              settings.scoreThreshold <
                                  AppConstants.maxScoreThreshold
                              ? () => settings.setScoreThreshold(
                                  settings.scoreThreshold + 5,
                                )
                              : null,
                          minimumSize: Size(32, 32),
                          child: Icon(
                            CupertinoIcons.plus_circle_fill,
                            size: 24,
                            color:
                                settings.scoreThreshold <
                                    AppConstants.maxScoreThreshold
                                ? _DesignColors.accentOrange
                                : CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Content Safety Card
            _buildSectionHeader('Content', isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(
              isDark: isDark,
              child: _buildSettingRow(
                isDark: isDark,
                icon: CupertinoIcons.shield_fill,
                iconColor: _DesignColors.accentGreen,
                title: 'Safe Mode',
                subtitle: 'Only show safe-rated content',
                trailing: CupertinoSwitch(
                  value: settings.safeMode,
                  activeTrackColor: _DesignColors.accentGreen,
                  onChanged: (value) => settings.setSafeMode(value),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Blacklist Card
            _buildSectionHeader('Blacklist', isDark),
            const SizedBox(height: 12),
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.eye_slash_fill,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Enable Blacklist',
                    subtitle: 'Hide posts matching blacklisted tags',
                    trailing: CupertinoSwitch(
                      value: settings.blacklistEnabled,
                      activeTrackColor: const Color(0xFFEF4444),
                      onChanged: (value) => settings.setBlacklistEnabled(value),
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.pencil_ellipsis_rectangle,
                    iconColor: _DesignColors.accentOrange,
                    title: 'Manage Blacklist',
                    subtitle:
                        '${settings.blacklistLines.length} ${settings.blacklistLines.length == 1 ? 'rule' : 'rules'} configured',
                    trailing: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: _DesignColors.accentOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () =>
                          widget.onNavigate(AppRoutes.blacklistSettings),
                      child: const Text(
                        'Manage',
                        style: TextStyle(
                          color: _DesignColors.accentOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDark
              ? CupertinoColors.systemGrey
              : CupertinoColors.systemGrey2,
        ),
      ),
    );
  }

  // Behavior Content
  Widget _buildBehaviorContent(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: _buildSettingRow(
                isDark: isDark,
                icon: CupertinoIcons.sparkles,
                iconColor: _DesignColors.accentOrange,
                title: 'Confetti on Favorite',
                subtitle: 'Show celebration animation when favoriting',
                trailing: CupertinoSwitch(
                  value: settings.confettiOnFavorite,
                  activeTrackColor: _DesignColors.accentOrange,
                  onChanged: (value) => settings.setConfettiOnFavorite(value),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Video Content
  Widget _buildVideoContent(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.play_circle_fill,
                    iconColor: _DesignColors.primaryIndigo,
                    title: 'Auto Play',
                    subtitle: 'Automatically play videos when viewing',
                    trailing: CupertinoSwitch(
                      value: settings.videoAutoPlay,
                      activeTrackColor: _DesignColors.primaryIndigo,
                      onChanged: (value) => settings.setVideoAutoPlay(value),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.1)
                        : CupertinoColors.black.withValues(alpha: 0.05),
                  ),
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.speaker_slash_fill,
                    iconColor: _DesignColors.accentOrange,
                    title: 'Mute by Default',
                    subtitle: 'Start videos muted',
                    trailing: CupertinoSwitch(
                      value: settings.videoMuteByDefault,
                      activeTrackColor: _DesignColors.accentOrange,
                      onChanged: (value) =>
                          settings.setVideoMuteByDefault(value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Customization Content
  Widget _buildCustomizationContent(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: _buildSettingRow(
                isDark: isDark,
                icon: CupertinoIcons.sidebar_left,
                iconColor: _DesignColors.accentTeal,
                title: 'Sidebar Order',
                subtitle: 'Customize the order of sidebar items',
                trailing: CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: _DesignColors.accentTeal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () =>
                      _showDesktopNavOrderDialog(context, settings, isDark),
                  child: const Text(
                    'Configure',
                    style: TextStyle(
                      color: _DesignColors.accentTeal,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDesktopNavOrderDialog(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    final navItems = <int, Map<String, dynamic>>{
      0: {'icon': CupertinoIcons.house_fill, 'label': 'Home'},
      1: {'icon': CupertinoIcons.flame_fill, 'label': 'Hot'},
      2: {'icon': CupertinoIcons.star_fill, 'label': 'Popular'},
      4: {'icon': CupertinoIcons.search, 'label': 'Search'},
      5: {'icon': CupertinoIcons.person_fill, 'label': 'Profile'},
      6: {'icon': CupertinoIcons.heart_fill, 'label': 'Favorites'},
    };

    List<int> currentOrder = List.from(settings.desktopNavOrder);

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return CupertinoAlertDialog(
            title: const Text('Sidebar Order'),
            content: SizedBox(
              width: 300,
              height: 350,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Drag to reorder sidebar items',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Material(
                      color: CupertinoColors.transparent,
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        itemCount: currentOrder.length,
                        onReorder: (oldIndex, newIndex) {
                          setDialogState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = currentOrder.removeAt(oldIndex);
                            currentOrder.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final itemId = currentOrder[index];
                          final item = navItems[itemId]!;
                          return Container(
                            key: ValueKey(itemId),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                item['icon'] as IconData,
                                color: _DesignColors.primaryPurple,
                                size: 20,
                              ),
                              title: Text(
                                item['label'] as String,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  setDialogState(() {
                    currentOrder = [0, 1, 2, 4, 5, 6];
                  });
                },
                child: const Text('Reset'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  settings.setDesktopNavOrder(currentOrder);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Data Content
  Widget _buildDataContent(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.clock_fill,
                    iconColor: CupertinoColors.systemBlue,
                    title: 'Search History',
                    subtitle: settings.searchHistoryEnabled
                        ? 'Save recent searches'
                        : 'History disabled',
                    trailing: CupertinoSwitch(
                      value: settings.searchHistoryEnabled,
                      activeTrackColor: CupertinoColors.systemBlue,
                      onChanged: (value) =>
                          settings.setSearchHistoryEnabled(value),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.1)
                        : CupertinoColors.black.withValues(alpha: 0.05),
                  ),
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.trash_circle_fill,
                    iconColor: CupertinoColors.destructiveRed,
                    title: 'Clear Search History',
                    subtitle: '${settings.searchHistory.length} items stored',
                    trailing: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: settings.searchHistory.isEmpty
                          ? CupertinoColors.systemGrey.withValues(alpha: 0.2)
                          : CupertinoColors.destructiveRed.withValues(
                              alpha: 0.2,
                            ),
                      borderRadius: BorderRadius.circular(8),
                      onPressed: settings.searchHistory.isEmpty
                          ? null
                          : () => _confirmClearSearchHistory(
                              context,
                              settings,
                              isDark,
                            ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: settings.searchHistory.isEmpty
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.destructiveRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearSearchHistory(
    BuildContext context,
    SettingsProvider settings,
    bool isDark,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Search History'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Are you sure you want to clear your search history? This cannot be undone.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              settings.clearSearchHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // Network Content
  Widget _buildNetworkContent(bool isDark) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final proxyConfig = settings.proxyConfig;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.link,
                    iconColor: _DesignColors.accentGreen,
                    title: 'API Host',
                    subtitle: settings.host,
                    trailing: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: _DesignColors.accentGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () =>
                          widget.onNavigate(AppRoutes.hostSettings),
                      child: const Text(
                        'Configure',
                        style: TextStyle(
                          color: _DesignColors.accentGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingRow(
                    isDark: isDark,
                    icon: CupertinoIcons.arrow_right_arrow_left,
                    iconColor: _DesignColors.primaryIndigo,
                    title: 'HTTP Proxy',
                    subtitle: proxyConfig.enabled
                        ? '${proxyConfig.host}:${proxyConfig.port}'
                        : 'Disabled',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoSwitch(
                          value: proxyConfig.enabled,
                          activeTrackColor: _DesignColors.primaryIndigo,
                          onChanged: (value) => settings.setProxyEnabled(value),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: _DesignColors.primaryIndigo.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          onPressed: () =>
                              _showProxySettingsDialog(context, isDark),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              color: _DesignColors.primaryIndigo,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProxySettingsDialog(BuildContext context, bool isDark) {
    final settings = context.read<SettingsProvider>();
    final proxyConfig = settings.proxyConfig;

    final hostController = TextEditingController(text: proxyConfig.host);
    final portController = TextEditingController(
      text: proxyConfig.port > 0 ? proxyConfig.port.toString() : '8080',
    );
    final usernameController = TextEditingController(
      text: proxyConfig.username ?? '',
    );
    final passwordController = TextEditingController(
      text: proxyConfig.password ?? '',
    );
    bool useAuth = proxyConfig.useAuthentication;

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
          title: const Text('Proxy Settings'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: hostController,
                  placeholder: 'Proxy Host (e.g., 127.0.0.1)',
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: portController,
                  placeholder: 'Port (e.g., 8080)',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Use Authentication',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                    ),
                    CupertinoSwitch(
                      value: useAuth,
                      onChanged: (value) => setState(() => useAuth = value),
                    ),
                  ],
                ),
                if (useAuth) ...[
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: usernameController,
                    placeholder: 'Username',
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: passwordController,
                    placeholder: 'Password',
                    obscureText: true,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final host = hostController.text.trim();
                final port = int.tryParse(portController.text.trim()) ?? 8080;
                final username = usernameController.text.trim();
                final password = passwordController.text;

                settings.setProxyConfig(
                  ProxyConfig(
                    enabled: proxyConfig.enabled,
                    host: host,
                    port: port,
                    useAuthentication: useAuth,
                    username: useAuth ? username : null,
                    password: useAuth ? password : null,
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // About Content
  Widget _buildAboutContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingsCard(
          isDark: isDark,
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _DesignColors.primaryIndigo,
                      _DesignColors.primaryPurple,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _DesignColors.primaryPurple.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version $_appVersion',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'A beautiful e926-compatible client built with Flutter.\nDesigned for an exceptional browsing experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.systemGrey2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAboutBadge(
                    isDark: isDark,
                    icon: CupertinoIcons.heart_fill,
                    label: 'Made with Flutter',
                    color: _DesignColors.accentPink,
                  ),
                  const SizedBox(width: 12),
                  _buildAboutBadge(
                    isDark: isDark,
                    icon: CupertinoIcons.sparkles,
                    label: 'Open Source',
                    color: _DesignColors.accentOrange,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCheckForUpdatesButton(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckForUpdatesButton(bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _checkForUpdates(isDark),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                _DesignColors.primaryIndigo,
                _DesignColors.primaryPurple,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _DesignColors.primaryPurple.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.arrow_clockwise_circle_fill,
                size: 18,
                color: CupertinoColors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Check for Updates',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkForUpdates(bool isDark) async {
    // Show loading dialog
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1C1C1E).withValues(alpha: 0.9),
                          const Color(0xFF2C2C2E).withValues(alpha: 0.8),
                        ]
                      : [
                          CupertinoColors.white.withValues(alpha: 0.95),
                          const Color(0xFFF8F8FA).withValues(alpha: 0.9),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? _DesignColors.primaryPurple.withValues(alpha: 0.2)
                      : const Color(0xFFE5E5E7),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(radius: 14),
                  const SizedBox(height: 16),
                  Text(
                    'Checking for updates...',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      decoration: TextDecoration.none,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final updateService = UpdateService();
      final result = await updateService.checkForUpdate(_appVersion);

      if (!mounted) return;

      // Dismiss loading dialog
      Navigator.of(context).pop();

      // Show result dialog
      _showUpdateResultDialog(isDark, result);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      _showUpdateResultDialog(
        isDark,
        UpdateCheckResult(
          updateAvailable: false,
          currentVersion: _appVersion,
          error: 'Failed to check for updates: $e',
        ),
      );
    }
  }

  void _showUpdateResultDialog(bool isDark, UpdateCheckResult result) {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1C1C1E).withValues(alpha: 0.95),
                          const Color(0xFF2C2C2E).withValues(alpha: 0.9),
                        ]
                      : [
                          CupertinoColors.white.withValues(alpha: 0.98),
                          const Color(0xFFF8F8FA).withValues(alpha: 0.95),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? _DesignColors.primaryPurple.withValues(alpha: 0.25)
                      : const Color(0xFFE5E5E7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: result.error != null
                            ? [
                                CupertinoColors.systemRed,
                                CupertinoColors.systemRed.withValues(
                                  alpha: 0.8,
                                ),
                              ]
                            : result.updateAvailable
                            ? [
                                _DesignColors.primaryIndigo,
                                _DesignColors.primaryPurple,
                              ]
                            : [
                                _DesignColors.accentGreen,
                                _DesignColors.accentGreen.withValues(
                                  alpha: 0.8,
                                ),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      result.error != null
                          ? CupertinoIcons.exclamationmark_triangle_fill
                          : result.updateAvailable
                          ? CupertinoIcons.arrow_down_circle_fill
                          : CupertinoIcons.checkmark_circle_fill,
                      color: CupertinoColors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    result.error != null
                        ? 'Error'
                        : result.updateAvailable
                        ? 'Update Available'
                        : 'Up to Date',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Content
                  if (result.error != null)
                    Text(
                      result.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else if (result.updateAvailable)
                    Column(
                      children: [
                        Text(
                          'A new version is available!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.8)
                                : CupertinoColors.black.withValues(alpha: 0.7),
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.05)
                                : CupertinoColors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildVersionBadge(
                                isDark: isDark,
                                label: 'Current',
                                version: result.currentVersion,
                                color: CupertinoColors.systemGrey,
                              ),
                              Icon(
                                CupertinoIcons.arrow_right,
                                color: isDark
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.systemGrey2,
                                size: 20,
                              ),
                              _buildVersionBadge(
                                isDark: isDark,
                                label: 'Latest',
                                version: result.latestVersion ?? '',
                                color: _DesignColors.primaryIndigo,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'You are running the latest version (${result.currentVersion}).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.8)
                            : CupertinoColors.black.withValues(alpha: 0.7),
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Actions
                  if (result.updateAvailable)
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.1)
                                : CupertinoColors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'Later',
                              style: TextStyle(
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  _DesignColors.primaryIndigo,
                                  _DesignColors.primaryPurple,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              borderRadius: BorderRadius.circular(12),
                              onPressed: () async {
                                Navigator.pop(dialogContext);
                                final uri = Uri.parse(
                                  'https://openlyst.ink/apps/klit',
                                );
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              child: const Text(
                                'Download',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: _DesignColors.primaryIndigo,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionBadge({
    required bool isDark,
    required String label,
    required String version,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            version,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutBadge({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
