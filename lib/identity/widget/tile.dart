import 'package:klit/app/routes/app_routes.dart';
import 'package:klit/identity/identity.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/user/user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
                  ? () => Get.offAllNamed(
                      AppRoutes.home,
                      arguments: {'path': AppRoutes.profile},
                    )
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
            onTap: openSettingsAccounts,
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
