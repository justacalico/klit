import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/tag/tag.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TagDisplay extends StatelessWidget {
  const TagDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    Widget tagCategory(String category) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ...post.tags[category]!.map(
            (tag) => TagCard(
              tag: tag,
              category: category,
              onTap: () {
                Navigator.maybePop(context).whenComplete(() {
                  final nav = Get.find<NavigationController>();
                  nav.searchInitialQuery.value = tag;
                  nav.currentPath.value = AppRoutes.search;
                });
              },
            ),
          ),
        ],
      );
    }

    Widget categoryTile(String category) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '${category[0].toUpperCase()}${category.substring(1)}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Row(children: [Expanded(child: tagCategory(category))]),
          const Divider(),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: post.tags.keys
          .where((category) => post.tags[category]?.isNotEmpty ?? false)
          .map((category) => categoryTile(category))
          .toList(),
    );
  }
}
