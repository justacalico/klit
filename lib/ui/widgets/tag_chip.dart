import 'package:flutter/cupertino.dart';
import '../../data/models/models.dart';

/// Tag chip widget with color coding
class TagChip extends StatelessWidget {
  final String tag;
  final String? category;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool showIcon;

  const TagChip({
    super.key,
    required this.tag,
    this.category,
    this.onTap,
    this.isSelected = false,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = category != null
        ? PostTags.getColorForCategory(category!)
        : CupertinoColors.systemBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon && category != null) ...[
              Icon(
                _getIconForCategory(category!),
                size: 12,
                color: isSelected ? CupertinoColors.white : color,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                tag.replaceAll('_', ' '),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? CupertinoColors.white : color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'artist':
        return CupertinoIcons.paintbrush;
      case 'copyright':
        return CupertinoIcons.doc_text;
      case 'character':
        return CupertinoIcons.person;
      case 'species':
        return CupertinoIcons.paw;
      case 'meta':
        return CupertinoIcons.info_circle;
      case 'lore':
        return CupertinoIcons.book;
      default:
        return CupertinoIcons.tag;
    }
  }
}

/// Tag list widget (horizontal scroll)
class TagList extends StatelessWidget {
  final PostTags tags;
  final Function(String tag, String category)? onTagTap;
  final int maxTags;

  const TagList({
    super.key,
    required this.tags,
    this.onTagTap,
    this.maxTags = 20,
  });

  @override
  Widget build(BuildContext context) {
    final allTags = _getAllTagsWithCategories();
    final displayTags = allTags.take(maxTags).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: displayTags.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: TagChip(
              tag: entry.key,
              category: entry.value,
              onTap: onTagTap != null
                  ? () => onTagTap!(entry.key, entry.value)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  List<MapEntry<String, String>> _getAllTagsWithCategories() {
    final result = <MapEntry<String, String>>[];

    for (final tag in tags.artist) {
      result.add(MapEntry(tag, 'artist'));
    }
    for (final tag in tags.character) {
      result.add(MapEntry(tag, 'character'));
    }
    for (final tag in tags.copyright) {
      result.add(MapEntry(tag, 'copyright'));
    }
    for (final tag in tags.species) {
      result.add(MapEntry(tag, 'species'));
    }
    for (final tag in tags.general) {
      result.add(MapEntry(tag, 'general'));
    }
    for (final tag in tags.meta) {
      result.add(MapEntry(tag, 'meta'));
    }
    for (final tag in tags.lore) {
      result.add(MapEntry(tag, 'lore'));
    }

    return result;
  }
}

/// Categorized tag list (grouped by category)
class CategorizedTagList extends StatelessWidget {
  final PostTags tags;
  final Function(String tag)? onTagTap;

  const CategorizedTagList({
    super.key,
    required this.tags,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.artist.isNotEmpty) _buildCategory('Artists', tags.artist, 'artist'),
        if (tags.character.isNotEmpty)
          _buildCategory('Characters', tags.character, 'character'),
        if (tags.copyright.isNotEmpty)
          _buildCategory('Copyrights', tags.copyright, 'copyright'),
        if (tags.species.isNotEmpty) _buildCategory('Species', tags.species, 'species'),
        if (tags.general.isNotEmpty) _buildCategory('General', tags.general, 'general'),
        if (tags.meta.isNotEmpty) _buildCategory('Meta', tags.meta, 'meta'),
        if (tags.lore.isNotEmpty) _buildCategory('Lore', tags.lore, 'lore'),
      ],
    );
  }

  Widget _buildCategory(String title, List<String> tagList, String category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PostTags.getColorForCategory(category),
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tagList.map((tag) {
              return TagChip(
                tag: tag,
                category: category,
                onTap: onTagTap != null ? () => onTagTap!(tag) : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
