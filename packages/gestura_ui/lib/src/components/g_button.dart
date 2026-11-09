import 'package:flutter/material.dart';
import 'package:gestura_ui/src/theme/gestura_theme_context.dart';
import 'package:gestura_ui/src/tokens/gestura_spacing.dart';

enum GButtonVariant { primary, secondary, text, destructive }

class GButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = GButtonVariant.primary;

  const new secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = GButtonVariant.secondary;

  const new text({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = GButtonVariant.text;

  const new destructive({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = GButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final GButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  static const double iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;
    final content = _GButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
    );
    final scheme = Theme.of(context).colorScheme;
    Color? whileLoading(Color color) => isLoading ? color : null;

    final button = switch (variant) {
      GButtonVariant.primary => FilledButton(
        onPressed: callback,
        style: FilledButton.styleFrom(
          disabledBackgroundColor: whileLoading(scheme.primary),
          disabledForegroundColor: whileLoading(scheme.onPrimary),
        ),
        child: content,
      ),
      GButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: whileLoading(scheme.primary),
        ),
        child: content,
      ),
      GButtonVariant.text => TextButton(
        onPressed: callback,
        style: TextButton.styleFrom(
          disabledForegroundColor: whileLoading(scheme.primary),
        ),
        child: content,
      ),
      GButtonVariant.destructive => FilledButton(
        onPressed: callback,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
          disabledBackgroundColor: whileLoading(scheme.error),
          disabledForegroundColor: whileLoading(scheme.onError),
        ),
        child: content,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _GButtonContent extends StatelessWidget {
  const new({required this.label, required this.icon, required this.isLoading});

  final String label;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final foreground = DefaultTextStyle.of(context).style.color;
    final sizes = context.gSizes;
    final iconSize = sizes.icon(GButton.iconSize);
    final leading = switch ((isLoading, icon)) {
      (true, _) => SizedBox.square(
        dimension: sizes.icon(GButton.iconSize - GesturaSpacing.xxs),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: foreground,
          backgroundColor: Colors.transparent,
        ),
      ),
      (false, final IconData data) => Icon(data, size: iconSize),
      (false, null) => null,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          ExcludeSemantics(child: leading),
          SizedBox(width: sizes.xs),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
  }
}
