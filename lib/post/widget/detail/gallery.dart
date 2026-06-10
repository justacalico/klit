import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';

class PostDetailGalleryWithShell extends StatefulWidget {
  const PostDetailGalleryWithShell({
    super.key,
    required this.controller,
    this.initialPage = 0,
    this.useShell = false,
  });

  final PostController controller;
  final int initialPage;
  final bool useShell;

  @override
  State<PostDetailGalleryWithShell> createState() =>
      _PostDetailGalleryWithShellState();
}

class _PostDetailGalleryWithShellState extends State<PostDetailGalleryWithShell> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialPage);
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialPage;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: Consumer<PostController>(
        builder: (context, controller, _) {
          final items = controller.items;
          final post = items != null &&
                  _currentIndex >= 0 &&
                  _currentIndex < items.length
              ? items[_currentIndex]
              : null;
          final PreferredSizeWidget? appBar = post != null
              ? PostDetailAppBar(post: post)
              : const TransparentAppBar(child: DefaultAppBar());
          final body = PostDetailGallery(
            controller: widget.controller,
            pageController: _pageController,
            contentOnly: true,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              preloadPostImages(
                context: context,
                index: index,
                posts: controller.items!,
                size: PostImageSize.sample,
              );
            },
          );
          if (widget.useShell) {
            return AppShell(
              appBar: appBar,
              floatingActionButton: null,
              body: body,
            );
          }
          return Scaffold(
            appBar: appBar,
            body: body,
          );
        },
      ),
    );
  }
}

class PostDetailGallery extends StatelessWidget {
  const PostDetailGallery({
    super.key,
    required this.controller,
    this.initialPage,
    this.pageController,
    this.onPageChanged,
    this.contentOnly = false,
  }) : assert(
         initialPage == null || pageController == null,
         'Cannot pass both initialPage and pageController',
       );

  final PostController controller;
  final int? initialPage;
  final PageController? pageController;
  final ValueChanged<int>? onPageChanged;
  final bool contentOnly;

  @override
  Widget build(BuildContext context) {
    return SubDefault<PageController>(
      value: pageController,
      create: () => PageController(initialPage: initialPage ?? 0),
      builder: (context, pageController) => ChangeNotifierProvider.value(
        value: controller,
        child: Consumer<PostController>(
          builder: (context, controller, child) => GalleryButtons(
            controller: pageController,
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => _PageChangeNotifier(
                pageController: pageController,
                onPageChanged: (index) {
                  onPageChanged?.call(index);
                  if (controller.items != null) {
                    preloadPostImages(
                      context: context,
                      index: index,
                      posts: controller.items!,
                      size: PostImageSize.sample,
                    );
                  }
                },
                child: PagedPageView(
                  pageController: pageController,
                  state: controller.state,
                  fetchNextPage: controller.getNextPage,
                  builderDelegate: defaultPagedChildBuilderDelegate<Post>(
                    onRetry: controller.getNextPage,
                    pageBuilder: contentOnly
                        ? (context, child) => child
                        : (context, child) => Scaffold(
                            appBar: const TransparentAppBar(
                                child: DefaultAppBar()),
                            body: child,
                          ),
                    onEmpty: const Text('No posts'),
                    onError: const Text('Failed to load posts'),
                    itemBuilder: (context, item, index) => SubScrollController(
                      builder: (context, scrollController) =>
                          PrimaryScrollController(
                        controller: scrollController,
                        child: PostDetailPageControllerProvider(
                          controller: pageController,
                          child: PostDetail(
                            post: item,
                            useShell: !contentOnly,
                            onTapImage: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PostsRouteConnector(
                                  controller: controller,
                                  child: PostFullscreenGallery(
                                    controller: controller,
                                    initialPage: index,
                                    onPageChanged: pageController.jumpToPage,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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

class _PageChangeNotifier extends StatefulWidget {
  const _PageChangeNotifier({
    required this.pageController,
    required this.onPageChanged,
    required this.child,
  });

  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final Widget child;

  @override
  State<_PageChangeNotifier> createState() => _PageChangeNotifierState();
}

class _PageChangeNotifierState extends State<_PageChangeNotifier> {
  int _lastReportedPage = 0;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_onPageChanged);
  }

  @override
  void didUpdateWidget(_PageChangeNotifier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageController != widget.pageController) {
      oldWidget.pageController.removeListener(_onPageChanged);
      widget.pageController.addListener(_onPageChanged);
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageChanged);
    super.dispose();
  }

  void _onPageChanged() {
    final page = widget.pageController.page?.round() ?? 0;
    if (page != _lastReportedPage) {
      _lastReportedPage = page;
      widget.onPageChanged(page);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
