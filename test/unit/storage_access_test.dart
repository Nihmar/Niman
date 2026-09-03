// Unit tests for StorageAccess.
//
// The Android side is a platform channel into the system settings screen,
// so only the off-Android behaviour is unit-testable: both calls must be
// a silent success on Linux, where shared storage has no such gate.

import 'package:copist/src/core/storage_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('has/ensure are a no-op success off Android', () async {
    expect(await StorageAccess.hasAllFilesAccess(), isTrue);
    expect(await StorageAccess.ensureAllFilesAccess(), isTrue);
  });
}
