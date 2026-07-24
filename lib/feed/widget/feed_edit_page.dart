import 'package:kilt/feed/data/feed.dart';
import 'package:kilt/feed/feeds_provider.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const OutlineInputBorder _roundedInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
);

class FeedEditPage extends StatefulWidget {
  const FeedEditPage({super.key, this.feed, this.onComplete});

  final Feed? feed;
  final VoidCallback? onComplete;

  @override
  State<FeedEditPage> createState() => _FeedEditPageState();
}

class _FeedEditPageState extends State<FeedEditPage> {
  late final TextEditingController _nameController;
  late String _mediaType;
  late final TextEditingController _includeController;
  late final TextEditingController _orController;
  late final TextEditingController _excludeController;
  late String? _rating;
  late String _order;
  late bool _excludeFavorites;
  late List<SubFeed> _subfeeds;

  bool get _isNew => widget.feed == null;
  bool get _embedded => widget.onComplete != null;

  static List<String> _tagsFrom(TextEditingController c) =>
      c.text.split(RegExp(r'\s+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    final f = widget.feed;
    _nameController = TextEditingController(text: f?.name ?? '');
    _mediaType = f?.mediaType ?? Feed.mediaTypeImage;
    _includeController = TextEditingController(text: f?.includeTags.join(' ') ?? '');
    _orController = TextEditingController(text: f?.orTags.join(' ') ?? '');
    _excludeController = TextEditingController(text: f?.excludeTags.join(' ') ?? '');
    _rating = f?.rating;
    _order = f?.order ?? 'id_desc';
    _excludeFavorites = f?.excludeFavorites ?? false;
    _subfeeds = f?.subfeeds != null ? List.from(f!.subfeeds) : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _includeController.dispose();
    _orController.dispose();
    _excludeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final feed = Feed(
      id: widget.feed?.id ?? '',
      name: name.isEmpty ? l10n.feedsUnnamed : name,
      mediaType: _mediaType,
      includeTags: _tagsFrom(_includeController),
      orTags: _tagsFrom(_orController),
      excludeTags: _tagsFrom(_excludeController),
      rating: _rating,
      order: _order,
      excludeFavorites: _excludeFavorites,
      subfeeds: _subfeeds,
    );
    final provider = context.read<FeedsProvider>();
    if (_isNew) {
      await provider.addFeed(feed);
    } else {
      await provider.updateFeed(feed);
    }
    if (!mounted) return;
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      context.pop();
    }
  }

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final padding = _embedded
        ? defaultActionListPadding.add(LimitedWidthLayout.of(context).padding)
        : defaultListPadding;
    return ListView(
      primary: true,
      padding: padding,
      children: [
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.commonName,
                  hintText: l10n.feedsNameHint,
                  border: _roundedInputBorder,
                ),
              ),
              const SizedBox(height: 16),
              ListTileHeader(title: l10n.commonType),
              _TypeSelector(
                value: _mediaType,
                onChanged: (v) => setState(() => _mediaType = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTileHeader(title: l10n.commonTags),
              TagInput(
                controller: _includeController,
                autofocus: false,
                cutoutForFab: false,
                labelText: l10n.feedsIncludeTags,
                decoration: InputDecoration(
                  hintText: l10n.feedsIncludeTagsHint,
                  border: _roundedInputBorder,
                ),
              ),
              const SizedBox(height: 8),
              TagInput(
                controller: _orController,
                autofocus: false,
                cutoutForFab: false,
                labelText: l10n.feedsOrTags,
                decoration: InputDecoration(
                  hintText: l10n.feedsOrTagsHint,
                  border: _roundedInputBorder,
                ),
              ),
              const SizedBox(height: 8),
              TagInput(
                controller: _excludeController,
                autofocus: false,
                cutoutForFab: false,
                labelText: l10n.feedsExcludeTags,
                decoration: InputDecoration(
                  hintText: l10n.feedsExcludeTagsHint,
                  border: _roundedInputBorder,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTileHeader(title: l10n.feedsSubfeeds),
              Text(
                l10n.feedsSubfeedsHelper,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_subfeeds.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubfeedEditCard(
                    key: ValueKey(_subfeeds[i].id),
                    subfeed: _subfeeds[i],
                    onChanged: (s) => setState(() {
                      _subfeeds = List.from(_subfeeds)..[i] = s;
                    }),
                    onDelete: () => setState(() {
                      _subfeeds = List.from(_subfeeds)..removeAt(i);
                    }),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() {
                    _subfeeds = [
                      ..._subfeeds,
                      SubFeed(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: '',
                        includeTags: [],
                        excludeTags: [],
                      ),
                    ];
                  }),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 18),
                      const SizedBox(width: 6),
                      Text(l10n.feedsAddSubfeed),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTileHeader(title: l10n.commonRating),
              SegmentedButton<String?>(
                segments: [
                  ButtonSegment(value: null, label: Text(l10n.commonRatingAll)),
                  ButtonSegment(value: 's', label: Text(l10n.commonRatingSafe)),
                  ButtonSegment(value: 'q', label: Text(l10n.commonRatingQ)),
                  ButtonSegment(value: 'e', label: Text(l10n.commonRatingE)),
                ],
                selected: {_rating},
                onSelectionChanged: (s) => setState(() => _rating = s.first),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _order,
                decoration: InputDecoration(
                  labelText: l10n.commonSort,
                  border: _roundedInputBorder,
                ),
                items: [
                  DropdownMenuItem(value: 'id_desc', child: Text(l10n.commonSortNewestFirst)),
                  DropdownMenuItem(value: 'id_asc', child: Text(l10n.commonSortOldestFirst)),
                  DropdownMenuItem(value: 'score', child: Text(l10n.commonScore)),
                  DropdownMenuItem(value: 'favcount', child: Text(l10n.commonSortFavCount)),
                ],
                onChanged: (v) => setState(() => _order = v ?? _order),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.feedsExcludeFavorited),
                        const SizedBox(height: 2),
                        Text(
                          l10n.feedsExcludeFavoritedHelper,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: _excludeFavorites,
                    onChanged: (v) => setState(() => _excludeFavorites = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_embedded) ...[
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: _save,
            child: Text(l10n.commonSave),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_embedded) {
      return _buildForm(context);
    }
    return Scaffold(
      appBar: DefaultAppBar(
        title: Text(_isNew ? l10n.feedsNewFeedTitle : l10n.feedsEditFeedTitle),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _save, minimumSize: Size(0, 0),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
      body: _buildForm(context),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOled = theme.scaffoldBackgroundColor == Colors.black;

    if (isOled) {
      return GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: child,
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _SubfeedEditCard extends StatefulWidget {
  const _SubfeedEditCard({
    super.key,
    required this.subfeed,
    required this.onChanged,
    required this.onDelete,
  });

  final SubFeed subfeed;
  final ValueChanged<SubFeed> onChanged;
  final VoidCallback onDelete;

  @override
  State<_SubfeedEditCard> createState() => _SubfeedEditCardState();
}

class _SubfeedEditCardState extends State<_SubfeedEditCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _includeController;
  late final TextEditingController _excludeController;

  static List<String> _parseTags(String text) {
    if (text.trim().isEmpty) return [];
    return text
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _notifyChanged() => widget.onChanged(_currentSubfeed());

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subfeed.name);
    _includeController = TextEditingController(text: widget.subfeed.includeTags.join(' '));
    _excludeController = TextEditingController(text: widget.subfeed.excludeTags.join(' '));
    _nameController.addListener(_notifyChanged);
    _includeController.addListener(_notifyChanged);
    _excludeController.addListener(_notifyChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_notifyChanged);
    _includeController.removeListener(_notifyChanged);
    _excludeController.removeListener(_notifyChanged);
    _nameController.dispose();
    _includeController.dispose();
    _excludeController.dispose();
    super.dispose();
  }

  SubFeed _currentSubfeed({List<SubFeed>? subfeeds}) {
    return SubFeed(
      id: widget.subfeed.id,
      name: _nameController.text.trim(),
      includeTags: _parseTags(_includeController.text),
      excludeTags: _parseTags(_excludeController.text),
      subfeeds: subfeeds ?? widget.subfeed.subfeeds,
    );
  }

  void _updateChild(int i, SubFeed s) {
    widget.onChanged(SubFeed(
      id: widget.subfeed.id,
      name: _nameController.text.trim(),
      includeTags: _parseTags(_includeController.text),
      excludeTags: _parseTags(_excludeController.text),
      subfeeds: List.from(widget.subfeed.subfeeds)..[i] = s,
    ));
  }

  void _removeChild(int i) {
    widget.onChanged(SubFeed(
      id: widget.subfeed.id,
      name: _nameController.text.trim(),
      includeTags: _parseTags(_includeController.text),
      excludeTags: _parseTags(_excludeController.text),
      subfeeds: List.from(widget.subfeed.subfeeds)..removeAt(i),
    ));
  }

  void _addChild() {
    widget.onChanged(SubFeed(
      id: widget.subfeed.id,
      name: _nameController.text.trim(),
      includeTags: _parseTags(_includeController.text),
      excludeTags: _parseTags(_excludeController.text),
      subfeeds: [
        ...widget.subfeed.subfeeds,
        SubFeed(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '',
          includeTags: [],
          excludeTags: [],
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isOled = theme.scaffoldBackgroundColor == Colors.black;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.feedsSubfeedName,
                    border: _roundedInputBorder,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTileHeader(title: l10n.feedsExtraIncludeTags),
          TagInput(
            controller: _includeController,
            autofocus: false,
            cutoutForFab: false,
            labelText: l10n.feedsExtraIncludeTagsLabel,
            decoration: const InputDecoration(border: _roundedInputBorder),
          ),
          const SizedBox(height: 8),
          ListTileHeader(title: l10n.feedsExtraExcludeTags),
          TagInput(
            controller: _excludeController,
            autofocus: false,
            cutoutForFab: false,
            labelText: l10n.feedsExtraExcludeTagsLabel,
            decoration: const InputDecoration(border: _roundedInputBorder),
          ),
          if (widget.subfeed.subfeeds.isNotEmpty) ...[
            const SizedBox(height: 12),
            ListTileHeader(title: l10n.feedsSubfeeds),
            ...List.generate(widget.subfeed.subfeeds.length, (i) {
              return _SubfeedEditCard(
                key: ValueKey(widget.subfeed.subfeeds[i].id),
                subfeed: widget.subfeed.subfeeds[i],
                onChanged: (s) => _updateChild(i, s),
                onDelete: () => _removeChild(i),
              );
            }),
            const SizedBox(height: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _addChild,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 18),
                  const SizedBox(width: 6),
                  Text(l10n.feedsAddSubfeed),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _addChild,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 18),
                  const SizedBox(width: 6),
                  Text(l10n.feedsAddSubfeed),
                ],
              ),
            ),
          ],
      ],
    );

    if (isOled) {
      return GlassCard(
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.all(12),
        borderRadius: 12,
        child: content,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: content,
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;

    final baseBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final containerBg = baseBg;
    final activeFg = colorScheme.onPrimary;
    final inactiveFg = colorScheme.onSurfaceVariant;

    Widget buildSegment({
      required String type,
      required IconData icon,
      required String label,
      BorderRadius? radius,
    }) {
      final selected = value == type;
      final fg = selected ? activeFg : inactiveFg;

      return Expanded(
        child: InkWell(
          borderRadius: radius,
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected ? colorScheme.primary : Colors.transparent,
              borderRadius: radius,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget divider() => Container(
          width: 1,
          height: 28,
          color: colorScheme.onSurface.withValues(alpha: 0.18),
        );

    return Container(
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          buildSegment(
            type: Feed.mediaTypeImage,
            icon: Icons.image,
            label: l10n.feedImage,
            radius: const BorderRadius.horizontal(left: Radius.circular(12)),
          ),
          divider(),
          buildSegment(
            type: Feed.mediaTypeVideo,
            icon: Icons.videocam,
            label: l10n.feedVideo,
          ),
          divider(),
          buildSegment(
            type: Feed.mediaTypeAll,
            icon: Icons.collections,
            label: l10n.feedImageAndVideo,
            radius: const BorderRadius.horizontal(right: Radius.circular(12)),
          ),
        ],
      ),
    );
  }
}
