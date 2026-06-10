import 'package:kilt/client/client.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/user/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer, ChangeNotifierProvider;

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = context.watch<Client>();
    final nav = ref.watch(navigationProvider);
    final viewUserId = nav.profileViewUserId;
    final viewUsername = nav.profileViewUsername;
    final Future<User> userFuture;
    if (viewUserId != null) {
      userFuture = client.users.get(id: viewUserId.toString());
    } else if (viewUsername != null) {
      userFuture = client.users.get(id: viewUsername);
    } else {
      if (!client.hasLogin) {
        return Scaffold(
          body: Center(
            child: IconMessage(
              icon: const Icon(Icons.person_off_outlined),
              title: const Text('Profile is not available for anonymous users'),
            ),
          ),
        );
      }
      userFuture = client.users.get(id: client.identity.username!);
    }
    return FutureBuilder<User>(
      future: userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null || snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: IconMessage(
                icon: const Icon(Icons.warning_amber_outlined),
                title: Text(
                  snapshot.hasError
                      ? 'Failed to load profile'
                      : 'User not found',
                ),
              ),
            ),
          );
        }
        return _ProfileProvider(
          user: user,
          child: _ProfileTabs(user: user),
        );
      },
    );
  }
}

class _ProfileControllers {
  _ProfileControllers({
    required this.favoritePosts,
    required this.uploadedPosts,
  });

  final PostController favoritePosts;
  final PostController uploadedPosts;

  void dispose() {
    favoritePosts.dispose();
    uploadedPosts.dispose();
  }
}

class _ProfileProvider extends SubProvider<Client, _ProfileControllers> {
  _ProfileProvider({required User user, required super.child})
    : super(
        create: (context, client) => _ProfileControllers(
          favoritePosts: UserFavoritesController(
            client: client,
            user: user.name,
          ),
          uploadedPosts: UserUploadsController(client: client, user: user.name),
        ),
        dispose: (context, value) => value.dispose(),
      );
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final stats = user.stats;
    final showUploads = (stats?.postUploadCount ?? 0) > 0;
    final showFavorites = (stats?.favoriteCount ?? 0) > 0;

    return Consumer<_ProfileControllers>(
      builder: (context, controllers, _) {
        final tabs = <Widget>[const Tab(text: 'Main')];
        if (showUploads) tabs.add(const Tab(text: 'Uploads'));
        if (showFavorites) tabs.add(const Tab(text: 'Favorites'));

        final children = <Widget>[
          SingleChildScrollView(
            padding: defaultListPadding,
            child: UserInfo(
              user: user,
              compact: true,
              aboutLeading: SizedBox(
                width: 48,
                height: 48,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: PostAvatar(id: user.avatarId),
                ),
              ),
            ),
          ),
        ];
        if (showUploads) {
          children.add(
            ChangeNotifierProvider<PostController>.value(
              value: controllers.uploadedPosts,
              child: LimitedWidthLayout(
                child: TileLayout(
                  child: CustomScrollView(
                    primary: true,
                    slivers: [
                      SliverPadding(
                        padding: defaultListPadding,
                        sliver: PostSliverDisplay(
                          controller: controllers.uploadedPosts,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        if (showFavorites) {
          children.add(
            ChangeNotifierProvider<PostController>.value(
              value: controllers.favoritePosts,
              child: LimitedWidthLayout(
                child: TileLayout(
                  child: CustomScrollView(
                    primary: true,
                    slivers: [
                      SliverPadding(
                        padding: defaultListPadding,
                        sliver: PostSliverDisplay(
                          controller: controllers.favoritePosts,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppHeaderBar(
              title: Text(user.name),
              secondary: TabBar(tabs: tabs),
            ),
            body: TabBarView(children: children),
          ),
        );
      },
    );
  }
}
