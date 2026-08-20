part of '../settings.dart';

Widget buildAppearanceSection(BuildContext context, Settings settings, List<Color> accentPresets) {
  final l10n = AppLocalizations.of(context);
  return SettingsSection(
    title: l10n.settingsSectionAppearance,
    child: SettingsGroupCard(
      children: [
        ValueListenableBuilder<AppTheme>(
          valueListenable: settings.theme,
          builder: (context, value, _) => CupertinoListTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.sun_max,
              color: Color(0xFFF39C12),
            ),
            title: Text(l10n.settingsTheme),
            subtitle: Text(value.displayName),
            trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
            onTap: () {
              HapticFeedback.selectionClick();
              showPickerSheet<AppTheme>(
                context,
                title: l10n.settingsTheme,
                values: AppTheme.values,
                current: value,
                labelOf: (theme) => theme.displayName,
                trailingBuilder: (theme) => Container(
                  height: 20,
                  width: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.data.cardColor,
                    border: Border.all(
                      color: Theme.of(context).iconTheme.color!,
                    ),
                  ),
                ),
                onSelected: (theme) => settings.theme.value = theme,
              );
            },
          ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: settings.localeTag,
          builder: (context, tag, _) {
            final l10n = AppLocalizations.of(context);
            final current = switch (tag) {
              null || '' => _AppLocaleChoice.system,
              'en' => _AppLocaleChoice.en,
              'zh' => _AppLocaleChoice.zh,
              _ => _AppLocaleChoice.system,
            };

            String subtitleOf(_AppLocaleChoice choice) => switch (choice) {
              _AppLocaleChoice.system => l10n.settingsLanguageSystem,
              _AppLocaleChoice.en => l10n.settingsLanguageEnglish,
              _AppLocaleChoice.zh => l10n.settingsLanguageSimplifiedChinese,
            };

            return CupertinoListTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.globe,
                color: Color(0xFF95A5A6),
              ),
              title: Text(l10n.settingsLanguageTitle),
              subtitle: Text(subtitleOf(current)),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () {
                HapticFeedback.selectionClick();
                showPickerSheet<_AppLocaleChoice>(
                  context,
                  title: l10n.settingsLanguageTitle,
                  values: _AppLocaleChoice.values,
                  current: current,
                  labelOf: subtitleOf,
                  onSelected: (choice) {
                    settings.localeTag.value = switch (choice) {
                      _AppLocaleChoice.system => null,
                      _AppLocaleChoice.en => 'en',
                      _AppLocaleChoice.zh => 'zh',
                    };
                  },
                );
              },
            );
          },
        ),
        ValueListenableBuilder<String>(
          valueListenable: settings.accentColorHex,
          builder: (context, value, _) {
            final accent = colorFromHex(value);
            final hex = hexFromColor(accent);
            return CupertinoListTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.paintbrush,
                color: Color(0xFFEC6F91),
              ),
              title: Text(l10n.settingsAccentColor),
              subtitle: Text(hex),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.chevron_forward, size: 18),
                ],
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                showAccentColorSheet(context, settings, accentPresets);
              },
            );
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: settings.tileSize,
          builder: (context, value, _) => CupertinoListTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.square_grid_2x2,
              color: Color(0xFF8E44AD),
            ),
            title: Text(l10n.settingsTileSize),
            subtitle: Text(l10n.settingsTileSizeValue(value)),
            trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
            onTap: () {
              HapticFeedback.selectionClick();
              showCupertinoDialog<void>(
                context: context,
                builder: (context) => RangeDialog(
                  title: Text(l10n.settingsTileSize),
                  value: NumberRange(value),
                  initialMode: RangeDialogMode.exact,
                  enforceMax: false,
                  canChangeMode: false,
                  division: (300 / 50).round(),
                  min: 100,
                  max: 400,
                  onSubmit: (range) {
                    if (range == null || range.value <= 0) return;
                    settings.tileSize.value = range.value;
                  },
                ),
              );
            },
          ),
        ),
        ValueListenableBuilder<GridQuilt>(
          valueListenable: settings.quilt,
          builder: (context, value, _) => CupertinoListTile(
            leading: SettingsLeadingIcon(
              icon: value.icon,
              color: const Color(0xFF34495E),
            ),
            title: Text(l10n.settingsQuilt),
            subtitle: Text(value.description(context)),
            trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
            onTap: () {
              HapticFeedback.selectionClick();
              showPickerSheet<GridQuilt>(
                context,
                title: l10n.settingsGrid,
                values: GridQuilt.values,
                current: value,
                labelOf: (state) => state.description(context),
                trailingBuilder: (state) => Icon(state.icon),
                onSelected: (state) => settings.quilt.value = state,
              );
            },
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: settings.showPostInfo,
          builder: (context, value, _) => SettingsSwitchTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.doc_text,
              color: Color(0xFF2980B9),
            ),
            title: l10n.settingsPostInfo,
            subtitle: value ? l10n.settingsPostInfoOnTiles : l10n.settingsPostInfoImageOnly,
            value: value,
            onChanged: (v) => settings.showPostInfo.value = v,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: settings.popularHotTab,
          builder: (context, value, _) => SettingsSwitchTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.flame,
              color: Color(0xFFE67E22),
            ),
            title: l10n.settingsPopularHotTab,
            subtitle: l10n.settingsPopularHotTabSubtitle,
            value: value,
            onChanged: (v) => settings.popularHotTab.value = v,
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: settings.postActionBarActions,
          builder: (context, rawActions, _) {
            final actions = PostActionPreferences.decode(rawActions);
            return CupertinoListTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.square_stack_3d_down_right,
                color: Color(0xFF1ABC9C),
              ),
              title: Text(l10n.settingsPostActionBar),
              subtitle: Text(l10n.settingsActionsPinned(actions.length)),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () {
                HapticFeedback.selectionClick();
                showPostActionBarEditor(context, settings);
              },
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: settings.postActionBarFloatingMobile,
          builder: (context, value, _) => SettingsSwitchTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.rectangle_stack,
              color: Color(0xFF16A085),
            ),
            title: l10n.settingsActionBarPlacement,
            subtitle: value
                ? l10n.settingsPlacementFloating
                : l10n.settingsPlacementInline,
            value: value,
            onChanged: (enabled) =>
                settings.postActionBarFloatingMobile.value = enabled,
          ),
        ),
      ],
    ),
  );
}
