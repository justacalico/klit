import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/client/client.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/tag/tag.dart';
import 'package:klit/traits/traits.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TagGesture extends StatelessWidget {
  const TagGesture({
    super.key,
    required this.child,
    required this.tag,
    this.safe = true,
    this.wiki = false,
  });

  final bool safe;
  final bool wiki;
  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    void sheet() => showTagSearchPrompt(context: context, tag: tag);

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        Traits traits = context.read<Client>().traits.value;
        if (wiki || (safe && traits.denylist.contains(tag))) {
          sheet();
        } else {
          final nav = Get.find<NavigationController>();
          nav.searchInitialQuery.value = tag;
          nav.currentPath.value = AppRoutes.search;
        }
      },
      onLongPress: sheet,
      onSecondaryTap: sheet,
      child: child,
    );
  }
}
