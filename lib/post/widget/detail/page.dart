import 'dart:io';
import 'dart:math';

import 'package:kilt/client/client.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostDetail extends StatefulWidget {
  const PostDetail({
    super.key,
    required this.post,
    this.onTapImage,
    this.useShell = false,
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final physicalKey = event.physicalKey;
    final logicalKey = event.logicalKey;

    if (physicalKey == PhysicalKeyboardKey.arrowLeft) {
      _goToAdjacentPost(-1);
      return KeyEventResult.handled;
    }
    if (physicalKey == PhysicalKeyboardKey.arrowRight) {
      _goToAdjacentPost(1);
      return KeyEventResult.handled;
    }

    final hasLogin = context.read<Client>().hasLogin;
    if (!hasLogin) return KeyEventResult.ignored;

    if (physicalKey == PhysicalKeyboardKey.arrowUp) {
      _vote(upvote: true);
      return KeyEventResult.handled;
    }
    if (physicalKey == PhysicalKeyboardKey.arrowDown) {
      _vote(upvote: false);
      return KeyEventResult.handled;
    }
    if (logicalKey == LogicalKeyboardKey.keyF) {
      _toggleFavorite();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _goToAdjacentPost(int delta) {
    final controller = context.read<PostController>();
    final items = controller.items;
    if (items == null) return;
    final pageController = PostDetailPageControllerProvider.of(context);
    if (pageController == null || !pageController.hasClients) return;
    final page = pageController.page?.round() ?? 0;
    final target = page + delta;
    if (target < 0 || target >= items.length) return;
    pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _vote({required bool upvote}) {
    final controller = context.read<PostController>();
    final voteStatus = widget.post.vote.status;
    final isLiked = upvote
        ? voteStatus == VoteStatus.upvoted
        : voteStatus == VoteStatus.downvoted;
    HapticFeedback.selectionClick();
    controller.vote(
      post: widget.post,
      upvote: upvote,
      replace: !isLiked,
    );
  }

  void _toggleFavorite() {
    HapticFeedback.selectionClick();
    final controller = context.read<PostController>();
    if (widget.post.isFavorited) {
      controller.unfav(widget.post);
    } else {
      final upvoteFavs = context.read<Settings>().upvoteFavs.value;
      controller.fav(widget.post).then((success) {
        if (success && upvoteFavs) {
          controller.vote(
            post: controller.postById(widget.post.id)!,
            upvote: true,
            replace: true,
          );
        }
      });
    }
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
          onKeyEvent: _handleKeyEvent,
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

    final paddedImage = post.type == PostType.video
        ? Padding(padding: const EdgeInsets.only(bottom: 10), child: image)
        : Padding(
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

    final pageController = PostDetailPageControllerProvider.of(context);
    if (pageController == null || ![Platform.isWindows, Platform.isMacOS, Platform.isLinux].any((e) => e)) {
      return paddedImage;
    }

    return Stack(
      children: [
        paddedImage,
        Positioned(
          left: 0,
          top: 0,
          bottom: 10,
          child: GalleryPageButton(
            controller: pageController,
            direction: GalleryButtonDirection.left,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 10,
          child: GalleryPageButton(
            controller: pageController,
            direction: GalleryButtonDirection.right,
          ),
        ),
      ],
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hasBottomNav = screenWidth < mobileBreakpoint;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          if (!hasBottomNav) {
            return CustomScrollView(
              primary: true,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _image(context, constraints),
                      _upperBody(context),
                      _middleBody(context),
                      _lowerBody(context),
                    ],
                  ),
                ),
              ],
            );
          }
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
                  hasLogin && floatingMobile;
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
