import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';
import 'package:klit/tag/tag.dart';
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
  Size get preferredSize => const Size.fromHeight(124);

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
    final inputFill = theme.brightness == Brightness.dark
        ? Color.lerp(theme.cardColor, Colors.white, 0.06)
        : theme.colorScheme.surfaceContainerHighest;

    return AppBar(
      centerTitle: false,
      title: const Text('Search'),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 6),
          child: Builder(builder: (context) => ContextDrawerButton()),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: Material(
            elevation: 0,
            color: inputFill,
            borderRadius: BorderRadius.circular(14),
            child: TagInput(
              controller: _textController,
              focusNode: _focusNode,
              autofocus: false,
              labelText: 'Search tags',
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search tags',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              submit: (value) {
                widget.controller.query = Map.from(widget.controller.query)
                  ..['tags'] = value;
              },
            ),
          ),
        ),
      ),
    );
  }
}
