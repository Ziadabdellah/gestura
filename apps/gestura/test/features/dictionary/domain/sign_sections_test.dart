import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/content/domain/sign.dart';
import 'package:gestura/features/dictionary/domain/sign_sections.dart';

import '../../../helpers/fake_content_repository.dart';

Sign _sign(String id) => demoCatalog.sign(SignId(id))!;

void main() {
  test('groups signs under the first letter of their gloss, A to Z', () {
    final sections = sectionsByInitial([
      _sign('sister'),
      _sign('family'),
      _sign('father'),
      _sign('sorry'),
    ]);

    expect(sections, [
      SignSection(initial: 'F', signs: [_sign('family'), _sign('father')]),
      SignSection(initial: 'S', signs: [_sign('sister'), _sign('sorry')]),
    ]);
  });

  test('has no sections without signs', () {
    expect(sectionsByInitial(const []), isEmpty);
  });

  test('compares sections by letter and signs', () {
    final section = SignSection(initial: 'H', signs: [_sign('hello')]);

    expect(section, SignSection(initial: 'H', signs: [_sign('hello')]));
    expect(
      section.hashCode,
      SignSection(initial: 'H', signs: [_sign('hello')]).hashCode,
    );
    expect(section, isNot(SignSection(initial: 'G', signs: [_sign('hello')])));
    expect(
      section,
      isNot(
        SignSection(initial: 'H', signs: [_sign('hello'), _sign('please')]),
      ),
    );
    expect(section, isNot(SignSection(initial: 'H', signs: [_sign('please')])));
  });
}
