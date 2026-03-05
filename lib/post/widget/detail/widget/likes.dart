import 'package:klit/client/client.dart';
import 'package:klit/post/post.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:like_button/like_button.dart';

class LikeDisplay extends StatelessWidget {
  const LikeDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final hasLogin = context.watch<Client>().hasLogin;
    final theme = Theme.of(context);
    final cupertino = CupertinoTheme.of(context);
    final primary = cupertino.primaryColor;
    final iconColor = theme.iconTheme.color;
    final voteStatus = post.vote.status;
    final settings = context.read<Settings>();
    final showShare = settings.showShareButton.value;

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

    Future<void> share() async {
      await Share.text(context, context.read<Client>().withHost(post.link));
    }

    Widget buildControlButton({
      required IconData icon,
      required bool active,
      required VoidCallback? onPressed,
    }) {
      final bgColor = active
          ? primary.withValues(alpha: 0.9)
          : primary.withValues(alpha: 0.2);
      final fgColor = active ? theme.colorScheme.onPrimary : iconColor;

      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: bgColor,
          ),
          child: CupertinoButton(
            onPressed: onPressed,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Icon(icon, size: 20, color: fgColor),
            minimumSize: Size(0, 0),
          ),
        ),
      );
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
          GlassCard(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            borderRadius: 18,
            child: Row(
              children: [
                buildControlButton(
                  icon: voteStatus == VoteStatus.upvoted
                      ? Icons.thumb_up
                      : Icons.thumb_up_alt_outlined,
                  active: voteStatus == VoteStatus.upvoted,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    vote(
                      upvote: true,
                      isLiked: voteStatus == VoteStatus.upvoted,
                    );
                  },
                ),
                buildControlButton(
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
                buildControlButton(
                  icon: post.isFavorited
                      ? Icons.favorite
                      : Icons.favorite_border,
                  active: post.isFavorited,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    toggleFavorite();
                  },
                ),
                if (showShare)
                  buildControlButton(
                    icon: Icons.share_outlined,
                    active: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      share();
                    },
                  ),
              ],
            ),
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
