part of '../settings.dart';

Widget buildInteractionsSection(BuildContext context, Settings settings) {
  final l10n = AppLocalizations.of(context);
  return SettingsSection(
    title: l10n.settingsSectionInteractions,
    child: SettingsGroupCard(
      children: [
        if (!Platform.isIOS)
          ValueListenableBuilder<String?>(
            valueListenable: settings.downloadPath,
            builder: (context, value, _) => CupertinoListTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.folder,
                color: Color(0xFFF1C40F),
              ),
              title: Text(l10n.settingsDownloadLocation),
              subtitle: value != null
                  ? Text(Uri.decodeComponent(Uri.parse(value).path))
                  : Text(l10n.settingsChooseDirectory),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
              onTap: () async {
                HapticFeedback.selectionClick();
                final result = await FileDownloader.pickDirectory(
                  initial: value,
                );
                if (result != null) {
                  unawaited(FileDownloader.forgetDirectory(value));
                  settings.downloadPath.value = result;
                }
              },
            ),
          ),
        ValueListenableBuilder<bool>(
          valueListenable: settings.upvoteFavs,
          builder: (context, value, _) => SettingsSwitchTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.arrow_up,
              color: Color(0xFF27AE60),
            ),
            title: l10n.settingsUpvoteFavorites,
            subtitle: value ? l10n.settingsUpvoteAndFav : l10n.settingsFavOnly,
            value: value,
            onChanged: (v) => settings.upvoteFavs.value = v,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: settings.muteVideos,
          builder: (context, value, _) => SettingsSwitchTile(
            leading: SettingsLeadingIcon(
              icon: value
                  ? CupertinoIcons.speaker_slash
                  : CupertinoIcons.speaker_2,
              color: const Color(0xFF3498DB),
            ),
            title: l10n.settingsVideoVolume,
            subtitle: value ? l10n.settingsMuted : l10n.settingsWithSound,
            value: value,
            onChanged: (v) => settings.muteVideos.value = v,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: settings.autoplayVideos,
          builder: (context, value, _) => SettingsSwitchTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.play_circle,
              color: Color(0xFF9B59B6),
            ),
            title: l10n.settingsAutoplayVideos,
            subtitle: value ? l10n.settingsPlayAutomatically : l10n.settingsPlayOnTap,
            value: value,
            onChanged: (v) => settings.autoplayVideos.value = v,
          ),
        ),
        ValueListenableBuilder<VideoResolution>(
          valueListenable: settings.videoResolution,
          builder: (context, value, _) => CupertinoListTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.videocam,
              color: Color(0xFF2ECC71),
            ),
            title: Text(l10n.settingsVideoResolution),
            subtitle: Text(value.title),
            trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
            onTap: () {
              HapticFeedback.selectionClick();
              showPickerSheet<VideoResolution>(
                context,
                title: l10n.settingsVideoResolution,
                values: VideoResolution.values,
                current: value,
                labelOf: (resolution) => resolution.title,
                onSelected: (resolution) {
                  settings.videoResolution.value = resolution;
                },
              );
            },
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: settings.iFinishedEnabled,
          builder: (context, value, _) => SettingsSwitchTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.checkmark_circle,
              color: Color(0xFF1ABC9C),
            ),
            title: l10n.settingsIFinished,
            subtitle: value
                ? l10n.settingsIFinishedDesc
                : l10n.settingsIFinishedOff,
            value: value,
            onChanged: (v) => settings.iFinishedEnabled.value = v,
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: settings.iFinishedEnabled,
          builder: (context, enabled, _) {
            if (!enabled) return const SizedBox.shrink();
            return ValueListenableBuilder<bool>(
              valueListenable: settings.iFinishedRequestPhoto,
              builder: (context, value, _) => SettingsSwitchTile(
                leading: const SettingsLeadingIcon(
                  icon: CupertinoIcons.camera,
                  color: Color(0xFF9B59B6),
                ),
                title: l10n.settingsRequestPhoto,
                subtitle: value
                    ? l10n.settingsRequestPhotoDesc
                    : l10n.settingsRequestPhotoOff,
                value: value,
                onChanged: (v) => settings.iFinishedRequestPhoto.value = v,
              ),
            );
          },
        ),
      ],
    ),
  );
}
