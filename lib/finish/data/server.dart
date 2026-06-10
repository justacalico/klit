import 'package:drift/drift.dart';
import 'package:kilt/finish/finish.dart';
import 'package:kilt/identity/identity.dart';

class FinishServer {
  FinishServer({
    required GeneratedDatabase database,
    required this.identity,
  }) : repository = FinishRepository(
          database: database,
          getFinishesTable: () => (database as dynamic).finishesTable,
        );

  final FinishRepository repository;
  final Identity identity;

  Future<int> add(int postId, [String? photoPath]) => repository.insert(
        identity.id,
        postId,
        DateTime.now(),
        photoPath,
      );

  Future<void> deleteById(int id) => repository.deleteById(id);

  Stream<List<Finish>> watchForIdentity() =>
      repository.watchForIdentity(identity.id);

  Stream<int> watchCountForPost(int postId) =>
      watchForIdentity().map((list) => list.where((f) => f.postId == postId).length);
}
