import 'package:flutter/material.dart';
import 'package:gestura_ui/src/theme/gestura_colors.dart';
import 'package:gestura_ui/src/theme/gestura_sizes.dart';
import 'package:gestura_ui/src/theme/gestura_text_styles.dart';
import 'package:gestura_ui/src/tokens/window_size_class.dart';

extension GesturaThemeContext on BuildContext {
  GesturaColors get gColors {
    final theme = Theme.of(this);
    return theme.extension<GesturaColors>() ??
        switch (theme.brightness) {
          Brightness.light => GesturaColors.light,
          Brightness.dark => GesturaColors.dark,
        };
  }

  GesturaTextStyles get gTextStyles =>
      Theme.of(this).extension<GesturaTextStyles>() ??
      GesturaTextStyles.standard;

  GesturaSizes get gSizes =>
      Theme.of(this).extension<GesturaSizes>() ?? GesturaSizes.standard;

  WindowSizeClass get windowSizeClass => WindowSizeClass.of(this);
}
