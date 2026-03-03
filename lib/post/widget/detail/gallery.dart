import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';

class PostDetailGallery extends StatelessWidget {
  const PostDetailGallery({
    super.key,
    required this.controller,
    this.initialPage,
    this.pageController,
    this.onPageChanged,
  }) : assert(
         initialPage == null || pageController == null,
         'Cannot pass both initialPage and pageController',
       );

  final PostController controller;
  final int? initialPage;
  final PageController? pageController;
  final ValueChanged<int>? onPageChanged;

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
              builder: (context, _) => PagedPageView(
                pageController: pageController,
                state: controller.state,
                fetchNextPage: controller.getNextPage,
                builderDelegate: defaultPagedChildBuilderDelegate<Post>(
                  onRetry: controller.getNextPage,
                  pageBuilder: (context, child) => Scaffold(
                    appBar: const TransparentAppBar(child: DefaultAppBar()),
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
                onPageChanged: (index) {
                  onPageChanged?.call(index);
                  preloadPostImages(
                    context: context,
                    index: index,
                    posts: controller.items!,
                    size: PostImageSize.sample,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
