// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/client/client.dart';
import 'package:kilt/comment/comment.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/widgets.dart';

class CommentLoadingPage extends StatefulWidget {
  const CommentLoadingPage(this.id, {super.key});

  final int id;

  @override
  State<CommentLoadingPage> createState() => _CommentLoadingPageState();
}

class _CommentLoadingPageState extends State<CommentLoadingPage> {
  late Future<Comment> comment = context.read<Client>().comments.get(
    id: widget.id,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureLoadingPage<Comment>(
      future: comment,
      builder: (context, value) => PostCommentsPage(postId: value.postId),
      title: Text(l10n.commentCommentTitle(widget.id)),
      onError: Text(l10n.commentFailedLoadOne),
      onEmpty: Text(l10n.commentNotFound),
    );
  }
}
