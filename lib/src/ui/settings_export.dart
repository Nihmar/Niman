/// The Export area of the settings (#1285): what an export is made on,
/// the same for every library — the paper a PDF is printed on.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/export/paper_size.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Export area's screen.
final class SettingsExportScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s session.
  const new({required this.controller, this.highlight, super.key});

  /// The session whose app settings the rows edit.
  final LibrarySession controller;

  /// The row to flash, when the screen was opened for one.
  final Key? highlight;

  @override
  State<SettingsExportScreen> createState() => _SettingsExportScreenState();
}

final class _SettingsExportScreenState extends State<SettingsExportScreen> {
  PaperSize _paper = PaperSize.a4;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final paper = await widget.controller.appSettings.pdfPaper;
    if (mounted) setState(() => _paper = paper);
  }

  /// Asks which paper the PDF exports are printed on.
  Future<void> _choosePaper() async {
    final paper = await showSettingsChoice<PaperSize>(
      context,
      dialogKey: const Key('pdf-paper-dialog'),
      title: AppStrings.pdfPaperTitle,
      subtitle: AppStrings.pdfPaperSubtitle,
      current: _paper,
      options: [
        for (final size in PaperSize.values)
          SettingsOption(size, AppStrings.paperSizeName(size)),
      ],
    );
    if (paper == null) return;
    await widget.controller.appSettings.setPdfPaper(paper);
    if (mounted) setState(() => _paper = paper);
  }

  @override
  Widget build(BuildContext context) => SettingsAreaShell(
    title: AppStrings.settingsSectionExport,
    controller: widget.controller,
    highlight: widget.highlight,
    body: ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        HighlightRow(
          key: SettingsKeys.pdfPaper,
          child: SettingsValueRow(
            title: AppStrings.pdfPaperTitle,
            subtitle: AppStrings.pdfPaperSubtitle,
            value: AppStrings.paperSizeName(_paper),
            onTap: () => unawaited(_choosePaper()),
          ),
        ),
      ],
    ),
  );
}
