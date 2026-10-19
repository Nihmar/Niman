import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/library/library_state.dart';

/// The question a downloader asks before it fetches (#1109): does the open
/// library have [feature] on?
///
/// Read at each download, never held, so the answer follows the library
/// that is open then and its switches as they stand. The installation-wide
/// services (Tesseract, the whisper models) are shared by every library;
/// the switch belongs to one, which is why the gate asks the session. With
/// no library open every feature reads as on, as the session answers.
bool Function() featureDownloadGate(Ref ref, LibraryFeature feature) =>
    () => ref.read(librarySessionProvider).features.value.isOn(feature);
