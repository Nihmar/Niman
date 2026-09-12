/// Note creation from a template (#51, T-M4-07): picker, questions,
/// directives, render, file, open. The shell owns the selection state;
/// this flow reads what it needs through callbacks and reports the filed
/// note back, so no setState lives here.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/templates/counters.dart';
import 'package:niman/src/templates/directives.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/templates/includes.dart';
import 'package:niman/src/templates/prompts.dart';
import 'package:niman/src/ui/name_dialog.dart';
import 'package:niman/src/ui/note_picker.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/template_form.dart';
import 'package:niman/src/ui/template_picker.dart';

/// The selection the creation starts from: the selected path, whether it
/// is a folder, and whether the tree (not a note) is on screen.
typedef TemplateOrigin = ({String? selected, bool isDir, bool treeVisible});

/// Creates notes from the library's templates.
final class ShellTemplateFlow {
  /// Creates the flow; the session outlives the shell, the callbacks
  /// read the shell's live state.
  new({
    required this.controller,
    required this.origin,
    required this.createParent,
    required this.guard,
    required this.opensPreviewOnly,
    required this.onNoteFiled,
  });

  /// The open library's session.
  final LibrarySession controller;

  /// Where the creation starts from (tree or note on screen).
  final TemplateOrigin Function() origin;

  /// Parent path for new note/folder creation.
  final String Function() createParent;

  /// Serializes mutating flows, reporting errors.
  final Future<void> Function(Future<void> Function() action) guard;

  /// Whether a note opens in preview-only mode.
  final bool Function() opensPreviewOnly;

  /// Reports the filed note: its path, whether the preview shows, and a
  /// template `{{cursor}}` offset for the caret (null when appending).
  final void Function({
    required String path,
    required bool preview,
    required int? caret,
  })
  onNoteFiled;

  /// Creates a note from a template in [parent] (default: the FAB
  /// target), T-M4-07.
  ///
  /// Template first, then name: which template you want is the decision,
  /// and the name often follows from it. The template's text — frontmatter
  /// included — becomes the note's, with its placeholders substituted
  /// against the name just chosen.
  ///
  /// A template that names its own notes (`niman: filename:`, T-TPL-02)
  /// is not asked about: it already answered. The rest of its directives
  /// decide the folder, whether a second use adds to the file instead of
  /// making a new one, and what happens once the note exists.
  Future<void> createFromTemplate(
    BuildContext context, {
    String? parent,
  }) async {
    final source = await controller.templateSource;
    if (source == null || !context.mounted) return;
    final templates = await source.templates();
    final folder = await source.folder;
    if (!context.mounted) return;
    final chosen = await showTemplatePicker(
      context,
      templates: templates,
      folder: folder,
    );
    if (chosen == null || !context.mounted) return;
    // The backlink's hint is read now, while the picker still holds the
    // screen: the selection cannot move until it closes, so this is what
    // the form below would read.
    final parentName = parentNoteName(context, templateFolder: folder);
    final ops = controller.ops!;
    final String template;
    try {
      // Includes first (T-TPL-06): the pasted text is then read like the
      // rest of the file, so its placeholders are substituted and its
      // own questions join the same form.
      template = await expandTemplateIncludes(
        await ops.readNote(chosen.path),
        sourcePath: chosen.path,
        resolve: (written) => resolveInclude(ops, folder, written),
      );
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
      return;
    }
    // The template's own questions first (T-TPL-03): an answer can name
    // the file and pick the folder, so it has to exist before either is
    // decided.
    //
    // The backlink joins them as a field of its own when the template
    // wants one (user, 2026-09-10): the note it points at is a choice,
    // and the app guessing it from wherever the user happened to be is
    // what got it wrong. The note on screen is only the suggestion.
    final wantsBacklink = templateUses(template, 'parent');
    final fields = <TemplateField>[
      if (wantsBacklink)
        TemplateField(
          label: parentFieldLabel,
          title: AppStrings.templateFormBacklink,
          kind: TemplateFieldKind.note,
          hint: parentName,
        ),
      ...templateFields(template),
    ];
    var answers = <String, String>{};
    if (fields.isNotEmpty) {
      if (!context.mounted) return;
      final given = await showTemplateForm(
        context,
        fields: fields,
        pickNote: () => pickBacklinkNote(context),
      );
      if (given == null) return;
      answers = given;
    }
    // Where the note is being made from (T-TPL-04). The clipboard is
    // read once, here, rather than per occurrence — two `{{clipboard}}`
    // in one template must not be able to disagree — and only for a
    // template that asks for it, so using any other template never
    // reaches into what the user copied.
    final surroundings = TemplateContext(
      parent: answers.remove(parentFieldLabel) ?? '',
      clipboard: templateUses(template, 'clipboard')
          ? await clipboardText()
          : '',
    );
    // Per-creation counters (#52): every `{{counter:name}}` in this note
    // — directives reads and body alike — shares one memoized number, and
    // nothing is persisted until the note below is actually created, so a
    // cancelled creation burns no numbers. A template with no counter
    // never touches the store file at all.
    final root = controller.root;
    final counters = templateUses(template, 'counter') && root != null
        ? await CounterStore.load(root)
        : null;
    int Function(String)? counter;
    if (counters != null) {
      final store = counters;
      final used = <String, int>{};
      counter = (name) => used.putIfAbsent(name, () => store.use(name));
    }
    // Read once with no title, only to find out whether the template
    // names the note itself; the real read happens below, once the name
    // is known, so a folder may be built from it.
    final declared = readTemplateDirectives(
      template,
      answers: answers,
      context: surroundings,
      counter: counter,
    );
    final String name;
    if (declared.namesItself) {
      name = declared.filename!;
    } else {
      if (!context.mounted) return;
      final asked = await showNameDialog(
        context,
        title: AppStrings.newFromTemplateTitle,
        initial: chosen.name.split('/').last,
      );
      if (asked == null) return;
      name = asked;
    }
    await guard(() async {
      final directives = readTemplateDirectives(
        template,
        title: name,
        answers: answers,
        context: surroundings,
        counter: counter,
      );
      final target =
          directives.folder ??
          awayFromTemplates(parent ?? createParent(), folder);
      // The body is rendered after the folder is settled, which is the
      // only reason `{{folder}}` can answer at all.
      final rendered = renderTemplateWithCaret(
        template,
        title: name,
        answers: answers,
        context: surroundings.withFolder(target),
        counter: counter,
      );
      final content = rendered.text;
      if (directives.folder case final wanted? when wanted.isNotEmpty) {
        await ops.ensureFolder(wanted);
      }
      final row = directives.append
          ? await ops.appendToNote(resolvePath(target, '$name.md'), content)
          : await ops.createNote(
              parentPath: target,
              name: name,
              content: content,
            );
      await counters?.save();
      if (!context.mounted) return;
      // A template whose frontmatter does not parse declares nothing, and
      // used to do it in silence: its questions still appeared, so it
      // looked like it was working while the folder and the name it asked
      // for did nothing (user, 2026-09-10).
      if (directives.error case final reason?) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.templateFrontmatterInvalid(chosen.name, reason),
            ),
          ),
        );
      }
      if (directives.open == TemplateOpen.none) {
        // The template filed something away; the user was in the middle
        // of something else and stays there.
        controller.notify();
        return;
      }
      if (opensPreviewOnly()) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      onNoteFiled(
        path: row.path,
        preview: directives.open == TemplateOpen.preview,
        caret: directives.append ? null : rendered.caret,
      );
    });
  }

  /// Asks which note a template's `[[{{parent}}]]` should point at, and
  /// answers with the name the link is written under.
  ///
  /// The name, not the path: a wikilink resolves by name, so that is what
  /// goes in the note.
  Future<String?> pickBacklinkNote(BuildContext context) async {
    final path = await showNotePicker(
      context,
      controller: controller,
      title: AppStrings.templateFormPickNote,
    );
    if (path == null) return null;
    final name = path.split('/').last;
    return isMarkdownNote(name) ? name.substring(0, name.length - 3) : name;
  }

  /// Where a template-made note goes when the template did not say, kept
  /// out of [templateFolder].
  ///
  /// Writing a template is exactly when someone tries one out, so the FAB
  /// is often pressed with the template itself open — and the note it
  /// makes must not land among the templates, where it would then be
  /// offered as one. The library root is the honest fallback: the
  /// template said nothing about where to file this, and neither did the
  /// place the user happened to be standing (user, 2026-09-10).
  String awayFromTemplates(String target, String templateFolder) {
    if (templateFolder.isEmpty) return target;
    if (target == templateFolder || isUnder(templateFolder, target)) return '';
    return target;
  }

  /// Finds the template an `{{include:…}}` names (T-TPL-06).
  ///
  /// Tried inside the template folder first, then from the library root,
  /// with the `.md` added when it was left off — a partial lives beside
  /// the templates that use it, and `{{include:_header}}` is what a
  /// person writes.
  Future<({String path, String text})?> resolveInclude(
    NoteOperations ops,
    String templateFolder,
    String written,
  ) async {
    final name = isMarkdownNote(written) ? written : '$written.md';
    final cleaned = name.split('/').where((s) => s.isNotEmpty && s != '..');
    if (cleaned.isEmpty) return null;
    final relative = cleaned.join('/');
    for (final candidate in <String>{
      resolvePath(templateFolder, relative),
      relative,
    }) {
      final row = await ops.find(candidate);
      if (row == null || row.isDir) continue;
      return (path: candidate, text: await ops.readNote(candidate));
    }
    return null;
  }

  /// The name of the note the creation is starting from, without the
  /// `.md`, or empty when it is starting from the tree (T-TPL-04).
  ///
  /// What `{{parent}}` answers, and what makes `[[{{parent}}]]` in a
  /// template a link back to the page the new note was spun out of.
  ///
  /// A selection is not a place. Closing a note leaves it selected so the
  /// tree can highlight it, and on a phone the tree and the note take
  /// turns — so pressing the FAB on the file list is not "coming from"
  /// whatever was open before it. Only a note actually on screen counts
  /// (user, 2026-09-10).
  ///
  /// Never a template either: writing one is done with it open, and
  /// pressing the FAB from there produced `[[Personaggio]]`, a link to the
  /// template itself.
  String parentNoteName(BuildContext context, {String templateFolder = ''}) {
    final from = origin();
    final selected = from.selected;
    if (selected == null || from.isDir) return '';
    final narrow = MediaQuery.sizeOf(context).width < splitBreakpoint;
    if (narrow && from.treeVisible) return '';
    if (templateFolder.isNotEmpty && isUnder(templateFolder, selected)) {
      return '';
    }
    final name = selected.split('/').last;
    return isMarkdownNote(name) ? name.substring(0, name.length - 3) : name;
  }

  /// The clipboard's text, or empty — including when the platform
  /// refuses it, which some Linux sessions do with no clipboard owner,
  /// and when it simply never answers: a note being created must not be
  /// held up by a clipboard that is somebody else's problem.
  Future<String> clipboardText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      return data?.text ?? '';
    } on Object catch (error) {
      const AppLogger(name: 'shell')
          .debug('clipboard unreadable for a template: $error');
      return '';
    }
  }
}
