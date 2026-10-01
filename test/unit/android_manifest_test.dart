// The widget background receivers carry a `niman://` URI that ends in a
// note read and write, so an exported receiver without a guard lets any
// installed app send one (issue #332). This pins the manifest half of the
// fix: the app's signature permission on both receivers of the background
// action.
//
// Issue #383 is the other manifest half: the default `allowBackup` is true,
// and the app's databases hold the private sync destination (URL, username)
// and the library paths, while the support folder holds the crash reports
// and the debug log. Auto-backup off is what keeps them off Google's servers
// and off a device-to-device transfer.
//
// Run from the package root, like `flutter test` does.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// The manifest of the Android source set [sourceSet] (`main`, `debug`,
/// `beta`, …).
File manifestFile(String sourceSet) =>
    File(p.join('android', 'app', 'src', sourceSet, 'AndroidManifest.xml'));

void main() {
  test('the widget background receivers ask for the signature permission', () {
    final file = manifestFile('main');
    expect(file.existsSync(), isTrue, reason: 'run from the package root');
    final manifest = XmlDocument.parse(file.readAsStringSync());

    // Named after the application ID, so the official app keeps
    // `dev.niman.niman.permission.WIDGET_TAP` and the beta gets a name of its
    // own: two packages signed with different keys cannot define the same
    // permission, and a fixed name kept the beta from installing next to the
    // official app.
    const permission = r'${applicationId}.permission.WIDGET_TAP';
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

  test('auto-backup is off, so the private databases stay on the device', () {
    final application = XmlDocument.parse(
      manifestFile('main').readAsStringSync(),
    ).rootElement.findElements('application').single;
    expect(
      application.getAttribute('android:allowBackup'),
      'false',
      reason:
          'the backup would carry the sync destination (URL and username), '
          'the library paths, the crash reports and the debug log',
    );

    // The source sets merge over this one, and one of them declaring the
    // attribute would put it back on. None does, and none may.
    for (final sourceSet in ['debug', 'profile', 'beta']) {
      final file = manifestFile(sourceSet);
      if (!file.existsSync()) continue;
      for (final flavor in XmlDocument.parse(
        file.readAsStringSync(),
      ).rootElement.findElements('application')) {
        expect(
          flavor.getAttribute('android:allowBackup'),
          isNot('true'),
          reason: '${file.path} turns auto-backup back on',
        );
      }
    }
  });
}
