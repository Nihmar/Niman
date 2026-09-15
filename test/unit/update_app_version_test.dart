// Issue #81: auto-update version parsing and comparison.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/update/app_version.dart';

void main() {
  group('parse', () {
    test('plain X.Y.Z', () {
      expect(AppVersion.parse('1.2.3'), const AppVersion(1, 2, 3));
    });

    test('tag form with v prefix and whitespace', () {
      expect(AppVersion.parse('  v0.0.3 '), const AppVersion(0, 0, 3));
    });

    test('rejects non-semver', () {
      expect(() => AppVersion.parse('1.2'), throwsFormatException);
      expect(() => AppVersion.parse('v1.2.3.4'), throwsFormatException);
      expect(() => AppVersion.parse('main'), throwsFormatException);
      expect(() => AppVersion.parse('1.x.3'), throwsFormatException);
      expect(() => AppVersion.parse(''), throwsFormatException);
    });

    test('tryParse returns null instead of throwing', () {
      expect(AppVersion.tryParse('nope'), isNull);
      expect(AppVersion.tryParse('v2.0.0'), const AppVersion(2, 0, 0));
    });
  });

  group('compareTo', () {
    test('orders by major, then minor, then patch', () {
      expect(
        const AppVersion(1, 0, 0).compareTo(const AppVersion(2, 0, 0)),
        lessThan(0),
      );
      expect(
        const AppVersion(1, 2, 0).compareTo(const AppVersion(1, 10, 0)),
        lessThan(0),
      );
      expect(
        const AppVersion(0, 0, 3).compareTo(const AppVersion(0, 0, 4)),
        lessThan(0),
      );
      expect(const AppVersion(1, 0, 0).compareTo(const AppVersion(1, 0, 0)), 0);
      expect(
        const AppVersion(2, 0, 0).compareTo(const AppVersion(1, 9, 9)),
        greaterThan(0),
      );
    });

    test('numeric, not lexicographic (10 > 9)', () {
      expect(
        AppVersion.parse('1.10.0').compareTo(AppVersion.parse('1.9.0')),
        greaterThan(0),
      );
    });
  });
}
