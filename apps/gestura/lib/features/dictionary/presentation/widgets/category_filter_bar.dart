import 'package:flutter/material.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class CategoryFilterBar extends StatelessWidget {
  const new({
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.padding,
    super.key,
  });

  final List<SignCategory> categories;
  final CategoryId? selected;
  final ValueChanged<CategoryId?> onSelected;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final sizes = context.gSizes;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsetsDirectional.symmetric(horizontal: padding),
      child: Row(
        children: [
          GChip(
            label: context.l10n.categoryAll,
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final category in categories) ...[
            SizedBox(width: sizes.xs),
            GChip(
              label: category.name.of(context),
              selected: selected == category.id,
              onSelected: (isSelected) =>
                  onSelected(isSelected ? category.id : null),
            ),
          ],
        ],
      ),
    );
  }
}
