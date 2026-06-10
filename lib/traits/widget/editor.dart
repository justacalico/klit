import 'package:kilt/client/client.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:flutter/material.dart';

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
    final client = context.read<Client>();
    return TextEditor(
      title: const Text('Blacklist'),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () =>
              showTagSearchPrompt(context: context, tag: 'e621:blacklist'),
        ),
      ],
      content: client.traits.value.denylist.join('\n'),
      onSubmitted: (value) async {
        List<String> tags = value.split('\n');
        tags = tags.trim();
        tags.removeWhere((tag) => tag.isEmpty);
        try {
          await client.accounts.push(
            traits: client.traits.value.copyWith(denylist: tags),
          );
        } on ClientException {
          return 'Failed to update blacklist!';
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
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final client = context.read<Client>();
    var tags = _controller.text.split('\n').trim();
    tags.removeWhere((tag) => tag.isEmpty);

    try {
      await client.accounts.push(
        traits: client.traits.value.copyWith(denylist: tags),
      );
      if (mounted) Navigator.of(context).maybePop();
    } on ClientException {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to update blacklist!';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Expanded(
                    child: Text(
                      'Blacklist',
                      style: TextStyle(
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'One tag per line',
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
                    child: const Text('Cancel'),
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
                    label: const Text('Save'),
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
