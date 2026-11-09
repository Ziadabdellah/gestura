import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class ListSkeleton extends StatelessWidget {
  const new({super.key, this.rows = defaultRows});

  static const int defaultRows = 6;
  static const Size leadingSize = Size(48, 60);
  static const double titleWidth = 160;
  static const double subtitleWidth = 96;

  final int rows;

  @override
  Widget build(BuildContext context) {
    final sizes = context.gSizes;
    final padding = context.windowSizeClass.screenPadding;

    return Semantics(
      container: true,
      label: context.l10n.loading,
      child: ReadableInset(
        minimum: padding,
        builder: (context, inset) => ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: inset,
            vertical: sizes.md,
          ),
          itemCount: rows,
          separatorBuilder: (context, index) => SizedBox(height: sizes.md),
          itemBuilder: (context, index) => Row(
            children: [
              GSkeleton(
                width: sizes.scaled(leadingSize.width),
                height: sizes.scaled(leadingSize.height),
              ),
              SizedBox(width: sizes.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GSkeleton(width: sizes.scaled(titleWidth)),
                  SizedBox(height: sizes.xs),
                  GSkeleton(width: sizes.scaled(subtitleWidth)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
