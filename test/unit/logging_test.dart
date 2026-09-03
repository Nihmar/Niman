import 'package:copist/src/core/logging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLogger logger;

  setUp(() {
    AppLog.clear();
    AppLog.enabled = true;
    logger = const AppLogger(name: 'unit');
  });

  test('events are buffered with timestamp, severity, name, and message', () {
    logger.info('hello world');
    final lines = AppLog.lines();
    expect(lines, hasLength(1));
    final line = lines.single;
    expect(line, contains('INFO'));
    expect(line, contains('[unit]'));
    expect(line, endsWith('hello world'));
    expect(line, matches(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3} ')));
  });

  test('severity labels are uppercased per level', () {
    logger
      ..debug('d')
      ..warning('w')
      ..error('e');
    expect(AppLog.lines(), [
      contains('DEBUG'),
      contains('WARNING'),
      contains('ERROR'),
    ]);
  });

  test('disabled logging buffers nothing', () {
    AppLog.enabled = false;
    logger
      ..info('dropped')
      ..error('also dropped');
    expect(AppLog.lines(), isEmpty);
    AppLog.enabled = true;
    logger.info('kept again');
    expect(AppLog.lines(), hasLength(1));
  });

  test('the buffer is capped at maxLines, dropping the oldest lines', () {
    for (var i = 0; i <= AppLog.maxLines; i++) {
      logger.debug('line $i');
    }
    final lines = AppLog.lines();
    expect(lines, hasLength(AppLog.maxLines));
    expect(lines.first, contains('line 1'));
    expect(lines.last, contains('line ${AppLog.maxLines}'));
  });

  test('dump joins the buffer; clear empties it', () {
    logger
      ..info('one')
      ..info('two');
    final dump = AppLog.dump();
    expect(dump.indexOf('one'), lessThan(dump.indexOf('two')));
    expect(dump, contains('\n'));
    AppLog.clear();
    expect(AppLog.dump(), isEmpty);
  });
}
