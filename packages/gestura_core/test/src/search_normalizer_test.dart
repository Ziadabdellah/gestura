import 'package:gestura_core/gestura_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeForSearch', () {
    test('removes Arabic diacritics and folds hamza and taa marbuta', () {
      expect(normalizeForSearch('إشارةٌ'), 'اشاره');
    });

    test('folds every alef form to a bare alef', () {
      expect(normalizeForSearch('أإآٱ'), 'اااا');
    });

    test('folds alef maqsura, hamza on waw and hamza on yaa', () {
      expect(normalizeForSearch('مستشفى مؤتمر قارئ'), 'مستشفي موتمر قاري');
    });

    test('removes tatweel and superscript alef', () {
      expect(normalizeForSearch('شـــكرا هٰذا'), 'شكرا هذا');
    });

    test('folds Arabic-Indic and Persian digits to Western digits', () {
      expect(normalizeForSearch('٣ ۱۲'), '3 12');
    });

    test('lowercases Latin and Cyrillic text', () {
      expect(normalizeForSearch('Thank YOU'), 'thank you');
      expect(normalizeForSearch('СПАСИБО'), 'спасибо');
    });

    test('folds Russian yo to ye', () {
      expect(normalizeForSearch('Ёлка ещё'), 'елка еще');
    });

    test('folds German sharp s to ss', () {
      expect(normalizeForSearch('Straße'), 'strasse');
    });

    test('keeps Latin accents for the search index to handle', () {
      expect(normalizeForSearch('Café Größe'), 'café grösse');
    });

    test('trims and collapses whitespace', () {
      expect(normalizeForSearch('  good \t  morning \n'), 'good morning');
    });

    test('returns an empty string for blank input', () {
      expect(normalizeForSearch('   '), isEmpty);
    });
  });
}
