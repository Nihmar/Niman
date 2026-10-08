import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_language_catalog.dart';
import 'package:niman/src/ui/download_tile.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The languages of the current quality (#593): those on this device,
/// with what they take, and below them the others to download, with a
/// search over the native and English names.
///
/// A language mid-download, or paused, sits with those on the device: it
/// is on its way there, and stays put while it arrives.
final class OcrLanguageList extends StatefulWidget {
  /// Creates the list over [installation].
  const new({required this.installation, super.key});

  /// What is installed for OCR on this device.
  final OcrInstallation installation;

  @override
  State<OcrLanguageList> createState() => _OcrLanguageListState();
}

final class _OcrLanguageListState extends State<OcrLanguageList> {
  /// The search's text, and the one place the filter reads it from: the
  /// list cannot show one query while the field shows another.
  final _search = TextEditingController();

  OcrInstallation get _ocr => widget.installation;

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

  @override
  Widget build(BuildContext context) {
    final quality = _ocr.settings.quality;
    final files = [for (final language in ocrLanguages) ?language.file(quality)]
      ..sort((a, b) => a.language.native.compareTo(b.language.native));
    final here = [
      for (final file in files)
        if (_ocr.stateOf(file) is! NotDownloaded) file,
    ];
    final others = [
      for (final file in files)
        if (_ocr.stateOf(file) is NotDownloaded &&
            file.language.matches(_search.text))
          file,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (here.isNotEmpty) ...[
          SettingsSection(
            AppStrings.ocrOnDevice(
              AppStrings.byteSize(_ocr.installedBytes(quality)),
            ),
          ),
          for (final file in here) _tile(file),
        ],
        SettingsSection(AppStrings.ocrOtherLanguages),
        // Keyed: a language starting to download joins those on the device
        // above, and an unkeyed row here would be matched by position —
        // the field built afresh under the user, its focus lost.
        Padding(
          key: const ValueKey('ocr-language-search-row'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            key: const Key('ocr-language-search'),
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: AppStrings.ocrSearchLanguages(files.length),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        for (final file in others) _tile(file),
      ],
    );
  }

  Widget _tile(OcrLanguageFile file) {
    final language = file.language;
    final isDefault = language == _ocr.defaultLanguage();
    return DownloadTile(
      key: ValueKey(file.id),
      id: file.id,
      keyPrefix: 'ocr',
      state: _ocr.stateOf(file),
      bytes: file.bytes,
      title: Text(language.native),
      idle: [
        if (language.english != language.native) language.english,
        AppStrings.byteSize(file.bytes),
        if (isDefault) AppStrings.ocrLanguageDefault,
      ].join(' · '),
      deleteTitle: AppStrings.ocrLanguageDeleteTitle(language.native),
      deleteBody: AppStrings.ocrDeleteBody,
      onDownload: () => unawaited(_ocr.download(file)),
      onCancel: () => unawaited(_ocr.cancel(file)),
      onDelete: () => _ocr.delete(file),
    );
  }
}
