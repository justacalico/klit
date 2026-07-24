import 'package:kilt/account/account.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class HostUnvailablePage extends StatelessWidget {
  const HostUnvailablePage({super.key, this.offerResolve = false});

  final bool offerResolve;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: TransparentAppBar(
        child: const DefaultAppBar(leading: CloseButton()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 60),
              const SizedBox(height: 8),
              Text(
                l10n.identityHostUnavailable,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.identityHostUnavailableBody(
                  linkToDisplay(context.watch<Client>().host),
                ),
              ),
              const SizedBox(height: 16),
              if (offerResolve &&
                  PlatformCapabilities.supportsWebViewLogin) ...[
                Text(
                  l10n.identityResolveBody,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const CookieCapturePage(),
                    ),
                  ),
                  child: Text(l10n.commonResolve),
                ),
              ] else
                Dimmed(
                  child: Text(
                    l10n.identityWaitForHost(
                      linkToDisplay(context.watch<Client>().host),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
