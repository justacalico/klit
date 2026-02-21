import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../core/constants/constants.dart';
import '../../core/types/navigation_args.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../shell/toolbar.dart';
import '../theme.dart';

/// Feeds list page: create and open feeds (saved tag filters + image/video type).
class UiFeedsPage extends StatelessWidget {
  const UiFeedsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final isOled = context.watch<SettingsProvider>().themeMode == 3;

    return KeyedSubtree(
      key: const ValueKey('feeds-page'),
      child: Column(
        children: [
          PageToolbar(
            title: 'Feeds',
            icon: CupertinoIcons.rectangle_stack_fill,
            actions: [
              ToolbarButton(
                icon: CupertinoIcons.add,
                tooltip: 'New feed',
                onPressed: () => _openFeedEdit(context, null),
              ),
            ],
          ),
          Expanded(
            child: _FeedsList(
              isDark: isDark,
              isOled: isOled,
              onOpenFeed: _openFeed,
              onEditFeed: _openFeedEdit,
              onDeleteFeed: _confirmDeleteFeed,
            ),
          ),
        ],
      ),
    );
  }

  void _openFeed(BuildContext context, Feed feed) {
    final args = SearchRouteArguments(
      query: feed.toSearchQuery(),
      feedTitle: feed.name.isEmpty ? 'Feed' : feed.name,
    );
    Navigator.of(context).pushNamed(AppRoutes.search, arguments: args);
  }

  void _openFeedEdit(BuildContext context, Feed? feed) {
    Navigator.of(context).pushNamed(
      AppRoutes.feedEdit,
      arguments: feed,
    );
  }

  void _confirmDeleteFeed(BuildContext context, Feed feed) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete feed'),
        content: Text('Delete "${feed.name}"?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<FeedsProvider>().deleteFeed(feed.id);
            },
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _FeedsList extends StatelessWidget {
  final bool isDark;
  final bool isOled;
  final void Function(BuildContext, Feed) onOpenFeed;
  final void Function(BuildContext, Feed?) onEditFeed;
  final void Function(BuildContext, Feed) onDeleteFeed;

  const _FeedsList({
    required this.isDark,
    required this.isOled,
    required this.onOpenFeed,
    required this.onEditFeed,
    required this.onDeleteFeed,
  });

  @override
  Widget build(BuildContext context) {
    final feeds = context.watch<FeedsProvider>().feeds;

    if (feeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.rectangle_stack_fill,
              size: 64,
              color: UIColors.primaryPurple.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No feeds yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a feed with tags and image or video type\nto browse posts in one tap',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () => onEditFeed(context, null),
              child: const Text('Create feed'),
            ),
          ],
        ),
      );
    }

    final bg = AppColors.resolveSecondaryBackground(isDark, isOled: isOled);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: feeds.length,
      itemBuilder: (context, index) {
        final feed = feeds[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FeedCard(
            feed: feed,
            isDark: isDark,
            isOled: isOled,
            backgroundColor: bg,
            onTap: () => onOpenFeed(context, feed),
            onEdit: () => onEditFeed(context, feed),
            onDelete: () => onDeleteFeed(context, feed),
          ),
        );
      },
    );
  }
}

class _FeedCard extends StatelessWidget {
  final Feed feed;
  final bool isDark;
  final bool isOled;
  final Color backgroundColor;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FeedCard({
    required this.feed,
    required this.isDark,
    required this.isOled,
    required this.backgroundColor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = feed.isVideo ? 'Video' : 'Image';
    final typeColor = feed.isVideo ? AppColors.primaryBlue : AppColors.primaryGreen;
    final includeStr = feed.includeTags.isEmpty
        ? (feed.orTags.isEmpty ? 'no and tags' : '')
        : feed.includeTags.take(3).join(', ') + (feed.includeTags.length > 3 ? '…' : '');
    final orStr = feed.orTags.isEmpty
        ? ''
        : 'or: ${feed.orTags.take(3).join(', ')}${feed.orTags.length > 3 ? '…' : ''}';
    final excludeStr = feed.excludeTags.isEmpty
        ? ''
        : '− ${feed.excludeTags.take(2).join(', ')}${feed.excludeTags.length > 2 ? '…' : ''}';

    return CupertinoContextMenu(
      actions: [
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.of(context).pop();
            onEdit();
          },
          child: const Text('Edit'),
        ),
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.of(context).pop();
            onDelete();
          },
          child: const Text('Delete'),
        ),
      ],
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                  .withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  feed.isVideo ? CupertinoIcons.play_rectangle_fill : CupertinoIcons.photo_fill,
                  color: typeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feed.name.isEmpty ? 'Unnamed feed' : feed.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? CupertinoColors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (includeStr.isNotEmpty) includeStr,
                        if (orStr.isNotEmpty) orStr,
                        if (excludeStr.isNotEmpty) excludeStr,
                      ].join('  '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                onPressed: onEdit,
                child: const Icon(CupertinoIcons.pencil, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
