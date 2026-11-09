import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gestura_ui/src/theme/gestura_color_schemes.dart';
import 'package:gestura_ui/src/theme/gestura_colors.dart';
import 'package:gestura_ui/src/theme/gestura_sizes.dart';
import 'package:gestura_ui/src/theme/gestura_text_styles.dart';
import 'package:gestura_ui/src/theme/gestura_typography.dart';
import 'package:gestura_ui/src/tokens/gestura_scale.dart';

abstract final class GesturaTheme {
  static const Size buttonMinimumSize = Size(64, 52);
  static const double iconSize = 24;
  static const double chipIconSize = 18;

  static final Map<(Brightness, GesturaScale), ThemeData> _cache = {};

  static ThemeData light({GesturaScale scale = GesturaScale.identity}) =>
      forBrightness(Brightness.light, scale: scale);

  static ThemeData dark({GesturaScale scale = GesturaScale.identity}) =>
      forBrightness(Brightness.dark, scale: scale);

  static ThemeData forBrightness(
    Brightness brightness, {
    GesturaScale scale = GesturaScale.identity,
  }) => _cache.putIfAbsent(
    (brightness, scale),
    () => switch (brightness) {
      Brightness.light => _build(
        GesturaColorSchemes.light,
        GesturaColors.light,
        scale,
      ),
      Brightness.dark => _build(
        GesturaColorSchemes.dark,
        GesturaColors.dark,
        scale,
      ),
    },
  );

  static ThemeData _build(
    ColorScheme scheme,
    GesturaColors colors,
    GesturaScale scale,
  ) {
    final sizes = GesturaSizes(scale: scale);
    final base = ThemeData(
      colorScheme: scheme,
      fontFamily: GesturaFonts.family,
      fontFamilyFallback: GesturaFonts.fallback,
      textTheme: GesturaTypography.textTheme.apply(fontSizeFactor: scale.text),
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconTheme: IconThemeData(
        color: scheme.onSurface,
        size: sizes.icon(iconSize),
      ),
      extensions: [colors, _textStyles(scheme, scale), sizes],
    );
    final text = base.textTheme;
    const pill = StadiumBorder();
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(sizes.radiusMd),
    );
    final buttonSize = Size(
      sizes.scaled(buttonMinimumSize.width),
      sizes.atLeastTapTarget(buttonMinimumSize.height),
    );
    final buttonPadding = EdgeInsetsDirectional.symmetric(
      horizontal: sizes.lg,
      vertical: sizes.sm,
    );
    final tapTarget = Size.square(sizes.tapTarget);

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: pill,
          textStyle: text.labelLarge,
          padding: buttonPadding,
          iconSize: sizes.icon(GesturaTheme.iconSize - 4),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: pill,
          textStyle: text.labelLarge,
          side: BorderSide(color: scheme.outline),
          padding: buttonPadding,
          iconSize: sizes.icon(GesturaTheme.iconSize - 4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: tapTarget,
          shape: pill,
          textStyle: text.labelLarge,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: sizes.md,
            vertical: sizes.sm,
          ),
          iconSize: sizes.icon(GesturaTheme.iconSize - 4),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: tapTarget,
          iconSize: sizes.icon(iconSize),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sizes.radiusLg),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: pill,
        side: BorderSide.none,
        showCheckmark: true,
        checkmarkColor: scheme.onPrimaryContainer,
        color: WidgetStateProperty.resolveWith(
          (states) => switch (states) {
            final s when s.contains(WidgetState.disabled) =>
              scheme.onSurface.withValues(alpha: 0.12),
            final s when s.contains(WidgetState.selected) =>
              scheme.primaryContainer,
            _ => scheme.surfaceContainerHigh,
          },
        ),
        labelStyle: text.labelMedium?.copyWith(
          color: WidgetStateColor.resolveWith(
            (states) => switch (states) {
              final s when s.contains(WidgetState.disabled) =>
                scheme.onSurface.withValues(alpha: 0.38),
              final s when s.contains(WidgetState.selected) =>
                scheme.onPrimaryContainer,
              _ => scheme.onSurface,
            },
          ),
        ),
        iconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: sizes.icon(chipIconSize),
        ),
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: sizes.xs,
          vertical: sizes.xxs,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: sizes.md,
          vertical: sizes.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(sizes.radiusMd),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(sizes.radiusMd),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(sizes.radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(sizes.radiusMd),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sizes.radiusXl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sizes.radiusXl),
        ),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: rounded,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(size: sizes.icon(iconSize)),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        selectedLabelTextStyle: text.labelMedium,
        unselectedLabelTextStyle: text.labelMedium,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsetsDirectional.symmetric(horizontal: sizes.md),
        minTileHeight: math.max(sizes.tapTarget + sizes.xs, sizes.scaled(56)),
        titleTextStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        shape: rounded,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(sizes.radiusLg),
        ),
      ),
    );
  }

  static GesturaTextStyles _textStyles(ColorScheme scheme, GesturaScale scale) {
    final gloss = GesturaTextStyles.standard.gloss;
    return GesturaTextStyles(
      gloss: gloss.copyWith(
        fontSize: gloss.fontSize! * scale.text,
        color: scheme.onSurface,
        fontFamily: GesturaFonts.family,
        fontFamilyFallback: GesturaFonts.fallback,
      ),
    );
  }
}
