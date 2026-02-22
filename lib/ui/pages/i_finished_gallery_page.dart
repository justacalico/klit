import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../data/services/services.dart';

/// One image source for the gallery: either a local file (camera photo) or a post ID (show post image).
class _ImageSource {
  const _ImageSource({this.filePath, this.postId})
      : assert(filePath != null || postId != null);

  final String? filePath;
  final int? postId;
}

/// Full-screen swipeable gallery of "I finished" images: camera photo if present, else post image.
class IFinishedGalleryPage extends StatefulWidget {
  const IFinishedGalleryPage({super.key, required this.entries});

  final List<IFinishedEntry> entries;

  @override
  State<IFinishedGalleryPage> createState() => _IFinishedGalleryPageState();
}

class _IFinishedGalleryPageState extends State<IFinishedGalleryPage> {
  late List<_ImageSource> _sources;
  final Map<int, String?> _postImageUrls = {};
  final Set<int> _loadingPostIds = {};

  @override
  void initState() {
    super.initState();
    _sources = widget.entries.map((e) {
      final hasValidFile = !kIsWeb &&
          e.imagePath != null &&
          e.imagePath!.isNotEmpty &&
          File(e.imagePath!).existsSync();
      if (hasValidFile) {
        return _ImageSource(filePath: e.imagePath);
      }
      return _ImageSource(postId: e.postId);
    }).toList();
    _loadPostUrls();
  }

  Future<void> _loadPostUrls() async {
    final api = context.read<ApiService>();
    final toLoad = _sources
        .where((s) => s.postId != null && !_postImageUrls.containsKey(s.postId))
        .map((s) => s.postId!)
        .toSet();
    if (toLoad.isEmpty) {
      if (mounted) setState(() {});
      return;
    }
    if (mounted) setState(() => _loadingPostIds.addAll(toLoad));
    for (final id in toLoad) {
      final result = await api.getPostById(id);
      if (!mounted) return;
      result.when(
        success: (post) {
          _postImageUrls[id] = post.displayUrl;
        },
        failure: (_) {
          _postImageUrls[id] = null;
        },
      );
      if (mounted) {
        setState(() => _loadingPostIds.remove(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sources.isEmpty) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Gallery'),
        ),
        child: const Center(child: Text('No finished posts')),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Gallery'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: PageView.builder(
          itemCount: _sources.length,
          itemBuilder: (context, index) {
            final src = _sources[index];
            if (src.filePath != null) {
              return _buildFileImage(src.filePath!);
            }
            final postId = src.postId!;
            final url = _postImageUrls[postId];
            if (url != null && url.isNotEmpty) {
              return _buildNetworkImage(url);
            }
            return const Center(child: CupertinoActivityIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildFileImage(String path) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.photo, size: 64),
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String url) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const CupertinoActivityIndicator(),
          errorWidget: (_, __, ___) => const Icon(CupertinoIcons.photo, size: 64),
        ),
      ),
    );
  }
}
