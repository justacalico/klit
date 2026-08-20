part of '../settings.dart';

void showPostActionBarEditor(BuildContext context, Settings settings) {
  final l10n = AppLocalizations.of(context);
  final initial = PostActionPreferences.decode(
    settings.postActionBarActions.value,
  );
  final selected = <PostActionId>[...initial];

  showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final available = PostActionId.values
              .where((action) => !selected.contains(action))
              .toList();

          return SafeArea(
            top: false,
            child: GlassSurface(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 560),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                          child: Text(
                            l10n.settingsPostActionBar,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                          child: Text(
                            l10n.settingsPinnedActions,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: selected.length,
                          onReorderItem: (oldIndex, newIndex) {
                            setSheetState(() {
                              final action = selected.removeAt(oldIndex);
                              selected.insert(newIndex, action);
                            });
                          },
                          itemBuilder: (context, index) {
                            final action = selected[index];
                            return ListTile(
                              key: ValueKey(action.key),
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              leading: Icon(action.icon, size: 20),
                              title: Text(action.label),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setSheetState(() {
                                        selected.removeAt(index);
                                      });
                                      HapticFeedback.selectionClick();
                                    },
                                    icon: const Icon(
                                      CupertinoIcons.minus_circle,
                                    ),
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.line_horizontal_3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (available.isNotEmpty) const Divider(height: 20),
                        if (available.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Text(
                              l10n.settingsAvailable,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ...available.map((action) {
                          final iFinishedDisabled =
                              action == PostActionId.iFinished &&
                              !settings.iFinishedEnabled.value;
                          return CupertinoListTile(
                            leading: Icon(
                              action.icon,
                              size: 20,
                              color: iFinishedDisabled
                                  ? CupertinoColors.systemGrey
                                  : null,
                            ),
                            title: Text(
                              action.label,
                              style: iFinishedDisabled
                                  ? const TextStyle(
                                      color: CupertinoColors.systemGrey,
                                    )
                                  : null,
                            ),
                            trailing: Icon(
                              CupertinoIcons.plus_circle,
                              size: 20,
                              color: iFinishedDisabled
                                  ? CupertinoColors.systemGrey
                                  : null,
                            ),
                            onTap: iFinishedDisabled
                                ? null
                                : () {
                                    setSheetState(() {
                                      selected.add(action);
                                    });
                                    HapticFeedback.selectionClick();
                                  },
                          );
                        }),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(l10n.commonCancel),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                settings.postActionBarActions.value =
                                    PostActionPreferences.encode(selected);
                                HapticFeedback.selectionClick();
                                Navigator.of(context).pop();
                              },
                              child: Text(l10n.commonSave),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
