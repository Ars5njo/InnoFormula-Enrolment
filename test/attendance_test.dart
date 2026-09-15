import 'package:flutter_test/flutter_test.dart';
import 'package:innoformula_enrolment/data/attendance_parser.dart';
import 'package:innoformula_enrolment/data/email_preparation.dart';
import 'package:innoformula_enrolment/domain/leaderboard.dart';

void main() {
  test('normalizes whitespace, case, all line endings and duplicates', () {
    expect(
      parseParticipants(' A.Ivanov \r\nm.petrov\ra.ivanov\n\n E.Smirnova '),
      {'a.ivanov', 'm.petrov', 'e.smirnova'},
    );
  });

  test('counts multiple meetings and assigns stable competition ranks', () {
    final meetings = [
      parseMeeting(
        '2026-09-01-первая.txt',
        'a.ivanov\na.ivanov\nb.petrov\nc.sidorov\nd.smirnov',
      ),
      parseMeeting('2026-09-02-вторая.txt', 'c.sidorov\nb.petrov\na.ivanov'),
      parseMeeting('2026-09-03-третья.txt', 'a.ivanov'),
    ];
    final result = calculateLeaderboard(meetings.reversed);
    expect(result.map((e) => (e.rank, e.participant, e.attendance)), [
      (1, 'a.ivanov', 3),
      (2, 'b.petrov', 2),
      (2, 'c.sidorov', 2),
      (4, 'd.smirnov', 1),
    ]);
    expect(Leaderboard(meetings).latestMeeting, DateTime.utc(2026, 9, 3));
  });

  test(
    'preserves multi-letter prefixes without merging distinct identifiers',
    () {
      expect(parseParticipants(' A.Ivanov\n AN.Ivanov\nan.ivanov '), {
        'a.ivanov',
        'an.ivanov',
      });
      final prepared = prepareEmails(
        'a.ivanov@example.test\nAN.Ivanov@example.test',
      );
      expect(prepared.participants, ['a.ivanov', 'an.ivanov']);
      expect(prepared.identities, hasLength(2));
    },
  );

  test('empty meetings and all ties are supported', () {
    expect(Leaderboard([]).entries, isEmpty);
    expect(Leaderboard([]).latestMeeting, isNull);
    final board = Leaderboard([parseMeeting('2026-09-01-empty.txt', '\n ')]);
    expect(board.meetings, hasLength(1));
    expect(board.entries, isEmpty);
    expect(
      calculateLeaderboard([
        parseMeeting('2026-09-01-tie.txt', 'z.last\na.first'),
      ]).map((e) => e.rank),
      [1, 1],
    );
  });

  test('rejects invalid records without echoing raw input', () {
    for (final invalid in [
      'fullname',
      'a1.ivanov',
      'a.n.ivanov',
      'a.ivanov@example.test',
      'a_ivanov',
      'a.ivanov extra',
      'a.123',
      'а.иванов',
    ]) {
      expect(
        () => parseParticipants('b.petrov\n$invalid'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Строка 2'), isNot(contains(invalid))),
          ),
        ),
      );
    }
  });

  test('validates filename, real dates and root-only paths', () {
    expect(
      parseMeetingFilename('2024-02-29-гран-при.txt').date,
      DateTime.utc(2024, 2, 29),
    );
    for (final filename in [
      '2026-02-29-race.txt',
      '2026-13-01-race.txt',
      '2026-09-31-race.txt',
      '0000-01-01-race.txt',
      '2026-1-01-race.txt',
      '2026-01-01-.txt',
      '2026-01-01-Race.txt',
      'folder/2026-01-01-race.txt',
    ]) {
      expect(() => parseMeetingFilename(filename), throwsFormatException);
    }
  });

  test('prepares sorted identifiers and preserves local identity history', () {
    final result = prepareEmails(
      ' M.Petrov@example.test \r\na.ivanov@example.test\nM.PETROV@EXAMPLE.TEST\n',
      knownIdentities: {'e.smirnova': 'e.smirnova@example.test'},
    );
    expect(result.participants, ['a.ivanov', 'm.petrov']);
    expect(result.identities, hasLength(3));
  });

  test(
    'finds collisions both within an import and against earlier meetings',
    () {
      expect(
        () => prepareEmails('a.ivanov@one.test\na.ivanov@two.test'),
        throwsFormatException,
      );
      expect(
        () => prepareEmails(
          'a.ivanov@two.test',
          knownIdentities: {'a.ivanov': 'a.ivanov@one.test'},
        ),
        throwsFormatException,
      );
    },
  );

  test('rejects malformed email lists and empty imports', () {
    for (final input in [
      '',
      '  \n',
      'a.ivanov',
      'a.ivanov@@example.test',
      'a.ivanov@-example.test',
      'a.ivanov@example',
      'a.ivanov@example..test',
    ]) {
      expect(() => prepareEmails(input), throwsFormatException);
    }
  });
}
