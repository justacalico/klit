import 'dart:math';
import '../data/models/models.dart';
import '../data/services/services.dart';

/// User interest profile built from e621 profile data
class UserInterestProfile {
  /// Tag weights - meaningful tags only (excludes metadata like order, score, etc.)
  final Map<String, double> tagWeights;
  
  /// Artist preferences
  final Map<String, double> artistWeights;
  
  /// Character preferences
  final Map<String, double> characterWeights;
  
  /// Copyright preferences
  final Map<String, double> copyrightWeights;
  
  /// Species preferences
  final Map<String, double> speciesWeights;
  
  /// General tag preferences
  final Map<String, double> generalWeights;
  
  /// Rating preferences (s, q, e)
  final Map<String, double> ratingWeights;
  
  /// Average score preference
  final double averageScorePreference;
  
  /// Average favorite count preference
  final double averageFavCountPreference;
  
  /// Content style preferences (based on tags like solo, group, etc.)
  final Map<String, double> styleWeights;

  UserInterestProfile({
    required this.tagWeights,
    required this.artistWeights,
    required this.characterWeights,
    required this.copyrightWeights,
    required this.speciesWeights,
    required this.generalWeights,
    required this.ratingWeights,
    required this.averageScorePreference,
    required this.averageFavCountPreference,
    required this.styleWeights,
  });

  /// Calculate similarity score between this profile and a post
  double calculateSimilarity(Post post) {
    double score = 0.0;
    double weightSum = 0.0;

    // Tag matching (meaningful tags only)
    for (final tag in post.tags.all) {
      if (_isMeaningfulTag(tag)) {
        final weight = tagWeights[tag] ?? 0.0;
        score += weight;
        weightSum += 1.0;
      }
    }

    // Artist matching
    for (final artist in post.tags.artist) {
      final weight = artistWeights[artist] ?? 0.0;
      score += weight * 1.5; // Artists are weighted higher
      weightSum += 1.5;
    }

    // Character matching
    for (final character in post.tags.character) {
      final weight = characterWeights[character] ?? 0.0;
      score += weight * 1.3;
      weightSum += 1.3;
    }

    // Copyright matching
    for (final copyright in post.tags.copyright) {
      final weight = copyrightWeights[copyright] ?? 0.0;
      score += weight * 1.2;
      weightSum += 1.2;
    }

    // Species matching
    for (final species in post.tags.species) {
      final weight = speciesWeights[species] ?? 0.0;
      score += weight * 1.1;
      weightSum += 1.1;
    }

    // General tag matching
    for (final general in post.tags.general) {
      if (_isMeaningfulTag(general)) {
        final weight = generalWeights[general] ?? 0.0;
        score += weight;
        weightSum += 1.0;
      }
    }

    // Rating preference
    final ratingWeight = ratingWeights[post.rating] ?? 0.0;
    score += ratingWeight * 0.5;
    weightSum += 0.5;

    // Score preference (normalized)
    final scoreDiff = (post.score.total - averageScorePreference).abs();
    final scoreMatch = 1.0 / (1.0 + scoreDiff / 100.0); // Normalize by 100
    score += scoreMatch * 0.3;
    weightSum += 0.3;

    // Style matching (solo, group, etc.)
    for (final style in styleWeights.keys) {
      if (post.tags.all.contains(style)) {
        score += styleWeights[style]! * 0.8;
        weightSum += 0.8;
      }
    }

    return weightSum > 0 ? score / weightSum : 0.0;
  }

  /// Check if a tag is meaningful (not metadata like order, score, etc.)
  static bool _isMeaningfulTag(String tag) {
    final lowerTag = tag.toLowerCase();
    // Exclude metadata tags
    final metadataPatterns = [
      'order:', 'score:', 'rating:', 'id:', 'date:', 'type:', 'status:',
      'limit:', 'page:', 'sort:', 'width:', 'height:', 'size:', 'ext:',
      'md5:', 'source:', 'pool:', 'parent:', 'child:', 'approver:', 'uploader:',
    ];
    
    for (final pattern in metadataPatterns) {
      if (lowerTag.startsWith(pattern)) return false;
    }
    
    // Exclude common metadata values
    final metadataValues = ['asc', 'desc', 'safe', 'questionable', 'explicit'];
    if (metadataValues.contains(lowerTag)) return false;
    
    return true;
  }
}

/// Service for training and using video recommendations based on e621 profile
class VideoRecommendationService {
  final ApiService _apiService;
  UserInterestProfile? _cachedProfile;
  DateTime? _lastTrainingTime;

  VideoRecommendationService({required ApiService apiService})
      : _apiService = apiService;

  /// Train the recommendation model based on user's e621 profile
  Future<UserInterestProfile> trainModel({
    required String username,
    int maxFavorites = 500,
  }) async {
    // Load favorites to analyze preferences
    final favoritesResult = await _apiService.getFavorites(
      username: username,
      page: 1,
      limit: maxFavorites,
      safeMode: false,
    );

    List<Post> favorites = [];
    favoritesResult.when(
      success: (posts) => favorites = posts,
      failure: (error) => throw Exception('Failed to load favorites for training: ${error.message}'),
    );
    if (favorites.isEmpty) {
      throw Exception('No favorites found to train on');
    }

    // Initialize weight maps
    final tagWeights = <String, double>{};
    final artistWeights = <String, double>{};
    final characterWeights = <String, double>{};
    final copyrightWeights = <String, double>{};
    final speciesWeights = <String, double>{};
    final generalWeights = <String, double>{};
    final ratingWeights = <String, double>{};
    final styleWeights = <String, double>{};
    
    double totalScore = 0.0;
    double totalFavCount = 0.0;
    int videoCount = 0;

    // Analyze each favorite
    for (final post in favorites) {
      // Only analyze videos
      if (!post.isVideo) continue;
      
      videoCount++;
      totalScore += post.score.total.toDouble();
      totalFavCount += post.favCount.toDouble();

      // Weight tags based on how often they appear
      final weight = 1.0 / favorites.length; // Normalize by total favorites

      // Process meaningful tags only
      for (final tag in post.tags.all) {
        if (UserInterestProfile._isMeaningfulTag(tag)) {
          tagWeights[tag] = (tagWeights[tag] ?? 0.0) + weight;
        }
      }

      // Process artists
      for (final artist in post.tags.artist) {
        artistWeights[artist] = (artistWeights[artist] ?? 0.0) + weight;
      }

      // Process characters
      for (final character in post.tags.character) {
        characterWeights[character] = (characterWeights[character] ?? 0.0) + weight;
      }

      // Process copyrights
      for (final copyright in post.tags.copyright) {
        copyrightWeights[copyright] = (copyrightWeights[copyright] ?? 0.0) + weight;
      }

      // Process species
      for (final species in post.tags.species) {
        speciesWeights[species] = (speciesWeights[species] ?? 0.0) + weight;
      }

      // Process general tags
      for (final general in post.tags.general) {
        if (UserInterestProfile._isMeaningfulTag(general)) {
          generalWeights[general] = (generalWeights[general] ?? 0.0) + weight;
        }
      }

      // Process rating
      ratingWeights[post.rating] = (ratingWeights[post.rating] ?? 0.0) + weight;

      // Process style tags (solo, group, etc.)
      final styleTags = ['solo', 'group', 'duo', 'threesome', 'foursome', 'multiple'];
      for (final style in styleTags) {
        if (post.tags.all.contains(style)) {
          styleWeights[style] = (styleWeights[style] ?? 0.0) + weight;
        }
      }
    }

    // Normalize weights (optional - helps with scoring)
    final normalize = (Map<String, double> weights) {
      if (weights.isEmpty) return;
      final maxWeight = weights.values.reduce(max);
      if (maxWeight > 0) {
        for (final key in weights.keys.toList()) {
          weights[key] = weights[key]! / maxWeight;
        }
      }
    };

    normalize(tagWeights);
    normalize(artistWeights);
    normalize(characterWeights);
    normalize(copyrightWeights);
    normalize(speciesWeights);
    normalize(generalWeights);
    normalize(styleWeights);

    final profile = UserInterestProfile(
      tagWeights: tagWeights,
      artistWeights: artistWeights,
      characterWeights: characterWeights,
      copyrightWeights: copyrightWeights,
      speciesWeights: speciesWeights,
      generalWeights: generalWeights,
      ratingWeights: ratingWeights,
      averageScorePreference: videoCount > 0 ? totalScore / videoCount : 0.0,
      averageFavCountPreference: videoCount > 0 ? totalFavCount / videoCount : 0.0,
      styleWeights: styleWeights,
    );

    _cachedProfile = profile;
    _lastTrainingTime = DateTime.now();
    
    return profile;
  }

  /// Get cached profile if available and recent (within 24 hours)
  UserInterestProfile? getCachedProfile() {
    if (_cachedProfile == null) return null;
    if (_lastTrainingTime == null) return null;
    
    final hoursSinceTraining = DateTime.now().difference(_lastTrainingTime!).inHours;
    if (hoursSinceTraining > 24) return null;
    
    return _cachedProfile;
  }

  /// Rank videos by recommendation score
  List<Post> rankVideos(List<Post> videos, UserInterestProfile profile) {
    final scored = videos.map((post) {
      return MapEntry(post, profile.calculateSimilarity(post));
    }).toList();

    // Sort by score descending
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }

  /// Generate search query based on top interests
  String generateSearchQuery(UserInterestProfile profile, {int maxTags = 10}) {
    final tags = <String>[];
    
    // Get top artists
    final topArtists = profile.artistWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in topArtists.take(3)) {
      tags.add(entry.key);
    }
    
    // Get top characters
    final topCharacters = profile.characterWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in topCharacters.take(2)) {
      tags.add(entry.key);
    }
    
    // Get top general tags
    final topGeneral = profile.generalWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in topGeneral.take(5)) {
      tags.add(entry.key);
    }
    
    return tags.join(' ');
  }
}
