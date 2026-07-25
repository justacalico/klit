import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';

class PostFullscreenGallery extends StatefulWidget {
  const PostFullscreenGallery({
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
  State<PostFullscreenGallery> createState() => _PostFullscreenGalleryState();
}

class _PostFullscreenGalleryState extends State<PostFullscreenGallery> {
  int _previousPage = 0;

  @override
  void initState() {
    super.initState();
    _previousPage = widget.initialPage ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return SubDefault<PageController>(
      value: widget.pageController,
      create: () => PageController(initialPage: widget.initialPage ?? 0),
      builder: (context, pageController) => ScaffoldFrame(
        child: ChangeNotifierProvider.value(
          value: widget.controller,
          child: Consumer<PostController>(
            builder: (context, controller, child) => GalleryButtons(
              controller: pageController,
              child: PageView.builder(
                itemCount: controller.items?.length ?? 0,
                controller: pageController,
                itemBuilder: (context, index) =>
                    PostFullscreen(post: controller.items![index]),
                onPageChanged: (index) {
                  if (controller.items != null &&
                      _previousPage >= 0 &&
                      _previousPage < controller.items!.length) {
                    controller.items![_previousPage]
                        .getVideo(context, listen: false)
                        ?.pause();
                  }
                  _previousPage = index;
                  widget.onPageChanged?.call(index);
                  if (controller.items != null) {
                    preloadPostImages(
                      context: context,
                      index: index,
                      posts: controller.items!,
                      size: PostImageSize.file,
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
