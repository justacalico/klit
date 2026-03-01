import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

String _hostLabel(String url) {
  final u = url.trim();
  if (u.endsWith('/')) return _hostLabel(u.substring(0, u.length - 1));
  final uri = Uri.tryParse(u);
  if (uri != null && uri.host.isNotEmpty) return uri.host;
  return u;
}

/// One source (host) row: checkbox, host label, and account used.
Widget _buildSourceRow({
  required String hostUrl,
  required bool selected,
  required bool isDark,
  required bool isOled,
  required VoidCallback onTap,
  required Account? accountForHost,
}) {
  final bg = AppColors.resolveSecondaryBackground(isDark, isOled: isOled);
  final borderColor = (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.08);
  final accountLabel = accountForHost != null ? accountForHost.username : 'Guest';
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              selected ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
              size: 24,
              color: selected ? UIColors.primaryPurple : CupertinoColors.systemGrey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _hostLabel(hostUrl),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Account: $accountLabel',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? CupertinoColors.white.withValues(alpha: 0.8)
                          : CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Wraps a section with a rounded card background for visual grouping.
Widget _sectionCard({
  required BuildContext context,
  required bool isDark,
  required bool isOled,
  required String title,
  required List<Widget> children,
}) {
  final bg = AppColors.resolveSecondaryBackground(isDark, isOled: isOled);
  final borderColor = (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.08);
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

/// Parse tag string (newlines or spaces) into a list of non-empty trimmed tags.
List<String> _parseTags(String text) {
  if (text.trim().isEmpty) return [];
  return text
      .split(RegExp(r'[\s\n]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Feed create/edit page: name, type (image/video), and/or/exclude tags.
/// When [onComplete] is set (e.g. when embedded in Feeds tab), calls it instead of popping.
class FeedEditPage extends StatefulWidget {
  final Feed? feed;
  final VoidCallback? onComplete;

  const FeedEditPage({super.key, this.feed, this.onComplete});

  @override
  State<FeedEditPage> createState() => _FeedEditPageState();
}

class _FeedEditPageState extends State<FeedEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _includeController;
  late TextEditingController _orController;
  late TextEditingController _excludeController;
  late String _mediaType;
  String? _rating;
  late String _order;
  bool _excludeFavorites = false;
  List<SubFeed> _subfeeds = [];
  bool _isNew = true;
  final Set<String> _selectedHostUrls = {};

  static const Map<String, String> _orderOptions = {
    'id_desc': 'Newest',
    'id_asc': 'Oldest',
    'score': 'Score',
    'favcount': 'Favorites',
  };

  static String _normalizeHost(String h) {
    var s = h.trim();
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  @override
  void initState() {
    super.initState();
    final f = widget.feed;
    _isNew = f == null;
    _nameController = TextEditingController(text: f?.name ?? '');
    _includeController = TextEditingController(
      text: f?.includeTags.join(' ') ?? '',
    );
    _orController = TextEditingController(
      text: f?.orTags.join(' ') ?? '',
    );
    _excludeController = TextEditingController(
      text: f?.excludeTags.join(' ') ?? '',
    );
    _mediaType = f?.mediaType ?? Feed.mediaTypeImage;
    _rating = f?.rating;
    _order = f?.order ?? 'id_desc';
    _excludeFavorites = f?.excludeFavorites ?? false;
    _subfeeds = f?.subfeeds != null ? List.from(f!.subfeeds) : [];
    if (f?.hostUrls != null) {
      _selectedHostUrls.addAll(f!.hostUrls.map(_normalizeHost));
    }
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
    final name = _nameController.text.trim();
    final includeTags = _parseTags(_includeController.text);
    final orTags = _parseTags(_orController.text);
    final excludeTags = _parseTags(_excludeController.text);
    final hostUrls = _selectedHostUrls.toList()..sort();

    final feedsProvider = context.read<FeedsProvider>();
    if (_isNew) {
      final feed = Feed(
        id: '',
        name: name.isEmpty ? 'Unnamed feed' : name,
        mediaType: _mediaType,
        includeTags: includeTags,
        orTags: orTags,
        excludeTags: excludeTags,
        hostUrls: hostUrls,
        rating: _rating,
        order: _order,
        excludeFavorites: _excludeFavorites,
        subfeeds: _subfeeds,
      );
      await feedsProvider.addFeed(feed);
    } else {
      final existing = widget.feed!;
      final feed = Feed(
        id: existing.id,
        name: name.isEmpty ? 'Unnamed feed' : name,
        mediaType: _mediaType,
        includeTags: includeTags,
        orTags: orTags,
        excludeTags: excludeTags,
        hostUrls: hostUrls,
        rating: _rating,
        order: _order,
        excludeFavorites: _excludeFavorites,
        subfeeds: _subfeeds,
      );
      await feedsProvider.updateFeed(feed);
    }

    if (mounted) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _cancel() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final isOled = context.watch<SettingsProvider>().themeMode == 3;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        middle: Text(_isNew ? 'New feed' : 'Edit feed'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _save,
          child: const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          children: [
            const SizedBox(height: 8),
            _sectionCard(
              context: context,
              isDark: isDark,
              isOled: isOled,
              title: 'Name',
              children: [
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'e.g. My art feed',
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                          .withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context: context,
              isDark: isDark,
              isOled: isOled,
              title: 'Type',
              children: [
                CupertinoSlidingSegmentedControl<String>(
              groupValue: _mediaType,
              children: {
                Feed.mediaTypeImage: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        CupertinoIcons.photo_fill,
                        size: 20,
                        color: _mediaType == Feed.mediaTypeImage
                            ? CupertinoColors.white
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Image',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _mediaType == Feed.mediaTypeImage
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Feed.mediaTypeVideo: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        CupertinoIcons.play_rectangle_fill,
                        size: 20,
                        color: _mediaType == Feed.mediaTypeVideo
                            ? CupertinoColors.white
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Video',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _mediaType == Feed.mediaTypeVideo
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Feed.mediaTypeAll: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        CupertinoIcons.rectangle_stack_fill,
                        size: 20,
                        color: _mediaType == Feed.mediaTypeAll
                            ? CupertinoColors.white
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Both',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _mediaType == Feed.mediaTypeAll
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              },
              onValueChanged: (v) {
                if (v != null) setState(() => _mediaType = v);
              },
            ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context: context,
              isDark: isDark,
              isOled: isOled,
              title: 'Rating & sort',
              children: [
                Text(
                  'Rating',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 6),
                CupertinoSlidingSegmentedControl<String>(
                  groupValue: _rating ?? 'all',
                  children: {
                    'all': Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: (_rating == null || _rating == 'all')
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                    's': Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Safe',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _rating == 's'
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                    'q': Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Q',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _rating == 'q'
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                    'e': Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'E',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _rating == 'e'
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (v) {
                    if (v != null) setState(() => _rating = v == 'all' ? null : v);
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  'Sort',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 6),
                CupertinoSlidingSegmentedControl<String>(
                  groupValue: _order,
                  children: {
                    for (final e in _orderOptions.entries)
                      e.key: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _order == e.key
                                ? CupertinoColors.white
                                : CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                  },
                  onValueChanged: (v) {
                    if (v != null) setState(() => _order = v);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.heart_slash,
                      size: 20,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Exclude my favorites',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Don\'t show posts you\'ve favorited in this feed',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
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
            const SizedBox(height: 16),
            _sectionCard(
              context: context,
              isDark: isDark,
              isOled: isOled,
              title: 'Subfeeds',
              children: [
                Text(
                  'Optional filters; only one can be active at a time when viewing the feed.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.8)
                        : CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_subfeeds.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SubfeedEditCard(
                      key: ValueKey(_subfeeds[i].id),
                      subfeed: _subfeeds[i],
                      isDark: isDark,
                      isOled: isOled,
                      onChanged: (s) {
                        setState(() {
                          _subfeeds = List.from(_subfeeds)..[i] = s;
                        });
                      },
                      onDelete: () {
                        setState(() {
                          _subfeeds = List.from(_subfeeds)..removeAt(i);
                        });
                      },
                    ),
                  );
                }),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _subfeeds = [
                        ..._subfeeds,
                        SubFeed(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: '',
                          includeTags: [],
                          excludeTags: [],
                        ),
                      ];
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.plus_circle_fill,
                        size: 20,
                        color: CupertinoColors.activeBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add subfeed',
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context: context,
              isDark: isDark,
              isOled: isOled,
              title: 'Sources',
              children: [
                Text(
                  'Choose which sites to load posts from. Leave empty for current host only.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? CupertinoColors.white.withValues(alpha: 0.8)
                        : CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 10),
                Builder(
              builder: (context) {
                final auth = context.watch<AuthProvider>();
                final hosts = <String>{
                  ApiConstants.defaultHost,
                  ApiConstants.nsfwHost,
                  ...auth.accounts.map((a) => _normalizeHost(a.host)),
                }.toList()..sort();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: hosts.map((url) {
                    final selected = _selectedHostUrls.contains(url);
                    final accountForHost = auth.getAccountForHost(url);
                    return _buildSourceRow(
                      hostUrl: url,
                      selected: selected,
                      isDark: isDark,
                      isOled: isOled,
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedHostUrls.remove(url);
                          } else {
                            _selectedHostUrls.add(url);
                          }
                        });
                      },
                      accountForHost: accountForHost,
                    );
                  }).toList(),
                );
              },
            ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context: context,
              isDark: isDark,
              isOled: isOled,
              title: 'Filter by tags',
              children: [
                Text(
                  'And tags',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 6),
                TagSuggestionField(
                  controller: _includeController,
                  placeholder: 'Post must have all of these (e.g. cat or fox)',
                  maxLines: 4,
                  decoration: BoxDecoration(
                    color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                          .withValues(alpha: 0.08),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Or tags',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 6),
                TagSuggestionField(
                  controller: _orController,
                  placeholder: 'Any of these (e.g. cat fox for cat or fox)',
                  maxLines: 4,
                  decoration: BoxDecoration(
                    color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                          .withValues(alpha: 0.08),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Tags to exclude',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 6),
                TagSuggestionField(
                  controller: _excludeController,
                  placeholder: 'e.g. cat when viewing fox to see only fox without cat',
                  maxLines: 4,
                  decoration: BoxDecoration(
                    color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isDark ? CupertinoColors.white : CupertinoColors.black)
                          .withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubfeedEditCard extends StatefulWidget {
  final SubFeed subfeed;
  final bool isDark;
  final bool isOled;
  final ValueChanged<SubFeed> onChanged;
  final VoidCallback onDelete;

  const _SubfeedEditCard({
    super.key,
    required this.subfeed,
    required this.isDark,
    required this.isOled,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_SubfeedEditCard> createState() => _SubfeedEditCardState();
}

class _SubfeedEditCardState extends State<_SubfeedEditCard> {
  late TextEditingController _nameController;
  late TextEditingController _includeController;
  late TextEditingController _excludeController;

  static List<String> _parseTags(String text) {
    if (text.trim().isEmpty) return [];
    return text
        .split(RegExp(r'[\s\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _notifyChanged() {
    widget.onChanged(SubFeed(
      id: widget.subfeed.id,
      name: _nameController.text.trim(),
      includeTags: _parseTags(_includeController.text),
      excludeTags: _parseTags(_excludeController.text),
    ));
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subfeed.name);
    _includeController = TextEditingController(
      text: widget.subfeed.includeTags.join(' '),
    );
    _excludeController = TextEditingController(
      text: widget.subfeed.excludeTags.join(' '),
    );
    _nameController.addListener(_notifyChanged);
    _includeController.addListener(_notifyChanged);
    _excludeController.addListener(_notifyChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _includeController.dispose();
    _excludeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isOled = widget.isOled;
    final borderColor = (isDark ? CupertinoColors.white : CupertinoColors.black)
        .withValues(alpha: 0.08);
    final bg = AppColors.resolveSecondaryBackground(isDark, isOled: isOled);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'Subfeed name',
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.resolveSecondaryBackground(isDark, isOled: isOled),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                onPressed: widget.onDelete,
                child: Icon(
                  CupertinoIcons.trash,
                  size: 20,
                  color: CupertinoColors.destructiveRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Extra include tags',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 4),
          TagSuggestionField(
            controller: _includeController,
            placeholder: 'Additional tags (all required)',
            maxLines: 2,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Extra exclude tags',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 4),
          TagSuggestionField(
            controller: _excludeController,
            placeholder: 'Tags to exclude in this subfeed',
            maxLines: 2,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
          ),
        ],
      ),
    );
  }
}
