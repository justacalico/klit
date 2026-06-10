import 'package:kilt/client/client.dart';
import 'package:kilt/comment/comment.dart';
import 'package:kilt/markup/markup.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

Future<bool> replyComment({
  required BuildContext context,
  required Comment comment,
}) {
  String body = comment.body;
  body = body
      .replaceFirstMapped(
        RegExp(
          r'\[quote\]"[\S\s]*?":/user(s|/show)/\d* said:[\S\s]*?\[/quote\]',
        ),
        (match) => '',
      )
      .trim();
  body =
      '[quote]"${comment.creatorName}":/users/${comment.creatorId} said:\n$body[/quote]\n';
  return writeComment(context: context, postId: comment.postId, text: body);
}

Future<bool> editComment({
  required BuildContext context,
  required Comment comment,
}) => writeComment(postId: comment.postId, context: context, comment: comment);

Future<bool> writeComment({
  required BuildContext context,
  required int postId,
  String? text,
  Comment? comment,
}) async {
  bool sent = false;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => DTextEditor(
        title: Text('#$postId comment'),
        content: text ?? (comment?.body),
        onSubmitted: (text) async {
          ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
          if (text.isNotEmpty) {
            String? error;
            if (comment == null) {
              error = await submitNewComment(
                context: context,
                postId: postId,
                text: text,
              );
            } else {
              try {
                await context.read<Client>().comments.update(
                  id: comment.id,
                  postId: postId,
                  content: text,
                );
              } on ClientException {
                error = 'Failed to send comment!';
              }
            }
            if (error != null) return error;
            sent = true;
            messenger.showSnackBar(
              const SnackBar(
                duration: Duration(seconds: 1),
                content: Text('Comment sent!'),
              ),
            );
          }
          return null;
        },
        onClosed: Navigator.of(context).maybePop,
      ),
    ),
  );
  return sent;
}

Future<String?> submitNewComment({
  required BuildContext context,
  required int postId,
  required String text,
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 'Comment cannot be empty';
  try {
    await context.read<Client>().comments.create(
      postId: postId,
      content: trimmed,
    );
    return null;
  } on ClientException {
    return 'Failed to send comment!';
  }
}

extension Transitioning on Comment {
  String get hero => getCommentHero(id);
}

String getCommentHero(int id) => 'comment_$id';
