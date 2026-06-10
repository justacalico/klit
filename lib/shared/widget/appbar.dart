import 'package:kilt/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

mixin AppBarBuilderWidget implements PreferredSizeWidget {
  abstract final PreferredSizeWidget child;

  @override
  Size get preferredSize => child.preferredSize;
}

class AppBarBuilder extends StatelessWidget with AppBarBuilderWidget {
  const AppBarBuilder({super.key, required this.child, required this.builder});

  @override
  final PreferredSizeWidget child;
  final Widget Function(BuildContext context, PreferredSizeWidget child)
  builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

AppBarLeadingConfiguration getLeadingConfiguration({
  required BuildContext context,
  required double width,
  double? alwaysShowDrawerBreakpoint = 800,
  Widget? leading,
  bool automaticallyImplyLeading = true,
}) {
  const minimumTapTarget = Size(44, 44);
  bool alwaysShowDrawer =
      alwaysShowDrawerBreakpoint != null && width >= alwaysShowDrawerBreakpoint;

  Widget? effectiveLeading = leading;
  double? leadingWidth;
  if (leading == null && automaticallyImplyLeading) {
    bool hasDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;
    ModalRoute? parentRoute = ModalRoute.of(context);
    bool isFirst = parentRoute?.isFirst ?? false;
    bool canPop = parentRoute?.canPop ?? false;

    Widget drawerButton() => CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: minimumTapTarget,
      onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
      child: const Icon(CupertinoIcons.line_horizontal_3),
    );

    Widget backButton =
        parentRoute is PageRoute<dynamic> && parentRoute.fullscreenDialog
        ? CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: minimumTapTarget,
            onPressed: () => Navigator.maybePop(context),
            child: const Icon(Icons.close),
          )
        : CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: minimumTapTarget,
            onPressed: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new),
          );

    if (hasDrawer && isFirst) {
      effectiveLeading = drawerButton();
    } else if (canPop) {
      if (alwaysShowDrawer && hasDrawer) {
        leadingWidth = 88;
        effectiveLeading = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            Expanded(child: drawerButton()),
            Expanded(child: backButton),
          ],
        );
      } else {
        effectiveLeading = backButton;
      }
    }
  }
  return AppBarLeadingConfiguration(
    leading: effectiveLeading,
    leadingWidth: leadingWidth,
  );
}

IconData getPlatformBackIcon(BuildContext context) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return Icons.arrow_back;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return Icons.arrow_back_ios_new;
  }
}

enum AppHeaderDensity { compact, regular, spacious }

enum AppHeaderSurface { solid, translucent, transparent }

class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const AppHeaderBar({
    super.key,
    this.leading,
    this.actions,
    this.title,
    this.secondary,
    this.automaticallyImplyLeading = true,
    this.ignoreTitlePointer = true,
    this.density = AppHeaderDensity.regular,
    this.surface = AppHeaderSurface.translucent,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? secondary;
  final bool automaticallyImplyLeading;
  final bool ignoreTitlePointer;
  final AppHeaderDensity density;
  final AppHeaderSurface surface;

  double get _secondaryHeight {
    return switch (density) {
      AppHeaderDensity.compact => 52,
      AppHeaderDensity.regular => 60,
      AppHeaderDensity.spacious => 68,
    };
  }

  @override
  Size get preferredSize => Size.fromHeight(
    defaultAppBarHeight + (secondary != null ? _secondaryHeight : 0),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cupertinoTheme = CupertinoTheme.of(context);
    final secondaryFill = theme.brightness == Brightness.dark
        ? Color.lerp(theme.cardColor, Colors.white, 0.06)!
        : theme.colorScheme.surfaceContainerHighest;

    Color navColor() {
      return switch (surface) {
        AppHeaderSurface.solid => cupertinoTheme.barBackgroundColor,
        AppHeaderSurface.translucent =>
          cupertinoTheme.barBackgroundColor.withValues(alpha: 0.9),
        AppHeaderSurface.transparent => Colors.transparent,
      };
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final leadingConfig = getLeadingConfiguration(
          context: context,
          width: constraints.maxWidth,
          automaticallyImplyLeading: automaticallyImplyLeading,
          leading: leading,
        );
        final bar = CupertinoNavigationBar(
          leading: leadingConfig.leading,
          middle: IgnorePointer(ignoring: ignoreTitlePointer, child: title),
          trailing: actions != null && actions!.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [...actions!, const SizedBox(width: 8)],
                )
              : null,
          backgroundColor: navColor(),
          border: null,
        );
        if (secondary == null) {
          return PreferredSize(preferredSize: preferredSize, child: bar);
        }
        return PreferredSize(
          preferredSize: preferredSize,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              bar,
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Material(
                  color: secondaryFill,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(height: _secondaryHeight, child: secondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// A preconfigured appbar.
  ///
  /// Contains extra behaviour such as:
  /// - double tap to scroll to the top of the primary scroll controller
  /// - showing drawer and back button at the same time on wide screens
  const DefaultAppBar({
    super.key,
    this.leading,
    this.actions,
    this.title,
    this.secondary,
    this.elevation,
    this.automaticallyImplyLeading = true,
    this.ignoreTitlePointer = true,
    this.surface = AppHeaderSurface.translucent,
    this.density = AppHeaderDensity.regular,
  });

  /// Copied from [AppBar.title].
  final Widget? title;

  /// Copied from [AppBar.leading].
  final Widget? leading;

  /// Copied from [AppBar.actions].
  final List<Widget>? actions;

  final Widget? secondary;

  /// Copied from [AppBar.elevation].
  final double? elevation;

  /// Copied from [AppBar.automaticallyImplyLeading].
  final bool automaticallyImplyLeading;

  /// Ignores tapping the title.
  final bool ignoreTitlePointer;

  final AppHeaderSurface surface;
  final AppHeaderDensity density;

  @override
  Size get preferredSize => AppHeaderBar(
    title: title,
    leading: leading,
    actions: actions,
    secondary: secondary,
    automaticallyImplyLeading: automaticallyImplyLeading,
    ignoreTitlePointer: ignoreTitlePointer,
    surface: surface,
    density: density,
  ).preferredSize;

  @override
  Widget build(BuildContext context) {
    return AppHeaderBar(
      title: title,
      leading: leading,
      actions: actions,
      secondary: secondary,
      automaticallyImplyLeading: automaticallyImplyLeading,
      ignoreTitlePointer: ignoreTitlePointer,
      surface: surface,
      density: density,
    );
  }
}

class AppBarLeadingConfiguration {
  /// Holds the configuration for a leading widget in an AppBar.
  const AppBarLeadingConfiguration({this.leading, this.leadingWidth});

  /// The leading widget.
  final Widget? leading;

  /// The width of the leading widget.
  final double? leadingWidth;
}

class ScrollToTop extends StatelessWidget {
  const ScrollToTop({
    super.key,
    this.builder,
    this.child,
    this.controller,
    this.height,
    this.primary = true,
  });

  final Widget Function(BuildContext context, Widget child)? builder;
  final Widget? child;
  final ScrollController? controller;
  final double? height;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    Widget tapWrapper(Widget? child) {
      ScrollController? controller =
          this.controller ??
          (primary ? PrimaryScrollController.of(context) : null);
      return GestureDetector(
        onDoubleTap: controller != null
            ? () => controller.animateTo(
                0,
                duration: defaultAnimationDuration,
                curve: Curves.easeOut,
              )
            : null,
        child: Container(
          height: height,
          color: Colors.transparent,
          child: child != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(children: [Expanded(child: child)]),
                    ),
                  ],
                )
              : null,
        ),
      );
    }

    Widget Function(BuildContext context, Widget child) builder =
        this.builder ?? (context, child) => child;

    return builder(context, tapWrapper(child));
  }
}

class TransparentAppBar extends StatelessWidget with AppBarBuilderWidget {
  const TransparentAppBar({
    super.key,
    this.transparent = true,
    required this.child,
  });

  final bool transparent;

  @override
  final PreferredSizeWidget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: Theme.of(context).copyWith(
        appBarTheme: Theme.of(context).appBarTheme.copyWith(
          iconTheme: Theme.of(context).iconTheme.copyWith(
            shadows: [
              Shadow(color: Theme.of(context).canvasColor, blurRadius: 9),
            ],
          ),
          elevation: transparent ? 0 : null,
          backgroundColor: transparent ? Colors.transparent : null,
        ),
      ),
      child: child,
    );
  }
}

class DefaultSliverAppBar extends StatelessWidget {
  const DefaultSliverAppBar({
    super.key,
    this.leading,
    this.actions,
    this.title,
    this.elevation,
    this.flexibleSpace,
    this.expandedHeight,
    this.bottom,
    this.floating = false,
    this.pinned = false,
    this.snap = false,
    this.automaticallyImplyLeading = true,
    this.forceElevated = false,
    this.scrollController,
  });

  final Widget? leading;
  final List<Widget>? actions;
  final Widget? title;
  final double? elevation;
  final bool forceElevated;
  final bool automaticallyImplyLeading;
  final double? expandedHeight;
  final PreferredSizeWidget? bottom;
  final Widget? flexibleSpace;
  final bool floating;
  final bool pinned;
  final bool snap;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    List<Widget>? effectiveActions = actions;
    if (actions != null) {
      effectiveActions = [...actions!, const SizedBox(width: 8)];
    }

    return SliverPadding(
      padding: EdgeInsets.zero,
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          AppBarLeadingConfiguration leadingConfig = getLeadingConfiguration(
            context: context,
            width: constraints.crossAxisExtent,
            automaticallyImplyLeading: automaticallyImplyLeading,
            leading: leading,
          );
          return SliverAppBar(
            title: IgnorePointer(child: title),
            automaticallyImplyLeading: false,
            elevation: elevation,
            forceElevated: forceElevated,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            expandedHeight: expandedHeight,
            leading: leadingConfig.leading,
            leadingWidth: leadingConfig.leadingWidth,
            floating: floating,
            pinned: pinned,
            snap: snap,
            actions: effectiveActions,
            bottom: bottom,
            flexibleSpace: ScrollToTop(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: bottom?.preferredSize.height ?? 0,
                ),
                child: flexibleSpace,
              ),
            ),
          );
        },
      ),
    );
  }
}
