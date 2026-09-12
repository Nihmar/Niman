// ignore_for_file: avoid_print
// Temporary reproduction: the full template-creation flow against a real
// LibraryController (real disk + real sqlite), with the exact
// Personaggio.md template. Every step is logged so a hang points at one.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/frontmatter/edit.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/templates/directives.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:path/path.dart' as p;

const String personaggio = '''
---
niman:
  folder: Mondo/{{choice:Tipo:Personaggi,Luoghi}}
  filename: "{{ask:Nome}}"
type: character
---

# {{ask:Nome}}

**Fazione**: {{choice:Fazione:Corona,Ribelli,Neutrale}}
**Vista in**: [[{{parent}}]]
**Creata**: {{date:dddd D MMMM YYYY}}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('niman block flow on a real session', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final tmp = await Directory.current.createTemp('niman_repro_');
    addTearDown(() async {
      await tmp.delete(recursive: true);
    });
    final root = Directory(p.join(tmp.path, 'library'))..createSync();
    Directory(p.join(root.path, 'Templates')).createSync();
    File(p.join(root.path, 'Templates', 'Personaggio.md'))
        .writeAsStringSync(personaggio);
    File(p.join(root.path, 'Avventura.md')).writeAsStringSync('# Avventura\n');

    Future<AppDatabase> appDb() async => AppDatabase(
      NativeDatabase(File(p.join(tmp.path, 'niman.db'))),
    );
    Future<IndexDatabase> indexDb(String libraryPath) async => IndexDatabase(
      NativeDatabase(File(p.join(tmp.path, 'library.db'))),
    );

    print('>> opening controller');
    final controller = LibraryController(
      appDb,
      indexDbFactory: indexDb,
    );
    await controller.open(root.path, create: false);
    print('>> open done, phase=${controller.phase}');

    print('>> templateSource');
    final source = await controller.templateSource;
    final templates = await source!.templates();
    print('>> templates: ${templates.map((t) => t.name).toList()}');
    final folder = await source.folder;
    print('>> template folder: $folder');

    print('>> readNote');
    final ops = controller.ops!;
    final template = await ops.readNote('Templates/Personaggio.md');

    print('>> directives (first read)');
    final answers = <String, String>{
      'Tipo': 'Personaggi',
      'Nome': 'Gandalf',
      'Fazione': 'Corona',
    };
    final surroundings = TemplateContext(parent: '', clipboard: '');
    final declared = readTemplateDirectives(
      template,
      answers: answers,
      context: surroundings,
    );
    print(
      '>> namesItself=${declared.namesItself} filename=${declared.filename}',
    );

    print('>> directives (second read)');
    final name = declared.filename!;
    final directives = readTemplateDirectives(
      template,
      title: name,
      answers: answers,
      context: surroundings,
    );
    final target = directives.folder!;
    print(
      '>> folder=$target append=${directives.append} open=${directives.open}',
    );

    print('>> render');
    final rendered = renderTemplateWithCaret(
      template,
      title: name,
      answers: answers,
      context: surroundings.withFolder(target),
    );
    final content = removeFrontmatterKey(rendered.text, directivesKey);
    print('>> content:\n$content');

    print('>> ensureFolder');
    await ops.ensureFolder(target);
    print('>> ensureFolder done');

    print('>> createNote');
    final row = await ops.createNote(
      parentPath: target,
      name: name,
      content: content,
    );
    print('>> created ${row.path}');

    final onDisk = File(p.join(root.path, row.path)).readAsStringSync();
    expect(onDisk, contains('# Gandalf'));
    expect(onDisk, isNot(contains('niman:')));

    print('>> close');
    await controller.close();
    print('>> DONE');
  });
}
