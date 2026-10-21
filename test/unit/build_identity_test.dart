import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/build_identity.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an exported log names its build, its system and its screens', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Niman',
      packageName: 'dev.niman.niman',
      version: '0.2.7',
      buildNumber: '42',
      buildSignature: '',
    );
    final lines = await buildIdentity();
    expect(
      lines.first,
      startsWith('# app: 0.2.7+42, release channel, debug build, commit '),
    );
    expect(lines, contains(matches(RegExp(r'^# system: \w+ .*, \d+ cores$'))));
    expect(
      lines,
      contains(matches(RegExp(r'^# display \d+: \d+×\d+ px at .*x, \d+ Hz$'))),
    );
    expect(lines.last, '# frames: NIMAN_FRAMES off');
  });
}
