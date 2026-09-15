import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoformula_enrolment/data/asset_meeting_repository.dart';
import 'package:innoformula_enrolment/data/attendance_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the actual Flutter manifest includes every attendance text file',
    () async {
      final source = Directory(attendanceDirectory)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.txt'))
          .toList();
      final meetings = await AssetMeetingRepository(rootBundle).loadMeetings();
      expect(meetings, hasLength(source.length));
      for (final file in source) {
        final expected = parseMeeting(
          file.uri.pathSegments.last,
          file.readAsStringSync(),
        );
        final actual = meetings.singleWhere(
          (m) => m.date == expected.date && m.name == expected.name,
        );
        expect(actual.participants, expected.participants);
      }
    },
  );
}
