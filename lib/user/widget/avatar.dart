// SPDX-License-Identifier: AGPL-3.0

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:kilt/account/account.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/traits/traits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_sub/flutter_sub.dart';

/// In-memory cache of avatar URLs keyed by identity id, so each identity's
/// avatar is only looked up once per session. The image bytes themselves are
/// cached on disk by [CachedNetworkImage] through the [BaseCacheManager].
final Map<int, String?> _identityAvatarUrlCache = {};

/// Looks up the avatar image URL for [identity] from its host. Uses the shared
/// HTTP cache so repeated lookups are cheap. Returns null when the identity has
/// no username or no avatar configured.
Future<String?> _lookupIdentityAvatarUrl(
  Identity identity,
  CacheStore? cache,
) async {
  if (identity.username == null) return null;
  final dio = createDefaultDio(identity, cache: cache);
  try {
    final account = await dio
        .get('/users/${identity.username}.json')
        .then((response) => E621Account.fromJson(response.data));
    final avatarId = account.avatarId;
    if (avatarId == null) return null;
    final post = await dio
        .get(
          '/posts/$avatarId.json',
          queryParameters: {'v2': true, 'mode': 'extended'},
        )
        .then((response) => E621Post.fromJson(response.data));
    return post.preview ?? post.sample ?? post.file;
  } catch (_) {
    return null;
  } finally {
    dio.close();
  }
}

class IdentityAvatar extends StatefulWidget {
  const IdentityAvatar(this.id, {super.key, this.radius = 20});

  final int id;
  final double radius;

  @override
  State<IdentityAvatar> createState() => _IdentityAvatarState();
}

class _IdentityAvatarState extends State<IdentityAvatar> {
  Future<String?>? _lookup;

  Future<String?> _resolveAvatar() async {
    final identityClient = context.read<IdentityClient>();
    final storage = context.read<AppStorage>();
    final identity = await identityClient.getOrNull(widget.id);
    if (identity == null) return null;
    return _lookupIdentityAvatarUrl(identity, storage.httpCache);
  }

  @override
  Widget build(BuildContext context) {
    final traitsClient = context.read<TraitsClient>();
    return SubStream<Traits?>(
      create: () => traitsClient.getOrNull(widget.id).stream,
      keys: [widget.id],
      builder: (context, snapshot) {
        final avatar =
            snapshot.data?.avatar ?? _identityAvatarUrlCache[widget.id];
        if (avatar != null) {
          return Avatar(avatar, radius: widget.radius);
        }
        _lookup ??= _resolveAvatar();
        return FutureBuilder<String?>(
          future: _lookup,
          builder: (context, fetchSnapshot) {
            if (fetchSnapshot.connectionState != ConnectionState.done) {
              return EmptyAvatar(radius: widget.radius);
            }
            final url = fetchSnapshot.data;
            if (url == null) {
              return EmptyAvatar(radius: widget.radius);
            }
            _identityAvatarUrlCache[widget.id] = url;
            return Avatar(url, radius: widget.radius);
          },
        );
      },
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.controller, required this.id});

  final PostController? controller;
  final int? id;

  @override
  Widget build(BuildContext context) {
    int? id = this.id;
    PostController? controller = this.controller;
    if (id == null || controller == null) {
      return const EmptyAvatar();
    }
    return SubFuture<PostController>(
      create: () => Future<PostController>(() async {
        await controller.getNextPage();
        return controller;
      }),
      keys: [controller],
      builder: (context, _) => PostsControllerConnector(
        id: id,
        controller: controller,
        builder: (context, post) => Avatar(
          post?.sample,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostsControllerConnector(
                id: id,
                controller: controller,
                builder: (context, post) => PostsRouteConnector(
                  controller: controller,
                  child: PostDetail(post: post!),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PostAvatar extends StatelessWidget {
  const PostAvatar({super.key, required this.id});

  final int? id;

  @override
  Widget build(BuildContext context) {
    if (id == null) {
      return const EmptyAvatar();
    } else {
      return SinglePostProvider(
        id: id!,
        child: Consumer<PostController>(
          builder: (context, controller, child) =>
              UserAvatar(id: id, controller: controller),
        ),
      );
    }
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.url, {super.key, this.onTap, this.radius = 20});

  final String? url;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (url case final url?) {
      return MouseCursorRegion(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle),
          clipBehavior: Clip.antiAlias,
          width: radius * 2,
          height: radius * 2,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            cacheManager: context.read<BaseCacheManager>(),
            placeholder: (context, url) => EmptyAvatar(radius: radius),
            errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.warning_amber)),
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
          ),
        ),
      );
    } else {
      return EmptyAvatar(radius: radius);
    }
  }
}

class EmptyAvatar extends StatelessWidget {
  const EmptyAvatar({super.key, this.radius = 20});

  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(shape: BoxShape.circle),
    clipBehavior: Clip.antiAlias,
    width: radius * 2,
    height: radius * 2,
    child: Image.asset('assets/icon/app/user.png'),
  );
}
