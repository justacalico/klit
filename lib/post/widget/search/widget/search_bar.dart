// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';

class SearchPageAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SearchPageAppBar({
    super.key,
    required this.controller,
    this.requestFocus = false,
  });

  final PostController controller;
  final bool requestFocus;

  @override
  Size get preferredSize => const DefaultAppBar(
    title: Text('Search'),
    secondary: SizedBox.shrink(),
  ).preferredSize;

  @override
  State<SearchPageAppBar> createState() => _SearchPageAppBarState();
}

class _SearchPageAppBarState extends State<SearchPageAppBar>
    with DefaultRouteAware<SearchPageAppBar> {
  late final FocusNode _focusNode = FocusNode();
  late final TextEditingController _textController = TextEditingController(
    text: widget.controller.query['tags'] ?? '',
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromController);
    if (widget.requestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(SearchPageAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromController);
      widget.controller.addListener(_syncFromController);
      _syncFromController();
    }
  }

  void _syncFromController() {
    final queryTags = widget.controller.query['tags'] ?? '';
    if (_textController.text != queryTags) {
      _textController.value = TextEditingValue(
        text: queryTags,
        selection: TextSelection.collapsed(offset: queryTags.length),
      );
    }
  }

  @override
  void didPushNext() {
    super.didPushNext();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;
    final hintColor = iconColor.withValues(alpha: 0.8);

    return DefaultAppBar(
      title: Text(l10n.postSearch),
      actions: [Builder(builder: (context) => const ContextDrawerButton())],
      secondary: TagInput(
        controller: _textController,
        focusNode: _focusNode,
        autofocus: false,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.postSearchTags,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(color: hintColor),
          prefixIcon: Icon(Icons.search, color: iconColor),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _textController,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.clear, size: 20),
                tooltip: l10n.commonClear,
                onPressed: () {
                  _textController.clear();
                  widget.controller.query = Map.from(widget.controller.query)
                    ..remove('tags');
                },
              );
            },
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isDense: true,
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          contentPadding: const EdgeInsetsDirectional.fromSTEB(0, 14, 14, 14),
        ),
        submit: (value) {
          widget.controller.query = Map.from(widget.controller.query)
            ..['tags'] = value;
        },
      ),
    );
  }
}
