import 'package:klit/post/post.dart';
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          Text(
            'Search',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TagInput(
                controller: _textController,
                focusNode: _focusNode,
                autofocus: false,
                labelText: 'Search tags',
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search tags',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                submit: (value) {
                  widget.controller.query =
                      Map.from(widget.controller.query)..['tags'] = value;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingSearchBar extends StatefulWidget {
  const FloatingSearchBar({
    super.key,
    required this.controller,
    this.requestFocus = false,
  });

  final PostController controller;
  final bool requestFocus;

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Material(
        elevation: 2,
        shadowColor: theme.shadowColor.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TagInput(
            controller: _textController,
            focusNode: _focusNode,
            autofocus: false,
            labelText: 'Search tags',
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search tags',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            submit: (value) {
              widget.controller.query =
                  Map.from(widget.controller.query)..['tags'] = value;
            },
          ),
        ),
      ),
    );
  }
}
