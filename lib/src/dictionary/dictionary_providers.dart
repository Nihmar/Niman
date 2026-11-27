import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/resume_observer.dart';
import 'package:niman/src/dictionary/dictionary_catalog.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_pack_info.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The packs the app offers to download: the generated catalog.
///
/// The one place the catalog is read from, so a test overrides it with a
/// catalog of its own, and an empty one is what the app ships until the
/// first release.
final dictionaryCatalogProvider = Provider<List<DictionaryPackInfo>>(
  (ref) => dictionaryPacks,
);

/// `<support>/dictionary/`: where the packs live, outside any library
/// (docs/records/dictionary.md, decision 14).
final dictionaryDirectoryProvider = FutureProvider<String>(
  (ref) async =>
      p.join((await getApplicationSupportDirectory()).path, 'dictionary'),
);

/// The app's one [DictionaryService], over the dictionaries folder: what a
/// look-up asks, and what the installation tells when a pack comes or goes.
/// Closed with the app.
final dictionaryServiceProvider = FutureProvider<DictionaryService>((
  ref,
) async {
  final service = DictionaryService(
    directory: await ref.watch(dictionaryDirectoryProvider.future),
  );
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// What dictionaries this device has and is getting, shared by the settings
/// page and the look-up: app-wide and long-lived, so a download goes on when
/// the page closes.
final dictionaryInstallationProvider = Provider<DictionaryInstallation>((ref) {
  final installation = DictionaryInstallation(
    directory: () => ref.read(dictionaryDirectoryProvider.future),
    service: () => ref.read(dictionaryServiceProvider.future),
    catalog: ref.watch(dictionaryCatalogProvider),
  );
  unawaited(installation.load());
  // Back in the foreground: pick up the downloads the freeze cut off.
  final observer = ResumeObserver(
    () => unawaited(installation.resumeInterrupted()),
  );
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
    installation.dispose();
  });
  return installation;
});
