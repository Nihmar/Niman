// T-TPL-08 AC: every placeholder and filter this build substitutes is on
// the reference page, reachable from the settings row next to the
// template folder.
import 'package:copist/src/core/language.dart';
import 'package:copist/src/ui/settings.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/template_help.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    AppLanguages.reset();
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    AppLanguages.reset();
  });

  /// Pumps the reference on its own, tall enough that the lazy list
  /// builds all of it.
  Future<void> pumpHelp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TemplateHelpScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('the reference names every placeholder that is substituted', (
    tester,
  ) async {
    await pumpHelp(tester);

    // The values, the questions, the surroundings and the include: a
    // placeholder this build fills but the page never mentions is one a
    // user cannot find out about.
    for (final placeholder in const [
      '{{title}}',
      '{{now}}',
      '{{uuid}}',
      '{{parent}}',
      '{{folder}}',
    ]) {
      expect(
        find.textContaining(placeholder),
        findsWidgets,
        reason: '$placeholder is missing from the reference',
      );
    }
    expect(find.textContaining('{{date}}'), findsWidgets);
    expect(find.textContaining('{{ask:'), findsWidgets);
    expect(find.textContaining('{{choice:'), findsWidgets);
    expect(find.textContaining('{{clipboard}}'), findsWidgets);
    expect(find.textContaining('{{selection}}'), findsWidgets);
    expect(find.textContaining('{{include:'), findsWidgets);
  });

  testWidgets('the filters and the date tokens are listed', (tester) async {
    await pumpHelp(tester);

    expect(find.textContaining('|upper'), findsWidgets);
    expect(find.textContaining('|slug'), findsWidgets);
    expect(find.textContaining('|pad:3'), findsWidgets);
    expect(find.textContaining('|default:'), findsWidgets);
    expect(find.textContaining('|+7d'), findsWidgets);
    expect(find.textContaining('|startof:week'), findsWidgets);
    expect(find.textContaining('YYYY'), findsWidgets);
    expect(find.textContaining('MMMM'), findsWidgets);
    expect(find.textContaining('dddd'), findsWidgets);
    expect(find.textContaining('WW'), findsWidgets);
  });

  testWidgets('the directive keys are listed', (tester) async {
    await pumpHelp(tester);

    expect(find.textContaining('folder:'), findsWidgets);
    expect(find.textContaining('filename:'), findsWidgets);
    expect(find.textContaining('append:'), findsWidgets);
    expect(find.textContaining('open:'), findsWidgets);
    expect(find.textContaining('copist:'), findsWidgets);
  });

  testWidgets('it speaks the app language', (tester) async {
    AppLanguages.choice = AppLanguage.italian;
    await pumpHelp(tester);

    expect(find.text(AppStrings.templateHelpTitle), findsOneWidget);
    expect(find.textContaining('modello'), findsWidgets);
  });

  testWidgets('the settings row next to the template folder opens it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SettingsBody(controller: controller))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('template-help-setting')), findsOneWidget);
    await tester.tap(find.byKey(const Key('template-help-setting')));
    await tester.pumpAndSettle();

    expect(find.byType(TemplateHelpScreen), findsOneWidget);
  });
}
