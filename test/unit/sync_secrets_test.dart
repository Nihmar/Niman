import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/sync_secrets.dart';
import 'package:path/path.dart' as p;

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
}
