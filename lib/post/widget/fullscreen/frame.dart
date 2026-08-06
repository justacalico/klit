import 'dart:async';

import 'package:kilt/client/client.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostFullscreenFrame extends StatefulWidget {
  const PostFullscreenFrame({
    super.key,
    required this.child,
    required this.post,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
  });

  final Post post;
  final Widget child;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;

  @override
  State<PostFullscreenFrame> createState() => _PostFullscreenFrameState();
}

class _PostFullscreenFrameState extends State<PostFullscreenFrame> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<_FullscreenActionIndicatorState> _indicatorKey = GlobalKey();
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pageController = PostDetailPageControllerProvider.of(context);
      _pageController?.addListener(_onPageChanged);
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageController?.removeListener(_onPageChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (!mounted || _pageController == null || !_pageController!.hasClients) {
      return;
    }
    final controller = context.read<PostController?>();
    final items = controller?.items;
    if (items == null) return;
    final currentPage = _pageController!.page?.round() ?? 0;
    final myIndex = items.indexWhere((p) => p.id == widget.post.id);
    if (myIndex == currentPage && !_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _showAction(_FullscreenAction action) {
    _indicatorKey.currentState?.push(action);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final physicalKey = event.physicalKey;
    final logicalKey = event.logicalKey;

    if (physicalKey == PhysicalKeyboardKey.arrowLeft ||
        logicalKey == LogicalKeyboardKey.keyA) {
      _goToAdjacentPost(-1);
      return KeyEventResult.handled;
    }
    if (physicalKey == PhysicalKeyboardKey.arrowRight ||
        logicalKey == LogicalKeyboardKey.keyD) {
      _goToAdjacentPost(1);
      return KeyEventResult.handled;
    }

    final client = context.read<Client>();
    if (!client.hasLogin) return KeyEventResult.ignored;
    final controller = context.read<PostController?>();
    if (controller == null) return KeyEventResult.ignored;

    if (physicalKey == PhysicalKeyboardKey.arrowUp ||
        logicalKey == LogicalKeyboardKey.keyW) {
      _vote(controller, upvote: true);
      return KeyEventResult.handled;
    }
    if (physicalKey == PhysicalKeyboardKey.arrowDown ||
        logicalKey == LogicalKeyboardKey.keyS) {
      _vote(controller, upvote: false);
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.keyF) {
      _toggleFavorite(controller);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _goToAdjacentPost(int delta) {
    final controller = context.read<PostController?>();
    final items = controller?.items;
    if (items == null) return;
    final pageController = PostDetailPageControllerProvider.of(context);
    if (pageController == null || !pageController.hasClients) return;
    final page = pageController.page?.round() ?? 0;
    final target = page + delta;
    if (target < 0 || target >= items.length) return;
    pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _vote(PostController controller, {required bool upvote}) {
    final post = controller.postById(widget.post.id) ?? widget.post;
    final isLiked = upvote
        ? post.vote.status == VoteStatus.upvoted
        : post.vote.status == VoteStatus.downvoted;
    HapticFeedback.selectionClick();
    controller.vote(post: post, upvote: upvote, replace: !isLiked);
    _showAction(
      upvote
          ? _FullscreenAction.upvote(active: !isLiked)
          : _FullscreenAction.downvote(active: !isLiked),
    );
  }

  void _toggleFavorite(PostController controller) {
    final post = controller.postById(widget.post.id) ?? widget.post;
    HapticFeedback.selectionClick();
    if (post.isFavorited) {
      controller.unfav(post);
      _showAction(const _FullscreenAction.unfavorite());
    } else {
      final upvoteFavs = context.read<Settings>().upvoteFavs.value;
      controller.fav(post).then((success) {
        if (success && upvoteFavs) {
          final updated = controller.postById(post.id);
          if (updated != null) {
            controller.vote(
              post: updated,
              upvote: true,
              replace: true,
            );
          }
        }
      });
      _showAction(const _FullscreenAction.favorite());
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        appBarTheme: theme.appBarTheme.copyWith(
          systemOverlayStyle: theme.appBarTheme.systemOverlayStyle!.copyWith(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.black26,
          ),
        ),
      ),
      child: ScaffoldFrame(
        controller: ScaffoldFrame.maybeOf(context),
        child: ScaffoldFrameSystemUI(
          child: Builder(
            builder: (context) {
              VideoPlayer? player = widget.post.getVideo(context);
              return AdaptiveScaffold(
                extendBodyBehindAppBar: true,
                extendBody: true,
                appBar: ScaffoldFrameAppBar(
                  child: PostFullscreenAppBar(post: widget.post),
                ),
                drawer: widget.drawer,
                endDrawer: widget.endDrawer,
                body: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    ScaffoldFrameController controller = ScaffoldFrame.of(
                      context,
                    );
                    controller.toggleFrame();
                    if ((player?.state.playing ?? false) &&
                        controller.visible) {
                      controller.hideFrame(
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  child: Stack(
                    fit: StackFit.passthrough,
                    alignment: Alignment.center,
                    children: [
                      Focus(
                        focusNode: _focusNode,
                        canRequestFocus: true,
                        onKeyEvent: _handleKeyEvent,
                        child: widget.child,
                      ),
                      if (player != null) VideoButton(player: player),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: IgnorePointer(
                          child: _FullscreenActionIndicator(
                            key: _indicatorKey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _FullscreenActionKind { favorite, unfavorite, upvote, downvote }

class _FullscreenAction {
  const _FullscreenAction({
    required this.kind,
    required this.active,
  });

  const _FullscreenAction.favorite()
    : kind = _FullscreenActionKind.favorite,
      active = true;

  const _FullscreenAction.unfavorite()
    : kind = _FullscreenActionKind.unfavorite,
      active = true;

  const _FullscreenAction.upvote({required this.active})
    : kind = _FullscreenActionKind.upvote;

  const _FullscreenAction.downvote({required this.active})
    : kind = _FullscreenActionKind.downvote;

  final _FullscreenActionKind kind;
  final bool active;
}

class _FullscreenActionIndicator extends StatefulWidget {
  const _FullscreenActionIndicator({super.key});

  @override
  State<_FullscreenActionIndicator> createState() =>
      _FullscreenActionIndicatorState();
}

class _IndicatorEntry {
  const _IndicatorEntry({required this.id, required this.action});

  final int id;
  final _FullscreenAction action;
}

class _FullscreenActionIndicatorState extends State<_FullscreenActionIndicator> {
  static const int _max = 3;
  static const double _slotHeight = 48.0;
  static const Duration _slideDuration = Duration(milliseconds: 240);

  final List<_IndicatorEntry> _items = [];
  int _nextId = 0;

  void push(_FullscreenAction action) {
    if (!mounted) return;
    setState(() {
      _items.insert(0, _IndicatorEntry(id: _nextId++, action: action));
    });
  }

  void _dismiss(int id) {
    if (!mounted) return;
    setState(() {
      _items.removeWhere((e) => e.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: (_max + 1) * _slotHeight,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (int i = 0; i < _items.length; i++)
              AnimatedPositioned(
                key: ValueKey(_items[i].id),
                left: 0,
                bottom: i * _slotHeight,
                duration: _slideDuration,
                curve: Curves.easeOutCubic,
                child: _IndicatorItem(
                  action: _items[i].action,
                  evicted: i >= _max,
                  onDismissed: () => _dismiss(_items[i].id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorItem extends StatefulWidget {
  const _IndicatorItem({
    required this.action,
    required this.evicted,
    required this.onDismissed,
  });

  final _FullscreenAction action;
  final bool evicted;
  final VoidCallback onDismissed;

  @override
  State<_IndicatorItem> createState() => _IndicatorItemState();
}

class _IndicatorItemState extends State<_IndicatorItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late final Animation<double> _fade;
  Timer? _autoTimer;
  bool _exiting = false;
  bool _upwardExit = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _fade = _curve;
    _controller.forward();
    if (widget.evicted) {
      _startExit(upward: true);
    } else {
      _autoTimer = Timer(const Duration(milliseconds: 1600), _startExit);
    }
  }

  void _startExit({bool upward = false}) {
    if (_exiting) return;
    _exiting = true;
    _upwardExit = upward;
    _autoTimer?.cancel();
    setState(() {});
    _controller.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void didUpdateWidget(covariant _IndicatorItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.evicted && widget.evicted && !_exiting) {
      _startExit(upward: true);
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    _curve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final begin = _exiting
        ? (_upwardExit ? Offset.zero : const Offset(-1.0, 0.0))
        : const Offset(-1.0, 0.0);
    final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(_curve);
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: slide,
        child: _FullscreenActionPill(action: widget.action),
      ),
    );
  }
}

class _FullscreenActionPill extends StatelessWidget {
  const _FullscreenActionPill({required this.action});

  final _FullscreenAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (icon, label, color) = switch (action.kind) {
      _FullscreenActionKind.favorite => (
        Icons.favorite,
        'Favorited',
        Colors.pinkAccent,
      ),
      _FullscreenActionKind.unfavorite => (
        Icons.favorite_border,
        'Unfavorited',
        Colors.white,
      ),
      _FullscreenActionKind.upvote => (
        Icons.arrow_upward,
        action.active ? 'Upvoted' : 'Upvote removed',
        action.active ? Colors.deepOrange : Colors.white,
      ),
      _FullscreenActionKind.downvote => (
        Icons.arrow_downward,
        action.active ? 'Downvoted' : 'Downvote removed',
        action.active ? Colors.blue : Colors.white,
      ),
    };

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.72),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
