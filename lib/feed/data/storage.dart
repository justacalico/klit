import 'dart:convert';

import 'package:kilt/feed/data/feed.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _feedsKey = 'feeds';

Future<List<Feed>> getFeeds() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(_feedsKey);
  if (json == null || json.isEmpty) return [];
  try {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => e is Map<String, dynamic> ? Feed.fromJson(e) : null)
        .whereType<Feed>()
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> setFeeds(List<Feed> feeds) async {
  final prefs = await SharedPreferences.getInstance();
  final list = feeds.map((e) => e.toJson()).toList();
  await prefs.setString(_feedsKey, jsonEncode(list));
}
