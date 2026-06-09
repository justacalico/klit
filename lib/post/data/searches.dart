import 'package:klit/client/client.dart';
import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PopularScale { day, week, month, hot }

class FavoritePostController extends PostController {
  FavoritePostController({required super.client});

  @override
  @protected
  List<Post>? filter(List<Post>? items) {
    List<Post>? result = super.filter(
      items?.where((p) => !p.isFavorited).toList(),
    );
    return items
        ?.where((p) => (result?.contains(p) ?? false) || p.isFavorited)
        .toList();
  }

  @override
  @protected
  Future<List<Post>> fetch(int page, bool force) async {
    return client.posts.favorites(
      page: page,
      query: query,
      orderByAdded: orderFavorites,
      force: force,
      cancelToken: cancelToken,
    );
  }

  @override
  @protected
  Future<PageResponse<int, Post>> withError(
    Future<PageResponse<int, Post>> Function() call,
  ) async {
    try {
      return await super.withError(call);
    } on NoUserLoginException catch (e) {
      return PageResponse.error(error: e);
    }
  }
}

class HotPostController extends PostController {
  HotPostController({
    required super.client,
    PopularScale scale = PopularScale.day,
    DateTime? referenceDate,
  }) : _scale = scale,
       _referenceDate = DateUtils.dateOnly(referenceDate ?? DateTime.now()),
       super(
         query: {
           'tags': _dateTagFor(
             scale: scale,
             referenceDate: DateUtils.dateOnly(referenceDate ?? DateTime.now()),
           ),
         },
       );

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  PopularScale _scale;
  PopularScale get scale => _scale;

  DateTime _referenceDate;
  DateTime get referenceDate => _referenceDate;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  bool get canNext {
    final next = _nextReferenceDate();
    return !next.isAfter(_today);
  }

  void setScale(PopularScale value) {
    if (value == _scale) return;
    _scale = value;
    _applyDateQuery();
  }

  void setReferenceDate(DateTime value) {
    final d = DateUtils.dateOnly(value);
    if (d == _referenceDate) return;
    _referenceDate = d;
    _applyDateQuery();
  }

  void prev() {
    _referenceDate = _prevReferenceDate();
    _applyDateQuery();
  }

  void next() {
    final next = _nextReferenceDate();
    if (next.isAfter(_today)) return;
    _referenceDate = next;
    _applyDateQuery();
  }

  DateTime _prevReferenceDate() => switch (_scale) {
    PopularScale.day => _referenceDate.subtract(const Duration(days: 1)),
    PopularScale.week => _referenceDate.subtract(const Duration(days: 7)),
    PopularScale.month => DateTime(_referenceDate.year, _referenceDate.month - 1, 1),
    PopularScale.hot => _referenceDate,
  };

  DateTime _nextReferenceDate() => switch (_scale) {
    PopularScale.day => _referenceDate.add(const Duration(days: 1)),
    PopularScale.week => _referenceDate.add(const Duration(days: 7)),
    PopularScale.month => DateTime(_referenceDate.year, _referenceDate.month + 1, 1),
    PopularScale.hot => _referenceDate,
  };

  void _applyDateQuery() {
    query = {'tags': _dateTagFor(scale: _scale, referenceDate: _referenceDate)};
  }

  static String _dateTagFor({
    required PopularScale scale,
    required DateTime referenceDate,
  }) {
    if (scale == PopularScale.hot) {
      return 'order:hot';
    }

    final d = DateUtils.dateOnly(referenceDate);
    final today = DateUtils.dateOnly(DateTime.now());
    if (scale == PopularScale.day) {
      if (d == today) return 'date:today';
      if (d == today.subtract(const Duration(days: 1))) return 'date:yesterday';
      return 'date:${_apiDate.format(d)}';
    }

    DateTime start;
    DateTime end;
    if (scale == PopularScale.week) {
      // e621 week is Monday..Sunday
      start = d.subtract(Duration(days: d.weekday - DateTime.monday));
      end = start.add(const Duration(days: 6));
    } else {
      start = DateTime(d.year, d.month, 1);
      end = DateTime(d.year, d.month + 1, 0);
    }

    if (end.isAfter(today)) end = today;
    if (start.isAfter(end)) start = end;
    return 'date:${_apiDate.format(start)}..${_apiDate.format(end)}';
  }

  @override
  @protected
  Future<List<Post>> fetch(int page, bool force) async {
    return client.posts.byHot(
      page: page,
      query: query,
      force: force,
      cancelToken: cancelToken,
    );
  }
}
