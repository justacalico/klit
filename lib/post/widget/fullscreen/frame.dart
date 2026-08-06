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
  _FullscreenAction? _action;
  Timer? _actionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _actionTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _showAction(_FullscreenAction action) {
    _actionTimer?.cancel();
    setState(() => _action = action);
    _actionTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _action = null);
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final physicalKey = event.physicalKey;
    final logicalKey = event.logicalKey;

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
                        child: _FullscreenActionIndicator(action: _action),
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

class _FullscreenActionIndicator extends StatelessWidget {
  const _FullscreenActionIndicator({required this.action});

  final _FullscreenAction? action;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: action == null
          ? const SizedBox.shrink()
          : _FullscreenActionPill(action: action!),
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
