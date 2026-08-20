// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';

Future<void> showDenyListEditorDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _DenyListEditorDialog(),
  );
}

class DenyListEditor extends StatelessWidget {
  const DenyListEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final client = context.read<Client>();
    return TextEditor(
      title: Text(l10n.traitsBlacklist),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () =>
              showTagSearchPrompt(context: context, tag: 'e621:blacklist'),
        ),
      ],
      content: client.traits.value.denylist.join('\n'),
      onSubmitted: (value) async {
        var tags = value.split('\n');
        tags = tags.trim();
        tags.removeWhere((tag) => tag.isEmpty);
        try {
          await client.accounts.push(
            traits: client.traits.value.copyWith(denylist: tags),
          );
        } on ClientException {
          return l10n.traitsFailedUpdate;
        }
        return null;
      },
      onClosed: Navigator.of(context).maybePop,
    );
  }
}

class _DenyListEditorDialog extends StatefulWidget {
  const _DenyListEditorDialog();

  @override
  State<_DenyListEditorDialog> createState() => _DenyListEditorDialogState();
}

class _DenyListEditorDialogState extends State<_DenyListEditorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<Client>().traits.value.denylist.join('\n'),
  );
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final client = context.read<Client>();
    final tags = _controller.text.split('\n').trim();
    tags.removeWhere((tag) => tag.isEmpty);

    try {
      await client.accounts.push(
        traits: client.traits.value.copyWith(denylist: tags),
      );
      if (mounted) Navigator.of(context).maybePop();
    } on ClientException {
      if (!mounted) return;
      setState(() {
        _error = l10n.traitsFailedUpdate;
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.traitsBlacklist,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => showTagSearchPrompt(
                      context: context,
                      tag: 'e621:blacklist',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.multiline,
                maxLines: 12,
                minLines: 10,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: l10n.traitsOneTagPerLine,
                ),
                enableIMEPersonalizedLearning: !PrivateTextFields.of(context),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(l10n.commonSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
