import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meya/database/database_encryption.dart';
import 'package:sqlite3/sqlite3.dart';

const keyA = '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
const keyB = 'ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100';

void main() {
  late Directory folder;
  late File file;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('meya_db_test');
    file = File('${folder.path}/meya.sqlite');
  });

  tearDown(() => folder.deleteSync(recursive: true));

  void writePlaintext() {
    final database = sqlite3.open(file.path);
    database.execute("CREATE TABLE contacts (name TEXT); INSERT INTO contacts VALUES ('Ana');");
    database.close();
  }

  List<String> namesWith(String? key) {
    final database = sqlite3.open(file.path);
    try {
      if (key != null) database.execute(MeyaDatabaseEncryption.keyPragma(key));
      return [
        for (final row in database.select('SELECT name FROM contacts')) row['name'] as String,
      ];
    } finally {
      database.close();
    }
  }

  test('an existing database is encrypted in place and keeps its data', () {
    writePlaintext();
    expect(file.readAsStringSync(encoding: latin1), contains('Ana'));

    MeyaDatabaseEncryption.prepare(file, keyA);

    expect(namesWith(keyA), ['Ana']);
    expect(() => namesWith(null), throwsA(isA<SqliteException>()));
    expect(() => namesWith(keyB), throwsA(isA<SqliteException>()));
    // Nothing readable is left in the file itself.
    expect(file.readAsStringSync(encoding: latin1), isNot(contains('Ana')));
    expect(file.readAsStringSync(encoding: latin1), isNot(contains('CREATE TABLE')));
  });

  test('preparing an already encrypted database changes nothing', () {
    writePlaintext();
    MeyaDatabaseEncryption.prepare(file, keyA);
    MeyaDatabaseEncryption.prepare(file, keyA);
    expect(namesWith(keyA), ['Ana']);
  });

  test('a database whose key was lost is moved aside, not opened', () {
    writePlaintext();
    MeyaDatabaseEncryption.prepare(file, keyA);

    MeyaDatabaseEncryption.prepare(file, keyB);

    expect(file.existsSync(), isFalse);
    expect(
      folder.listSync().whereType<File>().any((f) => f.path.contains('.unreadable-')),
      isTrue,
    );
  });

  test('only well-formed keys are accepted', () {
    expect(() => MeyaDatabaseEncryption.keyPragma("x'; DROP TABLE contacts; --"),
        throwsArgumentError);
    expect(MeyaDatabaseEncryption.keyPragma(keyA), contains(keyA));
  });
}
