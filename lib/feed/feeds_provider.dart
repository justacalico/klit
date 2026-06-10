import 'package:flutter/foundation.dart';

import 'package:kilt/feed/data/feed.dart';
import 'package:kilt/feed/data/storage.dart';

class FeedsProvider extends ChangeNotifier {
  List<Feed> _feeds = [];
  bool _loaded = false;

  List<Feed> get feeds => List.unmodifiable(_feeds);
  bool get loaded => _loaded;

  Future<void> loadFeeds() async {
    if (_loaded) return;
    _feeds = await getFeeds();
    _loaded = true;
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
    final id = feed.id.isEmpty ? 'feed_${DateTime.now().millisecondsSinceEpoch}' : feed.id;
    final f = feed.id.isEmpty ? feed.copyWith(id: id) : feed;
    _feeds = [..._feeds, f];
    await setFeeds(_feeds);
    notifyListeners();
  }

  Future<void> updateFeed(Feed feed) async {
    final i = _feeds.indexWhere((f) => f.id == feed.id);
    if (i < 0) return;
    _feeds = [..._feeds]..[i] = feed;
    await setFeeds(_feeds);
    notifyListeners();
  }

  Future<void> deleteFeed(String id) async {
    _feeds = _feeds.where((f) => f.id != id).toList();
    await setFeeds(_feeds);
    notifyListeners();
  }
}
