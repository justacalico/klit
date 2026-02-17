import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../../core/constants/constants.dart';

/// Custom iOS-style navigation bar with blur effect
class CustomAppBar extends StatelessWidget implements ObstructingPreferredSizeWidget {
  final String title;
  final bool largeTitle;
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;
  final bool showBorder;
  final VoidCallback? onTitleTap;

  const CustomAppBar({
    super.key,
    required this.title,
    this.largeTitle = false,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.showBorder = true,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isDark
                    ? const Color(0xF01C1C1E)
                    : const Color(0xF0F9F9F9)),
            border: showBorder
                ? Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.darkSeparator
                          : AppColors.lightSeparator,
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: largeTitle ? 96 : 44,
              child: largeTitle
                  ? _buildLargeTitleBar(context)
                  : _buildStandardBar(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardBar(BuildContext context) {
    return Row(
      children: [
        if (leading != null)
          leading!
        else
          const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: onTitleTap,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (trailing != null)
          trailing!
        else
          const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLargeTitleBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              if (leading != null) leading!,
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: onTitleTap,
            child: Text(
              title,
              style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(largeTitle ? 96 : 44);

  @override
  bool shouldFullyObstruct(BuildContext context) => false;
}

/// Search bar for the app bar
class AppBarSearchButton extends StatelessWidget {
  final VoidCallback onTap;

  const AppBarSearchButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(12),
      onPressed: onTap,
      child: const Icon(
        CupertinoIcons.search,
        size: 22,
      ),
    );
  }
}

/// App bar action button
class AppBarActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const AppBarActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(12),
      onPressed: onTap,
      child: Icon(
        icon,
        size: 22,
        color: color ?? CupertinoTheme.of(context).primaryColor,
      ),
    );
  }
}
