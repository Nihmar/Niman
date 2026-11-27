// The source editor's own keys per platform (#1351): `Ctrl` chords on Windows
// and Linux, `⌥` and `⌘` on a Mac and an iPad's keyboard, and the selectors
// the Apple text system sends for the chords the table does not bind.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/apple_selectors.dart';
import 'package:niman/src/markdown/edit/source_shortcuts.dart';

/// Actions that write down what they were asked.
({SourceKeyActions actions, List<String> log}) _recorder() {
  final log = <String>[];
  final actions = SourceKeyActions(
    moveVertically: (rows, {extend = false}) =>
        log.add('rows $rows${extend ? ' extend' : ''}'),
    moveBy: (motion, {extend = false}) =>
        log.add('${motion.name}${extend ? ' extend' : ''}'),
    downOutOfTable: () => false,
    page: (direction, {extend = false}) =>
        log.add('page $direction${extend ? ' extend' : ''}'),
    tab: ({required forward}) => log.add('tab $forward'),
    copy: () => log.add('copy'),
    cut: () => log.add('cut'),
    paste: () => log.add('paste'),
    selectAll: () => log.add('selectAll'),
    deleteBackward: ({word = false}) =>
        log.add('deleteBackward${word ? ' word' : ''}'),
    deleteForward: ({word = false}) =>
        log.add('deleteForward${word ? ' word' : ''}'),
    deleteTo: (motion) => log.add('deleteTo ${motion.name}'),
    undo: () => log.add('undo'),
    redo: () => log.add('redo'),
  );
  return (actions: actions, log: log);
}

/// What pressing [key] with the modifiers does under [platform], in the
/// order the actions ran.
List<String> _pressed(
  TargetPlatform platform,
  LogicalKeyboardKey key, {
  bool control = false,
  bool alt = false,
  bool meta = false,
  bool shift = false,
}) {
  final (:actions, :log) = _recorder();
  final bindings = sourceShortcuts(actions, platform: platform);
  for (final entry in bindings.entries) {
    final activator = entry.key;
    if (activator is SingleActivator &&
        activator.trigger == key &&
        activator.control == control &&
        activator.alt == alt &&
        activator.meta == meta &&
        activator.shift == shift) {
      entry.value();
    }
  }
  return log;
}

void main() {
  const apple = <TargetPlatform>[TargetPlatform.macOS, TargetPlatform.iOS];

  for (final platform in apple) {
    group('on ${platform.name}', () {
      test('⌥← and ⌥→ move by a word, with Shift they select one', () {
        expect(_pressed(platform, LogicalKeyboardKey.arrowLeft, alt: true), [
          'wordLeft',
        ]);
        expect(_pressed(platform, LogicalKeyboardKey.arrowRight, alt: true), [
          'wordRight',
        ]);
        expect(
          _pressed(
            platform,
            LogicalKeyboardKey.arrowLeft,
            alt: true,
            shift: true,
          ),
          ['wordLeft extend'],
        );
        expect(
          _pressed(
            platform,
            LogicalKeyboardKey.arrowRight,
            alt: true,
            shift: true,
          ),
          ['wordRight extend'],
        );
      });

      test('⌘← and ⌘→ go to the ends of the line', () {
        expect(_pressed(platform, LogicalKeyboardKey.arrowLeft, meta: true), [
          'lineTextStart',
        ]);
        expect(_pressed(platform, LogicalKeyboardKey.arrowRight, meta: true), [
          'lineEnd',
        ]);
        expect(
          _pressed(
            platform,
            LogicalKeyboardKey.arrowRight,
            meta: true,
            shift: true,
          ),
          ['lineEnd extend'],
        );
      });

      test('⌘↑ and ⌘↓ go to the ends of the note', () {
        expect(_pressed(platform, LogicalKeyboardKey.arrowUp, meta: true), [
          'documentStart',
        ]);
        expect(_pressed(platform, LogicalKeyboardKey.arrowDown, meta: true), [
          'documentEnd',
        ]);
        expect(
          _pressed(
            platform,
            LogicalKeyboardKey.arrowUp,
            meta: true,
            shift: true,
          ),
          ['documentStart extend'],
        );
      });

      test('⌥⌫ deletes a word and ⌘⌫ the line before the caret', () {
        expect(_pressed(platform, LogicalKeyboardKey.backspace, alt: true), [
          'deleteBackward word',
        ]);
        expect(_pressed(platform, LogicalKeyboardKey.backspace, meta: true), [
          'deleteTo lineStart',
        ]);
        expect(_pressed(platform, LogicalKeyboardKey.delete, alt: true), [
          'deleteForward word',
        ]);
        expect(_pressed(platform, LogicalKeyboardKey.delete, meta: true), [
          'deleteTo lineEnd',
        ]);
      });

      test("Ctrl+← is not a word motion: it is the system's", () {
        expect(
          _pressed(platform, LogicalKeyboardKey.arrowLeft, control: true),
          isEmpty,
        );
      });

      test('the clipboard and undo are ⌘ chords', () {
        expect(_pressed(platform, LogicalKeyboardKey.keyC, meta: true), [
          'copy',
        ]);
        expect(_pressed(platform, LogicalKeyboardKey.keyZ, meta: true), [
          'undo',
        ]);
        expect(
          _pressed(platform, LogicalKeyboardKey.keyZ, meta: true, shift: true),
          ['redo'],
        );
      });
    });
  }

  group('on Windows and Linux', () {
    for (final platform in <TargetPlatform>[
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      test('${platform.name}: Ctrl moves by words and to the ends', () {
        expect(
          _pressed(platform, LogicalKeyboardKey.arrowLeft, control: true),
          ['wordLeft'],
        );
        expect(
          _pressed(
            platform,
            LogicalKeyboardKey.arrowRight,
            control: true,
            shift: true,
          ),
          ['wordRight extend'],
        );
        expect(_pressed(platform, LogicalKeyboardKey.home, control: true), [
          'documentStart',
        ]);
        expect(
          _pressed(platform, LogicalKeyboardKey.backspace, control: true),
          ['deleteBackward word'],
        );
        // The Mac's chords are not bound.
        expect(
          _pressed(platform, LogicalKeyboardKey.arrowLeft, meta: true),
          isEmpty,
        );
      });
    }
  });

  test('without a platform given, the platform the app runs on', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final (:actions, :log) = _recorder();
    final bindings = sourceShortcuts(actions);
    final wordLeft = bindings.entries.firstWhere(
      (entry) =>
          entry.key is SingleActivator &&
          (entry.key as SingleActivator).trigger ==
              LogicalKeyboardKey.arrowLeft &&
          (entry.key as SingleActivator).alt &&
          !(entry.key as SingleActivator).shift,
    );
    wordLeft.value();
    expect(log, ['wordLeft']);
  });

  group('the selectors the Apple text system sends', () {
    /// What the selector asked for, or null when it is not one we answer.
    List<String>? asked(String selector) {
      final (:actions, :log) = _recorder();
      return performAppleSelector(selector, actions) ? log : null;
    }

    test('moves', () {
      expect(asked('moveLeft:'), ['characterLeft']);
      expect(asked('moveRightAndModifySelection:'), ['characterRight extend']);
      expect(asked('moveWordLeft:'), ['wordLeft']);
      expect(asked('moveWordRightAndModifySelection:'), ['wordRight extend']);
      expect(asked('moveToBeginningOfLine:'), ['lineTextStart']);
      expect(asked('moveToLeftEndOfLine:'), ['lineTextStart']);
      expect(asked('moveToRightEndOfLineAndModifySelection:'), [
        'lineEnd extend',
      ]);
      expect(asked('moveToEndOfParagraph:'), ['lineEnd']);
      expect(asked('moveToBeginningOfDocument:'), ['documentStart']);
      expect(asked('moveToEndOfDocumentAndModifySelection:'), [
        'documentEnd extend',
      ]);
      expect(asked('moveUp:'), ['rows -1']);
      expect(asked('moveDownAndModifySelection:'), ['rows 1 extend']);
      expect(asked('pageUpAndModifySelection:'), ['page -1 extend']);
    });

    test('deletions', () {
      expect(asked('deleteBackward:'), ['deleteBackward']);
      expect(asked('deleteForward:'), ['deleteForward']);
      expect(asked('deleteWordBackward:'), ['deleteBackward word']);
      expect(asked('deleteWordForward:'), ['deleteForward word']);
      expect(asked('deleteToBeginningOfLine:'), ['deleteTo lineStart']);
      expect(asked('deleteToEndOfLine:'), ['deleteTo lineEnd']);
    });

    test('the rest of the text commands', () {
      expect(asked('selectAll:'), ['selectAll']);
      expect(asked('insertTab:'), ['tab true']);
      expect(asked('insertBacktab:'), ['tab false']);
    });

    test('a selector nobody here knows is said so', () {
      expect(asked('transpose:'), isNull);
      expect(asked('cancelOperation:'), isNull);
      expect(asked('moveToBeginningOfLineAndFly:'), isNull);
    });

    test('every motion a selector names is one the key table has', () {
      // The two tables say the same thing: no selector goes somewhere its
      // chord does not.
      final (:actions, :log) = _recorder();
      final bound = <String>{};
      for (final entry in sourceShortcuts(
        actions,
        platform: TargetPlatform.macOS,
      ).entries) {
        entry.value();
        bound.addAll(log);
        log.clear();
      }
      for (final selector in <String>[
        'moveWordLeft:',
        'moveWordRight:',
        'moveToLeftEndOfLine:',
        'moveToRightEndOfLine:',
        'moveToBeginningOfDocument:',
        'moveToEndOfDocument:',
        'moveToBeginningOfParagraph:',
        'moveToEndOfParagraph:',
      ]) {
        final result = asked(selector)!.single;
        expect(bound, contains(result), reason: selector);
      }
    });
  });
}
