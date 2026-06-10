import 'package:kilt/client/client.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/user/user.dart';
import 'package:flutter/material.dart';

class CommenterAvatar extends StatelessWidget {
  const CommenterAvatar({
    super.key,
    required this.userId,
    this.radius = 16,
  });

  final int userId;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final client = context.watch<Client>();
    return FutureBuilder<User>(
      future: client.users.get(id: userId.toString()),
      builder: (context, snapshot) {
        final avatarId = snapshot.data?.avatarId;
        if (avatarId == null) {
          return EmptyAvatar(radius: radius);
        }
        return SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: FittedBox(
            fit: BoxFit.contain,
            child: PostAvatar(id: avatarId),
          ),
        );
      },
    );
  }
}
