import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/markup/markup.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:flutter/material.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.entry});

  final History entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: const E621LinkParser().parseOnTap(context, entry.link),
            child: SelectionItemOverlay<History>(
              item: entry,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HistoryTileHeader(entry: entry),
                    if (entry.category != HistoryCategory.searches)
                      _HistoryTileDescription(entry: entry),
                    if (entry.category != HistoryCategory.searches)
                      _HistoryTileImages(entry: entry),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Divider(indent: 8, endIndent: 8),
      ],
    );
  }
}

class _HistoryTileHeader extends StatelessWidget {
  const _HistoryTileHeader({required this.entry});

  final History entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TimedText(
            created: entry.visitedAt,
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(entry.getName(context)),
              ),
            ),
          ),
        ),
        _HistoryTileDropdown(entry: entry),
      ],
    );
  }
}

class _HistoryTileDescription extends StatelessWidget {
  const _HistoryTileDescription({required this.entry});

  final History entry;

  @override
  Widget build(BuildContext context) {
    if (entry.subtitle?.isNotEmpty ?? false) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: ExcludeFocus(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.7,
              child: DText(entry.subtitle!.ellipse(400)),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox(height: 8);
    }
  }
}

class _HistoryTileDropdown extends StatelessWidget {
  const _HistoryTileDropdown({required this.entry});

  final History entry;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      icon: Icon(Icons.more_vert, color: dimTextColor(context)),
      iconSize: 18,
      onSelected: (value) => value(),
      itemBuilder: (context) => [
        if (entry.isSearch(LinkType.post))
          PopupMenuTile(
            title: 'Wiki',
            icon: Icons.info,
            value: () => showTagSearchPrompt(
              context: context,
              tag: const E621LinkParser().parse(entry.link)!.query!['tags']!,
            ),
          ),
        if (entry.subtitle != null)
          PopupMenuTile(
            title: 'Description',
            icon: Icons.description,
            value: () => historySheet(context: context, entry: entry),
          ),
        PopupMenuTile(
          title: 'Share',
          icon: Icons.share,
          value: () =>
              Share.text(context, context.read<Client>().withHost(entry.link)),
        ),
        PopupMenuTile(
          title: 'Delete',
          icon: Icons.delete,
          value: () => context.read<Client>().histories.remove(entry.id),
        ),
      ],
    );
  }
}

class _HistoryTileImages extends StatelessWidget {
  const _HistoryTileImages({required this.entry});

  final History entry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: entry.thumbnails.isNotEmpty ? 300 : 0,
      child: entry.thumbnails.isNotEmpty
          ? HistoryImageGrid(images: entry.thumbnails)
          : const SizedBox.shrink(),
    );
  }
}
