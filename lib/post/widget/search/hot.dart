// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/post/widget/search/popular_date_control.dart';
import 'package:kilt/shared/shared.dart';

class HotPage extends StatelessWidget {
  const HotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PostProvider.builder(
        create: (context, client) => HotPostController(client: client),
        child: Consumer<PostController>(
              builder: (context, controller, child) {
                final hot = controller is HotPostController ? controller : null;
                return PostsControllerHistoryConnector(
                  controller: controller,
                  child: PostsPage(
                    controller: controller,
                    appBar: DefaultAppBar(title: Text(AppLocalizations.of(context).postPopular)),
                    bodyTop: hot != null
                        ? SafeArea(
                            bottom: false,
                            child: LimitedWidthLayout(
                              child: PopularDateInlineBar(controller: hot),
                            ),
                          )
                        : null,
                  ),
                );
              },
        ),
      );
  }
}
