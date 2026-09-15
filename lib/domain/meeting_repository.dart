import 'meeting.dart';

abstract interface class MeetingRepository {
  Future<List<Meeting>> loadMeetings();
}
