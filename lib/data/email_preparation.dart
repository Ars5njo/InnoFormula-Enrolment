import 'attendance_parser.dart';

final _domainPattern = RegExp(
  r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)+$',
);

({List<String> participants, Map<String, String> identities}) prepareEmails(
  String source, {
  Map<String, String> knownIdentities = const {},
}) {
  final identities = Map<String, String>.of(knownIdentities);
  final participants = <String>{};
  final lines = source.split(RegExp(r'\r\n|\n|\r'));
  for (var i = 0; i < lines.length; i++) {
    final email = lines[i].trim().toLowerCase();
    if (email.isEmpty) continue;
    final parts = email.split('@');
    if (parts.length != 2 ||
        !isValidIdentifier(parts[0]) ||
        !_domainPattern.hasMatch(parts[1])) {
      throw FormatException(
        'Строка ${i + 1}: ожидается одна почта вида инициал.фамилия и домен.',
      );
    }
    final id = parts[0];
    if (identities.containsKey(id) && identities[id] != email) {
      throw FormatException(
        'Строка ${i + 1}: идентификатор $id связан с разными адресами. '
        'Проверьте совпадение людей локально; файл не создан.',
      );
    }
    identities[id] = email;
    participants.add(id);
  }
  if (participants.isEmpty) {
    throw const FormatException('Исходный список не содержит участников.');
  }
  return (participants: participants.toList()..sort(), identities: identities);
}
