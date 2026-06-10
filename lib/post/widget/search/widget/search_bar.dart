import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:flutter/material.dart';

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

class _SearchPageAppBarState extends State<SearchPageAppBar> {
  late final FocusNode _focusNode = FocusNode();
  late final TextEditingController _textController = TextEditingController(
    text: widget.controller.query['tags'] ?? '',
  );

  @override
  void initState() {
    super.initState();
    if (widget.requestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.onSurfaceVariant;
    final hintColor = iconColor.withValues(alpha: 0.8);

    return DefaultAppBar(
      title: const Text('Search'),
      actions: [Builder(builder: (context) => ContextDrawerButton())],
      secondary: TagInput(
        controller: _textController,
        focusNode: _focusNode,
        autofocus: false,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search tags',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(color: hintColor),
          prefixIcon: Icon(Icons.search, color: iconColor),
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
