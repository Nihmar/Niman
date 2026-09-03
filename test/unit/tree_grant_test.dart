// Unit tests for TreeGrant.

import 'package:copist/src/core/tree_grant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('takePersistent is a no-op success off Android', () async {
    expect(await TreeGrant.takePersistent('content://x/y'), isTrue);
  });
}
