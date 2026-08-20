// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DividerListTile extends StatelessWidget {
  const DividerListTile({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.separated,
    this.contentPadding,
    this.onTapSeparated,
    this.onLongPressSeparated,
  });

  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? separated;
  final VoidCallback? onTap;
  final VoidCallback? onTapSeparated;
  final VoidCallback? onLongPressSeparated;
  final VoidCallback? onLongPress;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: CupertinoListTile(
              title: title ?? const SizedBox.shrink(),
              subtitle: subtitle,
              leading: leading,
              trailing: trailing,
              onTap: onTap,
              additionalInfo: null,
            ),
          ),
          if (separated != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onTapSeparated,
              child: SizedBox(
                width: 80,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        color: Theme.of(context).dividerColor,
                        width: 2,
                      ),
                    ),
                    separated!,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
