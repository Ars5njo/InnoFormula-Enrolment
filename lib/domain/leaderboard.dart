import 'meeting.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.participant,
    required this.attendance,
  });

  final int rank;
  final String participant;
  final int attendance;
}

/// Competition ranking: 1, 2, 2, 4. Input order never affects the result.
List<LeaderboardEntry> calculateLeaderboard(Iterable<Meeting> meetings) {
  final counts = <String, int>{};
  for (final meeting in meetings) {
    for (final participant in meeting.participants) {
      counts.update(participant, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byAttendance = b.value.compareTo(a.value);
      return byAttendance == 0 ? a.key.compareTo(b.key) : byAttendance;
    });
  var rank = 0;
  int? previousCount;
  final result = <LeaderboardEntry>[];
  for (var index = 0; index < sorted.length; index++) {
    final participant = sorted[index];
    if (participant.value != previousCount) rank = index + 1;
    previousCount = participant.value;
    result.add(
      LeaderboardEntry(
        rank: rank,
        participant: participant.key,
        attendance: participant.value,
      ),
    );
  }
  return List.unmodifiable(result);
}

class Leaderboard {
  Leaderboard(Iterable<Meeting> meetings)
    : meetings = List.unmodifiable(meetings),
      entries = calculateLeaderboard(meetings);

  final List<Meeting> meetings;
  final List<LeaderboardEntry> entries;

  DateTime? get latestMeeting => meetings.isEmpty
      ? null
      : meetings
            .map((meeting) => meeting.date)
            .reduce((a, b) => a.isAfter(b) ? a : b);
}
