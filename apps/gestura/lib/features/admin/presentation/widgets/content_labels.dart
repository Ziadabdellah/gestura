import 'package:flutter/material.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';
import 'package:gestura/l10n/l10n.dart';

extension ContentLabels on AppLocalizations {
  String kindLabel(ContentKind kind) => switch (kind) {
    ContentKind.signLanguages => adminKindSignLanguages,
    ContentKind.categories => adminKindCategories,
    ContentKind.signs => adminKindSigns,
    ContentKind.courses => adminKindCourses,
    ContentKind.lessons => adminKindLessons,
  };

  String fieldLabel(FieldName field) => switch (field) {
    FieldName.name => adminFieldName,
    FieldName.fingerspelling => adminFieldFingerspelling,
    FieldName.placeholder => adminFieldPlaceholder,
    FieldName.order => adminFieldOrder,
    FieldName.signLanguage => adminFieldSignLanguage,
    FieldName.gloss => adminFieldGloss,
    FieldName.meaning => adminFieldMeaning,
    FieldName.category => adminFieldCategory,
    FieldName.video => adminFieldVideo,
    FieldName.thumbnail => adminFieldThumbnail,
    FieldName.durationMs => adminFieldDuration,
    FieldName.sourceName => adminFieldSourceName,
    FieldName.sourceLicense => adminFieldSourceLicense,
    FieldName.sourceUrl => adminFieldSourceUrl,
    FieldName.level => adminFieldLevel,
    FieldName.title => adminFieldTitle,
    FieldName.units => adminFieldUnits,
    FieldName.courseId => adminFieldCourse,
    FieldName.unit => adminFieldUnit,
    FieldName.steps => adminFieldSteps,
  };

  String errorLabel(FieldError error) => switch (error) {
    FieldError.required => adminErrorRequired,
    FieldError.tooLong => adminErrorTooLong,
    FieldError.number => adminErrorNumber,
    FieldError.mediaPath => adminErrorMediaPath,
    FieldError.jsonList => adminErrorJsonList,
  };

  String languageLabel(String code) => switch (code) {
    'ar' => adminLanguageAr,
    'ru' => adminLanguageRu,
    'es' => adminLanguageEs,
    'fr' => adminLanguageFr,
    'de' => adminLanguageDe,
    _ => adminLanguageEn,
  };
}

IconData kindIcon(ContentKind kind) => switch (kind) {
  ContentKind.signLanguages => Icons.translate_rounded,
  ContentKind.categories => Icons.category_rounded,
  ContentKind.signs => Icons.sign_language_rounded,
  ContentKind.courses => Icons.school_rounded,
  ContentKind.lessons => Icons.menu_book_rounded,
};
