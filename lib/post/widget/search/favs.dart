import 'package:kilt/client/client.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class FavPage extends StatelessWidget {
  const FavPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              onError: const IconMessage(
                icon: Icon(Icons.person_search),
                title: Text('Favorites are unavailable for anonymous users'),
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
                        'Favorite order',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        controller.orderFavorites ? 'added order' : 'id order',
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
