// #1003: every section id has a heading, reusing the due-range strings.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/todo/todo_sections.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_section_label.dart';

void main() {
  setUp(AppLanguages.reset);
  tearDown(AppLanguages.reset);

  test('the due sections read like the due ranges', () {
    expect(
      todoSectionLabel(todoDueOverdueSectionId),
      AppStrings.todoDueOverdue,
    );
    expect(todoSectionLabel(todoDueTodaySectionId), AppStrings.todoDueToday);
    expect(todoSectionLabel(todoDueNext7SectionId), AppStrings.todoDueNext7);
    expect(todoSectionLabel(todoDueLaterSectionId), 'Later');
    expect(todoSectionLabel(todoDueNoneSectionId), AppStrings.todoDueNoDate);
  });

  test('the priority sections name their letter', () {
    expect(todoSectionLabel('priority.A'), 'Priority A');
    expect(todoSectionLabel('priority.Z'), 'Priority Z');
    expect(todoSectionLabel(todoPriorityNoneSectionId), 'No priority');
  });

  test('Done is labelled, the flat list and unknown ids are not', () {
    expect(todoSectionLabel(todoDoneSectionId), AppStrings.todoDone);
    expect(todoSectionLabel(todoAllSectionId), isEmpty);
    expect(todoSectionLabel('priority.'), isEmpty);
    expect(todoSectionLabel('priority.AB'), isEmpty);
    expect(todoSectionLabel('something.else'), isEmpty);
  });

  test('the labels follow the language', () {
    AppLanguages.choice = AppLanguage.italian;
    expect(todoSectionLabel('priority.B'), 'Priorità B');
    expect(todoSectionLabel(todoDueLaterSectionId), 'Più avanti');
    expect(todoSectionLabel(todoPriorityNoneSectionId), 'Senza priorità');
  });
}
