import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';

class FeedsProvider extends ChangeNotifier {
  FeedsProvider({required StorageService storageService})
      : _storageService = storageService;

  final StorageService _storageService;
  final _uuid = const Uuid();
  List<Feed> _feeds = [];

  List<Feed> get feeds => List.unmodifiable(_feeds);

  /// Load feeds from global storage (same list for all accounts). Call on startup only.
  Future<void> loadFeeds() async {
    _feeds = await _storageService.getFeedsGlobal();
    notifyListeners();
  }

  /// Reload feeds from global storage (e.g. after adding/editing). Not called on account change.
  Future<void> reloadFeeds() async {
    _feeds = await _storageService.getFeedsGlobal();
    notifyListeners();
  }

  Feed? getById(String id) {
    try {
      return _feeds.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addFeed(Feed feed) async {
    final id = feed.id.isEmpty ? _uuid.v4() : feed.id;
    final f = feed.id.isEmpty ? feed.copyWith(id: id) : feed;
    _feeds = [..._feeds, f];
    await _storageService.setFeedsGlobal(_feeds);
    notifyListeners();
  }

  Future<void> updateFeed(Feed feed) async {
    final i = _feeds.indexWhere((f) => f.id == feed.id);
    if (i < 0) return;
    _feeds = [..._feeds]..[i] = feed;
    await _storageService.setFeedsGlobal(_feeds);
    notifyListeners();
  }

  Future<void> deleteFeed(String id) async {
    _feeds = _feeds.where((f) => f.id != id).toList();
    await _storageService.setFeedsGlobal(_feeds);
    notifyListeners();
  }
}
