import 'package:flutter/material.dart';
import 'package:gestura_ui/gestura_ui.dart';

class OnboardingRadioTile<T> extends StatelessWidget {
  const new({
    required this.value,
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
  });

  final T value;
  final String title;
  final String? subtitle;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final sizes = context.gSizes;
    final scheme = Theme.of(context).colorScheme;
    final text = subtitle;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: sizes.sm),
      child: RadioListTile<T>(
        value: value,
        controlAffinity: ListTileControlAffinity.trailing,
        tileColor: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sizes.radiusLg),
        ),
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: sizes.md,
          vertical: sizes.xxs,
        ),
        secondary: icon,
        title: Text(title),
        subtitle: text == null ? null : Text(text),
      ),
    );
  }
}

class OnboardingSwitchTile extends StatelessWidget {
  const new({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final sizes = context.gSizes;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: sizes.sm),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sizes.radiusLg),
        ),
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: sizes.md,
          vertical: sizes.xxs,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class OnboardingHeading extends StatelessWidget {
  const new({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = context.gSizes;
    return Padding(
      padding: EdgeInsetsDirectional.only(top: sizes.md, bottom: sizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.headlineSmall),
          ),
          SizedBox(height: sizes.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
