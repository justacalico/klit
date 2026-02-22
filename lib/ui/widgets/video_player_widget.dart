import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart' as vp;
import '../../core/constants/constants.dart';

/// Check if we're on a desktop platform
bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

/// A reusable video player widget with cross-platform support
/// Uses media_kit for desktop (Linux, Windows, macOS) and chewie for mobile
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? aspectRatio;
  final bool muteByDefault;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio,
    this.muteByDefault = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  // Mobile player (chewie)
  vp.VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // Desktop player (media_kit)
  Player? _player;
  VideoController? _desktopController;

  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the video URL changed, reinitialize the player
    if (oldWidget.videoUrl != widget.videoUrl) {
      _reinitializePlayer();
    }
  }

  Future<void> _reinitializePlayer() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    // Dispose existing players
    await _disposeCurrentPlayers();

    // Initialize with new video
    await _initializePlayer();
  }

  Future<void> _disposeCurrentPlayers() async {
    // Dispose mobile player
    _chewieController?.dispose();
    _chewieController = null;
    await _videoController?.dispose();
    _videoController = null;

    // Dispose desktop player
    await _player?.dispose();
    _player = null;
    _desktopController = null;
  }

  Future<void> _initializePlayer() async {
    try {
      if (isDesktop) {
        await _initializeDesktopPlayer();
      } else {
        await _initializeMobilePlayer();
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

  Future<void> _initializeDesktopPlayer() async {
    _player = Player();
    _desktopController = VideoController(_player!);

    // Set up looping
    if (widget.looping) {
      _player!.setPlaylistMode(PlaylistMode.single);
    }

    // Set volume based on mute setting
    if (widget.muteByDefault) {
      await _player!.setVolume(0);
    }

    // Open the video
    await _player!.open(Media(widget.videoUrl), play: widget.autoPlay);

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _initializeMobilePlayer() async {
    _videoController = vp.VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    await _videoController!.initialize();

    // Set volume based on mute setting
    if (widget.muteByDefault) {
      await _videoController!.setVolume(0);
    }

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: widget.autoPlay,
      looping: widget.looping,
      showControls: widget.showControls,
      aspectRatio: widget.aspectRatio ?? _videoController!.value.aspectRatio,
      placeholder: widget.thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: widget.thumbnailUrl!,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => _buildPlaceholder(),
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
            const Text(
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
                style: const TextStyle(
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
    // Dispose all players synchronously (fire and forget the async parts)
    _chewieController?.dispose();
    _videoController?.dispose();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Container(
        color: CupertinoColors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(
                color: CupertinoColors.white,
                radius: 16,
              ),
              SizedBox(height: 16),
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

    if (isDesktop) {
      return _buildDesktopPlayer();
    } else {
      return _buildMobilePlayer();
    }
  }

  Widget _buildDesktopPlayer() {
    if (_desktopController == null) {
      return _buildErrorWidget('Failed to initialize video player');
    }

    return Video(
      controller: _desktopController!,
      controls: widget.showControls ? AdaptiveVideoControls : NoVideoControls,
    );
  }

  Widget _buildMobilePlayer() {
    if (_chewieController == null) {
      return _buildErrorWidget('Failed to initialize video player');
    }

    return RepaintBoundary(child: Chewie(controller: _chewieController!));
  }
}

/// Fullscreen video viewer with cross-platform support
class FullScreenVideoViewer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool muteByDefault;

  const FullScreenVideoViewer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.muteByDefault = true,
  });

  @override
  State<FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<FullScreenVideoViewer> {
  // Mobile player (chewie)
  vp.VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // Desktop player (media_kit)
  Player? _player;
  VideoController? _desktopController;

  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (isDesktop) {
        await _initializeDesktopPlayer();
      } else {
        await _initializeMobilePlayer();
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

  Future<void> _initializeDesktopPlayer() async {
    _player = Player();
    _desktopController = VideoController(_player!);

    // Loop videos by default in fullscreen
    _player!.setPlaylistMode(PlaylistMode.single);

    // Set volume based on mute setting
    if (widget.muteByDefault) {
      await _player!.setVolume(0);
    }

    // Open the video and autoplay
    await _player!.open(Media(widget.videoUrl), play: true);

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _initializeMobilePlayer() async {
    _videoController = vp.VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    await _videoController!.initialize();

    // Set volume based on mute setting
    if (widget.muteByDefault) {
      await _videoController!.setVolume(0);
    }

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: true,
      showControls: true,
      fullScreenByDefault: false,
      allowFullScreen: true,
      aspectRatio: _videoController!.value.aspectRatio,
      placeholder: widget.thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: widget.thumbnailUrl!,
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
  }

  @override
  void dispose() {
    // Dispose mobile player
    _chewieController?.dispose();
    _videoController?.dispose();

    // Dispose desktop player
    _player?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.5),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.white),
        ),
        middle: const Text(
          'Video',
          style: TextStyle(color: CupertinoColors.white),
        ),
      ),
      child: SafeArea(child: Center(child: _buildContent())),
    );
  }

  Widget _buildContent() {
    if (_isInitializing) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(color: CupertinoColors.white, radius: 20),
          SizedBox(height: 16),
          Text(
            'Loading video...',
            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 16),
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
          const Text(
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
              style: const TextStyle(
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

    if (isDesktop) {
      return _buildDesktopPlayer();
    } else {
      return _buildMobilePlayer();
    }
  }

  Widget _buildDesktopPlayer() {
    if (_desktopController == null) {
      return const Text(
        'Failed to initialize video player',
        style: TextStyle(color: CupertinoColors.white),
      );
    }

    return Video(
      controller: _desktopController!,
      controls: AdaptiveVideoControls,
    );
  }

  Widget _buildMobilePlayer() {
    if (_chewieController == null) {
      return const Text(
        'Failed to initialize video player',
        style: TextStyle(color: CupertinoColors.white),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}
