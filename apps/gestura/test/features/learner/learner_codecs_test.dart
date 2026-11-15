import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestura/features/activity/domain/daily_activity.dart';
import 'package:gestura/features/content/domain/content_ids.dart';
import 'package:gestura/features/learner/data/learner_codecs.dart';
import 'package:gestura/features/progress/domain/lesson_progress.dart';
import 'package:gestura/features/review/domain/review_card.dart';
import 'package:gestura_core/gestura_core.dart';

final DateTime _completed = DateTime.utc(2026, 11, 9, 8);
final DateTime _updated = DateTime.utc(2026, 11, 10, 9);
final Timestamp _time = Timestamp.fromDate(_completed);

void main() {
  group('ProgressCodec', () {
    const codec = ProgressCodec();
    final progress = LessonProgress(
      lessonId: const LessonId('l1'),
      bestScore: 80,
      completedAt: _completed,
      updatedAt: _updated,
    );

    test('writes the score with a server time', () {
      final document = codec.encode(progress);

      expect(codec.idOf(progress), 'l1');
      expect(document.id, 'l1');
      expect(document.data['bestScore'], 80);
      expect(document.data['completedAt'], _time);
      expect(document.data['updatedAt'], FieldValue.serverTimestamp());
    });

    test('reads a stored lesson and skips the rest', () {
      expect(
        codec.decode((
          id: 'l1',
          data: {
            'bestScore': 80,
            'completedAt': _time,
            'updatedAt': Timestamp.fromDate(_updated),
          },
        )),
        progress,
      );
      expect(codec.decode((id: 'l1', data: {'bestScore': 80})), isNull);
      for (final score in [-1, 101]) {
        expect(
          codec.decode((
            id: 'l1',
            data: {
              'bestScore': score,
              'completedAt': _time,
              'updatedAt': _time,
            },
          )),
          isNull,
        );
      }
    });
  });

  group('ReviewCardCodec', () {
    const codec = ReviewCardCodec();
    final card = ReviewCard(
      signId: const SignId('hello'),
      state: CardState(
        repetitions: 2,
        intervalDays: 6,
        ease: 2.6,
        dueAt: _completed,
        lapses: 1,
      ),
      updatedAt: _updated,
    );

    test('round-trips a card', () {
      final document = codec.encode(card);

      expect(codec.idOf(card), 'hello');
      expect(document.data, {
        'repetitions': 2,
        'intervalDays': 6,
        'ease': 2.6,
        'dueAt': _time,
        'lapses': 1,
        'updatedAt': Timestamp.fromDate(_updated),
      });
      expect(codec.decode(document), card);
    });

    test('reads a whole-number ease and skips broken cards', () {
      final document = codec.encode(card);
      expect(
        codec
            .decode((id: 'hello', data: {...document.data, 'ease': 2}))
            ?.state
            .ease,
        2.0,
      );
      for (final broken in [
        {'repetitions': -1},
        {'intervalDays': -1},
        {'lapses': -1},
        {'ease': 1.0},
        {'dueAt': 'tomorrow'},
      ]) {
        expect(
          codec.decode((id: 'hello', data: {...document.data, ...broken})),
          isNull,
        );
      }
    });
  });

  group('ActivityCodec', () {
    const codec = ActivityCodec();
    final day = DailyActivity(
      day: DateTime(2026, 11, 15),
      lessons: 1,
      reviews: 3,
      seconds: 240,
    );

    test('round-trips a day', () {
      final document = codec.encode(day);

      expect(codec.idOf(day), '2026-11-15');
      expect(document.data, {'lessons': 1, 'reviews': 3, 'seconds': 240});
      expect(codec.decode(document), day);
    });

    test('skips days it does not understand', () {
      final data = codec.encode(day).data;
      expect(codec.decode((id: 'today', data: data)), isNull);
      for (final broken in [
        {'lessons': -1},
        {'reviews': -1},
        {'seconds': -1},
        {'seconds': 1.5},
      ]) {
        expect(
          codec.decode((id: '2026-11-15', data: {...data, ...broken})),
          isNull,
        );
      }
    });
  });
}
