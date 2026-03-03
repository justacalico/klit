import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/tag/tag.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TagCard extends StatelessWidget {
  const TagCard({super.key, required this.tag, this.category, this.onRemove});

  final String tag;
  final String? category;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ColoredCard(
      color:
          (category != null ? TagCategory.byName(category!)?.color : null) ??
          Colors.grey,
      onTap: () {
        final nav = Get.find<NavigationController>();
        nav.searchInitialQuery.value = tag;
        nav.currentPath.value = AppRoutes.search;
      },
      onLongPress: () => showTagSearchPrompt(context: context, tag: tag),
      onSecondaryTap: () => showTagSearchPrompt(context: context, tag: tag),
      leading: onRemove != null
          ? IconButton(
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.clear, size: 16),
              onPressed: onRemove,
            )
          : null,
      child: Text(tagToTitle(tag), overflow: TextOverflow.ellipsis),
    );
  }
}

class TagCounterCard extends StatelessWidget {
  const TagCounterCard({
    super.key,
    required this.tag,
    required this.count,
    this.category,
  });

  final String tag;
  final int count;
  final String? category;

  @override
  Widget build(BuildContext context) {
    return ColoredCard(
      onTap: () => showTagSearchPrompt(context: context, tag: tag),
      onLongPress: () => showTagSearchPrompt(context: context, tag: tag),
      onSecondaryTap: () => showTagSearchPrompt(context: context, tag: tag),
      color: (category != null ? TagCategory.byName(category!)?.color : null),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2,
            height: 18,
            color: Theme.of(context).dividerColor,
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(count.toString()),
            ),
          ),
        ],
      ),
      child: Text(tagToTitle(tag), overflow: TextOverflow.ellipsis),
    );
  }
}

class DenyListTagCard extends StatelessWidget {
  const DenyListTagCard(this.tag, {super.key});

  final String tag;

  Color? getTagColor(String tag) {
    String prefix = tag[0];
    switch (prefix) {
      case '-':
        return Colors.green[300];
      case '~':
        return Colors.orange[300];
      case '#':
        return Colors.blue[300];
      default:
        return Colors.red[300];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredCard(
      color: getTagColor(tag),
      onTap: () => showTagSearchPrompt(context: context, tag: tag),
      onLongPress: () => showTagSearchPrompt(context: context, tag: tag),
      onSecondaryTap: () => showTagSearchPrompt(context: context, tag: tag),
      child: Text(tagToTitle(tag), overflow: TextOverflow.ellipsis),
    );
  }
}
