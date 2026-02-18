import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';
import '../../providers/providers.dart';
import '../../services/video_recommendation_service.dart';
import '../widgets/video_player_widget.dart';
import 'post_detail_page.dart';

/// TikTok-style video feed page with personalized recommendations
class VideoFeedPage extends StatefulWidget {
  final Function(PostDetailArguments) onPostTap;

  const VideoFeedPage({super.key, required this.onPostTap});

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> {
  final PageController _pageController = PageController();
  VideoRecommendationService? _recommendationService;
  
  List<Post> _videos = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isTraining = false;
  String? _error;
  UserInterestProfile? _profile;
  bool _hasMore = true;
  int _currentPage = 1;
  final Map<int, bool> _hasWatched = {};
  final Map<int, double> _watchProgress = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    final account = auth.currentAccount;
    if (account == null) return;

    final apiService = context.read<ApiService>();
    _recommendationService = VideoRecommendationService(apiService: apiService);

    // Try cached profile first
    final cached = _recommendationService!.getCachedProfile();
    if (cached != null) {
      setState(() => _profile = cached);
      return;
    }

    // Train if no cached profile
    await _trainModel();
  }

  Future<void> _trainModel() async {
    final auth = context.read<AuthProvider>();
    final account = auth.currentAccount;
    if (account == null) {
      setState(() => _error = 'Not logged in');
      return;
    }

    if (_recommendationService == null) {
      final apiService = context.read<ApiService>();
      _recommendationService = VideoRecommendationService(apiService: apiService);
    }

    setState(() {
      _isTraining = true;
      _error = null;
    });

    try {
      final profile = await _recommendationService!.trainModel(username: account.username);
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _isTraining = false;
        });
        // Reload videos with new profile
        _loadVideos(refresh: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTraining = false;
          _error = 'Training failed: $e';
        });
      }
    }
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final settings = context.read<SettingsProvider>();
      
      // Generate search query from profile if available
      String searchQuery = 'type:video';
      if (_profile != null && _recommendationService != null) {
        final query = _recommendationService!.generateSearchQuery(_profile!);
        if (query.isNotEmpty) {
          searchQuery = '$query type:video';
        }
      }

      final result = await apiService.getPosts(
        page: refresh ? 1 : _currentPage,
        limit: 50,
        tags: searchQuery,
        safeMode: settings.safeMode,
      );

      List<Post> newVideos = [];
      result.when(
        success: (posts) {
          newVideos = posts.where((p) => p.isVideo && p.file.url != null).toList();
        },
        failure: (error) {
          throw Exception(error.message);
        },
      );
      
      if (mounted) {
        // Rank videos if profile exists
        if (_profile != null && newVideos.isNotEmpty && _recommendationService != null) {
          final ranked = _recommendationService!.rankVideos(newVideos, _profile!);
          setState(() {
            if (refresh) {
              _videos = ranked;
              _currentPage = 1;
            } else {
              _videos.addAll(ranked);
            }
            _hasMore = newVideos.length >= 50;
            _currentPage++;
            _isLoading = false;
          });
        } else {
          setState(() {
            if (refresh) {
              _videos = newVideos;
              _currentPage = 1;
            } else {
              _videos.addAll(newVideos);
            }
            _hasMore = newVideos.length >= 50;
            _currentPage++;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    
    // Mark as watched
    if (index < _videos.length) {
      _hasWatched[_currentIndex] = true;
    }
    
    // Load more if near end
    if (index >= _videos.length - 5 && _hasMore && !_isLoading) {
      _loadVideos();
    }
  }

  void _onVideoProgress(int index, double progress) {
    setState(() {
      _watchProgress[index] = progress;
      // Mark as watched if >80% complete
      if (progress > 0.8) {
        _hasWatched[index] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('video-feed-page'),
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              // Video feed
              if (_videos.isEmpty && _isLoading)
                const Center(child: CupertinoActivityIndicator(color: CupertinoColors.white))
              else if (_error != null && _videos.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: CupertinoColors.white),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: CupertinoColors.white)),
                      const SizedBox(height: 16),
                      CupertinoButton.filled(
                        onPressed: () => _loadVideos(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (_videos.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.play_rectangle, size: 64, color: CupertinoColors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'No videos found',
                        style: TextStyle(color: CupertinoColors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Train the algorithm to get personalized recommendations',
                        style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  itemCount: _videos.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _videos.length) {
                      _loadVideos();
                      return const Center(child: CupertinoActivityIndicator(color: CupertinoColors.white));
                    }
                    
                    final post = _videos[index];
                    return _VideoFeedItem(
                      post: post,
                      isActive: index == _currentIndex,
                      onProgress: (progress) => _onVideoProgress(index, progress),
                      onPostTap: () => widget.onPostTap(
                        PostDetailArguments(
                          postIds: _videos.map((p) => p.id).toList(),
                          initialIndex: index,
                          hasMore: _hasMore,
                          onLoadMore: () async {
                            await _loadVideos();
                            return _videos.map((p) => p.id).toList();
                          },
                        ),
                      ),
                    );
                  },
                ),
              
              // Top bar with train button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        CupertinoColors.black.withValues(alpha: 0.8),
                        CupertinoColors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Icon(CupertinoIcons.back, color: CupertinoColors.white),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: _isTraining 
                            ? CupertinoColors.systemGrey
                            : (_profile != null 
                                ? CupertinoColors.systemGreen 
                                : CupertinoColors.systemBlue),
                        borderRadius: BorderRadius.circular(20),
                        onPressed: _isTraining ? null : _trainModel,
                        child: _isTraining
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CupertinoActivityIndicator(color: CupertinoColors.white),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _profile != null 
                                        ? CupertinoIcons.checkmark_circle_fill 
                                        : CupertinoIcons.sparkles,
                                    size: 16,
                                    color: CupertinoColors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _profile != null ? 'Retrain' : 'Train',
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom info overlay
              if (_videos.isNotEmpty && _currentIndex < _videos.length)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          CupertinoColors.black.withValues(alpha: 0.8),
                          CupertinoColors.black.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Post #${_videos[_currentIndex].id}',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentIndex + 1}/${_videos.length}',
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual video item in the feed
class _VideoFeedItem extends StatefulWidget {
  final Post post;
  final bool isActive;
  final void Function(double) onProgress;
  final VoidCallback onPostTap;

  const _VideoFeedItem({
    required this.post,
    required this.isActive,
    required this.onProgress,
    required this.onPostTap,
  });

  @override
  State<_VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<_VideoFeedItem> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return GestureDetector(
      onTap: widget.onPostTap,
      child: Container(
        color: CupertinoColors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            if (widget.post.file.url != null)
              VideoPlayerWidget(
                key: ValueKey('video_${widget.post.id}'),
                videoUrl: widget.post.file.url!,
                thumbnailUrl: widget.post.preview.url,
                autoPlay: widget.isActive && settings.videoAutoPlay,
                looping: true,
                showControls: false,
                aspectRatio: widget.post.file.aspectRatio,
                muteByDefault: settings.videoMuteByDefault,
              ),
          ],
        ),
      ),
    );
  }
}
