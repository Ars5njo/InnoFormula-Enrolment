import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoformula_enrolment/data/attendance_parser.dart';
import 'package:innoformula_enrolment/domain/meeting.dart';
import 'package:innoformula_enrolment/domain/meeting_repository.dart';
import 'package:innoformula_enrolment/presentation/app.dart';

class StubRepository implements MeetingRepository {
  StubRepository(this.load);
  final Future<List<Meeting>> Function() load;
  int calls = 0;

  @override
  Future<List<Meeting>> loadMeetings() {
    calls++;
    return load();
  }
}

void main() {
  testWidgets('loading runs once across rebuilds, then shows empty state', (
    tester,
  ) async {
    final completer = Completer<List<Meeting>>();
    final repository = StubRepository(() => completer.future);
    await tester.pumpWidget(InnoFormulaApp(repository: repository));
    expect(find.text('Собираем стартовую решётку'), findsOneWidget);
    await tester.pumpWidget(InnoFormulaApp(repository: repository));
    expect(repository.calls, 1);
    completer.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Всё начинается с первой встречи'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('error offers retry and never displays a partial ranking', (
    tester,
  ) async {
    var fail = true;
    final repository = StubRepository(() async {
      if (fail) {
        throw const FormatException('private input should never be shown');
      }
      return [parseMeeting('2026-09-15-first.txt', 'a.ivanov')];
    });
    await tester.pumpWidget(InnoFormulaApp(repository: repository));
    await tester.pumpAndSettle();
    expect(find.text('Красный флаг'), findsOneWidget);
    expect(find.textContaining('private input'), findsNothing);
    fail = false;
    await tester.ensureVisible(find.text('Повторить загрузку'));
    await tester.tap(find.text('Повторить загрузку'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.byKey(const ValueKey('participant-a.ivanov')), findsOneWidget);
    expect(find.text('Последняя встреча  ·  15.09.2026'), findsOneWidget);
  });

  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets(
      'ranking fits width $width with long identifiers and tied places',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = StubRepository(
          () async => [
            parseMeeting(
              '2026-09-15-first.txt',
              'a.veryveryveryveryveryveryverylong-surname\nb.petrov',
            ),
          ],
        );
        await tester.pumpWidget(InnoFormulaApp(repository: repository));
        await tester.pumpAndSettle();
        expect(
          find.text('01'),
          findsNWidgets(3),
        ); // one stat marker + two equal places
        final participant = find.byKey(
          const ValueKey(
            'participant-a.veryveryveryveryveryveryverylong-surname',
          ),
        );
        expect(tester.getRect(participant).right, lessThanOrEqualTo(width));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
