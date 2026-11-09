import 'package:flutter/material.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/settings_presentation.dart';
import 'package:gestura/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class SettingsView extends StatelessWidget {
  const new({
    required this.settings,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onReduceMotionChanged,
    super.key,
  });

  final AppSettings settings;
  final ValueChanged<AppThemePreference> onThemeChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<bool> onReduceMotionChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    final tilePadding = EdgeInsetsDirectional.symmetric(
      horizontal: context.windowSizeClass.screenPadding,
    );

    return ListView(
      padding: EdgeInsetsDirectional.only(bottom: sizes.lg),
      children: [
        SettingsSectionHeader(title: l10n.settingsTheme),
        RadioGroup<AppThemePreference>(
          groupValue: settings.theme,
          onChanged: (theme) {
            if (theme != null) onThemeChanged(theme);
          },
          child: Column(
            children: [
              for (final theme in AppThemePreference.values)
                RadioListTile<AppThemePreference>(
                  value: theme,
                  contentPadding: tilePadding,
                  controlAffinity: ListTileControlAffinity.trailing,
                  title: Text(theme.label(l10n)),
                  secondary: ExcludeSemantics(child: Icon(theme.icon)),
                ),
            ],
          ),
        ),
        SettingsSectionHeader(title: l10n.settingsLanguage),
        RadioGroup<AppLanguage>(
          groupValue: settings.language,
          onChanged: (language) {
            if (language != null) onLanguageChanged(language);
          },
          child: Column(
            children: [
              for (final language in AppLanguage.values)
                RadioListTile<AppLanguage>(
                  value: language,
                  contentPadding: tilePadding,
                  controlAffinity: ListTileControlAffinity.trailing,
                  title: Text(language.label(l10n)),
                ),
            ],
          ),
        ),
        SettingsSectionHeader(title: l10n.settingsAccessibility),
        SwitchListTile(
          value: settings.reduceMotion,
          onChanged: onReduceMotionChanged,
          contentPadding: tilePadding,
          title: Text(l10n.reduceMotionTitle),
          subtitle: Text(l10n.reduceMotionSubtitle),
        ),
      ],
    );
  }
}
