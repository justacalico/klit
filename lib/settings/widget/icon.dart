// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIcon extends StatelessWidget {
  const AppIcon({super.key, this.radius = 20});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final cornerRadius = size * 0.22;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF131313)
            : null,
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: SvgPicture.asset(
        'assets/icon/app/icon.svg',
        fit: BoxFit.cover,
        width: size,
        height: size,
      ),
    );
  }
}
