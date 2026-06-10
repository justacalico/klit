import 'package:kilt/client/client.dart';
import 'package:kilt/feed/data/feed.dart';
import 'package:kilt/feed/feeds_provider.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'feed_edit_page.dart';

class FeedsPage extends StatefulWidget {
  const FeedsPage({super.key});

  @override
  State<FeedsPage> createState() => _FeedsPageState();
}

class _FeedsPageState extends State<FeedsPage> {
  bool _showEditForm = false;
  Feed? _editingFeed;

  @override
  void initState() {
    super.initState();
    context.read<FeedsProvider>().loadFeeds();
  }

  void _openFeed(BuildContext context, Feed feed, {List<int> path = const []}) {
    var query = feed.toSearchQueryWithPath(path);
    if (feed.excludeFavorites) {
      final username = context.read<Client>().identity.username;
      if (username != null && username.isNotEmpty) {
        query = '$query -fav:$username';
      }
    }
    if (feed.rating != null && feed.rating!.isNotEmpty) {
      query = '$query rating:${feed.rating}';
    }
    query = '$query order:${feed.order}';
    context.go('/search?tags=${Uri.encodeComponent(query)}');
  }

  void _openEdit(BuildContext context, Feed? feed) {
    setState(() {
      _showEditForm = true;
      _editingFeed = feed;
    });
  }

  void _closeEdit() {
    setState(() {
      _showEditForm = false;
      _editingFeed = null;
    });
  }

  void _confirmDelete(BuildContext context, Feed feed) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete feed'),
        content: Text('Delete "${feed.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<FeedsProvider>().deleteFeed(feed.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showEditForm) {
      return Scaffold(
        appBar: DefaultAppBar(
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _closeEdit, minimumSize: Size(0, 0),
            child: const Icon(Icons.arrow_back_ios_new),
          ),
          title: Text(_editingFeed == null ? 'New feed' : 'Edit feed'),
        ),
        body: LimitedWidthLayout.builder(
          builder: (context) => FeedEditPage(
            feed: _editingFeed,
            onComplete: _closeEdit,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: DefaultAppBar(
        title: const Text('Feeds'),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _openEdit(context, null), minimumSize: Size(0, 0),
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: LimitedWidthLayout.builder(
        builder: (context) => Consumer<FeedsProvider>(
          builder: (context, provider, _) {
            if (!provider.loaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final feeds = provider.feeds;
            if (feeds.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rss_feed, size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'No feeds yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a feed with tags and image or video type to browse posts in one tap',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                      CupertinoButton.filled(
                        onPressed: () => _openEdit(context, null),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add),
                            SizedBox(width: 8),
                            Text('Create feed'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              primary: true,
              padding: defaultActionListPadding.add(LimitedWidthLayout.of(context).padding),
              itemCount: feeds.length,
              itemBuilder: (context, index) {
                final feed = feeds[index];
                return _FeedCard(
                  feed: feed,
                  onOpen: () => _openFeed(context, feed),
                  onOpenSubfeed: (path) => _openFeed(context, feed, path: path),
                  onEdit: () => _openEdit(context, feed),
                  onDelete: () => _confirmDelete(context, feed),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FeedCardSurface extends StatelessWidget {
  const _FeedCardSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ThemedSectionCard(
      child: child,
    );
  }
}

class _FeedActionsButton extends StatelessWidget {
  const _FeedActionsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed, minimumSize: Size(28, 28),
      child: Icon(
        Icons.more_vert,
        size: 20,
        color: CupertinoColors.label.resolveFrom(context),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.feed,
    required this.onOpen,
    required this.onOpenSubfeed,
    required this.onEdit,
    required this.onDelete,
  });

  final Feed feed;
  final VoidCallback onOpen;
  final void Function(List<int> path) onOpenSubfeed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static void _collectEntries(List<SubFeed> level, List<int> path, List<({List<int> path, String name, int depth})> out, int depth) {
    for (var i = 0; i < level.length; i++) {
      final sub = level[i];
      final p = [...path, i];
      out.add((path: p, name: sub.name.isEmpty ? 'Sub ${p.join('-')}' : sub.name, depth: depth));
      _collectEntries(sub.subfeeds, p, out, depth + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    final typeLabel = feed.mediaType == Feed.mediaTypeVideo
        ? 'Video'
        : feed.mediaType == Feed.mediaTypeAll
            ? 'Image & video'
            : 'Image';
    final includeStr = feed.includeTags.isEmpty
        ? (feed.orTags.isEmpty ? 'no tags' : '')
        : feed.includeTags.take(3).join(', ') + (feed.includeTags.length > 3 ? '…' : '');
    final entries = <({List<int> path, String name, int depth})>[];
    _collectEntries(feed.subfeeds, [], entries, 0);
    return _FeedCardSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.rss_feed,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feed.name.isEmpty ? 'Unnamed feed' : feed.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [if (includeStr.isNotEmpty) includeStr, typeLabel]
                            .where((e) => e.isNotEmpty)
                            .join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _FeedActionsButton(onPressed: () => _showFeedActionsSheet(context)),
              ],
            ),
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: theme.dividerColor),
            ...entries.map((e) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onOpenSubfeed(e.path),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24.0 + (e.depth * 20),
                        child: Icon(
                          Icons.subdirectory_arrow_right,
                          size: 16,
                          color: onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.name,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _showFeedActionsSheet(BuildContext context) {
    final theme = Theme.of(context);
    final cupertino = CupertinoTheme.of(context);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SafeArea(
          top: false,
          child: GlassSurface(
            borderRadius: 20,
            blurSigma: 20,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                CupertinoListTile(
                  leading: Icon(
                    CupertinoIcons.pencil,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                  title: const Text('Edit'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).maybePop();
                    onEdit();
                  },
                ),
                CupertinoListTile(
                  leading: Icon(
                    CupertinoIcons.trash,
                    color: cupertino.primaryColor,
                  ),
                  title: const Text('Delete'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).maybePop();
                    onDelete();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
