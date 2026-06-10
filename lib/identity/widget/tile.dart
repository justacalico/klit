import 'package:kilt/app/routing/app_routes.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/user/user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IdentityTile extends StatelessWidget {
  const IdentityTile({
    super.key,
    required this.identity,
    this.trailing,
    this.onTap,
  });

  final Identity identity;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(identity.id),
      title: Text(identity.usernameOrAnon),
      subtitle: Text(linkToDisplay(identity.host)),
      leading: IdentityAvatar(identity.id),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class CurrentIdentityTile extends StatelessWidget {
  const CurrentIdentityTile({super.key});

  @override
  Widget build(BuildContext context) {
    final identity = context.watch<IdentityClient>().identity;
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(4)),
              onTap: identity.username != null
                  ? () => context.go(AppRoutes.profile)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IdentityAvatar(identity.id, radius: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            identity.usernameOrAnon,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            linkToDisplay(identity.host),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            onTap: () => openSettingsAccounts(context),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Icon(Icons.swap_horiz),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
