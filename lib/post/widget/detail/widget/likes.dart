import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:klit/app/app.dart';
import 'package:klit/client/client.dart';
import 'package:klit/post/post.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:like_button/like_button.dart';
import 'package:path_provider/path_provider.dart';

class LikeDisplay extends StatelessWidget {
  const LikeDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final hasLogin = context.watch<Client>().hasLogin;
    final theme = Theme.of(context);
    final cupertino = CupertinoTheme.of(context);
    final primary = cupertino.primaryColor;
    final iconColor = theme.iconTheme.color ?? theme.colorScheme.onSurface;
    final voteStatus = post.vote.status;
    final settings = context.read<Settings>();

    Future<void> vote({required bool upvote, required bool isLiked}) async {
      PostController controller = context.read<PostController>();
      ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      controller.vote(post: post, upvote: upvote, replace: !isLiked).then((
        value,
      ) {
        if (!value) {
          messenger.showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(
                'Failed to ${upvote ? 'upvote' : 'downvote'} Post #${post.id}',
              ),
            ),
          );
        }
      });
    }

    Future<void> toggleFavorite() async {
      await _toggleFavorite(
        context: context,
        post: post,
        isLiked: post.isFavorited,
      );
    }

    Future<void> share() async =>
        Share.text(context, context.read<Client>().withHost(post.link));

    Future<void> download() async =>
        postDownloadingNotification(context, {post});

    Future<void> browse() async =>
        launch(context.read<Client>().withHost(post.link));

    Widget buildControlButton({
      required String keyId,
      required String semanticLabel,
      required IconData icon,
      required bool active,
      required VoidCallback? onPressed,
    }) {
      final bgColor = active
          ? primary.withValues(alpha: 0.9)
          : primary.withValues(alpha: 0.2);
      final fgColor = active ? theme.colorScheme.onPrimary : iconColor;

      return _AnimatedPostActionButton(
        key: ValueKey<String>('post_action_$keyId'),
        semanticLabel: semanticLabel,
        icon: icon,
        active: active,
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        onPressed: onPressed,
      );
    }

    List<Widget> buildActionButtons(List<PostActionId> actions) {
      final buttons = <Widget>[];
      for (final action in actions) {
        switch (action) {
          case PostActionId.upvote:
            buttons.add(
              buildControlButton(
                keyId: action.key,
                semanticLabel: action.label,
                icon: voteStatus == VoteStatus.upvoted
                    ? Icons.thumb_up
                    : Icons.thumb_up_alt_outlined,
                active: voteStatus == VoteStatus.upvoted,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  vote(upvote: true, isLiked: voteStatus == VoteStatus.upvoted);
                },
              ),
            );
            break;
          case PostActionId.downvote:
            buttons.add(
              buildControlButton(
                keyId: action.key,
                semanticLabel: action.label,
                icon: voteStatus == VoteStatus.downvoted
                    ? Icons.thumb_down
                    : Icons.thumb_down_alt_outlined,
                active: voteStatus == VoteStatus.downvoted,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  vote(
                    upvote: false,
                    isLiked: voteStatus == VoteStatus.downvoted,
                  );
                },
              ),
            );
            break;
          case PostActionId.favorite:
            buttons.add(
              buildControlButton(
                keyId: action.key,
                semanticLabel: action.label,
                icon: post.isFavorited ? Icons.favorite : Icons.favorite_border,
                active: post.isFavorited,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  toggleFavorite();
                },
              ),
            );
            break;
          case PostActionId.share:
            buttons.add(
              buildControlButton(
                keyId: action.key,
                semanticLabel: action.label,
                icon: Icons.share_outlined,
                active: false,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  share();
                },
              ),
            );
            break;
          case PostActionId.download:
            if (post.file != null) {
              buttons.add(
                buildControlButton(
                  keyId: action.key,
                  semanticLabel: action.label,
                  icon: Icons.file_download_outlined,
                  active: false,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    download();
                  },
                ),
              );
            }
            break;
          case PostActionId.browse:
            buttons.add(
              buildControlButton(
                keyId: action.key,
                semanticLabel: action.label,
                icon: Icons.open_in_browser_outlined,
                active: false,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  browse();
                },
              ),
            );
            break;
          case PostActionId.iFinished:
            final enabled = settings.iFinishedEnabled.value;
            buttons.add(
              _IFinishedButton(
                post: post,
                settings: settings,
                theme: theme,
                primary: primary,
                iconColor: iconColor,
                enabled: enabled,
                buildControlButton: buildControlButton,
              ),
            );
            break;
        }
      }
      return buttons;
    }

    Widget buildStat({
      required IconData icon,
      required String label,
      required String value,
      Color? color,
    }) {
      final textTheme = theme.textTheme;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color ?? iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: textTheme.labelSmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (hasLogin)
          ValueListenableBuilder<String>(
            valueListenable: settings.postActionBarActions,
            builder: (context, rawActions, _) {
              final actions = PostActionPreferences.decode(rawActions);
              final buttons = buildActionButtons(actions);
              return GlassCard(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                borderRadius: 18,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (buttons.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    const minButtonWidth = 72.0;
                    const gap = 8.0;
                    final count = buttons.length;
                    final availableWidth =
                        constraints.maxWidth - (gap * (count - 1));
                    final fittedWidth = availableWidth / count;
                    final buttonWidth = fittedWidth < minButtonWidth
                        ? minButtonWidth
                        : fittedWidth;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i < count; i++) ...[
                              SizedBox(width: buttonWidth, child: buttons[i]),
                              if (i != count - 1) const SizedBox(width: gap),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        GlassCard(
          margin: EdgeInsets.only(top: hasLogin ? 10 : 12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          borderRadius: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildStat(
                icon: Icons.thumb_up,
                label: 'Score',
                value: post.vote.score.toString(),
                color: voteStatus == VoteStatus.upvoted ? primary : iconColor,
              ),
              buildStat(
                icon: Icons.favorite,
                label: 'Favorites',
                value: post.favCount.toString(),
                color: post.isFavorited ? Colors.pinkAccent : iconColor,
              ),
              buildStat(
                icon: Icons.comment,
                label: 'Comments',
                value: post.commentCount.toString(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IFinishedButton extends StatefulWidget {
  const _IFinishedButton({
    required this.post,
    required this.settings,
    required this.theme,
    required this.primary,
    required this.iconColor,
    required this.enabled,
    required this.buildControlButton,
  });

  final Post post;
  final Settings settings;
  final ThemeData theme;
  final Color primary;
  final Color iconColor;
  final bool enabled;
  final Widget Function({
    required String keyId,
    required String semanticLabel,
    required IconData icon,
    required bool active,
    required VoidCallback? onPressed,
  }) buildControlButton;

  @override
  State<_IFinishedButton> createState() => _IFinishedButtonState();
}

class _IFinishedButtonState extends State<_IFinishedButton> {
  bool _lock = false;

  Future<void> _onTap() async {
    if (_lock || !widget.enabled) return;
    setState(() => _lock = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _lock = false);
    });
    HapticFeedback.selectionClick();
    final client = context.read<Client>();
    String? photoPath;
    final requestPhoto = widget.settings.iFinishedRequestPhoto.value &&
        (Platform.isIOS || Platform.isAndroid);
    if (requestPhoto) {
      final source = await _showPhotoSourceSheet(context);
      if (source == null) {
        setState(() => _lock = false);
        return;
      }
      if (source != _PhotoSource.skip) {
        final picker = ImagePicker();
        final sourceType =
            source == _PhotoSource.camera
                ? ImageSource.camera
                : ImageSource.gallery;
        final file = await picker.pickImage(source: sourceType);
        if (file != null) {
          final dir = await getTemporaryDirectory();
          final name = 'finish_${widget.post.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final dest = File('${dir.path}/$name');
          await dest.writeAsBytes(await file.readAsBytes());
          photoPath = dest.path;
        }
      }
    }
    await client.finishes.add(widget.post.id, photoPath);
  }

  @override
  Widget build(BuildContext context) {
    const action = PostActionId.iFinished;
    final effectiveEnabled = widget.enabled && !_lock;
    return widget.buildControlButton(
      keyId: action.key,
      semanticLabel: action.label,
      icon: CupertinoIcons.checkmark_circle,
      active: false,
      onPressed: effectiveEnabled ? _onTap : null,
    );
  }
}

enum _PhotoSource { camera, gallery, skip }

Future<_PhotoSource?> _showPhotoSourceSheet(BuildContext context) async {
  return showCupertinoModalPopup<_PhotoSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: CupertinoActionSheet(
        title: const Text('Take a photo?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, _PhotoSource.camera),
            child: const Text('Camera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, _PhotoSource.gallery),
            child: const Text('Gallery'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, _PhotoSource.skip),
            child: const Text('Skip'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    ),
  );
}

class _AnimatedPostActionButton extends StatefulWidget {
  const _AnimatedPostActionButton({
    super.key,
    required this.semanticLabel,
    required this.icon,
    required this.active,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String semanticLabel;
  final IconData icon;
  final bool active;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  @override
  State<_AnimatedPostActionButton> createState() =>
      _AnimatedPostActionButtonState();
}

class _AnimatedPostActionButtonState extends State<_AnimatedPostActionButton> {
  bool _pressed = false;
  double _activeScale = 1;

  @override
  void didUpdateWidget(covariant _AnimatedPostActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      setState(() => _activeScale = 1.06);
      Future<void>.delayed(const Duration(milliseconds: 170), () {
        if (!mounted) return;
        setState(() => _activeScale = 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _activeScale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: Duration(milliseconds: _pressed ? 90 : 140),
          curve: _pressed ? Curves.easeOut : Curves.easeOutBack,
          child: Listener(
            onPointerDown: (_) => setState(() => _pressed = true),
            onPointerUp: (_) => setState(() => _pressed = false),
            onPointerCancel: (_) => setState(() => _pressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: widget.backgroundColor,
              ),
              child: CupertinoButton(
                onPressed: widget.onPressed,
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: const Size(0, 0),
                child: Icon(widget.icon, size: 20, color: widget.foregroundColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {},
      child: LikeButton(
        isLiked: post.isFavorited,
        circleColor: const CircleColor(start: Colors.pink, end: Colors.red),
        bubblesColor: const BubblesColor(
          dotPrimaryColor: Colors.pink,
          dotSecondaryColor: Colors.red,
        ),
        likeBuilder: (isLiked) => Icon(
          Icons.favorite,
          color: isLiked ? Colors.pinkAccent : IconTheme.of(context).color,
        ),
        onTap: (isLiked) async {
          return _toggleFavorite(
            context: context,
            post: post,
            isLiked: isLiked,
          );
        },
      ),
    );
  }
}

Future<bool> _toggleFavorite({
  required BuildContext context,
  required Post post,
  required bool isLiked,
}) async {
  PostController controller = context.read<PostController>();
  ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  if (isLiked) {
    controller.unfav(post).then((value) {
      if (!value) {
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            content: Text('Failed to remove Post #${post.id} from favorites'),
          ),
        );
      }
    });
    return false;
  } else {
    bool upvote = context.read<Settings>().upvoteFavs.value;
    controller.fav(post).then((value) {
      if (value) {
        if (upvote) {
          controller.vote(
            post: controller.postById(post.id)!,
            upvote: true,
            replace: true,
          );
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            content: Text('Failed to add Post #${post.id} to favorites'),
          ),
        );
      }
    });
    return true;
  }
}
