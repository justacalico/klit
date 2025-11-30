/// API constants for e621 and compatible sites
class ApiConstants {
  ApiConstants._();

  /// Default e621 API endpoint
  static const String defaultHost = 'https://e621.net';

  /// Safe for work alternative
  static const String sfwHost = 'https://e926.net';

  /// API endpoints
  static const String postsEndpoint = '/posts.json';
  static const String tagsEndpoint = '/tags.json';
  static const String userEndpoint = '/users';
  static const String favoritesEndpoint = '/favorites.json';

  /// Default page size for pagination
  static const int defaultPageSize = 50;

  /// Maximum posts per request
  static const int maxPageSize = 320;

  /// Rate limiting - requests per second
  static const double requestsPerSecond = 2.0;

  /// User agent header (required by e621 API TOS)
  static const String userAgent = 'Klit/1.0.0 (Flutter App)';

  /// API headers
  static Map<String, String> get defaultHeaders => {
        'User-Agent': userAgent,
        'Accept': 'application/json',
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
