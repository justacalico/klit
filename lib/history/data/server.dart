import 'dart:async';
import 'dart:collection';

import 'package:drift/drift.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/traits/traits.dart';
import 'package:flutter/foundation.dart';

class HistoryServer with Disposable {
  HistoryServer({
    required GeneratedDatabase database,
    required this.identity,
    required this.traits,
  }) : repository = HistoryRepository(database: database);

  final HistoryRepository repository;
  final Identity identity;
  final ValueNotifier<Traits> traits;

  Timer? _trimTimer;

  static const int trimAmount = 5000;
  static const Duration trimAge = Duration(days: 30 * 3);
  static const Duration _duplicateAge = Duration(minutes: 3);
  static const int _recentMax = 256;

  final LinkedHashMap<String, DateTime> _recent = LinkedHashMap();

  Future<History> get({
    required int id,
    bool? force,
    CancelToken? cancelToken,
  }) => repository.get(id);

  Future<List<History>> page({
    int? page,
    int? limit,
    QueryMap? query,
    bool? force,
    CancelToken? cancelToken,
  }) {
    final search = HistoryQuery.maybeFrom(query);
    return repository.page(
      identity: identity.id,
      page: page,
      limit: limit,
      day: search?.date,
      link: search?.link?.infixRegex,
      category: search?.categories,
      type: search?.types,
      title: search?.title?.infixRegex,
      subtitle: search?.subtitle?.infixRegex,
    );
  }

  Future<void> removeAll(List<int>? ids) =>
      repository.removeAll(ids, identity: identity.id);

  Future<int> count() => repository.length(identity: identity.id);

  Future<List<DateTime>> days() => repository.days(identity: identity.id);

  Future<void> add(HistoryRequest request) async {
    if (!(traits.value.writeHistory ?? true)) return;
    if (_isRecentDuplicate(request)) return;

    await repository.transaction(() async {
      await repository.add(request, identity.id);
    });

    _scheduleTrim();
  }

  bool _isRecentDuplicate(HistoryRequest request) {
    final now = DateTime.now();
    _recent.removeWhere((_, t) => now.difference(t) > _duplicateAge);

    final key = _duplicateKey(request);
    final last = _recent[key];
    if (last != null && now.difference(last) <= _duplicateAge) return true;

    _recent.remove(key);
    _recent[key] = now;

    while (_recent.length > _recentMax) {
      _recent.remove(_recent.keys.first);
    }
    return false;
  }

  String _duplicateKey(HistoryRequest request) {
    return [
      request.link,
      request.title ?? '',
      request.subtitle ?? '',
      request.category.name,
      request.type.name,
      request.thumbnails.join('\n'),
    ].join('\u0001');
  }

  void _scheduleTrim() {
    if (!(traits.value.trimHistory ?? false)) return;
    if (_trimTimer != null) return;

    _trimTimer?.cancel();
    _trimTimer = Timer(const Duration(minutes: 1), () async {
      _trimTimer = null;
      await _performTrim();
    });
  }

  Future<void> _performTrim() async {
    if (!(traits.value.trimHistory ?? false)) return;

    await repository.trim(
      maxAmount: trimAmount,
      maxAge: trimAge,
      identity: identity.id,
    );
  }

  @override
  void dispose() {
    _trimTimer?.cancel();
    super.dispose();
  }
}
