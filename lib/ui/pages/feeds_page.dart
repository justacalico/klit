import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../shell/toolbar.dart';
import '../theme.dart';

import 'feed_edit_page.dart';

/// Feeds list page: create and open feeds (saved tag filters + image/video type).
/// Shows list or embedded feed edit so nav bar/sidebar stay visible.
class UiFeedsPage extends StatefulWidget {
  const UiFeedsPage({super.key});

  @override
  State<UiFeedsPage> createState() => _UiFeedsPageState();
}

class _UiFeedsPageState extends State<UiFeedsPage> {
  bool _showEditForm = false;
  Feed? _editingFeed;

  void _openFeed(BuildContext context, Feed feed, {int subfeedIndex = 0}) {
    var query = feed.toSearchQuery();
    if (feed.excludeFavorites) {
      final username = context.read<AuthProvider>().currentAccount?.username;
      if (username != null && username.isNotEmpty) {
        query = '$query -fav:$username';
      }
    }
    context.read<NavigationProvider>().openFeed(
      query: query,
      feedTitle: feed.name.isEmpty ? 'Feed' : feed.name,
      hostUrls: feed.hostUrls.isNotEmpty ? feed.hostUrls : null,
      rating: feed.rating,
      order: feed.order,
      subfeeds: feed.subfeeds.isNotEmpty ? feed.subfeeds : null,
      initialSubfeedIndex: subfeedIndex,
    );
  }

  void _openFeedEdit(BuildContext context, Feed? feed) {
    setState(() {
      _showEditForm = true;
      _editingFeed = feed;
    });
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

  @override
  Widget build(BuildContext context) {
    if (_showEditForm) {
      return KeyedSubtree(
        key: const ValueKey('feeds-edit'),
        child: FeedEditPage(
          feed: _editingFeed,
          onComplete: () => setState(() {
            _showEditForm = false;
            _editingFeed = null;
          }),
        ),
      );
    }

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
              onOpenFeed: (context, feed, [subfeedIndex = 0]) =>
                  _openFeed(context, feed, subfeedIndex: subfeedIndex),
              onEditFeed: _openFeedEdit,
              onDeleteFeed: _confirmDeleteFeed,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedsList extends StatelessWidget {
  final bool isDark;
  final bool isOled;
  final void Function(BuildContext, Feed, [int subfeedIndex]) onOpenFeed;
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
            Text(
              'No feeds yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a feed with tags and image or video type\nto browse posts in one tap',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
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
            onOpenFeed: onOpenFeed,
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
  final void Function(BuildContext, Feed, [int subfeedIndex]) onOpenFeed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FeedCard({
    required this.feed,
    required this.isDark,
    required this.isOled,
    required this.backgroundColor,
    required this.onOpenFeed,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = feed.mediaType == Feed.mediaTypeVideo
        ? 'Video'
        : feed.mediaType == Feed.mediaTypeAll
            ? 'Both'
            : 'Image';
    final typeColor = feed.mediaType == Feed.mediaTypeVideo
        ? AppColors.primaryBlue
        : feed.mediaType == Feed.mediaTypeAll
            ? CupertinoColors.systemGrey
            : AppColors.primaryGreen;
    final includeStr = feed.includeTags.isEmpty
        ? (feed.orTags.isEmpty ? 'no and tags' : '')
        : feed.includeTags.take(3).join(', ') + (feed.includeTags.length > 3 ? '…' : '');
    final orStr = feed.orTags.isEmpty
        ? ''
        : 'or: ${feed.orTags.take(3).join(', ')}${feed.orTags.length > 3 ? '…' : ''}';
    final excludeStr = feed.excludeTags.isEmpty
        ? ''
        : '− ${feed.excludeTags.take(2).join(', ')}${feed.excludeTags.length > 2 ? '…' : ''}';
    final hasSubfeeds = feed.subfeeds.isNotEmpty;

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
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                .withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => onOpenFeed(context, feed),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                        feed.mediaType == Feed.mediaTypeVideo
                            ? CupertinoIcons.play_rectangle_fill
                            : feed.mediaType == Feed.mediaTypeAll
                                ? CupertinoIcons.rectangle_stack_fill
                                : CupertinoIcons.photo_fill,
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
            if (hasSubfeeds) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 1,
                  color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                      .withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 16, top: 6, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < feed.subfeeds.length; i++) ...[
                      if (i > 0) const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => onOpenFeed(context, feed, i + 1),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.arrow_turn_down_right,
                                size: 14,
                                color: CupertinoColors.systemGrey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feed.subfeeds[i].name.isEmpty
                                      ? 'Sub ${i + 1}'
                                      : feed.subfeeds[i].name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? CupertinoColors.white.withValues(alpha: 0.85)
                                        : CupertinoColors.black.withValues(alpha: 0.85),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
