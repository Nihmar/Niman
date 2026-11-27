/// Looking a selection up (#1383): from the text a surface has selected, and
/// what it knows of its language, to the panel.
///
/// The surfaces — a book, a PDF, a scan's text — only say what is selected,
/// where, in what language they know and whether they can annotate; this
/// finds the language (decision 10), the dictionary service and the
/// installation, and shows the panel a phone's sheet or a desktop's panel
/// under the selection, as the device is drawn for. The panels read the
/// providers through the app's `ProviderScope`, as the settings do.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/dictionary/dictionary_language.dart';
import 'package:niman/src/dictionary/dictionary_providers.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/dictionary_panel.dart';
import 'package:niman/src/ui/dictionary_panel/lookup_session.dart';
import 'package:niman/src/ui/dictionary_panel/panel_popup.dart';
import 'package:niman/src/ui/dictionary_panel/panel_sheet.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/settings_dictionaries.dart';

export 'package:niman/src/ui/dictionary_panel.dart' show DictionaryAnnotate;

/// Which kind of surface a selection was made on: what its language is
/// taken from.
enum DictionarySurface {
  /// A book: its own `dc:language`.
  book,

  /// A PDF: the language chosen for the file.
  pdf,

  /// A note, or text recognized from a scan: the library's.
  text,
}

const AppLogger _log = AppLogger(name: 'dictionary');

/// Looks [selection] up and shows the answer.
///
/// [language] is what the surface holds: a book's `dc:language`, or the
/// language chosen for a PDF (null for none yet); the library's spelling
/// language and the app's fill in what it does not say. [anchor] is the
/// selection in the window's coordinates, which a desktop's panel hangs
/// from; a phone's sheet has no use for it. [annotate] annotates the
/// passage with the definition, null where the surface cannot, and
/// [onLanguage] is told the language the reader picked in the panel, to be
/// kept for the file.
///
/// With a panel already open on a desktop, it is updated in place and the
/// future completes at once.
Future<void> showDictionaryLookup(
  BuildContext context, {
  required String selection,
  required DictionarySurface surface,
  String? language,
  Rect? anchor,
  DictionaryAnnotate? annotate,
  ValueChanged<String>? onLanguage,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final navigator = Navigator.of(context, rootNavigator: true);
  final spelling = await _spellingLanguages(container);
  if (!context.mounted) return;
  final code = switch (surface) {
    DictionarySurface.book => DictionaryLanguage.forBook(
      language,
      spelling: spelling,
    ),
    DictionarySurface.pdf => DictionaryLanguage.forPdf(
      language,
      spelling: spelling,
    ),
    DictionarySurface.text => DictionaryLanguage.forNote(spelling: spelling),
  };
  final text = selection.trim();
  final here = _anchorOf(context, anchor);
  if (DictionaryPopup.current case final open?) {
    open.session
      ..onLanguage = onLanguage
      ..restart(text, code).ignore();
    open.update(anchor: here, annotate: annotate);
    return;
  }
  final installation = container.read(dictionaryInstallationProvider);
  final service = container.read(dictionaryServiceProvider.future);
  final session = DictionaryLookupSession(
    lookUp: (selection, language) async =>
        await (await service).lookUp(selection, language),
    selection: text,
    language: code,
    // A service that cannot start is the look-up's to report, not this
    // stream's.
    // Listened to once per look-up, so it is a broadcast one.
    progress:
        Stream.fromFuture(service.then((service) => service.indexProgress))
            .asyncExpand((progress) => progress)
            .handleError((Object _) {})
            .asBroadcastStream(),
    onLanguage: onLanguage,
  );
  void openSettings() => unawaited(_openSettings(navigator, container));
  if (pointerDense(Theme.of(context))) {
    DictionaryPopup.open(
      context,
      session: session,
      installation: installation,
      anchor: here,
      onOpenSettings: openSettings,
      annotate: annotate,
    );
    return;
  }
  await showDictionarySheet(
    context,
    session: session,
    installation: installation,
    onOpenSettings: openSettings,
    annotate: annotate,
  );
  session.dispose();
}

/// The selection's place: [anchor], or the middle of [context]'s box when
/// the surface knows none.
Rect _anchorOf(BuildContext context, Rect? anchor) {
  if (anchor != null) return anchor;
  final box = context.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    return Rect.fromCenter(
      center: box.localToGlobal(box.size.center(Offset.zero)),
      width: 0,
      height: 20,
    );
  }
  return Rect.zero;
}

/// The library's spelling languages, as hunspell names them; none when no
/// library is open or its settings cannot be read.
Future<List<String>> _spellingLanguages(ProviderContainer container) async {
  try {
    return await container
        .read(librarySessionProvider)
        .librarySettings
        .spellDictionaries;
  } on Object catch (error) {
    _log.info('no spelling languages for the look-up: $error');
    return const [];
  }
}

/// Settings → Dictionaries, over whatever is on screen.
Future<void> _openSettings(
  NavigatorState navigator,
  ProviderContainer container,
) async {
  if (!navigator.mounted) return;
  await navigator.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => SettingsDictionariesScreen(
        controller: container.read(librarySessionProvider),
      ),
    ),
  );
}
