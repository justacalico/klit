// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/ticket/ticket.dart';
import 'package:flutter/material.dart';

class EditReasonDisplay extends StatelessWidget {
  const EditReasonDisplay({super.key, required this.controller, this.enabled});

  final TextEditingController controller;
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: defaultFormPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.postEditReasonOptional, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.postEditReasonHint,
            ),
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}
