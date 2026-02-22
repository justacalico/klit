import 'dart:convert';

import '../models/models.dart';

/// Top-level function for use with compute(). Parses accounts JSON string.
List<Account> parseAccountsJson(String body) {
  final List<dynamic> accountsList = json.decode(body);
  return accountsList
      .map((e) => Account.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Top-level function for use with compute(). Parses feeds JSON string.
List<Feed> parseFeedsJson(String body) {
  try {
    final List<dynamic> list = json.decode(body);
    return list
        .whereType<Map<String, dynamic>>()
        .map(Feed.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
}

/// Top-level function for use with compute(). Parses search history JSON and sorts by timestamp desc.
List<SearchHistoryItem> parseSearchHistoryJson(String body) {
  final List<dynamic> historyList = json.decode(body);
  final result = historyList
      .map((e) => SearchHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList();
  result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return result;
}
