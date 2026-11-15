import 'package:flutter/material.dart';
import 'package:gestura/features/settings/domain/app_settings.dart';
import 'package:gestura/features/settings/presentation/settings_presentation.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

Future<AppLanguage?> showLanguageSheet(
  BuildContext context, {
  required AppLanguage current,
}) => showModalBottomSheet<AppLanguage>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => LanguageSheet(current: current),
);

class LanguageSheet extends StatelessWidget {
  const new({required this.current, super.key});

  final AppLanguage current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final padding = EdgeInsetsDirectional.symmetric(
      horizontal: context.windowSizeClass.screenPadding,
    );
    return SafeArea(
      child: RadioGroup<AppLanguage>(
        groupValue: current,
        onChanged: (language) => Navigator.of(context).pop(language),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsetsDirectional.only(bottom: context.gSizes.md),
          children: [
            Padding(
              padding: padding,
              child: Semantics(
                header: true,
                child: Text(
                  l10n.settingsLanguage,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            for (final language in AppLanguage.values)
              RadioListTile<AppLanguage>(
                value: language,
                contentPadding: padding,
                controlAffinity: ListTileControlAffinity.trailing,
                title: Text(language.label(l10n)),
              ),
          ],
        ),
      ),
    );
  }
}
