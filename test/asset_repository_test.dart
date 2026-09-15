import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoformula_enrolment/data/asset_meeting_repository.dart';

class TestBundle extends CachingAssetBundle {
  TestBundle(this.files);
  final Map<String, String?> files;
  int reads = 0;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object>{
        for (final path in files.keys)
          path: <Object>[
            <String, Object>{'asset': path},
          ],
      })!;
    }
    reads++;
    final content = files[key];
    if (content == null) throw StateError('Failed asset request');
    return ByteData.sublistView(utf8.encode(content));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('discovers multiple direct text assets and skips other files', () async {
    final bundle = TestBundle({
      'assets/attendance/2026-09-01-first.txt': 'a.ivanov',
      'assets/attendance/2026-09-02-second.txt': 'b.petrov',
      'assets/attendance/.gitkeep': '',
      'assets/attendance/nested/2026-09-03-third.txt': 'c.smirnov',
      'assets/other/2026-09-04-fourth.txt': 'd.sidorov',
    });
    final meetings = await AssetMeetingRepository(bundle).loadMeetings();
    expect(meetings.map((m) => m.name), ['first', 'second']);
    expect(bundle.reads, 2);
  });

  test(
    'fails the whole load for malformed or unreadable meetings; retry recovers',
    () async {
      for (final badContent in [null, 'invalid']) {
        final bundle = TestBundle({
          'assets/attendance/2026-09-01-first.txt': 'a.ivanov',
          'assets/attendance/2026-09-02-second.txt': badContent,
        });
        final repository = AssetMeetingRepository(bundle);
        await expectLater(repository.loadMeetings(), throwsA(anything));
        bundle.files['assets/attendance/2026-09-02-second.txt'] = 'b.petrov';
        expect(await repository.loadMeetings(), hasLength(2));
      }
    },
  );

  test(
    'invalid filename also fails and an empty manifest returns no meetings',
    () async {
      await expectLater(
        AssetMeetingRepository(
          TestBundle({'assets/attendance/bad.txt': 'a.ivanov'}),
        ).loadMeetings(),
        throwsFormatException,
      );
      expect(
        await AssetMeetingRepository(TestBundle({})).loadMeetings(),
        isEmpty,
      );
    },
  );
}
