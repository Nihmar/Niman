// Issue #78: dead links propose a note, ask, and create through the
// library's own path; the proposal and its guards are pure.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/links/missing_note_handler.dart';

LinkContext context({
  String? root = '/lib',
  String note = '/lib/Notes/Current.md',
}) => LinkContext(libraryRoot: root, currentNote: note);

void main() {
  group('LinkContext', () {
    test('the current folder is the clicked note parent, library-relative', () {
      expect(context().currentFolder, 'Notes');
      expect(context(note: '/lib/Current.md').currentFolder, '');
      expect(context(note: '/lib/a/b/Current.md').currentFolder, 'a/b');
    });

    test(
      'no library context when there is no root, or the note is outside',
      () {
        expect(context(root: null).currentFolder, isNull);
        expect(context(note: '/other/Current.md').currentFolder, isNull);
      },
    );
  });

  group('proposedMissingNotePath', () {
    test('a bare name lands next to the clicked note (current folder)', () {
      final path = proposedMissingNotePath(
        'Foo',
        NewItemLocation.openNoteFolder,
        context(),
      );
      expect(path, 'Notes/Foo.md');
    });

    test('a bare name lands at the root (library root)', () {
      final path = proposedMissingNotePath(
        'Foo',
        NewItemLocation.libraryRoot,
        context(),
      );
      expect(path, 'Foo.md');
    });

    test('a .md target is the same note, extension stripped', () {
      expect(
        proposedMissingNotePath(
          'Foo.md',
          NewItemLocation.openNoteFolder,
          context(),
        ),
        'Notes/Foo.md',
      );
    });

    test('a heading anchor is stripped', () {
      expect(
        proposedMissingNotePath(
          'Foo#Some Heading',
          NewItemLocation.openNoteFolder,
          context(),
        ),
        'Notes/Foo.md',
      );
    });

    test('a folder-qualified target keeps its own folder, both locations', () {
      final current = proposedMissingNotePath(
        'Sub/Foo',
        NewItemLocation.openNoteFolder,
        context(),
      );
      final root = proposedMissingNotePath(
        'Sub/Foo',
        NewItemLocation.libraryRoot,
        context(),
      );
      expect(current, 'Sub/Foo.md');
      expect(root, 'Sub/Foo.md');
    });

    test('attachments are not notes: a surviving extension is not offered', () {
      for (final target in ['photo.png', 'photo.JPG', 'notes/doc.pdf']) {
        expect(
          proposedMissingNotePath(
            target,
            NewItemLocation.openNoteFolder,
            context(),
          ),
          isNull,
          reason: target,
        );
      }
    });

    test('an empty target offers nothing', () {
      for (final target in ['', '  ', '#Heading', '.md']) {
        expect(
          proposedMissingNotePath(
            target,
            NewItemLocation.openNoteFolder,
            context(),
          ),
          isNull,
          reason: target,
        );
      }
    });

    test('a hidden folder is not made by a link', () {
      for (final target in ['.trash/Foo', '.niman/Foo', 'Sub/.hidden/Foo']) {
        expect(
          proposedMissingNotePath(
            target,
            NewItemLocation.openNoteFolder,
            context(),
          ),
          isNull,
          reason: target,
        );
      }
      expect(
        proposedMissingNotePath(
          'Sub/Foo',
          NewItemLocation.openNoteFolder,
          context(),
        ),
        'Sub/Foo.md',
        reason: 'a plain folder is still offered',
      );
    });

    test('trailing-slash and dot segments do not escape or double up', () {
      expect(
        proposedMissingNotePath(
          '../Sub/..//Foo',
          NewItemLocation.openNoteFolder,
          context(),
        ),
        'Sub/Foo.md',
      );
      expect(
        proposedMissingNotePath('Sub/', NewItemLocation.libraryRoot, context()),
        'Sub.md',
      );
    });

    test('backslash paths normalize to slashes', () {
      expect(
        proposedMissingNotePath(
          r'Sub\Foo',
          NewItemLocation.libraryRoot,
          context(),
        ),
        'Sub/Foo.md',
      );
    });

    test('the name is sanitized the way notes are named', () {
      expect(
        proposedMissingNotePath(
          'Bad/Name:',
          NewItemLocation.libraryRoot,
          context(),
        ),
        'Bad/Name.md',
      );
      expect(
        proposedMissingNotePath('::::', NewItemLocation.libraryRoot, context()),
        '$defaultNoteName.md',
      );
    });
  });

  group('MissingNoteHandler', () {
    /// A handler over recorded fakes.
    (MissingNoteHandler handler, _Recording recording) buildHandler({
      NewItemLocation location = NewItemLocation.openNoteFolder,
      bool confirm = true,
      String created = 'created',
    }) {
      final recording = _Recording();
      final handler = MissingNoteHandler(
        location: location,
        confirm: (path) async {
          recording.confirmCalls.add(path);
          return confirm;
        },
        createNote: (path) async {
          recording.createCalls.add(path);
          return created;
        },
      );
      return (handler, recording);
    }

    test(
      'no library context: not offered, nothing asked, nothing made',
      () async {
        final (handler, recording) = buildHandler();
        final outcome = await handler.handleDeadLink(
          'Foo',
          context(root: null),
        );
        expect(outcome, const DeadLinkNotOffered());
        expect(recording.confirmCalls, isEmpty);
        expect(recording.createCalls, isEmpty);
      },
    );

    test('an attachment target is not offered', () async {
      final (handler, recording) = buildHandler();
      final outcome = await handler.handleDeadLink('photo.png', context());
      expect(outcome, const DeadLinkNotOffered());
      expect(recording.confirmCalls, isEmpty);
      expect(recording.createCalls, isEmpty);
    });

    test(
      'a folder the library lacks is no refusal: it is asked and made',
      () async {
        // #847: the folders on the way are the creator's to make, so the
        // proposal names the whole path and the handler asks about it.
        final (handler, recording) = buildHandler();
        final outcome = await handler.handleDeadLink('Sub/Deep/Foo', context());
        expect(
          outcome,
          isA<DeadLinkCreated>().having((o) => o.path, 'path', 'created'),
        );
        expect(recording.confirmCalls, ['Sub/Deep/Foo.md']);
        expect(recording.createCalls, ['Sub/Deep/Foo.md']);
      },
    );

    test('a declined dialog makes neither the note nor its folders', () async {
      final (handler, recording) = buildHandler(confirm: false);
      final outcome = await handler.handleDeadLink('Sub/Foo', context());
      expect(outcome, const DeadLinkDeclined());
      expect(recording.createCalls, isEmpty);
    });

    test('a target that climbs out of the library stays in it', () async {
      final (handler, recording) = buildHandler();
      await handler.handleDeadLink('../../Out/Foo', context());
      expect(recording.confirmCalls, ['Out/Foo.md']);
    });

    test('the current folder is created when confirmed', () async {
      final (handler, recording) = buildHandler();
      final outcome = await handler.handleDeadLink('Foo', context());
      expect(
        outcome,
        isA<DeadLinkCreated>().having((o) => o.path, 'path', 'created'),
      );
      expect(recording.confirmCalls, ['Notes/Foo.md']);
      expect(recording.createCalls, ['Notes/Foo.md']);
    });

    test(
      'a declined dialog changes nothing (issue #78, no second prompt)',
      () async {
        final (handler, recording) = buildHandler(confirm: false);
        final outcome = await handler.handleDeadLink('Foo', context());
        expect(outcome, const DeadLinkDeclined());
        expect(recording.createCalls, isEmpty);
        expect(recording.confirmCalls, ['Notes/Foo.md']);
      },
    );

    test('a root proposal has no folder to make', () async {
      final (handler, recording) = buildHandler(
        location: NewItemLocation.libraryRoot,
      );
      final outcome = await handler.handleDeadLink('Foo', context());
      expect(
        outcome,
        isA<DeadLinkCreated>().having((o) => o.path, 'path', 'created'),
      );
      expect(recording.createCalls, ['Foo.md']);
    });
  });
}

/// The calls a handler made, in order.
final class _Recording {
  final List<String> confirmCalls = [];
  final List<String> createCalls = [];
}
