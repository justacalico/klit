// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/ticket/ticket.dart';
import 'package:flutter/material.dart';

extension ExtraRatingData on Rating {
  Widget get icon {
    switch (this) {
      case Rating.s:
        return const Icon(Icons.check);
      case Rating.q:
        return const Icon(Icons.help);
      case Rating.e:
        return const Icon(Icons.warning);
    }
  }

  String title(AppLocalizations l10n) {
    switch (this) {
      case Rating.s:
        return l10n.commonRatingSafe;
      case Rating.q:
        return l10n.commonRatingQuestionable;
      case Rating.e:
        return l10n.commonRatingExplicit;
    }
  }

  String get titleName {
    switch (this) {
      case Rating.s:
        return 'Safe';
      case Rating.q:
        return 'Questionable';
      case Rating.e:
        return 'Explicit';
    }
  }
}

class RatingEditDisplay extends StatelessWidget {
  const RatingEditDisplay({super.key, required this.rating, this.onChanged});

  final Rating rating;
  final ValueChanged<Rating>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: defaultFormPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.commonRating, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Rating>(
            initialValue: rating,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: Rating.values
                .map(
                  (rating) => DropdownMenuItem(
                    value: rating,
                    child: Row(
                      children: [
                        rating.icon,
                        const SizedBox(width: 8),
                        Text(rating.title(l10n)),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged != null
                ? (value) => value != null ? onChanged!(value) : null
                : null,
          ),
        ],
      ),
    );
  }
}

Future<Rating?> showRatingDialog({
  required BuildContext context,
  ValueChanged<Rating>? onSelected,
}) async {
  final l10n = AppLocalizations.of(context);
  return showDialog<Rating>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.commonRating),
      children: Rating.values
          .map(
            (rating) => ListTile(
              title: Text(rating.title(l10n)),
              leading: rating.icon,
              onTap: () {
                onSelected?.call(rating);
                Navigator.of(context).pop(rating);
              },
            ),
          )
          .toList(),
    ),
  );
}
