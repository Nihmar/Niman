// The sync's merge of `.niman/review.json` (#533), card by card, beside
// `mergeReadingJson` book by book.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/review_store.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/state_merge.dart';

String json(Map<String, Object?> m) => jsonEncode(m);

Map<String, Object?> parsed(String? text) =>
    (jsonDecode(text!) as Map).cast<String, Object?>();

Map<String, Object?> card(int interval, String at) => {
  'ef': 2.5,
  'interval': interval,
  'reps': 2,
  'due': '2026-10-20',
  'at': at,
};

const String early = '2026-10-14T09:00:00Z';
const String late = '2026-10-14T11:00:00Z';
const String earlier = '2026-10-13T09:00:00Z';

void main() {
  test('the file is one of the sync library state files', () {
    expect(libraryStateFiles, contains(ReviewStore.filePath));
    expect(jsonStateFiles, contains(ReviewStore.filePath));
  });

  test('decks studied on different sides both land', () {
    final merged = mergeReviewJson(
      base: json({}),
      local: json({
        'a.md': {'x': card(3, early)},
      }),
      remote: json({
        'b.md': {'y': card(7, late)},
      }),
    );
    expect(parsed(merged), {
      'a.md': {'x': card(3, early)},
      'b.md': {'y': card(7, late)},
    });
  });

  test('different cards of one deck on different sides both land', () {
    final merged = mergeReviewJson(
      base: json({
        'a.md': {'x': card(1, earlier)},
      }),
      local: json({
        'a.md': {'x': card(1, earlier), 'y': card(2, early)},
      }),
      remote: json({
        'a.md': {'x': card(1, earlier), 'z': card(3, late)},
      }),
    );
    expect(parsed(merged), {
      'a.md': {'x': card(1, earlier), 'y': card(2, early), 'z': card(3, late)},
    });
  });

  test('a card graded on both sides keeps the later grade', () {
    for (final (local, remote, kept) in [(early, late, 9), (late, early, 3)]) {
      final merged = mergeReviewJson(
        base: json({
          'a.md': {'x': card(1, earlier)},
        }),
        local: json({
          'a.md': {'x': card(3, local)},
        }),
        remote: json({
          'a.md': {'x': card(9, remote)},
        }),
      );
      expect(((parsed(merged)['a.md']! as Map)['x']! as Map)['interval'], kept);
    }
  });

  test('the later grade wins without a base, whatever the file dates', () {
    final merged = mergeReviewJson(
      base: null,
      local: json({
        'a.md': {'x': card(3, early)},
      }),
      remote: json({
        'a.md': {'x': card(9, late)},
      }),
    );
    expect(parsed(merged), {
      'a.md': {'x': card(9, late)},
    });
  });

  test('a card first graded on two devices keeps the earlier first day', () {
    Map<String, Object?> graded(int interval, String at, String first) => {
      ...card(interval, at),
      'first': first,
    };
    final merged = mergeReviewJson(
      base: null,
      local: json({
        'a.md': {'x': graded(1, early, '2026-10-14')},
      }),
      remote: json({
        'a.md': {'x': graded(6, late, '2026-10-13')},
      }),
    );
    expect(parsed(merged), {
      'a.md': {'x': graded(6, late, '2026-10-13')},
    });
    // One side without the field (an older build) leaves the other's.
    final legacy = mergeReviewJson(
      base: null,
      local: json({
        'a.md': {'x': card(1, late)},
      }),
      remote: json({
        'a.md': {'x': graded(2, early, '2026-10-13')},
      }),
    );
    expect(
      ((parsed(legacy)['a.md']! as Map)['x']! as Map)['first'],
      '2026-10-13',
    );
  });

  test('a card present on one side only is kept without a base', () {
    final merged = mergeReviewJson(
      base: null,
      local: json({
        'a.md': {'x': card(3, early)},
      }),
      remote: json({
        'a.md': {'y': card(9, late)},
      }),
    );
    expect(parsed(merged), {
      'a.md': {'x': card(3, early), 'y': card(9, late)},
    });
  });

  group('a card or a note the other side dropped', () {
    final base = json({
      'a.md': {'x': card(1, earlier), 'y': card(1, earlier)},
    });

    test('is dropped when this side did not review it since', () {
      final merged = mergeReviewJson(
        base: base,
        local: json({
          'a.md': {'x': card(1, earlier)},
        }),
        remote: base,
      );
      expect(parsed(merged), {
        'a.md': {'x': card(1, earlier)},
      });
    });

    test('whole note: deleted on one side, untouched on the other', () {
      final merged = mergeReviewJson(base: base, local: json({}), remote: base);
      expect(parsed(merged), isEmpty);
      final other = mergeReviewJson(base: base, local: base, remote: json({}));
      expect(parsed(other), isEmpty);
    });

    test('is kept when this side reviewed it since', () {
      final merged = mergeReviewJson(
        base: base,
        local: json({}),
        remote: json({
          'a.md': {'x': card(1, earlier), 'y': card(6, late)},
        }),
      );
      expect(parsed(merged), {
        'a.md': {'y': card(6, late)},
      });
    });

    test('a note carried to a new name is not brought back', () {
      final merged = mergeReviewJson(
        base: base,
        local: json({
          'new.md': {'x': card(1, earlier), 'y': card(1, earlier)},
        }),
        remote: base,
      );
      expect(parsed(merged), {
        'new.md': {'x': card(1, earlier), 'y': card(1, earlier)},
      });
    });

    test('a reset deck stays reset, unless the other side studied it', () {
      final reset = mergeReviewJson(
        base: base,
        local: json({}),
        remote: json({
          'a.md': {'x': card(1, earlier), 'y': card(1, earlier)},
        }),
      );
      expect(parsed(reset), isEmpty);
    });
  });

  test('keeps the same text when nothing differs', () {
    final text = json({
      'a.md': {'x': card(3, early)},
    });
    final merged = mergeReviewJson(base: text, local: text, remote: text);
    expect(parsed(merged), parsed(text));
    expect(merged!.endsWith('\n'), isTrue);
  });

  test('an entry that does not read is carried as it is, or dropped', () {
    final merged = mergeReviewJson(
      base: null,
      local: json({
        'a.md': {'x': 'garbage'},
        'b.md': 'not an object',
      }),
      remote: json({
        'a.md': {'y': card(2, late)},
      }),
    );
    expect(parsed(merged), {
      'a.md': {'x': 'garbage', 'y': card(2, late)},
    });
  });

  test('a side that is not a JSON object cannot be merged', () {
    expect(mergeReviewJson(base: null, local: '{', remote: json({})), isNull);
    expect(mergeReviewJson(base: null, local: json({}), remote: '[]'), isNull);
  });
}
