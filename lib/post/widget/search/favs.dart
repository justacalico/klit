// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/client/client.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class FavPage extends StatelessWidget {
  const FavPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PostProvider.builder(
        create: (context, client) => FavoritePostController(client: client),
        child: Consumer<PostController>(
          builder: (context, controller, child) => ControllerHistoryConnector(
            controller: controller,
            addToHistory: (context, client, controller) => client.histories.add(
              PostHistoryRequest.search(
                query: controller.query,
                posts: controller.items,
              ),
            ),
            child: LoadingPage(
              isEmpty: controller.error is NoUserLoginException,
              isError: controller.error is NoUserLoginException,
              onError: IconMessage(
                icon: const Icon(Icons.person_search),
                title: Text(l10n.postFavsUnavailable),
              ),
              loadingBuilder: (context, child) => AdaptiveScaffold(
                body: Center(child: child(context)),
              ),
              child: (context) => PostsPage(
                controller: controller,
                drawerActions: [
                  if (controller.query['tags']?.isEmpty ?? true)
                    SwitchListTile(
                      secondary: const Icon(Icons.sort),
                      title: Text(
                        l10n.postFavOrder,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        controller.orderFavorites ? l10n.postFavOrderAdded : l10n.postFavOrderId,
                      ),
                      value: controller.orderFavorites,
                      onChanged: (value) {
                        controller.orderFavorites = value;
                        Navigator.of(context).maybePop();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
