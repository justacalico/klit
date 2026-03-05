import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PostDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PostDetailAppBar({super.key, required this.post});

  final Post post;

  @override
  Size get preferredSize => const Size.fromHeight(defaultAppBarHeight);

  @override
  Widget build(BuildContext context) {
    return TransparentAppBar(
      child: DefaultAppBar(
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: const Size(44, 44),
            onPressed: () => showPostMenuSheet(context, post),
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }
}
