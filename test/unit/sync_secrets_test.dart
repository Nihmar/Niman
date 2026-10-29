import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/sync_secrets.dart';
import 'package:path/path.dart' as p;

/// The Mac Keychain as a build without the `keychain-access-groups`
/// entitlement meets it (#1244): the data protection keychain refuses what
/// is written to it with `errSecMissingEntitlement` and finds nothing, while
/// the login keychain (`usesDataProtectionKeychain: false`) keeps the entry.
/// [failure] stands in for a keychain error that is not that one.
final class _Keychain extends FlutterSecureStoragePlatform {
  /// What the login keychain holds.
  final Map<String, String> values = {};

  /// Thrown by every call instead of the simulated Keychain, when set.
  PlatformException? failure;

  /// How many writes reached the data protection keychain.
  int dataProtectionWrites = 0;

  static bool _dataProtection(Map<String, String> options) =>
      options['usesDataProtectionKeychain'] == 'true';

  static Never _refuse() => throw PlatformException(
    code: '-34018',
    message: 'A required entitlement is not present.',
    details: -34018,
  );

  void _check(Map<String, String> options) {
    final failure = this.failure;
    if (failure != null) throw failure;
    if (_dataProtection(options)) _refuse();
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    if (_dataProtection(options)) dataProtectionWrites++;
    _check(options);
    values[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    // What the log of a Mac without the entitlement reads: "none", not an
    // error (a query that finds nothing needs no entitlement to run).
    if (_dataProtection(options)) return null;
    return values[key];
  }

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    _check(options);
    values.remove(key);
  }

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async {
    _check(options);
    return values.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async {
    _check(options);
    return values;
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    _check(options);
    values.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('one entry per normalized library path; never logged', () async {
    AppLog.clear();
    final store = SecureSyncSecretStore();
    final work = p.join('libraries', 'Work');
    await store.write('$work${p.separator}', 'pa55-word');
    expect(await store.read(work), 'pa55-word');
    expect(await store.read(p.join('libraries', 'Home')), isNull);
    expect(
      await const FlutterSecureStorage().read(
        key: SecureSyncSecretStore.keyOf(work),
      ),
      'pa55-word',
    );
    expect(SecureSyncSecretStore.keyOf(work), 'sync.$work');

    await store.write(work, 'changed');
    expect(await store.read(work), 'changed');
    await store.delete(work);
    expect(await store.read(work), isNull);
    await store.delete(work); // no-op

    expect(AppLog.dump(), isNot(contains('pa55-word')));
    expect(AppLog.dump(), isNot(contains('changed')));
  });

  group('macOS without the keychain entitlement (#1244)', () {
    final work = p.join('libraries', 'Work');
    final key = SecureSyncSecretStore.keyOf(work);
    late _Keychain keychain;

    setUp(() {
      // The plugin picks its options by the target platform, and so does the
      // store: a Mac build is what the test stands in for on any host.
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      FlutterSecureStoragePlatform.instance = keychain = _Keychain();
    });

    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test(
      'the password goes to the login keychain, and later saves too',
      () async {
        final store = SecureSyncSecretStore();
        await store.write(work, 'pa55-word');
        expect(keychain.values, {key: 'pa55-word'});
        expect(
          keychain.dataProtectionWrites,
          1,
          reason: 'tried, then answered',
        );
        expect(await store.read(work), 'pa55-word');

        await store.write(work, 'changed');
        expect(keychain.values, {key: 'changed'});
        expect(
          keychain.dataProtectionWrites,
          1,
          reason: 'the keychain that refused is not asked again',
        );

        await store.delete(work);
        expect(keychain.values, isEmpty);
        expect(await store.read(work), isNull);
        expect(AppLog.dump(), isNot(contains('pa55-word')));
      },
    );

    test(
      'an entry already there is found, and the store stays on it',
      () async {
        keychain.values[key] = 'stored';
        final store = SecureSyncSecretStore();
        expect(await store.read(work), 'stored');

        await store.write(work, 'changed');
        expect(keychain.values[key], 'changed');
        expect(
          keychain.dataProtectionWrites,
          0,
          reason: 'the entry it found is in the login keychain',
        );
      },
    );

    test('another keychain failure is not taken for the missing '
        'entitlement', () async {
      keychain.failure = PlatformException(
        code: '-25308',
        message: 'User interaction is not allowed.',
      );
      await expectLater(
        SecureSyncSecretStore().write(work, 'pw'),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', '-25308'),
        ),
      );
      expect(keychain.values, isEmpty);
    });
  });
}
