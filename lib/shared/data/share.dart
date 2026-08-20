// SPDX-License-Identifier: AGPL-3.0

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract final class Share {
  static Future<void> text(BuildContext context, String text) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await SharePlus.instance.share(ShareParams(text: text));
    } else {
      await clipboard(context, text);
    }
  }

  static Future<void> asFile(
    BuildContext context,
    String text,
    String name,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (Platform.isAndroid || Platform.isIOS) {
      final file = File(
        join(await getTemporaryDirectory().then((e) => e.path), name),
      );
      await file.writeAsString(text);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } else {
      final messenger = ScaffoldMessenger.of(context);
      final outputFile = await FilePicker.saveFile(
        dialogTitle: l10n.commonSaveFile,
        fileName: name,
      );
      if (outputFile == null) return;

      await File(outputFile).writeAsString(text);
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(l10n.commonFileSavedAs(basename(outputFile))),
        ),
      );
    }
  }

  static Future<void> file(BuildContext context, String path) async {
    final l10n = AppLocalizations.of(context);
    final file = XFile(path);
    if (Platform.isAndroid || Platform.isIOS) {
      await SharePlus.instance.share(ShareParams(files: [file]));
    } else {
      final messenger = ScaffoldMessenger.of(context);
      final content = await file.readAsString();
      if (!context.mounted) return;

      final outputFile = await FilePicker.saveFile(
        dialogTitle: l10n.commonSaveFile,
        fileName: basename(path),
      );
      if (outputFile == null) return;

      await File(outputFile).writeAsString(content);
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(l10n.commonFileSavedAs(basename(outputFile))),
        ),
      );
    }
  }

  static Future<void> clipboard(BuildContext context, String text) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(l10n.commonCopiedToClipboard),
      ),
    );
  }
}
