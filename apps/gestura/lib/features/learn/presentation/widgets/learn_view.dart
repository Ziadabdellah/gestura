import 'package:flutter/material.dart';
import 'package:gestura/core/widgets/failure_view.dart';
import 'package:gestura/core/widgets/list_skeleton.dart';
import 'package:gestura/core/widgets/placeholder_content_notice.dart';
import 'package:gestura/core/widgets/readable_inset.dart';
import 'package:gestura/features/learn/presentation/view_models/learn_state.dart';
import 'package:gestura/features/learn/presentation/widgets/course_header.dart';
import 'package:gestura/features/learn/presentation/widgets/unit_section.dart';
import 'package:gestura_ui/gestura_ui.dart';

class LearnView extends StatelessWidget {
  const new({required this.state, required this.onRetry, super.key});

  final LearnState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (state) {
    LearnLoading() => const ListSkeleton(),
    LearnFailed(:final failure) => FailureView(
      failure: failure,
      onRetry: onRetry,
    ),
    LearnLoaded(:final pack, :final course) => ReadableInset(
      minimum: context.windowSizeClass.screenPadding,
      builder: (context, inset) => ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          inset,
          context.gSizes.xs,
          inset,
          context.gSizes.xl,
        ),
        children: [
          if (pack.isPlaceholder) ...[
            const PlaceholderContentNotice(),
            SizedBox(height: context.gSizes.lg),
          ],
          CourseHeader(course: course, pack: pack),
          for (final unit in course.units)
            UnitSection(unit: unit, lessons: course.lessonsIn(unit.index)),
        ],
      ),
    ),
  };
}
