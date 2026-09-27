// The widget background receivers carry a `niman://` URI that ends in a
// note read and write, so an exported receiver without a guard lets any
// installed app send one (issue #332). This pins the manifest half of the
// fix: the app's signature permission on both receivers of the background
// action.
//
// Run from the package root, like `flutter test` does.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  test('the widget background receivers ask for the signature permission', () {
    final file = File('android/app/src/main/AndroidManifest.xml');
    expect(file.existsSync(), isTrue, reason: 'run from the package root');
    final manifest = XmlDocument.parse(file.readAsStringSync());

    const permission = 'dev.niman.niman.permission.WIDGET_TAP';
    final declared = manifest.rootElement
        .findElements('permission')
        .where((e) => e.getAttribute('android:name') == permission)
        .toList();
    expect(declared, hasLength(1), reason: 'the permission is declared once');
    expect(
      declared.single.getAttribute('android:protectionLevel'),
      'signature',
      reason: 'only apps signed like this one may hold it',
    );

    const action = 'es.antonborri.home_widget.action.BACKGROUND';
    final receivers = manifest.rootElement
        .findAllElements('receiver')
        .where(
          (e) => e
              .findElements('intent-filter')
              .expand((f) => f.findElements('action'))
              .any((a) => a.getAttribute('android:name') == action),
        )
        .toList();
    expect(
      receivers,
      hasLength(2),
      reason: 'the tap receiver and the plugin worker',
    );
    for (final receiver in receivers) {
      expect(
        receiver.getAttribute('android:permission'),
        permission,
        reason:
            '${receiver.getAttribute('android:name')} accepts a write URI '
            'from any app without it',
      );
    }
  });
}
