import 'package:kilt/shared/widget/appbar.dart' as shared_appbar;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DefaultCupertinoAppBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  const DefaultCupertinoAppBar({
    super.key,
    this.leading,
    this.actions,
    this.title,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.border,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Border? border;

  @override
  Size get preferredSize => const Size.fromHeight(kMinInteractiveDimensionCupertino + 8);

  @override
  bool shouldFullyObstruct(BuildContext context) => true;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final paddingTop = mediaQuery.padding.top;
    final appBarHeight = preferredSize.height + paddingTop;

    return SizedBox(
      height: appBarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final leadingConfig = shared_appbar.getLeadingConfiguration(
            context: context,
            width: constraints.maxWidth,
            automaticallyImplyLeading: automaticallyImplyLeading,
            leading: leading,
          );

          final effectiveLeading = _buildCupertinoLeading(
            context,
            leadingConfig.leading,
          );

          final effectiveTitle = title;
          final effectiveActions = actions;

          return CupertinoNavigationBar(
            middle: effectiveTitle,
            leading: effectiveLeading,
            trailing: effectiveActions != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: effectiveActions,
                  )
                : null,
            automaticallyImplyLeading: false,
            backgroundColor: (backgroundColor ??
                    CupertinoTheme.of(context).barBackgroundColor)
                .withValues(alpha: 0.9),
            border: border ??
                const Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0.0,
                  ),
                ),
          );
        },
      ),
    );
  }

  Widget? _buildCupertinoLeading(BuildContext context, Widget? leading) {
    if (leading == null) {
      final route = ModalRoute.of(context);
      if (route is PageRoute && route.canPop) {
        return const CupertinoNavigationBarBackButton();
      }
      return null;
    }

    if (leading is IconButton) {
      final icon = leading.icon;
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: leading.onPressed,
        child: icon,
      );
    }

    return leading;
  }
}

