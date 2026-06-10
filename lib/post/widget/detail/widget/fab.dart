import 'package:kilt/post/post.dart';
import 'package:flutter/material.dart';

class PostDetailFloatingActionButton extends StatelessWidget {
  const PostDetailFloatingActionButton({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    heroTag: null,
    clipBehavior: Clip.antiAlias,
    backgroundColor: Theme.of(context).cardColor,
    foregroundColor: Theme.of(context).iconTheme.color,
    onPressed: () {},
    child: Padding(
      padding: const EdgeInsets.only(left: 2),
      child: FavoriteButton(post: post),
    ),
  );
}
