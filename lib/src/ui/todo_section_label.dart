import 'package:niman/src/todo/todo_sections.dart';
import 'package:niman/src/ui/strings.dart';

/// The heading of the todo section [id] (see `todoSections`).
///
/// The due sections reuse the due-range labels, so a heading and the
/// filter that selects the same tasks read alike. The flat list's `all`
/// section has no heading (empty), and so does an id this build does not
/// know, e.g. one remembered by a newer version.
String todoSectionLabel(String id) {
  switch (id) {
    case todoDueOverdueSectionId:
      return AppStrings.todoDueOverdue;
    case todoDueTodaySectionId:
      return AppStrings.todoDueToday;
    case todoDueNext7SectionId:
      return AppStrings.todoDueNext7;
    case todoDueLaterSectionId:
      return AppStrings.todoSectionLater;
    case todoDueNoneSectionId:
      return AppStrings.todoDueNoDate;
    case todoPriorityNoneSectionId:
      return AppStrings.todoSectionNoPriority;
    case todoDoneSectionId:
      return AppStrings.todoDone;
    case todoAllSectionId:
      return '';
  }
  if (id.startsWith(todoPrioritySectionPrefix) &&
      id.length == todoPrioritySectionPrefix.length + 1) {
    return AppStrings.todoSectionPriority(
      id.substring(todoPrioritySectionPrefix.length),
    );
  }
  return '';
}
