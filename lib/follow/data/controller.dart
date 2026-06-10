import 'package:kilt/client/client.dart';
import 'package:kilt/follow/follow.dart';
import 'package:kilt/shared/shared.dart';

class FollowController extends PageClientDataController<Follow> {
  FollowController({
    required this.client,
    this.types = FollowType.values,
    bool filterUnseen = false,
  }) : _filterUnseen = filterUnseen;

  @override
  final Client client;
  final List<FollowType> types;

  bool get filterUnseen => _filterUnseen;
  bool _filterUnseen;
  set filterUnseen(bool value) {
    if (_filterUnseen == value) return;
    _filterUnseen = value;
    refresh();
  }

  @override
  Future<List<Follow>> fetch(int page, bool force) {
    StreamFuture<List<Follow>> result;
    if (page == 1) {
      result = client.follows
          .all(
            query: FollowsQuery(types: types, hasUnseen: _filterUnseen),
            force: force,
          )
          .stream;
      if (_filterUnseen) {
        return result.stream.asyncExpand((event) {
          if (event.fold(0, (a, b) => a + b.unseen!) == 0) {
            return client.follows
                .all(
                  query: FollowsQuery(types: types),
                  force: force,
                )
                .stream
                .stream; // I can explain
          } else {
            return Stream.value(event);
          }
        }).future;
      }
    } else {
      result = StreamFuture.value([]);
    }
    return result;
  }
}
