/// The screen of the files open outside any library (#77).
///
/// The editor is the same one a note gets; what goes is everything a
/// library adds around it. There is no index, history or sync, the
/// frontmatter is text rather than a kind to draw, and links show without
/// being followed into a library. The toolbar has no image button, since
/// there is no attachments folder to copy an image into.
///
/// Each file keeps its own editor while it is open, undo and all, and
/// takes in a change something else makes to it on disk — unless it has
/// unsaved edits of its own, which win.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/editor_only.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/spellcheck/spell_check_provider.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/outside_files.dart';
import 'package:niman/src/ui/shell_preview_actions.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/title_bar.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/ui/window_controller.dart';

/// The toolbar without its image button.
const ToolbarLayout _outsideToolbar = ToolbarLayout(
  order: ToolbarItem.values,
  hidden: {ToolbarItem.image},
);

/// The outside files, a tab each.
final class OutsideFileScreen extends ConsumerStatefulWidget {
  /// Shows [files]; [documentFor] opens the next one asked for.
  const new({
    required this.files,
    this.documentFor = EditorOnlyDocument.new,
    super.key,
  });

  /// The files open outside the library.
  final OutsideFiles files;

  /// Opens a file picked from here.
  final EditorOnlyDocument Function(String path) documentFor;

  @override
  ConsumerState<OutsideFileScreen> createState() => _OutsideFileScreenState();
}

/// How one open file is shown.
final class _View {
  new(this.document);

  /// Stops following the file on disk.
  Future<void> dispose() async => await changes?.cancel();

  final EditorOnlyDocument document;
  final GlobalKey key = GlobalKey();
  bool preview = false;
  bool wysiwyg = false;
  int reloadToken = 0;
  StreamSubscription<void>? changes;
}

final class _OutsideFileScreenState extends ConsumerState<OutsideFileScreen> {
  final Map<String, _View> _views = {};

  @override
  void initState() {
    super.initState();
    widget.files.addListener(_onFilesChanged);
    _sync();
  }

  @override
  void dispose() {
    widget.files.removeListener(_onFilesChanged);
    for (final view in _views.values) {
      unawaited(view.dispose());
    }
    super.dispose();
  }

  void _onFilesChanged() {
    if (!mounted) return;
    if (widget.files.isEmpty) {
      // The last one closed: back where the user came from.
      Navigator.of(context).maybePop();
      return;
    }
    setState(_sync);
  }

  /// Opens a view for each new file, drops the ones closed.
  void _sync() {
    final open = {for (final d in widget.files.documents) d.filePath: d};
    for (final path in [..._views.keys]) {
      if (open.containsKey(path)) continue;
      unawaited(_views.remove(path)?.dispose());
    }
    for (final MapEntry(key: path, value: document) in open.entries) {
      _views.putIfAbsent(path, () {
        final view = _View(document);
        view.changes = document.changes().listen(
          (_) {
            if (mounted) setState(() => view.reloadToken++);
          },
          // A folder that cannot be watched only means no live reload.
          onError: (Object _) {},
        );
        return view;
      });
    }
  }

  Future<void> _openAnother() async {
    final path = await pickOutsideFile();
    if (path == null || !mounted) return;
    widget.files.open(widget.documentFor(path));
  }

  /// Opens the active file's find bar, [replace] and all.
  ///
  /// The editor hears Ctrl+F only with the caret in it; a file open on its
  /// own takes no focus into the editor by itself, so the screen binds the
  /// key over the file showing.
  void _openFind({bool replace = false}) {
    final path = widget.files.active?.filePath;
    final Object? state = path == null ? null : _views[path]?.key.currentState;
    if (state is NoteViewHandle) state.openFind(replace: replace);
  }

  void _closeActive() {
    final active = widget.files.active;
    if (active != null) widget.files.close(active.filePath);
  }

  @override
  Widget build(BuildContext context) {
    final window = ref.watch(windowControllerProvider);
    final active = widget.files.active;
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final title = active?.name ?? '';
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    final bindings = <ShortcutActivator, VoidCallback>{
      ...appShortcutBindings({
        AppCommand.closeTab: _closeActive,
        AppCommand.nextTab: () => widget.files.cycle(1),
        AppCommand.previousTab: () => widget.files.cycle(-1),
        AppCommand.openFile: () => unawaited(_openAnother()),
      }),
      // The editor's own keys, bound here too: with the focus outside the
      // editor the note's own handler never hears them.
      SingleActivator(LogicalKeyboardKey.keyF, control: !mac, meta: mac):
          _openFind,
      SingleActivator(
        LogicalKeyboardKey.keyF,
        control: !mac,
        meta: mac,
        alt: true,
      ): () =>
          _openFind(replace: true),
      if (!mac)
        const SingleActivator(LogicalKeyboardKey.keyH, control: true): () =>
            _openFind(replace: true),
    };
    return Scaffold(
      appBar: window.customTitleBar
          ? null
          : AppBar(title: Text(title, key: const Key('outside-file-title'))),
      body: CallbackShortcuts(
        bindings: bindings,
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              if (window.customTitleBar)
                SlimTitleBar(
                  key: const Key('outside-file-bar'),
                  title: title,
                  window: window,
                  leading: BackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              if (widget.files.documents.length > 1)
                _OutsideTabs(files: widget.files),
              if (active != null) _Where(document: active),
              const Divider(height: 1),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    for (final view in _views.values)
                      Offstage(
                        key: ValueKey('outside-${view.document.filePath}'),
                        offstage: view.document != active,
                        child: TickerMode(
                          enabled: view.document == active,
                          child: _note(view, wide: wide),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _note(_View view, {required bool wide}) {
    final document = view.document;
    return NoteView(
      key: view.key,
      path: document.filePath,
      showLineNumbers: true,
      autofocusEditor: false,
      toolbarTop: wide,
      toolbarLayout: _outsideToolbar,
      // A file outside a library links the way the rest of the world
      // does.
      linkType: LinkType.markdown,
      // Its images sit beside it, not under a library root.
      libraryRoot: document.folder,
      kindMode: false,
      showPreview: view.preview,
      showWysiwyg: view.wysiwyg,
      onEditorKindChanged: (kind) =>
          setState(() => view.wysiwyg = kind == EditorKind.wysiwyg),
      statusActions: [
        PreviewToggleAction(
          previewVisible: view.preview,
          onToggle: () => setState(() => view.preview = !view.preview),
          compact: true,
        ),
      ],
      readNote: (_) => document.read(),
      writeNote: (_, content) => document.write(content),
      reloadToken: view.reloadToken,
      unsavedTracker: ref.watch(unsavedTrackerProvider),
      spellCheck: ref.watch(spellCheckProvider),
    );
  }
}

/// Where the file on screen lives, and what being outside means.
final class _Where extends StatelessWidget {
  const new({required this.document});

  final EditorOnlyDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      key: const Key('outside-file-where'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: document.folder,
                    style: style?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' · ${AppStrings.outsideFileNote}'),
                ],
              ),
              style: style,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// One tab per outside file, when there is more than one.
final class _OutsideTabs extends StatelessWidget {
  const new({required this.files});

  final OutsideFiles files;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = files.active;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final document in files.documents)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              child: InputChip(
                key: Key('outside-tab-${document.name}'),
                label: Text(document.name),
                tooltip: document.filePath,
                selected: document == active,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                labelStyle: theme.textTheme.labelMedium,
                onPressed: () => files.show(document.filePath),
                deleteButtonTooltipMessage: AppStrings.closeTabTooltip,
                onDeleted: () => files.close(document.filePath),
              ),
            ),
        ],
      ),
    );
  }
}
