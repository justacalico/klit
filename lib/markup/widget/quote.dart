// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/shared/shared.dart';

class QuoteWrap extends StatelessWidget {
  const QuoteWrap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IndentedCard(
      backgroundColor: Theme.of(context).canvasColor,
      color: dimTextColor(context),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [child],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
