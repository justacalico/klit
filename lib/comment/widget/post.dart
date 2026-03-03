import 'package:klit/client/client.dart';
import 'package:klit/comment/comment.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';

class PostCommentsPage extends StatelessWidget {
  const PostCommentsPage({super.key, required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context) {
    final client = context.watch<Client>();
    return CommentProvider(
      postId: postId,
      child: AdaptiveScaffold(
        appBar: DefaultAppBar(
          title: Text('#$postId comments'),
          actions: const [ContextDrawerButton()],
        ),
        floatingActionButton: client.hasLogin
            ? CommentCreateFab(postId: postId)
            : null,
        endDrawer: const CommentListDrawer(),
        body: const CommentList(),
      ),
    );
  }
}
