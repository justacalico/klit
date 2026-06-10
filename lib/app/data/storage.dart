import 'package:drift/drift.dart';
import 'package:kilt/finish/data/database.dart';
import 'package:kilt/follow/data/database.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/identity/data/database.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/traits/traits.dart';
import 'package:notified_preferences/notified_preferences.dart';

// ignore: always_use_package_imports
import 'storage.drift.dart';

@DriftDatabase(
  tables: [
    IdentitiesTable,
    TraitsTable,
    HistoriesTable,
    HistoriesIdentitiesTable,
    FollowsTable,
    FollowsIdentitiesTable,
    FinishesTable,
  ],
)
class AppDatabase extends $AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) {
      return m.createAll().then((_) async {
        await customStatement('''
              CREATE TRIGGER delete_identity_follows
              AFTER DELETE ON identities_table
              BEGIN
                  DELETE FROM follows_table
                  WHERE id IN (SELECT follow FROM follows_identities_table WHERE identity = OLD.id);
              END;
              CREATE TRIGGER delete_identity_histories
              AFTER DELETE ON identities_table
              BEGIN
                  DELETE FROM histories_table
                  WHERE id IN (SELECT history FROM histories_identities_table WHERE identity = OLD.id);
              END;
            ''');
      });
    },
    onUpgrade: (m, from, to) async {
      if (from < 4) {
        await customStatement('''
              DELETE FROM identities_table
              WHERE type != 'e621';
              ''');
        await m.alterTable(TableMigration(identitiesTable));
        await m.alterTable(
          TableMigration(
            traitsTable,
            newColumns: [traitsTable.userId, traitsTable.perPage],
          ),
        );
      }
      if (from < 5) {
        await m.alterTable(
          TableMigration(
            traitsTable,
            newColumns: [traitsTable.writeHistory, traitsTable.trimHistory],
          ),
        );
      }
      if (from < 6) {
        await m.createTable(finishesTable);
      }
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}

/// Holds various databases for the app.
class AppStorage {
  const AppStorage({
    required this.preferences,
    required this.temporaryFiles,
    required this.httpCache,
    required this.sqlite,
  });

  final SharedPreferences preferences;
  final String temporaryFiles;
  final CacheStore? httpCache;
  final AppDatabase sqlite;

  Future<void> close() async {
    await httpCache?.close();
    await sqlite.close();
  }
}
