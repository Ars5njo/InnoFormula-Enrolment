import 'dart:convert';
import 'dart:io';

import 'package:innoformula_enrolment/data/attendance_parser.dart';
import 'package:innoformula_enrolment/data/email_preparation.dart';

const _usage = '''
Подготовка (почты и реестр должны находиться ВНЕ репозитория):
  dart run tool/attendance.dart prepare --input /private/path/emails.txt \\
    --registry /private/path/identities.json --date 2026-09-15 --name первая-встреча
  Добавьте --replace для исправления существующей встречи.

Проверка всех файлов перед коммитом:
  dart run tool/attendance.dart validate
''';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.first == '--help') {
    stdout.write(_usage);
    return;
  }
  final root = File.fromUri(Platform.script).parent.parent
      .resolveSymbolicLinksSync();
  try {
    switch (arguments.first) {
      case 'validate':
        if (arguments.length != 1) {
          throw const FormatException(
            'У validate нет дополнительных аргументов.',
          );
        }
        final count = await validateAttendance(
          Directory('$root/$attendanceDirectory'),
        );
        stdout.writeln('Проверка пройдена. Файлов встреч: $count.');
      case 'prepare':
        await _prepare(root, arguments.skip(1).toList());
      default:
        throw const FormatException('Неизвестная команда. Используйте --help.');
    }
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } on FileSystemException {
    stderr.writeln(
      'Не удалось прочитать или записать файл. Проверьте пути и права.',
    );
    exitCode = 1;
  }
}

Future<int> validateAttendance(
  Directory directory, {
  String? replacingPath,
}) async {
  if (!await directory.exists()) {
    throw const FormatException('Отсутствует директория assets/attendance/.');
  }
  var count = 0;
  final entities = await directory.list(followLinks: false).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final entity in entities) {
    final filename = entity.uri.pathSegments.where((p) => p.isNotEmpty).last;
    if (entity is File &&
        filename == '.gitkeep' &&
        await entity.length() == 0) {
      continue;
    }
    if (entity is File && entity.path == replacingPath) continue;
    if (entity is! File || !filename.endsWith('.txt')) {
      throw const FormatException(
        'В assets/attendance/ допустимы только файлы встреч .txt и пустой .gitkeep. '
        'Вложенные папки и ссылки запрещены.',
      );
    }
    try {
      parseMeeting(filename, await entity.readAsString());
    } on FormatException catch (error) {
      throw FormatException('Файл встречи №${count + 1}: ${error.message}');
    }
    count++;
  }
  return count;
}

Future<File> _externalFile(
  String path,
  String root, {
  bool existing = false,
}) async {
  final file = File(path).absolute;
  final String resolved;
  if (await FileSystemEntity.type(file.path) != FileSystemEntityType.notFound) {
    resolved = await file.resolveSymbolicLinks();
  } else {
    if (existing) throw const FormatException('Исходный файл не найден.');
    final parent = await file.parent.resolveSymbolicLinks();
    resolved = '$parent/${file.uri.pathSegments.last}';
  }
  if (resolved == root || resolved.startsWith('$root/')) {
    throw const FormatException(
      'Исходные почты и реестр нужно хранить вне репозитория.',
    );
  }
  return File(resolved);
}

Future<void> _prepare(String root, List<String> arguments) async {
  final options = <String, String>{};
  var replace = false;
  for (var i = 0; i < arguments.length; i++) {
    final argument = arguments[i];
    if (argument == '--replace' && !replace) {
      replace = true;
    } else if ([
          '--input',
          '--registry',
          '--date',
          '--name',
        ].contains(argument) &&
        !options.containsKey(argument) &&
        i + 1 < arguments.length) {
      options[argument] = arguments[++i];
    } else {
      throw const FormatException(
        'Некорректные или повторные аргументы. Используйте --help.',
      );
    }
  }
  if (options.length != 4) {
    throw const FormatException('Нужны --input, --registry, --date и --name.');
  }
  final filename = '${options['--date']}-${options['--name']}.txt';
  parseMeetingFilename(filename);
  final input = await _externalFile(options['--input']!, root, existing: true);
  final registry = await _externalFile(options['--registry']!, root);
  if (input.path == registry.path) {
    throw const FormatException(
      'Исходный файл и реестр должны быть разными файлами.',
    );
  }
  final output = File('$root/$attendanceDirectory$filename');
  if (await FileSystemEntity.type(output.path, followLinks: false) ==
      FileSystemEntityType.link) {
    throw const FormatException(
      'Нельзя записывать встречу через символическую ссылку.',
    );
  }
  if (await output.exists() && !replace) {
    throw const FormatException(
      'Встреча уже существует. Для исправления используйте --replace.',
    );
  }
  var identities = <String, String>{};
  if (await registry.exists()) {
    final decoded = jsonDecode(await registry.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded.entries.any((entry) => entry.value is! String)) {
      throw const FormatException(
        'Некорректный локальный реестр идентификаторов.',
      );
    }
    identities = decoded.cast<String, String>();
    for (final entry in identities.entries) {
      final check = prepareEmails(entry.value);
      if (check.participants.single != entry.key ||
          check.identities[entry.key] != entry.value) {
        throw const FormatException(
          'Ненормализованная запись в локальном реестре.',
        );
      }
    }
  }
  final prepared = prepareEmails(
    await input.readAsString(),
    knownIdentities: identities,
  );
  await validateAttendance(
    output.parent,
    replacingPath: replace ? output.path : null,
  );
  await registry.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(prepared.identities)}\n',
    flush: true,
  );
  final temporary = File('${output.path}.tmp');
  try {
    await temporary.writeAsString(
      '${prepared.participants.join('\n')}\n',
      flush: true,
    );
    await temporary.rename(output.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
  stdout.writeln(
    'Готово: $attendanceDirectory$filename. Участников: ${prepared.participants.length}.',
  );
}
