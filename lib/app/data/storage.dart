// SPDX-License-Identifier: AGPL-3.0

// ignore_for_file: experimental_member_use
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
  int get schemaVersion => 7;

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
      if (from < 7) {
        const indexes = [
          'CREATE INDEX IF NOT EXISTS follows_tags ON follows_table(tags);',
          'CREATE INDEX IF NOT EXISTS follows_updated ON follows_table(updated);',
          'CREATE INDEX IF NOT EXISTS follows_latest ON follows_table(latest);',
          'CREATE INDEX IF NOT EXISTS follows_unseen ON follows_table(unseen);',
          'CREATE INDEX IF NOT EXISTS histories_visited_at ON histories_table(visited_at);',
          'CREATE INDEX IF NOT EXISTS histories_category_visited_at ON histories_table(category, visited_at);',
          'CREATE INDEX IF NOT EXISTS histories_type_visited_at ON histories_table(type, visited_at);',
          'CREATE INDEX IF NOT EXISTS finishes_identity_finished_at ON finishes_table(identity_id, finished_at);',
          'CREATE INDEX IF NOT EXISTS finishes_post_id ON finishes_table(post_id);',
        ];
        for (final statement in indexes) {
          await customStatement(statement);
        }
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
