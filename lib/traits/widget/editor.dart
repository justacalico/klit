import 'package:klit/client/client.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/tag/tag.dart';
import 'package:flutter/material.dart';

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
