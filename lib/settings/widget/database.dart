// SPDX-License-Identifier: AGPL-3.0

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sub/flutter_sub.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/app/widget/initialize.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/logs/logs.dart';
import 'package:kilt/shared/shared.dart';

typedef DatabaseInfo = ({String name, String size});

final _logger = Logger('DbManagement');

class DatabaseManagementPage extends StatelessWidget {
  const DatabaseManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TransparentAppBar(
        child: DefaultAppBar(leading: CloseButton()),
      ),
      body: LimitedWidthLayout.builder(
        builder: (context) => ListView(
          padding: defaultActionListPadding.add(
            LimitedWidthLayout.of(context).padding,
          ),
          children: const [
            DatabaseInfoDisplay(),
            SizedBox(height: 64),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                child: Column(
                  children: [DatabaseExportTile(), DatabaseImportTile()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DatabaseInfoDisplay extends StatelessWidget {
  const DatabaseInfoDisplay({super.key});

  Future<DatabaseInfo> _loadDatabaseInfo() async {
    final dbPath = await getAppDatabasePath();
    final dbFile = File(dbPath);

    final name = dbPath.split(Platform.pathSeparator).last;
    final size = dbFile.existsSync()
        ? filesize(dbFile.lengthSync())
        : 'Unknown';

    return (name: name, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SubFuture<DatabaseInfo>(
      create: _loadDatabaseInfo,
      builder: (context, snapshot) {
        final dbInfo =
            snapshot.data ??
            (snapshot.error != null
                ? (name: l10n.databaseErrorLoading, size: 'N/A')
                : (name: l10n.commonLoading, size: '...'));

        return Center(
          child: Column(
            children: [
              const SizedBox(height: 32),
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.primary,
                radius: 64,
                child: const Icon(Icons.storage, size: 64),
              ),
              const SizedBox(height: 16),
              Text(dbInfo.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Dimmed(
                child: Text(
                  dbInfo.size,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class DatabaseExportTile extends StatelessWidget {
  const DatabaseExportTile({super.key});

  Future<void> _exportDatabase(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(4),
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.databaseExporting),
              ),
            ],
          ),
        ),
      );

      final dbPath = await getAppDatabasePath();
      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) {
        throw Exception('Database file does not exist');
      }

      final outputFile = await FilePicker.saveFile(
        dialogTitle: l10n.databaseExportDialogTitle,
        fileName: l10n.databaseBackupFileName,
        type: FileType.custom,
        allowedExtensions: ['db'],
        bytes: await dbFile.readAsBytes(),
      );

      navigator.pop();
      if (outputFile != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.databaseExportSuccess)),
        );
      }
    } on Exception catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.databaseExportFailed)));
      _logger.severe('Database export failed', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.file_download),
      title: Text(l10n.databaseExportTitle),
      subtitle: Text(
        l10n.databaseExportSubtitle,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _exportDatabase(context),
    );
  }
}

class DatabaseImportTile extends StatelessWidget {
  const DatabaseImportTile({super.key});

  Future<void> _importDatabase(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    final confirmed = await _showImportWarning(context);
    if (!confirmed) return;

    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: l10n.databaseImportDialogTitle,
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      final path = result?.files.single.path;

      if (path == null) return;
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(4),
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.databaseImporting),
              ),
            ],
          ),
        ),
      );

      try {
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
        final importDb = AppDatabase(
          driftDatabase(
            name: 'import',
            native: DriftNativeOptions(databasePath: () async => path),
          ),
        );
        await importDb.customSelect('SELECT 1').get();
        await importDb.close();
      } on Exception catch (e) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.databaseImportInvalidFile(e.toString()))),
        );
        _logger.warning('Database validation failed', e);
        return;
      } finally {
        driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
      }

      final importFile = File(path);
      final dbPath = await getAppDatabasePath();
      final newDbPath = '$dbPath.new';
      await importFile.copy(newDbPath);

      navigator.pop();
      if (context.mounted) {
        await _showRestartDialog(context);
      }
    } on Exception catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.databaseImportFailed(e.toString()))));
    }
  }

  Future<bool> _showImportWarning(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
    context: context,
    builder: (context) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: AlertDialog(
          title: Text(l10n.databaseImportDialogTitle),
          content: Text(l10n.databaseImportWarningBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancelUpper),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.commonImportUpper),
            ),
          ],
        ),
      ),
    ),
  ).then((value) => value ?? false);
  }

  Future<void> _showRestartDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l10n.databaseRestartRequiredTitle),
      content: Text(l10n.databaseRestartRequiredBody),
      actions: [
        TextButton(
          onPressed: () => AppInit.of(context).reinitialize(),
          child: Text(l10n.commonRestartNowUpper),
        ),
      ],
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.file_upload),
      title: Text(l10n.databaseImportTitle),
      subtitle: Text(
        l10n.databaseImportSubtitle,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _importDatabase(context),
    );
  }
}
