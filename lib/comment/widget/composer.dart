// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/comment/comment.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/markup/markup.dart';
import 'package:kilt/settings/settings.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InlineCommentComposer extends StatefulWidget {
  const InlineCommentComposer({super.key, required this.postId});

  final int postId;

  @override
  State<InlineCommentComposer> createState() => _InlineCommentComposerState();
}

class _InlineCommentComposerState extends State<InlineCommentComposer>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _textController = TextEditingController();
  late final TabController _tabController =
      TabController(length: 2, vsync: this)..addListener(() {
        if (mounted) setState(() {});
      });
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final error = await submitNewComment(
      context: context,
      postId: widget.postId,
      text: text,
    );

    if (!mounted) return;

    if (error != null) {
      messenger.showSnackBar(
        SnackBar(duration: const Duration(seconds: 1), content: Text(error)),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    HapticFeedback.selectionClick();
    _textController.clear();
    await context.read<CommentController>().refresh(force: true);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(l10n.commentSent),
      ),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasLogin = context.watch<Client>().hasLogin;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final theme = Theme.of(context);
    final isOled = context.read<Settings>().theme.value == AppTheme.amoled;
    final surface = isOled
        ? Colors.black
        : theme.brightness == Brightness.dark
        ? Color.lerp(theme.canvasColor, Colors.white, 0.06)!
        : theme.colorScheme.surface;

    if (!hasLogin) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Text(l10n.commentLogInToAdd),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                child: Row(
                  children: [
                    Text(
                      l10n.commentAddComment,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.commonWrite),
                  Tab(text: l10n.commonPreview),
                ],
              ),
              SizedBox(
                height: 140,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                      child: TextField(
                        controller: _textController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: l10n.commonTypeHere,
                        ),
                        enabled: !_isSubmitting,
                        enableIMEPersonalizedLearning: !PrivateTextFields.of(
                          context,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: SingleChildScrollView(
                        child: AnimatedBuilder(
                          animation: _textController,
                          builder: (context, _) {
                            if (_textController.text.trim().isNotEmpty) {
                              return DText(_textController.text);
                            }
                            return Text(
                              l10n.commonYourTextHere,
                              style: TextStyle(
                                color: dimTextColor(context),
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_tabController.index == 0)
                DTextEditorBar(controller: _textController),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, _) {
                    final canSend =
                        value.text.trim().isNotEmpty && !_isSubmitting;
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canSend ? _submit : null,
                        icon: const Icon(Icons.send),
                        label: Text(l10n.commonSend),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
