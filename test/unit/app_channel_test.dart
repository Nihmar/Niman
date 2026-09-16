import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/app_channel.dart';

void main() {
  // The test bed defines no APP_CHANNEL, so the define's default must
  // read as the release channel: update management stays on, and a
  // build command that forgets the define ships release behavior, not
  // a half-disabled testing build (issue #106).
  test('the default channel is release and not a testing build', () {
    expect(appChannel, 'release');
    expect(isTestingBuild, isFalse);
  });
}
