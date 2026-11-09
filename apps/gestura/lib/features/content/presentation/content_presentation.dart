import 'package:flutter/widgets.dart';
import 'package:gestura/features/content/domain/course.dart';
import 'package:gestura/features/content/domain/localized_text.dart';

extension LocalizedTextPresentation on LocalizedText {
  String of(BuildContext context) =>
      resolve(Localizations.localeOf(context).languageCode);
}

extension CefrLevelPresentation on CefrLevel {
  String get label => name.toUpperCase();
}
