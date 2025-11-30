import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_constants.dart';

/// A reusable video player widget with Chewie controls
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? aspectRatio;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    try {
      await _videoController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        showControls: widget.showControls,
        aspectRatio: widget.aspectRatio ?? _videoController.value.aspectRatio,
        placeholder: widget.thumbnailUrl != null
            ? Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              )
            : _buildPlaceholder(),
        errorBuilder: (context, errorMessage) => _buildErrorWidget(errorMessage),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryBlue,
          handleColor: AppColors.primaryBlue,
          backgroundColor: CupertinoColors.systemGrey4,
          bufferedColor: CupertinoColors.systemGrey3,
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryBlue,
          handleColor: AppColors.primaryBlue,
          backgroundColor: CupertinoColors.systemGrey4,
          bufferedColor: CupertinoColors.systemGrey3,
        ),
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load video: ${e.toString()}';
          _isInitializing = false;
        });
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: CupertinoColors.black,
      child: const Center(
        child: Icon(
          CupertinoIcons.play_circle_fill,
          size: 64,
          color: CupertinoColors.white,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      color: CupertinoColors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Video Error',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Container(
        color: CupertinoColors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CupertinoActivityIndicator(
                color: CupertinoColors.white,
                radius: 16,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorWidget(_error!);
    }

    if (_chewieController == null) {
      return _buildErrorWidget('Failed to initialize video player');
    }

    return Chewie(controller: _chewieController!);
  }
}

/// Fullscreen video viewer
class FullScreenVideoViewer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const FullScreenVideoViewer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<FullScreenVideoViewer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    try {
      await _videoController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: true,
        showControls: true,
        fullScreenByDefault: false,
        allowFullScreen: true,
        aspectRatio: _videoController.value.aspectRatio,
        placeholder: widget.thumbnailUrl != null
            ? Image.network(
                widget.thumbnailUrl!,
                fit: BoxFit.cover,
              )
            : null,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryBlue,
          handleColor: AppColors.primaryBlue,
          backgroundColor: CupertinoColors.systemGrey4,
          bufferedColor: CupertinoColors.systemGrey3,
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryBlue,
          handleColor: AppColors.primaryBlue,
          backgroundColor: CupertinoColors.systemGrey4,
          bufferedColor: CupertinoColors.systemGrey3,
        ),
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load video: ${e.toString()}';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withOpacity(0.5),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.xmark,
            color: CupertinoColors.white,
          ),
        ),
        middle: const Text(
          'Video',
          style: TextStyle(color: CupertinoColors.white),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitializing) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(
            color: CupertinoColors.white,
            radius: 20,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading video...',
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: CupertinoColors.systemRed,
          ),
          const SizedBox(height: 16),
          Text(
            'Video Error',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            color: AppColors.primaryBlue,
            onPressed: () {
              setState(() {
                _error = null;
                _isInitializing = true;
              });
              _initializePlayer();
            },
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (_chewieController == null) {
      return const Text(
        'Failed to initialize video player',
        style: TextStyle(color: CupertinoColors.white),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}
