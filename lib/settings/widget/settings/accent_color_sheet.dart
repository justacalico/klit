part of '../settings.dart';

void showAccentColorSheet(BuildContext context, Settings settings, List<Color> accentPresets) {
  final l10n = AppLocalizations.of(context);
  var selected = colorFromHex(settings.accentColorHex.value);

  final presets = <({Color color, String name})>[
    (color: accentPresets[0], name: l10n.settingsAccentPresetDefault),
    (color: accentPresets[1], name: l10n.settingsAccentPresetPink),
    (color: accentPresets[2], name: l10n.settingsAccentPresetRed),
    (color: accentPresets[3], name: l10n.settingsAccentPresetPurple),
    (color: accentPresets[4], name: l10n.settingsAccentPresetIndigo),
    (color: accentPresets[5], name: l10n.settingsAccentPresetBlue),
    (color: accentPresets[6], name: l10n.settingsAccentPresetTeal),
    (color: accentPresets[7], name: l10n.settingsAccentPresetGreen),
  ];

  showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.settingsAccentColor,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected,
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.settingsAccentPreset,
                    border: const OutlineInputBorder(),
                  ),
                  child: DropdownButton<Color>(
                    value: accentPresets
                            .where((c) => hexFromColor(c) == hexFromColor(selected))
                            .firstOrNull,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: Text(l10n.settingsAccentPresetDefault),
                    items: presets.map((preset) {
                      return DropdownMenuItem<Color>(
                        value: preset.color,
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: preset.color,
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(preset.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      HapticFeedback.selectionClick();
                      setSheetState(() => selected = value);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ColorPicker(
                  pickerColor: selected,
                  onColorChanged: (value) {
                    setSheetState(() => selected = value.withAlpha(255));
                  },
                  paletteType: PaletteType.hueWheel,
                  enableAlpha: false,
                  portraitOnly: true,
                  labelTypes: const [],
                  pickerAreaBorderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        settings.accentColorHex.value =
                            defaultAccentColorHex;
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.commonReset),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.commonCancel),
                    ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        settings.accentColorHex.value = hexFromColor(
                          selected,
                        );
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
}
