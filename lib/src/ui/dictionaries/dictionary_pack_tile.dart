import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/dictionary/dictionary_disk.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_pack.dart';
import 'package:niman/src/dictionary/dictionary_preparation.dart';
import 'package:niman/src/ui/dictionaries/dictionary_names.dart';
import 'package:niman/src/ui/download_tile.dart';
import 'package:niman/src/ui/strings.dart';

/// One dictionary in the settings' lists, whatever it is going through: on
/// offer, downloading, being unpacked and indexed, or installed.
///
/// A pack on offer, downloading or installed is the downloader's own row
/// ([DownloadTile], as the OCR's languages are); one being unpacked or
/// indexed has no cancel, only how far it has got. The row keeps its place
/// as it goes from one to the next.
final class DictionaryPackTile extends StatelessWidget {
  /// The row of the pack [id], in the lists of [installation].
  ///
  /// [pack] is its catalog entry, null for a pack the catalog does not
  /// know (one installed from an older catalog); [installed] its folder,
  /// null while it has none.
  const new({
    required this.id,
    required this.installation,
    required this.onRemoveFailed,
    this.pack,
    this.installed,
    super.key,
  });

  /// The pack's id (`niman-it`).
  final String id;

  /// What this device has and is getting.
  final DictionaryInstallation installation;

  /// Reports why a pack could not be removed.
  final void Function(String language, String reason) onRemoveFailed;

  /// The catalog's entry for the pack.
  final DictionaryPack? pack;

  /// The pack in the folder, with its size.
  final InstalledDictionary? installed;

  @override
  Widget build(BuildContext context) {
    final installed = this.installed;
    final pack = this.pack;
    final languages = installed?.pack.languages ?? pack?.languages ?? const [];
    final title = DictionaryNames.title(languages);
    final state = pack == null
        ? const NotDownloaded()
        : installation.stateOf(pack);
    final preparation = installation.preparationOf(id);
    // Downloaded and not installed is the moment between the two: the
    // archive is whole and the unpacking has not reported yet.
    if (preparation != null || (installed == null && state is Downloaded)) {
      return _Preparing(
        id: id,
        title: title,
        preparation: preparation ?? const DictionaryPreparation.unpacking(),
      );
    }
    final bytes = installed?.bytes ?? pack?.bytes ?? 0;
    // A pack this app cannot read, or whose index would not build: either
    // way it is on the device and cannot be used, and says why.
    final unusable = installed?.pack.unavailableReason;
    final indexFailure = installation.indexFailureOf(id);
    final broken = unusable != null || indexFailure != null;
    return DownloadTile(
      key: ValueKey('dictionary-tile-$id'),
      id: id,
      keyPrefix: 'dictionary',
      state: installed == null ? state : Downloaded(bytes),
      bytes: bytes,
      title: Text(title),
      idle: _detail(installed, pack, bytes, unusable, indexFailure),
      installedLeading: Icon(
        broken ? Icons.error_outline : Icons.menu_book_outlined,
        color: broken ? Theme.of(context).colorScheme.error : null,
      ),
      onRetryInstalled: indexFailure == null
          ? null
          : () => unawaited(installation.retryIndex(id)),
      deleteTitle: AppStrings.dictionaryDeleteTitle(title),
      deleteBody: AppStrings.dictionaryDeleteBody,
      onDownload: () {
        if (pack != null) unawaited(installation.download(pack));
      },
      onCancel: () {
        if (pack != null) unawaited(installation.cancel(pack));
      },
      onDelete: () async {
        final reason = await installation.remove(id);
        if (reason != null) onRemoveFailed(title, reason);
      },
    );
  }

  /// The line under the name: where the words come from, the language the
  /// definitions are in, the licence of an installed pack, and its size.
  String _detail(
    InstalledDictionary? installed,
    DictionaryPack? pack,
    int bytes,
    String? unusable,
    String? indexFailure,
  ) {
    final ifo = installed?.pack.ifo;
    final definitions = ifo?.definitions ?? pack?.info.definitions ?? '';
    return [
      ?DictionaryNames.serves(
        installed?.pack.languages ?? pack?.languages ?? const [],
      ),
      'Wiktionary',
      if (definitions.isNotEmpty)
        AppStrings.dictionaryDefinitions(DictionaryNames.native(definitions)),
      if (ifo != null && ifo.license.isNotEmpty) ifo.license,
      AppStrings.byteSize(bytes),
      ?(unusable == null ? null : AppStrings.dictionaryUnusable(unusable)),
      ?(indexFailure == null
          ? null
          : AppStrings.dictionaryIndexFailed(indexFailure)),
    ].join(' · ');
  }
}

/// A pack past its download: being unpacked, then indexed, with how far
/// the index is.
final class _Preparing extends StatelessWidget {
  const new({required this.id, required this.title, required this.preparation});

  final String id;
  final String title;
  final DictionaryPreparation preparation;

  @override
  Widget build(BuildContext context) {
    final fraction = preparation.fraction;
    final label = switch (preparation.step) {
      DictionaryPreparationStep.unpacking => AppStrings.dictionaryUnpacking,
      DictionaryPreparationStep.indexing => AppStrings.dictionaryIndexing(
        ((fraction ?? 0) * 100).floor(),
      ),
    };
    return ListTile(
      key: ValueKey('dictionary-preparing-$id'),
      leading: SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(value: fraction, strokeWidth: 2.5),
      ),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: fraction),
        ],
      ),
    );
  }
}
