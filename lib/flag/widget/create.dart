import 'dart:math';

import 'package:kilt/client/client.dart';
import 'package:kilt/flag/flag.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/markup/markup.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:kilt/ticket/ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostFlagScreen extends StatefulWidget {
  const PostFlagScreen({super.key, required this.post});

  final Post post;

  @override
  State<PostFlagScreen> createState() => _PostFlagScreenState();
}

class _PostFlagScreenState extends State<PostFlagScreen> {
  ScrollController scrollController = ScrollController();
  TextEditingController parentController = TextEditingController();
  FlagType? type;

  bool isLoading = false;

  @override
  void dispose() {
    scrollController.dispose();
    parentController.dispose();
    super.dispose();
  }

  Future<void> _sendFlag(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (Form.of(context).validate()) {
      setState(() {
        isLoading = true;
      });
      scrollController.animateTo(
        0,
        duration: defaultAnimationDuration,
        curve: Curves.easeInOut,
      );
      ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      try {
        await context.read<Client>().flags.create(
          widget.post.id,
          type!.title,
          parent: int.tryParse(parentController.text),
        );
        if (context.mounted) {
          Navigator.of(context).maybePop();
        }
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            content: Text(l10n.postFlaggedSuccess(widget.post.id)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } on ClientException {
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            content: Text(l10n.postFlagFailed(widget.post.id)),
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KeyboardDismisser(
      child: Form(
        child: Scaffold(
          appBar: DefaultAppBar(
            elevation: 0,
            title: Text(l10n.postFlagTitle(widget.post.id)),
            leading: const CloseButton(),
          ),
          floatingActionButton: Builder(
            builder: (context) => FloatingActionButton(
              onPressed: isLoading ? null : () => _sendFlag(context),
              child: const Icon(Icons.check),
            ),
          ),
          body: LimitedWidthLayout(
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                controller: scrollController,
                padding: LimitedWidthLayout.of(
                  context,
                ).padding.add(defaultFormScreenPadding),
                children: [
                  PostReportImage(
                    post: widget.post,
                    height: constraints.maxHeight,
                    isLoading: isLoading,
                  ),
                  ReportFormHeader(
                    title: Text(l10n.postFlag),
                    icon: IconButton(
                      onPressed: () => showTagSearchPrompt(
                        context: context,
                        tag: 'e621:flag_for_deletion',
                      ),
                      icon: const Icon(Icons.info_outline),
                    ),
                  ),
                  ReportFormDropdown<FlagType?>(
                    type: type,
                    types: {for (final e in FlagType.values) e: e.title},
                    onChanged: (value) => setState(() => type = value),
                    isLoading: isLoading,
                  ),
                  CrossFade.builder(
                    showChild: type == FlagType.inferior,
                    builder: (context) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: TextFormField(
                        enabled: !isLoading,
                        controller: parentController,
                        decoration: InputDecoration(
                          labelText: l10n.postFlagParentId,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^ ?\d*')),
                        ],
                        validator: (value) {
                          if (value!.trim().isEmpty) {
                            return l10n.postFlagParentIdEmpty;
                          }
                          if (int.tryParse(value) == null) {
                            return l10n.postFlagParentIdNumber;
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  CrossFade.builder(
                    showChild: type != null,
                    builder: (context) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: DText(type!.body),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
