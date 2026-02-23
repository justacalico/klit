import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';

String _hostLabel(String url) {
  final u = url.trim();
  if (u.endsWith('/')) return _hostLabel(u.substring(0, u.length - 1));
  final uri = Uri.tryParse(u);
  if (uri != null && uri.host.isNotEmpty) return uri.host;
  return u;
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
class FeedEditPage extends StatefulWidget {
  final Feed? feed;

  const FeedEditPage({super.key, this.feed});

  @override
  State<FeedEditPage> createState() => _FeedEditPageState();
}

class _FeedEditPageState extends State<FeedEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _includeController;
  late TextEditingController _orController;
  late TextEditingController _excludeController;
  late String _mediaType;
  bool _isNew = true;
  final Set<String> _selectedHostUrls = {};

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
      );
      await feedsProvider.updateFeed(feed);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final isOled = context.watch<SettingsProvider>().themeMode == 3;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const SizedBox(height: 8),
            Text(
              'Name',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 6),
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
            const SizedBox(height: 24),
            Text(
              'Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: _mediaType,
              children: {
                Feed.mediaTypeImage: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 24),
            Text(
              'Hosts',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 6),
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedHostUrls.remove(url);
                            } else {
                              _selectedHostUrls.add(url);
                            }
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Icon(
                              selected ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
                              size: 22,
                              color: selected
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.systemGrey,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _hostLabel(url),
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Leave empty to use current host only.',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'And tags',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _includeController,
              placeholder: 'Post must have all of these (e.g. cat or fox)',
              maxLines: 4,
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
            const SizedBox(height: 16),
            Text(
              'Or tags',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _orController,
              placeholder: 'Any of these (e.g. cat fox for cat or fox)',
              maxLines: 4,
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
            const SizedBox(height: 16),
            Text(
              'Tags to exclude',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _excludeController,
              placeholder: 'e.g. cat when viewing fox to see only fox without cat',
              maxLines: 4,
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
      ),
    );
  }
}
