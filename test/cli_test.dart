import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory sandbox;
  late Directory repo;
  late String dart;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('innoformula-cli-');
    repo = Directory('${sandbox.path}/repo')..createSync();
    for (final relative in [
      'tool/attendance.dart',
      'lib/data/attendance_parser.dart',
      'lib/data/email_preparation.dart',
      'lib/domain/meeting.dart',
    ]) {
      final destination = File('${repo.path}/$relative');
      destination.parent.createSync(recursive: true);
      File(relative).copySync(destination.path);
    }
    Directory('${repo.path}/assets/attendance').createSync(recursive: true);
    Directory('${repo.path}/.dart_tool').createSync();
    File('${repo.path}/.dart_tool/package_config.json').writeAsStringSync(
      jsonEncode({
        'configVersion': 2,
        'packages': [
          {
            'name': 'innoformula_enrolment',
            'rootUri': '../',
            'packageUri': 'lib/',
            'languageVersion': '3.13',
          },
        ],
      }),
    );
    final config = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final packages = config['packages'] as List<dynamic>;
    final flutter = packages.cast<Map<String, dynamic>>().singleWhere(
      (p) => p['name'] == 'flutter',
    );
    final flutterPackage = Directory.fromUri(
      Uri.parse(flutter['rootUri'] as String),
    );
    dart = '${flutterPackage.parent.parent.path}/bin/cache/dart-sdk/bin/dart';
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  Future<ProcessResult> run(List<String> args) => Process.run(dart, [
    '${repo.path}/tool/attendance.dart',
    ...args,
  ], workingDirectory: repo.path);

  List<String> prepare(String input, {bool replace = false}) => [
    'prepare',
    '--input',
    input,
    '--registry',
    '${sandbox.path}/identities.json',
    '--date',
    '2026-09-15',
    '--name',
    'race',
    if (replace) '--replace',
  ];

  test('CLI writes only identifiers, validates, protects overwrite and detects historical collisions', () async {
    final input = File('${sandbox.path}/emails.txt')
      ..writeAsStringSync(
        ' B.Petrov@example.test\r\na.ivanov@example.test\na.ivanov@example.test',
      );
    expect((await run(prepare(input.path))).exitCode, 0);
    final output = File('${repo.path}/assets/attendance/2026-09-15-race.txt');
    expect(output.readAsStringSync(), 'a.ivanov\nb.petrov\n');
    expect((await run(['validate'])).exitCode, 0);
    expect((await run(prepare(input.path))).exitCode, 1);
    input.writeAsStringSync('b.petrov@example.test');
    expect((await run(prepare(input.path, replace: true))).exitCode, 0);
    expect(output.readAsStringSync(), 'b.petrov\n');
    input.writeAsStringSync('a.ivanov@different.test');
    final collision = await run(prepare(input.path, replace: true));
    expect(collision.exitCode, 1);
    expect(collision.stderr, isNot(contains('@')));
    expect(output.readAsStringSync(), 'b.petrov\n');
  });

  test('CLI rejects internal sources including symlinks and invalid asset contents', () async {
    final internal = File('${repo.path}/raw.txt')
      ..writeAsStringSync('a.ivanov@example.test');
    expect((await run(prepare(internal.path))).exitCode, 1);
    final alias = Link('${sandbox.path}/alias.txt')..createSync(internal.path);
    expect((await run(prepare(alias.path))).exitCode, 1);
    File('${repo.path}/assets/attendance/2026-09-15-race.txt')
        .writeAsStringSync('a.ivanov@example.test');
    final invalid = await run(['validate']);
    expect(invalid.exitCode, 1);
    expect(invalid.stderr, isNot(contains('@')));
  });

  test('CLI rejects nested assets and raw export files', () async {
    final nested = Directory('${repo.path}/assets/attendance/nested')
      ..createSync();
    expect((await run(['validate'])).exitCode, 1);
    nested.deleteSync();
    File('${repo.path}/assets/attendance/export.csv').writeAsStringSync('raw');
    expect((await run(['validate'])).exitCode, 1);
  });
}
