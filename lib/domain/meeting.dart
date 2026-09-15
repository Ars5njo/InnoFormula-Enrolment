class Meeting {
  Meeting({
    required this.date,
    required this.name,
    required Iterable<String> participants,
  }) : participants = Set.unmodifiable(participants);

  final DateTime date;
  final String name;
  final Set<String> participants;
}
