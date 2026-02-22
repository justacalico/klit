import 'dart:io';
import 'dart:math' show sin, pi;
import 'dart:ui';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImage, CachedNetworkImageProvider;
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'
    show Colors, Theme, ThemeData, Brightness;
import 'package:flutter/widgets.dart' show precacheImage;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/constants/constants.dart';
import '../../core/extensions/extensions.dart';
import '../../core/input/input.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';
import '../../providers/providers.dart';
import '../layout/layout_scope.dart';
import '../shell/toolbar.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

/// One-shot sticky milk overlay: shoots at the screen and stays ~5s then fades.
class _MilkAnimationOverlay extends StatefulWidget {
  const _MilkAnimationOverlay({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_MilkAnimationOverlay> createState() => _MilkAnimationOverlayState();
}

class _MilkAnimationOverlayState extends State<_MilkAnimationOverlay>
    with SingleTickerProviderStateMixin {
  static const Duration _totalDuration = Duration(seconds: 5);
  static const Duration _shootDuration = Duration(milliseconds: 400);
  static const Duration _fadeDuration = Duration(milliseconds: 400);

  late AnimationController _controller;
  late Animation<double> _shoot;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    )..forward().then((_) {
        widget.onComplete();
      });

    final shootEnd = _shootDuration.inMilliseconds / _totalDuration.inMilliseconds;
    final fadeStart = 1.0 - _fadeDuration.inMilliseconds / _totalDuration.inMilliseconds;

    _shoot = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, shootEnd, curve: Curves.easeOutBack),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Interval(fadeStart, 1.0, curve: Curves.easeIn)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final shoot = _shoot.value;
              final fade = _fadeOut.value;
              final opacity = (shoot < 1.0 ? 1.0 : fade).clamp(0.0, 1.0);
              return CustomPaint(
                size: Size(w, h),
                painter: _StickyMilkPainter(
                  shootProgress: shoot,
                  opacity: opacity,
                  time: _controller.value,
                  shootEnd: _shootDuration.inMilliseconds / _totalDuration.inMilliseconds,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Stringy strand definition: end offset (frac of minDim), control offset, start/end radius (frac), taper curve.
/// originDx/originDy = offset from main origin so strands aren't all tied to one point.
class _StrandDef {
  const _StrandDef(
    this.dx,
    this.dy,
    this.cx,
    this.cy,
    this.rStart,
    this.rEnd,
    this.taper, {
    this.originDx = 0.0,
    this.originDy = 0.0,
  });
  final double dx;
  final double dy;
  final double cx;
  final double cy;
  final double rStart;
  final double rEnd;
  final double taper; // 0 = linear, >0 = thicker in middle (pinched ends), <0 = fatter at start (teardrop)
  final double originDx;
  final double originDy;
}

/// Paints viscous stringy milk: curved strands, teardrops, pinched and branching shapes with wobble.
class _StickyMilkPainter extends CustomPainter {
  _StickyMilkPainter({
    required this.shootProgress,
    required this.opacity,
    required this.time,
    required this.shootEnd,
  });

  final double shootProgress;
  final double opacity;
  final double time;
  final double shootEnd;

  static const Color _milkColor = Color(0xFFF5F0E8);
  static const Color _milkHighlight = Color(0xFFFFFBF5);
  static const Color _milkShadow = Color(0x1A000000);

  /// Spread-out fan; each strand has its own origin offset so they're not tied to one point.
  static const List<_StrandDef> _strands = [
    _StrandDef(0.0, -0.42, 0.0, -0.12, 0.038, 0.03, -0.25, originDx: 0.02, originDy: 0.0),
    _StrandDef(0.0, -0.32, 0.0, -0.06, 0.03, 0.022, 0.0, originDx: -0.015, originDy: 0.01),
    _StrandDef(-0.42, -0.22, -0.18, 0.02, 0.028, 0.01, 0.45, originDx: -0.04, originDy: -0.01),
    _StrandDef(0.4, -0.2, 0.16, 0.0, 0.026, 0.01, 0.4, originDx: 0.035, originDy: 0.0),
    _StrandDef(-0.38, -0.38, -0.14, -0.12, 0.032, 0.018, 0.3, originDx: -0.03, originDy: 0.02),
    _StrandDef(0.36, -0.36, 0.12, -0.1, 0.03, 0.016, 0.35, originDx: 0.025, originDy: -0.015),
    _StrandDef(-0.28, -0.5, -0.1, -0.2, 0.026, 0.014, -0.2, originDx: -0.02, originDy: 0.03),
    _StrandDef(0.3, -0.48, 0.08, -0.18, 0.025, 0.012, -0.15, originDx: 0.03, originDy: 0.02),
    _StrandDef(-0.5, -0.08, -0.22, 0.06, 0.022, 0.012, 0.35, originDx: -0.05, originDy: -0.02),
    _StrandDef(0.48, -0.1, 0.2, 0.04, 0.02, 0.01, 0.4, originDx: 0.045, originDy: -0.01),
    _StrandDef(-0.22, -0.55, -0.06, -0.22, 0.024, 0.018, 0.2, originDx: -0.01, originDy: 0.025),
    _StrandDef(0.24, -0.52, 0.06, -0.2, 0.023, 0.016, 0.25, originDx: 0.02, originDy: 0.02),
    _StrandDef(-0.12, -0.44, -0.03, -0.14, 0.028, 0.02, -0.1, originDx: -0.025, originDy: 0.0),
    _StrandDef(0.14, -0.46, 0.04, -0.16, 0.027, 0.019, -0.15, originDx: 0.018, originDy: -0.02),
    _StrandDef(-0.34, -0.3, -0.12, -0.06, 0.025, 0.014, 0.4, originDx: -0.035, originDy: 0.01),
    _StrandDef(0.32, -0.28, 0.1, -0.05, 0.024, 0.013, 0.38, originDx: 0.028, originDy: -0.01),
  ];

  /// Scattered sticky droplets (dx, dy, radius frac) — not tied to strands, spread across the area.
  static const List<({double dx, double dy, double r})> _droplets = [
    (dx: -0.18, dy: -0.25, r: 0.018),
    (dx: 0.22, dy: -0.2, r: 0.016),
    (dx: -0.08, dy: -0.38, r: 0.02),
    (dx: 0.1, dy: -0.35, r: 0.019),
    (dx: -0.32, dy: -0.12, r: 0.014),
    (dx: 0.28, dy: -0.15, r: 0.015),
    (dx: -0.42, dy: -0.32, r: 0.012),
    (dx: 0.38, dy: -0.3, r: 0.013),
    (dx: 0.0, dy: -0.28, r: 0.017),
    (dx: -0.25, dy: -0.42, r: 0.014),
    (dx: 0.2, dy: -0.44, r: 0.015),
  ];

  static const int _segments = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final minDim = size.shortestSide;
    final origin = Offset(size.width * 0.5, size.height * 0.72);
    final fadeStart = 0.92;
    final inHold = time >= shootEnd && time < fadeStart;
    final wobblePhase = inHold ? (time - shootEnd) / (fadeStart - shootEnd) * 2 * pi * 2 : 0.0;

    for (final s in _strands) {
      final strandOrigin = origin + Offset(s.originDx * minDim, s.originDy * minDim);
      _drawStrand(canvas, size, minDim, strandOrigin, s, wobblePhase);
    }

    _drawStickyCenter(canvas, origin, minDim);
    _drawScatteredDroplets(canvas, origin, minDim);
  }

  void _drawStrand(Canvas canvas, Size size, double minDim, Offset origin, _StrandDef s, double wobblePhase) {
    final target = Offset((s.dx - s.originDx) * minDim, (s.dy - s.originDy) * minDim);
    final control = Offset((s.cx - s.originDx) * minDim, (s.cy - s.originDy) * minDim);
    final visibleLength = shootProgress;
    final baseRadius = minDim;

    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    for (var i = 0; i <= _segments; i++) {
      final t = i / _segments;
      if (t > visibleLength) break;
      final tNorm = visibleLength > 0 ? t / visibleLength : 1.0;
      final pt = _quad(Offset.zero, control, target, tNorm);
      final wobble = 0.015 * baseRadius * sin(wobblePhase + t * 4);
      final ptWobble = Offset(pt.dx + wobble, pt.dy + wobble * 0.5);
      final r = _radiusAt(tNorm, s.rStart, s.rEnd, s.taper) * baseRadius * (0.4 + 0.6 * shootProgress);

      final circlePath = Path()..addOval(Rect.fromCircle(center: ptWobble, radius: r));
      final paint = Paint()
        ..color = _milkShadow.withValues(alpha: opacity * 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawPath(circlePath, paint);
      paint.color = _milkColor.withValues(alpha: opacity * 0.92);
      canvas.drawPath(circlePath, paint);
    }

    for (var i = 0; i <= _segments; i++) {
      final t = i / _segments;
      if (t > visibleLength) break;
      final tNorm = visibleLength > 0 ? t / visibleLength : 1.0;
      final pt = _quad(Offset.zero, control, target, tNorm);
      final wobble = 0.015 * baseRadius * sin(wobblePhase + t * 4);
      final ptWobble = Offset(pt.dx + wobble, pt.dy + wobble * 0.5);
      final r = _radiusAt(tNorm, s.rStart, s.rEnd, s.taper) * baseRadius * (0.4 + 0.6 * shootProgress);
      final highlightR = r * 0.35;
      final highlightOffset = Offset(-r * 0.25, -r * 0.2);
      final highlightPath = Path()
        ..addOval(Rect.fromCircle(center: ptWobble + highlightOffset, radius: highlightR));
      final highlightPaint = Paint()
        ..color = _milkHighlight.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawPath(highlightPath, highlightPaint);
    }

    canvas.restore();
  }

  double _radiusAt(double t, double rStart, double rEnd, double taper) {
    final linear = rStart + (rEnd - rStart) * t;
    final pinch = taper > 0 ? 1.0 - 4 * (t - 0.5) * (t - 0.5) * taper : 1.0;
    final teardrop = taper < 0 ? 1.0 - t * (-taper) : 1.0;
    return linear * pinch * teardrop;
  }

  Offset _quad(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1.0 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  /// Sticky mass at source: several overlapping blobs so it's not one single nozzle.
  void _drawStickyCenter(Canvas canvas, Offset origin, double minDim) {
    final scale = 0.4 + 0.6 * shootProgress;
    final blobs = [
      Offset(0.0, 0.0),
      Offset(-0.022 * minDim, 0.018 * minDim),
      Offset(0.018 * minDim, -0.012 * minDim),
      Offset(-0.01 * minDim, -0.02 * minDim),
      Offset(0.025 * minDim, 0.01 * minDim),
    ];
    for (final b in blobs) {
      final center = origin + b;
      final r = minDim * 0.048 * scale;
      final shadowPaint = Paint()
        ..color = _milkShadow.withValues(alpha: opacity * 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r + 1.5, shadowPaint);
      final paint = Paint()
        ..color = _milkColor.withValues(alpha: opacity * 0.93)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r, paint);
    }
    final mainR = minDim * 0.042 * scale;
    final highlightPaint = Paint()
      ..color = _milkHighlight.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(origin + Offset(-mainR * 0.25, -mainR * 0.2), mainR * 0.4, highlightPaint);
  }

  /// Scattered droplets that aren't part of strands — sticky drips spread across the area.
  void _drawScatteredDroplets(Canvas canvas, Offset origin, double minDim) {
    final scale = (0.3 + 0.7 * shootProgress).clamp(0.0, 1.0);
    for (final d in _droplets) {
      final center = origin + Offset(d.dx * minDim, d.dy * minDim);
      final r = d.r * minDim * scale;
      final shadowPaint = Paint()
        ..color = _milkShadow.withValues(alpha: opacity * 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r + 1, shadowPaint);
      final paint = Paint()
        ..color = _milkColor.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r, paint);
      final highlightPaint = Paint()
        ..color = _milkHighlight.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center + Offset(-r * 0.3, -r * 0.25), r * 0.35, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StickyMilkPainter oldDelegate) =>
      oldDelegate.shootProgress != shootProgress ||
      oldDelegate.opacity != opacity ||
      oldDelegate.time != time;
}

/// Converts e621-style DText (and BBCode) in descriptions/comments to Markdown.
/// Supports: [b]/[i]/[s]/[u], [spoiler], {{tag}} → tag search link, [[wiki]] → link.
String _descriptionToMarkdown(String raw) {
  var s = raw
      .replaceAll(RegExp(r'\[b\]', caseSensitive: false), '**')
      .replaceAll(RegExp(r'\[/b\]', caseSensitive: false), '**')
      .replaceAll(RegExp(r'\[i\]', caseSensitive: false), '*')
      .replaceAll(RegExp(r'\[/i\]', caseSensitive: false), '*')
      .replaceAll(RegExp(r'\[s\]', caseSensitive: false), '~~')
      .replaceAll(RegExp(r'\[/s\]', caseSensitive: false), '~~')
      .replaceAll(RegExp(r'\[u\]', caseSensitive: false), '<u>')
      .replaceAll(RegExp(r'\[/u\]', caseSensitive: false), '</u>')
      .replaceAll(RegExp(r'\[spoiler\]', caseSensitive: false), '||')
      .replaceAll(RegExp(r'\[/spoiler\]', caseSensitive: false), '||');
  // e621 tag links: {{tag name}} or {{tag -excluded}} → markdown link (tag: scheme for onTapLink)
  s = s.replaceAllMapped(RegExp(r'\{\{(.+?)\}\}', dotAll: true), (m) {
    final content = m.group(1)!.trim();
    if (content.isEmpty) return m.group(0)!;
    final encoded = Uri.encodeComponent(content);
    return '[$content](tag:$encoded)';
  });
  // Wiki-style links: [[page name]] → markdown link (wiki: scheme; open in browser or no-op)
  s = s.replaceAllMapped(RegExp(r'\[\[([^\]]+)\]\]'), (m) {
    final page = m.group(1)!.trim().replaceAll(' ', '_');
    final encoded = Uri.encodeComponent(page);
    return '[$page](wiki:$encoded)';
  });
  return s;
}

/// Builds the 48×48 uploader avatar: network image when [avatarUrl] is set, else initial letter.
Widget _uploaderAvatarWidget({
  required String? avatarUrl,
  required String initial,
  required bool isDark,
  required double size,
}) {
  final fallback = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: (isDark ? UIColors.primaryPurple : UIColors.primaryIndigo)
          .withValues(alpha: 0.3),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
        ),
      ),
    ),
  );
  if (avatarUrl == null || avatarUrl.isEmpty) return fallback;
  return SizedBox(
    width: size,
    height: size,
    child: ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    ),
  );
}

/// Post detail page - single state preserved across layout mode changes
class PostDetailPage extends StatefulWidget {
  final List<int> postIds;
  final int initialIndex;
  final void Function(String tag)? onSearchTag;
  final void Function(int currentIndex)? onCurrentIndexChanged;
  final Future<List<int>> Function()? onLoadMore;
  final bool hasMore;
  final VoidCallback? onClose;

  const PostDetailPage({
    super.key,
    required this.postIds,
    required this.initialIndex,
    this.onSearchTag,
    this.onCurrentIndexChanged,
    this.onLoadMore,
    this.hasMore = false,
    this.onClose,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

/// Single state for both desktop and mobile layouts - no reload when resizing
class _PostDetailPageState extends State<PostDetailPage>
    with GamepadInputMixin {
  late PageController _pageController;
  late int _currentIndex;
  late List<int> _postIds;
  late bool _hasMore;
  bool _isLoadingMore = false;
  final Map<int, Post?> _loadedPosts = {};
  final Map<int, bool> _loadingStates = {};
  final Map<int, String?> _errorStates = {};
  final Map<int, bool> _isFavorited = {};
  final Map<int, int?> _userVote = {};
  final Map<int, PostScore?> _updatedScores = {};
  final Map<int, bool> _isVoting = {};
  final Map<int, bool> _isTogglingFavorite = {};
  final Map<int, bool> _isDownloading = {};
  final Map<int, double> _downloadProgress = {};
  bool _isFullScreen = false;
  bool _showControllerHints = false;
  late ConfettiController _confettiController;
  late FocusNode _focusNode;
  final Map<String, String?> _uploaderAvatarUrls = {};
  final Set<String> _uploaderAvatarLoading = {};
  final Map<int, String> _uploaderNamesById = {};
  final Set<int> _uploaderNameLoading = {};

  int get _currentPostId => _postIds[_currentIndex];
  Post? get _currentPost => _loadedPosts[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _postIds = List.from(widget.postIds);
    _hasMore = widget.hasMore;
    _pageController = PageController(initialPage: _currentIndex);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _focusNode = FocusNode();
    _loadPost(_currentIndex);
    _preloadAdjacentPosts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _showControllerHints = gamepad.isConnected;
    gamepad.stateChanges.listen((state) {
      if (mounted && state.isConnected != _showControllerHints) {
        setState(() => _showControllerHints = state.isConnected);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Number of posts to preload on each side of the current post.
  static const int _preloadWindow = 3;

  void _preloadAdjacentPosts() {
    final start = (_currentIndex - _preloadWindow).clamp(0, _postIds.length - 1);
    final end = (_currentIndex + _preloadWindow).clamp(0, _postIds.length - 1);
    for (var i = start; i <= end; i++) {
      _loadPost(i);
    }
    if (_hasMore &&
        !_isLoadingMore &&
        widget.onLoadMore != null &&
        _currentIndex >= _postIds.length - _preloadWindow - 1) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || widget.onLoadMore == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final newPostIds = await widget.onLoadMore!();
      if (mounted) {
        setState(() {
          for (final id in newPostIds) {
            if (!_postIds.contains(id)) _postIds.add(id);
          }
          _hasMore = newPostIds.isNotEmpty;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadPost(int index, {bool forceRefresh = false}) async {
    if (index < 0 || index >= _postIds.length) return;
    if (_loadingStates[index] == true) return;
    if (!forceRefresh && _loadedPosts.containsKey(index)) return;
    setState(() {
      _loadingStates[index] = true;
      _errorStates[index] = null;
    });
    final postId = _postIds[index];
    final apiService = context.read<ApiService>();
    final result = await apiService.getPostById(postId);
    result.when(
      success: (post) {
        if (mounted) {
          setState(() {
            _loadedPosts[index] = post;
            _loadingStates[index] = false;
            _isFavorited[index] = post.isFavorited;
            _updatedScores[index] = post.score;
          });
          _precachePostImages(post);
        }
      },
      failure: (error) {
        if (mounted) {
          setState(() {
            _errorStates[index] = error.message;
            _loadingStates[index] = false;
          });
        }
      },
    );
  }

  /// Preload preview and main image into cache so swiping to this post shows images immediately.
  void _precachePostImages(Post post) {
    if (!mounted) return;
    final previewUrl = post.preview.url;
    final mainUrl = post.displayUrl ?? post.sample.url ?? post.preview.url;
    if (previewUrl != null && previewUrl.isNotEmpty) {
      precacheImage(CachedNetworkImageProvider(previewUrl), context);
    }
    if (mainUrl != null &&
        mainUrl.isNotEmpty &&
        mainUrl != previewUrl) {
      precacheImage(CachedNetworkImageProvider(mainUrl), context);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    widget.onCurrentIndexChanged?.call(index);
    _loadPost(index);
    _preloadAdjacentPosts();
  }

  void _navigatePost(int direction) {
    final newIndex = _currentIndex + direction;
    if (newIndex >= 0 && newIndex < _postIds.length) {
      setState(() => _currentIndex = newIndex);
      widget.onCurrentIndexChanged?.call(newIndex);
      _loadPost(newIndex);
      _preloadAdjacentPosts();
      _pageController.jumpToPage(newIndex);
    }
  }

  Future<void> _refreshCurrentPost() =>
      _loadPost(_currentIndex, forceRefresh: true);

  Future<void> _loadUploaderAvatar(String username) async {
    if (_uploaderAvatarLoading.contains(username)) return;
    _uploaderAvatarLoading.add(username);
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
        _uploaderAvatarUrls[username] = url;
        _uploaderAvatarLoading.remove(username);
      });
    }
  }

  /// Resolve uploader username by ID when post has no owner/uploader name, then load avatar.
  Future<void> _loadUploaderNameAndAvatar(int uploaderId) async {
    if (uploaderId <= 0 || _uploaderNameLoading.contains(uploaderId)) return;
    _uploaderNameLoading.add(uploaderId);
    final api = context.read<ApiService>();
    String? username;
    final userResult = await api.getUserById(uploaderId);
    userResult.when(
      success: (user) {
        username = user.name.isNotEmpty ? user.name : null;
      },
      failure: (_) {},
    );
    if (mounted) {
      setState(() {
        _uploaderNameLoading.remove(uploaderId);
        if (username != null) _uploaderNamesById[uploaderId] = username!;
      });
      if (username != null && username!.isNotEmpty) {
        _loadUploaderAvatar(username!);
      }
    }
  }

  Future<void> _vote(int index, int score) async {
    final post = _loadedPosts[index];
    if (post == null || _isVoting[index] == true) return;
    setState(() => _isVoting[index] = true);
    final apiService = context.read<ApiService>();
    final result = await apiService.votePost(post.id, score);
    if (mounted) {
      result.when(
        success: (newScore) {
          setState(() {
            _updatedScores[index] = newScore;
            _userVote[index] = score;
            _isVoting[index] = false;
          });
        },
        failure: (error) {
          setState(() => _isVoting[index] = false);
          _showError(error.message);
        },
      );
    }
  }

  Future<void> _toggleFavorite(int index) async {
    final post = _loadedPosts[index];
    if (post == null || _isTogglingFavorite[index] == true) return;
    final isFav = _isFavorited[index] ?? post.isFavorited;
    setState(() => _isTogglingFavorite[index] = true);
    final apiService = context.read<ApiService>();
    final result = isFav
        ? await apiService.removeFavorite(post.id)
        : await apiService.addFavorite(post.id);
    if (mounted) {
      result.when(
        success: (_) {
          setState(() {
            _isFavorited[index] = !isFav;
            _isTogglingFavorite[index] = false;
          });
          if (!isFav) {
            final settings = context.read<SettingsProvider>();
            if (settings.confettiOnFavorite) _confettiController.play();
            if (settings.upvoteWhenFavorited && _userVote[index] != 1) {
              _vote(index, 1);
            }
          }
        },
        failure: (error) {
          setState(() => _isTogglingFavorite[index] = false);
          _showError(error.message);
        },
      );
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _searchTag(String tag) {
    if (widget.onSearchTag != null) {
      widget.onSearchTag!(tag);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.search, arguments: tag);
    }
  }

  VoidCallback get _onClose =>
      widget.onClose ?? () => Navigator.of(context).pop();

  void _setFullScreen(bool value) {
    setState(() => _isFullScreen = value);
  }

  void _showComments(int index) {
    final post = _loadedPosts[index];
    if (post == null) return;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _CommentsSheet(
            postId: post.id,
            onSearchTag: _searchTag,
          ),
    );
  }

  /// I finished: remove if already finished; else optional camera then add (with optional milk animation).
  Future<void> _onIFinishedTap(int index) async {
    final post = _loadedPosts[index];
    if (post == null || !mounted) return;
    final settings = context.read<SettingsProvider>();
    final isFinished =
        settings.iFinishedEntries.any((e) => e.postId == post.id);
    if (isFinished) {
      await settings.removeIFinishedPostId(post.id);
      return;
    }
    // Camera only on Android/iOS; on desktop skip camera and add without photo.
    if (settings.iFinishedAskPhotoEnabled &&
        (Platform.isAndroid || Platform.isIOS)) {
      final status = await Permission.camera.request();
      if (!mounted) return;
      if (status.isDenied || status.isPermanentlyDenied) {
        final addAnyway = await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Camera access'),
            content: const Text(
              'Camera access is needed to attach a photo. Add without photo?',
            ),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Add without photo'),
              ),
            ],
          ),
        );
        if (addAnyway == true && mounted) {
          if (settings.iFinishedAnimationEnabled) _showMilkAnimation();
          await settings.addIFinishedPostId(post.id);
        }
        return;
      }
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.camera);
      if (!mounted) return;
      String? imagePath;
      if (xFile != null) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final photosDir =
              Directory('${dir.path}${Platform.pathSeparator}i_finished_photos');
          await photosDir.create(recursive: true);
          final destPath =
              '${photosDir.path}${Platform.pathSeparator}${post.id}.jpg';
          await File(xFile.path).copy(destPath);
          imagePath = destPath;
        } catch (_) {}
      }
      if (settings.iFinishedAnimationEnabled) _showMilkAnimation();
      await settings.addIFinishedPostId(post.id, imagePath: imagePath);
      return;
    }
    if (settings.iFinishedAnimationEnabled) _showMilkAnimation();
    await settings.addIFinishedPostId(post.id);
  }

  void _showMilkAnimation() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _MilkAnimationOverlay(
        onComplete: () {
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  void _openFullMedia() {
    if (_currentPost == null) return;
    if (_currentPost!.isVideo) {
      if (_currentPost!.file.url == null) return;
      Navigator.of(context).push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => FullScreenVideoViewer(
            videoUrl: _currentPost!.file.url!,
            thumbnailUrl: _currentPost!.preview.url,
          ),
        ),
      );
    } else {
      if (_currentPost?.file.url == null) return;
      Navigator.of(context).push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => _FullScreenImageViewer(
            imageUrl: _currentPost!.file.url!,
            heroTag: 'post_${_currentPost!.id}',
          ),
        ),
      );
    }
  }

  void _showMoreOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _openFullMedia();
            },
            child: Text(
              _currentPost?.isVideo == true
                  ? 'View Full Video'
                  : 'View Full Resolution',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Share'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadPost();
            },
            child: const Text('Download'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _downloadPost() async {
    final post = _currentPost;
    if (post == null || _isDownloading[_currentIndex] == true) return;
    final fileUrl = post.file.url;
    if (fileUrl == null) {
      _showError('No file URL available for download');
      return;
    }
    setState(() {
      _isDownloading[_currentIndex] = true;
      _downloadProgress[_currentIndex] = 0;
    });
    try {
      final extension = post.file.ext.isNotEmpty ? post.file.ext : 'png';
      final filename = 'e926_${post.id}.$extension';

      if (Platform.isAndroid || Platform.isIOS) {
        await _downloadToGallery(fileUrl, filename, post.isVideo);
      } else {
        await _downloadToDesktop(fileUrl, filename);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading[_currentIndex] = false);
        _showError('Download failed: ${e.toString()}');
      }
    }
  }

  /// Android/iOS: download to temp file then save to gallery.
  Future<void> _downloadToGallery(String fileUrl, String filename, bool isVideo) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';
      final file = File(filePath);
      final dio = Dio();
      await dio.download(
        fileUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress[_currentIndex] = received / total);
          }
        },
      );
      if (isVideo) {
        await Gal.putVideo(filePath);
      } else {
        await Gal.putImage(filePath);
      }
      try {
        await file.delete();
      } catch (_) { /* best-effort cleanup */ }
      if (mounted) {
        setState(() => _isDownloading[_currentIndex] = false);
        _showSavedToGallery();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Desktop: save to Downloads/openlyst/klit.
  Future<void> _downloadToDesktop(String fileUrl, String filename) async {
    try {
      final downloadsDir = await _getDesktopDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('Could not find Downloads directory');
      }
      await downloadsDir.create(recursive: true);
      final filePath = '${downloadsDir.path}${Platform.pathSeparator}$filename';
      final file = File(filePath);
      if (await file.exists()) {
        if (mounted) {
          setState(() => _isDownloading[_currentIndex] = false);
          _showDownloadComplete(filePath, alreadyExists: true);
        }
        return;
      }
      final dio = Dio();
      await dio.download(
        fileUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress[_currentIndex] = received / total);
          }
        },
      );
      if (mounted) {
        setState(() => _isDownloading[_currentIndex] = false);
        _showDownloadComplete(filePath);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Returns Downloads/openlyst/klit on desktop; null on mobile.
  Future<Directory?> _getDesktopDownloadsDirectory() async {
    if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) return Directory('$home/Downloads/openlyst/klit');
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return Directory('$userProfile\\Downloads\\openlyst\\klit');
      }
    }
    return null;
  }

  void _showSavedToGallery() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Saved to Gallery'),
        content: const Text('Image or video was saved to your photo library.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showDownloadComplete(String filePath, {bool alreadyExists = false}) {
    final fileName = filePath.split(Platform.pathSeparator).last;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(alreadyExists ? 'File Exists' : 'Download Complete'),
        content: Text(
          alreadyExists
              ? 'File already exists:\n$fileName'
              : 'Saved to Downloads/openlyst/klit:\n$fileName',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Open Folder'),
            onPressed: () {
              Navigator.of(context).pop();
              _openDownloadsFolder(filePath);
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _openDownloadsFolder(String filePath) async {
    try {
      final directory = File(filePath).parent.path;
      if (Platform.isLinux) {
        await Process.run('xdg-open', [directory]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [directory]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [directory]);
      }
    } catch (_) {
      // Best-effort open folder; ignore failures.
    }
  }

  @override
  void onGamepadButton(GamepadButton button) {
    if (!mounted) return;
    switch (button) {
      case GamepadButton.leftBumper:
        _navigatePost(-1);
        HapticFeedback.mediumImpact();
        break;
      case GamepadButton.rightBumper:
        _navigatePost(1);
        HapticFeedback.mediumImpact();
        break;
      case GamepadButton.y:
        _toggleFavorite(_currentIndex);
        HapticFeedback.heavyImpact();
        break;
      case GamepadButton.rightTrigger:
        _vote(_currentIndex, _userVote[_currentIndex] == 1 ? 0 : 1);
        HapticFeedback.mediumImpact();
        break;
      case GamepadButton.x:
        _vote(_currentIndex, _userVote[_currentIndex] == -1 ? 0 : -1);
        HapticFeedback.mediumImpact();
        break;
      case GamepadButton.b:
        if (_isFullScreen) {
          setState(() => _isFullScreen = false);
        } else {
          _onClose();
        }
        HapticFeedback.lightImpact();
        break;
      case GamepadButton.a:
        if (_currentPost != null && !_currentPost!.isVideo) {
          setState(() => _isFullScreen = !_isFullScreen);
          HapticFeedback.lightImpact();
        }
        break;
      default:
        break;
    }
  }

  @override
  void onGamepadDirection(GamepadDirection direction) {
    if (!mounted) return;
    if (direction == GamepadDirection.left) _navigatePost(-1);
    if (direction == GamepadDirection.right) _navigatePost(1);
  }

  @override
  Widget build(BuildContext context) {
    final mode = LayoutScope.of(context);
    return KeyedSubtree(
      key: const ValueKey('post-detail'),
      child: mode.isDesktop
          ? _DesktopPostDetailBody(state: this, onClose: _onClose)
          : _MobilePostDetailBody(state: this),
    );
  }
}

/// Mobile layout body - uses shared state, no reload on resize
class _MobilePostDetailBody extends StatelessWidget {
  const _MobilePostDetailBody({required this.state});
  final _PostDetailPageState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark =
        settingsProvider.themeMode == 2 ||
        settingsProvider.themeMode == 3 ||
        (settingsProvider.themeMode == 0 &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final isOled = settingsProvider.themeMode == 3;
    final hasMultiplePosts = s._postIds.length > 1;
    final leftHandedMode = settingsProvider.leftHandedMode;

    return KeyboardListener(
      focusNode: s._focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey.keyLabel.toLowerCase();
          if (key == 'd' || event.logicalKey == LogicalKeyboardKey.arrowRight) {
            s._navigatePost(1);
            return;
          }
          if (key == 'a' || event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            s._navigatePost(-1);
            return;
          }
          if (key == 'f') {
            s._toggleFavorite(s._currentIndex);
            return;
          }
          if (key == 'w' || event.logicalKey == LogicalKeyboardKey.arrowUp) {
            final currentVote = s._userVote[s._currentIndex];
            s._vote(s._currentIndex, currentVote == 1 ? 0 : 1);
            return;
          }
          if (key == 's' || event.logicalKey == LogicalKeyboardKey.arrowDown) {
            final currentVote = s._userVote[s._currentIndex];
            s._vote(s._currentIndex, currentVote == -1 ? 0 : -1);
            return;
          }
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: isOled
            ? CupertinoColors.black
            : isDark
            ? AppColors.darkBackground
            : AppColors.lightSecondaryBackground,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: isOled
              ? CupertinoColors.black.withValues(alpha: 0.8)
              : isDark
              ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.8)
              : CupertinoColors.systemBackground.withValues(alpha: 0.8),
          middle: Text(
            hasMultiplePosts
                ? 'Post #${s._currentPostId} (${s._currentIndex + 1}/${s._postIds.length})'
                : 'Post #${s._currentPostId}',
          ),
          trailing: s._currentPost != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: s._loadingStates[s._currentIndex] == true
                          ? null
                          : s._refreshCurrentPost,
                      child: Icon(
                        CupertinoIcons.refresh,
                        color: s._loadingStates[s._currentIndex] == true
                            ? CupertinoColors.systemGrey
                            : null,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => s._showMoreOptions(),
                      child: const Icon(CupertinoIcons.ellipsis),
                    ),
                  ],
                )
              : null,
        ),
        child: Stack(
          children: [
            SafeArea(
              child: hasMultiplePosts
                  ? PageView.builder(
                      controller: s._pageController,
                      itemCount: s._postIds.length,
                      onPageChanged: s._onPageChanged,
                      itemBuilder: (context, index) =>
                          _buildPageContent(context, index, isDark, isOled),
                    )
                  : _buildPageContent(context, 0, isDark, isOled),
            ),
            Align(
              alignment: Alignment(leftHandedMode ? -0.3 : 0.3, 0.45),
              child: ConfettiWidget(
                confettiController: s._confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 20,
                minBlastForce: 8,
                emissionFrequency: 0.05,
                numberOfParticles: 25,
                gravity: 0.3,
                colors: const [
                  Color(0xFFFF6B9D),
                  Color(0xFFFF8E53),
                  Color(0xFFFFD93D),
                  Color(0xFF6BCB77),
                  Color(0xFF4D96FF),
                  Color(0xFFC9B1FF),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(
    BuildContext context,
    int index,
    bool isDark,
    bool isOled,
  ) {
    final post = state._loadedPosts[index];
    final isLoading = state._loadingStates[index] == true;
    final error = state._errorStates[index];

    if (isLoading) return const FullPageLoading(message: 'Loading post...');
    if (error != null) {
      return ErrorState(message: error, onRetry: () => state._loadPost(index));
    }
    if (post == null) {
      return const EmptyState(
        icon: CupertinoIcons.photo,
        title: 'Post not found',
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(context, post),
          const SizedBox(height: 16),
          _buildActionBar(context, index, post, isDark, isOled),
          const SizedBox(height: 16),
          _buildStats(context, post, index, isDark, isOled),
          const SizedBox(height: 16),
          _buildUploader(context, post, isDark, isOled),
          if (post.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDescription(context, post, isDark, isOled),
          ],
          const SizedBox(height: 16),
          _buildTags(context, post, isDark, isOled),
          const SizedBox(height: 16),
          _buildMetadata(context, post, isDark, isOled),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, Post post) =>
      _MobilePostDetailContentBuilder.buildImage(context, state, post);
  Widget _buildActionBar(
    BuildContext context,
    int index,
    Post post,
    bool isDark,
    bool isOled,
  ) => _MobilePostDetailContentBuilder.buildActionBar(
    context,
    state,
    index,
    post,
    isDark,
    isOled,
  );
  Widget _buildStats(
    BuildContext context,
    Post post,
    int index,
    bool isDark,
    bool isOled,
  ) => _MobilePostDetailContentBuilder.buildStats(
    context,
    state,
    post,
    index,
    isDark,
    isOled,
  );
  Widget _buildUploader(
    BuildContext context,
    Post post,
    bool isDark,
    bool isOled,
  ) => _MobilePostDetailContentBuilder.buildUploaderCard(
    context,
    state,
    post,
    isDark,
    isOled,
  );
  Widget _buildDescription(
    BuildContext context,
    Post post,
    bool isDark,
    bool isOled,
  ) => _MobilePostDetailContentBuilder.buildDescription(
    context,
    state,
    post,
    isDark,
    isOled,
  );
  Widget _buildTags(
    BuildContext context,
    Post post,
    bool isDark,
    bool isOled,
  ) => _MobilePostDetailContentBuilder.buildTags(
    context,
    state,
    post,
    isDark,
    isOled,
  );
  Widget _buildMetadata(
    BuildContext context,
    Post post,
    bool isDark,
    bool isOled,
  ) => _MobilePostDetailContentBuilder.buildMetadata(
    context,
    state,
    post,
    isDark,
    isOled,
  );
}

/// Helper to hold mobile-specific build logic (extracted from _MobilePostDetailViewState)
class _MobilePostDetailContentBuilder {
  static Widget buildImage(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
  ) {
    if (post.isVideo && post.file.url != null) {
      final settings = context.read<SettingsProvider>();
      final aspectRatio = (post.file.height > 0)
          ? (post.file.width / post.file.height).clamp(0.3, 3.0)
          : 1.0;
      return RepaintBoundary(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: VideoPlayerWidget(
            key: ValueKey('video_${post.id}_${post.file.url}'),
            videoUrl: post.file.url!,
            thumbnailUrl: post.preview.url,
            autoPlay: settings.videoAutoPlay,
            looping: true,
            showControls: true,
            aspectRatio: aspectRatio,
            muteByDefault: settings.videoMuteByDefault,
          ),
        ),
      );
    }
    final imageUrl = post.file.url ?? post.sample.url ?? post.preview.url;
    if (imageUrl == null) return const Icon(CupertinoIcons.photo, size: 64);
    final aspectRatio = post.file.aspectRatio.clamp(0.3, 3.0);
    return GestureDetector(
      onTap: () => s._openFullMedia(),
      child: Hero(
        tag: 'post_${post.id}',
        child: AspectRatio(
          aspectRatio: aspectRatio,
          key: ValueKey('post_image_${post.id}'),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, _) => post.preview.url != null
                ? CachedNetworkImage(
                    imageUrl: post.preview.url!,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => const CupertinoActivityIndicator(),
                    errorWidget: (_, _, _) =>
                        const CupertinoActivityIndicator(),
                  )
                : const CupertinoActivityIndicator(),
            errorWidget: (_, _, _) =>
                const Icon(CupertinoIcons.exclamationmark_triangle, size: 48),
          ),
        ),
      ),
    );
  }

  static Widget buildActionBar(
    BuildContext context,
    _PostDetailPageState s,
    int index,
    Post post,
    bool isDark,
    bool isOled,
  ) {
    final authProvider = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final isGuest = authProvider.isGuest;
    final isFav = s._isFavorited[index] ?? post.isFavorited;
    final userVote = s._userVote[index];
    final isVoting = s._isVoting[index] == true;
    final isTogglingFav = s._isTogglingFavorite[index] == true;
    final leftHandedMode = settings.leftHandedMode;
    final isIFinished =
        settings.iFinishedEnabled &&
        settings.iFinishedEntries.any((e) => e.postId == post.id);

    final commentBtn = _buildGlassActionButton(
      context,
      s,
      index,
      CupertinoIcons.chat_bubble,
      CupertinoIcons.chat_bubble_fill,
      '${post.commentCount}',
      false,
      false,
      CupertinoColors.systemBlue,
      isDark,
      isOled,
      () => s._showComments(index),
    );
    final upvoteBtn = _buildGlassActionButton(
      context,
      s,
      index,
      CupertinoIcons.arrow_up_circle,
      CupertinoIcons.arrow_up_circle_fill,
      'Upvote',
      userVote == 1,
      isVoting,
      AppColors.safeColor,
      isDark,
      isOled,
      () => s._vote(index, userVote == 1 ? 0 : 1),
    );
    final downvoteBtn = _buildGlassActionButton(
      context,
      s,
      index,
      CupertinoIcons.arrow_down_circle,
      CupertinoIcons.arrow_down_circle_fill,
      'Downvote',
      userVote == -1,
      isVoting,
      AppColors.explicitColor,
      isDark,
      isOled,
      () => s._vote(index, userVote == -1 ? 0 : -1),
    );
    final favoriteBtn = _buildGlassActionButton(
      context,
      s,
      index,
      CupertinoIcons.heart,
      CupertinoIcons.heart_fill,
      'Favorite',
      isFav,
      isTogglingFav,
      CupertinoColors.systemPink,
      isDark,
      isOled,
      () => s._toggleFavorite(index),
    );
    // Download is available in the more-options sheet on mobile; no separate icon in the row.
    final iFinishedBtn = settings.iFinishedEnabled
        ? _buildGlassActionButton(
            context,
            s,
            index,
            CupertinoIcons.checkmark_circle,
            CupertinoIcons.checkmark_circle_fill,
            'I finished',
            isIFinished,
            false,
            const Color(0xFF22C55E),
            isDark,
            isOled,
            () => s._onIFinishedTap(index),
          )
        : null;

    var buttons = isGuest
        ? <Widget>[]
        : leftHandedMode
            ? [commentBtn, favoriteBtn, downvoteBtn, upvoteBtn]
            : [upvoteBtn, downvoteBtn, favoriteBtn, commentBtn];
    if (iFinishedBtn != null) buttons = [...buttons, iFinishedBtn];

    if (buttons.isEmpty) return const SizedBox.shrink();

    return _buildLiquidGlassContainer(
      context,
      s,
      isDark: isDark,
      isOled: isOled,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons.map((b) => Expanded(child: b)).toList(),
      ),
    );
  }

  static Widget _buildGlassActionButton(
    BuildContext context,
    _PostDetailPageState s,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    bool isActive,
    bool isLoading,
    Color color,
    bool isDark,
    bool isOled,
    VoidCallback onTap,
  ) {
    final displayColor = isActive
        ? color
        : (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      onPressed: isLoading ? null : onTap,
      minimumSize: Size(0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CupertinoActivityIndicator(color: color),
                )
              : Icon(
                  isActive ? activeIcon : icon,
                  size: 24,
                  color: displayColor,
                ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: displayColor,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildLiquidGlassContainer(
    BuildContext context,
    _PostDetailPageState s, {
    required bool isDark,
    required bool isOled,
    EdgeInsets? margin,
    EdgeInsets? padding,
    required Widget child,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
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
      ),
    );
  }

  static Widget buildStats(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    int index,
    bool isDark,
    bool isOled,
  ) {
    final score = s._updatedScores[index] ?? post.score;
    final isFav = s._isFavorited[index] ?? post.isFavorited;
    final favCount = isFav != post.isFavorited
        ? (isFav ? post.favCount + 1 : post.favCount - 1)
        : post.favCount;
    return _buildLiquidGlassContainer(
      context,
      s,
      isDark: isDark,
      isOled: isOled,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildGlassStatItem(
            context,
            score.total.toString(),
            'Score',
            score.total >= 0 ? AppColors.safeColor : AppColors.explicitColor,
            isDark,
          ),
          _buildGlassStatItem(
            context,
            favCount.compact,
            'Favorites',
            UIColors.primaryViolet,
            isDark,
          ),
          _buildGlassStatItem(
            context,
            post.commentCount.toString(),
            'Comments',
            UIColors.primaryIndigo,
            isDark,
          ),
        ],
      ),
    );
  }

  static Widget _buildGlassStatItem(
    BuildContext context,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
          ),
        ),
      ],
    );
  }

  static Widget buildUploaderCard(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    bool isDark,
    bool isOled,
  ) {
    final effectiveUsername = post.uploaderName?.isNotEmpty == true
        ? post.uploaderName
        : s._uploaderNamesById[post.uploaderId];
    final displayName = effectiveUsername ?? 'User #${post.uploaderId}';
    final initial = displayName.isNotEmpty
        ? displayName.replaceFirst(':', ' ').trim().isNotEmpty
            ? displayName.replaceFirst(':', ' ').trim()[0].toUpperCase()
            : '#'
        : '?';

    if (post.uploaderId > 0 && effectiveUsername == null &&
        !s._uploaderNameLoading.contains(post.uploaderId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        s._loadUploaderNameAndAvatar(post.uploaderId);
      });
    }
    if (effectiveUsername != null &&
        effectiveUsername.isNotEmpty &&
        s._uploaderAvatarUrls[effectiveUsername] == null &&
        !s._uploaderAvatarLoading.contains(effectiveUsername)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        s._loadUploaderAvatar(effectiveUsername);
      });
    }
    final avatarUrl = effectiveUsername != null
        ? s._uploaderAvatarUrls[effectiveUsername]
        : null;

    return _buildLiquidGlassContainer(
      context,
      s,
      isDark: isDark,
      isOled: isOled,
      child: Row(
        children: [
          _uploaderAvatarWidget(
            avatarUrl: avatarUrl,
            initial: initial,
            isDark: isDark,
            size: 48,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Uploader',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (effectiveUsername != null)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.profile,
                  arguments: effectiveUsername,
                );
              },
              child: Text(
                'View profile',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget buildDescription(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    bool isDark,
    bool isOled,
  ) {
    return _buildLiquidGlassContainer(
      context,
      s,
      isDark: isDark,
      isOled: isOled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 8),
          if (post.description.isEmpty)
            Text(
              'No description',
              style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
            )
          else
            SizedBox(
              width: double.infinity,
              child: Theme(
                data: ThemeData(
                  brightness: isDark ? Brightness.dark : Brightness.light,
                ),
                child: MarkdownBody(
                  data: _descriptionToMarkdown(post.description),
                  selectable: true,
                  shrinkWrap: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.85)
                          : CupertinoColors.label,
                    ),
                    a: TextStyle(
                      color: CupertinoColors.systemBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onTapLink: (text, href, title) {
                    if (href != null && href.startsWith('tag:')) {
                      s._searchTag(Uri.decodeComponent(href.substring(4)));
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget buildTags(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    bool isDark,
    bool isOled,
  ) {
    return _buildLiquidGlassContainer(
      context,
      s,
      isDark: isDark,
      isOled: isOled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.tags.allWithCategory.take(20).map((e) {
                final tag = e.$1.replaceFirst(':', ' ');
                final category = e.$2;
                final baseColor = PostTags.getColorForCategory(category);
                final chipColor = baseColor.withValues(alpha: 0.25);
                return GestureDetector(
                  onTap: () => s._searchTag(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildMetadata(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    bool isDark,
    bool isOled,
  ) {
    return _buildLiquidGlassContainer(
      context,
      s,
      isDark: isDark,
      isOled: isOled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetadataRow(context, 'ID', '#${post.id}', isDark),
          _buildMetadataRow(
            context,
            'Size',
            '${post.file.width}×${post.file.height}',
            isDark,
          ),
          _buildMetadataRow(
            context,
            'Type',
            post.file.ext.toUpperCase(),
            isDark,
          ),
          _buildMetadataRow(context, 'Rating', post.rating, isDark),
        ],
      ),
    );
  }

  static Widget _buildMetadataRow(
    BuildContext context,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop layout body - uses shared state, no reload on resize
class _DesktopPostDetailBody extends StatelessWidget {
  const _DesktopPostDetailBody({required this.state, required this.onClose});
  final _PostDetailPageState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    if (s._isFullScreen && s._currentPost != null) {
      return _DesktopPostDetailContentBuilder.buildFullScreenView(
        context,
        s,
        isDark,
      );
    }

    return KeyboardListener(
      focusNode: s._focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey.keyLabel.toLowerCase();
          if (key == 'd') {
            s._navigatePost(1);
            return;
          }
          if (key == 'a') {
            s._navigatePost(-1);
            return;
          }
          if (key == 'f') {
            s._toggleFavorite(s._currentIndex);
            return;
          }
          if (key == 'w') {
            final cv = s._userVote[s._currentIndex];
            s._vote(s._currentIndex, cv == 1 ? 0 : 1);
            return;
          }
          if (key == 's') {
            final cv = s._userVote[s._currentIndex];
            s._vote(s._currentIndex, cv == -1 ? 0 : -1);
            return;
          }
        }
      },
      child: Stack(
        children: [
          Container(
            color: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            child: Column(
              children: [
                _DesktopPostDetailContentBuilder.buildTopBar(
                  context,
                  s,
                  onClose,
                  isDark,
                ),
                Expanded(
                  child: _DesktopPostDetailContentBuilder.buildContent(
                    context,
                    s,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0.85, -0.3),
            child: ConfettiWidget(
              confettiController: s._confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 25,
              gravity: 0.3,
              colors: const [
                Color(0xFFFF6B9D),
                Color(0xFFFF8E53),
                Color(0xFFFFD93D),
                Color(0xFF6BCB77),
                Color(0xFF4D96FF),
                Color(0xFFC9B1FF),
              ],
            ),
          ),
          if (s._showControllerHints)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: _DesktopPostDetailContentBuilder.buildControllerHints(
                context,
                s,
                isDark,
              ),
            ),
        ],
      ),
    );
  }
}

/// Desktop-specific build logic
class _DesktopPostDetailContentBuilder {
  static Widget buildFullScreenView(
    BuildContext context,
    _PostDetailPageState s,
    bool isDark,
  ) {
    final post = s._currentPost!;
    if (post.isVideo && post.file.url != null) {
      return FullScreenVideoViewer(
        videoUrl: post.file.url!,
        thumbnailUrl: post.preview.url,
      );
    }
    final imageUrl = post.file.url ?? post.sample.url ?? post.preview.url;
    if (imageUrl == null) return const SizedBox();
    return GestureDetector(
      onTap: () => s._setFullScreen(false),
      child: Container(
        color: CupertinoColors.black,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Center(
            child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  static Widget buildTopBar(
    BuildContext context,
    _PostDetailPageState s,
    VoidCallback onClose,
    bool isDark,
  ) {
    final hasMultiple = s._postIds.length > 1;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF18181B).withValues(alpha: 0.85),
                      const Color(0xFF1F1F23).withValues(alpha: 0.9),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.85),
                      const Color(0xFFFAFAFC).withValues(alpha: 0.9),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: UIColors.primaryPurple.withValues(
                  alpha: isDark ? 0.15 : 0.1,
                ),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              ToolbarButton(
                icon: CupertinoIcons.back,
                tooltip: 'Back',
                onPressed: onClose,
              ),
              const SizedBox(width: 8),
              Text(
                'Back',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? CupertinoColors.white
                      : const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [UIColors.primaryIndigo, UIColors.primaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.photo,
                  size: 14,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                hasMultiple
                    ? 'Post #${s._currentPostId} (${s._currentIndex + 1}/${s._postIds.length})'
                    : 'Post #${s._currentPostId}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? CupertinoColors.white
                      : const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              if (hasMultiple) ...[
                ToolbarButton(
                  icon: CupertinoIcons.chevron_left,
                  tooltip: 'Previous',
                  onPressed: s._currentIndex > 0
                      ? () => s._navigatePost(-1)
                      : null,
                ),
                const SizedBox(width: 8),
                ToolbarButton(
                  icon: CupertinoIcons.chevron_right,
                  tooltip: 'Next',
                  onPressed: s._currentIndex < s._postIds.length - 1
                      ? () => s._navigatePost(1)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildContent(
    BuildContext context,
    _PostDetailPageState s,
    bool isDark,
  ) {
    final isLoading = s._loadingStates[s._currentIndex] == true;
    final error = s._errorStates[s._currentIndex];
    final post = s._currentPost;

    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 48),
            const SizedBox(height: 16),
            Text(error),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: () => s._loadPost(s._currentIndex),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (post == null) return const Center(child: Text('Post not found'));

    return LayoutBuilder(
      builder: (context, constraints) {
        const narrowBreakpoint = 700.0;
        final useNarrowLayout = constraints.maxWidth < narrowBreakpoint;

        if (useNarrowLayout) {
          // Vertical stack for smaller screens - image on top, info below
          final imageHeight = (constraints.maxHeight * 0.45).clamp(
            200.0,
            500.0,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: imageHeight,
                child: buildMediaPanel(context, s, post, isDark),
              ),
              Expanded(child: buildInfoPanel(context, s, post, isDark)),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: buildMediaPanel(context, s, post, isDark)),
            Container(
              width: 1,
              color: isDark
                  ? AppColors.darkSeparator
                  : AppColors.lightSeparator,
            ),
            SizedBox(
              width: 380,
              child: buildInfoPanel(context, s, post, isDark),
            ),
          ],
        );
      },
    );
  }

  static Widget buildMediaPanel(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    bool isDark,
  ) {
    return Container(
      color: isDark ? const Color(0xFF0A0A0C) : CupertinoColors.systemGrey6,
      child: Stack(
        children: [
          Center(child: buildMedia(context, s, post)),
          if (!post.isVideo)
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => s._setFullScreen(true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        UIColors.primaryPurple.withValues(alpha: 0.9),
                        UIColors.primaryIndigo.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.fullscreen,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget buildMedia(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
  ) {
    if (post.isVideo && post.file.url != null) {
      final settings = context.read<SettingsProvider>();
      return VideoPlayerWidget(
        key: ValueKey('video_${post.id}_${post.file.url}'),
        videoUrl: post.file.url!,
        thumbnailUrl: post.preview.url,
        autoPlay: settings.videoAutoPlay,
        looping: true,
        showControls: true,
        aspectRatio: post.file.aspectRatio,
        muteByDefault: settings.videoMuteByDefault,
      );
    }
    final imageUrl = post.file.url ?? post.sample.url ?? post.preview.url;
    if (imageUrl == null) return const Icon(CupertinoIcons.photo, size: 64);
    return GestureDetector(
      onDoubleTap: () => s._setFullScreen(true),
      child: AspectRatio(
        aspectRatio: post.file.aspectRatio.clamp(0.3, 3.0),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (_, _) => post.preview.url != null
              ? CachedNetworkImage(
                  imageUrl: post.preview.url!,
                  fit: BoxFit.contain,
                )
              : const CupertinoActivityIndicator(),
          errorWidget: (_, _, _) =>
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 48),
        ),
      ),
    );
  }

  static Widget buildInfoPanel(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    bool isDark,
  ) {
    final score = s._updatedScores[s._currentIndex] ?? post.score;
    final isFav = s._isFavorited[s._currentIndex] ?? post.isFavorited;
    final userVote = s._userVote[s._currentIndex];
    final isVoting = s._isVoting[s._currentIndex] == true;
    final isTogglingFav = s._isTogglingFavorite[s._currentIndex] == true;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF2C2C2E).withValues(alpha: 0.7),
                      const Color(0xFF1C1C1E).withValues(alpha: 0.8),
                    ]
                  : [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                      const Color(0xFFF8F8FA).withValues(alpha: 0.8),
                    ],
            ),
          ),
          child: Column(
            children: [
              buildActionBar(
                context,
                s,
                score,
                isFav,
                userVote,
                isVoting,
                isTogglingFav,
                isDark,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildStatsCard(context, s, post, score, isFav, isDark),
                      const SizedBox(height: 16),
                      buildUploaderCard(context, s, post, isDark),
                      const SizedBox(height: 16),
                      if (post.description.isNotEmpty) ...[
                        buildDescriptionCard(context, s, post, isDark),
                        const SizedBox(height: 16),
                      ],
                      buildTagsCard(context, s, post, isDark),
                      const SizedBox(height: 16),
                      buildMetadataCard(context, s, post, isDark),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildActionBar(
    BuildContext context,
    _PostDetailPageState s,
    PostScore score,
    bool isFav,
    int? userVote,
    bool isVoting,
    bool isTogglingFav,
    bool isDark,
  ) {
    final settings = context.watch<SettingsProvider>();
    final post = s._loadedPosts[s._currentIndex];
    final isIFinished = settings.iFinishedEnabled &&
        post != null &&
        settings.iFinishedEntries.any((e) => e.postId == post.id);

    final actionButtons = <Widget>[
      Expanded(
        child: _buildGradientActionButton(
          context,
          s,
          CupertinoIcons.arrow_up,
          CupertinoIcons.arrow_up_circle_fill,
          userVote == 1,
          isVoting,
          [const Color(0xFF22C55E), const Color(0xFF16A34A)],
          isDark,
          onTap: () => s._vote(s._currentIndex, userVote == 1 ? 0 : 1),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _buildGradientActionButton(
          context,
          s,
          CupertinoIcons.arrow_down,
          CupertinoIcons.arrow_down_circle_fill,
          userVote == -1,
          isVoting,
          [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          isDark,
          onTap: () =>
              s._vote(s._currentIndex, userVote == -1 ? 0 : -1),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _buildGradientActionButton(
          context,
          s,
          CupertinoIcons.heart,
          CupertinoIcons.heart_fill,
          isFav,
          isTogglingFav,
          [UIColors.primaryPurple, UIColors.primaryViolet],
          isDark,
          onTap: () => s._toggleFavorite(s._currentIndex),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _buildGradientActionButton(
          context,
          s,
          CupertinoIcons.square_arrow_down,
          CupertinoIcons.square_arrow_down_fill,
          false,
          s._isDownloading[s._currentIndex] == true,
          [UIColors.primaryIndigo, UIColors.primaryPurple],
          isDark,
          onTap: () => s._downloadPost(),
        ),
      ),
    ];
    if (settings.iFinishedEnabled) {
      actionButtons.add(const SizedBox(width: 8));
      actionButtons.add(
        Expanded(
          child: _buildGradientActionButton(
            context,
            s,
            CupertinoIcons.checkmark_circle,
            CupertinoIcons.checkmark_circle_fill,
            isIFinished,
            false,
            [const Color(0xFF22C55E), const Color(0xFF16A34A)],
            isDark,
            onTap: () => s._onIFinishedTap(s._currentIndex),
          ),
        ),
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryPurple.withValues(alpha: 0.08),
                      UIColors.primaryIndigo.withValues(alpha: 0.05),
                    ]
                  : [
                      UIColors.primaryPurple.withValues(alpha: 0.05),
                      UIColors.primaryIndigo.withValues(alpha: 0.03),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: UIColors.primaryPurple.withValues(
                  alpha: isDark ? 0.15 : 0.1,
                ),
              ),
            ),
          ),
          child: Row(
            children: actionButtons,
          ),
        ),
      ),
    );
  }

  static Widget _buildGradientActionButton(
    BuildContext context,
    _PostDetailPageState s,
    IconData icon,
    IconData activeIcon,
    bool isActive,
    bool isLoading,
    List<Color> activeGradient,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: activeGradient,
                )
              : null,
          color: isActive
              ? null
              : (isDark
                    ? const Color(0xFF2C2C2E).withValues(alpha: 0.6)
                    : const Color(0xFFF3F4F6).withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : UIColors.primaryPurple.withValues(alpha: isDark ? 0.2 : 0.1),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeGradient[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CupertinoActivityIndicator(
                    color: isActive
                        ? CupertinoColors.white
                        : UIColors.primaryPurple,
                  ),
                )
              : Icon(
                  isActive ? activeIcon : icon,
                  size: 20,
                  color: isActive
                      ? CupertinoColors.white
                      : (isDark
                            ? CupertinoColors.white.withValues(alpha: 0.7)
                            : const Color(0xFF374151)),
                ),
        ),
      ),
    );
  }

  static Widget buildStatsCard(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    PostScore score,
    bool isFav,
    bool isDark,
  ) {
    final favCount = isFav != post.isFavorited
        ? (isFav ? post.favCount + 1 : post.favCount - 1)
        : post.favCount;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryPurple.withValues(alpha: 0.08),
                      UIColors.primaryIndigo.withValues(alpha: 0.05),
                    ]
                  : [
                      UIColors.primaryPurple.withValues(alpha: 0.06),
                      UIColors.primaryIndigo.withValues(alpha: 0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: UIColors.primaryPurple.withValues(
                alpha: isDark ? 0.2 : 0.12,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    CupertinoIcons.arrow_up_circle_fill,
                    score.total.toString(),
                    'Score',
                    score.total >= 0
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    isDark,
                  ),
                  _buildStatColumn(
                    CupertinoIcons.heart_fill,
                    favCount.compact,
                    'Favorites',
                    UIColors.primaryViolet,
                    isDark,
                  ),
                  _buildStatColumn(
                    CupertinoIcons.chat_bubble_fill,
                    post.commentCount.toString(),
                    'Comments',
                    UIColors.primaryIndigo,
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildUploaderCard(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    bool isDark,
  ) {
    final effectiveUsername = post.uploaderName?.isNotEmpty == true
        ? post.uploaderName
        : s._uploaderNamesById[post.uploaderId];
    final displayName = effectiveUsername ?? 'User #${post.uploaderId}';
    final initial = displayName.isNotEmpty
        ? displayName.replaceFirst(':', ' ').trim().isNotEmpty
            ? displayName.replaceFirst(':', ' ').trim()[0].toUpperCase()
            : '#'
        : '?';
    if (post.uploaderId > 0 && effectiveUsername == null &&
        !s._uploaderNameLoading.contains(post.uploaderId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        s._loadUploaderNameAndAvatar(post.uploaderId);
      });
    }
    if (effectiveUsername != null &&
        effectiveUsername.isNotEmpty &&
        s._uploaderAvatarUrls[effectiveUsername] == null &&
        !s._uploaderAvatarLoading.contains(effectiveUsername)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        s._loadUploaderAvatar(effectiveUsername);
      });
    }
    final avatarUrl = effectiveUsername != null
        ? s._uploaderAvatarUrls[effectiveUsername]
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryPurple.withValues(alpha: 0.08),
                      UIColors.primaryIndigo.withValues(alpha: 0.05),
                    ]
                  : [
                      UIColors.primaryPurple.withValues(alpha: 0.06),
                      UIColors.primaryIndigo.withValues(alpha: 0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: UIColors.primaryPurple.withValues(
                alpha: isDark ? 0.2 : 0.12,
              ),
            ),
          ),
          child: Row(
            children: [
              _uploaderAvatarWidget(
                avatarUrl: avatarUrl,
                initial: initial,
                isDark: isDark,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Uploader',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? CupertinoColors.white
                            : const Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (effectiveUsername != null)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.profile,
                      arguments: effectiveUsername,
                    );
                  },
                  child: Text(
                    'View profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStatColumn(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
        ),
      ],
    );
  }

  static Widget buildDescriptionCard(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    bool isDark,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryPurple.withValues(alpha: 0.08),
                      UIColors.primaryIndigo.withValues(alpha: 0.05),
                    ]
                  : [
                      UIColors.primaryPurple.withValues(alpha: 0.06),
                      UIColors.primaryIndigo.withValues(alpha: 0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: UIColors.primaryPurple.withValues(
                alpha: isDark ? 0.2 : 0.12,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? CupertinoColors.white
                      : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Theme(
                  data: ThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                  ),
                  child: MarkdownBody(
                    data: _descriptionToMarkdown(post.description),
                    selectable: true,
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.85)
                            : CupertinoColors.label,
                      ),
                      a: TextStyle(
                        color: CupertinoColors.systemBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onTapLink: (text, href, title) {
                      if (href != null && href.startsWith('tag:')) {
                        s._searchTag(Uri.decodeComponent(href.substring(4)));
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildTagsCard(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    bool isDark,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryPurple.withValues(alpha: 0.08),
                      UIColors.primaryIndigo.withValues(alpha: 0.05),
                    ]
                  : [
                      UIColors.primaryPurple.withValues(alpha: 0.06),
                      UIColors.primaryIndigo.withValues(alpha: 0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: UIColors.primaryPurple.withValues(
                alpha: isDark ? 0.2 : 0.12,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? CupertinoColors.white
                      : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: post.tags.allWithCategory.take(20).map((e) {
                    final tag = e.$1.replaceFirst(':', ' ');
                    final category = e.$2;
                    final baseColor = PostTags.getColorForCategory(category);
                    final chipColor = baseColor.withValues(alpha: 0.25);
                    return GestureDetector(
                      onTap: () => s._searchTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: chipColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? CupertinoColors.white
                                : const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildMetadataCard(
    BuildContext context,
    _PostDetailPageState s,
    Post post,
    bool isDark,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      UIColors.primaryPurple.withValues(alpha: 0.08),
                      UIColors.primaryIndigo.withValues(alpha: 0.05),
                    ]
                  : [
                      UIColors.primaryPurple.withValues(alpha: 0.06),
                      UIColors.primaryIndigo.withValues(alpha: 0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: UIColors.primaryPurple.withValues(
                alpha: isDark ? 0.2 : 0.12,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetadataRow('ID', '#${post.id}', isDark),
              _buildMetadataRow(
                'Size',
                '${post.file.width}×${post.file.height}',
                isDark,
              ),
              _buildMetadataRow('Type', post.file.ext.toUpperCase(), isDark),
              _buildMetadataRow('Rating', post.rating, isDark),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildMetadataRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildControllerHints(
    BuildContext context,
    _PostDetailPageState s,
    bool isDark,
  ) {
    final currentVote = s._userVote[s._currentIndex];
    final isFavorited = s._isFavorited[s._currentIndex] ?? false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF))
                .withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHintButton('LB', 'Previous', isDark),
              const SizedBox(width: 16),
              _buildHintButton('RB', 'Next', isDark),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: 1,
                height: 20,
                color: isDark
                    ? const Color(0xFF3F3F46)
                    : const Color(0xFFD4D4D8),
              ),
              _buildHintButton(
                'Y',
                isFavorited ? 'Unfavorite' : 'Favorite',
                isDark,
                color: isFavorited ? const Color(0xFFFF6B9D) : null,
              ),
              const SizedBox(width: 16),
              _buildHintButton(
                'RT',
                currentVote == 1 ? 'Remove Vote' : 'Upvote',
                isDark,
                color: currentVote == 1 ? const Color(0xFF22C55E) : null,
              ),
              const SizedBox(width: 16),
              _buildHintButton(
                'X',
                currentVote == -1 ? 'Remove Vote' : 'Downvote',
                isDark,
                color: currentVote == -1 ? const Color(0xFFEF4444) : null,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: 1,
                height: 20,
                color: isDark
                    ? const Color(0xFF3F3F46)
                    : const Color(0xFFD4D4D8),
              ),
              _buildHintButton('B', 'Close', isDark),
              const SizedBox(width: 16),
              _buildHintButton('A', 'Fullscreen', isDark),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildHintButton(
    String button,
    String label,
    bool isDark, {
    Color? color,
  }) {
    final c =
        color ?? (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: c.withValues(alpha: 0.4)),
          ),
          child: Text(
            button,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF3F3F46),
          ),
        ),
      ],
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullScreenImageViewer({required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.5),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white),
        ),
      ),
      child: Hero(
        tag: heroTag,
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          backgroundDecoration: const BoxDecoration(
            color: CupertinoColors.black,
          ),
          loadingBuilder: (context, event) => const Center(
            child: CupertinoActivityIndicator(color: CupertinoColors.white),
          ),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Comments sheet with liquid glass design
class _CommentsSheet extends StatefulWidget {
  final int postId;
  final void Function(String tag)? onSearchTag;

  const _CommentsSheet({
    required this.postId,
    this.onSearchTag,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _error;
  final _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final apiService = context.read<ApiService>();
    final result = await apiService.getComments(widget.postId);

    if (mounted) {
      result.when(
        success: (comments) {
          setState(() {
            _comments = comments;
            _isLoading = false;
          });
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

  Future<void> _postComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    final apiService = context.read<ApiService>();
    final result = await apiService.postComment(widget.postId, body);

    if (mounted) {
      result.when(
        success: (comment) {
          setState(() {
            _comments.insert(0, comment);
            _commentController.clear();
            _isPosting = false;
          });
        },
        failure: (error) {
          setState(() {
            _isPosting = false;
          });
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text(error.message),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark =
        settingsProvider.themeMode == 2 ||
        settingsProvider.themeMode == 3 ||
        (settingsProvider.themeMode == 0 &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final isOled = settingsProvider.themeMode == 3;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isOled
                  ? [Colors.black.withValues(alpha: 0.95), Colors.black]
                  : isDark
                  ? [
                      AppColors.darkBackground.withValues(alpha: 0.95),
                      AppColors.darkBackground,
                    ]
                  : [
                      CupertinoColors.systemBackground.withValues(alpha: 0.95),
                      CupertinoColors.systemBackground,
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: isOled
                    ? Colors.white.withValues(alpha: 0.08)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CupertinoColors.systemBlue.withValues(
                                  alpha: 0.3,
                                ),
                                CupertinoColors.systemBlue.withValues(
                                  alpha: 0.1,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CupertinoIcons.chat_bubble_2_fill,
                            size: 18,
                            color: isDark
                                ? CupertinoColors.systemBlue.withValues(
                                    alpha: 0.8,
                                  )
                                : CupertinoColors.systemBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                      ],
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 18,
                          color: isDark
                              ? CupertinoColors.white.withValues(alpha: 0.6)
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 0.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              // Comments list
              Expanded(child: _buildCommentsList(isDark, isOled)),
              // Comment input
              _buildCommentInput(isDark, isOled, bottomPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInput(bool isDark, bool isOled, double bottomPadding) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12 + bottomPadding,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isOled
                  ? [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.02),
                    ]
                  : isDark
                  ? [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.8),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _commentController,
                  placeholder: 'Write a comment...',
                  maxLines: 3,
                  minLines: 1,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                  placeholderStyle: TextStyle(
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.4)
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isPosting ? null : _postComment,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CupertinoColors.systemBlue,
                        CupertinoColors.systemBlue.withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemBlue.withValues(
                          alpha: 0.4,
                        ),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.paperplane_fill,
                          size: 20,
                          color: CupertinoColors.white,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsList(bool isDark, bool isOled) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CupertinoColors.systemRed.withValues(alpha: 0.2),
                    CupertinoColors.systemRed.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 32,
                color: CupertinoColors.systemRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.6)
                    : CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _loadComments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CupertinoColors.systemBlue.withValues(alpha: 0.2),
                    CupertinoColors.systemBlue.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.chat_bubble,
                size: 40,
                color: isDark
                    ? CupertinoColors.systemBlue.withValues(alpha: 0.6)
                    : CupertinoColors.systemBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to comment!',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? CupertinoColors.white.withValues(alpha: 0.6)
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _CommentCard(
          comment: comment,
          isDark: isDark,
          isOled: isOled,
          onSearchTag: widget.onSearchTag,
        );
      },
    );
  }
}

/// Avatar for a comment creator: network image when URL available, else placeholder icon.
class _CommentAvatar extends StatelessWidget {
  final Comment comment;
  final bool isDark;
  final String apiBaseUrl;

  const _CommentAvatar({
    required this.comment,
    required this.isDark,
    required this.apiBaseUrl,
  });

  String? get _avatarUrl {
    final raw = comment.creatorAvatarUrl;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith(RegExp(r'https?://'))) return raw;
    final base = apiBaseUrl.endsWith('/') ? apiBaseUrl : '$apiBaseUrl/';
    final path = raw.startsWith('/') ? raw.substring(1) : raw;
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final url = _avatarUrl;
    final placeholder = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.systemBlue.withValues(alpha: 0.25),
            CupertinoColors.systemBlue.withValues(alpha: 0.1),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CupertinoIcons.person_fill,
        size: 14,
        color: isDark
            ? CupertinoColors.systemBlue.withValues(alpha: 0.8)
            : CupertinoColors.systemBlue,
      ),
    );
    if (url == null) return placeholder;
    return SizedBox(
      width: 32,
      height: 32,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, _) => placeholder,
          errorWidget: (_, _, _) => placeholder,
        ),
      ),
    );
  }
}

/// Individual comment card with liquid glass design
class _CommentCard extends StatelessWidget {
  final Comment comment;
  final bool isDark;
  final bool isOled;
  final void Function(String tag)? onSearchTag;

  const _CommentCard({
    required this.comment,
    required this.isDark,
    required this.isOled,
    this.onSearchTag,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isOled
                  ? [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.02),
                    ]
                  : isDark
                  ? [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOled
                  ? Colors.white.withValues(alpha: 0.06)
                  : isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _CommentAvatar(
                        comment: comment,
                        isDark: isDark,
                        apiBaseUrl: context.read<ApiService>().baseUrl,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        comment.creatorName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: comment.score >= 0
                            ? [
                                AppColors.safeColor.withValues(alpha: 0.25),
                                AppColors.safeColor.withValues(alpha: 0.1),
                              ]
                            : [
                                AppColors.explicitColor.withValues(alpha: 0.25),
                                AppColors.explicitColor.withValues(alpha: 0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          comment.score >= 0
                              ? CupertinoIcons.arrow_up
                              : CupertinoIcons.arrow_down,
                          size: 12,
                          color: comment.score >= 0
                              ? AppColors.safeColor
                              : AppColors.explicitColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comment.score.abs().toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: comment.score >= 0
                                ? AppColors.safeColor
                                : AppColors.explicitColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Theme(
                  data: ThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                  ),
                  child: MarkdownBody(
                    data: _descriptionToMarkdown(comment.body),
                    selectable: true,
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.85)
                          : CupertinoColors.label,
                    ),
                    a: TextStyle(
                      color: CupertinoColors.systemBlue,
                      decoration: TextDecoration.underline,
                    ),
                    code: TextStyle(
                      fontSize: 12,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.9)
                          : CupertinoColors.black,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    blockquoteDecoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: CupertinoColors.systemBlue.withValues(
                            alpha: 0.5,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                    blockquotePadding: const EdgeInsets.only(left: 10),
                  ),
                    onTapLink: (text, href, title) {
                      if (href != null && href.startsWith('tag:')) {
                        onSearchTag?.call(Uri.decodeComponent(href.substring(4)));
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                comment.createdAt.relativeTime,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.5)
                      : CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
