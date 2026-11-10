import 'package:flutter/material.dart';
import 'package:gestura/features/lesson/presentation/view_models/lesson_player_state.dart';
import 'package:gestura_ui/gestura_ui.dart';

class ChoiceTile extends StatelessWidget {
  const new({
    required this.mark,
    required this.onTap,
    required this.child,
    required this.semanticLabel,
    super.key,
    this.padding,
    this.markOnTop = false,
  });

  static const double markIconSize = 20;

  final OptionMark mark;
  final VoidCallback? onTap;
  final Widget child;
  final String semanticLabel;
  final EdgeInsetsGeometry? padding;
  final bool markOnTop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.gColors;
    final sizes = context.gSizes;
    final (background, foreground, border) = switch (mark) {
      OptionMark.none => (
        scheme.surfaceContainerLow,
        scheme.onSurface,
        scheme.outlineVariant,
      ),
      OptionMark.selected => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        scheme.primary,
      ),
      OptionMark.correct => (
        colors.successContainer,
        colors.onSuccessContainer,
        colors.success,
      ),
      OptionMark.wrong => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        scheme.error,
      ),
    };
    final icon = switch (mark) {
      OptionMark.correct => Icons.check_circle_rounded,
      OptionMark.wrong => Icons.cancel_rounded,
      OptionMark.none || OptionMark.selected => null,
    };
    final radius = BorderRadius.circular(sizes.radiusMd);

    return Semantics(
      button: true,
      selected: mark == OptionMark.selected,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: border,
            width: mark == OptionMark.none ? 1 : sizes.scaled(2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: sizes.tapTarget),
            child: Padding(
              padding: padding ?? EdgeInsetsDirectional.all(sizes.sm),
              child: IconTheme.merge(
                data: IconThemeData(color: foreground),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: foreground),
                  child: markOnTop
                      ? Stack(
                          children: [
                            child,
                            if (icon != null)
                              PositionedDirectional(
                                top: sizes.xxs,
                                end: sizes.xxs,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: background,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    size: sizes.icon(markIconSize),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: child),
                            if (icon != null) ...[
                              SizedBox(width: sizes.xs),
                              Icon(icon, size: sizes.icon(markIconSize)),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
