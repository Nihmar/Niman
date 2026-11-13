import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/calendar/calendar_source.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/launch_requests.dart';
import 'package:niman/src/core/share_in.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/storage_access.dart';
import 'package:niman/src/core/tray.dart';
import 'package:niman/src/editor/editor_only.dart';
import 'package:niman/src/export/export_files.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ocr/ocr_installation_provider.dart';
import 'package:niman/src/ocr/ocr_queue_provider.dart';
import 'package:niman/src/spellcheck/spell_check_provider.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/transcription/open_audio_notes.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/capture/capture_services.dart';
import 'package:niman/src/ui/close_to_tray.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/kinds/audio_transcript_writer.dart';
import 'package:niman/src/ui/open_library.dart';
import 'package:niman/src/ui/outside_files.dart';
import 'package:niman/src/ui/palette/pinned_commands.dart';
import 'package:niman/src/ui/shell.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/ui/update_banner.dart';
import 'package:niman/src/ui/welcome/welcome_gate.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/widget/widget_host.dart';
import 'package:niman/src/widget/widget_target.dart';
import 'package:niman/src/widget/widget_updater.dart';

/// Root screen: the open/create screen until a library is ready, then the
/// sidebar | detail shell (editor/preview arrive in M2).
final class LibraryHome extends ConsumerStatefulWidget {
  /// Creates the root screen.
  const new({super.key});

  @override
  ConsumerState<LibraryHome> createState() => _LibraryHomeState();
}

final class _LibraryHomeState extends ConsumerState<LibraryHome> {
  bool _resumeStarted = false;

  @override
  void initState() {
    super.initState();
    if (!_resumeStarted) {
      _resumeStarted = true;
      unawaited(_resume());
    }
    unawaited(_startLanguageAndActions());
    unawaited(_applyTheme());
    _listenToLaunches();
  }

  @override
  void dispose() {
    AppLanguages.revision.removeListener(_republishQuickActions);
    unawaited(_arrivals?.cancel());
    unawaited(_launchFiles?.cancel());
    unawaited(_launchFolders?.cancel());
    super.dispose();
  }

  /// The stored language, and only then the quick actions.
  ///
  /// Their labels are strings like any other, so they answer in whatever
  /// language is set when they are published — and publishing before the
  /// stored choice had landed handed the launcher the *system* language
  /// instead of the app's, on every launch (device report, 2026-09-10).
  Future<void> _startLanguageAndActions() async {
    await _applyLanguage();
    if (!mounted) return;
    await _publishQuickActions();
    // And again whenever the language changes under them: the settings
    // switch, or the OS locale moving while the app runs.
    AppLanguages.revision.addListener(_republishQuickActions);
  }

  void _republishQuickActions() => unawaited(_publishQuickActions());

  /// Applies the stored theme (T-M6-05).
  ///
  /// Read once at start, like the language: the app wears the device's
  /// colors until the choice lands, which is what it wears anyway unless
  /// the user picked a palette.
  Future<void> _applyTheme() async {
    final session = ref.read(librarySessionProvider);
    AppThemes.apply(
      brightness: await session.appSettings.themeBrightness,
      theme: await session.appSettings.theme,
    );
    // The keys this device was given (#159): read once, like the theme.
    AppKeyMap.current.value = KeyMap.fromJson(await session.appSettings.keyMap);
    // And the commands pinned in its palette (#208).
    await PinnedCommands.load(session);
    // Whether the window's × hides Niman to the tray (#209): the tray is
    // the desktops', so nowhere else hides. On a Mac it always does, to the
    // Dock, with no setting (decision 11 of docs/records/apple-platforms.md).
    CloseToTray.enabled.value =
        Platform.isMacOS ||
        ((Platform.isLinux || Platform.isWindows) &&
            await session.appSettings.closeToTray);
  }

  /// Applies the stored UI language (T-L10N-03).
  ///
  /// Read once at start: the app renders in the OS language until it
  /// lands, which is the same answer whenever the user never chose one.
  Future<void> _applyLanguage() async {
    AppLanguages.choice = await ref
        .read(librarySessionProvider)
        .appSettings
        .language;
  }

  /// Publishes the quick actions on every surface that takes a label map:
  /// the Android launcher (T-SC-02) and the desktop tray (T-PP-06b). Both
  /// carry the same ids, so both run the same flows.
  ///
  /// Here rather than in the shell: they belong to the app, not to an
  /// open library, so they are there on the very first launch too. Called
  /// again on every language change, so both surfaces speak the app's
  /// language and not the system's.
  Future<void> _publishQuickActions() async {
    final labels = {
      ShortcutAction.quickNote: AppStrings.shortcutQuickNote,
      ShortcutAction.journalToday: AppStrings.journalFabToday,
      ShortcutAction.newTodo: AppStrings.shortcutNewTodo,
      ShortcutAction.newNote: AppStrings.shortcutNewNote,
      ShortcutAction.newList: AppStrings.shortcutNewList,
      ShortcutAction.newVoice: AppStrings.shortcutNewAudio,
    };
    await ref.read(shortcutServiceProvider).publish(labels);
    final tray = ref.read(trayServiceProvider);
    await tray.init(
      labels: labels,
      openLabel: AppStrings.trayOpen,
      quitLabel: AppStrings.trayQuit,
    );
    CloseToTray.trayShown.value = tray.shown;
  }

  /// Resumes the last library, unless Android is withholding the
  /// shared-storage permission.
  ///
  /// Resuming without it would reconcile the index against a root whose
  /// files the OS hides, rewriting the tree down to its folders. The open
  /// screen shows the permission prompt instead.
  Future<void> _resume() async {
    if (await StorageAccess.hasAllFilesAccess() && mounted) {
      await ref.read(librarySessionProvider).resume();
    }
    // A file the app was started with (#41). With a library open the
    // shell takes it; with none, it opens on its own from here.
    if (!mounted || _libraryReady) return;
    final path = ref.read(launchRequestsProvider).consumeFile();
    if (path != null) _openOutside(path);
  }

  bool get _libraryReady =>
      ref.read(librarySessionProvider).phase == LibraryPhase.ready;

  /// Later launches (#41): each brings the window forward, and a file one
  /// asks for opens here while there is no library for the shell.
  StreamSubscription<void>? _arrivals;
  StreamSubscription<String>? _launchFiles;
  StreamSubscription<String>? _launchFolders;

  void _listenToLaunches() {
    final requests = ref.read(launchRequestsProvider);
    _arrivals = requests.arrivals.listen(
      (_) => unawaited(ref.read(windowControllerProvider).show()),
    );
    _launchFiles = requests.files.listen((path) {
      if (mounted && !_libraryReady) _openOutside(path);
    });
    // A folder dropped with no library open is one to open as a library
    // (#75), the way Open existing takes a folder.
    _launchFolders = requests.folders.listen((path) {
      final session = ref.read(librarySessionProvider);
      // Only while nothing is open or opening: a library on its way in
      // is not replaced by a drop.
      if (mounted && session.phase == LibraryPhase.none) {
        unawaited(session.open(path, create: false));
      }
    });
  }

  // No library is open here, so there is no library config to read an engine
  // setting from and the file is drawn the way the app has always drawn one.
  // The shell's own path (`_openPath`) inherits the open library's setting;
  // both go away when the engine setting does (phase 5).
  void _openOutside(String path) => unawaited(
    openOutsideFile(
      context,
      ref.read(outsideFilesProvider),
      EditorOnlyDocument(path),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(librarySessionProvider);
    // Started once: writes transcripts into notes no view has open.
    ref.read(audioTranscriptWriterProvider);
    // The first-run deck (#266) sits over whatever the phase asks for:
    // it is about the app, not about a library.
    return WelcomeGate(
      child: StreamBuilder<int>(
        stream: controller.events,
        initialData: controller.revision,
        builder: (context, _) => switch (controller.phase) {
          LibraryPhase.ready => Column(
            children: [
              UpdateAvailableBanner(session: controller),
              Expanded(
                // The banner above holds the status bar's inset while it is
                // up; the shell would pad for it a second time.
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: controller.pendingUpdate != null,
                  child: LibraryShell(
                    controller: controller,
                    reminders: ref.read(reminderServiceProvider),
                    spellCheck: ref.read(spellCheckProvider),
                    transcription: ref.read(transcriptionModelsProvider),
                    ocr: ref.read(ocrInstallationProvider),
                    ocrQueue: ref.read(ocrQueueProvider),
                    openNotes: ref.read(openAudioNotesProvider),
                    shortcuts: ref.read(shortcutServiceProvider),
                    shareIn: ref.read(shareInServiceProvider),
                    capture: ref.read(captureServicesProvider),
                    todoSourceFactory: ref.read(todoSourceFactoryProvider),
                    calendarSourceFactory: ref.read(
                      calendarSourceFactoryProvider,
                    ),
                    unsavedTracker: ref.watch(unsavedTrackerProvider),
                    saveExportFile: ref.read(saveExportFileProvider),
                    pickExportFolder: ref.read(pickExportFolderProvider),
                    pdfPrinter: ref.read(pdfPrinterProvider),
                    // The engine search is a process on Windows: looked up when
                    // a folder export actually asks for it, never at startup
                    // (L4), and awaited before the chooser can offer PDF (L5).
                    pdfEngineLookup: () async {
                      final engine = await ref.read(pdfEngineProvider.future);
                      // A "no engine" is not kept for the session: a slow
                      // first lookup — a `reg.exe` the antivirus was scanning
                      // right after an install — is not a machine without a
                      // browser, and the next export deserves a fresh answer
                      // (device report, 2026-09-29).
                      if (engine == null) ref.invalidate(pdfEngineProvider);
                      return engine;
                    },
                    // A book's metadata source, checked before the export
                    // starts (E3); widget tests answer for their library
                    // root.
                    epubMetadataProblem: ref.read(epubMetadataProblemProvider),
                    epubExport: ref.read(epubNoteExportProvider),
                    outsideFiles: ref.read(outsideFilesProvider),
                    launchRequests: ref.read(launchRequestsProvider),
                    targets: ref.read(widgetTargetServiceProvider),
                    widgetUpdater: ref.read(widgetUpdaterProvider),
                    widgetHost: ref.read(widgetHostServiceProvider),
                    tray: ref.read(trayServiceProvider),
                    window: ref.read(windowControllerProvider),
                  ),
                ),
              ),
            ],
          ),
          _ => OpenLibraryScreen(
            controller: controller,
            outsideFiles: ref.read(outsideFilesProvider),
          ),
        },
      ),
    );
  }
}
