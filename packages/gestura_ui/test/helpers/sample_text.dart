import 'package:flutter/widgets.dart';

typedef SampleText = ({
  String primary,
  String secondary,
  String text,
  String destructive,
  String errorTitle,
  String errorMessage,
  String retry,
  String cardTitle,
  String cardSubtitle,
  List<String> chips,
  String tagline,
  String gloss,
});

const Map<String, SampleText> _samples = {
  'en': (
    primary: 'Continue',
    secondary: 'Review mistakes',
    text: 'Skip for now',
    destructive: 'Delete pack',
    errorTitle: 'Something went wrong',
    errorMessage: 'Check your connection and try again.',
    retry: 'Try again',
    cardTitle: 'Unit 2 · Family',
    cardSubtitle: 'Lesson 3 of 6',
    chips: ['Family', 'Food', 'Greetings'],
    tagline: 'Sign language, in your hands.',
    gloss: 'THANK-YOU',
  ),
  'ar': (
    primary: 'متابعة',
    secondary: 'مراجعة الأخطاء',
    text: 'تخطَّ الآن',
    destructive: 'حذف الحزمة',
    errorTitle: 'حدث خطأ ما',
    errorMessage: 'تحقّق من اتصالك وحاول مرة أخرى.',
    retry: 'حاول مرة أخرى',
    cardTitle: 'الوحدة 2 · العائلة',
    cardSubtitle: 'الدرس 3 من 6',
    chips: ['العائلة', 'الطعام', 'التحيات'],
    tagline: 'لغة الإشارة بين يديك.',
    gloss: 'THANK-YOU',
  ),
  'ru': (
    primary: 'Продолжить',
    secondary: 'Разобрать ошибки',
    text: 'Пропустить',
    destructive: 'Удалить пакет',
    errorTitle: 'Что-то пошло не так',
    errorMessage: 'Проверьте подключение и попробуйте ещё раз.',
    retry: 'Повторить',
    cardTitle: 'Раздел 2 · Семья',
    cardSubtitle: 'Урок 3 из 6',
    chips: ['Семья', 'Еда', 'Приветствия'],
    tagline: 'Язык жестов — в ваших руках.',
    gloss: 'THANK-YOU',
  ),
};

SampleText sampleTextFor(Locale locale) =>
    _samples[locale.languageCode] ?? _samples['en']!;
