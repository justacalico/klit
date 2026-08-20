// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:kilt/traits/traits.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

PreferredSizeWidget _emptyAppBar() => const PreferredSize(
    preferredSize: Size.zero,
    child: SizedBox.shrink());

class PostsPage extends StatefulWidget {
  const PostsPage({
    super.key,
    required this.controller,
    this.appBar,
    this.bodyTop,
    this.displayType,
    this.drawerActions,
    this.canSelect = true,
  });

  final PostController controller;
  final PreferredSizeWidget? appBar;
  final Widget? bodyTop;
  final PostDisplayType? displayType;
  final List<Widget>? drawerActions;
  final bool canSelect;

  @override
  State<StatefulWidget> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget? endDrawer() {
      return ContextDrawer(
        title: Text(l10n.postPosts),
        children: [
          CrossFade.builder(
            showChild: widget.drawerActions?.isNotEmpty ?? false,
            builder: (context) =>
                Column(children: [...widget.drawerActions!, const Divider()]),
          ),
          if (widget.controller.filterMode != PostFilterMode.unavailable)
            DrawerDenySwitch(controller: widget.controller),
          DrawerTagCounter(controller: widget.controller),
        ],
      );
    }

    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: Consumer<PostController>(
        builder: (context, controller, child) => SelectionLayout<Post>(
          enabled: widget.canSelect,
          items: controller.items,
          child: AdaptiveScaffold(
            appBar: PostSelectionAppBar(
              controller: widget.controller,
              child: widget.appBar ?? _emptyAppBar(),
            ),
            endDrawer: endDrawer(),
            body: widget.appBar == null
                ? SafeArea(
                    top: true,
                    child: LimitedWidthLayout(
                      child: TileLayout(
                        child: PullToRefresh(
                          onRefresh: () => widget.controller.refresh(
                            force: true,
                            background: true,
                          ),
                          child: CustomScrollView(
                            primary: true,
                            scrollCacheExtent: ScrollCacheExtent.pixels(400),
                            slivers: [
                              SliverPadding(
                                padding: defaultActionListPadding,
                                sliver: PostSliverDisplay(
                                  controller: widget.controller,
                                  displayType:
                                      widget.displayType ?? PostDisplayType.grid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : widget.bodyTop != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          widget.bodyTop!,
                          Expanded(
                            child: LimitedWidthLayout(
                              child: TileLayout(
                                child: PullToRefresh(
                                  onRefresh: () => widget.controller.refresh(
                                    force: true,
                                    background: true,
                                  ),
                                  child: CustomScrollView(
                                    primary: true,
                                    scrollCacheExtent: ScrollCacheExtent.pixels(400),
                                    slivers: [
                                      SliverPadding(
                                        padding: defaultActionListPadding,
                                        sliver: PostSliverDisplay(
                                          controller: widget.controller,
                                          displayType: widget.displayType ??
                                              PostDisplayType.grid,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : LimitedWidthLayout(
                        child: TileLayout(
                          child: PullToRefresh(
                            onRefresh: () =>
                                widget.controller.refresh(force: true, background: true),
                            child: CustomScrollView(
                              primary: true,
                              scrollCacheExtent: ScrollCacheExtent.pixels(400),
                              slivers: [
                                SliverPadding(
                                  padding: defaultActionListPadding,
                                  sliver: PostSliverDisplay(
                                    controller: widget.controller,
                                    displayType:
                                        widget.displayType ?? PostDisplayType.grid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
