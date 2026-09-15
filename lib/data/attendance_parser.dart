import '../domain/meeting.dart';

const attendanceDirectory = 'assets/attendance/';
final _identifierPattern = RegExp(r'^[a-z]+\.[a-z]+(?:-[a-z]+)*$');
final _filenamePattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})-([a-zа-яё0-9]+(?:-[a-zа-яё0-9]+)*)\.txt$',
);

String normalizeIdentifier(String value) => value.trim().toLowerCase();

bool isValidIdentifier(String value) => _identifierPattern.hasMatch(value);

({DateTime date, String name}) parseMeetingFilename(String filename) {
  final match = _filenamePattern.firstMatch(filename);
  if (match == null) {
    throw const FormatException(
      'Ожидается имя YYYY-MM-DD-название-встречи.txt (нижний регистр).',
    );
  }
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final date = DateTime.utc(year, month, day);
  if (year < 1 || date.year != year || date.month != month || date.day != day) {
    throw const FormatException('Несуществующая календарная дата.');
  }
  return (date: date, name: match[4]!.replaceAll('-', ' '));
}

Set<String> parseParticipants(String content) {
  final participants = <String>{};
  final lines = content.split(RegExp(r'\r\n|\n|\r'));
  for (var i = 0; i < lines.length; i++) {
    final participant = normalizeIdentifier(lines[i]);
    if (participant.isEmpty) continue;
    if (!isValidIdentifier(participant)) {
      // Never include raw input in errors: it may contain private email data.
      throw FormatException(
        'Строка ${i + 1}: ожидается идентификатор вида a.ivanov без домена.',
      );
    }
    participants.add(participant);
  }
  return participants;
}

Meeting parseMeeting(String filename, String content) {
  final metadata = parseMeetingFilename(filename);
  return Meeting(
    date: metadata.date,
    name: metadata.name,
    participants: parseParticipants(content),
  );
}
