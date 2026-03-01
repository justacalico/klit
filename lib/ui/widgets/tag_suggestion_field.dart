import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/debouncer.dart';
import '../../data/models/models.dart';
import '../../data/services/services.dart';
import '../../providers/providers.dart';

/// Text field with tag suggestions (reused from search page logic).
/// Fetches suggestions as the user types; supports - and ~ prefix for current word.
class TagSuggestionField extends StatefulWidget {
  const TagSuggestionField({
    super.key,
    required this.controller,
    this.focusNode,
    this.placeholder,
    this.decoration,
    this.maxLines = 4,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final BoxDecoration? decoration;
  final int maxLines;
  final EdgeInsetsGeometry padding;

  @override
  State<TagSuggestionField> createState() => _TagSuggestionFieldState();
}

class _TagSuggestionFieldState extends State<TagSuggestionField> {
  late FocusNode _focusNode;
  List<Tag> _suggestions = [];
  bool _showSuggestions = false;
  String _prefix = '';
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _close();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.endsWith(' ')) {
      _close();
      return;
    }
    final word = _getCurrentWord();
    if (word.length >= 2) {
      _debouncer.run(() => _fetchSuggestions(word));
    } else {
      _close();
    }
  }

  String _getCurrentWord() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    String rawWord;
    if (cursorPos < 0 || cursorPos > text.length) {
      rawWord = text.split(' ').last;
    } else {
      final before = text.substring(0, cursorPos);
      final words = before.split(' ');
      rawWord = words.isNotEmpty ? words.last : '';
    }
    if (rawWord.startsWith('-')) {
      _prefix = '-';
      return rawWord.substring(1);
    } else if (rawWord.startsWith('~')) {
      _prefix = '~';
      return rawWord.substring(1);
    } else {
      _prefix = '';
      return rawWord;
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      if (_showSuggestions) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
      return;
    }
    final api = context.read<ApiService>();
    final result = await api.searchTags(query: query, limit: 10);
    if (mounted) {
      result.when(
        success: (tags) {
          setState(() {
            _suggestions = tags;
            _showSuggestions = tags.isNotEmpty;
          });
        },
        failure: (_) {
          setState(() {
            _suggestions = [];
            _showSuggestions = false;
          });
        },
      );
    }
  }

  void _close() {
    if (_showSuggestions || _suggestions.isNotEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
    _debouncer.cancel();
    _prefix = '';
  }

  void _insertTag(String tagName) {
    final tagWithPrefix = '$_prefix$tagName';
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) {
      final words = text.split(' ');
      if (words.isNotEmpty) {
        words[words.length - 1] = tagWithPrefix;
      } else {
        words.add(tagWithPrefix);
      }
      widget.controller.text = '${words.join(' ')} ';
    } else {
      final before = text.substring(0, cursorPos);
      final after = text.substring(cursorPos);
      final lastSpace = before.lastIndexOf(' ');
      final newBefore = lastSpace >= 0
          ? '${before.substring(0, lastSpace + 1)}$tagWithPrefix '
          : '$tagWithPrefix ';
      widget.controller.text = newBefore + after;
      widget.controller.selection = TextSelection.collapsed(offset: newBefore.length);
    }
    _close();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final isOled = context.watch<SettingsProvider>().themeMode == 3;
    final decoration = widget.decoration ??
        BoxDecoration(
          color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.08),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoTextField(
          controller: widget.controller,
          focusNode: _focusNode,
          placeholder: widget.placeholder,
          maxLines: widget.maxLines,
          padding: widget.padding,
          decoration: decoration,
        ),
        if (_showSuggestions && _suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSuggestionsList(isDark),
        ],
      ],
    );
  }

  Widget _buildSuggestionsList(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isDark
            ? CupertinoColors.white.withValues(alpha: 0.14)
            : CupertinoColors.white.withValues(alpha: 0.95),
        border: Border.all(
          color: isDark
              ? CupertinoColors.white.withValues(alpha: 0.15)
              : CupertinoColors.black.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _suggestions.length,
        itemBuilder: (_, i) {
          final tag = _suggestions[i];
          return GestureDetector(
            onTap: () => _insertTag(tag.name),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: i < _suggestions.length - 1
                    ? Border(
                        bottom: BorderSide(
                          color: isDark
                              ? CupertinoColors.white.withValues(alpha: 0.1)
                              : CupertinoColors.black.withValues(alpha: 0.05),
                          width: 0.5,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: tag.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tag.name.replaceAll('_', ' '),
                      style: TextStyle(color: tag.color, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    tag.postCount >= 1000000
                        ? '${(tag.postCount / 1000000).toStringAsFixed(1)}m'
                        : (tag.postCount >= 1000
                            ? '${(tag.postCount / 1000).toStringAsFixed(1)}k'
                            : '${tag.postCount}'),
                    style: TextStyle(
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.5)
                          : CupertinoColors.black.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
