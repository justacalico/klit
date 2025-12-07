/// API constants for e926 and compatible sites
class ApiConstants {
  ApiConstants._();

  /// Default e926 API endpoint
  static const String defaultHost = 'https://e926.net';

  /// NSFW alternative
  static const String nsfwHost = 'https://e621.net';

  /// API endpoints
  static const String postsEndpoint = '/posts.json';
  static const String tagsEndpoint = '/tags.json';
  static const String userEndpoint = '/users';
  static const String favoritesEndpoint = '/favorites.json';
  static const String popularEndpoint = '/popular.json';

  /// Default page size for pagination
  static const int defaultPageSize = 50;

  /// Maximum posts per request
  static const int maxPageSize = 320;

  /// Rate limiting - requests per second
  static const double requestsPerSecond = 2.0;

  /// User agent header (required by e926 API TOS)
  /// Must include app name, version, and a way to contact the developer
  /// Format: AppName/Version (contact info)
  static const String userAgent = 'Klit/2.0.0 (by Openlyst on GitLab; gitlab.com/Openlyst/klit)';

  /// API headers
  static Map<String, String> get defaultHeaders => {
        'User-Agent': userAgent,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  /// Popular time ranges
  static const List<String> popularTimeRanges = ['day', 'week', 'month'];

  /// Rating filters
  static const List<String> ratings = ['s', 'q', 'e'];
  static const Map<String, String> ratingLabels = {
    's': 'Safe',
    'q': 'Questionable',
    'e': 'Explicit',
  };
}
