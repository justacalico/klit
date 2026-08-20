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
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) {
      return m.createAll().then((_) async {
        await customStatement('''
          CREATE TRIGGER cleanup_orphan_follows
          AFTER DELETE ON follows_identities_table
          BEGIN
            DELETE FROM follows_table
            WHERE id = OLD.follow
              AND NOT EXISTS (
                SELECT 1 FROM follows_identities_table
                WHERE follow = OLD.follow
              );
          END;
          CREATE TRIGGER cleanup_orphan_histories
          AFTER DELETE ON histories_identities_table
          BEGIN
            DELETE FROM histories_table
            WHERE id = OLD.history
              AND NOT EXISTS (
                SELECT 1 FROM histories_identities_table
                WHERE history = OLD.history
              );
          END;
        ''');
      });
    },
    onUpgrade: (m, from, to) async {
      if (from < 4) {
        // Previously this migration deleted all non-e621 identities.
        // We no longer drop them silently; TableMigration will migrate
        // the remaining rows into the new schema instead.
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
      if (from < 8) {
        await customStatement('PRAGMA foreign_keys = OFF');
        await customStatement('DROP TRIGGER IF EXISTS delete_identity_follows');
        await customStatement('DROP TRIGGER IF EXISTS delete_identity_histories');

        await customStatement('''
          CREATE TABLE follows_identities_table_new (
            identity INTEGER NOT NULL REFERENCES identities_table(id) ON DELETE CASCADE ON UPDATE CASCADE,
            follow INTEGER NOT NULL REFERENCES follows_table(id) ON DELETE CASCADE ON UPDATE CASCADE,
            PRIMARY KEY (identity, follow)
          );
        ''');
        await customStatement('''
          INSERT INTO follows_identities_table_new (identity, follow)
          SELECT identity, follow FROM follows_identities_table;
        ''');
        await customStatement('DROP TABLE follows_identities_table');
        await customStatement('ALTER TABLE follows_identities_table_new RENAME TO follows_identities_table');

        await customStatement('''
          CREATE TABLE histories_identities_table_new (
            identity INTEGER NOT NULL REFERENCES identities_table(id) ON DELETE CASCADE ON UPDATE CASCADE,
            history INTEGER NOT NULL REFERENCES histories_table(id) ON DELETE CASCADE ON UPDATE CASCADE,
            PRIMARY KEY (identity, history)
          );
        ''');
        await customStatement('''
          INSERT INTO histories_identities_table_new (identity, history)
          SELECT identity, history FROM histories_identities_table;
        ''');
        await customStatement('DROP TABLE histories_identities_table');
        await customStatement('ALTER TABLE histories_identities_table_new RENAME TO histories_identities_table');

        await customStatement('''
          CREATE TRIGGER cleanup_orphan_follows
          AFTER DELETE ON follows_identities_table
          BEGIN
            DELETE FROM follows_table
            WHERE id = OLD.follow
              AND NOT EXISTS (
                SELECT 1 FROM follows_identities_table
                WHERE follow = OLD.follow
              );
          END;
          CREATE TRIGGER cleanup_orphan_histories
          AFTER DELETE ON histories_identities_table
          BEGIN
            DELETE FROM histories_table
            WHERE id = OLD.history
              AND NOT EXISTS (
                SELECT 1 FROM histories_identities_table
                WHERE history = OLD.history
              );
          END;
        ''');
        await customStatement('PRAGMA foreign_keys = ON');
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
