/// Asks how to recognize a file's text (#594): in which language, and
/// with which second one; for a PDF which pages; it says where the text
/// will be written and, on first use, what has to be downloaded first.
/// A sheet on a phone, a dialog on a wide window, as the app asks for an
/// annotation.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/download/downloadable.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show wideBreakpoint;
import 'package:niman/src/ocr/ocr_engine_build.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_sidecar.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// What the reader chose: the languages, the default first, and the
/// pages (null for all of them).
typedef OcrRequest = ({List<OcrLanguage> languages, List<int>? pages});

/// Asks how to recognize [path] (library-relative), a PDF of [pageCount]
/// pages on [page], or a picture (both null); null when cancelled.
Future<OcrRequest?> showRecognizeTextSheet(
  BuildContext context, {
  required OcrInstallation installation,
  required String path,
  int? pageCount,
  int? page,
}) {
  final body = _RecognizeForm(
    installation: installation,
    path: path,
    pageCount: pageCount,
    page: page,
  );
  if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
    return showDialog<OcrRequest>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(child: body),
        ),
      ),
    );
  }
  return showModalBottomSheet<OcrRequest>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(child: SingleChildScrollView(child: body)),
    ),
  );
}

enum _Pages { all, current, range }

final class _RecognizeForm extends StatefulWidget {
  const new({
    required this.installation,
    required this.path,
    required this.pageCount,
    required this.page,
  });

  final OcrInstallation installation;
  final String path;
  final int? pageCount;
  final int? page;

  @override
  State<_RecognizeForm> createState() => _RecognizeFormState();
}

final class _RecognizeFormState extends State<_RecognizeForm> {
  late OcrLanguage _language = widget.installation.defaultLanguage();
  late OcrLanguage? _also = widget.installation.alsoLanguage();
  _Pages _pages = _Pages.all;
  late final TextEditingController _from = TextEditingController(text: '1');
  late final TextEditingController _to = TextEditingController(
    text: '${widget.pageCount ?? 1}',
  );

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  List<OcrLanguage> get _languages => [_language, ?_also];

  /// Typing a page number means the range.
  void _chooseRange(String _) => setState(() => _pages = _Pages.range);

  List<int>? get _chosenPages {
    final count = widget.pageCount;
    if (count == null) return null;
    switch (_pages) {
      case _Pages.all:
        return null;
      case _Pages.current:
        return [widget.page ?? 1];
      case _Pages.range:
        final from = (int.tryParse(_from.text) ?? 1).clamp(1, count);
        final to = (int.tryParse(_to.text) ?? count).clamp(from, count);
        return [for (var i = from; i <= to; i++) i];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missing = widget.installation.missingFor(_languages);
    final folder = p.posix.dirname(widget.path);
    final sidecar = '${ocrSidecarName(p.posix.basename(widget.path))}.md';
    final count = widget.pageCount;
    return Padding(
      key: const Key('recognize-text-sheet'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.document_scanner_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.ocrRecognizeAction,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<OcrLanguage>(
            key: const Key('recognize-language'),
            initialValue: _language,
            menuMaxHeight: 420,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: AppStrings.ocrLanguageTitle,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final language in ocrLanguagesByName)
                DropdownMenuItem(value: language, child: Text(language.native)),
            ],
            onChanged: (language) => setState(() {
              _language = language ?? _language;
              if (_also == _language) _also = null;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('recognize-also'),
            initialValue: _also?.code ?? '',
            menuMaxHeight: 420,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: AppStrings.ocrAlsoTitle,
              helperText: AppStrings.ocrAlsoSubtitle,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: '', child: Text(AppStrings.ocrAlsoNone)),
              for (final language in ocrLanguagesByName)
                if (language != _language)
                  DropdownMenuItem(
                    value: language.code,
                    child: Text(language.native),
                  ),
            ],
            onChanged: (code) =>
                setState(() => _also = ocrLanguageByCode(code)),
          ),
          if (count != null && count > 1) ...[
            const SizedBox(height: 16),
            Text(AppStrings.ocrPagesTitle, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  key: const Key('recognize-pages-all'),
                  label: Text(AppStrings.ocrPagesAll(count)),
                  selected: _pages == _Pages.all,
                  onSelected: (_) => setState(() => _pages = _Pages.all),
                ),
                if (widget.page != null)
                  ChoiceChip(
                    key: const Key('recognize-pages-current'),
                    label: Text(AppStrings.ocrPagesThis(widget.page!)),
                    selected: _pages == _Pages.current,
                    onSelected: (_) => setState(() => _pages = _Pages.current),
                  ),
                ChoiceChip(
                  key: const Key('recognize-pages-range'),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppStrings.ocrPagesFrom),
                      _PageField(
                        controller: _from,
                        onChanged: _chooseRange,
                        key: const Key('recognize-from'),
                      ),
                      Text(AppStrings.ocrPagesTo),
                      _PageField(
                        controller: _to,
                        onChanged: _chooseRange,
                        key: const Key('recognize-to'),
                      ),
                    ],
                  ),
                  selected: _pages == _Pages.range,
                  onSelected: (_) => setState(() => _pages = _Pages.range),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(AppStrings.ocrSavedAs, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  folder == '.' ? sidecar : '$folder / $sidecar',
                  key: const Key('recognize-saved-as'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.ocrSavedAsHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Download(missing: missing),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppStrings.actionCancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('recognize-start'),
                onPressed: () => Navigator.of(
                  context,
                ).pop<OcrRequest>((languages: _languages, pages: _chosenPages)),
                child: Text(
                  missing.isEmpty
                      ? AppStrings.ocrRecognizeAction
                      : AppStrings.ocrDownloadAndRecognize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What a first recognition downloads: the total, and each piece.
final class _Download extends StatelessWidget {
  const new({required this.missing});

  final List<Downloadable> missing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = missing.fold(0, (sum, item) => sum + item.bytes);
    final pieces = [
      for (final item in missing)
        '${switch (item) {
          OcrLanguageFile(:final language) => language.native,
          OcrEngineBuild() => AppStrings.ocrEngineTitle,
          _ => item.id,
        }} ${AppStrings.byteSize(item.bytes)}',
    ].join(' · ');
    return DecoratedBox(
      key: const Key('recognize-download'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.download_outlined, color: theme.colorScheme.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.ocrNeedsDownload(AppStrings.byteSize(total))),
                  const SizedBox(height: 2),
                  Text(
                    '$pieces. ${AppStrings.ocrNeedsDownloadHint}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A page number, two or three digits wide.
final class _PageField extends StatelessWidget {
  const new({required this.controller, required this.onChanged, super.key});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: SizedBox(
      width: 44,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(isDense: true),
      ),
    ),
  );
}
