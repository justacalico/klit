import 'package:drift/drift.dart';
import 'package:kilt/finish/data/database.drift.dart';
import 'package:kilt/finish/data/finish.dart';
import 'package:kilt/identity/data/database.dart';

@UseRowClass(Finish, generateInsertable: true)
class FinishesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get identityId => integer().references(
        IdentitiesTable,
        #id,
        onDelete: KeyAction.cascade,
        onUpdate: KeyAction.cascade,
      )();
  IntColumn get postId => integer()();
  DateTimeColumn get finishedAt => dateTime()();
  TextColumn get photoPath => text().nullable()();
}

typedef FinishesTableGetter = $FinishesTableTable Function();

@DriftAccessor(tables: [FinishesTable])
class FinishRepository extends DatabaseAccessor<GeneratedDatabase> {
  FinishRepository({
    required GeneratedDatabase database,
    FinishesTableGetter? getFinishesTable,
  })  : _getTable =
            getFinishesTable ?? (() => (database as dynamic).finishesTable),
        super(database);

  final FinishesTableGetter _getTable;

  $FinishesTableTable get _table => _getTable();

  Future<int> insert(int identityId, int postId, DateTime finishedAt,
      [String? photoPath]) {
    return into(_table).insert(
      FinishesTableCompanion.insert(
        identityId: identityId,
        postId: postId,
        finishedAt: finishedAt,
        photoPath: Value(photoPath),
      ),
    );
  }

  Future<void> deleteById(int id) =>
      (delete(_table)..where((t) => t.id.equals(id))).go();

  Stream<List<Finish>> watchForIdentity(int identityId) {
    return (select(_table)
          ..where((t) => t.identityId.equals(identityId))
          ..orderBy([(t) => OrderingTerm(expression: t.finishedAt, mode: OrderingMode.desc)]))
        .watch();
  }
}
