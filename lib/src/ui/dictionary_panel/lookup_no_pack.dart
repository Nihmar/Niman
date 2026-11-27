import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_pack.dart';
import 'package:niman/src/dictionary/dictionary_result.dart';
import 'package:niman/src/dictionary/lookup_term.dart';
import 'package:niman/src/ui/dictionaries/dictionary_names.dart';
import 'package:niman/src/ui/strings.dart';

/// No dictionary for the language (screen F): the one the catalog has for
/// it, with its size, downloaded here; the word is looked up when it is
/// ready. With no pack to offer, it says so and leaves the language to
/// change.
final class LookupNoPack extends StatefulWidget {
  /// The answer [result] says no pack serves the language. A download goes
  /// through [installation]; [onReady] looks the word up again once the
  /// pack is usable, and [onChangeLanguage] opens the language chooser.
  const new({
    required this.result,
    required this.installation,
    required this.onReady,
    required this.onChangeLanguage,
    required this.fontSize,
    super.key,
  });

  /// The look-up that found no pack.
  final DictionaryResult result;

  /// What the device has, and the downloads under way.
  final DictionaryInstallation installation;

  /// Looks the word up again.
  final VoidCallback onReady;

  /// Opens the language chooser.
  final VoidCallback onChangeLanguage;

  /// The size of the body text.
  final double fontSize;

  @override
  State<LookupNoPack> createState() => _LookupNoPackState();
}

final class _LookupNoPackState extends State<LookupNoPack> {
  bool _fired = false;

  DictionaryPack? get _pack {
    final code = LookupTerm.primaryLanguage(widget.result.language);
    for (final pack in widget.installation.packs) {
      if (pack.serves(code)) return pack;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    widget.installation.addListener(_changed);
  }

  @override
  void didUpdateWidget(LookupNoPack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.installation != widget.installation) {
      oldWidget.installation.removeListener(_changed);
      widget.installation.addListener(_changed);
    }
    if (oldWidget.result != widget.result) _fired = false;
  }

  @override
  void dispose() {
    widget.installation.removeListener(_changed);
    super.dispose();
  }

  /// The pack came: the word is looked up in it, once.
  void _changed() {
    final pack = _pack;
    if (pack == null || _fired) return;
    final installation = widget.installation;
    if (installation.isInstalled(pack.id) &&
        installation.preparationOf(pack.id) == null) {
      _fired = true;
      widget.onReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = DictionaryNames.native(widget.result.language);
    final pack = _pack;
    return ListenableBuilder(
      listenable: widget.installation,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            pack == null
                ? AppStrings.lookUpNoPackOffered(language)
                : AppStrings.lookUpNoPack(language),
            key: const Key('lookup-no-pack'),
            style: TextStyle(fontSize: widget.fontSize, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (pack != null) _offer(pack, language),
              TextButton(
                key: const Key('lookup-change-language'),
                onPressed: widget.onChangeLanguage,
                child: Text(AppStrings.lookUpOrChangeLanguage),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// What the pack is going through: the button, then its progress.
  Widget _offer(DictionaryPack pack, String language) {
    final installation = widget.installation;
    final state = installation.stateOf(pack);
    final preparation = installation.preparationOf(pack.id);
    const figures = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
    if (preparation != null) {
      final indexed = preparation.fraction;
      return _Progress(
        key: const Key('lookup-preparing'),
        label: indexed == null
            ? AppStrings.dictionaryUnpacking
            : AppStrings.dictionaryIndexing((indexed * 100).floor()),
        value: indexed,
      );
    }
    return switch (state) {
      Downloading(:final received, :final total, :final fraction) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Progress(
            key: const Key('lookup-downloading'),
            label:
                '${AppStrings.byteSize(received)} / '
                '${AppStrings.byteSize(total)} · '
                '${(fraction * 100).floor()}%',
            value: fraction,
            style: figures,
          ),
          IconButton(
            key: const Key('lookup-cancel'),
            tooltip: AppStrings.actionCancel,
            icon: const Icon(Icons.close),
            onPressed: () => unawaited(installation.cancel(pack)),
          ),
        ],
      ),
      DownloadFailed(:final resumable) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.downloadFailed,
            key: const Key('lookup-failed'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            key: const Key('lookup-retry'),
            onPressed: () => unawaited(installation.download(pack)),
            child: Text(
              resumable ? AppStrings.actionResume : AppStrings.actionRetry,
            ),
          ),
        ],
      ),
      // The archive is whole and not yet unpacked: the moment between.
      Downloaded() => _Progress(
        key: const Key('lookup-preparing'),
        label: AppStrings.dictionaryUnpacking,
      ),
      NotDownloaded() => FilledButton.icon(
        key: const Key('lookup-download'),
        onPressed: () => unawaited(installation.download(pack)),
        icon: const Icon(Icons.download),
        label: Text(
          AppStrings.lookUpDownloadPack(
            language,
            AppStrings.byteSize(pack.bytes),
          ),
        ),
      ),
    };
  }
}

/// A line of progress: what it is and a bar.
final class _Progress extends StatelessWidget {
  const new({required this.label, this.value, this.style, super.key});

  final String label;
  final double? value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 240),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: style),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: value),
      ],
    ),
  );
}
