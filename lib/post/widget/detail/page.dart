import 'dart:math';

import 'package:klit/client/client.dart';
import 'package:klit/post/post.dart';
import 'package:klit/settings/settings.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';

class PostDetail extends StatefulWidget {
  const PostDetail({
    super.key,
    required this.post,
    this.onTapImage,
    this.useShell = true,
  });

  final Post post;
  final VoidCallback? onTapImage;
  final bool useShell;

  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    return _PostDetailBody(post: widget.post, onTapImage: widget.onTapImage);
  }

  @override
  Widget build(BuildContext context) {
    final content = PostVideoRoute(
      post: widget.post,
      child: PostHistoryConnector(
        post: widget.post,
        child: Focus(
          focusNode: _focusNode,
          canRequestFocus: true,
          child: widget.useShell
              ? AppShell(
                  appBar: PostDetailAppBar(post: widget.post),
                  floatingActionButton: null,
                  body: _buildContent(),
                )
              : _buildContent(),
        ),
      ),
    );
    return content;
  }
}

class _PostDetailBody extends StatelessWidget {
  const _PostDetailBody({required this.post, this.onTapImage});

  final Post post;
  final VoidCallback? onTapImage;

  Widget _image(BuildContext context, BoxConstraints constraints) {
    final image = AnimatedSize(
      duration: defaultAnimationDuration,
      child: PostDetailImageDisplay(
        post: post,
        onTap: () {
          PostVideoRoute.of(context).keepPlaying();
          if (onTapImage != null) {
            onTapImage!();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PostFullscreen(post: post),
              ),
            );
          }
        },
      ),
    );

    if (post.type == PostType.video) {
      return Padding(padding: const EdgeInsets.only(bottom: 10), child: image);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (constraints.maxHeight / 2),
          maxHeight: constraints.maxWidth > constraints.maxHeight
              ? max(400, constraints.maxHeight * 0.8)
              : double.infinity,
        ),
        child: image,
      ),
    );
  }

  Widget _upperBody(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArtistDisplay(post: post),
        DeletionDisplay(post: post),
        LikeDisplay(post: post),
        DescriptionDisplay(post: post),
      ],
    ),
  );

  Widget _middleBody(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(children: [CommentDisplay(post: post)]),
  );

  Widget _lowerBody(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        RelationshipDisplay(post: post),
        PoolDisplay(post: post),
        DenylistTagDisplay(post: post),
        TagDisplay(post: post),
        FileDisplay(post: post),
        SourceDisplay(post: post),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final settings = context.read<Settings>();
    final hasLogin = context.watch<Client>().hasLogin;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          final hasBottomNav = constraints.maxWidth < mobileBreakpoint;
          final viewPadding = MediaQuery.viewPaddingOf(context);
          final navBottomOffset = viewPadding.bottom > 0
              ? viewPadding.bottom + 8
              : 12.0;
          const floatingBarHeight = 58.0;
          final floatingBarBottom =
              kBottomNavigationBarHeight + navBottomOffset + 12;

          return ValueListenableBuilder<bool>(
            valueListenable: settings.postActionBarFloatingMobile,
            builder: (context, floatingMobile, _) {
              final showFloatingActions =
                  hasBottomNav && hasLogin && floatingMobile;
              final contentBottomPadding = showFloatingActions
                  ? floatingBarBottom + floatingBarHeight + 20
                  : kBottomNavigationBarHeight + 24;

              return Stack(
                children: [
                  ListView(
                    primary: true,
                    padding: EdgeInsets.only(bottom: contentBottomPadding),
                    children: [
                      _image(context, constraints),
                      _upperBody(context),
                      _middleBody(context),
                      _lowerBody(context),
                    ],
                  ),
                  if (showFloatingActions)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: floatingBarBottom,
                      child: PostDetailPinnedActions(
                        post: post,
                        floating: true,
                      ),
                    ),
                ],
              );
            },
          );
        } else {
          double sideBarWidth;
          if (constraints.maxWidth > 1400) {
            sideBarWidth = 404;
          } else {
            sideBarWidth = 304;
          }
          return CustomScrollView(
            primary: true,
            slivers: [
              SliverCrossAxisGroup(
                slivers: [
                  SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            _image(context, constraints),
                            _upperBody(context),
                          ],
                        ),
                      ),
                      SliverPostCommentSection(post: post),
                    ],
                  ),
                  SliverConstrainedCrossAxis(
                    maxExtent: sideBarWidth,
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 56),
                          _lowerBody(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }
}

class PostDetailPageControllerProvider extends InheritedWidget {
  const PostDetailPageControllerProvider({super.key, 
    required this.controller,
    required super.child,
  });

  final PageController controller;

  static PageController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PostDetailPageControllerProvider>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(PostDetailPageControllerProvider oldWidget) =>
      identical(controller, oldWidget.controller);
}
