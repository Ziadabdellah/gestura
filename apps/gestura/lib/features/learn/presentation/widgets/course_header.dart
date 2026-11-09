import 'package:flutter/material.dart';
import 'package:gestura/features/content/domain/content_catalog.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/presentation/content_presentation.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';

class CourseHeader extends StatelessWidget {
  const new({required this.course, required this.pack, super.key});

  final Course course;
  final SignLanguagePack pack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sizes = context.gSizes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            course.title.of(context),
            style: theme.textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: sizes.xs),
        Wrap(
          spacing: sizes.sm,
          runSpacing: sizes.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DecoratedBox(
              decoration: ShapeDecoration(
                color: scheme.primaryContainer,
                shape: const StadiumBorder(),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: sizes.sm,
                  vertical: sizes.xxs,
                ),
                child: Text(
                  context.l10n.courseLevel(course.level.label),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            Text(
              pack.name.of(context),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
