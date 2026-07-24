import 'package:kilt/client/client.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/ticket/ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParentEditDisplay extends StatefulWidget {
  const ParentEditDisplay({super.key, required this.controller, this.enabled});

  final TextEditingController controller;
  final bool? enabled;

  @override
  State<ParentEditDisplay> createState() => _ParentEditDisplayState();
}

class _ParentEditDisplayState extends State<ParentEditDisplay> {
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() async {
    if (!_focusNode.hasFocus) {
      final l10n = AppLocalizations.of(context);
      final value = widget.controller.text;
      if (value.trim().isEmpty) {
        setState(() => _errorText = null);
        return;
      }

      final parentId = int.tryParse(value);
      if (parentId == null) {
        setState(() => _errorText = l10n.postEditInvalidNumber);
        return;
      }

      try {
        await context.read<Client>().posts.get(id: parentId);
        setState(() => _errorText = null);
      } on ClientException {
        setState(() => _errorText = l10n.postEditInvalidParent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: defaultFormPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.postEditParentIdOptional, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.postEditParentIdHint,
              errorText: _errorText,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: widget.enabled,
          ),
        ],
      ),
    );
  }
}
