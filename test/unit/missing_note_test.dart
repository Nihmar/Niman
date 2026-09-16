// Issue #78: dead links propose a note, ask, and create through the
// library's own path; the proposal and its guards are pure.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/files.dart';
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
        MissingNoteLocation.currentFolder,
        context(),
      );
      expect(path, 'Notes/Foo.md');
    });

    test('a bare name lands at the root (library root)', () {
      final path = proposedMissingNotePath(
        'Foo',
        MissingNoteLocation.libraryRoot,
        context(),
      );
      expect(path, 'Foo.md');
    });

    test('a .md target is the same note, extension stripped', () {
      expect(
        proposedMissingNotePath(
          'Foo.md',
          MissingNoteLocation.currentFolder,
          context(),
        ),
        'Notes/Foo.md',
      );
    });

    test('a heading anchor is stripped', () {
      expect(
        proposedMissingNotePath(
          'Foo#Some Heading',
          MissingNoteLocation.currentFolder,
          context(),
        ),
        'Notes/Foo.md',
      );
    });

    test('a folder-qualified target keeps its own folder, both locations', () {
      final current = proposedMissingNotePath(
        'Sub/Foo',
        MissingNoteLocation.currentFolder,
        context(),
      );
      final root = proposedMissingNotePath(
        'Sub/Foo',
        MissingNoteLocation.libraryRoot,
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
            MissingNoteLocation.currentFolder,
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
            MissingNoteLocation.currentFolder,
            context(),
          ),
          isNull,
          reason: target,
        );
      }
    });

    test('trailing-slash and dot segments do not escape or double up', () {
      expect(
        proposedMissingNotePath(
          '../Sub/..//Foo',
          MissingNoteLocation.currentFolder,
          context(),
        ),
        'Sub/Foo.md',
      );
      expect(
        proposedMissingNotePath(
          'Sub/',
          MissingNoteLocation.libraryRoot,
          context(),
        ),
        'Sub.md',
      );
    });

    test('backslash paths normalize to slashes', () {
      expect(
        proposedMissingNotePath(
          r'Sub\Foo',
          MissingNoteLocation.libraryRoot,
          context(),
        ),
        'Sub/Foo.md',
      );
    });

    test('the name is sanitized the way notes are named', () {
      expect(
        proposedMissingNotePath(
          'Bad/Name:',
          MissingNoteLocation.libraryRoot,
          context(),
        ),
        'Bad/Name.md',
      );
      expect(
        proposedMissingNotePath(
          '::::',
          MissingNoteLocation.libraryRoot,
          context(),
        ),
        '$defaultNoteName.md',
      );
    });
  });

  group('MissingNoteHandler', () {
    /// A handler over recorded fakes; [folders] are the existing folders.
    (MissingNoteHandler handler, _Recording recording) buildHandler({
      MissingNoteLocation location = MissingNoteLocation.currentFolder,
      Set<String> folders = const <String>{},
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
        folderExists: (folder) async {
          recording.folderCalls.add(folder);
          return folders.contains(folder);
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

    test('a missing folder is an error, and nothing is created', () async {
      final (handler, recording) = buildHandler();
      final outcome = await handler.handleDeadLink('Sub/Foo', context());
      expect(
        outcome,
        isA<DeadLinkFolderMissing>()
            .having((o) => o.folder, 'folder', 'Sub'),
      );
      expect(recording.confirmCalls, isEmpty);
      expect(recording.createCalls, isEmpty);
    });

    test('an existing folder is created when confirmed', () async {
      final (handler, recording) = buildHandler(folders: {'Notes'});
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
        final (handler, recording) = buildHandler(
          confirm: false,
          folders: {'Notes'},
        );
        final outcome = await handler.handleDeadLink('Foo', context());
        expect(outcome, const DeadLinkDeclined());
        expect(recording.createCalls, isEmpty);
        expect(recording.confirmCalls, ['Notes/Foo.md']);
      },
    );

    test('a root proposal never asks about a folder', () async {
      final (handler, recording) = buildHandler(
        location: MissingNoteLocation.libraryRoot,
      );
      final outcome = await handler.handleDeadLink('Foo', context());
      expect(
        outcome,
        isA<DeadLinkCreated>().having((o) => o.path, 'path', 'created'),
      );
      expect(recording.folderCalls, isEmpty);
      expect(recording.createCalls, ['Foo.md']);
    });
  });
}

/// The calls a handler made, in order.
final class _Recording {
  final List<String> confirmCalls = [];
  final List<String> createCalls = [];
  final List<String> folderCalls = [];
}
