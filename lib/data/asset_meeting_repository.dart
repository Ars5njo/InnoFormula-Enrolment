import 'package:flutter/services.dart';

import '../domain/meeting.dart';
import '../domain/meeting_repository.dart';
import 'attendance_parser.dart';

class AssetMeetingRepository implements MeetingRepository {
  const AssetMeetingRepository(this.bundle);

  final AssetBundle bundle;

  @override
  Future<List<Meeting>> loadMeetings() async {
    // Clear cached manifests too, so retry can recover from a failed request.
    bundle.evict('AssetManifest.bin');
    bundle.evict('AssetManifest.bin.json');
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final files = manifest.listAssets().where((path) {
      if (!path.startsWith(attendanceDirectory)) return false;
      final filename = path.substring(attendanceDirectory.length);
      return filename.endsWith('.txt') && !filename.contains('/');
    }).toList()..sort();
    // Future.wait fails the entire load if any meeting is unreadable or invalid.
    return Future.wait([
      for (final path in files)
        (() async => parseMeeting(
          path.substring(attendanceDirectory.length),
          await bundle.loadString(path, cache: false),
        ))(),
    ]);
  }
}
