part of '../settings.dart';

Widget buildSecuritySection(BuildContext context, Settings settings) {
  final l10n = AppLocalizations.of(context);
  return SettingsSection(
    title: l10n.settingsSectionSecurity,
    child: SettingsGroupCard(
      children: [
        if (PlatformCapabilities.hasSecureDisplay)
          ValueListenableBuilder<bool>(
            valueListenable: settings.secureDisplay,
            builder: (context, value, _) => SettingsSwitchTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.rectangle_on_rectangle_angled,
                color: Color(0xFFE67E22),
              ),
              title: l10n.settingsSecureDisplay,
              subtitle: value ? l10n.settingsScreenProtected : l10n.settingsScreenVisible,
              value: value,
              onChanged: (v) => settings.secureDisplay.value = v,
            ),
          ),
        if (Platform.isAndroid)
          ValueListenableBuilder<bool>(
            valueListenable: settings.incognitoKeyboard,
            builder: (context, value, _) => SettingsSwitchTile(
              leading: const SettingsLeadingIcon(
                icon: CupertinoIcons.keyboard,
                color: Color(0xFF7F8C8D),
              ),
              title: l10n.settingsIncognitoKeyboard,
              subtitle: value ? l10n.commonEnabled : l10n.commonDisabled,
              value: value,
              onChanged: (v) => settings.incognitoKeyboard.value = v,
            ),
          ),
        ValueListenableBuilder<bool>(
          valueListenable: settings.allowHttpHosts,
          builder: (context, value, _) => SettingsSwitchTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.globe,
              color: Color(0xFF95A5A6),
            ),
            title: l10n.settingsAllowHttpHosts,
            subtitle: value
                ? l10n.settingsAllowHttpDesc
                : l10n.settingsHttpsOnly,
            value: value,
            onChanged: (v) => settings.allowHttpHosts.value = v,
          ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: settings.appPin,
          builder: (context, value, _) => SettingsSwitchTile(
            leading: const SettingsLeadingIcon(
              icon: CupertinoIcons.lock,
              color: Color(0xFF34495E),
            ),
            title: l10n.settingsPinLock,
            subtitle: value != null ? l10n.settingsPinEnabled : l10n.settingsPinDisabled,
            value: value != null,
            onChanged: (enabled) async {
              if (enabled) {
                final pin = await registerPin(context);
                if (pin != null) settings.appPin.value = pin;
              } else {
                settings.appPin.value = null;
              }
            },
          ),
        ),
        if (PlatformCapabilities.supportsBiometrics)
          SubFuture<bool>(
            create: () => LocalAuthentication().getAvailableBiometrics().then(
              (e) => e.isNotEmpty,
            ),
            builder: (context, snapshot) => ValueListenableBuilder<bool>(
              valueListenable: settings.biometricAuth,
              builder: (context, value, _) => SettingsSwitchTile(
                leading: const SettingsLeadingIcon(
                  icon: CupertinoIcons.hand_raised,
                  color: Color(0xFF16A085),
                ),
                title: l10n.settingsBiometricLock,
                subtitle: value
                    ? l10n.settingsBiometricsEnabled
                    : l10n.settingsBiometricsDisabled,
                value: value,
                onChanged: (snapshot.data ?? false)
                    ? (v) => settings.biometricAuth.value = v
                    : null,
              ),
            ),
          ),
      ],
    ),
  );
}
