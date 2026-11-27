import 'package:flutter/material.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/dictionary/dictionary_disk.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_pack.dart';
import 'package:niman/src/ui/dictionaries/dictionary_names.dart';
import 'package:niman/src/ui/dictionaries/dictionary_pack_tile.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The dictionaries of the settings (#1382): those on this device, or on
/// their way, and below them the others the catalog offers, with a search
/// over the language names.
///
/// A pack mid-download, or being unpacked or indexed, sits with those on
/// the device: it is on its way there, and stays put while it arrives, as
/// the OCR's languages do. With an empty catalog there is nothing to
/// offer, and a quiet line says so.
final class DictionaryPackList extends StatefulWidget {
  /// Creates the lists over [installation].
  const new({required this.installation, super.key});

  /// What this device has and is getting.
  final DictionaryInstallation installation;

  @override
  State<DictionaryPackList> createState() => _DictionaryPackListState();
}

final class _DictionaryPackListState extends State<DictionaryPackList> {
  /// The search's text, and the one place the filter reads it from.
  final _search = TextEditingController();

  DictionaryInstallation get _installation => widget.installation;

  @override
  void initState() {
    super.initState();
    _search.addListener(_searched);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _searched() => setState(() {});

  void _removeFailed(String language, String reason) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.dictionaryRemoveFailed(language, reason)),
      ),
    );
  }

  /// Whether [pack] is on the device, or on its way to being usable.
  bool _here(DictionaryPack pack) =>
      _installation.isInstalled(pack.id) ||
      _installation.preparationOf(pack.id) != null ||
      _installation.stateOf(pack) is! NotDownloaded;

  @override
  Widget build(BuildContext context) {
    final installation = _installation;
    final byId = <String, DictionaryPackTile>{};
    for (final entry in installation.installed) {
      final id = entry.pack.id;
      byId[id] = _tile(id, installed: entry, pack: installation.packOf(id));
    }
    for (final pack in installation.packs) {
      if (_here(pack)) {
        byId.putIfAbsent(pack.id, () => _tile(pack.id, pack: pack));
      }
    }
    final here = byId.values.toList()
      ..sort((a, b) => _title(a).compareTo(_title(b)));
    final offered =
        [
          for (final pack in installation.packs)
            if (!_here(pack) &&
                DictionaryNames.matches(pack.languages, _search.text))
              pack,
        ]..sort(
          (a, b) =>
              DictionaryNames.title(a.languages)
                  .compareTo(DictionaryNames.title(b.languages)),
        );
    final empty = installation.packs.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(AppStrings.dictionariesInstalled),
        if (here.isEmpty)
          _quiet(
            const Key('dictionaries-none-installed'),
            AppStrings.dictionariesNoneInstalled,
          )
        else
          ...here,
        HighlightRow(
          key: SettingsKeys.dictionaryDownload,
          child: SettingsSection(AppStrings.dictionariesDownload),
        ),
        if (empty)
          _quiet(
            const Key('dictionaries-unavailable'),
            AppStrings.dictionariesUnavailable,
          )
        else ...[
          // Keyed: a pack starting to download joins those on the device
          // above, and an unkeyed row here would be matched by position,
          // the field built afresh under the user and its focus lost.
          Padding(
            key: const ValueKey('dictionary-search-row'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const Key('dictionary-search'),
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: AppStrings.dictionariesSearchHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          for (final pack in offered) _tile(pack.id, pack: pack),
          if (offered.isEmpty)
            _quiet(
              const Key('dictionaries-no-offer'),
              _search.text.trim().isEmpty
                  ? AppStrings.dictionariesAllInstalled
                  : AppStrings.dictionariesNoMatch,
            ),
        ],
      ],
    );
  }

  String _title(DictionaryPackTile tile) => DictionaryNames.title(
    tile.installed?.pack.languages ?? tile.pack?.languages ?? const [],
  );

  DictionaryPackTile _tile(
    String id, {
    DictionaryPack? pack,
    InstalledDictionary? installed,
  }) => DictionaryPackTile(
    key: ValueKey(id),
    id: id,
    installation: _installation,
    pack: pack,
    installed: installed,
    onRemoveFailed: _removeFailed,
  );

  /// A line that says there is nothing here, in the colour of a hint.
  Widget _quiet(Key key, String text) {
    final theme = Theme.of(context);
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
